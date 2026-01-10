import Foundation
@preconcurrency import GRDB

// MARK: - Sermon Repository
// Centralized data access layer for all Sermon-related entities.
// Follows BibleRepository pattern: singleton, @unchecked Sendable, synchronous throws.

final class SermonRepository: SermonRepositoryProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = SermonRepository()

    // MARK: - Dependencies

    private var database: DatabaseManager { DatabaseManager.shared }

    /// Helper to get dbQueue or throw appropriate error (DRY pattern)
    private var dbQueue: DatabaseQueue {
        get throws {
            guard let queue = database.dbQueue else {
                throw SermonRepositoryError.databaseNotInitialized
            }
            return queue
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Sermon Operations

    func fetchSermons(
        userId: UUID,
        includeDeleted: Bool,
        cursor: SermonCursor?,
        limit: Int
    ) throws -> PaginatedSermons {
        let effectiveLimit = min(limit, SermonPaginationDefaults.maxPageSize)

        return try dbQueue.read { db in
            var query = Sermon
                .filter(Sermon.Columns.userId == userId)

            if !includeDeleted {
                query = query.filter(Sermon.Columns.deletedAt == nil)
            }

            // Apply cursor for keyset pagination
            // Use (recordedAt, id) tuple for stable ordering
            if let cursor = cursor {
                // WHERE (recorded_at, id) < (cursor.recordedAt, cursor.id)
                // This handles the case where multiple sermons have the same recordedAt
                query = query.filter(
                    Sermon.Columns.recordedAt < cursor.recordedAt ||
                    (Sermon.Columns.recordedAt == cursor.recordedAt && Sermon.Columns.id < cursor.id)
                )
            }

            // Order by recordedAt DESC, id DESC for deterministic pagination
            query = query
                .order(Sermon.Columns.recordedAt.desc, Sermon.Columns.id.desc)
                .limit(effectiveLimit + 1)  // Fetch one extra to check hasMore

            let sermons = try query.fetchAll(db)

            // Determine if there are more results
            let hasMore = sermons.count > effectiveLimit
            let resultSermons = hasMore ? Array(sermons.prefix(effectiveLimit)) : sermons

            // Build next cursor from last sermon in results
            let nextCursor: SermonCursor? = hasMore ? resultSermons.last.map { SermonCursor(from: $0) } : nil

            return PaginatedSermons(
                sermons: resultSermons,
                nextCursor: nextCursor,
                hasMore: hasMore,
                totalCount: nil  // Skip count for performance
            )
        }
    }

    func fetchAllSermons(userId: UUID, includeDeleted: Bool) throws -> [Sermon] {
        return try dbQueue.read { db in
            var query = Sermon
                .filter(Sermon.Columns.userId == userId)

            if !includeDeleted {
                query = query.filter(Sermon.Columns.deletedAt == nil)
            }

            return try query
                .order(Sermon.Columns.recordedAt.desc)
                .fetchAll(db)
        }
    }

    func fetchSermon(id: UUID) throws -> Sermon? {
        return try dbQueue.read { db in
            try Sermon.fetchOne(db, key: id)
        }
    }

    func saveSermon(_ sermon: Sermon) throws {
        try dbQueue.write { db in
            try sermon.save(db)
        }
    }

    func updateSermon(_ sermon: Sermon) throws {
        try dbQueue.write { db in
            try sermon.update(db)
        }
    }

    func fetchSermonsNeedingSync() throws -> [Sermon] {
        return try dbQueue.read { db in
            try Sermon
                .filter(Sermon.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    // MARK: - Audio Chunk Operations

    func saveChunk(_ chunk: SermonAudioChunk) throws {
        try dbQueue.write { db in
            // Check if a chunk with same (sermon_id, chunk_index) already exists
            // This handles retry scenarios where a new chunk UUID is generated
            let existingChunk = try SermonAudioChunk
                .filter(SermonAudioChunk.Columns.sermonId == chunk.sermonId)
                .filter(SermonAudioChunk.Columns.chunkIndex == chunk.chunkIndex)
                .fetchOne(db)

            if let existing = existingChunk {
                // Update existing chunk with new data (preserving the original ID)
                try db.execute(
                    sql: """
                        UPDATE sermon_audio_chunks SET
                            start_offset_seconds = ?,
                            duration_seconds = ?,
                            local_path = ?,
                            remote_path = ?,
                            file_size = ?,
                            content_hash = ?,
                            upload_status = ?,
                            upload_error = ?,
                            upload_progress = ?,
                            transcription_status = ?,
                            transcription_error = ?,
                            transcript_segment = ?,
                            waveform_samples = ?,
                            updated_at = ?,
                            needs_sync = ?
                        WHERE id = ?
                        """,
                    arguments: [
                        chunk.startOffsetSeconds,
                        chunk.durationSeconds,
                        chunk.localPath,
                        chunk.remotePath,
                        chunk.fileSize,
                        chunk.contentHash,
                        chunk.uploadStatus.rawValue,
                        chunk.uploadError,
                        chunk.uploadProgress,
                        chunk.transcriptionStatus.rawValue,
                        chunk.transcriptionError,
                        chunk.transcriptSegment.flatMap { segment in
                            try? JSONEncoder().encode(segment)
                        }.flatMap { String(data: $0, encoding: .utf8) },
                        chunk.waveformSamples.flatMap { samples in
                            try? JSONEncoder().encode(samples)
                        }.flatMap { String(data: $0, encoding: .utf8) },
                        chunk.updatedAt,
                        chunk.needsSync,
                        existing.id.uuidString
                    ]
                )
            } else {
                // No existing chunk, safe to insert
                try chunk.insert(db)
            }
        }
    }

    func updateChunk(_ chunk: SermonAudioChunk) throws {
        try dbQueue.write { db in
            try chunk.update(db)
        }
    }

    func fetchChunks(sermonId: UUID) throws -> [SermonAudioChunk] {
        return try dbQueue.read { db in
            try SermonAudioChunk
                .filter(SermonAudioChunk.Columns.sermonId == sermonId)
                .order(SermonAudioChunk.Columns.chunkIndex)
                .fetchAll(db)
        }
    }

    func fetchChunk(id: UUID) throws -> SermonAudioChunk? {
        return try dbQueue.read { db in
            try SermonAudioChunk.fetchOne(db, key: id)
        }
    }

    func fetchChunksNeedingSync() throws -> [SermonAudioChunk] {
        return try dbQueue.read { db in
            try SermonAudioChunk
                .filter(SermonAudioChunk.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    // MARK: - Transcript Operations

    func fetchTranscript(sermonId: UUID) throws -> SermonTranscript? {
        return try dbQueue.read { db in
            try SermonTranscript
                .filter(SermonTranscript.Columns.sermonId == sermonId)
                .fetchOne(db)
        }
    }

    func saveTranscript(_ transcript: SermonTranscript) throws {
        try dbQueue.write { db in
            try transcript.save(db)
        }
    }

    func updateTranscript(_ transcript: SermonTranscript) throws {
        try dbQueue.write { db in
            try transcript.update(db)
        }
    }

    func fetchTranscriptsNeedingSync() throws -> [SermonTranscript] {
        return try dbQueue.read { db in
            try SermonTranscript
                .filter(SermonTranscript.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    // MARK: - Study Guide Operations

    func fetchStudyGuide(sermonId: UUID) throws -> SermonStudyGuide? {
        return try dbQueue.read { db in
            try SermonStudyGuide
                .filter(SermonStudyGuide.Columns.sermonId == sermonId)
                .fetchOne(db)
        }
    }

    func saveStudyGuide(_ guide: SermonStudyGuide) throws {
        try dbQueue.write { db in
            try guide.save(db)
        }
    }

    func updateStudyGuide(_ guide: SermonStudyGuide) throws {
        try dbQueue.write { db in
            try guide.update(db)
        }
    }

    func fetchStudyGuidesNeedingSync() throws -> [SermonStudyGuide] {
        return try dbQueue.read { db in
            try SermonStudyGuide
                .filter(SermonStudyGuide.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    // MARK: - Bookmark Operations

    func fetchBookmarks(sermonId: UUID, includeDeleted: Bool) throws -> [SermonBookmark] {
        return try dbQueue.read { db in
            var query = SermonBookmark
                .filter(SermonBookmark.Columns.sermonId == sermonId)

            if !includeDeleted {
                query = query.filter(SermonBookmark.Columns.deletedAt == nil)
            }

            return try query
                .order(SermonBookmark.Columns.timestampSeconds)
                .fetchAll(db)
        }
    }

    func saveBookmark(_ bookmark: SermonBookmark) throws {
        try dbQueue.write { db in
            try bookmark.save(db)
        }
    }

    func updateBookmark(_ bookmark: SermonBookmark) throws {
        try dbQueue.write { db in
            try bookmark.update(db)
        }
    }

    func fetchBookmarksNeedingSync() throws -> [SermonBookmark] {
        return try dbQueue.read { db in
            try SermonBookmark
                .filter(SermonBookmark.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    // MARK: - Bulk Operations

    func saveSermons(_ sermons: [Sermon]) throws {
        try dbQueue.write { db in
            for sermon in sermons {
                try sermon.save(db)
            }
        }
    }

    func softDeleteSermon(id: UUID) throws {
        try dbQueue.write { db in
            guard var sermon = try Sermon.fetchOne(db, key: id) else {
                throw SermonRepositoryError.sermonNotFound(id)
            }

            sermon.markDeleted()
            try sermon.update(db)
        }
    }
}
