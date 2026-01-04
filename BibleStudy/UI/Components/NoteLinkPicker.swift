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
                                .font(Typography.UI.body)
                                .foregroundStyle(Color.secondaryText)
                                .listRowBackground(Color.clear)
                        } else {
                            Text("No notes match your search")
                                .font(Typography.UI.body)
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
    let note: Note
    let isLinked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Link status indicator
                Image(systemName: isLinked ? "link.circle.fill" : "link.circle")
                    .font(Typography.UI.title2)
                    .foregroundStyle(isLinked ? Color.accentGold : Color.tertiaryText)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    // Reference
                    Text(note.reference)
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.accentGold)

                    // Preview
                    Text(note.preview)
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)

                    // Template badge
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: note.template.icon)
                        Text(note.template.displayName)
                    }
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                if isLinked {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentGold)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
    }
}

// MARK: - Linked Notes Display
// Shows linked notes in a compact view

struct LinkedNotesDisplay: View {
    let linkedNotes: [Note]
    let onNoteTap: (Note) -> Void
    let onRemoveLink: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "link")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)

                Text("Linked Notes")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                Text("\(linkedNotes.count)")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }

            ForEach(linkedNotes) { note in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        onNoteTap(note)
                    } label: {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Circle()
                                .fill(Color.accentGold.opacity(AppTheme.Opacity.lightMedium))
                                .frame(width: AppTheme.ComponentSize.indicator, height: AppTheme.ComponentSize.indicator)

                            Text(note.reference)
                                .font(Typography.UI.caption1Bold)
                                .foregroundStyle(Color.accentGold)

                            Text(note.preview)
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        onRemoveLink(note)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.elevatedBackground)
        )
    }
}

// MARK: - Compact Link Button
// Small button for adding links

struct NoteLinkButton: View {
    let linkedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "link")
                    .font(Typography.UI.subheadline)

                if linkedCount > 0 {
                    Text("\(linkedCount)")
                        .font(Typography.UI.caption2)
                }
            }
            .foregroundStyle(linkedCount > 0 ? Color.accentGold : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(linkedCount > 0 ? Color.accentGold.opacity(AppTheme.Opacity.light) : Color.elevatedBackground)
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
