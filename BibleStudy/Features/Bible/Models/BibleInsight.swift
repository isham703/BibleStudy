import Foundation
import GRDB

// MARK: - Bible Insight
// Production model for pre-generated marginalia insights
// Designed for read-only bundled SQLite access

struct BibleInsight: Identifiable, Hashable, Sendable {
    let id: String                      // Format: "43_1_1_connection_0"
    let bookId: Int                     // 43 for John (matches Verse.bookId)
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int

    // Deterministic anchoring
    let segmentText: String             // Display text (extracted from locator)
    let segmentStartChar: Int           // 0-based start index in verse text
    let segmentEndChar: Int             // Exclusive end index

    // Content
    let insightType: BibleInsightType   // connection/greek/theology/question
    let title: String
    let content: String
    let icon: String                    // SF Symbol name
    let sources: [InsightSource]

    // Versioning
    let contentVersion: Int
    let promptVersion: String
    let modelVersion: String
    let createdAt: Date

    // Quality
    let qualityTier: QualityTier
    let isInterpretive: Bool            // True if theology without hard source

    // MARK: - Computed Properties

    var verseReference: String {
        guard let book = Book.find(byId: bookId) else { return "\(bookId):\(chapter):\(verseStart)" }
        if verseStart == verseEnd {
            return "\(book.name) \(chapter):\(verseStart)"
        }
        return "\(book.name) \(chapter):\(verseStart)-\(verseEnd)"
    }

    /// Convert to legacy MarginaliaInsight for view compatibility
    func toMarginaliaInsight() -> MarginaliaInsight {
        MarginaliaInsight(
            phrase: segmentText,
            type: insightType,
            title: title,
            content: content,
            icon: icon
        )
    }
}

// MARK: - Quality Tier

enum QualityTier: String, Codable, Sendable {
    case standard   // Default tier
    case reviewed   // Human-reviewed and approved
    case flagged    // Marked for review/improvement
}

// MARK: - Insight Source

/// References and citations for an insight
struct InsightSource: Codable, Hashable, Sendable, Identifiable {
    let type: SourceType
    let reference: String               // e.g., "Genesis 1:1" or "Strong's G3056"
    let description: String?            // Optional explanation

    /// Identifiable conformance - reference is unique per insight
    var id: String { "\(type.rawValue)_\(reference)" }

    enum SourceType: String, Codable, Sendable {
        case crossReference             // Bible verse reference
        case strongs                    // Strong's concordance
        case commentary                 // Published commentary
        case lexicon                    // Greek/Hebrew lexicon

        /// Display label for UI
        var label: String {
            switch self {
            case .crossReference: return "Cross-Reference"
            case .strongs: return "Strong's"
            case .commentary: return "Commentary"
            case .lexicon: return "Lexicon"
            }
        }
    }
}

// MARK: - GRDB Support

extension BibleInsight: FetchableRecord, PersistableRecord {
    // Note: Table name stays as commentary_insights (database-level)
    nonisolated static var databaseTableName: String { "commentary_insights" }

    enum Columns: String, ColumnExpression {
        case id
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case segmentText = "segment_text"
        case segmentStartChar = "segment_start_char"
        case segmentEndChar = "segment_end_char"
        case insightType = "insight_type"
        case title
        case content
        case icon
        case sources
        case contentVersion = "content_version"
        case promptVersion = "prompt_version"
        case modelVersion = "model_version"
        case createdAt = "created_at"
        case qualityTier = "quality_tier"
        case isInterpretive = "is_interpretive"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verseStart = row[Columns.verseStart]
        verseEnd = row[Columns.verseEnd]
        segmentText = row[Columns.segmentText]
        segmentStartChar = row[Columns.segmentStartChar]
        segmentEndChar = row[Columns.segmentEndChar]

        // Parse insight type from string
        let typeString: String = row[Columns.insightType]
        insightType = BibleInsightType(rawValue: typeString) ?? .connection

        title = row[Columns.title]
        content = row[Columns.content]
        icon = row[Columns.icon]

        // Parse sources from JSON
        let sourcesJSON: String? = row[Columns.sources]
        if let json = sourcesJSON,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([InsightSource].self, from: data) {
            sources = decoded
        } else {
            sources = []
        }

        contentVersion = row[Columns.contentVersion]
        promptVersion = row[Columns.promptVersion]
        modelVersion = row[Columns.modelVersion]

        // Parse date from ISO 8601 string
        let dateString: String = row[Columns.createdAt]
        createdAt = ISO8601DateFormatter().date(from: dateString) ?? Date()

        // Parse quality tier
        let tierString: String = row[Columns.qualityTier]
        qualityTier = QualityTier(rawValue: tierString) ?? .standard

        isInterpretive = row[Columns.isInterpretive]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verseStart] = verseStart
        container[Columns.verseEnd] = verseEnd
        container[Columns.segmentText] = segmentText
        container[Columns.segmentStartChar] = segmentStartChar
        container[Columns.segmentEndChar] = segmentEndChar
        container[Columns.insightType] = insightType.rawValue
        container[Columns.title] = title
        container[Columns.content] = content
        container[Columns.icon] = icon

        // Encode sources to JSON
        if let data = try? JSONEncoder().encode(sources),
           let json = String(data: data, encoding: .utf8) {
            container[Columns.sources] = json
        } else {
            container[Columns.sources] = "[]"
        }

        container[Columns.contentVersion] = contentVersion
        container[Columns.promptVersion] = promptVersion
        container[Columns.modelVersion] = modelVersion
        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.qualityTier] = qualityTier.rawValue
        container[Columns.isInterpretive] = isInterpretive
    }
}

// MARK: - BibleInsightType Extension for GRDB

extension BibleInsightType: RawRepresentable {
    public nonisolated init?(rawValue: String) {
        switch rawValue {
        case "connection": self = .connection
        case "greek": self = .greek
        case "theology": self = .theology
        case "question": self = .question
        default: return nil
        }
    }

    public nonisolated var rawValue: String {
        switch self {
        case .connection: return "connection"
        case .greek: return "greek"
        case .theology: return "theology"
        case .question: return "question"
        }
    }
}

// MARK: - Verse Segment with Insight

/// Pairs verse text segments with their associated insights for display
struct VerseSegmentWithInsight: Identifiable, Sendable {
    let id: String
    let text: String
    let insight: BibleInsight?

    init(text: String, insight: BibleInsight? = nil) {
        self.id = insight?.id ?? UUID().uuidString
        self.text = text
        self.insight = insight
    }
}
