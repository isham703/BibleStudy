import Foundation
import GRDB

// MARK: - Language Token
// Represents a Hebrew or Greek word with its morphology and meaning

struct LanguageToken: Hashable, Sendable {
    var rowID: Int64?
    let bookId: Int
    let chapter: Int
    let verse: Int
    let position: Int
    let surface: String      // The word as it appears in the original text
    let lemma: String?       // Dictionary form
    let morph: String?       // Morphological code
    let strongId: String?    // Strong's number (H1234 or G5678)
    let gloss: String?       // English translation
    let language: Language

    // MARK: - Computed Properties
    var displayLemma: String {
        lemma ?? surface
    }

    var morphDescription: String? {
        guard let morph = morph else { return nil }
        return MorphologyParser.parse(morph, language: language)
    }

    var strongsNumber: String? {
        strongId
    }

    var isHebrew: Bool { language == .hebrew }
    var isGreek: Bool { language == .greek }

    init(
        rowID: Int64? = nil,
        bookId: Int,
        chapter: Int,
        verse: Int,
        position: Int,
        surface: String,
        lemma: String? = nil,
        morph: String? = nil,
        strongId: String? = nil,
        gloss: String? = nil,
        language: Language
    ) {
        self.rowID = rowID
        self.bookId = bookId
        self.chapter = chapter
        self.verse = verse
        self.position = position
        self.surface = surface
        self.lemma = lemma
        self.morph = morph
        self.strongId = strongId
        self.gloss = gloss
        self.language = language
    }
}

// MARK: - Language
enum Language: String, Codable, Sendable {
    case hebrew
    case greek

    var displayName: String {
        switch self {
        case .hebrew: return "Hebrew"
        case .greek: return "Greek"
        }
    }
}

// MARK: - Identifiable
extension LanguageToken: Identifiable {
    var id: Int64 { rowID ?? 0 }
}

// MARK: - GRDB Support
extension LanguageToken: FetchableRecord, MutablePersistableRecord {
    nonisolated static var databaseTableName: String { "language_tokens" }

    enum Columns: String, ColumnExpression {
        case rowID = "id"
        case bookId = "book_id"
        case chapter
        case verse
        case position
        case surface
        case lemma
        case morph
        case strongId = "strong_id"
        case gloss
        case language
    }

    nonisolated init(row: Row) {
        rowID = row[Columns.rowID]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verse = row[Columns.verse]
        position = row[Columns.position]
        surface = row[Columns.surface]
        lemma = row[Columns.lemma]
        morph = row[Columns.morph]
        strongId = row[Columns.strongId]
        gloss = row[Columns.gloss]
        language = Language(rawValue: row[Columns.language]) ?? .hebrew
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.rowID] = rowID
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verse] = verse
        container[Columns.position] = position
        container[Columns.surface] = surface
        container[Columns.lemma] = lemma
        container[Columns.morph] = morph
        container[Columns.strongId] = strongId
        container[Columns.gloss] = gloss
        container[Columns.language] = language.rawValue
    }

    nonisolated mutating func didInsert(_ inserted: InsertionSuccess) {
        rowID = inserted.rowID
    }
}

// MARK: - Morphology Parser
enum MorphologyParser {
    static func parse(_ code: String, language: Language) -> String {
        // Simplified morphology parsing
        // In production, this would be a comprehensive parser
        switch language {
        case .hebrew:
            return parseHebrewMorph(code)
        case .greek:
            return parseGreekMorph(code)
        }
    }

    private static func parseHebrewMorph(_ code: String) -> String {
        var parts: [String] = []

        // Parse common Hebrew morphology codes
        if code.contains("V") { parts.append("Verb") }
        if code.contains("N") { parts.append("Noun") }
        if code.contains("A") { parts.append("Adjective") }
        if code.contains("P") { parts.append("Preposition") }
        if code.contains("C") { parts.append("Conjunction") }

        // Person
        if code.contains("1") { parts.append("1st person") }
        if code.contains("2") { parts.append("2nd person") }
        if code.contains("3") { parts.append("3rd person") }

        // Number
        if code.contains("s") { parts.append("singular") }
        if code.contains("p") { parts.append("plural") }

        // Gender
        if code.contains("m") { parts.append("masculine") }
        if code.contains("f") { parts.append("feminine") }

        return parts.isEmpty ? code : parts.joined(separator: ", ")
    }

    private static func parseGreekMorph(_ code: String) -> String {
        var parts: [String] = []

        // Parse common Greek morphology codes
        if code.contains("V") { parts.append("Verb") }
        if code.contains("N") { parts.append("Noun") }
        if code.contains("A") { parts.append("Adjective") }
        if code.contains("P") { parts.append("Preposition") }
        if code.contains("C") { parts.append("Conjunction") }
        if code.contains("D") { parts.append("Adverb") }

        // Tense
        if code.contains("P") { parts.append("Present") }
        if code.contains("I") { parts.append("Imperfect") }
        if code.contains("F") { parts.append("Future") }
        if code.contains("A") { parts.append("Aorist") }
        if code.contains("R") { parts.append("Perfect") }

        // Voice
        if code.contains("A") { parts.append("Active") }
        if code.contains("M") { parts.append("Middle") }
        if code.contains("P") { parts.append("Passive") }

        // Case
        if code.contains("N") { parts.append("Nominative") }
        if code.contains("G") { parts.append("Genitive") }
        if code.contains("D") { parts.append("Dative") }
        if code.contains("A") { parts.append("Accusative") }

        return parts.isEmpty ? code : parts.joined(separator: ", ")
    }
}

// MARK: - Token with Explanation
struct TokenWithExplanation: Identifiable {
    let token: LanguageToken
    var explanation: String?
    var isLoadingExplanation: Bool = false

    var id: Int64 { token.id }
}

// MARK: - JSON Import DTO
struct LanguageTokenImport: Codable {
    let id: Int64?
    let bookId: Int
    let chapter: Int
    let verse: Int
    let position: Int
    let surface: String
    let lemma: String?
    let morph: String?
    let strongId: String?
    let gloss: String?
    let language: String

    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case chapter
        case verse
        case position
        case surface
        case lemma
        case morph
        case strongId = "strong_id"
        case gloss
        case language
    }

    func toLanguageToken() -> LanguageToken {
        LanguageToken(
            rowID: id,
            bookId: bookId,
            chapter: chapter,
            verse: verse,
            position: position,
            surface: surface,
            lemma: lemma,
            morph: morph,
            strongId: strongId,
            gloss: gloss,
            language: Language(rawValue: language) ?? .hebrew
        )
    }
}
