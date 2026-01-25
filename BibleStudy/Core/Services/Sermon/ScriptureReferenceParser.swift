//
//  ScriptureReferenceParser.swift
//  BibleStudy
//
//  Parses scripture references from text to extract book names
//  Used for deterministic grouping of sermons by scripture book
//

import Foundation

// MARK: - Scripture Reference Parser

struct ScriptureReferenceParser {

    // MARK: - Book Names

    /// All Bible book names with common variations
    static let bookNames: [String: String] = [
        // Old Testament
        "genesis": "Genesis",
        "gen": "Genesis",
        "exodus": "Exodus",
        "exod": "Exodus",
        "ex": "Exodus",
        "leviticus": "Leviticus",
        "lev": "Leviticus",
        "numbers": "Numbers",
        "num": "Numbers",
        "deuteronomy": "Deuteronomy",
        "deut": "Deuteronomy",
        "joshua": "Joshua",
        "josh": "Joshua",
        "judges": "Judges",
        "judg": "Judges",
        "ruth": "Ruth",
        "1 samuel": "1 Samuel",
        "1samuel": "1 Samuel",
        "1 sam": "1 Samuel",
        "1sam": "1 Samuel",
        "2 samuel": "2 Samuel",
        "2samuel": "2 Samuel",
        "2 sam": "2 Samuel",
        "2sam": "2 Samuel",
        "1 kings": "1 Kings",
        "1kings": "1 Kings",
        "1 kgs": "1 Kings",
        "2 kings": "2 Kings",
        "2kings": "2 Kings",
        "2 kgs": "2 Kings",
        "1 chronicles": "1 Chronicles",
        "1chronicles": "1 Chronicles",
        "1 chr": "1 Chronicles",
        "2 chronicles": "2 Chronicles",
        "2chronicles": "2 Chronicles",
        "2 chr": "2 Chronicles",
        "ezra": "Ezra",
        "nehemiah": "Nehemiah",
        "neh": "Nehemiah",
        "esther": "Esther",
        "est": "Esther",
        "job": "Job",
        "psalms": "Psalms",
        "psalm": "Psalms",
        "ps": "Psalms",
        "proverbs": "Proverbs",
        "prov": "Proverbs",
        "ecclesiastes": "Ecclesiastes",
        "eccl": "Ecclesiastes",
        "ecc": "Ecclesiastes",
        "song of solomon": "Song of Solomon",
        "song of songs": "Song of Solomon",
        "song": "Song of Solomon",
        "isaiah": "Isaiah",
        "isa": "Isaiah",
        "jeremiah": "Jeremiah",
        "jer": "Jeremiah",
        "lamentations": "Lamentations",
        "lam": "Lamentations",
        "ezekiel": "Ezekiel",
        "ezek": "Ezekiel",
        "daniel": "Daniel",
        "dan": "Daniel",
        "hosea": "Hosea",
        "hos": "Hosea",
        "joel": "Joel",
        "amos": "Amos",
        "obadiah": "Obadiah",
        "obad": "Obadiah",
        "jonah": "Jonah",
        "micah": "Micah",
        "mic": "Micah",
        "nahum": "Nahum",
        "nah": "Nahum",
        "habakkuk": "Habakkuk",
        "hab": "Habakkuk",
        "zephaniah": "Zephaniah",
        "zeph": "Zephaniah",
        "haggai": "Haggai",
        "hag": "Haggai",
        "zechariah": "Zechariah",
        "zech": "Zechariah",
        "malachi": "Malachi",
        "mal": "Malachi",

        // New Testament
        "matthew": "Matthew",
        "matt": "Matthew",
        "mt": "Matthew",
        "mark": "Mark",
        "mk": "Mark",
        "luke": "Luke",
        "lk": "Luke",
        "john": "John",
        "jn": "John",
        "acts": "Acts",
        "romans": "Romans",
        "rom": "Romans",
        "1 corinthians": "1 Corinthians",
        "1corinthians": "1 Corinthians",
        "1 cor": "1 Corinthians",
        "1cor": "1 Corinthians",
        "2 corinthians": "2 Corinthians",
        "2corinthians": "2 Corinthians",
        "2 cor": "2 Corinthians",
        "2cor": "2 Corinthians",
        "galatians": "Galatians",
        "gal": "Galatians",
        "ephesians": "Ephesians",
        "eph": "Ephesians",
        "philippians": "Philippians",
        "phil": "Philippians",
        "colossians": "Colossians",
        "col": "Colossians",
        "1 thessalonians": "1 Thessalonians",
        "1thessalonians": "1 Thessalonians",
        "1 thess": "1 Thessalonians",
        "1thess": "1 Thessalonians",
        "2 thessalonians": "2 Thessalonians",
        "2thessalonians": "2 Thessalonians",
        "2 thess": "2 Thessalonians",
        "2thess": "2 Thessalonians",
        "1 timothy": "1 Timothy",
        "1timothy": "1 Timothy",
        "1 tim": "1 Timothy",
        "1tim": "1 Timothy",
        "2 timothy": "2 Timothy",
        "2timothy": "2 Timothy",
        "2 tim": "2 Timothy",
        "2tim": "2 Timothy",
        "titus": "Titus",
        "philemon": "Philemon",
        "phlm": "Philemon",
        "hebrews": "Hebrews",
        "heb": "Hebrews",
        "james": "James",
        "jas": "James",
        "1 peter": "1 Peter",
        "1peter": "1 Peter",
        "1 pet": "1 Peter",
        "1pet": "1 Peter",
        "2 peter": "2 Peter",
        "2peter": "2 Peter",
        "2 pet": "2 Peter",
        "2pet": "2 Peter",
        "1 john": "1 John",
        "1john": "1 John",
        "1 jn": "1 John",
        "2 john": "2 John",
        "2john": "2 John",
        "2 jn": "2 John",
        "3 john": "3 John",
        "3john": "3 John",
        "3 jn": "3 John",
        "jude": "Jude",
        "revelation": "Revelation",
        "rev": "Revelation"
    ]

    /// Canonical book order for sorting
    static let bookOrder: [String] = [
        "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
        "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
        "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
        "Ezra", "Nehemiah", "Esther", "Job", "Psalms",
        "Proverbs", "Ecclesiastes", "Song of Solomon",
        "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
        "Hosea", "Joel", "Amos", "Obadiah", "Jonah",
        "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
        "Zechariah", "Malachi",
        "Matthew", "Mark", "Luke", "John", "Acts",
        "Romans", "1 Corinthians", "2 Corinthians", "Galatians",
        "Ephesians", "Philippians", "Colossians",
        "1 Thessalonians", "2 Thessalonians",
        "1 Timothy", "2 Timothy", "Titus", "Philemon",
        "Hebrews", "James", "1 Peter", "2 Peter",
        "1 John", "2 John", "3 John", "Jude", "Revelation"
    ]

    // MARK: - Parsing

    /// Extract all scripture book references from text
    /// Returns normalized book names in order of appearance
    static func extractBooks(from text: String) -> [String] {
        var foundBooks: [String] = []
        let lowercased = text.lowercased()

        // Try to match book names (longest first to avoid partial matches)
        let sortedKeys = bookNames.keys.sorted { $0.count > $1.count }

        for key in sortedKeys {
            if lowercased.contains(key) {
                if let normalizedName = bookNames[key], !foundBooks.contains(normalizedName) {
                    foundBooks.append(normalizedName)
                }
            }
        }

        // Sort by canonical order
        return foundBooks.sorted { book1, book2 in
            let index1 = bookOrder.firstIndex(of: book1) ?? Int.max
            let index2 = bookOrder.firstIndex(of: book2) ?? Int.max
            return index1 < index2
        }
    }

    /// Extract the primary (first) scripture book from text
    static func extractPrimaryBook(from text: String) -> String? {
        extractBooks(from: text).first
    }

    /// Check if text contains a scripture reference
    static func containsScriptureReference(_ text: String) -> Bool {
        !extractBooks(from: text).isEmpty
    }

    /// Parse a full scripture reference like "John 3:16" or "Romans 8:28-30"
    static func parseReference(_ text: String) -> ScriptureReference? {
        guard let book = extractPrimaryBook(from: text) else {
            return nil
        }

        // Try to extract chapter and verse
        // Pattern: Book Chapter:Verse or Book Chapter:Verse-Verse
        let pattern = #"(\d+)(?::(\d+)(?:-(\d+))?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ScriptureReference(book: book, chapter: nil, verseStart: nil, verseEnd: nil)
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return ScriptureReference(book: book, chapter: nil, verseStart: nil, verseEnd: nil)
        }

        var chapter: Int?
        var verseStart: Int?
        var verseEnd: Int?

        if let chapterRange = Range(match.range(at: 1), in: text) {
            chapter = Int(text[chapterRange])
        }

        if match.numberOfRanges > 2, let verseRange = Range(match.range(at: 2), in: text) {
            verseStart = Int(text[verseRange])
        }

        if match.numberOfRanges > 3, let endRange = Range(match.range(at: 3), in: text) {
            verseEnd = Int(text[endRange])
        }

        return ScriptureReference(
            book: book,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
}

// MARK: - Scripture Reference

struct ScriptureReference: Equatable, Hashable {
    let book: String
    let chapter: Int?
    let verseStart: Int?
    let verseEnd: Int?

    var displayString: String {
        var result = book
        if let chapter = chapter {
            result += " \(chapter)"
            if let verseStart = verseStart {
                result += ":\(verseStart)"
                if let verseEnd = verseEnd {
                    result += "-\(verseEnd)"
                }
            }
        }
        return result
    }
}

// MARK: - Sermon Extension

extension Sermon {
    /// Extract the primary scripture book from this sermon
    /// Checks title first, then study guide data if available
    var primaryScriptureBook: String? {
        // First try the title
        if let book = ScriptureReferenceParser.extractPrimaryBook(from: title) {
            return book
        }

        // Could extend to check study guide primaryScripture field
        // For now, title-based extraction is sufficient
        return nil
    }

    /// All scripture books referenced in this sermon
    var scriptureBooks: [String] {
        ScriptureReferenceParser.extractBooks(from: title)
    }
}
