//
//  ExplanationLoaderTests.swift
//  BibleStudyTests
//
//  Unit tests for ExplanationLoader
//

import Testing
import Foundation
@testable import BibleStudy

// MARK: - Explanation Loader Tests

@Suite("ExplanationLoader Tests")
@MainActor
struct ExplanationLoaderTests {

    // MARK: - Test Fixtures

    let testRange = VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 1)
    let testText = "In the beginning God created the heaven and the earth."
    let testTranslationId = "kjv"
    let testTranslationAbbrev = "KJV"

    // MARK: - Limit Reached Tests

    @Test("Returns limit reached when user has no quota")
    func returnsLimitReachedWhenNoQuota() async {
        let mockEntitlement = MockEntitlementService()
        mockEntitlement.simulateLimitReached()

        let loader = ExplanationLoader(
            aiService: MockAIService(),
            cache: MockAIResponseCache(),
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.isLimitReached == true)
        #expect(result.explanation == nil)
    }

    @Test("Returns limit reached when recordUsage fails")
    func returnsLimitReachedWhenRecordUsageFails() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        // User has quota initially but recording fails (just hit limit)
        mockEntitlement.canUseAIInsights = true
        mockEntitlement.recordAIInsightUsageReturnValue = false

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.isLimitReached == true)
        #expect(mockEntitlement.recordAIInsightUsageCallCount == 1)
    }

    // MARK: - Cache Tests

    @Test("Returns cached result when available")
    func returnsCachedResult() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        // Pre-populate cache
        let cachedOutput = ExplanationOutput(
            explanation: "Cached explanation",
            keyPoints: ["Cached point"],
            relatedVerses: nil,
            historicalContext: nil,
            applicationPoints: nil,
            uncertaintyNotes: nil,
            reasoning: nil,
            translationNotes: nil
        )
        mockCache.preloadExplanation(cachedOutput, for: testRange, translationId: testTranslationId)

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.explanation == "Cached explanation")
        #expect(result.isLimitReached == false)
        #expect(mockAI.generateExplanationCallCount == 0) // AI not called
        #expect(mockCache.getExplanationCallCount == 1)
    }

    @Test("Caches result after successful AI call")
    func cachesResultAfterAICall() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        mockAI.stubbedExplanationOutput = ExplanationOutput(
            explanation: "AI generated explanation",
            keyPoints: ["AI point"],
            relatedVerses: nil,
            historicalContext: nil,
            applicationPoints: nil,
            uncertaintyNotes: nil,
            reasoning: nil,
            translationNotes: nil
        )

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.explanation == "AI generated explanation")
        #expect(mockCache.cacheExplanationCallCount == 1)
    }

    // MARK: - AI Availability Tests

    @Test("Returns sample when AI unavailable")
    func returnsSampleWhenAIUnavailable() async {
        let mockAI = MockAIService()
        mockAI.isAvailable = false

        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.explanation != nil)
        #expect(result.explanation?.contains("Sample") == true)
        #expect(result.isLimitReached == false)
        #expect(mockAI.generateExplanationCallCount == 0)
    }

    // MARK: - AI Call Tests

    @Test("Makes AI call when cache miss and AI available")
    func makesAICallOnCacheMiss() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(mockAI.generateExplanationCallCount == 1)
        #expect(mockEntitlement.recordAIInsightUsageCallCount == 1)
        #expect(result.explanation != nil)
    }

    @Test("Records entitlement usage before AI call")
    func recordsEntitlementBeforeAICall() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        _ = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(mockEntitlement.recordAIInsightUsageCallCount == 1)
    }

    // MARK: - Error Handling Tests

    @Test("Returns sample with error on AI failure")
    func returnsSampleWithErrorOnAIFailure() async {
        let mockAI = MockAIService()
        mockAI.stubbedError = AIServiceError.networkError(NSError(domain: "test", code: -1))

        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.explanation != nil) // Sample is provided
        #expect(result.error != nil)       // Error is captured
        #expect(result.isLimitReached == false)
    }

    @Test("Does not cache on AI error")
    func doesNotCacheOnAIError() async {
        let mockAI = MockAIService()
        mockAI.stubbedError = AIServiceError.invalidResponse

        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        _ = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(mockCache.cacheExplanationCallCount == 0)
    }

    // MARK: - Structured Output Tests

    @Test("Parses structured explanation from output")
    func parsesStructuredExplanation() async {
        let mockAI = MockAIService()
        let mockCache = MockAIResponseCache()
        let mockEntitlement = MockEntitlementService()

        mockAI.stubbedExplanationOutput = ExplanationOutput(
            explanation: "Main explanation text",
            keyPoints: ["Point 1", "Point 2", "Point 3"],
            relatedVerses: nil,
            historicalContext: nil,
            applicationPoints: nil,
            uncertaintyNotes: nil,
            reasoning: [
                ReasoningPoint(phrase: "phrase1", explanation: "reason1")
            ],
            translationNotes: [
                TranslationNote(phrase: "word", translations: ["KJV: word"], explanation: "note")
            ]
        )

        let loader = ExplanationLoader(
            aiService: mockAI,
            cache: mockCache,
            entitlementManager: mockEntitlement
        )

        let result = await loader.load(
            for: testRange,
            verseText: testText,
            translationId: testTranslationId,
            translationAbbrev: testTranslationAbbrev
        )

        #expect(result.explanation == "Main explanation text")
        #expect(result.reasoning?.count == 1)
        #expect(result.translationNotes?.count == 1)
    }

    // MARK: - Edge Cases

    @Test("Empty result when explanation nil and limit not reached")
    func emptyResultConstruction() {
        let empty = ExplanationLoadResult.empty

        #expect(empty.explanation == nil)
        #expect(empty.isLimitReached == false)
        #expect(empty.error == nil)
    }

    @Test("Limit reached result construction")
    func limitReachedResultConstruction() {
        let limitReached = ExplanationLoadResult.limitReached()

        #expect(limitReached.explanation == nil)
        #expect(limitReached.isLimitReached == true)
        #expect(limitReached.error == nil)
    }
}
