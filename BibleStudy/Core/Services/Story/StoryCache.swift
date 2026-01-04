import Foundation

// MARK: - Story Cache
// Caches AI-generated stories to reduce API calls and improve response time

@MainActor
final class StoryCache {
    // MARK: - Singleton
    static let shared = StoryCache()

    // MARK: - Cache Storage
    private var storyCache: [String: CachedStory] = [:]

    // MARK: - Configuration
    private let maxCacheSize = 20
    private let cacheExpirationHours: TimeInterval = 24

    // MARK: - Cache Entry
    private struct CachedStory {
        let story: Story
        let createdAt: Date
        var lastAccessed: Date

        var isExpired: Bool {
            Date().timeIntervalSince(createdAt) > (24 * 3600) // 24 hours
        }

        init(story: Story) {
            self.story = story
            self.createdAt = Date()
            self.lastAccessed = Date()
        }
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Cache Key Generation

    /// Generate cache key for a verse range and reading level
    func key(for range: VerseRange, level: StoryReadingLevel, type: StoryType = .narrative) -> String {
        "\(range.id):\(level.rawValue):\(type.rawValue)"
    }

    /// Generate cache key from story generation parameters
    func key(
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        level: StoryReadingLevel,
        type: StoryType = .narrative
    ) -> String {
        let rangeId = "\(bookId).\(chapter).\(verseStart)-\(verseEnd)"
        return "\(rangeId):\(level.rawValue):\(type.rawValue)"
    }

    // MARK: - Get Cached Story

    func get(key: String) -> Story? {
        guard var cached = storyCache[key], !cached.isExpired else {
            storyCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        storyCache[key] = cached
        return cached.story
    }

    func get(for range: VerseRange, level: StoryReadingLevel, type: StoryType = .narrative) -> Story? {
        let cacheKey = key(for: range, level: level, type: type)
        return get(key: cacheKey)
    }

    // MARK: - Set Cached Story

    func set(_ story: Story, for key: String) {
        evictIfNeeded()
        storyCache[key] = CachedStory(story: story)
    }

    func set(_ story: Story, for range: VerseRange, level: StoryReadingLevel, type: StoryType = .narrative) {
        let cacheKey = key(for: range, level: level, type: type)
        set(story, for: cacheKey)
    }

    // MARK: - Cache Management

    func clear() {
        storyCache.removeAll()
    }

    func removeExpired() {
        storyCache = storyCache.filter { !$0.value.isExpired }
    }

    var count: Int {
        storyCache.count
    }

    // MARK: - Private Helpers

    private func evictIfNeeded() {
        // Remove expired entries first
        removeExpired()

        // If still over limit, remove least recently accessed
        if storyCache.count >= maxCacheSize {
            let sortedKeys = storyCache
                .sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                .prefix(storyCache.count - maxCacheSize + 1)
                .map { $0.key }

            for key in sortedKeys {
                storyCache.removeValue(forKey: key)
            }
        }
    }
}
