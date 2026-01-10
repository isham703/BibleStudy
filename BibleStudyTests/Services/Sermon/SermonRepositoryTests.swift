import Testing
import Foundation
@testable import BibleStudy

// MARK: - Sermon Repository Tests
// Tests for pagination, cursor stability, and upsert semantics

@Suite("SermonRepository")
struct SermonRepositoryTests {

    // MARK: - Test Data Factory

    private func makeSermon(
        id: UUID = UUID(),
        userId: UUID,
        title: String = "Test Sermon",
        recordedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false
    ) -> Sermon {
        Sermon(
            id: id,
            userId: userId,
            title: title,
            recordedAt: recordedAt,
            deletedAt: deletedAt,
            needsSync: needsSync
        )
    }

    private func makeChunk(
        id: UUID = UUID(),
        sermonId: UUID,
        chunkIndex: Int,
        needsSync: Bool = false
    ) -> SermonAudioChunk {
        SermonAudioChunk(
            id: id,
            sermonId: sermonId,
            chunkIndex: chunkIndex,
            startOffsetSeconds: Double(chunkIndex * 600),
            durationSeconds: 600,
            needsSync: needsSync
        )
    }

    // MARK: - Pagination Tests

    @Test("Fetch sermons returns first page correctly")
    func testFetchSermons_FirstPage() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        // Create 25 sermons with different dates
        let now = Date()
        var sermons: [Sermon] = []
        for i in 0..<25 {
            let sermon = makeSermon(
                userId: userId,
                title: "Sermon \(i)",
                recordedAt: now.addingTimeInterval(TimeInterval(-i * 3600)) // 1 hour apart
            )
            sermons.append(sermon)
        }
        repository.seed(sermons: sermons)

        // Fetch first page
        let result = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: nil,
            limit: 10
        )

        #expect(result.sermons.count == 10)
        #expect(result.hasMore == true)
        #expect(result.nextCursor != nil)

        // First sermon should be most recent (index 0)
        #expect(result.sermons.first?.title == "Sermon 0")
        // Last sermon on page should be index 9
        #expect(result.sermons.last?.title == "Sermon 9")
    }

    @Test("Fetch sermons second page uses cursor correctly")
    func testFetchSermons_SecondPage_CursorStability() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        // Create 25 sermons
        let now = Date()
        var sermons: [Sermon] = []
        for i in 0..<25 {
            let sermon = makeSermon(
                userId: userId,
                title: "Sermon \(i)",
                recordedAt: now.addingTimeInterval(TimeInterval(-i * 3600))
            )
            sermons.append(sermon)
        }
        repository.seed(sermons: sermons)

        // Fetch first page
        let firstPage = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: nil,
            limit: 10
        )

        // Fetch second page using cursor
        let secondPage = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: firstPage.nextCursor,
            limit: 10
        )

        #expect(secondPage.sermons.count == 10)
        #expect(secondPage.hasMore == true)

        // First sermon on second page should be index 10
        #expect(secondPage.sermons.first?.title == "Sermon 10")
        // Last sermon on second page should be index 19
        #expect(secondPage.sermons.last?.title == "Sermon 19")

        // No overlap with first page
        let firstPageIds = Set(firstPage.sermons.map { $0.id })
        let secondPageIds = Set(secondPage.sermons.map { $0.id })
        #expect(firstPageIds.isDisjoint(with: secondPageIds))
    }

    @Test("Fetch sermons empty result")
    func testFetchSermons_EmptyResult() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        let result = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: nil,
            limit: 10
        )

        #expect(result.sermons.isEmpty)
        #expect(result.hasMore == false)
        #expect(result.nextCursor == nil)
    }

    @Test("Fetch sermons excludes deleted by default")
    func testFetchSermons_ExcludesDeleted() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        let activeSermon = makeSermon(userId: userId, title: "Active")
        let deletedSermon = makeSermon(userId: userId, title: "Deleted", deletedAt: Date())

        repository.seed(sermons: [activeSermon, deletedSermon])

        let result = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: nil,
            limit: 10
        )

        #expect(result.sermons.count == 1)
        #expect(result.sermons.first?.title == "Active")
    }

    @Test("Fetch sermons includes deleted when requested")
    func testFetchSermons_IncludesDeleted() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        let activeSermon = makeSermon(userId: userId, title: "Active")
        let deletedSermon = makeSermon(userId: userId, title: "Deleted", deletedAt: Date())

        repository.seed(sermons: [activeSermon, deletedSermon])

        let result = try repository.fetchSermons(
            userId: userId,
            includeDeleted: true,
            cursor: nil,
            limit: 10
        )

        #expect(result.sermons.count == 2)
    }

    @Test("Fetch sermons respects max page size")
    func testFetchSermons_RespectsMaxPageSize() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        // Create more than max page size
        var sermons: [Sermon] = []
        for i in 0..<150 {
            sermons.append(makeSermon(userId: userId, title: "Sermon \(i)"))
        }
        repository.seed(sermons: sermons)

        // Request more than max
        let result = try repository.fetchSermons(
            userId: userId,
            includeDeleted: false,
            cursor: nil,
            limit: 200
        )

        // Should be capped at maxPageSize (100)
        #expect(result.sermons.count == 100)
    }

    // MARK: - Chunk Upsert Tests

    @Test("Save chunk upserts by sermon ID and chunk index")
    func testSaveChunk_UpsertPreservesId() throws {
        let repository = MockSermonRepository()
        let sermonId = UUID()

        // Save initial chunk
        let originalChunk = makeChunk(sermonId: sermonId, chunkIndex: 0)
        try repository.saveChunk(originalChunk)

        // Save another chunk with same sermonId/chunkIndex but different ID
        let newChunkId = UUID()
        var duplicateChunk = makeChunk(id: newChunkId, sermonId: sermonId, chunkIndex: 0)
        duplicateChunk.localPath = "/updated/path"

        try repository.saveChunk(duplicateChunk)

        // Should only have one chunk
        let chunks = try repository.fetchChunks(sermonId: sermonId)
        #expect(chunks.count == 1)
    }

    @Test("Save chunk creates new when no conflict")
    func testSaveChunk_CreatesNew() throws {
        let repository = MockSermonRepository()
        let sermonId = UUID()

        let chunk0 = makeChunk(sermonId: sermonId, chunkIndex: 0)
        let chunk1 = makeChunk(sermonId: sermonId, chunkIndex: 1)

        try repository.saveChunk(chunk0)
        try repository.saveChunk(chunk1)

        let chunks = try repository.fetchChunks(sermonId: sermonId)
        #expect(chunks.count == 2)
        #expect(chunks[0].chunkIndex == 0)
        #expect(chunks[1].chunkIndex == 1)
    }

    // MARK: - Error Handling Tests

    @Test("Throws error when configured")
    func testThrowsError_WhenConfigured() throws {
        let repository = MockSermonRepository()
        repository.shouldThrowError = .databaseNotInitialized

        #expect(throws: SermonRepositoryError.self) {
            _ = try repository.fetchSermon(id: UUID())
        }
    }

    @Test("Update non-existent sermon throws")
    func testUpdateSermon_NotFound() throws {
        let repository = MockSermonRepository()
        let nonExistentSermon = makeSermon(userId: UUID())

        #expect(throws: SermonRepositoryError.self) {
            try repository.updateSermon(nonExistentSermon)
        }
    }

    // MARK: - Needs Sync Tests

    @Test("Fetch sermons needing sync")
    func testFetchSermonsNeedingSync() throws {
        let repository = MockSermonRepository()
        let userId = UUID()

        let syncedSermon = makeSermon(userId: userId, title: "Synced", needsSync: false)
        let unsyncedSermon = makeSermon(userId: userId, title: "Unsynced", needsSync: true)

        repository.seed(sermons: [syncedSermon, unsyncedSermon])

        let needsSync = try repository.fetchSermonsNeedingSync()
        #expect(needsSync.count == 1)
        #expect(needsSync.first?.title == "Unsynced")
    }
}
