import Testing
import Foundation
@testable import BibleStudy

// MARK: - Biblical Context Provider Tests

@Suite("Biblical Context Provider")
struct BiblicalContextProviderTests {

    // MARK: - Book-Specific Terms Tests

    @Suite("Book-Specific Terms")
    struct BookSpecificTermsTests {

        @Test("Book-specific terms map is not empty")
        func bookTermsMapNotEmpty() {
            #expect(!BiblicalContextProvider.bookSpecificTerms.isEmpty,
                   "Should contain terms for Bible books")
        }

        @Test("Habakkuk has specific terms")
        func habakkukHasTerms() {
            let terms = BiblicalContextProvider.bookSpecificTerms["Habakkuk"]
            #expect(terms != nil, "Should have terms for Habakkuk")
            #expect(terms?.contains("Chaldeans") == true,
                   "Habakkuk terms should include Chaldeans")
            #expect(terms?.contains("Babylonians") == true,
                   "Habakkuk terms should include Babylonians")
        }

        @Test("Romans has theological terms")
        func romansHasTheologicalTerms() {
            let terms = BiblicalContextProvider.bookSpecificTerms["Romans"]
            #expect(terms != nil, "Should have terms for Romans")
            #expect(terms?.contains("justification") == true,
                   "Romans terms should include justification")
            #expect(terms?.contains("propitiation") == true,
                   "Romans terms should include propitiation")
        }

        @Test("Genesis has patriarchal terms")
        func genesisHasPatriarchTerms() {
            let terms = BiblicalContextProvider.bookSpecificTerms["Genesis"]
            #expect(terms != nil, "Should have terms for Genesis")
            #expect(terms?.contains("Abraham") == true,
                   "Genesis terms should include Abraham")
            #expect(terms?.contains("Melchizedek") == true,
                   "Genesis terms should include Melchizedek")
        }

        @Test("Revelation has apocalyptic terms")
        func revelationHasApocalypticTerms() {
            let terms = BiblicalContextProvider.bookSpecificTerms["Revelation"]
            #expect(terms != nil, "Should have terms for Revelation")
            #expect(terms?.contains("Lamb") == true,
                   "Revelation terms should include Lamb")
            #expect(terms?.contains("New Jerusalem") == true,
                   "Revelation terms should include New Jerusalem")
        }
    }

    // MARK: - Contextual Strings Tests

    @Suite("Contextual Strings Generation")
    struct ContextualStringsTests {

        @Test("Returns strings for empty books array")
        func returnsStringsForEmptyBooks() {
            let strings = BiblicalContextProvider.contextualStrings(for: [])
            #expect(!strings.isEmpty, "Should return base terms even with no books")
        }

        @Test("Includes hard-to-recognize book names")
        func includesHardToRecognizeBooks() {
            let strings = BiblicalContextProvider.contextualStrings(for: [])
            #expect(strings.contains("Habakkuk"),
                   "Should always include Habakkuk")
            #expect(strings.contains("Zephaniah"),
                   "Should always include Zephaniah")
            #expect(strings.contains("Ecclesiastes"),
                   "Should always include Ecclesiastes")
        }

        @Test("Includes book-specific terms when book detected")
        func includesBookSpecificTerms() {
            let strings = BiblicalContextProvider.contextualStrings(for: ["Habakkuk"])
            #expect(strings.contains("Chaldeans"),
                   "Should include Habakkuk-specific term Chaldeans")
        }

        @Test("Includes terms from multiple detected books")
        func includesTermsFromMultipleBooks() {
            let strings = BiblicalContextProvider.contextualStrings(for: ["Habakkuk", "Romans"])
            #expect(strings.contains("Chaldeans"),
                   "Should include Habakkuk-specific term")
            #expect(strings.contains("justification"),
                   "Should include Romans-specific term")
        }

        @Test("Respects max terms limit")
        func respectsMaxTermsLimit() {
            let strings = BiblicalContextProvider.contextualStrings(for: ["Genesis"], maxTerms: 10)
            #expect(strings.count <= 10, "Should not exceed max terms limit")
        }

        @Test("Returns sorted strings for consistency")
        func returnsSortedStrings() {
            let strings = BiblicalContextProvider.contextualStrings(for: ["Habakkuk"])
            let sorted = strings.sorted()
            #expect(strings == sorted, "Strings should be sorted alphabetically")
        }
    }

    // MARK: - Glossary Prompt Tests

    @Suite("Glossary Prompt Generation")
    struct GlossaryPromptTests {

        @Test("Returns default glossary for empty books")
        func returnsDefaultForEmptyBooks() {
            let prompt = BiblicalContextProvider.glossaryPrompt(for: [])
            #expect(prompt == SermonConfiguration.biblicalGlossaryPrompt,
                   "Should return default glossary when no books detected")
        }

        @Test("Includes detected book name in prompt")
        func includesDetectedBookName() {
            let prompt = BiblicalContextProvider.glossaryPrompt(for: ["Habakkuk"])
            #expect(prompt.contains("Habakkuk"),
                   "Prompt should mention the detected book")
        }

        @Test("Includes book-specific terms in prompt")
        func includesBookSpecificTermsInPrompt() {
            let prompt = BiblicalContextProvider.glossaryPrompt(for: ["Habakkuk"])
            #expect(prompt.contains("Chaldeans") || prompt.contains("Babylonians"),
                   "Prompt should include book-specific terms")
        }

        @Test("Respects budget limit")
        func respectsBudgetLimit() {
            let budget = 200
            let prompt = BiblicalContextProvider.glossaryPrompt(for: ["Genesis", "Exodus", "Romans"], budgetChars: budget)
            #expect(prompt.count <= budget,
                   "Prompt should not exceed budget (\(prompt.count) > \(budget))")
        }

        @Test("Falls back to default for short result")
        func fallsBackForShortResult() {
            // Very small budget should trigger fallback
            let prompt = BiblicalContextProvider.glossaryPrompt(for: ["Job"], budgetChars: 30)
            #expect(prompt == SermonConfiguration.biblicalGlossaryPrompt,
                   "Should fall back to default for very small budget")
        }
    }

    // MARK: - Sermon Title Convenience Tests

    @Suite("Sermon Title Convenience Methods")
    struct SermonTitleTests {

        @Test("Extracts context from sermon title with book name")
        func extractsContextFromTitle() {
            let strings = BiblicalContextProvider.contextualStrings(forSermonTitle: "A Study in Habakkuk 2:4")
            #expect(strings.contains("Chaldeans"),
                   "Should detect Habakkuk and include specific terms")
        }

        @Test("Builds glossary from sermon title")
        func buildsGlossaryFromTitle() {
            let prompt = BiblicalContextProvider.glossaryPrompt(forSermonTitle: "Walking Through Romans 8")
            #expect(prompt.contains("Romans"),
                   "Prompt should mention Romans")
        }

        @Test("Handles title with multiple books")
        func handlesMultipleBooks() {
            let strings = BiblicalContextProvider.contextualStrings(
                forSermonTitle: "Comparing Isaiah and Revelation"
            )
            // Should have terms from both books
            let hasIsaiahTerm = strings.contains("Immanuel") || strings.contains("Hezekiah")
            let hasRevelationTerm = strings.contains("Lamb") || strings.contains("apocalypse")
            #expect(hasIsaiahTerm, "Should include Isaiah-specific terms")
            #expect(hasRevelationTerm, "Should include Revelation-specific terms")
        }

        @Test("Handles title with no book reference")
        func handlesTitleWithNoBook() {
            let strings = BiblicalContextProvider.contextualStrings(
                forSermonTitle: "Sunday Morning Message"
            )
            // Should still return base terms
            #expect(!strings.isEmpty, "Should return terms even without book reference")
            #expect(strings.contains("Habakkuk"),
                   "Should include hard-to-recognize books as fallback")
        }
    }

    // MARK: - Integration with WhisperPromptBuilder Tests

    @Suite("WhisperPromptBuilder Integration")
    struct WhisperPromptBuilderIntegrationTests {

        @Test("WhisperPromptBuilder.forSermon creates dynamic glossary")
        func forSermonCreatesDynamicGlossary() {
            let builder = WhisperPromptBuilder.forSermon(title: "Exploring Habakkuk")
            let prompt = builder.buildPrompt(context: "")
            #expect(prompt.contains("Habakkuk"),
                   "Dynamic glossary should mention detected book")
        }

        @Test("WhisperPromptBuilder.forSermon includes context and glossary")
        func forSermonIncludesContextAndGlossary() {
            let builder = WhisperPromptBuilder.forSermon(title: "Romans 8 Study")
            let prompt = builder.buildPrompt(context: "In this passage we see")
            #expect(prompt.contains("In this passage"),
                   "Prompt should include context")
            #expect(prompt.contains("Romans"),
                   "Prompt should include book from dynamic glossary")
        }

        @Test("Dynamic builder respects budget limits")
        func dynamicBuilderRespectsBudget() {
            let builder = WhisperPromptBuilder.forSermon(title: "Genesis to Revelation Journey")
            let prompt = builder.buildPrompt(context: String(repeating: "word ", count: 100))
            #expect(builder.isWithinBudget(prompt),
                   "Built prompt should be within budget")
        }
    }
}
