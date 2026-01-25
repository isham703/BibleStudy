import SwiftUI

// MARK: - Note Preview Sheet State
// Manages state for NotePreviewSheet including pagination, edit/delete flows
// Follows InsightSheetState pattern with @Observable + callbacks

@Observable
@MainActor
final class NotePreviewSheetState {
    // MARK: - Data

    /// All notes for the verse
    var notes: [Note] = []

    /// Current page index (0-based)
    var currentIndex: Int = 0

    // MARK: - Callbacks (set by parent)

    /// Called when user taps Edit
    var onEdit: ((Note) -> Void)?

    /// Called when user confirms Delete
    var onDelete: ((Note) async -> Void)?

    /// Called to dismiss the sheet
    var onDismiss: (() -> Void)?

    /// Called to refresh notes from parent (after edit/delete)
    var onRefresh: (() -> [Note])?

    // MARK: - Computed Properties

    /// Currently displayed note
    var currentNote: Note? {
        guard currentIndex >= 0 && currentIndex < notes.count else { return nil }
        return notes[currentIndex]
    }

    /// Whether there are multiple notes (show paging UI)
    var hasMultipleNotes: Bool {
        notes.count > 1
    }

    /// Total note count
    var noteCount: Int {
        notes.count
    }

    /// Page indicator text: "1 of 3"
    var pageIndicatorText: String {
        "\(currentIndex + 1) of \(notes.count)"
    }

    // MARK: - Configuration

    /// Configure state for a new presentation
    func configure(
        notes: [Note],
        initialIndex: Int = 0,
        onEdit: ((Note) -> Void)?,
        onDelete: ((Note) async -> Void)?,
        onDismiss: @escaping () -> Void,
        onRefresh: @escaping () -> [Note]
    ) {
        self.notes = notes
        self.currentIndex = min(initialIndex, max(0, notes.count - 1))
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDismiss = onDismiss
        self.onRefresh = onRefresh
    }

    // MARK: - Actions

    /// Refresh notes from parent after edit
    func refreshNotes() {
        let updatedNotes = onRefresh?() ?? notes

        // Update notes array
        notes = updatedNotes

        // Clamp index if notes were deleted
        if notes.isEmpty {
            currentIndex = 0
        } else if currentIndex >= notes.count {
            currentIndex = notes.count - 1
        }
    }

    /// Handle delete action with smart navigation
    func handleDelete() async {
        guard let note = currentNote else { return }

        // Call delete callback
        await onDelete?(note)

        // Refresh notes from parent
        refreshNotes()

        // If no notes remain, dismiss
        if notes.isEmpty {
            onDismiss?()
        }
        // Otherwise, state already adjusted to show next/previous note
    }

    /// Handle edit action
    func handleEdit() {
        guard let note = currentNote else { return }
        onEdit?(note)
    }

    // MARK: - Reset

    /// Reset all state
    func reset() {
        notes = []
        currentIndex = 0
        onEdit = nil
        onDelete = nil
        onDismiss = nil
        onRefresh = nil
    }
}
