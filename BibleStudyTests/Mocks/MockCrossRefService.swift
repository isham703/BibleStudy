//
//  MockCrossRefService.swift
//  BibleStudyTests
//
//  Mock cross-reference service for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock Cross Reference Service

@MainActor
final class MockCrossRefService: CrossRefServiceProtocol {
    // MARK: - Stubbed Responses

    var stubbedCrossRefsWithText: [CrossReferenceWithExplanation] = []
    var stubbedIncomingRefs: [CrossReference] = []
    var stubbedSampleRefs: [CrossReferenceWithExplanation] = []
    var stubbedError: Error?

    // MARK: - Call Tracking

    var getCrossReferencesWithTextCallCount = 0
    var getIncomingCrossReferencesCallCount = 0
    var getSampleCrossReferencesCallCount = 0

    // MARK: - Protocol Methods

    func getCrossReferencesWithText(for range: VerseRange) async throws -> [CrossReferenceWithExplanation] {
        getCrossReferencesWithTextCallCount += 1

        if let error = stubbedError {
            throw error
        }

        return stubbedCrossRefsWithText
    }

    func getIncomingCrossReferences(for range: VerseRange) throws -> [CrossReference] {
        getIncomingCrossReferencesCallCount += 1

        if let error = stubbedError {
            throw error
        }

        return stubbedIncomingRefs
    }

    func getSampleCrossReferences(for range: VerseRange) -> [CrossReferenceWithExplanation] {
        getSampleCrossReferencesCallCount += 1
        return stubbedSampleRefs
    }

    // MARK: - Test Helpers

    func reset() {
        stubbedCrossRefsWithText = []
        stubbedIncomingRefs = []
        stubbedSampleRefs = []
        stubbedError = nil
        getCrossReferencesWithTextCallCount = 0
        getIncomingCrossReferencesCallCount = 0
        getSampleCrossReferencesCallCount = 0
    }
}
