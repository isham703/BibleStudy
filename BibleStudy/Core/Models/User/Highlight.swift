import Foundation
import GRDB

// MARK: - Highlight Category
// Semantic categories for organizing highlights

enum HighlightCategory: String, CaseIterable, Codable, Sendable {
    case none
    case promise
    case command
    case prophecy
    case character
    case geography
    case doctrine
    case warning
    case praise

    var displayName: String {
        switch self {
        case .none: return "None"
        case .promise: return "Promise"
        case .command: return "Command"
        case .prophecy: return "Prophecy"
        case .character: return "Character"
        case .geography: return "Geography"
        case .doctrine: return "Doctrine"
        case .warning: return "Warning"
        case .praise: return "Praise"
        }
    }

    var icon: String {
        switch self {
        case .none: return "tag"  // SF Symbol
        case .promise: return "streamline-promise"  // Streamline
        case .command: return "streamline-command"  // Streamline
        case .prophecy: return "streamline-prophecy"  // Streamline
        case .character: return "streamline-character"  // Streamline
        case .geography: return "streamline-geography"  // Streamline
        case .doctrine: return "streamline-doctrine"  // Streamline
        case .warning: return "streamline-warning"  // Streamline
        case .praise: return "streamline-praise"  // Streamline
        }
    }

    /// Whether this category uses a Streamline asset (vs SF Symbol)
    var usesStreamlineIcon: Bool {
        switch self {
        case .none:
            return false
        default:
            return true
        }
    }

    var description: String {
        switch self {
        case .none: return "No category"
        case .promise: return "God's promises to His people"
        case .command: return "Instructions and commandments"
        case .prophecy: return "Prophetic statements and fulfillments"
        case .character: return "Notable people in Scripture"
        case .geography: return "Places and locations"
        case .doctrine: return "Theological teachings"
        case .warning: return "Warnings and admonitions"
        case .praise: return "Worship and thanksgiving"
        }
    }

    /// Suggested color for each category
    var suggestedColor: HighlightColor {
        switch self {
        case .none: return .amber
        case .promise: return .green
        case .command: return .blue
        case .prophecy: return .purple
        case .character: return .amber
        case .geography: return .blue
        case .doctrine: return .purple
        case .warning: return .rose
        case .praise: return .green
        }
    }
}

// MARK: - Highlight
// User-created highlight on Bible verses

struct Highlight: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let color: HighlightColor
    var category: HighlightCategory
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // Local-only tracking
    var needsSync: Bool = false

    var range: VerseRange {
        VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
    }

    var reference: String {
        range.reference
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        color: HighlightColor = .amber,
        category: HighlightCategory = .none,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.color = color
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
    }

    init(userId: UUID, range: VerseRange, color: HighlightColor = .amber, category: HighlightCategory = .none) {
        self.init(
            userId: userId,
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseStart,
            verseEnd: range.verseEnd,
            color: color,
            category: category,
            needsSync: true
        )
    }
}

// MARK: - GRDB Support
extension Highlight: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "highlights_cache" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case color
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        // userId stored as string for consistent querying
        if let userIdString: String = row[Columns.userId] {
            userId = UUID(uuidString: userIdString) ?? UUID()
        } else {
            userId = UUID()
        }
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verseStart = row[Columns.verseStart]
        verseEnd = row[Columns.verseEnd]
        color = HighlightColor(rawValue: row[Columns.color]) ?? .amber
        // Handle legacy highlights without category field
        if let categoryString: String = row[Columns.category] {
            category = HighlightCategory(rawValue: categoryString) ?? .none
        } else {
            category = .none
        }
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId.uuidString  // Store as string for consistent querying
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verseStart] = verseStart
        container[Columns.verseEnd] = verseEnd
        container[Columns.color] = color.rawValue
        container[Columns.category] = category.rawValue
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - Conversion from DTO
extension Highlight {
    nonisolated init(from dto: HighlightDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.bookId = dto.bookId
        self.chapter = dto.chapter
        self.verseStart = dto.verseStart
        self.verseEnd = dto.verseEnd
        self.color = HighlightColor(rawValue: dto.color) ?? .amber
        self.category = HighlightCategory(rawValue: dto.category ?? "none") ?? .none
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = nil
        self.needsSync = false
    }

    func toDTO() -> HighlightDTO {
        HighlightDTO(
            id: id,
            userId: userId,
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            color: color.rawValue,
            category: category.rawValue,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
