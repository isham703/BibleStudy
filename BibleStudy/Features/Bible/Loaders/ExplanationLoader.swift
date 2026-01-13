//
//  ExplanationLoader.swift
//  BibleStudy
//
//  Domain loader for explanation content
//  Encapsulates AI generation, caching, and entitlement logic
//

import Foundation

// MARK: - Explanation Loader Result

/// Result of loading explanation content
struct ExplanationLoadResult: Sendable {
    let explanation: String?
    let structured: StructuredExplanation?
    let reasoning: [ReasoningPoint]?
    let translationNotes: [TranslationNote]?
    let groundingSources: [String]
    let isLimitReached: Bool
    let error: Error?

    static let empty = ExplanationLoadResult(
        explanation: nil,
        structured: nil,
        reasoning: nil,
        translationNotes: nil,
        groundingSources: [],
        isLimitReached: false,
        error: nil
    )

    static func limitReached() -> ExplanationLoadResult {
        ExplanationLoadResult(
            explanation: nil,
            structured: nil,
            reasoning: nil,
            translationNotes: nil,
            groundingSources: [],
            isLimitReached: true,
            error: nil
        )
    }
}

// MARK: - Explanation Loader

/// Loads AI-generated verse explanations
/// Handles caching, entitlements, and fallback to samples
@MainActor
final class ExplanationLoader {
    // MARK: - Dependencies

    private let aiService: AIServiceProtocol
    private let cache: AIResponseCacheProtocol
    private let entitlementManager: EntitlementServiceProtocol

    // MARK: - Initialization

    init(
        aiService: AIServiceProtocol? = nil,
        cache: AIResponseCacheProtocol? = nil,
        entitlementManager: EntitlementServiceProtocol? = nil
    ) {
        self.aiService = aiService ?? OpenAIProvider.shared
        self.cache = cache ?? AIResponseCache.shared
        self.entitlementManager = entitlementManager ?? EntitlementService.shared
    }

    // MARK: - Load Explanation

    /// Load explanation for a verse range
    /// - Parameters:
    ///   - verseRange: The verse range to explain
    ///   - verseText: The text of the verses
    ///   - translationId: Current translation ID for cache key
    ///   - translationAbbrev: Translation abbreviation for AI context
    /// - Returns: ExplanationLoadResult with content or error state
    func load(
        for verseRange: VerseRange,
        verseText: String,
        translationId: String,
        translationAbbrev: String
    ) async -> ExplanationLoadResult {
        // Check entitlement first
        guard entitlementManager.canUseAIInsights else {
            return .limitReached()
        }

        // Check cache
        if let cached = cache.getExplanation(for: verseRange, translationId: translationId, mode: .plain) {
            return ExplanationLoadResult(
                explanation: cached.explanation,
                structured: StructuredExplanation.parse(cached.explanation, keyPoints: cached.keyPoints),
                reasoning: cached.reasoning,
                translationNotes: cached.translationNotes,
                groundingSources: cached.groundingSources,
                isLimitReached: false,
                error: nil
            )
        }

        // Check AI availability
        guard aiService.isAvailable else {
            return makeSampleResult()
        }

        // Record usage - if denied, user just hit limit
        guard entitlementManager.recordAIInsightUsage() else {
            return .limitReached()
        }

        // Make AI request
        do {
            let input = ExplanationInput(
                verseRange: verseRange,
                verseText: verseText,
                surroundingContext: nil,
                mode: .plain,
                translation: translationAbbrev
            )

            let output = try await aiService.generateExplanation(input: input)

            // Cache the result
            cache.cacheExplanation(output, for: verseRange, translationId: translationId, mode: .plain)

            return ExplanationLoadResult(
                explanation: output.explanation,
                structured: StructuredExplanation.parse(output.explanation, keyPoints: output.keyPoints),
                reasoning: output.reasoning,
                translationNotes: output.translationNotes,
                groundingSources: output.groundingSources,
                isLimitReached: false,
                error: nil
            )
        } catch {
            // Return sample with error for display
            let result = makeSampleResult()
            return ExplanationLoadResult(
                explanation: result.explanation,
                structured: result.structured,
                reasoning: result.reasoning,
                translationNotes: result.translationNotes,
                groundingSources: result.groundingSources,
                isLimitReached: false,
                error: error
            )
        }
    }

    // MARK: - Sample Data

    private func makeSampleResult() -> ExplanationLoadResult {
        let sampleText = """
        This passage describes the foundational moment of creation where God speaks light into existence. \
        The Hebrew phrase "יְהִי אוֹר" (yehi 'or) uses the jussive form, expressing a divine command or decree.

        **Key observations:**
        • The creation of light precedes the creation of the sun (verse 14), suggesting this is divine light or the light of God's presence.
        • The pattern of "God said... and it was so" establishes God's word as the means of creation.
        • The separation of light from darkness establishes the first boundary in creation.

        This verse connects thematically to John 1:4-5, where Jesus is described as "the light of men" that "shines in the darkness."

        *(Sample explanation - configure API key for live AI responses)*
        """

        let reasoning = [
            ReasoningPoint(
                phrase: "יְהִי אוֹר (yehi 'or)",
                explanation: "The jussive form indicates a divine command, showing God's word has creative power."
            ),
            ReasoningPoint(
                phrase: "and there was light",
                explanation: "Immediate fulfillment demonstrates the effectiveness of God's spoken word."
            )
        ]

        let translationNotes = [
            TranslationNote(
                phrase: "Let there be light",
                translations: ["KJV: Let there be light", "ESV: Let there be light", "NIV: Let there be light"],
                explanation: "Most translations agree on this phrase. The Hebrew 'yehi' is a jussive form expressing divine command."
            )
        ]

        return ExplanationLoadResult(
            explanation: sampleText,
            structured: StructuredExplanation.parse(sampleText),
            reasoning: reasoning,
            translationNotes: translationNotes,
            groundingSources: ["Selected passage text", "Original language lexicon", "Translation comparison"],
            isLimitReached: false,
            error: nil
        )
    }
}
