import Testing
import Foundation
@testable import BibleStudy

// MARK: - TranscriptSegmentCache Tests

@Suite("TranscriptSegmentCache")
@MainActor
struct TranscriptSegmentCacheTests {

    // MARK: - Test Helpers

    private func makeTranscript(
        id: UUID = UUID(),
        sermonId: UUID = UUID(),
        content: String = "Test transcript content",
        wordTimestamps: [SermonTranscript.WordTimestamp] = []
    ) -> SermonTranscript {
        SermonTranscript(
            id: id,
            sermonId: sermonId,
            content: content,
            wordTimestamps: wordTimestamps
        )
    }

    private func makeWordTimestamps(count: Int) -> [SermonTranscript.WordTimestamp] {
        (0..<count).map { index in
            SermonTranscript.WordTimestamp(
                word: "word\(index)",
                start: Double(index),
                end: Double(index) + 0.5
            )
        }
    }

    // MARK: - getSegments Tests

    @Suite("getSegments(for:compute:)")
    struct GetSegmentsTests {

        @Test("Returns computed segments on cache miss")
        @MainActor
        func returnsComputedSegmentsOnCacheMiss() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript = SermonTranscript(
                sermonId: UUID(),
                content: "Hello world"
            )

            let expectedSegments = [
                TranscriptDisplaySegment(
                    text: "Hello world",
                    startTime: 0,
                    endTime: 5,
                    wordRange: 0..<2
                )
            ]

            var computeCallCount = 0
            let result = cache.getSegments(for: transcript) {
                computeCallCount += 1
                return expectedSegments
            }

            #expect(result.count == 1)
            #expect(result[0].text == "Hello world")
            #expect(computeCallCount == 1)
        }

        @Test("Returns cached segments on cache hit")
        @MainActor
        func returnsCachedSegmentsOnCacheHit() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript = SermonTranscript(
                sermonId: UUID(),
                content: "Cached content"
            )

            var computeCallCount = 0
            let compute: () -> [TranscriptDisplaySegment] = {
                computeCallCount += 1
                return [TranscriptDisplaySegment(
                    text: "Cached content",
                    startTime: 0,
                    endTime: 10,
                    wordRange: 0..<2
                )]
            }

            // First call - should compute
            _ = cache.getSegments(for: transcript, compute: compute)
            #expect(computeCallCount == 1)

            // Second call - should use cache
            _ = cache.getSegments(for: transcript, compute: compute)
            #expect(computeCallCount == 1) // Still 1, no recomputation
        }

        @Test("Recomputes when updatedAt changes (simulating transcript update)")
        @MainActor
        func recomputesWhenUpdatedAtChanges() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcriptId = UUID()
            let sermonId = UUID()
            let originalUpdatedAt = Date()

            // Original transcript
            let transcript = SermonTranscript(
                id: transcriptId,
                sermonId: sermonId,
                content: "Original content",
                wordTimestamps: [
                    .init(word: "Original", start: 0, end: 0.5),
                    .init(word: "content", start: 0.5, end: 1.0)
                ],
                updatedAt: originalUpdatedAt
            )

            var computeCallCount = 0
            let compute: () -> [TranscriptDisplaySegment] = {
                computeCallCount += 1
                return [TranscriptDisplaySegment(
                    text: "Test",
                    startTime: 0,
                    endTime: 1,
                    wordRange: 0..<1
                )]
            }

            // First call
            _ = cache.getSegments(for: transcript, compute: compute)
            #expect(computeCallCount == 1)

            // Same transcript - should use cache
            _ = cache.getSegments(for: transcript, compute: compute)
            #expect(computeCallCount == 1)

            // Create new transcript with updated timestamps and new updatedAt
            // (simulating how repository updates work - creates new instance)
            let updatedTranscript = SermonTranscript(
                id: transcriptId,
                sermonId: sermonId,
                content: "Original content",
                wordTimestamps: [
                    .init(word: "Original", start: 0, end: 0.5),
                    .init(word: "content", start: 0.5, end: 1.0),
                    .init(word: "new", start: 1.0, end: 1.5)
                ],
                updatedAt: Date()  // New updatedAt triggers cache invalidation
            )

            // Should recompute due to updatedAt change
            _ = cache.getSegments(for: updatedTranscript, compute: compute)
            #expect(computeCallCount == 2)
        }

        @Test("Caches different transcripts independently")
        @MainActor
        func cachesDifferentTranscriptsIndependently() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript1 = SermonTranscript(
                sermonId: UUID(),
                content: "First transcript"
            )

            let transcript2 = SermonTranscript(
                sermonId: UUID(),
                content: "Second transcript"
            )

            var computeCount1 = 0
            var computeCount2 = 0

            _ = cache.getSegments(for: transcript1) {
                computeCount1 += 1
                return []
            }

            _ = cache.getSegments(for: transcript2) {
                computeCount2 += 1
                return []
            }

            // Both should compute (different IDs)
            #expect(computeCount1 == 1)
            #expect(computeCount2 == 1)

            // Access both again - should use cache
            _ = cache.getSegments(for: transcript1) { computeCount1 += 1; return [] }
            _ = cache.getSegments(for: transcript2) { computeCount2 += 1; return [] }

            #expect(computeCount1 == 1) // Still 1
            #expect(computeCount2 == 1) // Still 1
        }
    }

    // MARK: - invalidate Tests

    @Suite("invalidate(transcriptId:)")
    struct InvalidateTests {

        @Test("Invalidates cache for specific transcript")
        @MainActor
        func invalidatesSpecificTranscript() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript = SermonTranscript(
                sermonId: UUID(),
                content: "Content to invalidate"
            )

            var computeCallCount = 0

            // Populate cache
            _ = cache.getSegments(for: transcript) {
                computeCallCount += 1
                return []
            }
            #expect(computeCallCount == 1)

            // Invalidate
            cache.invalidate(transcriptId: transcript.id)

            // Should recompute after invalidation
            _ = cache.getSegments(for: transcript) {
                computeCallCount += 1
                return []
            }
            #expect(computeCallCount == 2)
        }

        @Test("Does not affect other cached transcripts")
        @MainActor
        func doesNotAffectOtherTranscripts() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript1 = SermonTranscript(
                sermonId: UUID(),
                content: "First"
            )

            let transcript2 = SermonTranscript(
                sermonId: UUID(),
                content: "Second"
            )

            var computeCount1 = 0
            var computeCount2 = 0

            // Populate both
            _ = cache.getSegments(for: transcript1) { computeCount1 += 1; return [] }
            _ = cache.getSegments(for: transcript2) { computeCount2 += 1; return [] }

            // Invalidate only transcript1
            cache.invalidate(transcriptId: transcript1.id)

            // transcript1 should recompute
            _ = cache.getSegments(for: transcript1) { computeCount1 += 1; return [] }
            #expect(computeCount1 == 2)

            // transcript2 should still use cache
            _ = cache.getSegments(for: transcript2) { computeCount2 += 1; return [] }
            #expect(computeCount2 == 1) // Still 1
        }

        @Test("Handles invalidation of non-existent transcript gracefully")
        @MainActor
        func handlesNonExistentTranscript() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            // Should not crash
            cache.invalidate(transcriptId: UUID())
        }
    }

    // MARK: - clear Tests

    @Suite("clear()")
    struct ClearTests {

        @Test("Clears all cached entries")
        @MainActor
        func clearsAllEntries() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            let transcript1 = SermonTranscript(sermonId: UUID(), content: "First")
            let transcript2 = SermonTranscript(sermonId: UUID(), content: "Second")

            var computeCount1 = 0
            var computeCount2 = 0

            // Populate cache
            _ = cache.getSegments(for: transcript1) { computeCount1 += 1; return [] }
            _ = cache.getSegments(for: transcript2) { computeCount2 += 1; return [] }

            #expect(computeCount1 == 1)
            #expect(computeCount2 == 1)

            // Clear cache
            cache.clear()

            // Both should recompute
            _ = cache.getSegments(for: transcript1) { computeCount1 += 1; return [] }
            _ = cache.getSegments(for: transcript2) { computeCount2 += 1; return [] }

            #expect(computeCount1 == 2)
            #expect(computeCount2 == 2)
        }

        @Test("Handles clearing empty cache gracefully")
        @MainActor
        func handlesClearingEmptyCache() {
            let cache = TranscriptSegmentCache.shared
            cache.clear()

            // Should not crash
            cache.clear()
        }
    }
}
