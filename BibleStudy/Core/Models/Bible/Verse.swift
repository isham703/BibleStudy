import Foundation
import GRDB

// MARK: - Verse Model
// Represents a single verse in the Bible

struct Verse: Identifiable, Hashable, Sendable {
    let translationId: String
    let bookId: Int
    let chapter: Int
    let verse: Int
    let text: String

    /// Convenience initializer with default translation
    init(bookId: Int, chapter: Int, verse: Int, text: String, translationId: String = "kjv") {
        self.translationId = translationId
        self.bookId = bookId
        self.chapter = chapter
        self.verse = verse
        self.text = text
    }

    var id: String {
        "\(translationId).\(bookId).\(chapter).\(verse)"
    }

    /// ID without translation for cross-translation comparison
    var verseId: String {
        "\(bookId).\(chapter).\(verse)"
    }

    var book: Book? {
        Book.find(byId: bookId)
    }

    var reference: String {
        guard let book = book else { return id }
        return "\(book.name) \(chapter):\(verse)"
    }

    var shortReference: String {
        guard let book = book else { return id }
        return "\(book.abbreviation) \(chapter):\(verse)"
    }

    /// Reference with translation abbreviation (e.g., "John 3:16 (ESV)")
    var fullReference: String {
        let translationAbbr = translationId.uppercased()
        return "\(reference) (\(translationAbbr))"
    }
}

// MARK: - GRDB Support
extension Verse: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "verses" }

    enum Columns: String, ColumnExpression {
        case translationId = "translation_id"
        case bookId = "book_id"
        case chapter
        case verse
        case text
    }

    nonisolated init(row: Row) {
        translationId = row[Columns.translationId]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verse = row[Columns.verse]
        text = row[Columns.text]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.translationId] = translationId
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verse] = verse
        container[Columns.text] = text
    }
}

// MARK: - Verse ID Parsing
extension Verse {
    /// Parse a verse ID string (e.g., "1.1.1" for Genesis 1:1)
    static func parseId(_ id: String) -> (bookId: Int, chapter: Int, verse: Int)? {
        let parts = id.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return (parts[0], parts[1], parts[2])
    }

    /// Parse a reference string (e.g., "Genesis 1:1" or "Gen 1:1")
    static func parseReference(_ reference: String) -> (bookId: Int, chapter: Int, verse: Int)? {
        // Pattern: "Book Chapter:Verse" or "Book Chapter:Verse-Verse"
        let pattern = #"^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(reference.startIndex..., in: reference)
        guard let match = regex.firstMatch(in: reference, options: [], range: range) else {
            return nil
        }

        guard let bookRange = Range(match.range(at: 1), in: reference),
              let chapterRange = Range(match.range(at: 2), in: reference),
              let verseRange = Range(match.range(at: 3), in: reference) else {
            return nil
        }

        let bookStr = String(reference[bookRange]).trimmingCharacters(in: .whitespaces)
        guard let book = Book.find(byName: bookStr) ?? Book.find(byAbbreviation: bookStr),
              let chapter = Int(reference[chapterRange]),
              let verse = Int(reference[verseRange]) else {
            return nil
        }

        return (book.id, chapter, verse)
    }
}

// MARK: - Verse Comparison
extension Verse: Comparable {
    static func < (lhs: Verse, rhs: Verse) -> Bool {
        if lhs.bookId != rhs.bookId {
            return lhs.bookId < rhs.bookId
        }
        if lhs.chapter != rhs.chapter {
            return lhs.chapter < rhs.chapter
        }
        return lhs.verse < rhs.verse
    }
}

// MARK: - Chapter Model
// Represents a chapter with all its verses

struct Chapter: Identifiable, Sendable, Equatable {
    let translationId: String
    let bookId: Int
    let chapter: Int
    let verses: [Verse]

    /// Convenience initializer with default translation
    init(bookId: Int, chapter: Int, verses: [Verse], translationId: String = "kjv") {
        self.translationId = translationId
        self.bookId = bookId
        self.chapter = chapter
        self.verses = verses
    }

    static func == (lhs: Chapter, rhs: Chapter) -> Bool {
        lhs.translationId == rhs.translationId && lhs.bookId == rhs.bookId && lhs.chapter == rhs.chapter
    }

    var id: String {
        "\(translationId).\(bookId).\(chapter)"
    }

    var book: Book? {
        Book.find(byId: bookId)
    }

    var reference: String {
        guard let book = book else { return id }
        return "\(book.name) \(chapter)"
    }

    /// Reference with translation abbreviation
    var fullReference: String {
        let translationAbbr = translationId.uppercased()
        return "\(reference) (\(translationAbbr))"
    }

    var verseCount: Int {
        verses.count
    }

    func verse(at number: Int) -> Verse? {
        verses.first { $0.verse == number }
    }

    func verses(from start: Int, to end: Int) -> [Verse] {
        verses.filter { $0.verse >= start && $0.verse <= end }
    }
}

// MARK: - Bible Location
// Represents a specific location in the Bible for navigation

struct BibleLocation: Codable, Hashable, Sendable {
    let bookId: Int
    let chapter: Int
    var verse: Int?

    var book: Book? {
        Book.find(byId: bookId)
    }

    var reference: String {
        guard let book = book else { return "\(bookId):\(chapter)" }
        if let verse = verse {
            return "\(book.name) \(chapter):\(verse)"
        }
        return "\(book.name) \(chapter)"
    }

    static var genesis1: BibleLocation {
        BibleLocation(bookId: 1, chapter: 1)
    }

    static var john1: BibleLocation {
        BibleLocation(bookId: 43, chapter: 1)
    }

    static var psalm1: BibleLocation {
        BibleLocation(bookId: 19, chapter: 1)
    }

    func next(maxChapter: Int) -> BibleLocation? {
        if chapter < maxChapter {
            return BibleLocation(bookId: bookId, chapter: chapter + 1)
        }
        // Move to next book
        if let nextBook = Book.find(byId: bookId + 1) {
            return BibleLocation(bookId: nextBook.id, chapter: 1)
        }
        return nil
    }

    func previous() -> BibleLocation? {
        if chapter > 1 {
            return BibleLocation(bookId: bookId, chapter: chapter - 1)
        }
        // Move to previous book
        if let prevBook = Book.find(byId: bookId - 1) {
            return BibleLocation(bookId: prevBook.id, chapter: prevBook.chapters)
        }
        return nil
    }
}
