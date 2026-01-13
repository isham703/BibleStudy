import Foundation
import GRDB

// MARK: - Cross Reference Service
// Manages cross-reference data and AI explanations

@MainActor
@Observable
final class CrossRefService {
    // MARK: - Singleton
    static let shared = CrossRefService()

    // MARK: - Dependencies
    private let db = DatabaseStore.shared
    private let bibleService = BibleService.shared

    // MARK: - State
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - Fetch Cross References

    /// Get all cross-references for a verse range
    func getCrossReferences(for range: VerseRange) throws -> [CrossReference] {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try CrossReference
                .filter(CrossReference.Columns.sourceBookId == range.bookId)
                .filter(CrossReference.Columns.sourceChapter == range.chapter)
                .filter(CrossReference.Columns.sourceVerseStart <= range.verseEnd)
                .filter(CrossReference.Columns.sourceVerseEnd >= range.verseStart)
                .order(CrossReference.Columns.weight.desc)
                .fetchAll(db)
        }
    }

    /// Get cross-references with target verse text
    func getCrossReferencesWithText(for range: VerseRange) async throws -> [CrossReferenceWithExplanation] {
        let crossRefs = try getCrossReferences(for: range)

        var results: [CrossReferenceWithExplanation] = []

        for crossRef in crossRefs {
            var result = CrossReferenceWithExplanation(crossRef: crossRef)

            // Fetch target verse text
            if let verses = try? await bibleService.getVerses(range: crossRef.targetRange) {
                result.targetText = verses.map { $0.text }.joined(separator: " ")
            }

            results.append(result)
        }

        return results
    }

    /// Get cross-references that point TO a verse range
    func getIncomingCrossReferences(for range: VerseRange) throws -> [CrossReference] {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try CrossReference
                .filter(CrossReference.Columns.targetBookId == range.bookId)
                .filter(CrossReference.Columns.targetChapter == range.chapter)
                .filter(CrossReference.Columns.targetVerseStart <= range.verseEnd)
                .filter(CrossReference.Columns.targetVerseEnd >= range.verseStart)
                .order(CrossReference.Columns.weight.desc)
                .fetchAll(db)
        }
    }

    // MARK: - Import Cross References

    /// Import cross-references from bundled JSON
    func importFromBundle(filename: String = "crossrefs_sample") throws -> Int {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DatabaseError.importFailed("File not found: \(filename).json")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let imports = try decoder.decode([CrossReferenceImport].self, from: data)

        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try dbQueue.write { db in
            for importData in imports {
                var crossRef = importData.toCrossReference()
                try crossRef.insert(db)
            }
        }

        return imports.count
    }

    // MARK: - Sample Data

    /// Get sample cross-references for development
    func getSampleCrossReferences(for range: VerseRange) -> [CrossReferenceWithExplanation] {
        // Sample cross-references for Genesis 1:1
        if range.bookId == 1 && range.chapter == 1 && range.verseStart == 1 {
            return [
                CrossReferenceWithExplanation(
                    crossRef: CrossReference(
                        source: range,
                        target: VerseRange(bookId: 43, chapter: 1, verseStart: 1, verseEnd: 3),
                        weight: 1.0,
                        sourceInfo: "TSK"
                    ),
                    targetText: "In the beginning was the Word, and the Word was with God, and the Word was God. The same was in the beginning with God. All things were made by him..."
                ),
                CrossReferenceWithExplanation(
                    crossRef: CrossReference(
                        source: range,
                        target: VerseRange(bookId: 19, chapter: 33, verseStart: 6, verseEnd: 6),
                        weight: 0.9,
                        sourceInfo: "TSK"
                    ),
                    targetText: "By the word of the LORD were the heavens made; and all the host of them by the breath of his mouth."
                ),
                CrossReferenceWithExplanation(
                    crossRef: CrossReference(
                        source: range,
                        target: VerseRange(bookId: 58, chapter: 11, verseStart: 3, verseEnd: 3),
                        weight: 0.85,
                        sourceInfo: "TSK"
                    ),
                    targetText: "Through faith we understand that the worlds were framed by the word of God, so that things which are seen were not made of things which do appear."
                )
            ]
        }

        // Sample for John 3:16
        if range.bookId == 43 && range.chapter == 3 && range.verseStart == 16 {
            return [
                CrossReferenceWithExplanation(
                    crossRef: CrossReference(
                        source: range,
                        target: VerseRange(bookId: 45, chapter: 5, verseStart: 8, verseEnd: 8),
                        weight: 1.0,
                        sourceInfo: "TSK"
                    ),
                    targetText: "But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us."
                ),
                CrossReferenceWithExplanation(
                    crossRef: CrossReference(
                        source: range,
                        target: VerseRange(bookId: 62, chapter: 4, verseStart: 9, verseEnd: 10),
                        weight: 0.95,
                        sourceInfo: "TSK"
                    ),
                    targetText: "In this was manifested the love of God toward us, because that God sent his only begotten Son into the world, that we might live through him."
                )
            ]
        }

        return []
    }
}

