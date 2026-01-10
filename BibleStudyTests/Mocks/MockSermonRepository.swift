import Foundation
@testable import BibleStudy

// MARK: - Mock Sermon Repository
// In-memory implementation of SermonRepositoryProtocol for testing.
// Supports injecting errors and tracking method calls.

final class MockSermonRepository: SermonRepositoryProtocol, @unchecked Sendable {

    // MARK: - Storage

    private var sermons: [UUID: Sermon] = [:]
    private var chunks: [UUID: SermonAudioChunk] = [:]
    private var transcripts: [UUID: SermonTranscript] = [:]
    private var studyGuides: [UUID: SermonStudyGuide] = [:]
    private var bookmarks: [UUID: SermonBookmark] = [:]

    // MARK: - Call Tracking

    var fetchSermonsCalled = false
    var fetchAllSermonsCalled = false
    var fetchSermonCalled = false
    var saveSermonCalled = false
    var updateSermonCalled = false
    var saveChunkCalled = false
    var updateChunkCalled = false
    var fetchChunksCalled = false
    var fetchChunkCalled = false
    var fetchTranscriptCalled = false
    var saveTranscriptCalled = false
    var fetchStudyGuideCalled = false
    var saveStudyGuideCalled = false
    var fetchBookmarksCalled = false
    var saveBookmarkCalled = false

    // MARK: - Error Injection

    var shouldThrowError: SermonRepositoryError?

    // MARK: - Setup Helpers

    func seed(sermons: [Sermon]) {
        for sermon in sermons {
            self.sermons[sermon.id] = sermon
        }
    }

    func seed(chunks: [SermonAudioChunk]) {
        for chunk in chunks {
            self.chunks[chunk.id] = chunk
        }
    }

    func seed(transcripts: [SermonTranscript]) {
        for transcript in transcripts {
            self.transcripts[transcript.sermonId] = transcript
        }
    }

    func seed(studyGuides: [SermonStudyGuide]) {
        for guide in studyGuides {
            self.studyGuides[guide.sermonId] = guide
        }
    }

    func seed(bookmarks: [SermonBookmark]) {
        for bookmark in bookmarks {
            self.bookmarks[bookmark.id] = bookmark
        }
    }

    func reset() {
        sermons.removeAll()
        chunks.removeAll()
        transcripts.removeAll()
        studyGuides.removeAll()
        bookmarks.removeAll()
        shouldThrowError = nil
        resetCallTracking()
    }

    func resetCallTracking() {
        fetchSermonsCalled = false
        fetchAllSermonsCalled = false
        fetchSermonCalled = false
        saveSermonCalled = false
        updateSermonCalled = false
        saveChunkCalled = false
        updateChunkCalled = false
        fetchChunksCalled = false
        fetchChunkCalled = false
        fetchTranscriptCalled = false
        saveTranscriptCalled = false
        fetchStudyGuideCalled = false
        saveStudyGuideCalled = false
        fetchBookmarksCalled = false
        saveBookmarkCalled = false
    }

    // MARK: - Sermon Operations

    func fetchSermons(
        userId: UUID,
        includeDeleted: Bool,
        cursor: SermonCursor?,
        limit: Int
    ) throws -> PaginatedSermons {
        fetchSermonsCalled = true
        if let error = shouldThrowError { throw error }

        var filtered = sermons.values.filter { $0.userId == userId }
        if !includeDeleted {
            filtered = filtered.filter { $0.deletedAt == nil }
        }

        // Sort by recordedAt DESC, id DESC
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.recordedAt != rhs.recordedAt {
                return lhs.recordedAt > rhs.recordedAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }

        // Apply cursor
        var startIndex = 0
        if let cursor = cursor {
            startIndex = sorted.firstIndex { sermon in
                sermon.recordedAt < cursor.recordedAt ||
                (sermon.recordedAt == cursor.recordedAt && sermon.id.uuidString < cursor.id.uuidString)
            } ?? sorted.count
        }

        // Apply limit
        let effectiveLimit = min(limit, SermonPaginationDefaults.maxPageSize)
        let endIndex = min(startIndex + effectiveLimit, sorted.count)
        let page = Array(sorted[startIndex..<endIndex])

        let hasMore = endIndex < sorted.count
        let nextCursor = hasMore ? page.last.map { SermonCursor(from: $0) } : nil

        return PaginatedSermons(
            sermons: page,
            nextCursor: nextCursor,
            hasMore: hasMore,
            totalCount: filtered.count
        )
    }

    func fetchAllSermons(userId: UUID, includeDeleted: Bool) throws -> [Sermon] {
        fetchAllSermonsCalled = true
        if let error = shouldThrowError { throw error }

        var filtered = sermons.values.filter { $0.userId == userId }
        if !includeDeleted {
            filtered = filtered.filter { $0.deletedAt == nil }
        }
        return filtered.sorted { $0.recordedAt > $1.recordedAt }
    }

    func fetchSermon(id: UUID) throws -> Sermon? {
        fetchSermonCalled = true
        if let error = shouldThrowError { throw error }
        return sermons[id]
    }

    func saveSermon(_ sermon: Sermon) throws {
        saveSermonCalled = true
        if let error = shouldThrowError { throw error }
        sermons[sermon.id] = sermon
    }

    func updateSermon(_ sermon: Sermon) throws {
        updateSermonCalled = true
        if let error = shouldThrowError { throw error }
        guard sermons[sermon.id] != nil else {
            throw SermonRepositoryError.sermonNotFound(sermon.id)
        }
        sermons[sermon.id] = sermon
    }

    func fetchSermonsNeedingSync() throws -> [Sermon] {
        if let error = shouldThrowError { throw error }
        return sermons.values.filter { $0.needsSync }
    }

    // MARK: - Chunk Operations

    func saveChunk(_ chunk: SermonAudioChunk) throws {
        saveChunkCalled = true
        if let error = shouldThrowError { throw error }

        // Check for existing chunk with same (sermonId, chunkIndex)
        if let existing = chunks.values.first(where: {
            $0.sermonId == chunk.sermonId && $0.chunkIndex == chunk.chunkIndex
        }) {
            // Update existing (preserve ID)
            var updated = chunk
            // In mock, we can just use the incoming chunk since we're not preserving IDs
            chunks[existing.id] = updated
        } else {
            chunks[chunk.id] = chunk
        }
    }

    func updateChunk(_ chunk: SermonAudioChunk) throws {
        updateChunkCalled = true
        if let error = shouldThrowError { throw error }
        guard chunks[chunk.id] != nil else {
            throw SermonRepositoryError.chunkNotFound(chunk.id)
        }
        chunks[chunk.id] = chunk
    }

    func fetchChunks(sermonId: UUID) throws -> [SermonAudioChunk] {
        fetchChunksCalled = true
        if let error = shouldThrowError { throw error }
        return chunks.values
            .filter { $0.sermonId == sermonId }
            .sorted { $0.chunkIndex < $1.chunkIndex }
    }

    func fetchChunk(id: UUID) throws -> SermonAudioChunk? {
        fetchChunkCalled = true
        if let error = shouldThrowError { throw error }
        return chunks[id]
    }

    func fetchChunksNeedingSync() throws -> [SermonAudioChunk] {
        if let error = shouldThrowError { throw error }
        return Array(chunks.values.filter { $0.needsSync })
    }

    // MARK: - Transcript Operations

    func fetchTranscript(sermonId: UUID) throws -> SermonTranscript? {
        fetchTranscriptCalled = true
        if let error = shouldThrowError { throw error }
        return transcripts[sermonId]
    }

    func saveTranscript(_ transcript: SermonTranscript) throws {
        saveTranscriptCalled = true
        if let error = shouldThrowError { throw error }
        transcripts[transcript.sermonId] = transcript
    }

    func updateTranscript(_ transcript: SermonTranscript) throws {
        if let error = shouldThrowError { throw error }
        transcripts[transcript.sermonId] = transcript
    }

    func fetchTranscriptsNeedingSync() throws -> [SermonTranscript] {
        if let error = shouldThrowError { throw error }
        return Array(transcripts.values.filter { $0.needsSync })
    }

    // MARK: - Study Guide Operations

    func fetchStudyGuide(sermonId: UUID) throws -> SermonStudyGuide? {
        fetchStudyGuideCalled = true
        if let error = shouldThrowError { throw error }
        return studyGuides[sermonId]
    }

    func saveStudyGuide(_ guide: SermonStudyGuide) throws {
        saveStudyGuideCalled = true
        if let error = shouldThrowError { throw error }
        studyGuides[guide.sermonId] = guide
    }

    func updateStudyGuide(_ guide: SermonStudyGuide) throws {
        if let error = shouldThrowError { throw error }
        studyGuides[guide.sermonId] = guide
    }

    func fetchStudyGuidesNeedingSync() throws -> [SermonStudyGuide] {
        if let error = shouldThrowError { throw error }
        return Array(studyGuides.values.filter { $0.needsSync })
    }

    // MARK: - Bookmark Operations

    func fetchBookmarks(sermonId: UUID, includeDeleted: Bool) throws -> [SermonBookmark] {
        fetchBookmarksCalled = true
        if let error = shouldThrowError { throw error }

        var filtered = bookmarks.values.filter { $0.sermonId == sermonId }
        if !includeDeleted {
            filtered = filtered.filter { $0.deletedAt == nil }
        }
        return filtered.sorted { $0.timestampSeconds < $1.timestampSeconds }
    }

    func saveBookmark(_ bookmark: SermonBookmark) throws {
        saveBookmarkCalled = true
        if let error = shouldThrowError { throw error }
        bookmarks[bookmark.id] = bookmark
    }

    func updateBookmark(_ bookmark: SermonBookmark) throws {
        if let error = shouldThrowError { throw error }
        bookmarks[bookmark.id] = bookmark
    }

    func fetchBookmarksNeedingSync() throws -> [SermonBookmark] {
        if let error = shouldThrowError { throw error }
        return Array(bookmarks.values.filter { $0.needsSync })
    }

    // MARK: - Bulk Operations

    func saveSermons(_ sermons: [Sermon]) throws {
        if let error = shouldThrowError { throw error }
        for sermon in sermons {
            self.sermons[sermon.id] = sermon
        }
    }

    func softDeleteSermon(id: UUID) throws {
        if let error = shouldThrowError { throw error }
        guard var sermon = sermons[id] else {
            throw SermonRepositoryError.sermonNotFound(id)
        }
        sermon.markDeleted()
        sermons[id] = sermon
    }
}
