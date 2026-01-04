import SwiftUI

// MARK: - Notebook View Model
// Manages state for the notebook (highlights and notes)

@Observable
@MainActor
final class NotebookViewModel {
    // MARK: - Dependencies
    private let userContentService: UserContentService

    // MARK: - State
    var highlights: [Highlight] = []
    var notes: [Note] = []
    var isLoading: Bool = false
    var error: Error?

    // Filtering
    var filterMode: FilterMode = .all
    var searchText: String = ""

    // MARK: - Computed Properties
    var filteredHighlights: [Highlight] {
        var result = highlights

        if !searchText.isEmpty {
            result = result.filter { highlight in
                highlight.reference.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var filteredNotes: [Note] {
        var result = notes

        if !searchText.isEmpty {
            result = result.filter { note in
                note.reference.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var isEmpty: Bool {
        highlights.isEmpty && notes.isEmpty
    }

    var isSearchEmpty: Bool {
        !searchText.isEmpty && filteredHighlights.isEmpty && filteredNotes.isEmpty
    }

    // MARK: - Initialization
    init(userContentService: UserContentService? = nil) {
        self.userContentService = userContentService ?? UserContentService.shared
    }

    // MARK: - Loading
    func load() async {
        isLoading = true
        error = nil

        await userContentService.loadContent()
        highlights = userContentService.highlights
        notes = userContentService.notes

        isLoading = false
    }

    // MARK: - Actions
    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try await userContentService.deleteHighlight(highlight)
            highlights.removeAll { $0.id == highlight.id }
        } catch {
            self.error = error
        }
    }

    func deleteNote(_ note: Note) async {
        do {
            try await userContentService.deleteNote(note)
            notes.removeAll { $0.id == note.id }
        } catch {
            self.error = error
        }
    }

    func updateNote(_ note: Note, content: String, template: NoteTemplate, linkedNoteIds: [UUID] = []) async {
        do {
            var updatedNote = note
            updatedNote.content = content
            updatedNote.template = template
            updatedNote.linkedNoteIds = linkedNoteIds
            updatedNote.updatedAt = Date()
            updatedNote.needsSync = true

            try await userContentService.updateNote(updatedNote)

            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = updatedNote
            }
        } catch {
            self.error = error
        }
    }
}

// MARK: - Filter Mode
enum FilterMode: String, CaseIterable {
    case all = "All"
    case highlights = "Highlights"
    case notes = "Notes"
}
