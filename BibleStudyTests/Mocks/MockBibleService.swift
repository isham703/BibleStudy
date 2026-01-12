//
//  MockBibleService.swift
//  BibleStudyTests
//
//  Mock Bible service for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock Bible Service

@MainActor
final class MockBibleService: BibleServiceProtocol {
    // MARK: - Configuration

    var currentTranslationId: String = "kjv"

    // MARK: - Stubbed Responses

    var stubbedVerses: [Verse] = []
    var stubbedSurroundingVerses: (before: [Verse], after: [Verse]) = ([], [])
    var stubbedChapter: Chapter?
    var stubbedError: Error?

    // MARK: - Call Tracking

    var getVersesCallCount = 0
    var getTextCallCount = 0
    var getSurroundingVersesCallCount = 0
    var getChapterCallCount = 0

    // MARK: - Protocol Methods

    func getVerses(range: VerseRange, translationId: String?) async throws -> [Verse] {
        getVersesCallCount += 1

        if let error = stubbedError {
            throw error
        }

        // Return stubbed verses or generate default test verses
        if !stubbedVerses.isEmpty {
            return stubbedVerses
        }

        return (range.verseStart...range.verseEnd).map { verseNum in
            Verse(
                bookId: range.bookId,
                chapter: range.chapter,
                verse: verseNum,
                text: "Mock verse \(verseNum) text.",
                translationId: translationId ?? currentTranslationId
            )
        }
    }

    func getText(range: VerseRange, translationId: String?) async throws -> String {
        getTextCallCount += 1

        if let error = stubbedError {
            throw error
        }

        let verses = try await getVerses(range: range, translationId: translationId)
        return verses.map { $0.text }.joined(separator: " ")
    }

    func getSurroundingVerses(for range: VerseRange, count: Int) async throws -> (before: [Verse], after: [Verse]) {
        getSurroundingVersesCallCount += 1

        if let error = stubbedError {
            throw error
        }

        return stubbedSurroundingVerses
    }

    func getChapter(bookId: Int, chapter: Int, translationId: String?) async throws -> Chapter {
        getChapterCallCount += 1

        if let error = stubbedError {
            throw error
        }

        if let stubbedChapter = stubbedChapter {
            return stubbedChapter
        }

        // Return empty chapter by default
        return Chapter(
            bookId: bookId,
            chapter: chapter,
            verses: []
        )
    }

    // MARK: - Test Helpers

    /// Reset all tracking and stubs
    func reset() {
        stubbedVerses = []
        stubbedSurroundingVerses = ([], [])
        stubbedChapter = nil
        stubbedError = nil
        getVersesCallCount = 0
        getTextCallCount = 0
        getSurroundingVersesCallCount = 0
        getChapterCallCount = 0
    }
}
