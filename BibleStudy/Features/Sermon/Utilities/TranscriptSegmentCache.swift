import Foundation
import UIKit

// MARK: - Transcript Segment Cache
// Caches computed display segments to avoid O(n) recomputation on every access
// Invalidates automatically when wordTimestamps change
// Uses LRU eviction and responds to memory pressure

@MainActor
final class TranscriptSegmentCache {
    // MARK: - Singleton

    static let shared = TranscriptSegmentCache()

    // MARK: - Configuration

    private let maxCapacity = 100

    // MARK: - Cache Storage

    private var cache: [UUID: CacheEntry] = [:]
    private var accessOrder: [UUID] = []

    private struct CacheEntry {
        let segments: [TranscriptDisplaySegment]
        let hash: Int
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
        let currentHash = transcript.wordTimestamps.hashValue

        // Check if cached and valid
        if let entry = cache[transcript.id], entry.hash == currentHash {
            updateAccessOrder(for: transcript.id)
            return entry.segments
        }

        // Compute and cache
        let segments = compute()
        cache[transcript.id] = CacheEntry(segments: segments, hash: currentHash)
        updateAccessOrder(for: transcript.id)
        evictIfNeeded()
        return segments
    }

    /// Clear cache for a specific transcript
    func invalidate(transcriptId: UUID) {
        cache.removeValue(forKey: transcriptId)
        accessOrder.removeAll { $0 == transcriptId }
    }

    /// Clear cache for a sermon (by sermon ID, which maps to transcript ID)
    func invalidate(sermonId: UUID) {
        // In practice, 1 sermon = 1 transcript with matching ID
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
