//
//  MockLanguageService.swift
//  BibleStudyTests
//
//  Mock language service for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock Language Service

@MainActor
final class MockLanguageService: LanguageServiceProtocol {
    // MARK: - Stubbed Responses

    var stubbedTokens: [LanguageToken] = []
    var stubbedSampleTokens: [LanguageToken] = []
    var stubbedError: Error?

    // MARK: - Call Tracking

    var getTokensCallCount = 0
    var getSampleTokensCallCount = 0

    // MARK: - Protocol Methods

    func getTokens(for range: VerseRange) throws -> [LanguageToken] {
        getTokensCallCount += 1

        if let error = stubbedError {
            throw error
        }

        return stubbedTokens
    }

    func getSampleTokens(for range: VerseRange) -> [LanguageToken] {
        getSampleTokensCallCount += 1
        return stubbedSampleTokens
    }

    // MARK: - Test Helpers

    func reset() {
        stubbedTokens = []
        stubbedSampleTokens = []
        stubbedError = nil
        getTokensCallCount = 0
        getSampleTokensCallCount = 0
    }
}
