//
//  LanguageServiceProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for Hebrew/Greek language service
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - Language Service Protocol

/// Protocol for Hebrew/Greek language data access
/// Abstracts LanguageService for dependency injection
@MainActor
protocol LanguageServiceProtocol: Sendable {
    /// Get language tokens for a verse range
    func getTokens(for range: VerseRange) throws -> [LanguageToken]

    /// Get sample tokens for development/testing
    func getSampleTokens(for range: VerseRange) -> [LanguageToken]
}

// MARK: - Conformance

extension LanguageService: LanguageServiceProtocol {}
