import Testing
import Foundation
@testable import BibleStudy

// MARK: - Live Caption Context Tests

@Suite("Live Caption Contextual Biasing")
struct LiveCaptionContextTests {

    // MARK: - Configuration Tests

    @Suite("Configuration")
    struct ConfigurationTests {

        @Test("Biblical contextual strings array is not empty")
        func biblicalContextualStringsNotEmpty() {
            let strings = SermonConfiguration.biblicalContextualStrings
            #expect(!strings.isEmpty, "biblicalContextualStrings should not be empty")
        }

        @Test("Biblical contextual strings count is within recommended range")
        func biblicalContextualStringsCountInRange() {
            let strings = SermonConfiguration.biblicalContextualStrings
            // Plan recommends 30-50 terms to avoid over-biasing
            #expect(strings.count >= 20, "Should have at least 20 terms for meaningful biasing")
            #expect(strings.count <= 60, "Should have at most 60 terms to avoid over-biasing")
        }

        @Test("Biblical contextual strings contain key book names")
        func biblicalContextualStringsContainKeyBooks() {
            let strings = SermonConfiguration.biblicalContextualStrings

            // Hard-to-transcribe OT books
            #expect(strings.contains("Habakkuk"), "Should contain Habakkuk")
            #expect(strings.contains("Zephaniah"), "Should contain Zephaniah")
            #expect(strings.contains("Ecclesiastes"), "Should contain Ecclesiastes")

            // Hard-to-transcribe NT books
            #expect(strings.contains("Thessalonians"), "Should contain Thessalonians")
            #expect(strings.contains("Philippians"), "Should contain Philippians")
            #expect(strings.contains("Colossians"), "Should contain Colossians")
        }

        @Test("Biblical contextual strings contain key proper nouns")
        func biblicalContextualStringsContainProperNouns() {
            let strings = SermonConfiguration.biblicalContextualStrings

            #expect(strings.contains("Melchizedek"), "Should contain Melchizedek")
            #expect(strings.contains("Nebuchadnezzar"), "Should contain Nebuchadnezzar")
            #expect(strings.contains("Gethsemane"), "Should contain Gethsemane")
        }

        @Test("Biblical contextual strings have no duplicates")
        func biblicalContextualStringsNoDuplicates() {
            let strings = SermonConfiguration.biblicalContextualStrings
            let uniqueStrings = Set(strings)
            #expect(strings.count == uniqueStrings.count, "Should have no duplicate terms")
        }

        @Test("Biblical contextual strings are all non-empty")
        func biblicalContextualStringsAllNonEmpty() {
            let strings = SermonConfiguration.biblicalContextualStrings
            for term in strings {
                #expect(!term.isEmpty, "All terms should be non-empty")
                #expect(!term.trimmingCharacters(in: .whitespaces).isEmpty,
                       "Terms should not be whitespace-only")
            }
        }
    }

    // MARK: - Consistency Tests

    @Suite("Consistency with Whisper Glossary")
    struct ConsistencyTests {

        @Test("Key terms appear in both Whisper glossary and contextual strings")
        func keyTermsConsistentAcrossApis() {
            let contextualStrings = SermonConfiguration.biblicalContextualStrings
            let whisperGlossary = SermonConfiguration.biblicalGlossaryPrompt

            // Key terms should appear in both for consistent behavior
            let keyTerms = ["Habakkuk", "Zephaniah", "Thessalonians", "Melchizedek"]

            for term in keyTerms {
                let inContextual = contextualStrings.contains(term)
                let inWhisper = whisperGlossary.contains(term)
                #expect(inContextual && inWhisper,
                       "\(term) should appear in both contextualStrings and Whisper glossary")
            }
        }
    }
}
