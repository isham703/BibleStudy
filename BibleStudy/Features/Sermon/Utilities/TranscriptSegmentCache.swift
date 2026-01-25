import Foundation
import UIKit

// MARK: - Transcript Segment Cache
// Caches computed display segments to avoid O(n) recomputation on every access
// Invalidates automatically when updatedAt changes (O(1) check)
// Uses LRU eviction and responds to memory pressure
//
// NOTE: This cache relies on SermonTranscript.updatedAt for invalidation.
// SermonTranscript is effectively immutable after creation - properties are only
// set during initialization (via TranscriptionService) or DTO conversion.
// The `var` declarations exist for GRDB's FetchableRecord protocol compliance.
// If transcript mutation is ever needed, add mutation methods that update updatedAt.

@MainActor
final class TranscriptSegmentCache {
    // MARK: - Singleton

    static let shared = TranscriptSegmentCache()

    // MARK: - Configuration

    private let maxCapacity = SermonConfiguration.maxCacheEntries

    // MARK: - Cache Storage

    private var cache: [UUID: CacheEntry] = [:]
    private var accessOrder: [UUID] = []

    private struct CacheEntry {
        let segments: [TranscriptDisplaySegment]
        let updatedAt: Date  // O(1) invalidation check (was O(n) hashValue)
    }

    // MARK: - Memory Warning Observer

    private var memoryWarningToken: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        // Use block-based observer to avoid @MainActor + selector issues
        memoryWarningToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.respondToMemoryWarning()
        }
    }

    deinit {
        if let token = memoryWarningToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Public API

    /// Get cached segments or compute and cache new ones
    /// - Parameters:
    ///   - transcript: The transcript to get segments for
    ///   - compute: Closure that computes segments if not cached
    /// - Returns: The display segments for the transcript
    func getSegments(
        for transcript: SermonTranscript,
        compute: () -> [TranscriptDisplaySegment]
    ) -> [TranscriptDisplaySegment] {
        let cacheKey = transcript.sermonId  // Use sermonId for consistent cache invalidation

        // Check if cached and valid (O(1) updatedAt comparison vs O(n) hashValue)
        if let entry = cache[cacheKey], entry.updatedAt == transcript.updatedAt {
            updateAccessOrder(for: cacheKey)
            return entry.segments
        }

        // Compute and cache
        let segments = compute()
        cache[cacheKey] = CacheEntry(segments: segments, updatedAt: transcript.updatedAt)
        updateAccessOrder(for: cacheKey)
        evictIfNeeded()
        return segments
    }

    /// Clear cache for a sermon
    /// - Parameter sermonId: The sermon ID to invalidate cache for
    func invalidate(sermonId: UUID) {
        cache.removeValue(forKey: sermonId)
        accessOrder.removeAll { $0 == sermonId }
    }

    /// Clear entire cache
    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    // MARK: - LRU Management

    private func updateAccessOrder(for id: UUID) {
        // Remove before append to avoid duplicates and maintain LRU order
        accessOrder.removeAll { $0 == id }
        accessOrder.append(id)
    }

    private func evictIfNeeded() {
        while cache.count > maxCapacity, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
    }

    // MARK: - Memory Pressure Response

    private func respondToMemoryWarning() {
        // Evict 50% of cache on memory warning
        let toEvict = cache.count / 2
        for _ in 0..<toEvict {
            guard let oldest = accessOrder.first else { break }
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }

        #if DEBUG
        print("[TranscriptSegmentCache] Memory warning: evicted \(toEvict) entries, \(cache.count) remaining")
        #endif
    }

    // MARK: - Testing Support

    #if DEBUG
    var count: Int { cache.count }
    var accessOrderCount: Int { accessOrder.count }
    #endif
}
