@preconcurrency import AVFoundation
import Speech
import CoreMedia

// MARK: - Live Caption Segment
// Individual recognized text segment from on-device speech recognition

struct LiveCaptionSegment: Identifiable, Sendable {
    let id: UUID
    let text: String
    let timestamp: TimeInterval
    let isFinal: Bool
}

// MARK: - Live Transcription Service
// Wraps SpeechAnalyzer + DictationTranscriber (iOS 26) for on-device
// streaming recognition with punctuated output.
// Ephemeral — captions are NOT persisted. The canonical transcript
// comes from the Whisper pipeline.

@available(iOS 26, *)
@MainActor @Observable
final class LiveTranscriptionService {
    static let shared = LiveTranscriptionService()

    // MARK: - Public State

    private(set) var isAvailable: Bool = false
    private(set) var currentText: String = ""
    private(set) var segments: [LiveCaptionSegment] = []
    private(set) var isTranscribing: Bool = false

    // MARK: - Private State

    private var transcriber: DictationTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var analyzerFormat: AVAudioFormat?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriptionTask: Task<Void, Never>?
    private var bufferConverter: AVAudioConverter?
    private var retryCount: Int = 0
    private var lastResultRangeStart: CMTime = .zero

    // MARK: - Initialization

    private init() {
        // Availability check is async — callers must invoke checkAvailability()
    }

    /// Check device + locale support. Must be called before use.
    func checkAvailability() async {
        let supported = await DictationTranscriber.supportedLocale(equivalentTo: .current)
        isAvailable = supported != nil
    }

    // MARK: - Authorization

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Check current authorization status without prompting
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Language Asset Management

    /// Check if the language model for the current locale is installed
    func checkLanguageModelInstalled() async -> Bool {
        let installed = await DictationTranscriber.installedLocales
        return installed.contains(where: { $0.language == Locale.current.language })
    }

    /// Install language assets for the current locale.
    /// Called from Settings preflight, NOT during recording start.
    func installLanguageAssets(progress: @escaping @Sendable (Double) -> Void) async throws {
        // Create a temporary transcriber instance for asset management
        let tempTranscriber = DictationTranscriber(
            locale: .current,
            preset: .progressiveLongDictation
        )

        guard let request = try await AssetInventory.assetInstallationRequest(
            supporting: [tempTranscriber]
        ) else {
            throw SermonError.speechRecognitionUnavailable
        }

        // Observe progress via Foundation.Progress
        let progressObservation = request.progress.observe(
            \.fractionCompleted,
            options: [.new]
        ) { progressObj, _ in
            progress(progressObj.fractionCompleted)
        }

        // Perform the download (blocks until complete)
        try await request.downloadAndInstall()

        // Clean up observation
        progressObservation.invalidate()

        // Recheck availability after install
        await checkAvailability()
    }

    // MARK: - Transcription Lifecycle

    /// Start live transcription. Call after recording has started.
    func startTranscription(recordingFormat: AVAudioFormat) async throws {
        guard isAvailable else {
            throw SermonError.speechRecognitionUnavailable
        }

        guard authorizationStatus == .authorized else {
            throw SermonError.speechRecognitionDenied
        }

        retryCount = 0
        lastResultRangeStart = .zero
        try await startTranscriptionInternal(recordingFormat: recordingFormat)
    }

    private func startTranscriptionInternal(recordingFormat: AVAudioFormat) async throws {
        // Create DictationTranscriber using the long dictation preset
        // progressiveLongDictation: volatile results + punctuation for sermons/lectures
        let newTranscriber = DictationTranscriber(
            locale: .current,
            preset: .progressiveLongDictation
        )
        transcriber = newTranscriber

        // Create SpeechAnalyzer with transcriber module
        let newAnalyzer = SpeechAnalyzer(modules: [newTranscriber])
        analyzer = newAnalyzer

        // Apply contextual biasing for biblical terminology
        await applyBiblicalContext(to: newAnalyzer)

        // Get the best audio format compatible with the transcriber
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [newTranscriber]
        )

        // Create converter from recording format to analyzer format
        if let targetFormat = analyzerFormat, targetFormat != recordingFormat {
            bufferConverter = AVAudioConverter(from: recordingFormat, to: targetFormat)
        } else {
            bufferConverter = nil
        }

        // Create input stream
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        // Start analyzer
        try await newAnalyzer.start(inputSequence: stream)

        isTranscribing = true

        // Launch result processing task
        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in newTranscriber.results {
                    guard !Task.isCancelled else { break }
                    await self.handleTranscriptionResult(result)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await self.handleTranscriptionError(error, recordingFormat: recordingFormat)
            }
        }
    }

    /// Feed an audio buffer from the recording service
    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard isTranscribing else { return }

        let inputBuffer: AVAudioPCMBuffer
        if let converter = bufferConverter, let targetFormat = analyzerFormat {
            // Convert to analyzer format
            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate
            )
            guard let converted = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCapacity
            ) else { return }

            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard error == nil else { return }
            inputBuffer = converted
        } else {
            inputBuffer = buffer
        }

        inputContinuation?.yield(AnalyzerInput(buffer: inputBuffer))
    }

    /// Stop transcription and return draft transcript text
    func stopTranscription() async -> String? {
        guard isTranscribing else { return nil }
        isTranscribing = false

        // Signal end of input
        inputContinuation?.finish()

        // Finalize remaining audio
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()

        // Cancel result processing
        transcriptionTask?.cancel()
        transcriptionTask = nil

        // Flush any remaining currentText as a final segment
        if !currentText.isEmpty {
            segments.append(LiveCaptionSegment(
                id: UUID(),
                text: currentText,
                timestamp: Date.timeIntervalSinceReferenceDate,
                isFinal: true
            ))
            currentText = ""
        }

        // Build draft transcript from all segments
        let draft = segments.isEmpty ? nil : segments.map(\.text).joined(separator: " ")

        // Clean up
        analyzer = nil
        transcriber = nil
        bufferConverter = nil
        analyzerFormat = nil
        inputContinuation = nil
        lastResultRangeStart = .zero

        return draft
    }

    /// Reset all state (on cancel or new recording)
    func reset() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        inputContinuation?.finish()
        inputContinuation = nil
        analyzer = nil
        transcriber = nil
        bufferConverter = nil
        analyzerFormat = nil
        currentText = ""
        segments = []
        isTranscribing = false
        retryCount = 0
        lastResultRangeStart = .zero
    }

    // MARK: - Contextual Biasing

    /// Apply biblical terminology context to improve transcription accuracy.
    /// Uses AnalysisContext.contextualStrings to bias recognition toward biblical terms.
    private func applyBiblicalContext(to analyzer: SpeechAnalyzer) async {
        let context = AnalysisContext()
        context.contextualStrings = [
            AnalysisContext.ContextualStringsTag("vocabulary"):
                SermonConfiguration.biblicalContextualStrings
        ]

        do {
            try await analyzer.setContext(context)
        } catch {
            // Non-fatal: transcription continues without biasing
            print("[LiveTranscriptionService] Failed to apply biblical context: \(error.localizedDescription)")
        }
    }

    // MARK: - Result Handling

    private func handleTranscriptionResult(_ result: DictationTranscriber.Result) {
        let text = String(result.text.characters)
        guard !text.isEmpty else { return }

        let rangeStart = result.range.start

        // When a result arrives with a later start time, the previous
        // currentText is effectively finalized (the recognizer moved on).
        if !currentText.isEmpty && CMTimeCompare(rangeStart, lastResultRangeStart) > 0 {
            let segment = LiveCaptionSegment(
                id: UUID(),
                text: currentText,
                timestamp: Date.timeIntervalSinceReferenceDate,
                isFinal: true
            )
            segments.append(segment)

            // Cap segments at max (LRU eviction of oldest)
            if segments.count > SermonConfiguration.maxLiveCaptionSegments {
                segments.removeFirst(segments.count - SermonConfiguration.maxLiveCaptionSegments)
            }
        }

        // Update volatile text with latest result
        currentText = text
        lastResultRangeStart = rangeStart
    }

    private func handleTranscriptionError(_ error: Error, recordingFormat: AVAudioFormat) async {
        guard retryCount < SermonConfiguration.maxRecognitionRetries else {
            isTranscribing = false
            return
        }

        retryCount += 1
        let delay = SermonConfiguration.recognitionRetryBaseDelaySeconds * pow(2, Double(retryCount - 1))

        try? await Task.sleep(for: .seconds(delay))
        guard !Task.isCancelled else { return }

        do {
            try await startTranscriptionInternal(recordingFormat: recordingFormat)
        } catch {
            isTranscribing = false
        }
    }
}
