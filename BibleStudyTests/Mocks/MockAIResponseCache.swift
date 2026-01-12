//
//  MockAIResponseCache.swift
//  BibleStudyTests
//
//  Mock AI response cache for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock AI Response Cache

@MainActor
final class MockAIResponseCache: AIResponseCacheProtocol {
    // MARK: - Storage

    private var explanations: [String: ExplanationOutput] = [:]
    private var interpretations: [String: InterpretationOutput] = [:]
    private var comprehensions: [String: ComprehensionQuestionsOutput] = [:]

    // MARK: - Call Tracking

    var getExplanationCallCount = 0
    var cacheExplanationCallCount = 0
    var clearAllCallCount = 0
    var purgeExpiredCallCount = 0

    // MARK: - Explanation Cache

    func getExplanation(for range: VerseRange, translationId: String, mode: ExplanationMode) -> ExplanationOutput? {
        getExplanationCallCount += 1
        let key = "\(translationId):\(range.reference):\(mode.rawValue)"
        return explanations[key]
    }

    func cacheExplanation(_ response: ExplanationOutput, for range: VerseRange, translationId: String, mode: ExplanationMode) {
        cacheExplanationCallCount += 1
        let key = "\(translationId):\(range.reference):\(mode.rawValue)"
        explanations[key] = response
    }

    // MARK: - Interpretation Cache

    func getInterpretation(for range: VerseRange, translationId: String, mode: InterpretationViewMode) -> InterpretationOutput? {
        let key = "\(translationId):\(range.reference):\(mode.rawValue)"
        return interpretations[key]
    }

    func cacheInterpretation(_ response: InterpretationOutput, for range: VerseRange, translationId: String, mode: InterpretationViewMode) {
        let key = "\(translationId):\(range.reference):\(mode.rawValue)"
        interpretations[key] = response
    }

    // MARK: - Comprehension Cache

    func getComprehensionQuestions(for range: VerseRange, translationId: String, passageType: PassageType) -> ComprehensionQuestionsOutput? {
        let key = "\(translationId):\(range.reference):\(passageType.rawValue)"
        return comprehensions[key]
    }

    func cacheComprehensionQuestions(_ response: ComprehensionQuestionsOutput, for range: VerseRange, translationId: String, passageType: PassageType) {
        let key = "\(translationId):\(range.reference):\(passageType.rawValue)"
        comprehensions[key] = response
    }

    // MARK: - Cache Management

    func clearAll() {
        clearAllCallCount += 1
        explanations.removeAll()
        interpretations.removeAll()
        comprehensions.removeAll()
    }

    func purgeExpired() {
        purgeExpiredCallCount += 1
        // Mock implementation - no actual expiration
    }

    // MARK: - Test Helpers

    func preloadExplanation(_ response: ExplanationOutput, for range: VerseRange, translationId: String, mode: ExplanationMode = .plain) {
        let key = "\(translationId):\(range.reference):\(mode.rawValue)"
        explanations[key] = response
    }
}
