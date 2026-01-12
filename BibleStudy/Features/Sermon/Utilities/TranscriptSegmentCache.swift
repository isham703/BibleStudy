import Foundation

// MARK: - Transcript Segment Cache
// Caches computed display segments to avoid O(n) recomputation on every access
// Invalidates automatically when wordTimestamps change

@MainActor
final class TranscriptSegmentCache {
    // MARK: - Singleton

    static let shared = TranscriptSegmentCache()

    // MARK: - Cache Storage

    private var cache: [UUID: CacheEntry] = [:]

    private struct CacheEntry {
        let segments: [TranscriptDisplaySegment]
        let hash: Int
    }

    // MARK: - Initialization

    private init() {}

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
            return entry.segments
        }

        // Compute and cache
        let segments = compute()
        cache[transcript.id] = CacheEntry(segments: segments, hash: currentHash)
        return segments
    }

    /// Clear cache for a specific transcript
    func invalidate(transcriptId: UUID) {
        cache.removeValue(forKey: transcriptId)
    }

    /// Clear entire cache
    func clear() {
        cache.removeAll()
    }
}
