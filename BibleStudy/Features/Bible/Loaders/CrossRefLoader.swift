//
//  CrossRefLoader.swift
//  BibleStudy
//
//  Domain loader for cross-reference content
//  Encapsulates fetching, mapping, and fallback logic
//

import Foundation

// Note: CrossReferenceDisplay is defined in BibleInsightViewModel.swift

// MARK: - Cross Reference Load Result

/// Result of loading cross-references
struct CrossRefLoadResult: Sendable {
    let crossRefs: [CrossReferenceDisplay]
    let error: Error?

    static let empty = CrossRefLoadResult(crossRefs: [], error: nil)
}

// MARK: - Cross Reference Loader

/// Loads cross-references for verses
/// Handles database access and fallback to samples
@MainActor
final class CrossRefLoader {
    // MARK: - Dependencies

    private let crossRefService: CrossRefServiceProtocol
    private let bibleService: BibleServiceProtocol

    // MARK: - Initialization

    init(
        crossRefService: CrossRefServiceProtocol? = nil,
        bibleService: BibleServiceProtocol? = nil
    ) {
        self.crossRefService = crossRefService ?? CrossRefService.shared
        self.bibleService = bibleService ?? BibleService.shared
    }

    // MARK: - Load Cross References

    /// Load cross-references for a verse range
    /// - Parameter verseRange: The verse range to find cross-references for
    /// - Returns: CrossRefLoadResult with outgoing and incoming references
    func load(for verseRange: VerseRange) async -> CrossRefLoadResult {
        var outgoingRefs: [CrossReferenceDisplay] = []
        var incomingRefs: [CrossReferenceDisplay] = []

        do {
            // Load outgoing cross-references (this verse references others)
            let refs = try await crossRefService.getCrossReferencesWithText(for: verseRange)
            outgoingRefs = refs.map { ref in
                CrossReferenceDisplay(
                    id: "out-\(ref.crossRef.id)",
                    reference: ref.targetReference,
                    preview: ref.targetText ?? "",
                    weight: ref.crossRef.weight,
                    whyLinked: ref.explanation,
                    targetRange: ref.targetRange,
                    isIncoming: false
                )
            }

            // Load incoming cross-references (other verses reference this)
            let incoming = try crossRefService.getIncomingCrossReferences(for: verseRange)
            for inRef in incoming {
                // Fetch source verse text
                var sourceText = ""
                if let verses = try? await bibleService.getVerses(range: inRef.sourceRange, translationId: nil) {
                    sourceText = verses.map { $0.text }.joined(separator: " ")
                }
                incomingRefs.append(CrossReferenceDisplay(
                    id: "in-\(inRef.id)",
                    reference: inRef.sourceRange.reference,
                    preview: sourceText,
                    weight: inRef.weight,
                    whyLinked: nil,
                    targetRange: inRef.sourceRange,
                    isIncoming: true
                ))
            }
        } catch {
            // Fall back to sample data
            let sampleRefs = crossRefService.getSampleCrossReferences(for: verseRange)
            outgoingRefs = sampleRefs.map { ref in
                CrossReferenceDisplay(
                    id: "out-\(ref.crossRef.id)",
                    reference: ref.targetReference,
                    preview: ref.targetText ?? "",
                    weight: ref.crossRef.weight,
                    whyLinked: ref.explanation,
                    targetRange: ref.targetRange,
                    isIncoming: false
                )
            }

            // If still empty, provide default samples
            if outgoingRefs.isEmpty {
                outgoingRefs = defaultSamples()
            }

            return CrossRefLoadResult(crossRefs: outgoingRefs, error: error)
        }

        // Combine outgoing and incoming, with outgoing first
        let allRefs = outgoingRefs + incomingRefs

        // If still no cross-refs found, provide default samples
        if allRefs.isEmpty {
            return CrossRefLoadResult(crossRefs: defaultSamples(), error: nil)
        }

        return CrossRefLoadResult(crossRefs: allRefs, error: nil)
    }

    // MARK: - Default Samples

    private func defaultSamples() -> [CrossReferenceDisplay] {
        [
            CrossReferenceDisplay(
                id: "1",
                reference: "John 1:4-5",
                preview: "In him was life; and the life was the light of men.",
                weight: 0.95,
                whyLinked: nil,
                targetRange: VerseRange(bookId: 43, chapter: 1, verseStart: 4, verseEnd: 5),
                isIncoming: false
            ),
            CrossReferenceDisplay(
                id: "2",
                reference: "2 Corinthians 4:6",
                preview: "For God, who commanded the light to shine out of darkness...",
                weight: 0.88,
                whyLinked: nil,
                targetRange: VerseRange(bookId: 47, chapter: 4, verseStart: 6, verseEnd: 6),
                isIncoming: false
            )
        ]
    }
}
