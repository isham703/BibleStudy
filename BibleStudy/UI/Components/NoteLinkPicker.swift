import SwiftUI

// MARK: - Note Link Picker
// Allows users to select notes to link together

struct NoteLinkPicker: View {
    @Environment(\.dismiss) private var dismiss

    let currentNoteId: UUID?
    let allNotes: [Note]
    @Binding var linkedNoteIds: [UUID]
    var onLinksChanged: (([UUID]) -> Void)?

    @State private var searchText = ""

    private var availableNotes: [Note] {
        allNotes.filter { note in
            // Exclude current note and already linked notes
            note.id != currentNoteId
        }
    }

    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return availableNotes
        }
        return availableNotes.filter { note in
            note.reference.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var linkedNotes: [Note] {
        allNotes.filter { linkedNoteIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Currently linked notes section
                if !linkedNotes.isEmpty {
                    Section {
                        ForEach(linkedNotes) { note in
                            LinkedNoteRow(
                                note: note,
                                isLinked: true,
                                onToggle: {
                                    toggleLink(note)
                                }
                            )
                        }
                    } header: {
                        Text("Linked Notes (\(linkedNotes.count))")
                    }
                }

                // Available notes section
                Section {
                    if filteredNotes.isEmpty {
                        if searchText.isEmpty {
                            Text("No other notes available to link")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color.secondaryText)
                                .listRowBackground(Color.clear)
                        } else {
                            Text("No notes match your search")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color.secondaryText)
                                .listRowBackground(Color.clear)
                        }
                    } else {
                        ForEach(filteredNotes) { note in
                            LinkedNoteRow(
                                note: note,
                                isLinked: linkedNoteIds.contains(note.id),
                                onToggle: {
                                    toggleLink(note)
                                }
                            )
                        }
                    }
                } header: {
                    Text("Available Notes")
                }
            }
            .searchable(text: $searchText, prompt: "Search notes...")
            .navigationTitle("Link Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onLinksChanged?(linkedNoteIds)
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleLink(_ note: Note) {
        if linkedNoteIds.contains(note.id) {
            linkedNoteIds.removeAll { $0 == note.id }
        } else {
            linkedNoteIds.append(note.id)
        }
    }
}

// MARK: - Linked Note Row
struct LinkedNoteRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let note: Note
    let isLinked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                // Link status indicator
                Image(systemName: isLinked ? "link.circle.fill" : "link.circle")
                    .font(Typography.Command.title2)
                    .foregroundStyle(isLinked ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.tertiaryText)

                VStack(alignment: .leading, spacing: 2) {
                    // Reference
                    Text(note.reference)
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                    // Preview
                    Text(note.preview)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)

                    // Template badge
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: note.template.icon)
                        Text(note.template.displayName)
                    }
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                if isLinked {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }
}

// MARK: - Linked Notes Display
// Shows linked notes in a compact view

struct LinkedNotesDisplay: View {
    @Environment(\.colorScheme) private var colorScheme
    let linkedNotes: [Note]
    let onNoteTap: (Note) -> Void
    let onRemoveLink: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "link")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.secondaryText)

                Text("Linked Notes")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                Text("\(linkedNotes.count)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.tertiaryText)
            }

            ForEach(linkedNotes) { note in
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        onNoteTap(note)
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                                .frame(width: 8, height: 8)

                            Text(note.reference)
                                .font(Typography.Command.caption.weight(.semibold))
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                            Text(note.preview)
                                .font(Typography.Command.caption)
                                .foregroundStyle(Color.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        onRemoveLink(note)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.Command.subheadline)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color.elevatedBackground)
        )
    }
}

// MARK: - Compact Link Button
// Small button for adding links

struct NoteLinkButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let linkedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "link")
                    .font(Typography.Command.subheadline)

                if linkedCount > 0 {
                    Text("\(linkedCount)")
                        .font(Typography.Command.meta)
                }
            }
            .foregroundStyle(linkedCount > 0 ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.secondaryText)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(linkedCount > 0 ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light) : Color.elevatedBackground)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleNotes = [
        Note(
            id: UUID(),
            userId: UUID(),
            bookId: 1,
            chapter: 1,
            verseStart: 1,
            verseEnd: 3,
            content: "Sample note about creation",
            template: .observation
        ),
        Note(
            id: UUID(),
            userId: UUID(),
            bookId: 43,
            chapter: 1,
            verseStart: 1,
            verseEnd: 5,
            content: "In the beginning was the Word - connecting to Genesis",
            template: .exegesis
        ),
        Note(
            id: UUID(),
            userId: UUID(),
            bookId: 19,
            chapter: 23,
            verseStart: 1,
            verseEnd: 6,
            content: "The Lord is my shepherd - comfort and provision",
            template: .application
        )
    ]

    return NoteLinkPicker(
        currentNoteId: nil,
        allNotes: sampleNotes,
        linkedNoteIds: .constant([])
    )
}
