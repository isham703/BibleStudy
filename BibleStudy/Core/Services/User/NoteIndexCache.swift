import Foundation

// MARK: - Note Index Cache
// LRU cache for per-chapter note indexes
// Follows HighlightIndexCache pattern

@MainActor
final class NoteIndexCache {
    // MARK: - Cache Structure

    private struct CachedIndex {
        let index: NoteIndex
        var lastAccessed: Date
    }

    // MARK: - Properties

    private var cache: [String: CachedIndex] = [:]
    private let maxCacheSize = 5  // Keep 5 most recent chapters

    // MARK: - Cache Key

    private func cacheKey(bookId: Int, chapter: Int) -> String {
        "\(bookId):\(chapter)"
    }

    // MARK: - Public API

    /// Get or build note index for a chapter
    /// Returns cached index if available, otherwise builds and caches a new one
    func getIndex(for chapter: Int, bookId: Int, notes: [Note]) -> NoteIndex {
        let key = cacheKey(bookId: bookId, chapter: chapter)

        // Check cache
        if var cached = cache[key] {
            cached.lastAccessed = Date()
            cache[key] = cached
            return cached.index
        }

        // Build new index
        let index = NoteIndex(notes: notes)

        // Evict oldest if needed
        evictIfNeeded()

        // Cache it
        cache[key] = CachedIndex(index: index, lastAccessed: Date())
        return index
    }

    /// Invalidate cache for a specific chapter
    /// Call this when notes are created, deleted, or modified
    func invalidate(chapter: Int, bookId: Int) {
        let key = cacheKey(bookId: bookId, chapter: chapter)
        cache.removeValue(forKey: key)
    }

    /// Invalidate all cached indexes
    /// Call this on user logout or major data changes
    func invalidateAll() {
        cache.removeAll()
    }

    // MARK: - LRU Eviction

    private func evictIfNeeded() {
        while cache.count >= maxCacheSize {
            // Find oldest entry by lastAccessed
            guard let oldestKey = cache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })?.key else {
                break
            }
            cache.removeValue(forKey: oldestKey)
        }
    }

    // MARK: - Debug

    #if DEBUG
    var cacheCount: Int { cache.count }
    var cachedKeys: [String] { Array(cache.keys) }
    #endif
}
