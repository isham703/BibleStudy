import Foundation
@preconcurrency import GRDB

// MARK: - Sermon Repository
// Centralized data access layer for all Sermon-related entities.
// Follows BibleRepository pattern: singleton, @unchecked Sendable, synchronous throws.

final class SermonRepository: SermonRepositoryProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = SermonRepository()

    // MARK: - Dependencies

    private var database: DatabaseStore { DatabaseStore.shared }

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
        // Notify observers that study guide was saved
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .sermonStudyGuideUpdated,
                object: nil,
                userInfo: ["sermonId": guide.sermonId]
            )
        }
    }

    func updateStudyGuide(_ guide: SermonStudyGuide) throws {
        try dbQueue.write { db in
            try guide.update(db)
        }
        // Notify observers that study guide was updated
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .sermonStudyGuideUpdated,
                object: nil,
                userInfo: ["sermonId": guide.sermonId]
            )
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
                // Check if sermon exists locally and is soft-deleted
                if let existing = try Sermon.fetchOne(db, key: sermon.id) {
                    // Don't overwrite locally deleted sermons with undeleted remote versions
                    if existing.deletedAt != nil && sermon.deletedAt == nil {
                        print("[SermonRepository] Skipping save - sermon \(sermon.id) is locally deleted")
                        continue
                    }
                }
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

    func updateSermonTitle(_ id: UUID, title: String) throws {
        try dbQueue.write { db in
            guard var sermon = try Sermon.fetchOne(db, key: id) else {
                throw SermonRepositoryError.sermonNotFound(id)
            }

            sermon.title = title
            sermon.updatedAt = Date()
            sermon.needsSync = true
            try sermon.update(db)
        }
    }

    // MARK: - Storage Size Calculation

    /// Calculate the total storage size for a sermon's audio chunks
    /// - Parameter sermonId: The sermon ID
    /// - Returns: Total size in bytes (best-effort, includes filesystem fallback)
    func calculateSermonStorageSize(sermonId: UUID) throws -> Int64 {
        return try dbQueue.read { db in
            let chunks = try SermonAudioChunk
                .filter(SermonAudioChunk.Columns.sermonId == sermonId)
                .fetchAll(db)

            // Primary: sum stored fileSize values
            var totalSize = Int64(chunks.compactMap { $0.fileSize }.reduce(0, +))

            // Fallback: compute from filesystem for chunks missing fileSize
            let fileManager = FileManager.default
            for chunk in chunks where chunk.fileSize == nil {
                if let localPath = chunk.localPath,
                   let attrs = try? fileManager.attributesOfItem(atPath: localPath),
                   let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            }

            return totalSize
        }
    }

    /// Calculate the total storage size for multiple sermons
    /// - Parameter sermonIds: Array of sermon IDs
    /// - Returns: Total size in bytes across all sermons
    func calculateTotalSermonStorageSize(sermonIds: [UUID]) -> Int64 {
        sermonIds.reduce(Int64(0)) { total, id in
            total + ((try? calculateSermonStorageSize(sermonId: id)) ?? 0)
        }
    }

    // MARK: - Theme Assignment Operations

    /// Fetch all theme assignments for a sermon
    func fetchThemeAssignments(sermonId: UUID) throws -> [SermonThemeAssignment] {
        return try dbQueue.read { db in
            try SermonThemeAssignment
                .filter(SermonThemeAssignment.Columns.sermonId == sermonId)
                .order(SermonThemeAssignment.Columns.confidence.desc)
                .fetchAll(db)
        }
    }

    /// Fetch visible theme assignments (excludes user_removed)
    func fetchVisibleThemeAssignments(sermonId: UUID) throws -> [SermonThemeAssignment] {
        return try dbQueue.read { db in
            try SermonThemeAssignment
                .filter(SermonThemeAssignment.Columns.sermonId == sermonId)
                .filter(SermonThemeAssignment.Columns.overrideState != ThemeOverrideState.userRemoved.rawValue)
                .order(SermonThemeAssignment.Columns.confidence.desc)
                .fetchAll(db)
        }
    }

    /// Save theme assignments for a sermon (replaces auto assignments, preserves user overrides)
    func saveThemeAssignments(sermonId: UUID, assignments: [SermonThemeAssignment]) throws {
        try dbQueue.write { db in
            // Delete existing auto assignments (preserve user overrides)
            try db.execute(
                sql: """
                    DELETE FROM sermon_themes
                    WHERE sermon_id = ? AND override_state = 'auto'
                """,
                arguments: [sermonId]
            )

            // Insert new assignments
            for var assignment in assignments {
                assignment.updatedAt = Date()
                try assignment.save(db)
            }
        }
    }

    /// Update a single theme assignment
    func updateThemeAssignment(_ assignment: SermonThemeAssignment) throws {
        try dbQueue.write { db in
            var updated = assignment
            updated.updatedAt = Date()
            try updated.save(db)
        }
    }

    /// Add a user-added theme to a sermon
    func addUserTheme(sermonId: UUID, theme: NormalizedTheme) throws {
        try dbQueue.write { db in
            let assignment = SermonThemeAssignment(
                sermonId: sermonId,
                theme: theme.rawValue,
                confidence: 1.0,
                overrideState: .userAdded,
                sourceThemes: [],
                matchType: .exact
            )
            try assignment.save(db)
        }
    }

    /// Remove a theme from a sermon (marks as user_removed to prevent re-adding)
    func removeUserTheme(sermonId: UUID, theme: NormalizedTheme) throws {
        try dbQueue.write { db in
            // Check if assignment exists
            if var existing = try SermonThemeAssignment
                .filter(SermonThemeAssignment.Columns.sermonId == sermonId)
                .filter(SermonThemeAssignment.Columns.theme == theme.rawValue)
                .fetchOne(db) {
                // Mark as user removed
                existing.overrideState = .userRemoved
                existing.updatedAt = Date()
                try existing.update(db)
            } else {
                // Create a user_removed entry to prevent future auto-assignment
                let assignment = SermonThemeAssignment(
                    sermonId: sermonId,
                    theme: theme.rawValue,
                    confidence: 0.0,
                    overrideState: .userRemoved,
                    sourceThemes: [],
                    matchType: .exact
                )
                try assignment.save(db)
            }
        }
    }

    /// Delete all theme assignments for a sermon
    func deleteThemeAssignments(sermonId: UUID) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM sermon_themes WHERE sermon_id = ?",
                arguments: [sermonId]
            )
        }
    }

    /// Get primary theme for a sermon (highest confidence visible theme)
    func fetchPrimaryTheme(sermonId: UUID) throws -> NormalizedTheme? {
        return try dbQueue.read { db in
            let assignment = try SermonThemeAssignment
                .filter(SermonThemeAssignment.Columns.sermonId == sermonId)
                .filter(SermonThemeAssignment.Columns.overrideState != ThemeOverrideState.userRemoved.rawValue)
                .order(SermonThemeAssignment.Columns.confidence.desc)
                .fetchOne(db)
            return assignment?.normalizedTheme
        }
    }
}
