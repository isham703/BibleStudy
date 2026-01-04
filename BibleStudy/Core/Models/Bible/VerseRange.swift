import Foundation

// MARK: - Verse Range
// Represents a range of verses (single verse or multiple)

struct VerseRange: Codable, Hashable, Identifiable, Sendable {
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int

    var id: String {
        if verseStart == verseEnd {
            return "\(bookId).\(chapter).\(verseStart)"
        }
        return "\(bookId).\(chapter).\(verseStart)-\(verseEnd)"
    }

    var book: Book? {
        Book.find(byId: bookId)
    }

    var isSingleVerse: Bool {
        verseStart == verseEnd
    }

    var verseCount: Int {
        verseEnd - verseStart + 1
    }

    var reference: String {
        guard let book = book else { return id }
        if isSingleVerse {
            return "\(book.name) \(chapter):\(verseStart)"
        }
        return "\(book.name) \(chapter):\(verseStart)-\(verseEnd)"
    }

    var shortReference: String {
        guard let book = book else { return id }
        if isSingleVerse {
            return "\(book.abbreviation) \(chapter):\(verseStart)"
        }
        return "\(book.abbreviation) \(chapter):\(verseStart)-\(verseEnd)"
    }

    // MARK: - Initializers
    nonisolated init(bookId: Int, chapter: Int, verseStart: Int, verseEnd: Int) {
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = min(verseStart, verseEnd)
        self.verseEnd = max(verseStart, verseEnd)
    }

    nonisolated init(bookId: Int, chapter: Int, verse: Int) {
        self.init(bookId: bookId, chapter: chapter, verseStart: verse, verseEnd: verse)
    }

    nonisolated init(verse: Verse) {
        self.init(bookId: verse.bookId, chapter: verse.chapter, verse: verse.verse)
    }

    nonisolated init(verses: [Verse]) {
        guard let first = verses.first, let last = verses.last else {
            fatalError("Cannot create VerseRange from empty array")
        }
        self.init(
            bookId: first.bookId,
            chapter: first.chapter,
            verseStart: first.verse,
            verseEnd: last.verse
        )
    }

    // MARK: - Containment
    func contains(verse: Int) -> Bool {
        verse >= verseStart && verse <= verseEnd
    }

    func contains(verseRange: VerseRange) -> Bool {
        bookId == verseRange.bookId &&
        chapter == verseRange.chapter &&
        verseStart <= verseRange.verseStart &&
        verseEnd >= verseRange.verseEnd
    }

    func overlaps(with other: VerseRange) -> Bool {
        guard bookId == other.bookId && chapter == other.chapter else {
            return false
        }
        return verseStart <= other.verseEnd && verseEnd >= other.verseStart
    }

    // MARK: - Expansion
    func expanded(by amount: Int) -> VerseRange {
        VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: max(1, verseStart - amount),
            verseEnd: verseEnd + amount // Will be clamped by actual verse count
        )
    }

    func merged(with other: VerseRange) -> VerseRange? {
        guard bookId == other.bookId && chapter == other.chapter else {
            return nil
        }
        return VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: min(verseStart, other.verseStart),
            verseEnd: max(verseEnd, other.verseEnd)
        )
    }
}

// MARK: - Parsing
extension VerseRange {
    /// Parse a reference string (e.g., "Genesis 1:1", "Gen 1:1-5")
    static func parse(_ reference: String) -> VerseRange? {
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
              let verseStartRange = Range(match.range(at: 3), in: reference) else {
            return nil
        }

        let bookStr = String(reference[bookRange]).trimmingCharacters(in: .whitespaces)
        guard let book = Book.find(byName: bookStr) ?? Book.find(byAbbreviation: bookStr),
              let chapter = Int(reference[chapterRange]),
              let verseStart = Int(reference[verseStartRange]) else {
            return nil
        }

        let verseEnd: Int
        if match.range(at: 4).location != NSNotFound,
           let verseEndRange = Range(match.range(at: 4), in: reference),
           let parsed = Int(reference[verseEndRange]) {
            verseEnd = parsed
        } else {
            verseEnd = verseStart
        }

        return VerseRange(
            bookId: book.id,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }

    /// Parse a verse ID string (e.g., "1.1.1" or "1.1.1-5")
    static func parseId(_ id: String) -> VerseRange? {
        // Pattern: "bookId.chapter.verse" or "bookId.chapter.verse-verse"
        let parts = id.split(separator: ".")
        guard parts.count == 3 else { return nil }

        guard let bookId = Int(parts[0]),
              let chapter = Int(parts[1]) else {
            return nil
        }

        let versePart = String(parts[2])
        let verseParts = versePart.split(separator: "-")

        guard let verseStart = Int(verseParts[0]) else {
            return nil
        }

        let verseEnd: Int
        if verseParts.count > 1, let end = Int(verseParts[1]) {
            verseEnd = end
        } else {
            verseEnd = verseStart
        }

        return VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
}

// MARK: - Comparison
extension VerseRange: Comparable {
    static func < (lhs: VerseRange, rhs: VerseRange) -> Bool {
        if lhs.bookId != rhs.bookId {
            return lhs.bookId < rhs.bookId
        }
        if lhs.chapter != rhs.chapter {
            return lhs.chapter < rhs.chapter
        }
        if lhs.verseStart != rhs.verseStart {
            return lhs.verseStart < rhs.verseStart
        }
        return lhs.verseEnd < rhs.verseEnd
    }
}

// MARK: - Common Ranges
extension VerseRange {
    static var genesis1_1: VerseRange {
        VerseRange(bookId: 1, chapter: 1, verse: 1)
    }

    static var john3_16: VerseRange {
        VerseRange(bookId: 43, chapter: 3, verse: 16)
    }

    static var psalm23: VerseRange {
        VerseRange(bookId: 19, chapter: 23, verseStart: 1, verseEnd: 6)
    }
}

// MARK: - Nonisolated JSON Helpers
// For use in GRDB and other nonisolated contexts
// Uses JSONSerialization to avoid MainActor-isolated Codable conformance issues
extension VerseRange {
    /// Decode from JSON string in nonisolated context
    nonisolated static func fromJSON(_ jsonString: String) -> VerseRange? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bookId = dict["bookId"] as? Int,
              let chapter = dict["chapter"] as? Int,
              let verseStart = dict["verseStart"] as? Int,
              let verseEnd = dict["verseEnd"] as? Int else {
            return nil
        }
        return VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }

    /// Encode to JSON string in nonisolated context
    nonisolated func toJSON() -> String? {
        let dict: [String: Any] = [
            "bookId": bookId,
            "chapter": chapter,
            "verseStart": verseStart,
            "verseEnd": verseEnd
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Decode array from JSON string in nonisolated context
    nonisolated static func arrayFromJSON(_ jsonString: String) -> [VerseRange]? {
        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return array.compactMap { dict -> VerseRange? in
            guard let bookId = dict["bookId"] as? Int,
                  let chapter = dict["chapter"] as? Int,
                  let verseStart = dict["verseStart"] as? Int,
                  let verseEnd = dict["verseEnd"] as? Int else {
                return nil
            }
            return VerseRange(
                bookId: bookId,
                chapter: chapter,
                verseStart: verseStart,
                verseEnd: verseEnd
            )
        }
    }

    /// Encode array to JSON string in nonisolated context
    nonisolated static func arrayToJSON(_ ranges: [VerseRange]) -> String? {
        let array = ranges.map { range -> [String: Any] in
            [
                "bookId": range.bookId,
                "chapter": range.chapter,
                "verseStart": range.verseStart,
                "verseEnd": range.verseEnd
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: array) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
