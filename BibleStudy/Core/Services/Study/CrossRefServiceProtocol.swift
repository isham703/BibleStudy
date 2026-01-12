//
//  CrossRefServiceProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for cross-reference service
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - Cross Reference Service Protocol

/// Protocol for cross-reference data access
/// Abstracts CrossRefService for dependency injection
@MainActor
protocol CrossRefServiceProtocol: Sendable {
    /// Get cross-references for a verse range with target verse text
    func getCrossReferencesWithText(for range: VerseRange) async throws -> [CrossReferenceWithExplanation]

    /// Get cross-references that point TO a verse range
    func getIncomingCrossReferences(for range: VerseRange) throws -> [CrossReference]

    /// Get sample cross-references for development/testing
    func getSampleCrossReferences(for range: VerseRange) -> [CrossReferenceWithExplanation]
}

// MARK: - Conformance

extension CrossRefService: CrossRefServiceProtocol {}
