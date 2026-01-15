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

            // 1) Save study guide immediately (outline visible, timestamps may be nil)
            try saveStudyGuide(studyGuide)

            // Update status to succeeded
            try updateSermonStatus(sermonId: sermonId, studyGuideStatus: .succeeded)
            job.studyGuideStatus = .succeeded

            await progressPublisher.publish(sermonId: sermonId, job: job, progress: 1.0)

            print("[SermonProcessingQueue] Study guide generation complete")

            // 2) Enrich outline timestamps asynchronously (outline becomes clickable)
            let capturedRepository = repository
            let sermonDuration = try? repository.fetchSermon(id: sermonId)?.durationSeconds
            Task.detached(priority: .utility) {
                var updated = studyGuide
                if let outline = updated.content.outline, !outline.isEmpty {
                    updated.content.outline = OutlineTimestampMatcher.matchOutlineToTranscript(
                        outline: outline,
                        wordTimestamps: transcript.wordTimestamps,
                        sermonDuration: Double(sermonDuration ?? 0)
                    )
                    updated.updatedAt = Date()
                    updated.needsSync = true
                    do {
                        try capturedRepository.updateStudyGuide(updated)
                        print("[SermonProcessingQueue] Outline timestamps enriched for sermon \(sermonId)")
                    } catch {
                        print("[SermonProcessingQueue] Failed to save enriched outline: \(error)")
                    }
                }
            }

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

        // Convert AI output to StudyGuideContent with enriched references and timestamp resolution
        let content = convertToStudyGuideContent(
            output,
            enrichedMentioned: enrichedMentioned,
            enrichedSuggested: enrichedSuggested,
            wordTimestamps: transcript.wordTimestamps
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
    /// - Parameters:
    ///   - output: The AI-generated study guide output
    ///   - enrichedMentioned: Bible references mentioned in the sermon (enriched)
    ///   - enrichedSuggested: AI-suggested Bible references (enriched)
    ///   - wordTimestamps: Word-level timestamps for anchor resolution
    private func convertToStudyGuideContent(
        _ output: SermonStudyGuideOutput,
        enrichedMentioned: [SermonVerseReference],
        enrichedSuggested: [SermonVerseReference],
        wordTimestamps: [SermonTranscript.WordTimestamp]
    ) -> StudyGuideContent {
        // Convert outline sections (timestamps will be enriched later)
        let outline = output.outline?.map { section in
            OutlineSection(
                title: section.title,
                startSeconds: section.startSeconds,
                endSeconds: section.endSeconds,
                summary: section.summary,
                anchorText: section.anchorText,
                matchConfidence: nil  // Will be set by OutlineTimestampMatcher
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

        // Parse sermon type
        let sermonType: SermonType?
        if let typeStr = output.sermonType {
            sermonType = SermonType(rawValue: typeStr.lowercased())
        } else {
            sermonType = nil
        }

        // Convert and resolve timestamps for anchored insights
        let keyTakeaways: [AnchoredInsight]?
        if let aiTakeaways = output.keyTakeaways {
            let unresolved = aiTakeaways.map { $0.toAnchoredInsight() }
            keyTakeaways = resolveTimestamps(for: unresolved, using: wordTimestamps)
        } else {
            keyTakeaways = nil
        }

        let theologicalAnnotations: [AnchoredInsight]?
        if let aiAnnotations = output.theologicalAnnotations {
            let unresolved = aiAnnotations.map { $0.toAnchoredInsight() }
            theologicalAnnotations = resolveTimestamps(for: unresolved, using: wordTimestamps)
        } else {
            theologicalAnnotations = nil
        }

        let anchoredApplicationPoints: [AnchoredInsight]?
        if let aiApps = output.anchoredApplicationPoints {
            let unresolved = aiApps.map { $0.toAnchoredInsight() }
            anchoredApplicationPoints = resolveTimestamps(for: unresolved, using: wordTimestamps)
        } else {
            anchoredApplicationPoints = nil
        }

        return StudyGuideContent(
            title: output.title,
            summary: output.summary,
            keyThemes: output.keyThemes,
            sermonType: sermonType,
            centralThesis: output.centralThesis,
            keyTakeaways: keyTakeaways,
            theologicalAnnotations: theologicalAnnotations,
            outline: outline,
            notableQuotes: quotes,
            bibleReferencesMentioned: enrichedMentioned,
            bibleReferencesSuggested: enrichedSuggested,
            discussionQuestions: questions,
            reflectionPrompts: output.reflectionPrompts,
            applicationPoints: output.applicationPoints,
            anchoredApplicationPoints: anchoredApplicationPoints,
            confidenceNotes: output.confidenceNotes
        )
    }

    // MARK: - Timestamp Resolution

    /// Result of finding a quote in the transcript
    private struct QuoteMatch {
        let startTime: Double
        let endTime: Double
        let confidence: Double
    }

    /// Find a quote in the transcript using fuzzy token matching
    /// Returns the timestamp of the best match above the confidence threshold
    private func findQuoteInTranscript(
        quote: String,
        wordTimestamps: [SermonTranscript.WordTimestamp]
    ) -> QuoteMatch? {
        guard !quote.isEmpty, !wordTimestamps.isEmpty else { return nil }

        // Normalize the quote: lowercase, remove punctuation
        let normalizedQuote = normalizeText(quote)
        let quoteTokens = normalizedQuote.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        guard quoteTokens.count >= 3 else { return nil }  // Need at least 3 words for reliable matching

        // Build normalized word list from transcript
        let normalizedWords = wordTimestamps.map { normalizeText($0.word) }

        var bestMatch: (startIndex: Int, endIndex: Int, score: Double)?

        // Sliding window approach
        let windowSize = quoteTokens.count
        let maxStartIndex = max(0, normalizedWords.count - windowSize)

        for startIndex in 0...maxStartIndex {
            let endIndex = min(startIndex + windowSize + 2, normalizedWords.count)  // Allow slight variance
            let windowWords = Array(normalizedWords[startIndex..<endIndex])

            // Calculate token overlap score
            let score = calculateTokenOverlap(quoteTokens: quoteTokens, windowWords: windowWords)

            if score > (bestMatch?.score ?? 0.0) {
                bestMatch = (startIndex, min(startIndex + windowSize - 1, normalizedWords.count - 1), score)
            }
        }

        // Check confidence threshold
        guard let match = bestMatch, match.score >= 0.6 else { return nil }

        let startTime = wordTimestamps[match.startIndex].start
        let endTime = wordTimestamps[match.endIndex].end

        return QuoteMatch(startTime: startTime, endTime: endTime, confidence: match.score)
    }

    /// Normalize text for matching: lowercase, remove punctuation
    private func normalizeText(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Calculate token overlap between quote and window (returns 0-1 score)
    private func calculateTokenOverlap(quoteTokens: [String], windowWords: [String]) -> Double {
        guard !quoteTokens.isEmpty else { return 0.0 }

        var matchedTokens = 0
        var usedIndices = Set<Int>()

        for quoteToken in quoteTokens {
            // Find best match in window (allowing for slight misspellings)
            for (index, windowWord) in windowWords.enumerated() {
                if usedIndices.contains(index) { continue }

                if quoteToken == windowWord || levenshteinDistance(quoteToken, windowWord) <= 1 {
                    matchedTokens += 1
                    usedIndices.insert(index)
                    break
                }
            }
        }

        return Double(matchedTokens) / Double(quoteTokens.count)
    }

    /// Simple Levenshtein distance for fuzzy matching
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        if s1.isEmpty { return s2.count }
        if s2.isEmpty { return s1.count }

        let a = Array(s1)
        let b = Array(s2)

        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)

        for i in 0...a.count { dist[i][0] = i }
        for j in 0...b.count { dist[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                dist[i][j] = min(
                    dist[i - 1][j] + 1,      // deletion
                    dist[i][j - 1] + 1,      // insertion
                    dist[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return dist[a.count][b.count]
    }

    /// Resolve timestamps for an array of AnchoredInsights
    private func resolveTimestamps(
        for insights: [AnchoredInsight],
        using wordTimestamps: [SermonTranscript.WordTimestamp]
    ) -> [AnchoredInsight] {
        return insights.map { insight in
            var resolved = insight

            if let match = findQuoteInTranscript(
                quote: insight.supportingQuote,
                wordTimestamps: wordTimestamps
            ) {
                resolved.timestampSeconds = match.startTime
                resolved.confidence = match.confidence
            }

            return resolved
        }
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
