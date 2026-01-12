//
//  MockAIService.swift
//  BibleStudyTests
//
//  Mock AI service for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock AI Service

@MainActor
final class MockAIService: AIServiceProtocol {
    // MARK: - Configuration

    var isAvailable: Bool = true

    // MARK: - Stubbed Responses

    var stubbedExplanationOutput: ExplanationOutput?
    var stubbedError: Error?
    var generateExplanationCallCount = 0

    // MARK: - Protocol Methods

    func generateExplanation(input: ExplanationInput) async throws -> ExplanationOutput {
        generateExplanationCallCount += 1

        if let error = stubbedError {
            throw error
        }

        if let output = stubbedExplanationOutput {
            return output
        }

        // Default output
        return ExplanationOutput(
            explanation: "Mock explanation for \(input.verseRange.reference)",
            keyPoints: ["Key point 1", "Key point 2"],
            relatedVerses: nil,
            historicalContext: nil,
            applicationPoints: nil,
            uncertaintyNotes: nil,
            reasoning: nil,
            translationNotes: nil
        )
    }

    // MARK: - Other Protocol Methods (Minimal Implementation)

    func generateQuickInsight(verseRange: VerseRange, verseText: String) async throws -> QuickInsightOutput {
        QuickInsightOutput(summary: "Mock insight", keyTerm: nil, keyTermMeaning: nil, suggestedAction: nil)
    }

    func generateWhyLinked(source: VerseRange, target: VerseRange, context: String?) async throws -> String {
        "Mock link explanation"
    }

    func generateTermExplanation(lemma: String, morph: String, verseContext: String) async throws -> String {
        "Mock term explanation"
    }

    func generateInterpretation(input: InterpretationInput) async throws -> InterpretationOutput {
        InterpretationOutput(
            plainMeaning: "Mock meaning",
            context: "Mock context",
            keyTerms: [],
            crossReferences: [],
            interpretationNotes: "",
            reflectionPrompt: nil,
            hasDebatedInterpretations: false,
            uncertaintyIndicators: nil,
            reasoning: nil,
            alternativeViews: nil
        )
    }

    func embedText(text: String) async throws -> [Float] { [] }

    func simplifyPassage(verseRange: VerseRange, verseText: String, level: ReadingLevel) async throws -> SimplifiedPassageOutput {
        SimplifiedPassageOutput(simplified: "Mock simplified", keyTermsExplained: nil, oneLineSummary: "Summary")
    }

    func summarizePassage(verseRange: VerseRange, verseText: String) async throws -> PassageSummaryOutput {
        PassageSummaryOutput(summary: "Mock summary", theme: "Theme", whatHappened: nil)
    }

    func generateComprehensionQuestions(verseRange: VerseRange, verseText: String, passageType: PassageType) async throws -> ComprehensionQuestionsOutput {
        ComprehensionQuestionsOutput(questions: [], passageType: "narrative")
    }

    func clarifyPhrase(phrase: String, verseRange: VerseRange, verseText: String) async throws -> PhraseClarificationOutput {
        PhraseClarificationOutput(clarification: "Mock", simpleVersion: "Simple", whyItMatters: "Matters")
    }

    func generateStory(input: StoryGenerationInput) async throws -> StoryGenerationOutput {
        StoryGenerationOutput(
            title: "Mock Story",
            subtitle: nil,
            description: "Mock description",
            estimatedMinutes: 5,
            segments: [],
            characters: nil
        )
    }

    func sendChatMessage(input: ChatMessageInput) async throws -> ChatMessageOutput {
        ChatMessageOutput(
            content: "Mock response",
            responseType: .answer,
            citations: nil,
            uncertaintyLevel: .low,
            suggestedFollowUps: nil,
            tokensIn: 100,
            tokensOut: 50,
            modelUsed: "mock"
        )
    }

    func generatePrayer(input: PrayerGenerationInput) async throws -> PrayerGenerationOutput {
        PrayerGenerationOutput(content: "Mock prayer", amen: "Amen.")
    }

    func generateSermonStudyGuide(input: SermonStudyGuideInput) async throws -> SermonStudyGuideOutput {
        SermonStudyGuideOutput(
            title: "Mock Sermon",
            summary: "Summary",
            keyThemes: [],
            outline: nil,
            notableQuotes: nil,
            bibleReferencesMentioned: [],
            bibleReferencesSuggested: [],
            discussionQuestions: [],
            reflectionPrompts: [],
            applicationPoints: [],
            confidenceNotes: nil,
            promptVersion: "1.0"
        )
    }
}
