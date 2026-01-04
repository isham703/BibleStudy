import SwiftUI

// MARK: - Collection Detail View Model
// Manages state for viewing and editing a collection

@Observable
@MainActor
final class CollectionDetailViewModel {
    // MARK: - Dependencies
    private let collectionService: StudyCollectionService
    private let userContentService: UserContentService

    // MARK: - State
    var collection: StudyCollection
    var isLoading: Bool = false
    var error: Error?
    var isEditing: Bool = false

    // MARK: - Computed Properties
    var items: [CollectionItem] {
        collection.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var verseItems: [CollectionItem] {
        items.filter { $0.type == .verse }
    }

    var highlightItems: [CollectionItem] {
        items.filter { $0.type == .highlight }
    }

    var noteItems: [CollectionItem] {
        items.filter { $0.type == .note }
    }

    var isEmpty: Bool {
        collection.items.isEmpty
    }

    // MARK: - Initialization
    init(
        collection: StudyCollection,
        collectionService: StudyCollectionService? = nil,
        userContentService: UserContentService? = nil
    ) {
        self.collection = collection
        self.collectionService = collectionService ?? StudyCollectionService.shared
        self.userContentService = userContentService ?? UserContentService.shared
    }

    // MARK: - Actions

    func refresh() async {
        // Reload from service in case of updates
        if let updated = collectionService.getCollection(by: collection.id) {
            collection = updated
        }
    }

    func removeItem(_ item: CollectionItem) async {
        do {
            try await collectionService.removeItemFromCollection(collection, item: item)
            if let updated = collectionService.getCollection(by: collection.id) {
                collection = updated
            }
        } catch {
            self.error = error
        }
    }

    func removeItem(at index: Int) async {
        do {
            try await collectionService.removeItemFromCollection(collection, at: index)
            if let updated = collectionService.getCollection(by: collection.id) {
                collection = updated
            }
        } catch {
            self.error = error
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) async {
        do {
            try await collectionService.moveItem(in: collection, from: source, to: destination)
            if let updated = collectionService.getCollection(by: collection.id) {
                collection = updated
            }
        } catch {
            self.error = error
        }
    }

    func renameCollection(name: String) async {
        do {
            try await collectionService.renameCollection(collection, name: name)
            collection.name = name
        } catch {
            self.error = error
        }
    }

    func setDescription(_ description: String) async {
        do {
            try await collectionService.setCollectionDescription(collection, description: description)
            collection.description = description
        } catch {
            self.error = error
        }
    }

    func togglePin() async {
        do {
            try await collectionService.togglePin(collection)
            collection.isPinned.toggle()
        } catch {
            self.error = error
        }
    }

    func deleteCollection() async -> Bool {
        do {
            try await collectionService.deleteCollection(collection)
            return true
        } catch {
            self.error = error
            return false
        }
    }

    // MARK: - Helpers

    func getHighlight(for item: CollectionItem) -> Highlight? {
        guard item.type == .highlight,
              let highlightId = UUID(uuidString: item.referenceId) else { return nil }
        return userContentService.highlights.first { $0.id == highlightId }
    }

    func getNote(for item: CollectionItem) -> Note? {
        guard item.type == .note,
              let noteId = UUID(uuidString: item.referenceId) else { return nil }
        return userContentService.notes.first { $0.id == noteId }
    }
}
