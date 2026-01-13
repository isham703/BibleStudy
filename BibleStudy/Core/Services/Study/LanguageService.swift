import Foundation
import GRDB

// MARK: - Language Service
// Manages Hebrew and Greek language data

@MainActor
@Observable
final class LanguageService {
    // MARK: - Singleton
    static let shared = LanguageService()

    // MARK: - Dependencies
    private let db = DatabaseStore.shared

    // MARK: - State
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - Fetch Tokens

    /// Get all language tokens for a verse
    func getTokens(bookId: Int, chapter: Int, verse: Int) throws -> [LanguageToken] {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try LanguageToken
                .filter(LanguageToken.Columns.bookId == bookId)
                .filter(LanguageToken.Columns.chapter == chapter)
                .filter(LanguageToken.Columns.verse == verse)
                .order(LanguageToken.Columns.position)
                .fetchAll(db)
        }
    }

    /// Get tokens for a verse range
    func getTokens(for range: VerseRange) throws -> [LanguageToken] {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try LanguageToken
                .filter(LanguageToken.Columns.bookId == range.bookId)
                .filter(LanguageToken.Columns.chapter == range.chapter)
                .filter(LanguageToken.Columns.verse >= range.verseStart)
                .filter(LanguageToken.Columns.verse <= range.verseEnd)
                .order(LanguageToken.Columns.verse)
                .order(LanguageToken.Columns.position)
                .fetchAll(db)
        }
    }

    /// Get all occurrences of a lemma
    func getOccurrences(lemma: String) throws -> [LanguageToken] {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try LanguageToken
                .filter(LanguageToken.Columns.lemma == lemma)
                .order(LanguageToken.Columns.bookId)
                .order(LanguageToken.Columns.chapter)
                .order(LanguageToken.Columns.verse)
                .fetchAll(db)
        }
    }

    // MARK: - Key Terms

    /// Get key terms (important words) from a verse range
    func getKeyTerms(for range: VerseRange) throws -> [LanguageToken] {
        let allTokens = try getTokens(for: range)

        // Filter to important terms (exclude common words)
        return allTokens.filter { token in
            // Include if it has a Strong's number or morphology
            token.strongId != nil || token.morph != nil
        }
    }

    // MARK: - Import Tokens

    /// Import language tokens from bundled JSON
    func importFromBundle(filename: String = "tokens_sample") throws -> Int {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DatabaseError.importFailed("File not found: \(filename).json")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let imports = try decoder.decode([LanguageTokenImport].self, from: data)

        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try dbQueue.write { db in
            for importData in imports {
                var token = importData.toLanguageToken()
                try token.insert(db)
            }
        }

        return imports.count
    }

    // MARK: - Sample Data

    /// Get sample tokens for development
    func getSampleTokens(for range: VerseRange) -> [LanguageToken] {
        // Sample tokens for Genesis 1:1
        if range.bookId == 1 && range.chapter == 1 && range.verseStart == 1 {
            return [
                LanguageToken(
                    bookId: 1, chapter: 1, verse: 1, position: 1,
                    surface: "בְּרֵאשִׁית",
                    lemma: "רֵאשִׁית",
                    morph: "Ncfsa",
                    strongId: "H7225",
                    gloss: "beginning",
                    language: .hebrew
                ),
                LanguageToken(
                    bookId: 1, chapter: 1, verse: 1, position: 2,
                    surface: "בָּרָא",
                    lemma: "בָּרָא",
                    morph: "Vqp3ms",
                    strongId: "H1254",
                    gloss: "created",
                    language: .hebrew
                ),
                LanguageToken(
                    bookId: 1, chapter: 1, verse: 1, position: 3,
                    surface: "אֱלֹהִים",
                    lemma: "אֱלֹהִים",
                    morph: "Ncmpa",
                    strongId: "H430",
                    gloss: "God",
                    language: .hebrew
                ),
                LanguageToken(
                    bookId: 1, chapter: 1, verse: 1, position: 4,
                    surface: "הַשָּׁמַיִם",
                    lemma: "שָׁמַיִם",
                    morph: "Ncmpa",
                    strongId: "H8064",
                    gloss: "the heavens",
                    language: .hebrew
                ),
                LanguageToken(
                    bookId: 1, chapter: 1, verse: 1, position: 5,
                    surface: "הָאָרֶץ",
                    lemma: "אֶרֶץ",
                    morph: "Ncfsa",
                    strongId: "H776",
                    gloss: "the earth",
                    language: .hebrew
                )
            ]
        }

        // Sample tokens for John 1:1
        if range.bookId == 43 && range.chapter == 1 && range.verseStart == 1 {
            return [
                LanguageToken(
                    bookId: 43, chapter: 1, verse: 1, position: 1,
                    surface: "ἐν",
                    lemma: "ἐν",
                    morph: "P",
                    strongId: "G1722",
                    gloss: "in",
                    language: .greek
                ),
                LanguageToken(
                    bookId: 43, chapter: 1, verse: 1, position: 2,
                    surface: "ἀρχῇ",
                    lemma: "ἀρχή",
                    morph: "N-DSF",
                    strongId: "G746",
                    gloss: "beginning",
                    language: .greek
                ),
                LanguageToken(
                    bookId: 43, chapter: 1, verse: 1, position: 3,
                    surface: "λόγος",
                    lemma: "λόγος",
                    morph: "N-NSM",
                    strongId: "G3056",
                    gloss: "Word",
                    language: .greek
                ),
                LanguageToken(
                    bookId: 43, chapter: 1, verse: 1, position: 4,
                    surface: "θεός",
                    lemma: "θεός",
                    morph: "N-NSM",
                    strongId: "G2316",
                    gloss: "God",
                    language: .greek
                )
            ]
        }

        return []
    }
}
