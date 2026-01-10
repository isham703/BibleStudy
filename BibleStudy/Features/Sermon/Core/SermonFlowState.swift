import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
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

    private var recordingTask: Task<Void, Never>?
    private var processingTask: Task<Void, Never>?
    private var meteringTask: Task<Void, Never>?
    private var progressStreamTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {}

    // MARK: - Computed Properties

    var canStartRecording: Bool {
        phase == .input
    }

    var canStopRecording: Bool {
        phase == .recording && isRecording
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var hasSermon: Bool {
        currentSermon != nil
    }

    var isProcessing: Bool {
        if case .processing = phase { return true }
        return false
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
        guard canStopRecording else { return }

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
            // Validate file
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
            let fileSize = resourceValues.fileSize ?? 0
            let maxSize = 500 * 1024 * 1024 // 500 MB

            guard fileSize <= maxSize else {
                throw SermonError.fileTooLarge(maxMB: 500)
            }

            // Check audio format
            let supportedTypes: Set<UTType> = [.mp3, .mpeg4Audio, .wav, .audio]
            if let contentType = resourceValues.contentType,
               !supportedTypes.contains(where: { contentType.conforms(to: $0) }) {
                throw SermonError.unsupportedAudioFormat(contentType.identifier)
            }

            // Get audio duration
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)

            // Create sermon record
            let sermon = Sermon(
                userId: userId,
                title: title.isEmpty ? url.deletingPathExtension().lastPathComponent : title,
                speakerName: speakerName.isEmpty ? nil : speakerName,
                recordedAt: Date(),
                durationSeconds: Int(durationSeconds)
            )
            currentSermon = sermon

            // Copy file to local storage
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let sermonDir = documentsDir.appendingPathComponent("Sermons/\(sermon.id.uuidString)")
            try FileManager.default.createDirectory(at: sermonDir, withIntermediateDirectories: true)

            let localURL = sermonDir.appendingPathComponent("audio.m4a")

            // If file needs conversion, handle that; otherwise just copy
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                try FileManager.default.copyItem(at: url, to: localURL)
            }

            // Create chunk record
            let chunk = SermonAudioChunk(
                sermonId: sermon.id,
                chunkIndex: 0,
                startOffsetSeconds: 0,
                durationSeconds: durationSeconds,
                localPath: localURL.path,
                fileSize: fileSize
            )
            audioChunks = [chunk]

            HapticService.shared.success()

            // Start processing
            await processRecording(chunkURLs: [localURL])

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

        processingTask = Task { @MainActor in
            do {
                // Create chunk records
                var chunks: [SermonAudioChunk] = []
                var offset: Double = 0

                for (index, url) in chunkURLs.enumerated() {
                    let asset = AVAsset(url: url)
                    let duration = try await asset.load(.duration)
                    let durationSeconds = CMTimeGetSeconds(duration)

                    // Generate waveform samples
                    let waveform = try await SermonRecordingService.generateWaveformSamples(
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

                // Subscribe to progress stream (replaces callback registration)
                self.startProgressStream(for: sermon.id)

                // Start processing
                await processingQueue.enqueue(sermonId: sermon.id)

                // Wait for completion with timeout (30 minutes max for long sermons)
                let pollingInterval: Duration = .milliseconds(500)
                let maxPollingIterations = 3600  // 30 minutes at 500ms intervals
                var iterations = 0

                while iterations < maxPollingIterations {
                    try await Task.sleep(for: pollingInterval)
                    guard !Task.isCancelled else { break }
                    iterations += 1

                    if let job = await processingQueue.getStatus(sermonId: sermon.id) {
                        if job.isComplete {
                            break
                        }
                        if job.transcriptionStatus == .failed {
                            throw SermonError.transcriptionFailed(sermon.transcriptionError ?? "Unknown error")
                        }
                        if job.studyGuideStatus == .failed {
                            throw SermonError.studyGuideGenerationFailed(sermon.studyGuideError ?? "Unknown error")
                        }
                    }
                }

                // Check if we timed out
                if iterations >= maxPollingIterations {
                    throw SermonError.processingTimeout
                }

                // Cancel progress stream
                self.stopProgressStream()

                // Load completed data
                await loadSermonData(sermonId: sermon.id)

                phase = .viewing
                HapticService.shared.success()

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
    private func startProgressStream(for sermonId: UUID) {
        progressStreamTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            let stream = self.processingQueue.progressStream(for: sermonId)
            for await update in stream {
                guard !Task.isCancelled else { break }
                self.updateProcessingProgress(job: update.job, progress: update.progress)
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
        meteringTask = Task { @MainActor in
            recordingService.startMetering { [weak self] level in
                Task { @MainActor [weak self] in
                    self?.currentAudioLevel = level
                    self?.audioLevels.append(level)

                    // Keep last 100 samples for waveform display
                    if (self?.audioLevels.count ?? 0) > 100 {
                        self?.audioLevels.removeFirst()
                    }
                }
            }
        }
    }

    private func stopMetering() {
        meteringTask?.cancel()
        meteringTask = nil
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
        if let sermon = currentSermon, !audioChunks.isEmpty {
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
        recordingTask?.cancel()
        processingTask?.cancel()
        meteringTask?.cancel()
        stopProgressStream()

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

        if currentTranscript != nil && currentStudyGuide != nil {
            phase = .viewing
        } else if sermon.transcriptionStatus == .running || sermon.studyGuideStatus == .running {
            phase = .processing(.transcribing(progress: 0.5, chunk: 1, total: 1))

            // Subscribe to progress stream (replaces callback registration)
            startProgressStream(for: sermon.id)
        } else if sermon.transcriptionStatus == .failed || sermon.studyGuideStatus == .failed {
            handleError(.transcriptionFailed(sermon.transcriptionError ?? "Processing failed"))
        }
    }
}
