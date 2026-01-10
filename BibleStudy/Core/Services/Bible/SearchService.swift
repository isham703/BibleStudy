import Foundation
import GRDB
import SwiftUI

// MARK: - Search Service
// Full-text search for Bible verses using FTS5

@MainActor
@Observable
final class SearchService {
    // MARK: - Singleton
    static let shared = SearchService()

    // MARK: - Dependencies
    private let db = DatabaseManager.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - Search Result
    struct SearchResult: Identifiable, Sendable {
        let id: Int64  // rowid from FTS
        let verse: Verse
        let snippet: String  // Raw snippet with <mark> tags
        let rank: Double

        @MainActor var highlightedSnippet: AttributedString {
            SearchService.parseSnippet(snippet)
        }

        var verseRange: VerseRange {
            VerseRange(
                bookId: verse.bookId,
                chapter: verse.chapter,
                verseStart: verse.verse,
                verseEnd: verse.verse
            )
        }
    }

    // MARK: - Search API

    /// Search verses using FTS5 full-text search
    /// - Parameters:
    ///   - query: Search query (supports phrases, AND/OR/NOT operators)
    ///   - translationId: Filter to specific translation (nil = current only)
    ///   - bookId: Filter to specific book (nil = all books)
    ///   - limit: Maximum results to return
    /// - Returns: Array of search results sorted by relevance
    func search(
        query: String,
        translationId: String? = nil,
        bookId: Int? = nil,
        limit: Int = 100
    ) async throws -> [SearchResult] {
        guard let dbQueue = db.dbQueue else {
            throw SearchError.databaseNotInitialized
        }

        let ftsQuery = buildFTSQuery(query)
        guard !ftsQuery.isEmpty else {
            return []
        }

        return try await dbQueue.read { db in
            try self.executeSearch(
                db: db,
                ftsQuery: ftsQuery,
                translationId: translationId,
                bookId: bookId,
                limit: limit
            )
        }
    }

    // MARK: - Private: Execute Search

    private nonisolated func executeSearch(
        db: Database,
        ftsQuery: String,
        translationId: String?,
        bookId: Int?,
        limit: Int
    ) throws -> [SearchResult] {
        // Build dynamic WHERE clause
        var conditions = ["verses_fts MATCH ?"]
        var arguments: [DatabaseValueConvertible] = [ftsQuery]

        if let tid = translationId {
            conditions.append("v.translation_id = ?")
            arguments.append(tid)
        }

        if let bid = bookId {
            conditions.append("v.book_id = ?")
            arguments.append(bid)
        }

        arguments.append(limit)

        let whereClause = conditions.joined(separator: " AND ")

        let sql = """
            SELECT v.*,
                   verses_fts.rowid as fts_rowid,
                   bm25(verses_fts) as rank,
                   snippet(verses_fts, 0, '<mark>', '</mark>', '...', 32) as snippet
            FROM verses_fts
            JOIN verses v ON verses_fts.rowid = v.rowid
            WHERE \(whereClause)
            ORDER BY rank
            LIMIT ?
            """

        let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))

        return rows.compactMap { row -> SearchResult? in
            let verse = Verse(row: row)
            return SearchResult(
                id: row["fts_rowid"] as? Int64 ?? 0,
                verse: verse,
                snippet: row["snippet"] as? String ?? verse.text,
                rank: row["rank"] as? Double ?? 0
            )
        }
    }

    // MARK: - Query Building & Sanitization

    private func buildFTSQuery(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Reject empty or overly long queries
        guard !trimmed.isEmpty, trimmed.count <= 200 else { return "" }

        // Handle phrase queries: "exact phrase"
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count > 2 {
            let phrase = String(trimmed.dropFirst().dropLast())
            let sanitized = sanitizeToken(phrase)
            return sanitized.isEmpty ? "" : "\"\(sanitized)\""
        }

        // Tokenize and process
        var tokens = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Cap token count to prevent pathological queries
        if tokens.count > 10 {
            tokens = Array(tokens.prefix(10))
        }

        // Build query with operators
        var result: [String] = []
        var i = 0

        while i < tokens.count {
            let token = tokens[i]
            let upperToken = token.uppercased()

            if upperToken == "AND" || upperToken == "OR" {
                // Pass through boolean operators
                result.append(upperToken)
            } else if upperToken == "NOT" && i + 1 < tokens.count {
                // NOT must be followed by a term
                result.append("NOT")
            } else {
                // Regular term: sanitize and add prefix wildcard for partial matching
                let clean = sanitizeToken(token)
                if !clean.isEmpty {
                    result.append(clean + "*")
                }
            }
            i += 1
        }

        // Remove trailing operators that have no following term
        while let last = result.last,
              ["AND", "OR", "NOT"].contains(last) {
            result.removeLast()
        }

        return result.joined(separator: " ")
    }

    private func sanitizeToken(_ token: String) -> String {
        // Remove FTS5 special characters that could break queries
        // Keep: letters, numbers, apostrophe (for "God's"), hyphen (for compound words)
        token.filter { $0.isLetter || $0.isNumber || $0 == "'" || $0 == "-" }
    }

    // MARK: - Snippet Parsing

    private static func parseSnippet(_ text: String) -> AttributedString {
        var result = AttributedString()
        var remaining = text[...]

        while let markStart = remaining.range(of: "<mark>") {
            // Add text before mark
            let beforeText = String(remaining[..<markStart.lowerBound])
            result += AttributedString(beforeText)
            remaining = remaining[markStart.upperBound...]

            // Find closing mark
            if let markEnd = remaining.range(of: "</mark>") {
                let highlightedText = String(remaining[..<markEnd.lowerBound])
                var highlighted = AttributedString(highlightedText)
                highlighted.backgroundColor = Color.yellow.opacity(Theme.Opacity.disabled)
                highlighted.font = .body.bold()
                result += highlighted
                remaining = remaining[markEnd.upperBound...]
            }
        }

        // Add remaining text
        result += AttributedString(String(remaining))
        return result
    }
}

// MARK: - Search Errors

enum SearchError: Error, LocalizedError {
    case databaseNotInitialized
    case invalidQuery(String)
    case searchFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotInitialized:
            return "Database not initialized"
        case .invalidQuery(let query):
            return "Invalid search query: \(query)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        }
    }
}
