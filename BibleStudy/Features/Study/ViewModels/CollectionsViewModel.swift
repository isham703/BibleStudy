import SwiftUI

// MARK: - Collections View Model
// Manages state for the collections list

@Observable
@MainActor
final class CollectionsViewModel {
    // MARK: - Dependencies
    private let collectionService: StudyCollectionService

    // MARK: - State
    var collections: [StudyCollection] = []
    var pinnedCollections: [StudyCollection] = []
    var isLoading: Bool = false
    var error: Error?

    // Filtering
    var searchText: String = ""
    var selectedType: CollectionType?

    // MARK: - Computed Properties
    var filteredCollections: [StudyCollection] {
        var result = collections

        // Filter by type if selected
        if let selectedType {
            result = result.filter { $0.type == selectedType }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { collection in
                collection.name.localizedCaseInsensitiveContains(searchText) ||
                collection.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var unpinnedCollections: [StudyCollection] {
        filteredCollections.filter { !$0.isPinned }
    }

    var isEmpty: Bool {
        collections.isEmpty
    }

    var isSearchEmpty: Bool {
        !searchText.isEmpty && filteredCollections.isEmpty
    }

    // Statistics
    var totalCollections: Int { collections.count }
    var totalItems: Int { collections.reduce(0) { $0 + $1.itemCount } }

    // MARK: - Initialization
    init(collectionService: StudyCollectionService? = nil) {
        self.collectionService = collectionService ?? StudyCollectionService.shared
    }

    // MARK: - Loading
    func load() async {
        isLoading = true
        error = nil

        await collectionService.loadCollections()
        collections = collectionService.collections
        pinnedCollections = collectionService.pinnedCollections

        isLoading = false
    }

    // MARK: - Actions

    func createCollection(
        name: String,
        description: String = "",
        type: CollectionType = .personal,
        color: String = "AccentGold"
    ) async -> StudyCollection? {
        do {
            let collection = try await collectionService.createCollection(
                name: name,
                description: description,
                type: type,
                color: color
            )
            collections = collectionService.collections
            pinnedCollections = collectionService.pinnedCollections
            return collection
        } catch {
            self.error = error
            return nil
        }
    }

    func deleteCollection(_ collection: StudyCollection) async {
        do {
            try await collectionService.deleteCollection(collection)
            collections.removeAll { $0.id == collection.id }
            pinnedCollections.removeAll { $0.id == collection.id }
        } catch {
            self.error = error
        }
    }

    func togglePin(_ collection: StudyCollection) async {
        do {
            try await collectionService.togglePin(collection)
            collections = collectionService.collections
            pinnedCollections = collectionService.pinnedCollections
        } catch {
            self.error = error
        }
    }

    func renameCollection(_ collection: StudyCollection, name: String) async {
        do {
            try await collectionService.renameCollection(collection, name: name)
            if let index = collections.firstIndex(where: { $0.id == collection.id }) {
                collections[index].name = name
            }
        } catch {
            self.error = error
        }
    }
}
