import Testing
import Foundation
@testable import BibleStudy

// MARK: - Biblical Term Corrector Tests

@Suite("Biblical Term Corrector")
struct BiblicalTermCorrectorTests {

    // MARK: - Confusion Map Tests

    @Suite("Confusion Map")
    struct ConfusionMapTests {

        @Test("Confusion map is not empty")
        func confusionMapNotEmpty() {
            #expect(!BiblicalTermCorrector.confusionMap.isEmpty,
                   "Confusion map should contain known misrecognitions")
        }

        @Test("Confusion map contains Habakkuk confusions")
        func confusionMapContainsHabakkuk() {
            #expect(BiblicalTermCorrector.confusionMap["have a cook"] == "Habakkuk",
                   "Should map 'have a cook' to 'Habakkuk'")
        }

        @Test("Confusion map contains Zephaniah confusions")
        func confusionMapContainsZephaniah() {
            #expect(BiblicalTermCorrector.confusionMap["definitely"] == "Zephaniah",
                   "Should map 'definitely' to 'Zephaniah'")
        }

        @Test("Confusion map contains Melchizedek confusions")
        func confusionMapContainsMelchizedek() {
            #expect(BiblicalTermCorrector.confusionMap["milk is a deck"] == "Melchizedek",
                   "Should map 'milk is a deck' to 'Melchizedek'")
        }

        @Test("Single word corrections map is not empty")
        func singleWordCorrectionsNotEmpty() {
            #expect(!BiblicalTermCorrector.singleWordCorrections.isEmpty,
                   "Single word corrections should contain partial matches")
        }
    }

    // MARK: - Normalization Tests

    @Suite("Text Normalization")
    struct NormalizationTests {

        @Test("Normalizes text to lowercase")
        func normalizesToLowercase() {
            let result = BiblicalTermCorrector.normalize("HAVE A COOK")
            #expect(result == "have a cook")
        }

        @Test("Removes punctuation")
        func removesPunctuation() {
            let result = BiblicalTermCorrector.normalize("have, a cook!")
            #expect(result == "have a cook")
        }

        @Test("Trims whitespace")
        func trimsWhitespace() {
            let result = BiblicalTermCorrector.normalize("  have a cook  ")
            #expect(result == "have a cook")
        }
    }

    // MARK: - Verse Context Detection Tests

    @Suite("Verse Context Detection")
    struct VerseContextTests {

        @Test("Detects chapter:verse pattern")
        func detectsChapterVerse() {
            let words = ["turn", "to", "3:16", "in", "john"]
            #expect(BiblicalTermCorrector.hasVerseContext(in: words, near: 0, windowSize: 3))
        }

        @Test("Detects chapter only pattern")
        func detectsChapterOnly() {
            let words = ["chapter", "3", "of", "romans"]
            #expect(BiblicalTermCorrector.hasVerseContext(in: words, near: 0, windowSize: 3))
        }

        @Test("Returns false when no verse context")
        func noVerseContext() {
            let words = ["today", "we", "study", "the", "bible"]
            #expect(!BiblicalTermCorrector.hasVerseContext(in: words, near: 0, windowSize: 3))
        }
    }

    // MARK: - Text Normalization for Parsing Tests

    @Suite("Parsing Normalization")
    struct ParsingNormalizationTests {

        @Test("Normalizes Habakkuk confusion for parsing")
        func normalizesHabakkukForParsing() {
            let text = "Turn to have a cook 2:4"
            let normalized = BiblicalTermCorrector.normalizeForParsing(text)
            #expect(normalized.contains("Habakkuk"),
                   "Should replace 'have a cook' with 'Habakkuk'")
        }

        @Test("Normalizes case-insensitively")
        func normalizesCaseInsensitive() {
            let text = "Turn to HAVE A COOK chapter 2"
            let normalized = BiblicalTermCorrector.normalizeForParsing(text)
            #expect(normalized.contains("Habakkuk"),
                   "Should replace case-insensitive confusion")
        }

        @Test("Does not modify correctly spelled terms")
        func preservesCorrectSpelling() {
            let text = "Turn to Habakkuk 2:4"
            let normalized = BiblicalTermCorrector.normalizeForParsing(text)
            #expect(normalized == text,
                   "Should preserve correctly spelled biblical terms")
        }

        @Test("Handles multiple confusions in same text")
        func handlesMultipleConfusions() {
            let text = "From have a cook to definitely in the bible"
            let normalized = BiblicalTermCorrector.normalizeForParsing(text)
            #expect(normalized.contains("Habakkuk"),
                   "Should replace first confusion")
            #expect(normalized.contains("Zephaniah"),
                   "Should replace second confusion")
        }
    }

    // MARK: - Correction Overlay Tests

    @Suite("Correction Overlays")
    struct CorrectionOverlayTests {

        @Test("Finds multi-word correction with verse context")
        func findsMultiWordCorrectionWithContext() {
            // Simulate word timestamps for "have a cook 2:4"
            let wordTimestamps = [
                SermonTranscript.WordTimestamp(word: "have", start: 0, end: 0.5),
                SermonTranscript.WordTimestamp(word: "a", start: 0.5, end: 0.8),
                SermonTranscript.WordTimestamp(word: "cook", start: 0.8, end: 1.2),
                SermonTranscript.WordTimestamp(word: "2:4", start: 1.3, end: 1.8)
            ]

            let corrections = BiblicalTermCorrector.findCorrections(
                in: "have a cook 2:4",
                wordTimestamps: wordTimestamps,
                requireContext: true
            )

            #expect(corrections.count == 1, "Should find one correction")
            if let correction = corrections.first {
                #expect(correction.correctedText == "Habakkuk")
                #expect(correction.startWordIndex == 0)
                #expect(correction.wordCount == 3)
            }
        }

        @Test("Skips correction without verse context when required")
        func skipsWithoutContextWhenRequired() {
            let wordTimestamps = [
                SermonTranscript.WordTimestamp(word: "have", start: 0, end: 0.5),
                SermonTranscript.WordTimestamp(word: "a", start: 0.5, end: 0.8),
                SermonTranscript.WordTimestamp(word: "cook", start: 0.8, end: 1.2),
                SermonTranscript.WordTimestamp(word: "today", start: 1.3, end: 1.8)
            ]

            let corrections = BiblicalTermCorrector.findCorrections(
                in: "have a cook today",
                wordTimestamps: wordTimestamps,
                requireContext: true
            )

            #expect(corrections.isEmpty,
                   "Should not correct without verse context when required")
        }

        @Test("Applies correction without context requirement")
        func appliesWithoutContextRequirement() {
            let wordTimestamps = [
                SermonTranscript.WordTimestamp(word: "have", start: 0, end: 0.5),
                SermonTranscript.WordTimestamp(word: "a", start: 0.5, end: 0.8),
                SermonTranscript.WordTimestamp(word: "cook", start: 0.8, end: 1.2),
                SermonTranscript.WordTimestamp(word: "today", start: 1.3, end: 1.8)
            ]

            let corrections = BiblicalTermCorrector.findCorrections(
                in: "have a cook today",
                wordTimestamps: wordTimestamps,
                requireContext: false
            )

            #expect(corrections.count == 1,
                   "Should find correction when context not required")
        }
    }

    // MARK: - Apply Corrections Tests

    @Suite("Apply Corrections")
    struct ApplyCorrectionTests {

        @Test("Applies single correction to word timestamps")
        func appliesSingleCorrection() {
            let wordTimestamps = [
                SermonTranscript.WordTimestamp(word: "Turn", start: 0, end: 0.4),
                SermonTranscript.WordTimestamp(word: "to", start: 0.4, end: 0.6),
                SermonTranscript.WordTimestamp(word: "have", start: 0.6, end: 0.9),
                SermonTranscript.WordTimestamp(word: "a", start: 0.9, end: 1.1),
                SermonTranscript.WordTimestamp(word: "cook", start: 1.1, end: 1.5)
            ]

            let corrections = [
                CorrectionOverlay(
                    startWordIndex: 2,
                    wordCount: 3,
                    correctedText: "Habakkuk",
                    originalText: "have a cook",
                    confidence: 0.85
                )
            ]

            let result = BiblicalTermCorrector.applyCorrections(
                to: wordTimestamps,
                corrections: corrections
            )

            #expect(result == "Turn to Habakkuk",
                   "Should produce 'Turn to Habakkuk'")
        }

        @Test("Handles empty corrections array")
        func handlesEmptyCorrections() {
            let wordTimestamps = [
                SermonTranscript.WordTimestamp(word: "Hello", start: 0, end: 0.5),
                SermonTranscript.WordTimestamp(word: "world", start: 0.5, end: 1.0)
            ]

            let result = BiblicalTermCorrector.applyCorrections(
                to: wordTimestamps,
                corrections: []
            )

            #expect(result == "Hello world")
        }

        @Test("Handles empty word timestamps")
        func handlesEmptyWordTimestamps() {
            let result = BiblicalTermCorrector.applyCorrections(
                to: [],
                corrections: []
            )

            #expect(result == "")
        }
    }

    // MARK: - Integration Tests

    @Suite("Integration with Parsers")
    struct IntegrationTests {

        @Test("ScriptureReferenceParser extracts Habakkuk from confused text")
        func scriptureParserExtractsHabakkuk() {
            let text = "Today we study have a cook chapter 2"
            let books = ScriptureReferenceParser.extractBooks(from: text)
            #expect(books.contains("Habakkuk"),
                   "Should extract Habakkuk from confused text")
        }

        @Test("ReferenceParser extracts reference from confused text")
        func referenceParserExtractsFromConfused() {
            let text = "Turn to have a cook 2:4 in your bibles"
            let refs = ReferenceParser.extractAll(from: text)
            #expect(refs.count >= 1, "Should find at least one reference")
            if let ref = refs.first {
                #expect(ref.book.name == "Habakkuk")
                #expect(ref.chapter == 2)
                #expect(ref.verseStart == 4)
            }
        }

        @Test("Parser still works with correct spelling")
        func parserWorksWithCorrectSpelling() {
            let text = "Turn to Habakkuk 2:4"
            let refs = ReferenceParser.extractAll(from: text)
            #expect(refs.count == 1)
            if let ref = refs.first {
                #expect(ref.book.name == "Habakkuk")
                #expect(ref.chapter == 2)
                #expect(ref.verseStart == 4)
            }
        }
    }
}
