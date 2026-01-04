import Foundation
import GRDB
import Auth

// MARK: - Study Collection Service
// Manages user study collections with offline-first sync

@MainActor
@Observable
final class StudyCollectionService {
    // MARK: - Singleton
    static let shared = StudyCollectionService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseManager.shared

    var collections: [StudyCollection] = []
    var pinnedCollections: [StudyCollection] = []
    var isLoading: Bool = false
    var error: Error?

    // Statistics
    var totalCollections: Int { collections.count }
    var totalItems: Int { collections.reduce(0) { $0 + $1.itemCount } }

    // MARK: - Initialization
    private init() {}

    // MARK: - Load Collections

    func loadCollections() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await loadFromCache(userId: userId)
            updatePinnedCollections()
        } catch {
            self.error = error
        }
    }

    private nonisolated func fetchCollectionsFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [StudyCollection] {
        return try dbQueue.read { db in
            try StudyCollection
                .filter(StudyCollection.Columns.userId == userId.uuidString)
                .filter(StudyCollection.Columns.deletedAt == nil)
                .order(StudyCollection.Columns.isPinned.desc)
                .order(StudyCollection.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    private func loadFromCache(userId: UUID) async throws {
        guard let dbQueue = db.dbQueue else { return }
        collections = try fetchCollectionsFromCache(userId: userId, dbQueue: dbQueue)
    }

    private func updatePinnedCollections() {
        pinnedCollections = collections.filter { $0.isPinned }
    }

    // MARK: - Nonisolated DB Helpers

    private nonisolated func saveCollectionToCache(_ collection: StudyCollection, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try collection.save(db)
        }
    }

    private nonisolated func updateCollectionInCache(_ collection: StudyCollection, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try collection.update(db)
        }
    }

    // MARK: - Create Collection

    func createCollection(
        name: String,
        description: String = "",
        type: CollectionType = .personal,
        icon: String? = nil,
        color: String = "AccentGold"
    ) async throws -> StudyCollection {
        guard let userId = supabase.currentUser?.id else {
            throw CollectionError.notAuthenticated
        }

        let collection = StudyCollection(
            userId: userId,
            name: name,
            description: description,
            type: type,
            icon: icon,
            color: color,
            needsSync: true
        )

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveCollectionToCache(collection, dbQueue: dbQueue)

        // Update local state
        collections.insert(collection, at: 0)
        updatePinnedCollections()

        return collection
    }

    // MARK: - Update Collection

    func updateCollection(_ collection: StudyCollection) async throws {
        var updated = collection
        updated.updatedAt = Date()
        updated.needsSync = true

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try updateCollectionInCache(updated, dbQueue: dbQueue)

        // Update local state
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = updated
        }
        updatePinnedCollections()
    }

    func renameCollection(_ collection: StudyCollection, name: String) async throws {
        var updated = collection
        updated.name = name
        try await updateCollection(updated)
    }

    func setCollectionDescription(_ collection: StudyCollection, description: String) async throws {
        var updated = collection
        updated.description = description
        try await updateCollection(updated)
    }

    // MARK: - Pin/Unpin Collection

    func togglePin(_ collection: StudyCollection) async throws {
        var updated = collection
        updated.isPinned.toggle()
        try await updateCollection(updated)
    }

    func pinCollection(_ collection: StudyCollection) async throws {
        var updated = collection
        updated.isPinned = true
        try await updateCollection(updated)
    }

    func unpinCollection(_ collection: StudyCollection) async throws {
        var updated = collection
        updated.isPinned = false
        try await updateCollection(updated)
    }

    // MARK: - Delete Collection

    func deleteCollection(_ collection: StudyCollection) async throws {
        var deleted = collection
        deleted.deletedAt = Date()
        deleted.updatedAt = Date()
        deleted.needsSync = true

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try updateCollectionInCache(deleted, dbQueue: dbQueue)

        // Update local state
        collections.removeAll { $0.id == collection.id }
        updatePinnedCollections()
    }

    // MARK: - Add Items to Collection

    func addVerseToCollection(_ collection: StudyCollection, range: VerseRange) async throws {
        guard !collection.contains(verseRange: range) else {
            throw CollectionError.itemAlreadyExists
        }

        var updated = collection
        updated.addVerse(range: range)
        try await updateCollection(updated)
    }

    func addHighlightToCollection(_ collection: StudyCollection, highlight: Highlight) async throws {
        guard !collection.contains(highlightId: highlight.id) else {
            throw CollectionError.itemAlreadyExists
        }

        var updated = collection
        updated.addHighlight(highlight)
        try await updateCollection(updated)
    }

    func addNoteToCollection(_ collection: StudyCollection, note: Note) async throws {
        guard !collection.contains(noteId: note.id) else {
            throw CollectionError.itemAlreadyExists
        }

        var updated = collection
        updated.addNote(note)
        try await updateCollection(updated)
    }

    func addItemToCollection(_ collection: StudyCollection, item: CollectionItem) async throws {
        var updated = collection
        updated.addItem(item)
        try await updateCollection(updated)
    }

    // MARK: - Remove Items from Collection

    func removeItemFromCollection(_ collection: StudyCollection, item: CollectionItem) async throws {
        var updated = collection
        updated.removeItem(item)
        try await updateCollection(updated)
    }

    func removeItemFromCollection(_ collection: StudyCollection, at index: Int) async throws {
        var updated = collection
        updated.removeItem(at: index)
        try await updateCollection(updated)
    }

    // MARK: - Reorder Items

    func moveItem(in collection: StudyCollection, from source: IndexSet, to destination: Int) async throws {
        var updated = collection
        updated.moveItem(from: source, to: destination)
        try await updateCollection(updated)
    }

    // MARK: - Find Collections

    func getCollection(by id: UUID) -> StudyCollection? {
        collections.first { $0.id == id }
    }

    func getCollections(containingVerseRange range: VerseRange) -> [StudyCollection] {
        collections.filter { $0.contains(verseRange: range) }
    }

    func getCollections(containingHighlight highlightId: UUID) -> [StudyCollection] {
        collections.filter { $0.contains(highlightId: highlightId) }
    }

    func getCollections(containingNote noteId: UUID) -> [StudyCollection] {
        collections.filter { $0.contains(noteId: noteId) }
    }

    func getCollections(ofType type: CollectionType) -> [StudyCollection] {
        collections.filter { $0.type == type }
    }

    // MARK: - Search Collections

    func searchCollections(query: String) -> [StudyCollection] {
        guard !query.isEmpty else { return collections }
        return collections.filter { collection in
            collection.name.localizedCaseInsensitiveContains(query) ||
            collection.description.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Quick Add

    /// Quick add verse to a collection, creating a new collection if needed
    func quickAddVerse(range: VerseRange, toCollectionNamed name: String) async throws {
        if let existing = collections.first(where: { $0.name == name }) {
            try await addVerseToCollection(existing, range: range)
        } else {
            let collection = try await createCollection(name: name)
            try await addVerseToCollection(collection, range: range)
        }
    }

    /// Get or create a collection by name
    func getOrCreateCollection(name: String, type: CollectionType = .personal) async throws -> StudyCollection {
        if let existing = collections.first(where: { $0.name == name }) {
            return existing
        }
        return try await createCollection(name: name, type: type)
    }
}

// MARK: - Collection Errors

enum CollectionError: Error, LocalizedError {
    case notAuthenticated
    case collectionNotFound
    case itemAlreadyExists
    case invalidOperation

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to use collections."
        case .collectionNotFound:
            return "Collection not found."
        case .itemAlreadyExists:
            return "This item is already in the collection."
        case .invalidOperation:
            return "Invalid operation."
        }
    }
}
