import Foundation
import AVFoundation
import Accelerate
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

    /// AAC output settings for file writing
    var outputSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Self.sampleRate,
            AVNumberOfChannelsKey: Int(Self.channelCount),
            AVEncoderBitRateKey: 32000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
    }

    /// Recording format: 16kHz mono Float32 (optimal for speech + analyzer)
    static let sampleRate: Double = 16000
    static let channelCount: AVAudioChannelCount = 1

    /// PCM processing format for the audio engine tap
    var processingFormat: AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: Self.channelCount,
            interleaved: false
        )!
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
// Manages in-app audio recording with chunked output for Whisper API compatibility.
// Uses AVAudioEngine to provide audio buffers for both file writing and
// live transcription (SpeechAnalyzer).

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
    private(set) var isSpeechDetected: Bool = false

    // MARK: - Configuration
    private(set) var configuration: RecordingConfiguration = .default

    // MARK: - Private Properties — Audio Engine
    private var audioEngine: AVAudioEngine?
    /// nonisolated(unsafe): Written on MainActor (openNewChunkFile, rotateChunk, stop/cancel).
    /// Read on audio render thread (processAudioBuffer). AVAudioFile.write is thread-safe;
    /// Optional reference reads are atomic on 64-bit ARM.
    private nonisolated(unsafe) var audioFile: AVAudioFile?
    private var audioConverter: AVAudioConverter?

    // MARK: - Private Properties — Timers & State
    private var chunkTimer: Timer?
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var lastPauseTime: Date?
    private var currentSermonId: UUID?
    private var outputDirectory: URL?
    private var chunkStartTime: TimeInterval = 0

    // MARK: - Voice Activity Detection
    private var speechHoldCounter: Int = 0

    // MARK: - Callbacks
    private var levelCallback: ((Float) -> Void)?
    var speechActivityCallback: ((Bool) -> Void)?
    /// nonisolated(unsafe): Set on MainActor (setBufferCallback).
    /// Read on audio render thread (processAudioBuffer). Copied to local before invocation.
    private nonisolated(unsafe) var bufferCallback: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
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
        guard state == .recording || state == .paused else { return 0 }
        return currentDuration - chunkStartTime
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupInterruptionObserver()
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

    // MARK: - Buffer Callback

    /// Set a callback to receive audio buffers (for live transcription)
    func setBufferCallback(_ callback: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?) {
        bufferCallback = callback
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
        self.pausedDuration = 0
        self.lastPauseTime = nil
        self.chunkStartTime = 0
        self.speechHoldCounter = 0
        self.isSpeechDetected = false

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

        // Create and configure audio engine
        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = configuration.processingFormat

        // Create converter from native input format to 16kHz mono Float32
        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
            state = .error("Failed to create audio converter")
            AudioService.shared.popAudioSession(owner: "SermonRecordingService")
            throw SermonError.recordingFailed("Audio format conversion not supported")
        }
        audioConverter = converter

        // Open first chunk file
        do {
            try openNewChunkFile()
        } catch {
            audioEngine = nil
            audioConverter = nil
            AudioService.shared.popAudioSession(owner: "SermonRecordingService")
            throw error
        }

        // Install tap on input node
        let bufferSize: AVAudioFrameCount = 4096
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: nativeFormat) {
            [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time, converter: converter, targetFormat: targetFormat)
        }

        // Start engine
        engine.prepare()
        try engine.start()

        state = .recording
        recordingStartTime = Date()

        // Start duration timer
        startDurationTimer()

        // Schedule chunk timer
        scheduleChunkTimer()

        print("[SermonRecordingService] Started recording with AVAudioEngine")

        return sermonDirectory
    }

    /// Pause recording
    func pauseRecording() {
        guard state == .recording else { return }

        audioEngine?.pause()
        chunkTimer?.invalidate()
        chunkTimer = nil
        lastPauseTime = Date()
        state = .paused
    }

    /// Resume recording after pause
    func resumeRecording() {
        guard state == .paused else { return }

        // Track paused duration
        if let pauseStart = lastPauseTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
            lastPauseTime = nil
        }

        do {
            try audioEngine?.start()
        } catch {
            state = .error("Failed to resume recording: \(error.localizedDescription)")
            print("[SermonRecordingService] Error resuming: \(error)")
            return
        }
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
        durationTimer?.invalidate()
        durationTimer = nil

        // Stop engine and remove tap
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil
        audioConverter = nil

        // Close current chunk file
        if let file = audioFile {
            let url = file.url
            audioFile = nil
            if FileManager.default.fileExists(atPath: url.path) {
                completedChunkURLs.append(url)
            }
        }

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

        // Stop engine
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil
        audioConverter = nil

        // Delete current in-progress chunk file before releasing handle
        if let file = audioFile {
            try? FileManager.default.removeItem(at: file.url)
        }
        audioFile = nil

        chunkTimer?.invalidate()
        chunkTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil

        // Delete completed chunks
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

    // MARK: - Audio Buffer Processing

    /// Called on the audio render thread for each captured buffer
    private nonisolated func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        time: AVAudioTime,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) {
        // Convert to 16kHz mono Float32
        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate
        )
        guard frameCapacity > 0 else { return }

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: frameCapacity
        ) else { return }

        var error: NSError?
        var hasData = true
        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            if hasData {
                hasData = false
                outStatus.pointee = .haveData
                return buffer
            }
            outStatus.pointee = .noDataNow
            return nil
        }

        guard error == nil, convertedBuffer.frameLength > 0 else { return }

        // Write to file (AVAudioFile write is thread-safe)
        try? self.audioFile?.write(from: convertedBuffer)

        // Compute RMS + voice activity detection
        updateLevelFromBuffer(convertedBuffer)

        // Forward to buffer callback (live transcription)
        let cb = self.bufferCallback
        if cb != nil {
            DispatchQueue.main.async {
                cb?(convertedBuffer, time)
            }
        }
    }

    /// Compute RMS level and voice activity from buffer (called on render thread)
    private nonisolated func updateLevelFromBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(buffer.frameLength))
        rms = sqrtf(rms)

        let normalized = min(1.0, rms * 5.0)
        let smoothed = normalized * normalized

        let rmsThreshold = SermonConfiguration.speechActivityRMSThreshold
        let silenceThreshold = SermonConfiguration.speechActivitySilenceThreshold
        let holdFrames = SermonConfiguration.speechActivityHoldFrames

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let wasSpeaking = self.isSpeechDetected

            if rms > rmsThreshold {
                self.speechHoldCounter = holdFrames
                self.isSpeechDetected = true
            } else if rms < silenceThreshold {
                if self.speechHoldCounter > 0 {
                    self.speechHoldCounter -= 1
                } else {
                    self.isSpeechDetected = false
                }
            }
            // In hysteresis zone (between thresholds): maintain current state

            self.audioLevel = smoothed
            self.levelCallback?(smoothed)

            if wasSpeaking != self.isSpeechDetected {
                self.speechActivityCallback?(self.isSpeechDetected)
            }
        }
    }

    // MARK: - Chunk Management

    private func openNewChunkFile() throws {
        guard let directory = outputDirectory else {
            throw SermonError.recordingFailed("No output directory")
        }

        let chunkFilename = String(format: "chunk_%03d.m4a", currentChunkIndex)
        let chunkURL = directory.appendingPathComponent(chunkFilename)

        // Create AVAudioFile for writing with AAC settings
        audioFile = try AVAudioFile(
            forWriting: chunkURL,
            settings: configuration.outputSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        print("[SermonRecordingService] Started chunk \(currentChunkIndex) at \(chunkFilename)")
    }

    private func scheduleChunkTimer() {
        chunkTimer?.invalidate()

        let elapsed = currentChunkDuration
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

        // Close current chunk file
        guard let file = audioFile else { return }
        let completedURL = file.url
        audioFile = nil

        if FileManager.default.fileExists(atPath: completedURL.path) {
            completedChunkURLs.append(completedURL)
            onChunkCompleted?(completedURL, currentChunkIndex)
            print("[SermonRecordingService] Completed chunk \(currentChunkIndex): \(completedURL.lastPathComponent)")
        }

        // Start next chunk
        currentChunkIndex += 1
        chunkStartTime = currentDuration
        do {
            try openNewChunkFile()
            scheduleChunkTimer()
        } catch {
            currentChunkIndex -= 1  // Revert increment on failure
            state = .error("Failed to start new chunk: \(error.localizedDescription)")
            print("[SermonRecordingService] Error starting new chunk: \(error)")
        }
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()

        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            Task { @MainActor [weak self] in
                guard let self, self.state == .recording, let startTime = self.recordingStartTime else { return }
                self.currentDuration = Date().timeIntervalSince(startTime) - self.pausedDuration
            }
        }
    }

    // MARK: - Audio Session Interruption

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            if state == .recording {
                pauseRecording()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && state == .paused {
                    resumeRecording()
                }
            }
        @unknown default:
            break
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
