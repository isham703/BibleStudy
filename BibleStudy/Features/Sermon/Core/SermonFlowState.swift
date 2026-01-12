import SwiftUI
import AVFoundation
import Auth
import Supabase
@preconcurrency import GRDB

// MARK: - Sermon Flow Phase

enum SermonFlowPhase: Equatable {
    case input
    case recording
    case importing
    case processing(ProcessingStep)
    case viewing
    case error(SermonError)

    static func == (lhs: SermonFlowPhase, rhs: SermonFlowPhase) -> Bool {
        switch (lhs, rhs) {
        case (.input, .input): return true
        case (.recording, .recording): return true
        case (.importing, .importing): return true
        case (.processing(let a), .processing(let b)): return a == b
        case (.viewing, .viewing): return true
        case (.error, .error): return true
        default: return false
        }
    }
}

// MARK: - Processing Step

enum ProcessingStep: Equatable {
    case uploading(progress: Double)
    case transcribing(progress: Double, chunk: Int, total: Int)
    case moderating
    case analyzing
    case saving

    var displayName: String {
        switch self {
        case .uploading: return "Uploading audio..."
        case .transcribing(_, let chunk, let total):
            if total > 1 {
                return "Transcribing (chunk \(chunk) of \(total))..."
            }
            return "Transcribing audio..."
        case .moderating: return "Reviewing content..."
        case .analyzing: return "Generating study guide..."
        case .saving: return "Saving..."
        }
    }

    var progress: Double {
        switch self {
        case .uploading(let p): return 0.0 + p * 0.2
        case .transcribing(let p, _, _): return 0.2 + p * 0.5
        case .moderating: return 0.75
        case .analyzing: return 0.85
        case .saving: return 0.95
        }
    }

    var isComplete: Bool {
        switch self {
        case .saving: return progress >= 0.95
        default: return false
        }
    }
}

// MARK: - Sermon Flow State
// Observable state manager for the sermon recording/import flow

@MainActor
@Observable
final class SermonFlowState {
    // MARK: - Constants

    static let minimumRecordingDuration: TimeInterval = 30

    // MARK: - Core State

    var phase: SermonFlowPhase = .input
    var title: String = ""
    var speakerName: String = ""

    // MARK: - Recording State

    var isRecording: Bool = false
    var isPaused: Bool = false
    var recordingDuration: TimeInterval = 0
    var audioLevels: [Float] = []
    var currentAudioLevel: Float = 0

    // MARK: - Sermon Data

    var currentSermon: Sermon?
    var currentTranscript: SermonTranscript?
    var currentStudyGuide: SermonStudyGuide?
    var audioChunks: [SermonAudioChunk] = []

    // MARK: - Processing State

    var processingProgress: Double = 0
    var processingStep: ProcessingStep = .uploading(progress: 0)

    // MARK: - Error State

    var error: SermonError?
    var showErrorAlert: Bool = false

    // MARK: - Services

    private let recordingService = SermonRecordingService.shared
    private let syncService = SermonSyncService.shared
    private let processingQueue = SermonProcessingQueue.shared
    private let repository = SermonRepository.shared
    private let supabase = SupabaseManager.shared

    // MARK: - Tasks

    private var processingTask: Task<Void, Never>?
    private var durationTimerTask: Task<Void, Never>?
    private var progressStreamTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {}

    // MARK: - Computed Properties

    var canStartRecording: Bool {
        phase == .input
    }

    var canStopRecording: Bool {
        phase == .recording && isRecording && meetsMinimumDuration
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var meetsMinimumDuration: Bool {
        recordingDuration >= Self.minimumRecordingDuration
    }

    var remainingTimeToMinimum: TimeInterval {
        max(0, Self.minimumRecordingDuration - recordingDuration)
    }

    var formattedRemainingTime: String {
        let seconds = Int(ceil(remainingTimeToMinimum))
        return "\(seconds)s"
    }

    var hasSermon: Bool {
        currentSermon != nil
    }

    var isProcessing: Bool {
        if case .processing = phase { return true }
        return false
    }

    // MARK: - Processing Time Estimates

    /// Time when processing started (for estimate calculations)
    private(set) var processingStartedAt: Date = Date()

    /// Estimated total processing time (~3 min per 10 min of audio)
    var estimatedProcessingTime: TimeInterval {
        guard let sermon = currentSermon else { return 0 }
        return (Double(sermon.durationSeconds) / 600.0) * 180.0
    }

    /// Estimated remaining processing time
    var estimatedRemainingTime: TimeInterval {
        let elapsed = Date().timeIntervalSince(processingStartedAt)
        return max(0, estimatedProcessingTime - elapsed)
    }

    /// Formatted remaining time for display
    var formattedEstimatedTime: String {
        let minutes = Int(estimatedRemainingTime) / 60
        if minutes < 2 {
            return "About 1 minute"
        }
        return "About \(minutes) minutes"
    }

    /// Chunk progress text during recording
    var chunkProgressText: String {
        guard !audioChunks.isEmpty else { return "" }
        return "Chunk \(audioChunks.count) saved"
    }

    // MARK: - Recording Actions

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        await recordingService.requestMicrophonePermission()
    }

    /// Start recording a new sermon
    func startRecording() async {
        guard canStartRecording else { return }

        // Ensure we have a valid session by refreshing it
        _ = try? await supabase.client.auth.refreshSession()

        guard let userId = supabase.currentUser?.id else {
            handleError(.notAuthenticated)
            return
        }

        // Check microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            handleError(.microphonePermissionDenied)
            return
        }

        // Create new sermon record
        let sermon = Sermon(
            userId: userId,
            title: title.isEmpty ? "Untitled Sermon" : title,
            speakerName: speakerName.isEmpty ? nil : speakerName,
            recordedAt: Date()
        )
        currentSermon = sermon

        // Start recording
        do {
            phase = .recording
            isRecording = true
            isPaused = false
            recordingDuration = 0
            audioLevels = []

            let configuration = RecordingConfiguration(
                chunkDurationSeconds: 600 // 10 minute chunks
            )

            _ = try await recordingService.startRecording(
                sermonId: sermon.id,
                configuration: configuration,
                onChunkCompleted: { [weak self] url, index in
                    Task { @MainActor [weak self] in
                        guard let self = self, let sermon = self.currentSermon else { return }
                        let startOffset = Double(index) * Double(configuration.chunkDurationSeconds)
                        let chunk = SermonAudioChunk(
                            sermonId: sermon.id,
                            chunkIndex: index,
                            startOffsetSeconds: startOffset,
                            localPath: url.path,
                            needsSync: true
                        )
                        self.audioChunks.append(chunk)
                    }
                },
                onRecordingCompleted: nil
            )

            // Start audio level metering
            startMetering()

            HapticService.shared.success()

        } catch {
            handleError(.recordingFailed(error.localizedDescription))
        }
    }

    /// Pause recording
    func pauseRecording() {
        guard phase == .recording, isRecording else { return }
        recordingService.pauseRecording()
        isPaused = true
        HapticService.shared.softTap()
    }

    /// Resume recording
    func resumeRecording() {
        guard phase == .recording, isPaused else { return }
        recordingService.resumeRecording()
        isPaused = false
        HapticService.shared.softTap()
    }

    /// Stop recording and start processing
    func stopRecording() async {
        guard phase == .recording, isRecording else { return }

        // Validate minimum duration before stopping
        guard meetsMinimumDuration else {
            handleError(.recordingTooShort(
                durationSeconds: Int(recordingDuration),
                minimumSeconds: Int(Self.minimumRecordingDuration)
            ))
            return
        }

        stopMetering()
        let chunkURLs = recordingService.stopRecording()

        isRecording = false
        isPaused = false

        HapticService.shared.mediumTap()

        // Process the recording
        await processRecording(chunkURLs: chunkURLs)
    }

    /// Cancel recording without saving
    func cancelRecording() {
        guard phase == .recording else { return }

        stopMetering()
        recordingService.cancelRecording()

        isRecording = false
        isPaused = false
        recordingDuration = 0
        currentSermon = nil
        audioChunks = []

        phase = .input
        HapticService.shared.warning()
    }

    /// Add a bookmark at the current timestamp
    func addBookmark(label: BookmarkLabel? = nil, note: String? = nil) async {
        // Ensure we have a valid session
        _ = try? await supabase.client.auth.refreshSession()

        guard let sermon = currentSermon,
              let userId = supabase.currentUser?.id else { return }

        let bookmark = SermonBookmark(
            userId: userId,
            sermonId: sermon.id,
            timestampSeconds: recordingDuration,
            note: note,
            label: label ?? .keyPoint,
            needsSync: true
        )

        do {
            try await syncService.addBookmark(bookmark)
            HapticService.shared.selectionChanged()
        } catch {
            print("[SermonFlowState] Failed to add bookmark: \(error)")
        }
    }

    // MARK: - Import Actions

    /// Import an audio file
    func importAudio(from url: URL) async {
        // Ensure we have a valid session by refreshing it
        _ = try? await supabase.client.auth.refreshSession()

        guard let userId = supabase.currentUser?.id else {
            handleError(.notAuthenticated)
            return
        }

        phase = .importing

        do {
            // Use SermonImportService for validation, chunking, and file handling
            let result = try await SermonImportService.shared.importAudioFile(
                url: url,
                userId: userId,
                title: title.isEmpty ? nil : title,
                speakerName: speakerName.isEmpty ? nil : speakerName
            )

            currentSermon = result.sermon
            audioChunks = result.chunks

            HapticService.shared.success()

            // Start processing
            await processRecording(chunkURLs: result.chunkURLs)

        } catch let sermonError as SermonError {
            handleError(sermonError)
        } catch {
            handleError(.importFailed(error.localizedDescription))
        }
    }

    // MARK: - Processing

    private func processRecording(chunkURLs: [URL]) async {
        guard let sermon = currentSermon else { return }

        phase = .processing(.uploading(progress: 0))
        processingProgress = 0
        processingStartedAt = Date()

        processingTask = Task { @MainActor in
            do {
                // Create chunk records
                var chunks: [SermonAudioChunk] = []
                var offset: Double = 0

                for (index, url) in chunkURLs.enumerated() {
                    let asset = AVURLAsset(url: url)
                    let duration = try await asset.load(.duration)
                    let durationSeconds = CMTimeGetSeconds(duration)

                    // Generate waveform samples
                    let waveform = try await WaveformGenerator.generateSamples(
                        from: url,
                        sampleCount: 100
                    )

                    let chunk = SermonAudioChunk(
                        sermonId: sermon.id,
                        chunkIndex: index,
                        startOffsetSeconds: offset,
                        durationSeconds: durationSeconds,
                        localPath: url.path,
                        waveformSamples: waveform,
                        needsSync: true
                    )
                    chunks.append(chunk)
                    offset += durationSeconds
                }
                audioChunks = chunks

                // Update sermon duration
                var updatedSermon = sermon
                updatedSermon.durationSeconds = Int(offset)
                currentSermon = updatedSermon

                // Save sermon and chunks to database
                try await syncService.createSermon(updatedSermon, chunks: chunks)

                // Upload chunks
                phase = .processing(.uploading(progress: 0))
                for (index, chunk) in chunks.enumerated() {
                    guard let localPath = chunk.localPath else {
                        throw SermonError.chunkNotFound
                    }
                    let data = try Data(contentsOf: URL(fileURLWithPath: localPath))
                    _ = try await syncService.uploadChunk(chunk, data: data)

                    let progress = Double(index + 1) / Double(chunks.count)
                    phase = .processing(.uploading(progress: progress))
                }

                // Enqueue for transcription and study guide
                phase = .processing(.transcribing(progress: 0, chunk: 1, total: chunks.count))

                // Subscribe to progress stream - handles completion/failure internally
                self.startProgressStream(for: sermon.id)

                // Start processing
                await processingQueue.enqueue(sermonId: sermon.id)

                // Set up timeout (30 minutes max for long sermons)
                let timeoutTask = Task {
                    try await Task.sleep(for: .seconds(30 * 60))
                    await MainActor.run { [weak self] in
                        self?.stopProgressStream()
                        self?.handleError(.processingTimeout)
                    }
                }

                // Wait for stream to complete (handles success/failure transitions)
                await progressStreamTask?.value
                timeoutTask.cancel()

            } catch let sermonError as SermonError {
                handleError(sermonError)
            } catch {
                handleError(.transcriptionFailed(error.localizedDescription))
            }
        }
    }

    private func updateProcessingProgress(job: SermonProcessingJob, progress: Double) {
        processingProgress = progress

        if progress < 0.2 {
            phase = .processing(.uploading(progress: progress / 0.2))
        } else if progress < 0.7 {
            let transcriptionProgress = (progress - 0.2) / 0.5
            let chunkIndex = Int(transcriptionProgress * Double(audioChunks.count)) + 1
            phase = .processing(.transcribing(
                progress: transcriptionProgress,
                chunk: min(chunkIndex, audioChunks.count),
                total: audioChunks.count
            ))
        } else if progress < 0.75 {
            phase = .processing(.moderating)
        } else if progress < 0.95 {
            phase = .processing(.analyzing)
        } else {
            phase = .processing(.saving)
        }
    }

    // MARK: - Load Sermon Data

    func loadSermonData(sermonId: UUID) async {
        if let sermon = await syncService.loadSermon(id: sermonId) {
            currentSermon = sermon
        }

        // Load transcript (via repository)
        do {
            currentTranscript = try loadTranscript(sermonId: sermonId)
        } catch {
            print("[SermonFlowState] Failed to load transcript: \(error)")
        }

        // Load study guide (via repository)
        do {
            currentStudyGuide = try loadStudyGuide(sermonId: sermonId)
        } catch {
            print("[SermonFlowState] Failed to load study guide: \(error)")
        }
    }

    private func loadTranscript(sermonId: UUID) throws -> SermonTranscript? {
        try repository.fetchTranscript(sermonId: sermonId)
    }

    private func loadStudyGuide(sermonId: UUID) throws -> SermonStudyGuide? {
        try repository.fetchStudyGuide(sermonId: sermonId)
    }

    // MARK: - Progress Stream Helpers

    /// Start listening to progress updates via AsyncStream
    /// Handles completion/failure internally - no polling needed
    private func startProgressStream(for sermonId: UUID) {
        progressStreamTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            let stream = self.processingQueue.progressStream(for: sermonId)

            var lastJob: SermonProcessingJob?

            for await update in stream {
                guard !Task.isCancelled else { break }
                lastJob = update.job
                self.updateProcessingProgress(job: update.job, progress: update.progress)
            }

            // Stream completed - handle final state
            guard !Task.isCancelled, let job = lastJob else { return }

            if job.isComplete {
                await self.loadSermonData(sermonId: sermonId)
                self.phase = .viewing
                HapticService.shared.success()
            } else if job.transcriptionStatus == .failed {
                self.handleError(.transcriptionFailed(self.currentSermon?.transcriptionError ?? "Unknown error"))
            } else if job.studyGuideStatus == .failed {
                self.handleError(.studyGuideGenerationFailed(self.currentSermon?.studyGuideError ?? "Unknown error"))
            }
        }
    }

    /// Stop listening to progress updates
    private func stopProgressStream() {
        progressStreamTask?.cancel()
        progressStreamTask = nil
    }

    // MARK: - Metering

    private func startMetering() {
        // Note: Callback is already dispatched to main thread by recordingService
        // No need for nested Task - we're already MainActor-isolated
        recordingService.startMetering { [weak self] level in
            guard let self = self else { return }
            self.currentAudioLevel = level
            self.audioLevels.append(level)

            // Keep last 100 samples for waveform display
            if self.audioLevels.count > 100 {
                self.audioLevels.removeFirst()
            }
        }

        // Start duration timer
        startDurationTimer()
    }

    private func stopMetering() {
        recordingService.stopMetering()
        stopDurationTimer()
    }

    private func startDurationTimer() {
        durationTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self = self, !Task.isCancelled else { break }
                // Only increment if recording and not paused
                if self.isRecording && !self.isPaused {
                    self.recordingDuration += 1
                }
            }
        }
    }

    private func stopDurationTimer() {
        durationTimerTask?.cancel()
        durationTimerTask = nil
    }

    // MARK: - Error Handling

    private func handleError(_ sermonError: SermonError) {
        error = sermonError
        phase = .error(sermonError)
        showErrorAlert = true
        HapticService.shared.warning()
    }

    func dismissError() {
        showErrorAlert = false
        if case .error = phase {
            phase = .input
        }
        error = nil
    }

    func retry() {
        dismissError()
        if currentSermon != nil, !audioChunks.isEmpty {
            // Retry processing
            Task {
                await processRecording(chunkURLs: audioChunks.compactMap {
                    $0.localPath.map { URL(fileURLWithPath: $0) }
                })
            }
        }
    }

    // MARK: - Reset

    func reset() {
        // Cancel all active tasks
        processingTask?.cancel()
        durationTimerTask?.cancel()
        stopProgressStream()
        recordingService.stopMetering()

        // Clear task references
        processingTask = nil
        durationTimerTask = nil

        // Reset all state
        phase = .input
        title = ""
        speakerName = ""
        isRecording = false
        isPaused = false
        recordingDuration = 0
        audioLevels = []
        currentAudioLevel = 0
        currentSermon = nil
        currentTranscript = nil
        currentStudyGuide = nil
        audioChunks = []
        processingProgress = 0
        error = nil
        showErrorAlert = false
    }

    // MARK: - View an existing sermon

    func loadExistingSermon(_ sermon: Sermon) async {
        currentSermon = sermon
        await loadSermonData(sermonId: sermon.id)

        // Check if still processing
        if sermon.transcriptionStatus == .running || sermon.studyGuideStatus == .running {
            phase = .processing(.transcribing(progress: 0.5, chunk: 1, total: 1))

            // Subscribe to progress stream (replaces callback registration)
            startProgressStream(for: sermon.id)
        } else if sermon.transcriptionStatus == .failed || sermon.studyGuideStatus == .failed {
            handleError(.transcriptionFailed(sermon.transcriptionError ?? "Processing failed"))
        } else {
            // Go to viewing phase - the UI will handle missing transcript/study guide gracefully
            phase = .viewing
        }
    }
}
