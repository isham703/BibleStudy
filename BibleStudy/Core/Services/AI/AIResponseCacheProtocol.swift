//
//  AIResponseCacheProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for AI response cache
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - AI Response Cache Protocol

/// Protocol for caching AI-generated responses
/// Abstracts AIResponseCache for dependency injection
@MainActor
protocol AIResponseCacheProtocol: Sendable {
    // MARK: - Explanation Cache

    func getExplanation(for range: VerseRange, translationId: String, mode: ExplanationMode) -> ExplanationOutput?
    func cacheExplanation(_ response: ExplanationOutput, for range: VerseRange, translationId: String, mode: ExplanationMode)

    // MARK: - Interpretation Cache

    func getInterpretation(for range: VerseRange, translationId: String, mode: InterpretationViewMode) -> InterpretationOutput?
    func cacheInterpretation(_ response: InterpretationOutput, for range: VerseRange, translationId: String, mode: InterpretationViewMode)

    // MARK: - Comprehension Cache

    func getComprehensionQuestions(for range: VerseRange, translationId: String, passageType: PassageType) -> ComprehensionQuestionsOutput?
    func cacheComprehensionQuestions(_ response: ComprehensionQuestionsOutput, for range: VerseRange, translationId: String, passageType: PassageType)

    // MARK: - Cache Management

    func clearAll()
    func purgeExpired()
}

// MARK: - Conformance

extension AIResponseCache: AIResponseCacheProtocol {}
