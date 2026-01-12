//
//  ContextLoader.swift
//  BibleStudy
//
//  Domain loader for surrounding verse context
//  Encapsulates verse fetching and context building
//

import Foundation

// Note: ContextInfo is defined in BibleInsightViewModel.swift

// MARK: - Context Load Result

/// Result of loading context information
struct ContextLoadResult: Sendable {
    let contextInfo: ContextInfo?
    let error: Error?

    static let empty = ContextLoadResult(contextInfo: nil, error: nil)
}

// MARK: - Context Loader

/// Loads surrounding context for verses
/// Fetches verses before and after the selected range
@MainActor
final class ContextLoader {
    // MARK: - Dependencies

    private let bibleService: BibleServiceProtocol

    // MARK: - Configuration

    private let contextVerseCount: Int

    // MARK: - Initialization

    init(
        bibleService: BibleServiceProtocol? = nil,
        contextVerseCount: Int = 2
    ) {
        self.bibleService = bibleService ?? BibleService.shared
        self.contextVerseCount = contextVerseCount
    }

    // MARK: - Load Context

    /// Load surrounding context for a verse range
    /// - Parameter verseRange: The verse range to load context around
    /// - Returns: ContextLoadResult with before/after text
    func load(for verseRange: VerseRange) async -> ContextLoadResult {
        do {
            // Get verses before the selected range
            let beforeRange = VerseRange(
                bookId: verseRange.bookId,
                chapter: verseRange.chapter,
                verseStart: max(1, verseRange.verseStart - contextVerseCount),
                verseEnd: max(1, verseRange.verseStart - 1)
            )

            // Get verses after the selected range
            let afterRange = VerseRange(
                bookId: verseRange.bookId,
                chapter: verseRange.chapter,
                verseStart: verseRange.verseEnd + 1,
                verseEnd: verseRange.verseEnd + contextVerseCount
            )

            let beforeVerses = try await bibleService.getVerses(range: beforeRange, translationId: nil)
            let afterVerses = try await bibleService.getVerses(range: afterRange, translationId: nil)

            let beforeText = beforeVerses.isEmpty
                ? "(Beginning of chapter)"
                : beforeVerses.map { "v.\($0.verse): \($0.text)" }.joined(separator: " ")

            let afterText = afterVerses.isEmpty
                ? "(End of chapter)"
                : afterVerses.map { "v.\($0.verse): \($0.text)" }.joined(separator: " ")

            let contextInfo = ContextInfo(
                before: beforeText,
                after: afterText,
                keyPeople: nil,
                keyPlaces: nil
            )

            return ContextLoadResult(contextInfo: contextInfo, error: nil)
        } catch {
            // Fall back to sample context
            let contextInfo = ContextInfo(
                before: "(Unable to load preceding verses)",
                after: "(Unable to load following verses)",
                keyPeople: nil,
                keyPlaces: nil
            )
            return ContextLoadResult(contextInfo: contextInfo, error: error)
        }
    }

    // MARK: - Load Surrounding Verses

    /// Load surrounding verses with explicit before/after counts
    /// - Parameters:
    ///   - verseRange: The verse range to load context around
    ///   - beforeCount: Number of verses to load before
    ///   - afterCount: Number of verses to load after
    /// - Returns: Tuple of before and after verses
    func loadSurrounding(
        for verseRange: VerseRange,
        beforeCount: Int = 3,
        afterCount: Int = 3
    ) async -> (before: [Verse], after: [Verse]) {
        do {
            return try await bibleService.getSurroundingVerses(for: verseRange, count: max(beforeCount, afterCount))
        } catch {
            return ([], [])
        }
    }
}
