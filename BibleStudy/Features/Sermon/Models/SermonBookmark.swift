import Foundation
import GRDB

// MARK: - Bookmark Label
enum BookmarkLabel: String, Codable, Sendable, CaseIterable {
    case keyPoint = "key_point"
    case question
    case highlight
    case note

    var displayName: String {
        switch self {
        case .keyPoint: return "Key Point"
        case .question: return "Question"
        case .highlight: return "Highlight"
        case .note: return "Note"
        }
    }

    var icon: String {
        switch self {
        case .keyPoint: return "star.fill"
        case .question: return "questionmark.circle"
        case .highlight: return "highlighter"
        case .note: return "note.text"
        }
    }

    var color: String {
        switch self {
        case .keyPoint: return "yellow"
        case .question: return "blue"
        case .highlight: return "orange"
        case .note: return "gray"
        }
    }
}

// MARK: - Sermon Bookmark
// User annotation at a specific timestamp in a sermon
struct SermonBookmark: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let sermonId: UUID
    var timestampSeconds: Double
    var note: String?
    var label: BookmarkLabel?
    var verseReference: VerseReferenceData?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var needsSync: Bool

    // MARK: - Verse Reference Data
    // Note: nonisolated to prevent MainActor inference on Codable conformance
    nonisolated struct VerseReferenceData: Codable, Hashable, Sendable {
        let bookId: Int
        let chapter: Int
        let verseStart: Int
        let verseEnd: Int?
    }

    // MARK: - Computed Properties

    var formattedTimestamp: String {
        let mins = Int(timestampSeconds) / 60
        let secs = Int(timestampSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var displayLabel: String {
        label?.displayName ?? "Bookmark"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        sermonId: UUID,
        timestampSeconds: Double,
        note: String? = nil,
        label: BookmarkLabel? = nil,
        verseReference: VerseReferenceData? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.sermonId = sermonId
        self.timestampSeconds = timestampSeconds
        self.note = note
        self.label = label
        self.verseReference = verseReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
    }

    // MARK: - Mutations

    mutating func markDeleted() {
        deletedAt = Date()
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateNote(_ newNote: String?) {
        note = newNote
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateLabel(_ newLabel: BookmarkLabel?) {
        label = newLabel
        updatedAt = Date()
        needsSync = true
    }
}

// MARK: - GRDB Support
// Note: nonisolated to prevent MainActor inference from -default-isolation=MainActor
nonisolated extension SermonBookmark: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_bookmarks" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case sermonId = "sermon_id"
        case timestampSeconds = "timestamp_seconds"
        case note
        case label
        case verseReference = "verse_reference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        sermonId = row[Columns.sermonId]
        timestampSeconds = row[Columns.timestampSeconds]
        note = row[Columns.note]

        if let labelString: String = row[Columns.label] {
            label = BookmarkLabel(rawValue: labelString)
        } else {
            label = nil
        }

        if let refString: String = row[Columns.verseReference],
           let data = refString.data(using: .utf8) {
            verseReference = try? JSONDecoder().decode(VerseReferenceData.self, from: data)
        } else {
            verseReference = nil
        }

        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.sermonId] = sermonId
        container[Columns.timestampSeconds] = timestampSeconds
        container[Columns.note] = note
        container[Columns.label] = label?.rawValue

        if let ref = verseReference,
           let data = try? JSONEncoder().encode(ref),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.verseReference] = jsonString
        } else {
            container[Columns.verseReference] = nil
        }

        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase Sync
struct SermonBookmarkDTO: Codable {
    let id: UUID
    let userId: UUID
    let sermonId: UUID
    let timestampSeconds: Double
    let note: String?
    let label: String?
    let verseReference: SermonBookmark.VerseReferenceData?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sermonId = "sermon_id"
        case timestampSeconds = "timestamp_seconds"
        case note
        case label
        case verseReference = "verse_reference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Conversion
extension SermonBookmark {
    init(from dto: SermonBookmarkDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.sermonId = dto.sermonId
        self.timestampSeconds = dto.timestampSeconds
        self.note = dto.note
        self.label = dto.label.flatMap { BookmarkLabel(rawValue: $0) }
        self.verseReference = dto.verseReference
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = dto.deletedAt
        self.needsSync = false
    }

    func toDTO() -> SermonBookmarkDTO {
        SermonBookmarkDTO(
            id: id,
            userId: userId,
            sermonId: sermonId,
            timestampSeconds: timestampSeconds,
            note: note,
            label: label?.rawValue,
            verseReference: verseReference,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
