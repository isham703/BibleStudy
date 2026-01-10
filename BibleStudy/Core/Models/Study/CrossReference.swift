import Foundation
import GRDB

// MARK: - Cross Reference
// Represents a connection between two Bible passages

struct CrossReference: Hashable, Sendable {
    var rowID: Int64?
    let sourceBookId: Int
    let sourceChapter: Int
    let sourceVerseStart: Int
    let sourceVerseEnd: Int
    let targetBookId: Int
    let targetChapter: Int
    let targetVerseStart: Int
    let targetVerseEnd: Int
    let weight: Double
    let source: String?

    // MARK: - Computed Properties
    nonisolated var sourceRange: VerseRange {
        VerseRange(
            bookId: sourceBookId,
            chapter: sourceChapter,
            verseStart: sourceVerseStart,
            verseEnd: sourceVerseEnd
        )
    }

    nonisolated var targetRange: VerseRange {
        VerseRange(
            bookId: targetBookId,
            chapter: targetChapter,
            verseStart: targetVerseStart,
            verseEnd: targetVerseEnd
        )
    }

    nonisolated var targetReference: String {
        targetRange.reference
    }

    nonisolated var targetBook: Book? {
        Book.find(byId: targetBookId)
    }

    init(
        rowID: Int64? = nil,
        sourceBookId: Int,
        sourceChapter: Int,
        sourceVerseStart: Int,
        sourceVerseEnd: Int,
        targetBookId: Int,
        targetChapter: Int,
        targetVerseStart: Int,
        targetVerseEnd: Int,
        weight: Double = 1.0,
        source: String? = nil
    ) {
        self.rowID = rowID
        self.sourceBookId = sourceBookId
        self.sourceChapter = sourceChapter
        self.sourceVerseStart = sourceVerseStart
        self.sourceVerseEnd = sourceVerseEnd
        self.targetBookId = targetBookId
        self.targetChapter = targetChapter
        self.targetVerseStart = targetVerseStart
        self.targetVerseEnd = targetVerseEnd
        self.weight = weight
        self.source = source
    }

    init(source: VerseRange, target: VerseRange, weight: Double = 1.0, sourceInfo: String? = nil) {
        self.init(
            sourceBookId: source.bookId,
            sourceChapter: source.chapter,
            sourceVerseStart: source.verseStart,
            sourceVerseEnd: source.verseEnd,
            targetBookId: target.bookId,
            targetChapter: target.chapter,
            targetVerseStart: target.verseStart,
            targetVerseEnd: target.verseEnd,
            weight: weight,
            source: sourceInfo
        )
    }
}

// MARK: - Identifiable
extension CrossReference: Identifiable {
    var id: Int64 { rowID ?? 0 }
}

// MARK: - GRDB Support
extension CrossReference: FetchableRecord, MutablePersistableRecord {
    nonisolated static var databaseTableName: String { "cross_references" }

    enum Columns: String, ColumnExpression {
        case rowID = "id"
        case sourceBookId = "source_book_id"
        case sourceChapter = "source_chapter"
        case sourceVerseStart = "source_verse_start"
        case sourceVerseEnd = "source_verse_end"
        case targetBookId = "target_book_id"
        case targetChapter = "target_chapter"
        case targetVerseStart = "target_verse_start"
        case targetVerseEnd = "target_verse_end"
        case weight
        case source
    }

    nonisolated init(row: Row) {
        rowID = row[Columns.rowID]
        sourceBookId = row[Columns.sourceBookId]
        sourceChapter = row[Columns.sourceChapter]
        sourceVerseStart = row[Columns.sourceVerseStart]
        sourceVerseEnd = row[Columns.sourceVerseEnd]
        targetBookId = row[Columns.targetBookId]
        targetChapter = row[Columns.targetChapter]
        targetVerseStart = row[Columns.targetVerseStart]
        targetVerseEnd = row[Columns.targetVerseEnd]
        weight = row[Columns.weight]
        source = row[Columns.source]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.rowID] = rowID
        container[Columns.sourceBookId] = sourceBookId
        container[Columns.sourceChapter] = sourceChapter
        container[Columns.sourceVerseStart] = sourceVerseStart
        container[Columns.sourceVerseEnd] = sourceVerseEnd
        container[Columns.targetBookId] = targetBookId
        container[Columns.targetChapter] = targetChapter
        container[Columns.targetVerseStart] = targetVerseStart
        container[Columns.targetVerseEnd] = targetVerseEnd
        container[Columns.weight] = weight
        container[Columns.source] = source
    }

    nonisolated mutating func didInsert(_ inserted: InsertionSuccess) {
        rowID = inserted.rowID
    }
}

// MARK: - JSON Import DTO
struct CrossReferenceImport: Codable {
    let id: Int64?
    let sourceBookId: Int
    let sourceChapter: Int
    let sourceVerseStart: Int
    let sourceVerseEnd: Int
    let targetBookId: Int
    let targetChapter: Int
    let targetVerseStart: Int
    let targetVerseEnd: Int
    let weight: Double?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceBookId = "source_book_id"
        case sourceChapter = "source_chapter"
        case sourceVerseStart = "source_verse_start"
        case sourceVerseEnd = "source_verse_end"
        case targetBookId = "target_book_id"
        case targetChapter = "target_chapter"
        case targetVerseStart = "target_verse_start"
        case targetVerseEnd = "target_verse_end"
        case weight
        case source
    }

    func toCrossReference() -> CrossReference {
        CrossReference(
            rowID: id,
            sourceBookId: sourceBookId,
            sourceChapter: sourceChapter,
            sourceVerseStart: sourceVerseStart,
            sourceVerseEnd: sourceVerseEnd,
            targetBookId: targetBookId,
            targetChapter: targetChapter,
            targetVerseStart: targetVerseStart,
            targetVerseEnd: targetVerseEnd,
            weight: weight ?? 1.0,
            source: source
        )
    }
}

// MARK: - Cross Reference with AI Explanation
struct CrossReferenceWithExplanation: Identifiable {
    let crossRef: CrossReference
    var targetText: String?
    var explanation: String?
    var isLoadingExplanation: Bool = false

    var id: Int64 { crossRef.id }
    var targetReference: String { crossRef.targetReference }
    var targetRange: VerseRange { crossRef.targetRange }
}
