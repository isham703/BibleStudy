import Foundation
import GRDB

// MARK: - Collection Type
// Predefined collection types for organizing study materials

enum CollectionType: String, CaseIterable, Codable, Sendable {
    case personal
    case sermonPrep
    case bibleStudy
    case memorization
    case topical
    case custom

    var displayName: String {
        switch self {
        case .personal: return "Personal Study"
        case .sermonPrep: return "Sermon Prep"
        case .bibleStudy: return "Bible Study"
        case .memorization: return "Memorization"
        case .topical: return "Topical"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .sermonPrep: return "doc.text.fill"
        case .bibleStudy: return "book.fill"
        case .memorization: return "brain.head.profile"
        case .topical: return "tag.fill"
        case .custom: return "folder.fill"
        }
    }

    var description: String {
        switch self {
        case .personal: return "Personal devotional study"
        case .sermonPrep: return "Sermon or teaching preparation"
        case .bibleStudy: return "Group Bible study materials"
        case .memorization: return "Verses to memorize"
        case .topical: return "Topic-focused collection"
        case .custom: return "Custom collection"
        }
    }
}

// MARK: - Collection Item
// Reference to an item in a collection

struct CollectionItem: Identifiable, Hashable, Codable, Sendable {
    enum ItemType: String, Codable, Sendable {
        case verse
        case highlight
        case note
    }

    let id: UUID
    let type: ItemType
    let referenceId: String // verseId for verses, UUID string for highlights/notes
    let addedAt: Date
    var sortOrder: Int

    // For verse type items
    var bookId: Int?
    var chapter: Int?
    var verseStart: Int?
    var verseEnd: Int?

    init(
        id: UUID = UUID(),
        type: ItemType,
        referenceId: String,
        addedAt: Date = Date(),
        sortOrder: Int = 0,
        bookId: Int? = nil,
        chapter: Int? = nil,
        verseStart: Int? = nil,
        verseEnd: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.referenceId = referenceId
        self.addedAt = addedAt
        self.sortOrder = sortOrder
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
    }

    static func verse(range: VerseRange, sortOrder: Int = 0) -> CollectionItem {
        CollectionItem(
            type: .verse,
            referenceId: range.id,
            sortOrder: sortOrder,
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseStart,
            verseEnd: range.verseEnd
        )
    }

    static func highlight(_ highlight: Highlight, sortOrder: Int = 0) -> CollectionItem {
        CollectionItem(
            type: .highlight,
            referenceId: highlight.id.uuidString,
            sortOrder: sortOrder,
            bookId: highlight.bookId,
            chapter: highlight.chapter,
            verseStart: highlight.verseStart,
            verseEnd: highlight.verseEnd
        )
    }

    static func note(_ note: Note, sortOrder: Int = 0) -> CollectionItem {
        CollectionItem(
            type: .note,
            referenceId: note.id.uuidString,
            sortOrder: sortOrder,
            bookId: note.bookId,
            chapter: note.chapter,
            verseStart: note.verseStart,
            verseEnd: note.verseEnd
        )
    }

    var verseRange: VerseRange? {
        guard let bookId, let chapter, let verseStart, let verseEnd else { return nil }
        return VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
    }

    var reference: String {
        verseRange?.reference ?? referenceId
    }
}

// MARK: - Study Collection
// User-created collection for organizing study materials

struct StudyCollection: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String
    var type: CollectionType
    var icon: String
    var color: String
    var items: [CollectionItem]
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // Local-only tracking
    var needsSync: Bool = false

    var itemCount: Int {
        items.count
    }

    var verseCount: Int {
        items.filter { $0.type == .verse }.count
    }

    var highlightCount: Int {
        items.filter { $0.type == .highlight }.count
    }

    var noteCount: Int {
        items.filter { $0.type == .note }.count
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        description: String = "",
        type: CollectionType = .personal,
        icon: String? = nil,
        color: String = "AccentGold",
        items: [CollectionItem] = [],
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.type = type
        self.icon = icon ?? type.icon
        self.color = color
        self.items = items
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
    }

    // MARK: - Item Management

    mutating func addItem(_ item: CollectionItem) {
        var newItem = item
        newItem.sortOrder = items.count
        items.append(newItem)
        updatedAt = Date()
        needsSync = true
    }

    mutating func addVerse(range: VerseRange) {
        let item = CollectionItem.verse(range: range, sortOrder: items.count)
        items.append(item)
        updatedAt = Date()
        needsSync = true
    }

    mutating func addHighlight(_ highlight: Highlight) {
        let item = CollectionItem.highlight(highlight, sortOrder: items.count)
        items.append(item)
        updatedAt = Date()
        needsSync = true
    }

    mutating func addNote(_ note: Note) {
        let item = CollectionItem.note(note, sortOrder: items.count)
        items.append(item)
        updatedAt = Date()
        needsSync = true
    }

    mutating func removeItem(_ item: CollectionItem) {
        items.removeAll { $0.id == item.id }
        updatedAt = Date()
        needsSync = true
    }

    mutating func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        updatedAt = Date()
        needsSync = true
    }

    mutating func moveItem(from source: IndexSet, to destination: Int) {
        // Manual implementation of move to avoid SwiftUI dependency
        var newItems = items
        let itemsToMove = source.map { newItems[$0] }

        // Remove items from highest to lowest to preserve indices
        for index in source.sorted().reversed() {
            newItems.remove(at: index)
        }

        // Calculate adjusted destination
        let adjustedDestination = source.filter { $0 < destination }.count
        let insertionIndex = destination - adjustedDestination

        // Insert at new position
        for (offset, item) in itemsToMove.enumerated() {
            newItems.insert(item, at: min(insertionIndex + offset, newItems.count))
        }

        items = newItems

        // Update sort orders
        for (index, _) in items.enumerated() {
            items[index].sortOrder = index
        }
        updatedAt = Date()
        needsSync = true
    }

    func contains(verseRange: VerseRange) -> Bool {
        items.contains { item in
            item.type == .verse && item.referenceId == verseRange.id
        }
    }

    func contains(highlightId: UUID) -> Bool {
        items.contains { item in
            item.type == .highlight && item.referenceId == highlightId.uuidString
        }
    }

    func contains(noteId: UUID) -> Bool {
        items.contains { item in
            item.type == .note && item.referenceId == noteId.uuidString
        }
    }
}

// MARK: - GRDB Support
extension StudyCollection: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "study_collections" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case name
        case description
        case type
        case icon
        case color
        case items
        case isPinned = "is_pinned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        name = row[Columns.name]
        description = row[Columns.description] ?? ""
        type = CollectionType(rawValue: row[Columns.type]) ?? .personal
        icon = row[Columns.icon]
        color = row[Columns.color]

        // Decode items from JSON
        if let itemsJson: String = row[Columns.items],
           let itemsData = itemsJson.data(using: .utf8) {
            items = (try? JSONDecoder().decode([CollectionItem].self, from: itemsData)) ?? []
        } else {
            items = []
        }

        isPinned = row[Columns.isPinned]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.name] = name
        container[Columns.description] = description
        container[Columns.type] = type.rawValue
        container[Columns.icon] = icon
        container[Columns.color] = color

        // Encode items to JSON
        if let itemsData = try? JSONEncoder().encode(items),
           let itemsJson = String(data: itemsData, encoding: .utf8) {
            container[Columns.items] = itemsJson
        } else {
            container[Columns.items] = "[]"
        }

        container[Columns.isPinned] = isPinned
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase
struct StudyCollectionDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var type: String
    var icon: String
    var color: String
    var items: [CollectionItem]?
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case type
        case icon
        case color
        case items
        case isPinned = "is_pinned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension StudyCollection {
    nonisolated init(from dto: StudyCollectionDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.name = dto.name
        self.description = dto.description ?? ""
        self.type = CollectionType(rawValue: dto.type) ?? .personal
        self.icon = dto.icon
        self.color = dto.color
        self.items = dto.items ?? []
        self.isPinned = dto.isPinned
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = nil
        self.needsSync = false
    }

    func toDTO() -> StudyCollectionDTO {
        StudyCollectionDTO(
            id: id,
            userId: userId,
            name: name,
            description: description,
            type: type.rawValue,
            icon: icon,
            color: color,
            items: items,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
