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
    private var supportedLocale: Locale?
    private var retryCount: Int = 0
    private var lastResultRangeStart: CMTime = .zero
    private var bufferFeedCount: Int = 0

    // MARK: - Initialization

    private init() {
        // Availability check is async — callers must invoke checkAvailability()
    }

    /// Check device + locale support. Must be called before use.
    func checkAvailability() async {
        let supported = await DictationTranscriber.supportedLocale(equivalentTo: .current)
        supportedLocale = supported
        isAvailable = supported != nil
        print("[LiveTranscriptionService] Supported locale: \(supported?.identifier ?? "none")")
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

    /// Check if the language model for the supported locale is installed
    func checkLanguageModelInstalled() async -> Bool {
        guard let locale = supportedLocale else { return false }
        let installed = await DictationTranscriber.installedLocales
        let found = installed.contains(where: { $0.identifier == locale.identifier })
        print("[LiveTranscriptionService] Installed locales: \(installed.map(\.identifier)), need: \(locale.identifier), found: \(found)")
        return found
    }

    /// Install language assets for the supported locale.
    /// Called from Settings preflight, NOT during recording start.
    func installLanguageAssets(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard let locale = supportedLocale else {
            throw SermonError.speechRecognitionUnavailable
        }

        // Create a temporary transcriber instance for asset management
        let tempTranscriber = DictationTranscriber(
            locale: locale,
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
        guard let locale = supportedLocale else {
            throw SermonError.speechRecognitionUnavailable
        }

        // Create DictationTranscriber using the exact supported locale
        // progressiveLongDictation: volatile results + punctuation for sermons/lectures
        let newTranscriber = DictationTranscriber(
            locale: locale,
            preset: .progressiveLongDictation
        )
        transcriber = newTranscriber

        // Ensure language assets are allocated for this transcriber
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [newTranscriber]) {
            print("[LiveTranscriptionService] Installing language assets for \(locale.identifier)...")
            try await request.downloadAndInstall()
            print("[LiveTranscriptionService] Language assets installed")
        }

        // Create SpeechAnalyzer with transcriber module
        let newAnalyzer = SpeechAnalyzer(modules: [newTranscriber])
        analyzer = newAnalyzer

        // Get the best audio format compatible with the transcriber
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [newTranscriber]
        )

        // Create converter from recording format to analyzer format
        if let targetFormat = analyzerFormat, targetFormat != recordingFormat {
            bufferConverter = AVAudioConverter(from: recordingFormat, to: targetFormat)
            print("[LiveTranscriptionService] Format conversion: \(recordingFormat) → \(targetFormat)")
        } else {
            bufferConverter = nil
            print("[LiveTranscriptionService] No format conversion needed (recording format matches analyzer)")
        }

        // Create input stream
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        // Start analyzer
        try await newAnalyzer.start(inputSequence: stream)

        isTranscribing = true
        bufferFeedCount = 0
        print("[LiveTranscriptionService] Analyzer started, awaiting results...")

        // Launch result processing task
        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in newTranscriber.results {
                    guard !Task.isCancelled else { break }
                    await self.handleTranscriptionResult(result)
                }
                print("[LiveTranscriptionService] Results sequence ended normally")
            } catch {
                print("[LiveTranscriptionService] Results sequence threw: \(error)")
                guard !Task.isCancelled else { return }
                await self.handleTranscriptionError(error, recordingFormat: recordingFormat)
            }
        }
    }

    /// Feed an audio buffer from the recording service
    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard isTranscribing else { return }

        let inputBuffer: AVAudioPCMBuffer
        if let targetFormat = analyzerFormat, targetFormat != buffer.format {
            // Manual format conversion (same sample rate, Float32 → Int16)
            guard let converted = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: buffer.frameLength
            ) else { return }

            if let srcFloat = buffer.floatChannelData?[0],
               let dstInt16 = converted.int16ChannelData?[0] {
                // Direct Float32 → Int16 sample conversion
                let count = Int(buffer.frameLength)
                for i in 0..<count {
                    let clamped = max(-1.0, min(1.0, srcFloat[i]))
                    dstInt16[i] = Int16(clamped * 32767.0)
                }
                converted.frameLength = buffer.frameLength
            } else {
                // Fallback: use AVAudioConverter for non-trivial conversions
                guard let converter = bufferConverter else { return }
                var error: NSError?
                var hasData = true
                converter.convert(to: converted, error: &error) { _, outStatus in
                    if hasData {
                        hasData = false
                        outStatus.pointee = .haveData
                        return buffer
                    }
                    outStatus.pointee = .noDataNow
                    return nil
                }
                guard error == nil, converted.frameLength > 0 else { return }
            }

            inputBuffer = converted
        } else {
            inputBuffer = buffer
        }

        inputContinuation?.yield(AnalyzerInput(buffer: inputBuffer))

        bufferFeedCount += 1
        if bufferFeedCount == 1 || bufferFeedCount == 10 || bufferFeedCount == 50 {
            // Log buffer info + RMS to verify audio data is non-silent
            var rms: Float = 0
            if let int16Data = inputBuffer.int16ChannelData?[0] {
                var sum: Float = 0
                for i in 0..<Int(inputBuffer.frameLength) {
                    let sample = Float(int16Data[i]) / 32768.0
                    sum += sample * sample
                }
                rms = sqrtf(sum / Float(inputBuffer.frameLength))
            } else if let floatData = inputBuffer.floatChannelData?[0] {
                var sum: Float = 0
                for i in 0..<Int(inputBuffer.frameLength) {
                    sum += floatData[i] * floatData[i]
                }
                rms = sqrtf(sum / Float(inputBuffer.frameLength))
            }
            print("[LiveTranscriptionService] Fed buffer #\(bufferFeedCount): \(inputBuffer.frameLength) frames, format=\(inputBuffer.format), rms=\(String(format: "%.4f", rms)), time=\(time.sampleTime)@\(time.sampleRate)Hz")
        }

        // Warn if significant audio fed with no results
        if bufferFeedCount == 100 && segments.isEmpty && currentText.isEmpty {
            print("[LiveTranscriptionService] ⚠️ 100 buffers fed (~10s) with no transcription results")
        }
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
        bufferFeedCount = 0
        supportedLocale = nil
    }

    // MARK: - Result Handling

    private func handleTranscriptionResult(_ result: DictationTranscriber.Result) {
        let text = String(result.text.characters)
        guard !text.isEmpty else { return }

        if segments.isEmpty && currentText.isEmpty {
            print("[LiveTranscriptionService] First result received: \"\(text.prefix(60))\"")
        }

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
        print("[LiveTranscriptionService] Error: \(error.localizedDescription), retry \(retryCount)/\(SermonConfiguration.maxRecognitionRetries)")
        guard retryCount < SermonConfiguration.maxRecognitionRetries else {
            print("[LiveTranscriptionService] Max retries exhausted, stopping transcription")
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
