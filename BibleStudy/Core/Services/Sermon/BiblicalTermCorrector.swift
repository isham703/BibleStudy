//
//  BiblicalTermCorrector.swift
//  BibleStudy
//
//  Applies biblical term corrections to transcribed text.
//  Maps common STT misrecognitions back to canonical book names.
//  Uses sliding window n-gram matching with reference context detection.
//

import Foundation

// MARK: - Correction Overlay

/// A correction overlay for a transcript word range.
/// Stored separately from raw transcript to preserve timestamp integrity.
struct CorrectionOverlay: Codable, Hashable, Sendable {
    /// Index of the first word being replaced in the word timestamps array
    let startWordIndex: Int
    /// Number of words being replaced (1 for single-word, 2+ for multi-word)
    let wordCount: Int
    /// The corrected text to display
    let correctedText: String
    /// The original raw text that was replaced
    let originalText: String
    /// Confidence score for the correction (0.0-1.0)
    let confidence: Double
}

// MARK: - Biblical Term Corrector

enum BiblicalTermCorrector {
    // MARK: - Confusion Map

    /// Known STT misrecognitions mapped to canonical book names.
    /// Keys are lowercase normalized misrecognitions; values are canonical names.
    /// Focus on the worst offenders from real Whisper outputs.
    static let confusionMap: [String: String] = [
        // Habakkuk - commonly misheard
        "have a cook": "Habakkuk",
        "have a coke": "Habakkuk",
        "habba cook": "Habakkuk",
        "haba cook": "Habakkuk",
        "haba kook": "Habakkuk",
        "havoc cook": "Habakkuk",

        // Zephaniah - commonly misheard
        "definitely": "Zephaniah",
        "definitely a": "Zephaniah",
        "zef in eye": "Zephaniah",
        "zeff and i": "Zephaniah",
        "zephyr naya": "Zephaniah",

        // Ecclesiastes - commonly misheard
        "ecclesia sees": "Ecclesiastes",
        "ecclesia steeze": "Ecclesiastes",
        "a classy estes": "Ecclesiastes",

        // Thessalonians - commonly misheard
        "the salonians": "Thessalonians",
        "thessalonian": "Thessalonians",
        "the salon eons": "Thessalonians",

        // Philippians - commonly misheard
        "philippines": "Philippians",
        "philippine": "Philippians",
        "fill a peons": "Philippians",

        // Colossians - commonly misheard
        "colosseum": "Colossians",
        "collusions": "Colossians",
        "colossal ones": "Colossians",

        // Nehemiah - commonly misheard
        "knee a maya": "Nehemiah",
        "nee a my": "Nehemiah",

        // Melchizedek - commonly misheard
        "milk is a deck": "Melchizedek",
        "milky said deck": "Melchizedek",
        "milk has a deck": "Melchizedek",
        "mel kizza deck": "Melchizedek",

        // Nebuchadnezzar - commonly misheard
        "never could neza": "Nebuchadnezzar",
        "neb you kid neza": "Nebuchadnezzar",
        "nebula nezzar": "Nebuchadnezzar",

        // Gethsemane - commonly misheard
        "get some money": "Gethsemane",
        "gets a mini": "Gethsemane",
        "gets seminary": "Gethsemane",

        // Golgotha - commonly misheard
        "gal go the": "Golgotha",
        "goal go the": "Golgotha",

        // Pharisees - commonly misheard
        "fair a sees": "Pharisees",
        "ferris seas": "Pharisees",

        // Sadducees - commonly misheard
        "sad you sees": "Sadducees",
        "sad disease": "Sadducees",

        // Corinthians - commonly misheard
        "corinthian": "Corinthians",
        "korean thins": "Corinthians",

        // Galatians - commonly misheard
        "glaciation": "Galatians",
        "galatian": "Galatians",

        // Ephesians - commonly misheard
        "a fusions": "Ephesians",
        "ephesian": "Ephesians"
    ]

    /// Single-word corrections (no context needed, always correct)
    static let singleWordCorrections: [String: String] = [
        "habba": "Habakkuk",
        "haba": "Habakkuk",
        "ecclesia": "Ecclesiastes",
        "zephan": "Zephaniah",
        "nehemi": "Nehemiah"
    ]

    // MARK: - Reference Context Detection

    /// Pattern to detect verse-like context (chapter:verse numbers nearby)
    private static let verseContextPattern = try! NSRegularExpression(
        pattern: #"\d+(?::\d+)?"#,
        options: []
    )

    /// Check if text contains verse-like context within a word distance
    static func hasVerseContext(in words: [String], near index: Int, windowSize: Int = 3) -> Bool {
        let startIndex = max(0, index - windowSize)
        let endIndex = min(words.count, index + windowSize + 1)

        for i in startIndex..<endIndex {
            let word = words[i]
            let range = NSRange(word.startIndex..., in: word)
            if verseContextPattern.firstMatch(in: word, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    // MARK: - Text Normalization

    /// Normalize text for matching: lowercase, remove punctuation
    static func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Correction Functions

    /// Apply corrections to transcript text and return correction overlays.
    /// - Parameters:
    ///   - text: The raw transcript text
    ///   - wordTimestamps: Word timestamps for index tracking
    ///   - requireContext: If true, only apply multi-word corrections near verse-like context
    /// - Returns: Array of correction overlays to apply
    static func findCorrections(
        in text: String,
        wordTimestamps: [SermonTranscript.WordTimestamp],
        requireContext: Bool = true
    ) -> [CorrectionOverlay] {
        var corrections: [CorrectionOverlay] = []
        let words = wordTimestamps.map { $0.word }

        // Check multi-word confusions (2-3 word windows)
        corrections.append(contentsOf: findMultiWordCorrections(
            words: words,
            requireContext: requireContext
        ))

        // Check single-word corrections
        corrections.append(contentsOf: findSingleWordCorrections(words: words))

        // Remove overlapping corrections (prefer higher confidence)
        return removeOverlaps(corrections)
    }

    /// Find multi-word confusion corrections using sliding window
    private static func findMultiWordCorrections(
        words: [String],
        requireContext: Bool
    ) -> [CorrectionOverlay] {
        var corrections: [CorrectionOverlay] = []

        // Check 3-word and 2-word windows
        for windowSize in [3, 2] {
            guard words.count >= windowSize else { continue }

            for startIndex in 0...(words.count - windowSize) {
                let windowWords = Array(words[startIndex..<(startIndex + windowSize)])
                let normalizedWindow = normalize(windowWords.joined(separator: " "))

                if let canonical = confusionMap[normalizedWindow] {
                    // Check context requirement
                    if requireContext && !hasVerseContext(in: words, near: startIndex) {
                        continue
                    }

                    let originalText = windowWords.joined(separator: " ")
                    corrections.append(CorrectionOverlay(
                        startWordIndex: startIndex,
                        wordCount: windowSize,
                        correctedText: canonical,
                        originalText: originalText,
                        confidence: 0.85  // Multi-word matches are high confidence
                    ))
                }
            }
        }

        return corrections
    }

    /// Find single-word corrections
    private static func findSingleWordCorrections(words: [String]) -> [CorrectionOverlay] {
        var corrections: [CorrectionOverlay] = []

        for (index, word) in words.enumerated() {
            let normalizedWord = normalize(word)

            if let canonical = singleWordCorrections[normalizedWord] {
                corrections.append(CorrectionOverlay(
                    startWordIndex: index,
                    wordCount: 1,
                    correctedText: canonical,
                    originalText: word,
                    confidence: 0.90  // Single-word exact matches are very high confidence
                ))
            }
        }

        return corrections
    }

    /// Remove overlapping corrections, preferring higher confidence
    private static func removeOverlaps(_ corrections: [CorrectionOverlay]) -> [CorrectionOverlay] {
        guard corrections.count > 1 else { return corrections }

        // Sort by confidence descending
        let sorted = corrections.sorted { $0.confidence > $1.confidence }
        var result: [CorrectionOverlay] = []
        var usedIndices = Set<Int>()

        for correction in sorted {
            let correctionIndices = Set(correction.startWordIndex..<(correction.startWordIndex + correction.wordCount))

            // Check if any indices are already used
            if correctionIndices.isDisjoint(with: usedIndices) {
                result.append(correction)
                usedIndices.formUnion(correctionIndices)
            }
        }

        // Sort result by start index for consistent ordering
        return result.sorted { $0.startWordIndex < $1.startWordIndex }
    }

    // MARK: - Text Application

    /// Apply correction overlays to produce corrected text.
    /// Preserves original word boundaries for timestamp alignment.
    static func applyCorrections(
        to wordTimestamps: [SermonTranscript.WordTimestamp],
        corrections: [CorrectionOverlay]
    ) -> String {
        guard !wordTimestamps.isEmpty else { return "" }

        var resultWords: [String] = []
        var skipUntilIndex = 0

        for (index, wordTimestamp) in wordTimestamps.enumerated() {
            if index < skipUntilIndex { continue }

            // Check if this index starts a correction
            if let correction = corrections.first(where: { $0.startWordIndex == index }) {
                resultWords.append(correction.correctedText)
                skipUntilIndex = index + correction.wordCount
            } else {
                resultWords.append(wordTimestamp.word)
            }
        }

        return resultWords.joined(separator: " ")
    }

    // MARK: - Normalized Text for Parsing

    /// Apply confusion map normalization to raw text for parser consumption.
    /// This is a lightweight version that normalizes text without tracking overlays.
    /// Use when you just need normalized text for reference detection.
    static func normalizeForParsing(_ text: String) -> String {
        var result = text

        // Apply multi-word replacements (longest first)
        let sortedConfusions = confusionMap.sorted { $0.key.count > $1.key.count }
        for (confusion, canonical) in sortedConfusions {
            // Case-insensitive replacement
            if let range = result.range(of: confusion, options: .caseInsensitive) {
                result.replaceSubrange(range, with: canonical)
            }
        }

        return result
    }
}
