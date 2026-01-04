import Foundation
import GRDB

// MARK: - Bible Repository
// Handles all Bible data operations with the local database

final class BibleRepository: @unchecked Sendable {
    // MARK: - Singleton
    static let shared = BibleRepository()

    // MARK: - Properties
    private var database: DatabaseManager { DatabaseManager.shared }

    /// Default translation ID used when none is specified
    static let defaultTranslationId = "kjv"

    // MARK: - Initialization
    private init() {}

    // MARK: - Verse Operations

    /// Fetch a single verse
    func getVerse(bookId: Int, chapter: Int, verse: Int, translationId: String = defaultTranslationId) throws -> Verse? {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .filter(Verse.Columns.verse == verse)
                .fetchOne(db)
        }
    }

    /// Fetch all verses for a chapter
    func getChapter(bookId: Int, chapter: Int, translationId: String = defaultTranslationId) throws -> [Verse] {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .order(Verse.Columns.verse)
                .fetchAll(db)
        }
    }

    /// Fetch verses in a range
    func getVerses(range: VerseRange, translationId: String = defaultTranslationId) throws -> [Verse] {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == range.bookId)
                .filter(Verse.Columns.chapter == range.chapter)
                .filter(Verse.Columns.verse >= range.verseStart)
                .filter(Verse.Columns.verse <= range.verseEnd)
                .order(Verse.Columns.verse)
                .fetchAll(db)
        }
    }

    /// Fetch verse count for a chapter
    func getVerseCount(bookId: Int, chapter: Int, translationId: String = defaultTranslationId) throws -> Int {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .fetchCount(db)
        }
    }

    /// Search verses by text
    func searchVerses(query: String, translationId: String = defaultTranslationId, limit: Int = 50) throws -> [Verse] {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.text.like("%\(query)%"))
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - Chapter Info

    /// Get chapter count for a book
    func getChapterCount(bookId: Int, translationId: String = defaultTranslationId) throws -> Int {
        try database.read { db in
            try Int.fetchOne(db, sql: """
                SELECT MAX(chapter) FROM verses WHERE translation_id = ? AND book_id = ?
                """, arguments: [translationId, bookId]) ?? 0
        }
    }

    /// Check if a chapter exists
    func chapterExists(bookId: Int, chapter: Int, translationId: String = defaultTranslationId) throws -> Bool {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .fetchCount(db) > 0
        }
    }

    // MARK: - Translation Operations

    /// Get all available translations from the database
    func getTranslations() throws -> [Translation] {
        try database.read { db in
            try Translation
                .order(Translation.DatabaseColumns.sortOrder)
                .fetchAll(db)
        }
    }

    /// Get a translation by ID
    func getTranslation(id: String) throws -> Translation? {
        try database.read { db in
            try Translation
                .filter(Translation.DatabaseColumns.id == id)
                .fetchOne(db)
        }
    }

    /// Get translations that have verse data
    func getAvailableTranslations() throws -> [Translation] {
        try database.read { db in
            try Translation
                .filter(sql: """
                    id IN (SELECT DISTINCT translation_id FROM verses)
                    """)
                .order(Translation.DatabaseColumns.sortOrder)
                .fetchAll(db)
        }
    }

    // MARK: - Cross-Translation Comparison

    /// Fetch a verse in multiple translations for comparison
    func getVerseInTranslations(bookId: Int, chapter: Int, verse: Int, translationIds: [String]) throws -> [Verse] {
        try database.read { db in
            try Verse
                .filter(translationIds.contains(Verse.Columns.translationId))
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .filter(Verse.Columns.verse == verse)
                .fetchAll(db)
        }
    }

    // MARK: - Import Operations

    /// Import verses from JSON data for a specific translation
    func importVerses(from data: Data, translationId: String = defaultTranslationId) throws -> Int {
        let decoder = JSONDecoder()
        let versesData = try decoder.decode([VerseImport].self, from: data)

        var count = 0
        try database.write { db in
            for verseData in versesData {
                let verse = Verse(
                    bookId: verseData.bookId,
                    chapter: verseData.chapter,
                    verse: verseData.verse,
                    text: verseData.text,
                    translationId: translationId
                )
                try verse.insert(db, onConflict: .replace)
                count += 1
            }
        }

        return count
    }

    /// Import verses from a JSON file in the bundle
    func importVersesFromBundle(filename: String, translationId: String = defaultTranslationId) throws -> Int {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DatabaseError.importFailed("File not found: \(filename).json")
        }

        let data = try Data(contentsOf: url)
        return try importVerses(from: data, translationId: translationId)
    }

    /// Check if Bible data has been imported
    func hasData() throws -> Bool {
        try database.read { db in
            try Verse.fetchCount(db) > 0
        }
    }

    /// Check if a specific translation has data
    func hasData(translationId: String) throws -> Bool {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .fetchCount(db) > 0
        }
    }
}

// MARK: - Import Data Structures
private struct VerseImport: Codable {
    let bookId: Int
    let chapter: Int
    let verse: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case bookId = "book_id"
        case chapter
        case verse
        case text
    }
}
