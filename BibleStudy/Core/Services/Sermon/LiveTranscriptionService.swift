@preconcurrency import AVFoundation
import Speech
import CoreMedia
import Network

// MARK: - Live Caption Segment
// Individual recognized text segment from on-device or cloud speech recognition

struct LiveCaptionSegment: Identifiable, Sendable {
    let id: UUID
    let text: String
    let timestamp: TimeInterval
    let isFinal: Bool
    let source: CaptionSource

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: TimeInterval = Date.timeIntervalSinceReferenceDate,
        isFinal: Bool,
        source: CaptionSource = .apple
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isFinal = isFinal
        self.source = source
    }
}

// MARK: - Live Transcription Service
// Orchestrates live captioning providers (Apple on-device, Deepgram cloud).
// Handles automatic provider selection, fallback on network drop, and reconnection.
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
    private(set) var currentSource: CaptionSource?

    /// Whether cloud captions are available to switch back to (after reconnection)
    private(set) var isCloudReconnectAvailable: Bool = false

    // MARK: - Providers

    private var activeProvider: (any LiveCaptioningProvider)?
    private var appleProvider: AppleLiveCaptioningProvider?
    private var deepgramProvider: DeepgramLiveCaptioningProvider?

    // MARK: - Network Monitoring

    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "com.biblestudy.networkmonitor")
    private(set) var isNetworkAvailable: Bool = true

    // MARK: - State Management

    private var currentSermonTitle: String?
    private var recordingFormat: AVAudioFormat?
    private var contextHints: [String] = []
    private var sequenceCounter: UInt64 = 0

    // MARK: - Initialization

    private init() {}

    // MARK: - Availability Checks

    /// Check device + locale support. Must be called before use.
    func checkAvailability() async {
        // Check Apple provider availability
        let tempApple = AppleLiveCaptioningProvider()
        let appleAvailable = await tempApple.checkAvailability()

        // Check Deepgram API key is configured
        let deepgramKey = getDeepgramAPIKey()
        let deepgramConfigured = !deepgramKey.isEmpty

        // Service is available if at least one provider can work
        isAvailable = appleAvailable || deepgramConfigured
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
    /// - Parameters:
    ///   - recordingFormat: Audio format from the recording service
    ///   - sermonTitle: Optional sermon title for dynamic contextual biasing
    func startTranscription(recordingFormat: AVAudioFormat, sermonTitle: String? = nil) async throws {
        guard isAvailable else {
            throw SermonError.speechRecognitionUnavailable
        }

        guard authorizationStatus == .authorized else {
            throw SermonError.speechRecognitionDenied
        }

        self.currentSermonTitle = sermonTitle
        self.recordingFormat = recordingFormat
        self.sequenceCounter = 0
        self.segments = []
        self.currentText = ""
        self.isCloudReconnectAvailable = false

        // Build context hints for biblical terminology
        if let title = sermonTitle, !title.isEmpty {
            contextHints = BiblicalContextProvider.contextualStrings(forSermonTitle: title)
        } else {
            contextHints = SermonConfiguration.biblicalContextualStrings
        }

        // Start network monitoring
        startNetworkMonitoring()

        // Check user preference
        let preferOnDevice = UserDefaults.standard.bool(
            forKey: AppConfiguration.UserDefaultsKeys.preferOnDeviceCaptions
        )

        // Select initial provider based on network and preference
        let selectedSource = selectProvider(preferOnDevice: preferOnDevice)

        // Create and start provider
        do {
            try await startProvider(source: selectedSource)
        } catch {
            // Clean up network monitor if provider start fails
            stopNetworkMonitoring()
            throw error
        }
    }

    /// Feed an audio buffer from the recording service
    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard isTranscribing else { return }
        activeProvider?.feedAudioBuffer(buffer, at: time)
    }

    /// Stop transcription and return draft transcript text
    func stopTranscription() async -> String? {
        guard isTranscribing else { return nil }

        stopNetworkMonitoring()

        let finalText = await activeProvider?.stopTranscription()

        cleanup()

        // Build draft transcript from all segments
        let draft = segments.isEmpty ? finalText : segments.map(\.text).joined(separator: " ")

        return draft
    }

    /// Reset all state (on cancel or new recording)
    func reset() {
        stopNetworkMonitoring()
        activeProvider?.reset()
        cleanup()
    }

    /// Manually switch to cloud captions (user tapped reconnect banner)
    func switchToCloud() async throws {
        guard isCloudReconnectAvailable else { return }
        guard isNetworkAvailable else { return }

        isCloudReconnectAvailable = false

        // Add segment marker for source change
        addSourceChangeMarker(from: .apple, to: .deepgram)

        // Switch to Deepgram
        try await startProvider(source: .deepgram)
    }

    // MARK: - Provider Selection

    private func selectProvider(preferOnDevice: Bool) -> CaptionSource {
        let deepgramKey = getDeepgramAPIKey()
        print("[LiveTranscriptionService] Provider selection - preferOnDevice: \(preferOnDevice), networkAvailable: \(isNetworkAvailable), deepgramKeyPresent: \(!deepgramKey.isEmpty), keyLength: \(deepgramKey.count)")

        if preferOnDevice {
            return .apple
        }

        // Check if Deepgram is configured before selecting it
        if isNetworkAvailable && !deepgramKey.isEmpty {
            return .deepgram
        }

        return .apple
    }

    private func startProvider(source: CaptionSource) async throws {
        guard let format = recordingFormat else {
            throw CaptionProviderError.notAvailable
        }

        // Clean up existing provider
        await activeProvider?.stopTranscription()
        activeProvider = nil

        let provider: any LiveCaptioningProvider

        switch source {
        case .deepgram:
            let deepgramKey = getDeepgramAPIKey()
            print("[LiveTranscriptionService] Starting Deepgram provider, key length: \(deepgramKey.count)")
            guard !deepgramKey.isEmpty else {
                print("[LiveTranscriptionService] No Deepgram key - falling back to Apple")
                // Fall back to Apple if no Deepgram key
                try await startProvider(source: .apple)
                return
            }

            let deepgram = DeepgramLiveCaptioningProvider(apiKey: deepgramKey)
            deepgramProvider = deepgram
            provider = deepgram

        case .apple:
            print("[LiveTranscriptionService] Starting Apple on-device provider")
            let apple = AppleLiveCaptioningProvider()
            appleProvider = apple
            provider = apple
        }

        activeProvider = provider
        currentSource = source
        isTranscribing = true

        try await provider.startTranscription(
            recordingFormat: format,
            contextHints: contextHints,
            eventHandler: { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleProviderEvent(event)
                }
            }
        )
    }

    // MARK: - Event Handling

    private func handleProviderEvent(_ event: CaptionEvent) {
        switch event {
        case .transcript(let transcript):
            handleTranscript(transcript)

        case .stateChange(let state):
            handleStateChange(state)

        case .error(let error):
            handleProviderError(error)
        }
    }

    private func handleTranscript(_ transcript: CaptionTranscript) {
        currentText = transcript.text

        if transcript.isFinal {
            let segment = LiveCaptionSegment(
                id: transcript.id,
                text: transcript.text,
                timestamp: transcript.timestamp,
                isFinal: true,
                source: transcript.source
            )
            segments.append(segment)

            // LRU eviction
            if segments.count > SermonConfiguration.maxLiveCaptionSegments {
                segments.removeFirst(segments.count - SermonConfiguration.maxLiveCaptionSegments)
            }
        }
    }

    private func handleStateChange(_ state: CaptionProviderState) {
        switch state {
        case .idle:
            break
        case .initializing:
            break
        case .ready:
            break
        case .transcribing:
            isTranscribing = true
        case .reconnecting:
            // Deepgram is attempting to reconnect in background
            break
        case .failed(let message):
            print("[LiveTranscriptionService] Provider failed: \(message)")
        }
    }

    private func handleProviderError(_ error: CaptionProviderError) {
        print("[LiveTranscriptionService] Provider error: \(error.localizedDescription)")

        if error.shouldFallback && currentSource == .deepgram {
            // Network-related error from Deepgram - switch to Apple
            Task {
                await fallbackToApple()
            }
        }
    }

    // MARK: - Fallback Logic

    private func fallbackToApple() async {
        guard currentSource == .deepgram else { return }

        print("[LiveTranscriptionService] Falling back to Apple on-device captions")

        // Clear failed Deepgram provider reference
        deepgramProvider = nil

        // Add segment marker for source change
        addSourceChangeMarker(from: .deepgram, to: .apple)

        // Switch to Apple provider
        do {
            try await startProvider(source: .apple)

            // Start monitoring for reconnect opportunity
            startReconnectMonitoring()
        } catch {
            print("[LiveTranscriptionService] Fallback to Apple failed: \(error)")
            isTranscribing = false
        }
    }

    private func addSourceChangeMarker(from oldSource: CaptionSource, to newSource: CaptionSource) {
        sequenceCounter += 1

        // Empty segment marks source boundary
        let marker = LiveCaptionSegment(
            text: "",
            isFinal: true,
            source: newSource
        )
        segments.append(marker)
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let wasOnline = self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied

                // Handle network state changes
                if wasOnline && !self.isNetworkAvailable && self.currentSource == .deepgram {
                    // Network dropped while using Deepgram - will be handled by provider error
                    print("[LiveTranscriptionService] Network lost while using Deepgram")
                }

                if !wasOnline && self.isNetworkAvailable && self.currentSource == .apple {
                    // Network restored while using Apple - check Deepgram stability
                    self.checkDeepgramReconnectAvailable()
                }
            }
        }
        networkMonitor?.start(queue: networkQueue)
    }

    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    // MARK: - Reconnection

    private var reconnectStabilityTask: Task<Void, Never>?

    private func startReconnectMonitoring() {
        // Only monitor if we have Deepgram configured
        guard !getDeepgramAPIKey().isEmpty else { return }

        reconnectStabilityTask?.cancel()
        reconnectStabilityTask = Task { @MainActor [weak self] in
            // Wait for network to stabilize
            try? await Task.sleep(for: .seconds(DeepgramConfiguration.reconnectStabilitySeconds))

            guard !Task.isCancelled else { return }
            guard let self else { return }

            // Check if network is still available and we're still on Apple
            if self.isNetworkAvailable && self.currentSource == .apple {
                self.isCloudReconnectAvailable = true
                print("[LiveTranscriptionService] Cloud captions available - user can tap to switch back")
            }
        }
    }

    private func checkDeepgramReconnectAvailable() {
        // User preference
        let preferOnDevice = UserDefaults.standard.bool(
            forKey: AppConfiguration.UserDefaultsKeys.preferOnDeviceCaptions
        )
        guard !preferOnDevice else { return }

        // Start stability timer
        startReconnectMonitoring()
    }

    // MARK: - Cleanup

    private func cleanup() {
        reconnectStabilityTask?.cancel()
        reconnectStabilityTask = nil
        activeProvider = nil
        appleProvider = nil
        deepgramProvider = nil
        currentSource = nil
        isTranscribing = false
        currentText = ""
        segments = []
        recordingFormat = nil
        currentSermonTitle = nil
        contextHints = []
        sequenceCounter = 0
        isCloudReconnectAvailable = false
    }

    // MARK: - Configuration

    private func getDeepgramAPIKey() -> String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "DEEPGRAM_API_KEY") as? String else {
            return ""
        }
        return key
    }
}
