import Testing
import Foundation
@testable import BibleStudy

// MARK: - WhisperPromptBuilder Tests

@Suite("WhisperPromptBuilder")
struct WhisperPromptBuilderTests {

    // MARK: - Budget Validation Tests

    @Suite("Budget Validation")
    struct BudgetValidationTests {

        @Test("Default glossary fits within budget")
        func defaultGlossaryFitsWithinBudget() {
            let builder = WhisperPromptBuilder.default

            #expect(builder.isGlossaryWithinBudget)
            #expect(builder.glossary.count <= builder.glossaryBudgetChars)
        }

        @Test("Configuration glossary fits within configured budget")
        func configurationGlossaryFitsWithinBudget() {
            let glossary = SermonConfiguration.biblicalGlossaryPrompt
            let budget = SermonConfiguration.glossaryBudgetChars

            #expect(glossary.count <= budget, "Glossary (\(glossary.count) chars) exceeds budget (\(budget) chars)")
        }

        @Test("Built prompt stays within max chars")
        func builtPromptStaysWithinMaxChars() {
            let builder = WhisperPromptBuilder.default

            // Test with empty context
            let emptyPrompt = builder.buildPrompt(context: "")
            #expect(builder.isWithinBudget(emptyPrompt))

            // Test with short context
            let shortPrompt = builder.buildPrompt(context: "This is a short context.")
            #expect(builder.isWithinBudget(shortPrompt))

            // Test with context at exactly the budget
            let exactContext = String(repeating: "a", count: SermonConfiguration.contextBudgetChars)
            let exactPrompt = builder.buildPrompt(context: exactContext)
            #expect(builder.isWithinBudget(exactPrompt))

            // Test with context exceeding budget (should be trimmed)
            let longContext = String(repeating: "b", count: SermonConfiguration.contextBudgetChars * 2)
            let longPrompt = builder.buildPrompt(context: longContext)
            #expect(builder.isWithinBudget(longPrompt))
        }
    }

    // MARK: - Glossary Inclusion Tests

    @Suite("Glossary Inclusion")
    struct GlossaryInclusionTests {

        @Test("Glossary is always included in prompt")
        func glossaryAlwaysIncluded() {
            let builder = WhisperPromptBuilder.default

            // Empty context
            let emptyPrompt = builder.buildPrompt(context: "")
            #expect(emptyPrompt.contains(builder.glossary))

            // Short context
            let shortPrompt = builder.buildPrompt(context: "Short context")
            #expect(shortPrompt.contains(builder.glossary))

            // Very long context
            let longContext = String(repeating: "Long ", count: 500)
            let longPrompt = builder.buildPrompt(context: longContext)
            #expect(longPrompt.contains(builder.glossary))
        }

        @Test("Glossary is never trimmed")
        func glossaryNeverTrimmed() {
            let builder = WhisperPromptBuilder.default
            let fullGlossary = builder.glossary

            // Even with maximum context, glossary should be complete
            let maxContext = String(repeating: "x", count: 10000)
            let prompt = builder.buildPrompt(context: maxContext)

            #expect(prompt.hasSuffix(fullGlossary), "Glossary should appear at end of prompt, untrimmed")
        }

        @Test("Glossary-only prompt when context is empty")
        func glossaryOnlyWhenContextEmpty() {
            let builder = WhisperPromptBuilder.default

            let prompt = builder.buildPrompt(context: "")
            #expect(prompt == builder.glossary)

            let segmentsPrompt = builder.buildPrompt(recentSegments: [])
            #expect(segmentsPrompt == builder.glossary)
        }
    }

    // MARK: - Context Handling Tests

    @Suite("Context Handling")
    struct ContextHandlingTests {

        @Test("Context is trimmed when exceeding budget")
        func contextTrimmedWhenExceedingBudget() {
            let builder = WhisperPromptBuilder(
                glossary: "GLOSSARY",
                maxPromptChars: 100,
                glossaryBudgetChars: 20,
                contextBudgetChars: 79  // 100 - 20 - 1 (space)
            )

            let longContext = "START" + String(repeating: "x", count: 100) + "END"
            let prompt = builder.buildPrompt(context: longContext)

            // Should contain END (suffix) but not necessarily START (prefix)
            #expect(prompt.contains("END"))
            #expect(prompt.contains("GLOSSARY"))
        }

        @Test("Context suffix is preserved when trimming")
        func contextSuffixPreservedWhenTrimming() {
            let builder = WhisperPromptBuilder(
                glossary: "GLOSS",
                maxPromptChars: 50,
                glossaryBudgetChars: 10,
                contextBudgetChars: 39
            )

            let context = "old words that will be trimmed RECENT WORDS"
            let prompt = builder.buildPrompt(context: context)

            // Recent words should be preserved
            #expect(prompt.contains("RECENT WORDS"))
            #expect(prompt.contains("GLOSS"))
        }

        @Test("Segments are joined with spaces")
        func segmentsJoinedWithSpaces() {
            let builder = WhisperPromptBuilder(
                glossary: "G",
                maxPromptChars: 100,
                glossaryBudgetChars: 5,
                contextBudgetChars: 94
            )

            let segments = ["First segment.", "Second segment.", "Third segment."]
            let prompt = builder.buildPrompt(recentSegments: segments)

            #expect(prompt.contains("First segment. Second segment. Third segment."))
        }
    }

    // MARK: - Integration Tests

    @Suite("Integration")
    struct IntegrationTests {

        @Test("Biblical terms are present in default glossary")
        func biblicalTermsInDefaultGlossary() {
            let glossary = SermonConfiguration.biblicalGlossaryPrompt

            // Check for hard-to-transcribe book names
            #expect(glossary.contains("Habakkuk"))
            #expect(glossary.contains("Zephaniah"))
            #expect(glossary.contains("Ecclesiastes"))
            #expect(glossary.contains("Thessalonians"))
            #expect(glossary.contains("Colossians"))

            // Check for proper nouns
            #expect(glossary.contains("Melchizedek"))
            #expect(glossary.contains("Nebuchadnezzar"))
            #expect(glossary.contains("Gethsemane"))

            // Check for religious terms
            #expect(glossary.contains("Pharisees"))
            #expect(glossary.contains("Sadducees"))
            #expect(glossary.contains("Hallelujah"))
        }

        @Test("Budget constants are consistent")
        func budgetConstantsConsistent() {
            let max = SermonConfiguration.maxPromptChars
            let glossary = SermonConfiguration.glossaryBudgetChars
            let context = SermonConfiguration.contextBudgetChars

            // Context budget should be max - glossary - 1 (for space separator)
            #expect(context == max - glossary - 1, "contextBudgetChars should equal maxPromptChars - glossaryBudgetChars - 1")
        }
    }
}
