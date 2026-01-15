import Foundation

/// Service for matching outline sections to transcript timestamps using word-level timing data.
/// This is a pure, deterministic service that operates on-device.
enum OutlineTimestampMatcher {

    /// Result of finding a match in the transcript
    struct MatchResult: Sendable {
        let wordIndex: Int
        let confidence: Double
    }

    /// Match outline sections to transcript positions using word timestamps.
    /// Uses a cascading strategy: anchorText → title → keyword cluster → proportional fallback.
    ///
    /// - Parameters:
    ///   - outline: Array of outline sections to enrich
    ///   - wordTimestamps: Word-level timestamps from Whisper transcription
    ///   - sermonDuration: Optional sermon duration for endSeconds calculation
    /// - Returns: Outline sections with populated startSeconds, endSeconds, and matchConfidence
    static func matchOutlineToTranscript(
        outline: [OutlineSection],
        wordTimestamps: [SermonTranscript.WordTimestamp],
        sermonDuration: Double? = nil
    ) -> [OutlineSection] {
        guard !wordTimestamps.isEmpty, !outline.isEmpty else { return outline }

        // Normalize all transcript words for matching
        let transcriptTokens = wordTimestamps.map { normalizeToken($0.word) }
        let tokenIndex = buildTokenIndex(tokens: transcriptTokens)

        var enriched = outline
        var startWordIndices: [Int?] = Array(repeating: nil, count: outline.count)
        var confidences: [Double?] = Array(repeating: nil, count: outline.count)

        for i in outline.indices {
            let section = outline[i]

            // Strategy A: Exact match on anchorText (highest confidence)
            if let anchor = section.anchorText, !anchor.isEmpty {
                let anchorTokens = normalizeTokens(anchor)
                if anchorTokens.count >= 3,
                   let exact = findExactPhrase(anchorTokens, in: transcriptTokens, tokenIndex: tokenIndex) {
                    startWordIndices[i] = exact.wordIndex
                    confidences[i] = 1.0
                    continue
                }
            }

            // Strategy B: Exact match on title (if title appears verbatim)
            let titleTokens = normalizeTokens(section.title)
            if titleTokens.count >= 3,
               let exact = findExactPhrase(titleTokens, in: transcriptTokens, tokenIndex: tokenIndex) {
                startWordIndices[i] = exact.wordIndex
                confidences[i] = 0.95
                continue
            }

            // Strategy C: Keyword cluster matching
            if let cluster = findKeywordCluster(titleTokens, tokenIndex: tokenIndex, totalTokens: transcriptTokens.count) {
                startWordIndices[i] = cluster.wordIndex
                confidences[i] = cluster.confidence
                continue
            }

            // Strategy D: Proportional fallback (divide sermon by section count)
            let proportion = Double(i) / max(1.0, Double(outline.count))
            let fallbackIndex = Int(proportion * Double(transcriptTokens.count - 1))
            startWordIndices[i] = max(0, min(fallbackIndex, transcriptTokens.count - 1))
            confidences[i] = 0.30
        }

        // Convert word indices to seconds and compute endSeconds
        let lastEnd = sermonDuration ?? wordTimestamps.last?.end ?? 0

        for i in outline.indices {
            guard let wordIdx = startWordIndices[i] else { continue }

            let start = wordTimestamps[wordIdx].start

            // endSeconds = next section's start, or sermon end
            let nextStart: Double? = {
                guard i + 1 < outline.count,
                      let nextWordIdx = startWordIndices[i + 1] else { return nil }
                return wordTimestamps[nextWordIdx].start
            }()

            enriched[i].startSeconds = start
            enriched[i].endSeconds = nextStart ?? lastEnd
            enriched[i].matchConfidence = confidences[i]
        }

        return enriched
    }

    // MARK: - Text Normalization

    /// Normalize a single token: lowercase, remove punctuation
    private static func normalizeToken(_ token: String) -> String {
        token.lowercased()
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }

    /// Normalize text into array of tokens, filtering short noise words
    private static func normalizeTokens(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map { normalizeToken(String($0)) }
            .filter { $0.count >= 2 }  // Drop noise like "a", "I"
    }

    // MARK: - Token Index

    /// Build inverted index: token → [positions where it appears]
    private static func buildTokenIndex(tokens: [String]) -> [String: [Int]] {
        var index: [String: [Int]] = [:]
        index.reserveCapacity(tokens.count / 4)

        for (i, token) in tokens.enumerated() {
            index[token, default: []].append(i)
        }
        return index
    }

    // MARK: - Matching Strategies

    /// Find exact phrase match in transcript
    private static func findExactPhrase(
        _ phraseTokens: [String],
        in transcriptTokens: [String],
        tokenIndex: [String: [Int]]
    ) -> MatchResult? {
        guard phraseTokens.count >= 3 else { return nil }
        guard let firstToken = phraseTokens.first,
              let candidates = tokenIndex[firstToken] else { return nil }

        // For each occurrence of the first word, check if the phrase continues
        for startIdx in candidates {
            let endIdx = startIdx + phraseTokens.count
            guard endIdx <= transcriptTokens.count else { continue }

            let window = Array(transcriptTokens[startIdx..<endIdx])
            if window == phraseTokens {
                return MatchResult(wordIndex: startIdx, confidence: 1.0)
            }
        }
        return nil
    }

    /// Find densest cluster of keywords from the title
    private static func findKeywordCluster(
        _ tokens: [String],
        tokenIndex: [String: [Int]],
        totalTokens: Int
    ) -> MatchResult? {
        // Only use meaningful keywords (4+ chars)
        let keywords = Array(Set(tokens)).filter { $0.count >= 4 }
        guard keywords.count >= 2 else { return nil }

        // Collect all positions where any keyword appears
        var positions: [Int] = []
        for keyword in keywords {
            if let indices = tokenIndex[keyword] {
                positions.append(contentsOf: indices)
            }
        }
        positions.sort()
        guard positions.count >= 2 else { return nil }

        // Sliding window to find densest cluster (within 80 words)
        let windowSize = 80
        var best: (start: Int, count: Int) = (0, 0)
        var left = 0

        for right in positions.indices {
            // Shrink window from left while too wide
            while positions[right] - positions[left] > windowSize {
                left += 1
            }
            let count = right - left + 1
            if count > best.count {
                best = (positions[left], count)
            }
        }

        // Require at least 2 keywords in cluster
        guard best.count >= 2 else { return nil }

        // Confidence scales with density, capped at 0.9
        let confidence = min(0.9, 0.5 + (Double(best.count) / 10.0))
        return MatchResult(wordIndex: best.start, confidence: confidence)
    }
}
