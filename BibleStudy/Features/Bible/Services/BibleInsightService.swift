import Foundation
import GRDB

// MARK: - Bible Insight Service
// Read-only access to bundled pre-generated commentary insights
// Opens CommentaryData.sqlite directly from app bundle
// Conforms to InsightProviding protocol for use in sermon enrichment

final class BibleInsightService: InsightProviding, Sendable {
    // MARK: - Singleton

    static let shared = BibleInsightService()

    // MARK: - Properties

    private let dbQueue: DatabaseQueue?
    private let isAvailable: Bool

    // MARK: - Initialization

    private init() {
        // Attempt to open bundled database in read-only mode
        guard let bundlePath = Bundle.main.path(forResource: "CommentaryData", ofType: "sqlite") else {
            print("BibleInsightService: CommentaryData.sqlite not found in bundle")
            self.dbQueue = nil
            self.isAvailable = false
            return
        }

        do {
            var config = Configuration()
            config.readonly = true  // Critical: prevents journal/WAL issues on bundle

            self.dbQueue = try DatabaseQueue(path: bundlePath, configuration: config)
            self.isAvailable = true
            print("BibleInsightService: Database opened successfully")
        } catch {
            print("BibleInsightService: Failed to open database - \(error)")
            self.dbQueue = nil
            self.isAvailable = false
        }
    }

    // MARK: - Public API

    /// Whether the commentary database is available
    var hasCommentaryData: Bool {
        isAvailable
    }

    /// Get all insights for a specific chapter
    /// - Parameters:
    ///   - bookId: Book ID (e.g., 43 for John)
    ///   - chapter: Chapter number
    /// - Returns: Array of insights ordered by verse and position
    func getInsights(bookId: Int, chapter: Int) async throws -> [BibleInsight] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        return try await dbQueue.read { db in
            try BibleInsight
                .filter(BibleInsight.Columns.bookId == bookId)
                .filter(BibleInsight.Columns.chapter == chapter)
                .order(BibleInsight.Columns.verseStart, BibleInsight.Columns.segmentStartChar)
                .fetchAll(db)
        }
    }

    /// Get insights for a specific verse
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    ///   - verse: Verse number
    /// - Returns: Array of insights for that verse
    func getInsights(bookId: Int, chapter: Int, verse: Int) async throws -> [BibleInsight] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        return try await dbQueue.read { db in
            try BibleInsight
                .filter(BibleInsight.Columns.bookId == bookId)
                .filter(BibleInsight.Columns.chapter == chapter)
                .filter(BibleInsight.Columns.verseStart <= verse)
                .filter(BibleInsight.Columns.verseEnd >= verse)
                .order(BibleInsight.Columns.segmentStartChar)
                .fetchAll(db)
        }
    }

    /// Get insights filtered by type
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    ///   - types: Set of insight types to include
    /// - Returns: Filtered array of insights
    func getInsights(bookId: Int, chapter: Int, types: Set<BibleInsightType>) async throws -> [BibleInsight] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        let typeStrings = types.map { $0.rawValue }

        return try await dbQueue.read { db in
            try BibleInsight
                .filter(BibleInsight.Columns.bookId == bookId)
                .filter(BibleInsight.Columns.chapter == chapter)
                .filter(typeStrings.contains(BibleInsight.Columns.insightType))
                .order(BibleInsight.Columns.verseStart, BibleInsight.Columns.segmentStartChar)
                .fetchAll(db)
        }
    }

    /// Build verse segments with paired insights for a chapter
    /// - Parameters:
    ///   - verses: Array of verses to segment
    ///   - insights: Insights to pair with segments
    /// - Returns: Array of segments - each verse shown as complete text, followed by its insights
    func buildSegments(from verses: [Verse], with insights: [BibleInsight]) -> [VerseSegmentWithInsight] {
        var segments: [VerseSegmentWithInsight] = []

        for verse in verses {
            let verseInsights = insights.filter {
                $0.verseStart <= verse.verse && $0.verseEnd >= verse.verse
            }.sorted { $0.segmentStartChar < $1.segmentStartChar }

            if verseInsights.isEmpty {
                // No insights - add whole verse as single segment
                segments.append(VerseSegmentWithInsight(text: verse.text))
            } else {
                // Show full verse text first, paired with first insight
                segments.append(VerseSegmentWithInsight(text: verse.text, insight: verseInsights[0]))

                // Add remaining insights with empty text (they stack below the verse)
                for insight in verseInsights.dropFirst() {
                    segments.append(VerseSegmentWithInsight(text: "", insight: insight))
                }
            }
        }

        return segments
    }

    /// Get count of insights for a book (for UI display)
    func getInsightCount(bookId: Int) async throws -> Int {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        return try await dbQueue.read { db in
            try BibleInsight
                .filter(BibleInsight.Columns.bookId == bookId)
                .fetchCount(db)
        }
    }

    /// Get chapters that have insights for a book
    func getChaptersWithInsights(bookId: Int) async throws -> [Int] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        return try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT DISTINCT chapter FROM commentary_insights
                WHERE book_id = ?
                ORDER BY chapter
            """, arguments: [bookId])

            return rows.map { $0["chapter"] as Int }
        }
    }

    /// Get insight counts per verse for a chapter (for Reading Mode indicators)
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    ///   - types: Optional set of insight types to include (nil = all types)
    /// - Returns: Dictionary mapping verse number to insight count
    func getInsightCountsByVerse(
        bookId: Int,
        chapter: Int,
        types: Set<BibleInsightType>? = nil
    ) async throws -> [Int: Int] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        return try await dbQueue.read { db in
            var sql = """
                SELECT verse_start, COUNT(*) as count
                FROM commentary_insights
                WHERE book_id = ? AND chapter = ?
            """
            var arguments: [DatabaseValueConvertible] = [bookId, chapter]

            // Add type filter if specified
            if let types = types, !types.isEmpty {
                let placeholders = types.map { _ in "?" }.joined(separator: ", ")
                sql += " AND insight_type IN (\(placeholders))"
                arguments.append(contentsOf: types.map { $0.rawValue })
            }

            sql += " GROUP BY verse_start"

            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))

            var counts: [Int: Int] = [:]
            for row in rows {
                let verse: Int = row["verse_start"]
                let count: Int = row["count"]
                counts[verse] = count
            }
            return counts
        }
    }

    /// Get insights grouped by verse for efficient loading
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    /// - Returns: Dictionary mapping verse number to array of insights
    func getInsightsGroupedByVerse(bookId: Int, chapter: Int) async throws -> [Int: [BibleInsight]] {
        let allInsights = try await getInsights(bookId: bookId, chapter: chapter)

        var grouped: [Int: [BibleInsight]] = [:]
        for insight in allInsights {
            grouped[insight.verseStart, default: []].append(insight)
        }
        return grouped
    }

    // MARK: - InsightProviding Protocol

    /// Get insight summaries for a specific verse (InsightProviding protocol)
    /// - Parameters:
    ///   - bookId: Book ID (e.g., 43 for John)
    ///   - chapter: Chapter number
    ///   - verse: Verse number
    /// - Returns: Array of insight summaries for sermon enrichment
    func getInsightSummaries(bookId: Int, chapter: Int, verse: Int) async throws -> [InsightSummary] {
        let insights = try await getInsights(bookId: bookId, chapter: chapter, verse: verse)
        return insights.map { $0.toInsightSummary() }
    }

    /// Get insight summaries for a verse range (InsightProviding protocol)
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    ///   - verseStart: Starting verse number
    ///   - verseEnd: Ending verse number (inclusive)
    /// - Returns: Array of insight summaries for sermon enrichment
    func getInsightSummaries(bookId: Int, chapter: Int, verseStart: Int, verseEnd: Int) async throws -> [InsightSummary] {
        guard let dbQueue = dbQueue else {
            throw BibleInsightError.databaseNotAvailable
        }

        let insights = try await dbQueue.read { db in
            try BibleInsight
                .filter(BibleInsight.Columns.bookId == bookId)
                .filter(BibleInsight.Columns.chapter == chapter)
                .filter(BibleInsight.Columns.verseStart <= verseEnd)
                .filter(BibleInsight.Columns.verseEnd >= verseStart)
                .order(BibleInsight.Columns.verseStart, BibleInsight.Columns.segmentStartChar)
                .fetchAll(db)
        }

        return insights.map { $0.toInsightSummary() }
    }
}

// MARK: - BibleInsight → InsightSummary Conversion

extension BibleInsight {
    /// Convert to InsightSummary for sermon enrichment (avoids Core → Features dependency)
    func toInsightSummary() -> InsightSummary {
        InsightSummary(
            id: id,
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            title: title,
            insightType: insightType.rawValue
        )
    }
}

// MARK: - Bible Insight Errors

enum BibleInsightError: Error, LocalizedError {
    case databaseNotAvailable
    case insightNotFound(String)
    case invalidSegmentLocator

    var errorDescription: String? {
        switch self {
        case .databaseNotAvailable:
            return "Bible insight database is not available. This feature requires pre-generated insights."
        case .insightNotFound(let id):
            return "Insight not found: \(id)"
        case .invalidSegmentLocator:
            return "Invalid segment locator: character indices out of bounds"
        }
    }
}

// MARK: - Environment Key

import SwiftUI

private struct BibleInsightServiceKey: EnvironmentKey {
    static let defaultValue: BibleInsightService = .shared
}

extension EnvironmentValues {
    var bibleInsightService: BibleInsightService {
        get { self[BibleInsightServiceKey.self] }
        set { self[BibleInsightServiceKey.self] = newValue }
    }
}
