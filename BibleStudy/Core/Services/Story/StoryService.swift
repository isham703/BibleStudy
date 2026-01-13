import Foundation
import GRDB
import Auth
import Supabase

// MARK: - Story Service Errors

enum StoryServiceError: Error, LocalizedError {
    case notAuthenticated
    case storyNotFound
    case segmentNotFound
    case progressNotFound
    case databaseError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to access this feature"
        case .storyNotFound:
            return "Story not found"
        case .segmentNotFound:
            return "Story segment not found"
        case .progressNotFound:
            return "Story progress not found"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .decodingError(let message):
            return "Failed to decode story data: \(message)"
        }
    }
}

// MARK: - Story Service
// Manages biblical narrative stories with interactive timeline

@MainActor
@Observable
final class StoryService {
    // MARK: - Singleton
    static let shared = StoryService()

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared
    private let db = DatabaseStore.shared

    // MARK: - State
    var prebuiltStories: [Story] = []
    var userStories: [Story] = []
    var progressMap: [UUID: StoryProgress] = [:] // storyId -> progress
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Computed Properties

    var allStories: [Story] {
        prebuiltStories + userStories
    }

    var inProgressStories: [Story] {
        allStories.filter { story in
            if let progress = progressMap[story.id] {
                return progress.isStarted && !progress.isCompleted
            }
            return false
        }
    }

    var completedStories: [Story] {
        allStories.filter { story in
            progressMap[story.id]?.isCompleted == true
        }
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Load Stories

    func loadStories() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await loadPrebuiltStories()
            // Load progress for current user (authenticated or local anonymous)
            try await loadUserProgress()
        } catch {
            self.error = error
        }
    }

    func loadPrebuiltStories() async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        prebuiltStories = try fetchPrebuiltStories(dbQueue: dbQueue)

        // If no prebuilt stories in DB, try to seed from bundle
        if prebuiltStories.isEmpty {
            try await seedPrebuiltStoriesFromBundle()
            prebuiltStories = try fetchPrebuiltStories(dbQueue: dbQueue)
        }
    }

    private nonisolated func fetchPrebuiltStories(dbQueue: DatabaseQueue) throws -> [Story] {
        try dbQueue.read { db in
            var stories = try Story
                .filter(Story.Columns.isPrebuilt == true)
                .order(Story.Columns.createdAt.asc)
                .fetchAll(db)

            // Load segments for each story
            for i in stories.indices {
                stories[i].segments = try StorySegment
                    .filter(StorySegment.Columns.storyId == stories[i].id)
                    .order(StorySegment.Columns.order.asc)
                    .fetchAll(db)
            }

            return stories
        }
    }

    // MARK: - Get Stories by Type/Level

    func getStories(type: StoryType? = nil, level: StoryReadingLevel? = nil) -> [Story] {
        var filtered = prebuiltStories

        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }

        if let level = level {
            filtered = filtered.filter { $0.readingLevel == level }
        }

        return filtered
    }

    // MARK: - Get Single Story with Segments

    func getStory(id: UUID) async throws -> Story {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try fetchStoryWithSegments(id: id, dbQueue: dbQueue)
    }

    private nonisolated func fetchStoryWithSegments(id: UUID, dbQueue: DatabaseQueue) throws -> Story {
        try dbQueue.read { db in
            guard var story = try Story
                .filter(Story.Columns.id == id)
                .fetchOne(db) else {
                throw StoryServiceError.storyNotFound
            }

            story.segments = try StorySegment
                .filter(StorySegment.Columns.storyId == id)
                .order(StorySegment.Columns.order.asc)
                .fetchAll(db)

            return story
        }
    }

    // MARK: - Progress Management

    func loadUserProgress(userId: UUID? = nil) async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        let effectiveUserId = userId ?? currentUserId
        let progressList = try fetchUserProgress(userId: effectiveUserId, dbQueue: dbQueue)
        progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.storyId, $0) })
    }

    private nonisolated func fetchUserProgress(userId: UUID, dbQueue: DatabaseQueue) throws -> [StoryProgress] {
        try dbQueue.read { db in
            try StoryProgress
                .filter(StoryProgress.Columns.userId == userId.uuidString)
                .fetchAll(db)
        }
    }

    func getProgress(for storyId: UUID) -> StoryProgress? {
        progressMap[storyId]
    }

    /// Local anonymous user ID for offline progress tracking
    private var localUserId: UUID {
        let key = "local_anonymous_user_id"
        if let stored = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: stored) {
            return uuid
        }
        let newId = UUID()
        UserDefaults.standard.set(newId.uuidString, forKey: key)
        return newId
    }

    /// Current user ID - authenticated or local anonymous
    private var currentUserId: UUID {
        supabase.currentUser?.id ?? localUserId
    }

    func startStory(_ story: Story) async throws -> StoryProgress {
        let userId = currentUserId

        // Check if progress already exists
        if let existing = progressMap[story.id] {
            return existing
        }

        let progress = StoryProgress(
            userId: userId,
            storyId: story.id,
            needsSync: supabase.currentUser != nil // Only sync if authenticated
        )

        try await saveProgress(progress)
        progressMap[story.id] = progress

        return progress
    }

    func updateProgress(_ progress: StoryProgress) async throws {
        var updatedProgress = progress
        updatedProgress.needsSync = true

        try await saveProgress(updatedProgress)
        progressMap[progress.storyId] = updatedProgress
    }

    private func saveProgress(_ progress: StoryProgress) async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveProgressToCache(progress, dbQueue: dbQueue)
    }

    private nonisolated func saveProgressToCache(_ progress: StoryProgress, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try progress.save(db)
        }
    }

    func completeSegment(segmentId: UUID, in storyId: UUID) async throws {
        guard var progress = progressMap[storyId] else {
            throw StoryServiceError.progressNotFound
        }

        progress.markSegmentComplete(segmentId)
        try await updateProgress(progress)
    }

    func saveReflection(_ text: String, for segmentId: UUID, in storyId: UUID) async throws {
        guard var progress = progressMap[storyId] else {
            throw StoryServiceError.progressNotFound
        }

        progress.saveReflection(text, for: segmentId)
        try await updateProgress(progress)
    }

    func advanceToSegment(_ index: Int, in storyId: UUID) async throws {
        guard var progress = progressMap[storyId] else {
            throw StoryServiceError.progressNotFound
        }

        progress.advanceToSegment(index)
        try await updateProgress(progress)
    }

    func markStoryCompleted(_ storyId: UUID) async throws {
        guard var progress = progressMap[storyId] else {
            throw StoryServiceError.progressNotFound
        }

        progress.markCompleted()
        try await updateProgress(progress)
    }

    // MARK: - Seed Prebuilt Stories

    func seedPrebuiltStoriesFromBundle() async throws {
        guard let url = Bundle.main.url(forResource: "PrebuiltStories", withExtension: "json") else {
            // No bundle file yet, that's okay
            return
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        // Decode using DTOs to avoid circular reference issues with GRDB
        let bundle = try decoder.decode(StoriesBundle.self, from: data)
        let stories = bundle.stories.map { $0.toStory() }

        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try seedStoriesToDatabase(stories, dbQueue: dbQueue)
    }

    private nonisolated func seedStoriesToDatabase(_ stories: [Story], dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            for story in stories {
                // Check if already exists
                let exists = try Story
                    .filter(Story.Columns.slug == story.slug)
                    .fetchCount(db) > 0

                if !exists {
                    try story.insert(db)

                    // Insert segments
                    for segment in story.segments {
                        try segment.insert(db)
                    }

                    // Insert characters
                    for character in story.characters {
                        try character.insert(db)
                    }
                }
            }
        }
    }

    // MARK: - Save User-Generated Story

    func saveStory(_ story: Story) async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveStoryToCache(story, dbQueue: dbQueue)

        // Update local state
        if story.isPrebuilt {
            if let index = prebuiltStories.firstIndex(where: { $0.id == story.id }) {
                prebuiltStories[index] = story
            } else {
                prebuiltStories.append(story)
            }
        } else {
            if let index = userStories.firstIndex(where: { $0.id == story.id }) {
                userStories[index] = story
            } else {
                userStories.append(story)
            }
        }
    }

    private nonisolated func saveStoryToCache(_ story: Story, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try story.save(db)

            // Save segments
            for segment in story.segments {
                try segment.save(db)
            }

            // Save characters
            for character in story.characters {
                try character.save(db)
            }
        }
    }

    // MARK: - Delete Story

    func deleteStory(_ storyId: UUID) async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try deleteStoryFromCache(storyId, dbQueue: dbQueue)

        // Update local state
        userStories.removeAll { $0.id == storyId }
        progressMap.removeValue(forKey: storyId)
    }

    private nonisolated func deleteStoryFromCache(_ storyId: UUID, dbQueue: DatabaseQueue) throws {
        _ = try dbQueue.write { db in
            try Story
                .filter(Story.Columns.id == storyId.uuidString)
                .deleteAll(db)
            // Segments and progress are cascade deleted
        }
    }

    // MARK: - Sync to Supabase

    /// Sync all pending progress to Supabase
    func syncProgress() async throws {
        guard let userId = supabase.currentUser?.id else {
            return // Not authenticated, skip sync
        }

        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        // Get all progress needing sync
        let pendingProgress = try fetchPendingProgress(dbQueue: dbQueue)

        for progress in pendingProgress {
            do {
                try await pushProgressToSupabase(progress)
                try markProgressSynced(progress.id, dbQueue: dbQueue)
            } catch {
                // Log error but continue with other items
                print("Failed to sync progress for story \(progress.storyId): \(error)")
            }
        }

        // Update local state
        progressMap = Dictionary(uniqueKeysWithValues:
            try fetchUserProgress(userId: userId, dbQueue: dbQueue).map { ($0.storyId, $0) }
        )
    }

    private nonisolated func fetchPendingProgress(dbQueue: DatabaseQueue) throws -> [StoryProgress] {
        try dbQueue.read { db in
            try StoryProgress
                .filter(StoryProgress.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    private func pushProgressToSupabase(_ progress: StoryProgress) async throws {
        // Convert to Supabase format
        let payload: [String: StoryAnyEncodable] = [
            "id": StoryAnyEncodable(progress.id.uuidString),
            "user_id": StoryAnyEncodable(progress.userId.uuidString),
            "story_id": StoryAnyEncodable(progress.storyId.uuidString),
            "current_segment_index": StoryAnyEncodable(progress.currentSegmentIndex),
            "completed_segment_ids": StoryAnyEncodable(progress.completedSegmentIds.map { $0.uuidString }),
            "started_at": StoryAnyEncodable(progress.startedAt.ISO8601Format()),
            "last_read_at": StoryAnyEncodable(progress.lastReadAt.ISO8601Format()),
            "completed_at": StoryAnyEncodable(progress.completedAt?.ISO8601Format()),
            "reflection_notes": StoryAnyEncodable(progress.reflectionNotes.mapKeys { $0.uuidString })
        ]

        try await supabase.client.from("story_progress")
            .upsert(payload, onConflict: "user_id,story_id")
            .execute()
    }

    private nonisolated func markProgressSynced(_ progressId: UUID, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE story_progress SET needs_sync = 0 WHERE id = ?",
                arguments: [progressId.uuidString]
            )
        }
    }

    /// Fetch remote progress and merge with local (last-write-wins)
    func fetchRemoteProgress() async throws {
        guard let userId = supabase.currentUser?.id else {
            return
        }

        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        let response = try await supabase.client.from("story_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let remoteProgressList = try? decoder.decode([RemoteStoryProgress].self, from: response.data) else {
            return
        }

        // Merge with local - remote wins if newer
        for remote in remoteProgressList {
            let localProgress = progressMap[remote.storyId]

            if localProgress == nil || remote.lastReadAt > (localProgress?.lastReadAt ?? .distantPast) {
                let progress = remote.toStoryProgress()
                try saveProgressToCache(progress, dbQueue: dbQueue)
                progressMap[remote.storyId] = progress
            }
        }
    }
}

// MARK: - Remote Progress DTO

private struct RemoteStoryProgress: Codable {
    let id: UUID
    let userId: UUID
    let storyId: UUID
    let currentSegmentIndex: Int
    let completedSegmentIds: [UUID]
    let startedAt: Date
    let lastReadAt: Date
    let completedAt: Date?
    let reflectionNotes: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storyId = "story_id"
        case currentSegmentIndex = "current_segment_index"
        case completedSegmentIds = "completed_segment_ids"
        case startedAt = "started_at"
        case lastReadAt = "last_read_at"
        case completedAt = "completed_at"
        case reflectionNotes = "reflection_notes"
    }

    func toStoryProgress() -> StoryProgress {
        StoryProgress(
            id: id,
            userId: userId,
            storyId: storyId,
            currentSegmentIndex: currentSegmentIndex,
            completedSegmentIds: Set(completedSegmentIds),
            startedAt: startedAt,
            lastReadAt: lastReadAt,
            completedAt: completedAt,
            reflectionNotes: reflectionNotes.reduce(into: [:]) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            },
            needsSync: false
        )
    }
}

// MARK: - Helper for Encodable Any

private struct StoryAnyEncodable: Encodable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value {
            switch value {
            case let string as String:
                try container.encode(string)
            case let int as Int:
                try container.encode(int)
            case let bool as Bool:
                try container.encode(bool)
            case let array as [String]:
                try container.encode(array)
            case let dict as [String: String]:
                try container.encode(dict)
            default:
                try container.encodeNil()
            }
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Dictionary Extension

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}

