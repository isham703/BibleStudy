import Foundation

// MARK: - Parsed Reference
// Result of parsing a Bible reference string

struct ParsedReference: Equatable, Hashable, Sendable {
    let book: Book
    let chapter: Int
    let verseStart: Int?
    let verseEnd: Int?

    var location: BibleLocation {
        BibleLocation(bookId: book.id, chapter: chapter, verse: verseStart)
    }

    var displayText: String {
        if let start = verseStart, let end = verseEnd, start != end {
            return "\(book.name) \(chapter):\(start)-\(end)"
        } else if let verse = verseStart {
            return "\(book.name) \(chapter):\(verse)"
        }
        return "\(book.name) \(chapter)"
    }

    var shortDisplayText: String {
        if let start = verseStart, let end = verseEnd, start != end {
            return "\(book.abbreviation) \(chapter):\(start)-\(end)"
        } else if let verse = verseStart {
            return "\(book.abbreviation) \(chapter):\(verse)"
        }
        return "\(book.abbreviation) \(chapter)"
    }
}

// MARK: - Parse Error

enum ReferenceParseError: LocalizedError, Equatable {
    case emptyInput
    case bookNotFound(String)
    case invalidChapter(book: String, chapter: Int, maxChapter: Int)
    case invalidVerse(Int)
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a reference"
        case .bookNotFound(let name):
            return "Book not found: \"\(name)\""
        case .invalidChapter(let book, let chapter, let maxChapter):
            return "\(book) has only \(maxChapter) chapter\(maxChapter == 1 ? "" : "s"), not \(chapter)"
        case .invalidVerse(let verse):
            return "Invalid verse number: \(verse)"
        case .invalidFormat(let input):
            return "Couldn't parse: \"\(input)\""
        }
    }
}

// MARK: - Reference Parser
// Parses Bible references like "John 3:16", "Gen 1", "Rom 8:28-30"

enum ReferenceParser {
    // MARK: - Main Parse Function

    /// Parse a Bible reference string into a ParsedReference
    /// - Parameter input: The reference string (e.g., "John 3:16", "Gen 1", "1 Cor 13:4-8")
    /// - Returns: A Result with either ParsedReference or ReferenceParseError
    static func parse(_ input: String) -> Result<ParsedReference, ReferenceParseError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.emptyInput)
        }

        // Regex: captures book name (with optional number prefix), chapter, and optional verse range
        // Examples: "John 3:16", "1 Cor 13", "Song of Solomon 2:1-4", "Gen 1"
        let pattern = #"^((?:\d\s*)?[a-zA-Z]+(?:\s+[a-zA-Z]+)*)\s*(\d+)(?::(\d+)(?:\s*[-–—]\s*(\d+))?)?$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return .failure(.invalidFormat(trimmed))
        }

        // Extract book name
        guard let bookRange = Range(match.range(at: 1), in: trimmed) else {
            return .failure(.invalidFormat(trimmed))
        }
        let bookStr = String(trimmed[bookRange]).trimmingCharacters(in: .whitespaces)

        // Extract chapter
        guard let chapterRange = Range(match.range(at: 2), in: trimmed),
              let chapter = Int(trimmed[chapterRange]) else {
            return .failure(.invalidFormat(trimmed))
        }

        // Extract optional verses
        var verseStart: Int?
        var verseEnd: Int?

        if match.range(at: 3).location != NSNotFound,
           let verseStartRange = Range(match.range(at: 3), in: trimmed) {
            verseStart = Int(trimmed[verseStartRange])
        }

        if match.range(at: 4).location != NSNotFound,
           let verseEndRange = Range(match.range(at: 4), in: trimmed) {
            verseEnd = Int(trimmed[verseEndRange])
        }

        // Find the book using fuzzy matching
        guard let book = findBook(bookStr) else {
            return .failure(.bookNotFound(bookStr))
        }

        // Validate chapter
        guard chapter >= 1 && chapter <= book.chapters else {
            return .failure(.invalidChapter(book: book.name, chapter: chapter, maxChapter: book.chapters))
        }

        // Validate verses
        if let start = verseStart, start < 1 {
            return .failure(.invalidVerse(start))
        }
        if let end = verseEnd, end < 1 {
            return .failure(.invalidVerse(end))
        }

        return .success(ParsedReference(
            book: book,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        ))
    }

    // MARK: - Book Lookup with Fuzzy Matching

    /// Find a book by name or abbreviation with fuzzy matching
    private static func findBook(_ input: String) -> Book? {
        let normalized = input.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. Try exact name match
        if let book = Book.find(byName: input) {
            return book
        }

        // 2. Try exact abbreviation match
        if let book = Book.find(byAbbreviation: input) {
            return book
        }

        // 3. Try common aliases
        if let book = commonAliases[normalized] {
            return book
        }

        // 4. Try prefix match on book names
        let prefixMatches = Book.all.filter { book in
            book.name.lowercased().hasPrefix(normalized) ||
            book.abbreviation.lowercased().hasPrefix(normalized)
        }
        if prefixMatches.count == 1 {
            return prefixMatches.first
        }

        // 5. Try removing spaces/periods for numbered books (e.g., "1cor" -> "1 Corinthians")
        let compacted = normalized.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
        if let book = compactedAliases[compacted] {
            return book
        }

        return nil
    }

    // MARK: - Alias Dictionaries

    /// Common informal abbreviations and aliases
    private static let commonAliases: [String: Book] = {
        var aliases: [String: Book] = [:]

        // Genesis aliases
        if let gen = Book.find(byId: 1) {
            aliases["gn"] = gen
            aliases["ge"] = gen
        }

        // Exodus aliases
        if let exod = Book.find(byId: 2) {
            aliases["ex"] = exod
            aliases["exo"] = exod
        }

        // Leviticus aliases
        if let lev = Book.find(byId: 3) {
            aliases["lv"] = lev
            aliases["le"] = lev
        }

        // Numbers aliases
        if let num = Book.find(byId: 4) {
            aliases["nb"] = num
            aliases["nu"] = num
        }

        // Deuteronomy aliases
        if let deut = Book.find(byId: 5) {
            aliases["dt"] = deut
            aliases["de"] = deut
        }

        // Psalms aliases
        if let ps = Book.find(byId: 19) {
            aliases["psalm"] = ps
            aliases["psa"] = ps
            aliases["psm"] = ps
        }

        // Song of Solomon aliases
        if let song = Book.find(byId: 22) {
            aliases["sos"] = song
            aliases["song"] = song
            aliases["canticles"] = song
            aliases["song of songs"] = song
            aliases["songs"] = song
        }

        // Gospel of John aliases
        if let john = Book.find(byId: 43) {
            aliases["jn"] = john
            aliases["jhn"] = john
        }

        // Romans aliases
        if let rom = Book.find(byId: 45) {
            aliases["ro"] = rom
            aliases["rm"] = rom
        }

        // Philippians vs Philemon disambiguation
        if let phil = Book.find(byId: 50) {
            aliases["php"] = phil
            aliases["philippians"] = phil
        }
        if let phlm = Book.find(byId: 57) {
            aliases["phm"] = phlm
            aliases["philemon"] = phlm
            aliases["phile"] = phlm
        }

        // Revelation aliases
        if let rev = Book.find(byId: 66) {
            aliases["rv"] = rev
            aliases["apocalypse"] = rev
            aliases["apoc"] = rev
        }

        return aliases
    }()

    /// Compacted versions for numbered books (no spaces)
    private static let compactedAliases: [String: Book] = {
        var aliases: [String: Book] = [:]

        // Samuel
        if let sam1 = Book.find(byId: 9) {
            aliases["1sam"] = sam1
            aliases["1sa"] = sam1
            aliases["1samuel"] = sam1
        }
        if let sam2 = Book.find(byId: 10) {
            aliases["2sam"] = sam2
            aliases["2sa"] = sam2
            aliases["2samuel"] = sam2
        }

        // Kings
        if let kgs1 = Book.find(byId: 11) {
            aliases["1kgs"] = kgs1
            aliases["1ki"] = kgs1
            aliases["1kings"] = kgs1
        }
        if let kgs2 = Book.find(byId: 12) {
            aliases["2kgs"] = kgs2
            aliases["2ki"] = kgs2
            aliases["2kings"] = kgs2
        }

        // Chronicles
        if let chr1 = Book.find(byId: 13) {
            aliases["1chr"] = chr1
            aliases["1ch"] = chr1
            aliases["1chronicles"] = chr1
        }
        if let chr2 = Book.find(byId: 14) {
            aliases["2chr"] = chr2
            aliases["2ch"] = chr2
            aliases["2chronicles"] = chr2
        }

        // Corinthians
        if let cor1 = Book.find(byId: 46) {
            aliases["1cor"] = cor1
            aliases["1co"] = cor1
            aliases["1corinthians"] = cor1
        }
        if let cor2 = Book.find(byId: 47) {
            aliases["2cor"] = cor2
            aliases["2co"] = cor2
            aliases["2corinthians"] = cor2
        }

        // Thessalonians
        if let thess1 = Book.find(byId: 52) {
            aliases["1thess"] = thess1
            aliases["1th"] = thess1
            aliases["1thessalonians"] = thess1
        }
        if let thess2 = Book.find(byId: 53) {
            aliases["2thess"] = thess2
            aliases["2th"] = thess2
            aliases["2thessalonians"] = thess2
        }

        // Timothy
        if let tim1 = Book.find(byId: 54) {
            aliases["1tim"] = tim1
            aliases["1ti"] = tim1
            aliases["1timothy"] = tim1
        }
        if let tim2 = Book.find(byId: 55) {
            aliases["2tim"] = tim2
            aliases["2ti"] = tim2
            aliases["2timothy"] = tim2
        }

        // Peter
        if let pet1 = Book.find(byId: 60) {
            aliases["1pet"] = pet1
            aliases["1pe"] = pet1
            aliases["1peter"] = pet1
        }
        if let pet2 = Book.find(byId: 61) {
            aliases["2pet"] = pet2
            aliases["2pe"] = pet2
            aliases["2peter"] = pet2
        }

        // John (epistles)
        if let jn1 = Book.find(byId: 62) {
            aliases["1john"] = jn1
            aliases["1jn"] = jn1
            aliases["1jo"] = jn1
        }
        if let jn2 = Book.find(byId: 63) {
            aliases["2john"] = jn2
            aliases["2jn"] = jn2
            aliases["2jo"] = jn2
        }
        if let jn3 = Book.find(byId: 64) {
            aliases["3john"] = jn3
            aliases["3jn"] = jn3
            aliases["3jo"] = jn3
        }

        return aliases
    }()
}

// MARK: - Suggestion Support

extension ReferenceParser {
    /// Provide suggestions based on partial input
    static func suggestions(for input: String, limit: Int = 5) -> [Book] {
        let normalized = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return [] }

        // Split off any trailing numbers (chapter/verse)
        let bookPart = normalized.components(separatedBy: CharacterSet.decimalDigits).first?
            .trimmingCharacters(in: .whitespaces) ?? normalized

        guard !bookPart.isEmpty else { return [] }

        // Find matching books
        let matches = Book.all.filter { book in
            book.name.lowercased().hasPrefix(bookPart) ||
            book.abbreviation.lowercased().hasPrefix(bookPart)
        }

        return Array(matches.prefix(limit))
    }
}
