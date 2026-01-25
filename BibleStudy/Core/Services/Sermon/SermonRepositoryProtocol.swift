import Foundation

// MARK: - Sermon Repository Protocol
// Defines the data access interface for all Sermon-related entities.
// Follows BibleRepository pattern: synchronous throws, @unchecked Sendable implementation.

protocol SermonRepositoryProtocol: Sendable {

    // MARK: - Sermon Operations

    /// Fetch paginated sermons for a user with cursor-based pagination
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - includeDeleted: Whether to include soft-deleted sermons
    ///   - cursor: Optional cursor for pagination (nil = first page)
    ///   - limit: Maximum number of sermons to return
    /// - Returns: Paginated result with sermons and next cursor
    func fetchSermons(
        userId: UUID,
        includeDeleted: Bool,
        cursor: SermonCursor?,
        limit: Int
    ) throws -> PaginatedSermons

    /// Fetch all sermons for a user (legacy, non-paginated)
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - includeDeleted: Whether to include soft-deleted sermons
    /// - Returns: All matching sermons sorted by recordedAt descending
    func fetchAllSermons(userId: UUID, includeDeleted: Bool) throws -> [Sermon]

    /// Fetch a single sermon by ID
    func fetchSermon(id: UUID) throws -> Sermon?

    /// Save a sermon (insert or update)
    func saveSermon(_ sermon: Sermon) throws

    /// Update an existing sermon
    func updateSermon(_ sermon: Sermon) throws

    /// Fetch sermons that need to be synced with remote
    func fetchSermonsNeedingSync() throws -> [Sermon]

    // MARK: - Audio Chunk Operations

    /// Save an audio chunk with upsert semantics
    /// - Note: Preserves original chunk ID when updating by (sermonId, chunkIndex)
    func saveChunk(_ chunk: SermonAudioChunk) throws

    /// Update an existing chunk
    func updateChunk(_ chunk: SermonAudioChunk) throws

    /// Fetch all chunks for a sermon sorted by index
    func fetchChunks(sermonId: UUID) throws -> [SermonAudioChunk]

    /// Fetch a single chunk by ID
    func fetchChunk(id: UUID) throws -> SermonAudioChunk?

    /// Fetch chunks that need to be synced
    func fetchChunksNeedingSync() throws -> [SermonAudioChunk]

    // MARK: - Transcript Operations

    /// Fetch transcript for a sermon
    func fetchTranscript(sermonId: UUID) throws -> SermonTranscript?

    /// Save a transcript (insert or update)
    func saveTranscript(_ transcript: SermonTranscript) throws

    /// Update an existing transcript
    func updateTranscript(_ transcript: SermonTranscript) throws

    /// Fetch transcripts that need to be synced
    func fetchTranscriptsNeedingSync() throws -> [SermonTranscript]

    // MARK: - Study Guide Operations

    /// Fetch study guide for a sermon
    func fetchStudyGuide(sermonId: UUID) throws -> SermonStudyGuide?

    /// Save a study guide (insert or update)
    func saveStudyGuide(_ guide: SermonStudyGuide) throws

    /// Update an existing study guide
    func updateStudyGuide(_ guide: SermonStudyGuide) throws

    /// Fetch study guides that need to be synced
    func fetchStudyGuidesNeedingSync() throws -> [SermonStudyGuide]

    // MARK: - Bookmark Operations

    /// Fetch bookmarks for a sermon
    func fetchBookmarks(sermonId: UUID, includeDeleted: Bool) throws -> [SermonBookmark]

    /// Save a bookmark (insert or update)
    func saveBookmark(_ bookmark: SermonBookmark) throws

    /// Update an existing bookmark
    func updateBookmark(_ bookmark: SermonBookmark) throws

    /// Fetch bookmarks that need to be synced
    func fetchBookmarksNeedingSync() throws -> [SermonBookmark]

    // MARK: - Bulk Operations

    /// Save multiple sermons in a single transaction
    func saveSermons(_ sermons: [Sermon]) throws

    /// Delete a sermon and all related data (cascading)
    /// - Note: Performs soft delete by setting deletedAt
    func softDeleteSermon(id: UUID) throws

    /// Update a sermon's title
    func updateSermonTitle(_ id: UUID, title: String) throws
}

// MARK: - Pagination Types

/// Cursor for stable cursor-based pagination
/// Uses (recordedAt, id) tuple for deterministic ordering even with identical timestamps
struct SermonCursor: Codable, Sendable, Equatable {
    let recordedAt: Date
    let id: UUID

    /// Create cursor from a sermon
    init(from sermon: Sermon) {
        self.recordedAt = sermon.recordedAt
        self.id = sermon.id
    }

    init(recordedAt: Date, id: UUID) {
        self.recordedAt = recordedAt
        self.id = id
    }
}

/// Result of a paginated sermon fetch
struct PaginatedSermons: Sendable {
    /// The fetched sermons
    let sermons: [Sermon]

    /// Cursor for the next page (nil if no more results)
    let nextCursor: SermonCursor?

    /// Whether there are more results after this page
    let hasMore: Bool

    /// Total count of matching sermons (optional, expensive to compute)
    let totalCount: Int?

    init(sermons: [Sermon], nextCursor: SermonCursor?, hasMore: Bool, totalCount: Int? = nil) {
        self.sermons = sermons
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.totalCount = totalCount
    }

    /// Empty result with no more pages
    static let empty = PaginatedSermons(sermons: [], nextCursor: nil, hasMore: false, totalCount: 0)
}

// MARK: - Default Pagination Values

enum SermonPaginationDefaults {
    /// Default page size for sermon lists
    static let defaultPageSize = 20

    /// Maximum allowed page size
    static let maxPageSize = 100
}

// MARK: - Repository Error

enum SermonRepositoryError: Error, LocalizedError {
    case databaseNotInitialized
    case sermonNotFound(UUID)
    case chunkNotFound(UUID)
    case transcriptNotFound(UUID)
    case studyGuideNotFound(UUID)
    case bookmarkNotFound(UUID)
    case invalidCursor
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .databaseNotInitialized:
            return "Database is not initialized"
        case .sermonNotFound(let id):
            return "Sermon not found: \(id)"
        case .chunkNotFound(let id):
            return "Audio chunk not found: \(id)"
        case .transcriptNotFound(let id):
            return "Transcript not found for sermon: \(id)"
        case .studyGuideNotFound(let id):
            return "Study guide not found for sermon: \(id)"
        case .bookmarkNotFound(let id):
            return "Bookmark not found: \(id)"
        case .invalidCursor:
            return "Invalid pagination cursor"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        }
    }
}
