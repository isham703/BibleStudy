import Foundation
@preconcurrency import GRDB
import CryptoKit

// MARK: - Processing Job
// Represents a sermon processing job with its current state
struct SermonProcessingJob: Sendable {
    let sermonId: UUID
    var transcriptionStatus: SermonProcessingStatus
    var studyGuideStatus: SermonProcessingStatus
    var chunkStatuses: [ChunkStatus]

    struct ChunkStatus: Sendable {
        let chunkId: UUID
        let chunkIndex: Int
        var uploadStatus: ChunkUploadStatus
        var transcriptionStatus: SermonProcessingStatus
    }

    var needsTranscription: Bool {
        transcriptionStatus == .pending || transcriptionStatus == .failed
    }

    var needsStudyGuide: Bool {
        studyGuideStatus == .pending || studyGuideStatus == .failed
    }

    var isComplete: Bool {
        transcriptionStatus == .succeeded && studyGuideStatus == .succeeded
    }
}

// MARK: - Sermon Processing Queue
// Manages sermon processing jobs with resumability and bounded concurrency.
// Uses AsyncStream for progress updates (replaces callback dictionary).
// Uses ordered array for FIFO job ordering (replaces Set).

@MainActor
@Observable
final class SermonProcessingQueue {
    // MARK: - Singleton
    static let shared = SermonProcessingQueue()

    // MARK: - Dependencies
    private let transcriptionService = TranscriptionService.shared
    private let repository = SermonRepository.shared
    private let enrichmentService = SermonEnrichmentService()
    private let progressPublisher = SermonProgressPublisher.shared

    // MARK: - Configuration
    /// Maximum concurrent processing jobs (bounded parallelism)
    private let maxConcurrentJobs = 2

    // MARK: - State
    /// Currently processing job IDs (bounded by maxConcurrentJobs)
    private var processingJobIds: Set<UUID> = []
    /// Jobs awaiting processing (ordered for FIFO)
    private var pendingSermonIds: [UUID] = []

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /// Enqueue a sermon for processing
    /// - Parameter sermonId: UUID of the sermon to process
    func enqueue(sermonId: UUID) async {
        // Avoid duplicates in pending or processing
        guard !pendingSermonIds.contains(sermonId),
              !processingJobIds.contains(sermonId) else { return }

        pendingSermonIds.append(sermonId)
        await processNextBatch()
    }

    /// Resume any pending jobs (call on app launch)
    func resumePendingJobs() async {
        // Find all sermons with pending processing
        do {
            let pendingSermons = try fetchPendingSermons()
            for sermon in pendingSermons {
                // Maintain FIFO order, avoid duplicates
                if !pendingSermonIds.contains(sermon.id) && !processingJobIds.contains(sermon.id) {
                    pendingSermonIds.append(sermon.id)
                }
            }
            print("[SermonProcessingQueue] Found \(pendingSermons.count) pending sermons to resume")
            await processNextBatch()
        } catch {
            print("[SermonProcessingQueue] Error fetching pending sermons: \(error)")
        }
    }

    /// Get an AsyncStream of progress updates for a sermon
    /// - Parameter sermonId: The sermon to observe
    /// - Returns: AsyncStream that yields progress updates
    ///
    /// Example usage:
    /// ```swift
    /// let stream = processingQueue.progressStream(for: sermon.id)
    /// for await update in stream {
    ///     self.progress = update.progress
    /// }
    /// ```
    nonisolated func progressStream(for sermonId: UUID) -> AsyncStream<SermonProgressUpdate> {
        progressPublisher.progressStream(for: sermonId)
    }

    /// Cancel processing for a sermon
    func cancel(sermonId: UUID) async {
        pendingSermonIds.removeAll { $0 == sermonId }
        processingJobIds.remove(sermonId)
        await progressPublisher.complete(sermonId: sermonId)
    }

    /// Get current processing status for a sermon
    func getStatus(sermonId: UUID) async -> SermonProcessingJob? {
        return loadJob(sermonId: sermonId)
    }

    /// Check if a sermon is currently being processed
    func isProcessing(sermonId: UUID) -> Bool {
        processingJobIds.contains(sermonId)
    }

    /// Check if a sermon is pending processing
    func isPending(sermonId: UUID) -> Bool {
        pendingSermonIds.contains(sermonId)
    }

    // MARK: - Processing Logic

    /// Process the next batch of sermons with bounded concurrency
    private func processNextBatch() async {
        // Calculate how many new jobs we can start
        let availableSlots = maxConcurrentJobs - processingJobIds.count
        guard availableSlots > 0 else { return }
        guard !pendingSermonIds.isEmpty else { return }

        // Take the first N pending jobs (FIFO)
        let batchCount = min(availableSlots, pendingSermonIds.count)
        let batch = Array(pendingSermonIds.prefix(batchCount))
        pendingSermonIds.removeFirst(batchCount)

        // Mark as processing
        for sermonId in batch {
            processingJobIds.insert(sermonId)
        }

        // Process batch concurrently using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            for sermonId in batch {
                group.addTask { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.processSermonWithCompletion(sermonId: sermonId)
                }
            }
        }
    }

    /// Process a single sermon and handle completion/cleanup
    private func processSermonWithCompletion(sermonId: UUID) async {
        do {
            try await processSermon(sermonId: sermonId)
        } catch {
            print("[SermonProcessingQueue] Error processing sermon \(sermonId): \(error)")
            // Notify error through progress publisher
            if let job = loadJob(sermonId: sermonId) {
                await progressPublisher.completeWithError(sermonId: sermonId, job: job)
            }
        }

        // Cleanup: remove from processing set
        processingJobIds.remove(sermonId)

        // Complete the progress stream
        await progressPublisher.complete(sermonId: sermonId)

        // Process next batch if there are pending jobs
        await processNextBatch()
    }

    private func processSermon(sermonId: UUID) async throws {
        // Load job state
        guard var job = loadJob(sermonId: sermonId) else {
            print("[SermonProcessingQueue] Sermon \(sermonId) not found")
            return
        }

        print("[SermonProcessingQueue] Processing sermon: \(sermonId)")

        // Step 1: Upload chunks (if needed)
        try await uploadChunksIfNeeded(job: &job, sermonId: sermonId)

        // Step 2: Transcribe chunks
        if job.needsTranscription {
            try await runTranscription(job: &job, sermonId: sermonId)
        }

        // Step 3: Generate study guide
        if job.needsStudyGuide {
            try await runStudyGuideGeneration(job: &job, sermonId: sermonId)
        }

        print("[SermonProcessingQueue] Completed sermon: \(sermonId)")
    }

    // MARK: - Processing Steps

    private func uploadChunksIfNeeded(job: inout SermonProcessingJob, sermonId: UUID) async throws {
        // Check if any chunks need uploading
        let chunksToUpload = job.chunkStatuses.filter { $0.uploadStatus == .pending || $0.uploadStatus == .failed }
        guard !chunksToUpload.isEmpty else { return }

        // Upload is handled by SermonSyncService - mark as pending for sync
        for chunk in chunksToUpload {
            try updateChunkUploadStatus(chunkId: chunk.chunkId, status: .pending)
        }

        await progressPublisher.publish(sermonId: sermonId, job: job, progress: 0.1)
    }

    private func runTranscription(job: inout SermonProcessingJob, sermonId: UUID) async throws {
        // Update status to running
        try updateSermonStatus(sermonId: sermonId, transcriptionStatus: .running)
        job.transcriptionStatus = .running

        await progressPublisher.publish(sermonId: sermonId, job: job, progress: 0.2)

        do {
            // Get chunk URLs via repository
            let chunks = try repository.fetchChunks(sermonId: sermonId)
            let chunkURLs = chunks.compactMap { chunk -> URL? in
                guard let path = chunk.localPath else { return nil }
                return URL(fileURLWithPath: path)
            }

            guard !chunkURLs.isEmpty else {
                throw SermonError.chunkNotFound
            }

            // Capture values for escaping closure
            let capturedJob = job
            let publisher = progressPublisher

            // Transcribe all chunks
            let output = try await transcriptionService.transcribeChunks(
                chunkURLs: chunkURLs
            ) { progress in
                Task {
                    await publisher.publish(
                        sermonId: sermonId,
                        job: capturedJob,
                        progress: 0.2 + progress * 0.5
                    )
                }
            }

            // Save transcript via repository
            let transcript = SermonTranscript(
                sermonId: sermonId,
                content: output.text,
                language: output.language,
                wordTimestamps: output.wordTimestamps,
                modelUsed: "whisper-1",
                confidenceScore: nil,
                needsSync: true
            )

            try saveTranscript(transcript)

            // Update status to succeeded
            try updateSermonStatus(sermonId: sermonId, transcriptionStatus: .succeeded)
            job.transcriptionStatus = .succeeded

            await progressPublisher.publish(sermonId: sermonId, job: job, progress: 0.7)

            print("[SermonProcessingQueue] Transcription complete: \(output.text.prefix(100))...")

        } catch {
            // Update status to failed
            try updateSermonStatus(
                sermonId: sermonId,
                transcriptionStatus: .failed,
                transcriptionError: error.localizedDescription
            )
            job.transcriptionStatus = .failed
            throw error
        }
    }

    private func runStudyGuideGeneration(job: inout SermonProcessingJob, sermonId: UUID) async throws {
        // Ensure we have a transcript via repository
        guard let transcript = try repository.fetchTranscript(sermonId: sermonId) else {
            throw SermonError.transcriptionFailed("No transcript available")
        }

        // Update status to running
        try updateSermonStatus(sermonId: sermonId, studyGuideStatus: .running)
        job.studyGuideStatus = .running

        await progressPublisher.publish(sermonId: sermonId, job: job, progress: 0.75)

        do {
            // Generate study guide using AI service
            let studyGuide = try await generateStudyGuide(
                sermonId: sermonId,
                transcript: transcript
            )

            // Save study guide via repository
            try saveStudyGuide(studyGuide)

            // Update status to succeeded
            try updateSermonStatus(sermonId: sermonId, studyGuideStatus: .succeeded)
            job.studyGuideStatus = .succeeded

            await progressPublisher.publish(sermonId: sermonId, job: job, progress: 1.0)

            print("[SermonProcessingQueue] Study guide generation complete")

        } catch {
            // Update status to failed
            try updateSermonStatus(
                sermonId: sermonId,
                studyGuideStatus: .failed,
                studyGuideError: error.localizedDescription
            )
            job.studyGuideStatus = .failed
            throw error
        }
    }

    private func generateStudyGuide(sermonId: UUID, transcript: SermonTranscript) async throws -> SermonStudyGuide {
        // Get AI service
        let aiService = OpenAIProvider.shared

        // Fetch sermon for title and speaker via repository
        let sermon = try repository.fetchSermon(id: sermonId)

        // Extract explicit references using ReferenceParser (replaces regex)
        let parsedRefs = ReferenceParser.extractAll(from: transcript.content)
        let explicitRefs = parsedRefs.map { parsed in
            if let start = parsed.verseStart, let end = parsed.verseEnd, start != end {
                return "\(parsed.book.name) \(parsed.chapter):\(start)-\(end)"
            } else if let verse = parsed.verseStart {
                return "\(parsed.book.name) \(parsed.chapter):\(verse)"
            }
            return "\(parsed.book.name) \(parsed.chapter)"
        }

        // Parse references into VerseRanges for enrichment (nonisolated, no await needed)
        let parsedVerseRanges = enrichmentService.parseAndValidateReferences(explicitRefs)

        // Build enrichment context (Pre-AI)
        let enrichmentContext: SermonEnrichmentContext?
        let hasEnrichmentData: Bool
        do {
            enrichmentContext = try await enrichmentService.buildEnrichmentContext(
                for: parsedVerseRanges,
                config: SermonEnrichmentService.ContextConfig.default
            )
            hasEnrichmentData = !(enrichmentContext?.promptContext.items.isEmpty ?? true)
        } catch {
            print("[SermonProcessingQueue] Enrichment context build failed: \(error)")
            enrichmentContext = nil
            hasEnrichmentData = false
        }

        // Calculate duration from transcript word timestamps
        let durationMinutes: Int?
        if let lastWord = transcript.wordTimestamps.last {
            durationMinutes = Int(lastWord.end / 60)
        } else {
            durationMinutes = nil
        }

        // Prepare input using types from AIServiceProtocol
        let input = SermonStudyGuideInput(
            transcript: transcript.content,
            title: sermon?.title,
            speakerName: sermon?.speakerName,
            durationMinutes: durationMinutes,
            explicitReferences: explicitRefs,
            enrichmentContext: enrichmentContext,
            parsedVerseRanges: parsedVerseRanges,
            hasEnrichmentData: hasEnrichmentData
        )

        // Generate study guide (AI call)
        let output = try await aiService.generateSermonStudyGuide(input: input)

        // Post-AI: Classify and enrich references
        let enrichedMentioned = enrichmentService.classifyAndEnrich(
            output.bibleReferencesMentioned.map { $0.toSermonVerseReference(isMentioned: true) },
            context: enrichmentContext,
            classification: RefClassification.mentioned
        )
        let enrichedSuggested = enrichmentService.classifyAndEnrich(
            output.bibleReferencesSuggested.map { $0.toSermonVerseReference(isMentioned: false) },
            context: enrichmentContext,
            classification: RefClassification.suggested
        )

        // Convert AI output to StudyGuideContent with enriched references
        let content = convertToStudyGuideContent(
            output,
            enrichedMentioned: enrichedMentioned,
            enrichedSuggested: enrichedSuggested
        )

        // Use SHA256 for deterministic transcript hash
        let transcriptHash = SHA256.hash(data: Data(transcript.content.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()

        // Create study guide model
        let studyGuide = SermonStudyGuide(
            sermonId: sermonId,
            content: content,
            modelUsed: "gpt-4o",
            promptVersion: output.promptVersion,
            transcriptHash: transcriptHash,
            needsSync: true
        )

        return studyGuide
    }

    /// Convert SermonStudyGuideOutput to StudyGuideContent with enriched references
    private func convertToStudyGuideContent(
        _ output: SermonStudyGuideOutput,
        enrichedMentioned: [SermonVerseReference],
        enrichedSuggested: [SermonVerseReference]
    ) -> StudyGuideContent {
        // Convert outline sections
        let outline = output.outline?.map { section in
            OutlineSection(
                title: section.title,
                startSeconds: section.startSeconds,
                endSeconds: section.endSeconds,
                summary: section.summary
            )
        }

        // Convert quotes
        let quotes = output.notableQuotes?.map { quote in
            Quote(
                text: quote.text,
                timestampSeconds: quote.timestampSeconds,
                context: quote.context
            )
        }

        // Convert discussion questions
        let questions = output.discussionQuestions.map { q in
            StudyQuestion(
                id: q.id,
                question: q.question,
                type: QuestionType(rawValue: q.type.rawValue) ?? .discussion,
                relatedVerses: q.relatedVerses,
                discussionHint: q.discussionHint
            )
        }

        return StudyGuideContent(
            title: output.title,
            summary: output.summary,
            keyThemes: output.keyThemes,
            outline: outline,
            notableQuotes: quotes,
            bibleReferencesMentioned: enrichedMentioned,
            bibleReferencesSuggested: enrichedSuggested,
            discussionQuestions: questions,
            reflectionPrompts: output.reflectionPrompts,
            applicationPoints: output.applicationPoints,
            confidenceNotes: output.confidenceNotes
        )
    }

    // MARK: - Database Operations (via Repository)

    private func loadJob(sermonId: UUID) -> SermonProcessingJob? {
        do {
            guard let sermon = try repository.fetchSermon(id: sermonId) else {
                return nil
            }

            let chunks = try repository.fetchChunks(sermonId: sermonId)
            let chunkStatuses = chunks.map { chunk in
                SermonProcessingJob.ChunkStatus(
                    chunkId: chunk.id,
                    chunkIndex: chunk.chunkIndex,
                    uploadStatus: chunk.uploadStatus,
                    transcriptionStatus: chunk.transcriptionStatus
                )
            }

            return SermonProcessingJob(
                sermonId: sermon.id,
                transcriptionStatus: sermon.transcriptionStatus,
                studyGuideStatus: sermon.studyGuideStatus,
                chunkStatuses: chunkStatuses
            )
        } catch {
            print("[SermonProcessingQueue] Error loading job: \(error)")
            return nil
        }
    }

    private func fetchPendingSermons() throws -> [Sermon] {
        // Fetch sermons needing sync includes pending/running processing status
        try repository.fetchSermonsNeedingSync().filter { sermon in
            sermon.transcriptionStatus == .pending ||
            sermon.transcriptionStatus == .running ||
            sermon.studyGuideStatus == .pending ||
            sermon.studyGuideStatus == .running
        }
    }

    private func updateSermonStatus(
        sermonId: UUID,
        transcriptionStatus: SermonProcessingStatus? = nil,
        transcriptionError: String? = nil,
        studyGuideStatus: SermonProcessingStatus? = nil,
        studyGuideError: String? = nil
    ) throws {
        guard var sermon = try repository.fetchSermon(id: sermonId) else {
            return
        }

        if let status = transcriptionStatus {
            sermon.transcriptionStatus = status
        }
        if let error = transcriptionError {
            sermon.transcriptionError = error
        }
        if let status = studyGuideStatus {
            sermon.studyGuideStatus = status
        }
        if let error = studyGuideError {
            sermon.studyGuideError = error
        }

        sermon.updatedAt = Date()
        sermon.needsSync = true

        try repository.updateSermon(sermon)
    }

    private func updateChunkUploadStatus(chunkId: UUID, status: ChunkUploadStatus) throws {
        guard var chunk = try repository.fetchChunk(id: chunkId) else {
            return
        }

        chunk.uploadStatus = status
        chunk.updatedAt = Date()
        chunk.needsSync = true

        try repository.updateChunk(chunk)
    }

    private func saveTranscript(_ transcript: SermonTranscript) throws {
        // Repository's saveTranscript handles upsert semantics
        try repository.saveTranscript(transcript)
    }

    private func saveStudyGuide(_ studyGuide: SermonStudyGuide) throws {
        // Repository's saveStudyGuide handles upsert semantics
        try repository.saveStudyGuide(studyGuide)
    }
}
