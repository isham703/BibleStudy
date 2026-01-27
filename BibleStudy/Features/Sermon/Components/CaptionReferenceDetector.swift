import Foundation

// MARK: - Caption Reference Detector
// Scans live caption text for Bible references using ReferenceParser.
// Runs on accumulating text to detect references as they are spoken.
// Deduplicates by canonical ID to avoid repeated detections.

enum CaptionReferenceDetector {
    /// Scan text for new Bible references not already in the seen set.
    /// Returns newly detected references (deduped against `seenIds`).
    /// Adds new canonical IDs to `seenIds` in place.
    static func detectNew(
        in text: String,
        seenIds: inout Set<String>
    ) -> [ParsedReference] {
        let allRefs = ReferenceParser.extractAll(from: text)
        var newRefs: [ParsedReference] = []

        for ref in allRefs {
            let canonicalId = ReferenceParser.canonicalId(for: ref)
            if !seenIds.contains(canonicalId) {
                seenIds.insert(canonicalId)
                newRefs.append(ref)
            }
        }

        return newRefs
    }

    /// Find all reference ranges in a text string for highlighting.
    /// Returns tuples of (range in text, parsed reference).
    static func findRanges(
        in text: String
    ) -> [(range: Range<String.Index>, reference: ParsedReference)] {
        var results: [(Range<String.Index>, ParsedReference)] = []

        let regex = ReferenceParser.candidateRegex
        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let candidate = String(text[matchRange]).trimmingCharacters(in: .whitespaces)

            if case .success(let parsed) = ReferenceParser.parseFlexible(candidate) {
                results.append((matchRange, parsed))
            }
        }

        return results
    }
}
