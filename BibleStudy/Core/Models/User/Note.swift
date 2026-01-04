import Foundation
import GRDB

// MARK: - Note Template
// Predefined templates for different types of notes

enum NoteTemplate: String, CaseIterable, Codable, Sendable {
    case freeform
    case observation
    case application
    case questions
    case exegesis
    case prayer

    var displayName: String {
        switch self {
        case .freeform: return "Free-form"
        case .observation: return "Observation"
        case .application: return "Application"
        case .questions: return "Questions"
        case .exegesis: return "Exegesis"
        case .prayer: return "Prayer"
        }
    }

    var icon: String {
        switch self {
        case .freeform: return "doc.text"
        case .observation: return "eye"
        case .application: return "hand.point.right"
        case .questions: return "questionmark.circle"
        case .exegesis: return "text.book.closed"
        case .prayer: return "hands.sparkles"
        }
    }

    var templateContent: String {
        switch self {
        case .freeform:
            return ""
        case .observation:
            return """
            ## What I Notice

            -

            ## Key Words/Phrases

            -

            ## Context Clues

            -
            """
        case .application:
            return """
            ## What This Means



            ## How This Applies to Me



            ## Action Steps

            - [ ]
            """
        case .questions:
            return """
            ## Questions About This Passage

            1.

            ## Questions This Passage Raises

            1.

            ## Questions for Further Study

            1.
            """
        case .exegesis:
            return """
            ## Historical Context



            ## Literary Context



            ## Key Terms (Original Language)

            | Term | Meaning |
            |------|---------|
            |      |         |

            ## Cross-References

            -

            ## Interpretation



            ## Application


            """
        case .prayer:
            return """
            ## Praise



            ## Confession



            ## Thanksgiving



            ## Supplication


            """
        }
    }
}

// MARK: - Note
// User-created note attached to Bible verses

struct Note: Identifiable, Hashable, Sendable {
    /// Maximum allowed character count for note content
    /// Protects against abuse while allowing ~25 pages of text
    static let maxContentLength = 50000

    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    var content: String
    var template: NoteTemplate
    var linkedNoteIds: [UUID]
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

    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }

    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasLinks: Bool {
        !linkedNoteIds.isEmpty
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        content: String,
        template: NoteTemplate = .freeform,
        linkedNoteIds: [UUID] = [],
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
        self.content = content
        self.template = template
        self.linkedNoteIds = linkedNoteIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
    }

    init(userId: UUID, range: VerseRange, content: String, template: NoteTemplate = .freeform) {
        self.init(
            userId: userId,
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseStart,
            verseEnd: range.verseEnd,
            content: content,
            template: template,
            linkedNoteIds: [],
            needsSync: true
        )
    }

    mutating func updateContent(_ newContent: String) {
        content = newContent
        updatedAt = Date()
        needsSync = true
    }

    mutating func addLink(to noteId: UUID) {
        if !linkedNoteIds.contains(noteId) && noteId != id {
            linkedNoteIds.append(noteId)
            updatedAt = Date()
            needsSync = true
        }
    }

    mutating func removeLink(to noteId: UUID) {
        linkedNoteIds.removeAll { $0 == noteId }
        updatedAt = Date()
        needsSync = true
    }
}

// MARK: - GRDB Support
extension Note: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "notes_cache" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case content
        case template
        case linkedNoteIds = "linked_note_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verseStart = row[Columns.verseStart]
        verseEnd = row[Columns.verseEnd]
        content = row[Columns.content]
        // Handle legacy notes without template field
        if let templateString: String = row[Columns.template] {
            template = NoteTemplate(rawValue: templateString) ?? .freeform
        } else {
            template = .freeform
        }
        // Parse linked note IDs from JSON
        if let jsonString: String = row[Columns.linkedNoteIds],
           let data = jsonString.data(using: .utf8),
           let ids = try? JSONDecoder().decode([UUID].self, from: data) {
            linkedNoteIds = ids
        } else {
            linkedNoteIds = []
        }
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verseStart] = verseStart
        container[Columns.verseEnd] = verseEnd
        container[Columns.content] = content
        container[Columns.template] = template.rawValue
        // Encode linked note IDs as JSON
        if let data = try? JSONEncoder().encode(linkedNoteIds),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.linkedNoteIds] = jsonString
        } else {
            container[Columns.linkedNoteIds] = "[]"
        }
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - Conversion from DTO
extension Note {
    nonisolated init(from dto: NoteDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.bookId = dto.bookId
        self.chapter = dto.chapter
        self.verseStart = dto.verseStart
        self.verseEnd = dto.verseEnd
        self.content = dto.content
        self.template = NoteTemplate(rawValue: dto.template ?? "freeform") ?? .freeform
        self.linkedNoteIds = dto.linkedNoteIds ?? []
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = nil
        self.needsSync = false
    }

    func toDTO() -> NoteDTO {
        NoteDTO(
            id: id,
            userId: userId,
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            content: content,
            template: template.rawValue,
            linkedNoteIds: linkedNoteIds,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
