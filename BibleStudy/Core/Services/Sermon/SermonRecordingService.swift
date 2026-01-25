import Foundation
import AVFoundation
import Combine

// MARK: - Recording State
enum RecordingState: Equatable, Sendable {
    case idle
    case preparing
    case recording
    case paused
    case stopping
    case error(String)

    var isActive: Bool {
        self == .recording || self == .paused
    }
}

// MARK: - Recording Configuration
struct RecordingConfiguration: Sendable {
    /// Target duration per chunk in seconds (10-15 minutes recommended)
    let chunkDurationSeconds: TimeInterval

    /// Recording settings dictionary for AVAudioRecorder
    var settings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,              // 16kHz - optimal for speech
            AVNumberOfChannelsKey: 1,            // Mono
            AVEncoderBitRateKey: 32000,          // 32kbps - ~14MB/hour, well under 25MB limit
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
    }

    /// Estimated bytes per minute at current settings (~240KB/min at 32kbps)
    var estimatedBytesPerMinute: Int { SermonConfiguration.estimatedBytesPerMinute }

    /// Maximum file size in bytes (25MB Whisper limit)
    static let maxChunkSize: Int = SermonConfiguration.maxChunkFileSizeBytes

    // nonisolated(unsafe) allows use as default parameter in @MainActor function
    nonisolated(unsafe) static let `default` = RecordingConfiguration(
        chunkDurationSeconds: SermonConfiguration.chunkDurationSeconds
    )

    nonisolated(unsafe) static let highQuality = RecordingConfiguration(
        chunkDurationSeconds: SermonConfiguration.highQualityChunkDurationSeconds
    )

    init(chunkDurationSeconds: TimeInterval) {
        self.chunkDurationSeconds = chunkDurationSeconds
    }
}

// MARK: - Sermon Recording Service
// Manages in-app audio recording with chunked output for Whisper API compatibility

@MainActor
@Observable
final class SermonRecordingService: NSObject, Sendable {
    // MARK: - Singleton
    static let shared = SermonRecordingService()

    // MARK: - State
    private(set) var state: RecordingState = .idle
    private(set) var currentDuration: TimeInterval = 0
    private(set) var currentChunkIndex: Int = 0
    private(set) var audioLevel: Float = 0  // 0-1 normalized for waveform

    // MARK: - Configuration
    private(set) var configuration: RecordingConfiguration = .default

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var chunkTimer: Timer?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var currentSermonId: UUID?
    private var outputDirectory: URL?

    // Metering callback
    private var levelCallback: ((Float) -> Void)?

    // Chunk completion callbacks
    private var onChunkCompleted: ((URL, Int) -> Void)?
    private var onRecordingCompleted: (([URL]) -> Void)?

    // Track completed chunks
    private var completedChunkURLs: [URL] = []

    // MARK: - Computed Properties

    var isRecording: Bool {
        state == .recording
    }

    var isPaused: Bool {
        state == .paused
    }

    var formattedDuration: String {
        let hours = Int(currentDuration) / 3600
        let minutes = (Int(currentDuration) % 3600) / 60
        let seconds = Int(currentDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentChunkDuration: TimeInterval {
        guard let recorder = audioRecorder else { return 0 }
        return recorder.currentTime
    }

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Permission

    /// Request microphone permission
    /// Returns true if permission is granted
    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            let status = AVAudioApplication.shared.recordPermission

            switch status {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await AVAudioApplication.requestRecordPermission()
            @unknown default:
                return false
            }
        } else {
            // Fallback for iOS 16 and earlier
            let status = AVAudioSession.sharedInstance().recordPermission

            switch status {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
    }

    // MARK: - Recording Control

    /// Start recording a new sermon
    /// - Parameters:
    ///   - sermonId: UUID of the sermon being recorded
    ///   - configuration: Recording settings (default optimized for Whisper)
    ///   - onChunkCompleted: Called when each chunk finishes
    ///   - onRecordingCompleted: Called when recording stops with all chunk URLs
    /// - Returns: URL of the output directory
    func startRecording(
        sermonId: UUID,
        configuration: RecordingConfiguration = .default,
        onChunkCompleted: ((URL, Int) -> Void)? = nil,
        onRecordingCompleted: (([URL]) -> Void)? = nil
    ) async throws -> URL {
        // Check permission
        guard await requestMicrophonePermission() else {
            state = .error("Microphone permission denied")
            throw SermonError.microphonePermissionDenied
        }

        state = .preparing
        self.configuration = configuration
        self.currentSermonId = sermonId
        self.onChunkCompleted = onChunkCompleted
        self.onRecordingCompleted = onRecordingCompleted
        self.completedChunkURLs = []
        self.currentChunkIndex = 0
        self.currentDuration = 0

        // Create output directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sermonDirectory = documentsURL
            .appendingPathComponent("Sermons", isDirectory: true)
            .appendingPathComponent(sermonId.uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: sermonDirectory, withIntermediateDirectories: true)
        self.outputDirectory = sermonDirectory

        // Claim audio session for recording (highest priority - will override playback)
        guard AudioService.shared.pushAudioSession(mode: .sermonRecording, owner: "SermonRecordingService") else {
            state = .error("Failed to configure audio session for recording")
            throw SermonError.recordingFailed("Audio session configuration failed")
        }

        // Start first chunk
        try startNewChunk()

        state = .recording
        recordingStartTime = Date()

        // Start duration timer
        startDurationTimer()

        // Start level metering
        startLevelMetering()

        return sermonDirectory
    }

    /// Pause recording
    func pauseRecording() {
        guard state == .recording else { return }

        audioRecorder?.pause()
        chunkTimer?.invalidate()
        chunkTimer = nil
        state = .paused
    }

    /// Resume recording after pause
    func resumeRecording() {
        guard state == .paused else { return }

        audioRecorder?.record()
        scheduleChunkTimer()
        state = .recording
    }

    /// Stop recording and finalize all chunks
    /// Returns array of chunk URLs
    func stopRecording() -> [URL] {
        guard state.isActive else { return completedChunkURLs }

        state = .stopping

        // Stop timers
        chunkTimer?.invalidate()
        chunkTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil

        // Stop and finalize current chunk
        if let recorder = audioRecorder {
            recorder.stop()
            let url = recorder.url
            if FileManager.default.fileExists(atPath: url.path) {
                completedChunkURLs.append(url)
            }
        }
        audioRecorder = nil

        // Release audio session claim (reverts to prior mode, e.g., Bible playback)
        AudioService.shared.popAudioSession(owner: "SermonRecordingService")

        state = .idle

        // Notify completion
        onRecordingCompleted?(completedChunkURLs)

        let chunks = completedChunkURLs
        completedChunkURLs = []
        return chunks
    }

    /// Cancel recording and delete all chunks
    func cancelRecording() {
        guard state.isActive else { return }

        // Stop recording
        audioRecorder?.stop()
        audioRecorder = nil
        chunkTimer?.invalidate()
        chunkTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil

        // Delete all chunks
        for url in completedChunkURLs {
            try? FileManager.default.removeItem(at: url)
        }

        // Delete output directory if empty
        if let directory = outputDirectory {
            try? FileManager.default.removeItem(at: directory)
        }

        completedChunkURLs = []
        state = .idle

        // Release audio session claim
        AudioService.shared.popAudioSession(owner: "SermonRecordingService")
    }

    /// Add a bookmark at the current timestamp
    /// Returns the timestamp in seconds from start
    func addBookmark() -> TimeInterval {
        return currentDuration
    }

    // MARK: - Level Metering

    /// Start continuous audio level metering
    /// - Parameter onLevel: Callback with normalized level (0-1)
    func startMetering(onLevel: @escaping (Float) -> Void) {
        levelCallback = onLevel
    }

    /// Stop level metering
    func stopMetering() {
        levelCallback = nil
    }

    // MARK: - Private Methods

    private func startNewChunk() throws {
        // Generate chunk filename
        guard let directory = outputDirectory else {
            throw SermonError.recordingFailed("No output directory")
        }

        let chunkFilename = String(format: "chunk_%03d.m4a", currentChunkIndex)
        let chunkURL = directory.appendingPathComponent(chunkFilename)

        // Create recorder
        let recorder = try AVAudioRecorder(url: chunkURL, settings: configuration.settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true

        guard recorder.prepareToRecord() else {
            throw SermonError.recordingFailed("Failed to prepare recorder")
        }

        guard recorder.record() else {
            throw SermonError.recordingFailed("Failed to start recording")
        }

        audioRecorder = recorder

        // Schedule chunk timer
        scheduleChunkTimer()

        print("[SermonRecordingService] Started chunk \(currentChunkIndex) at \(chunkURL.lastPathComponent)")
    }

    private func scheduleChunkTimer() {
        chunkTimer?.invalidate()

        // Calculate remaining time for this chunk
        let elapsed = audioRecorder?.currentTime ?? 0
        let remaining = configuration.chunkDurationSeconds - elapsed

        guard remaining > 0 else {
            rotateChunk()
            return
        }

        chunkTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rotateChunk()
            }
        }
    }

    private func rotateChunk() {
        guard state == .recording else { return }

        // Stop current chunk
        guard let recorder = audioRecorder else { return }
        recorder.stop()

        let completedURL = recorder.url
        if FileManager.default.fileExists(atPath: completedURL.path) {
            completedChunkURLs.append(completedURL)
            onChunkCompleted?(completedURL, currentChunkIndex)
            print("[SermonRecordingService] Completed chunk \(currentChunkIndex): \(completedURL.lastPathComponent)")
        }

        // Start next chunk
        currentChunkIndex += 1
        do {
            try startNewChunk()
        } catch {
            state = .error("Failed to start new chunk: \(error.localizedDescription)")
            print("[SermonRecordingService] Error starting new chunk: \(error)")
        }
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()

        // Update duration every 0.1 seconds
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            // Check state synchronously, then update on main actor
            Task { @MainActor [weak self] in
                guard let self, self.state == .recording, self.recordingStartTime != nil else { return }

                // Total duration is time since start minus any paused time
                let chunkTime = self.audioRecorder?.currentTime ?? 0
                let previousChunksDuration = Double(self.currentChunkIndex) * self.configuration.chunkDurationSeconds
                self.currentDuration = previousChunksDuration + chunkTime
            }
        }
    }

    private func startLevelMetering() {
        levelTimer?.invalidate()

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let recorder = self.audioRecorder, self.state == .recording else { return }

                recorder.updateMeters()

                // Get average power and convert to 0-1 range
                // AVAudioRecorder returns dB from -160 to 0
                let averagePower = recorder.averagePower(forChannel: 0)

                // Normalize: -60dB (quiet) to 0dB (loud) -> 0 to 1
                let minDb: Float = -60
                let normalizedLevel = max(0, (averagePower - minDb) / -minDb)
                let smoothedLevel = normalizedLevel * normalizedLevel // Square for better visual response

                self.audioLevel = smoothedLevel
                self.levelCallback?(smoothedLevel)
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension SermonRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            if !flag {
                print("[SermonRecordingService] Recording finished unsuccessfully")
                self.state = .error("Recording failed")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let errorMessage = error?.localizedDescription ?? "Unknown encoding error"
            print("[SermonRecordingService] Encode error: \(errorMessage)")
            self.state = .error(errorMessage)
        }
    }
}

// MARK: - Waveform Helpers
extension SermonRecordingService {
    /// Generate downsampled waveform samples from recorded chunk
    /// - Parameters:
    ///   - url: URL of the audio chunk
    ///   - sampleCount: Number of samples to return (default 100)
    /// - Returns: Array of normalized amplitude values (0-1)
    static func generateWaveformSamples(from url: URL, sampleCount: Int = 100) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = UInt32(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw SermonError.fileCorrupted
        }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData?[0] else {
            throw SermonError.fileCorrupted
        }

        let framesPerSample = Int(frameCount) / sampleCount
        var samples: [Float] = []

        for i in 0..<sampleCount {
            let startFrame = i * framesPerSample
            let endFrame = min(startFrame + framesPerSample, Int(frameCount))

            var sum: Float = 0
            for frame in startFrame..<endFrame {
                sum += abs(channelData[frame])
            }

            let average = sum / Float(endFrame - startFrame)
            samples.append(min(1.0, average * 2)) // Normalize and cap at 1.0
        }

        return samples
    }
}
