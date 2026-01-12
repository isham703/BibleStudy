//
//  BibleServiceProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for Bible service
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - Bible Service Protocol

/// Protocol for Bible verse and chapter access
/// Abstracts BibleService for dependency injection
@MainActor
protocol BibleServiceProtocol: Sendable {
    /// Current translation ID
    var currentTranslationId: String { get }

    /// Get verses for a range
    func getVerses(range: VerseRange, translationId: String?) async throws -> [Verse]

    /// Get combined text for a range
    func getText(range: VerseRange, translationId: String?) async throws -> String

    /// Get surrounding verses for context
    func getSurroundingVerses(for range: VerseRange, count: Int) async throws -> (before: [Verse], after: [Verse])

    /// Get a chapter
    func getChapter(bookId: Int, chapter: Int, translationId: String?) async throws -> Chapter
}

// MARK: - Conformance

extension BibleService: BibleServiceProtocol {}
