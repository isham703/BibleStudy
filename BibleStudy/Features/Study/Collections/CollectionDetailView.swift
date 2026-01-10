import SwiftUI

// MARK: - Collection Detail View
// Displays contents of a study collection

struct CollectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CollectionDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    init(collection: StudyCollection) {
        _viewModel = State(initialValue: CollectionDetailViewModel(collection: collection))
    }

    var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyState
            } else {
                contentList
            }
        }
        .navigationTitle(viewModel.collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            await viewModel.togglePin()
                        }
                    } label: {
                        Label(
                            viewModel.collection.isPinned ? "Unpin" : "Pin",
                            systemImage: viewModel.collection.isPinned ? "pin.slash" : "pin"
                        )
                    }

                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Collection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCollectionSheet(
                name: viewModel.collection.name,
                description: viewModel.collection.description
            ) { name, description in
                Task {
                    await viewModel.renameCollection(name: name)
                    await viewModel.setDescription(description)
                }
            }
        }
        .confirmationDialog(
            "Delete Collection",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteCollection() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.collection.name)\"? This cannot be undone.")
        }
        .task {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            collectionHeader

            EmptyStateView(
                icon: "tray",
                title: "No items yet",
                message: "Add verses, highlights, or notes to this collection while reading"
            )
        }
    }

    // MARK: - Collection Header
    private var collectionHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(viewModel.collection.color).opacity(Theme.Opacity.light))
                    .frame(width: 64, height: 64)

                Image(systemName: viewModel.collection.icon)
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color(viewModel.collection.color))
            }

            // Type
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: viewModel.collection.type.icon)
                Text(viewModel.collection.type.displayName)
            }
            .font(Typography.Command.caption)
            .foregroundStyle(Color.secondaryText)

            // Description
            if !viewModel.collection.description.isEmpty {
                Text(viewModel.collection.description)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Content List
    private var contentList: some View {
        List {
            // Header Section
            Section {
                collectionHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Statistics
            Section {
                HStack(spacing: Theme.Spacing.lg) {
                    StatBadge(
                        icon: "book",
                        value: "\(viewModel.collection.verseCount)",
                        label: "Verses"
                    )
                    StatBadge(
                        icon: "highlighter",
                        value: "\(viewModel.collection.highlightCount)",
                        label: "Highlights"
                    )
                    StatBadge(
                        icon: "note.text",
                        value: "\(viewModel.collection.noteCount)",
                        label: "Notes"
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .listRowBackground(Color.clear)

            // Items
            Section("Items") {
                ForEach(viewModel.items) { item in
                    CollectionItemRow(
                        item: item,
                        highlight: viewModel.getHighlight(for: item),
                        note: viewModel.getNote(for: item)
                    )
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.removeItem(at: index)
                        }
                    }
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.moveItem(from: source, to: destination)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(viewModel.isEditing ? .active : .inactive))
    }
}

// MARK: - Collection Item Row

struct CollectionItemRow: View {
    let item: CollectionItem
    let highlight: Highlight?
    let note: Note?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Type Icon
            itemIcon

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.reference)
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                itemSubtitle
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    @ViewBuilder
    private var itemIcon: some View {
        switch item.type {
        case .verse:
            Image(systemName: "book")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 24)

        case .highlight:
            if let highlight {
                Circle()
                    .fill(highlight.color.color)
                    .frame(width: 16, height: 16)
                    .frame(width: 24)
            } else {
                Image(systemName: "highlighter")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 24)
            }

        case .note:
            Image(systemName: note?.template.icon ?? "note.text")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 24)
        }
    }

    @ViewBuilder
    private var itemSubtitle: some View {
        switch item.type {
        case .verse:
            Text("Verse")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)

        case .highlight:
            if let highlight {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(highlight.color.displayName)
                    if highlight.category != .none {
                        Text("•")
                        Text(highlight.category.displayName)
                    }
                }
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)
            }

        case .note:
            if let note {
                Text(note.preview)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.caption)
                Text(value)
                    .font(Typography.Command.headline.monospacedDigit())
            }
            .foregroundStyle(Color.primaryText)

            Text(label)
                .font(Typography.Command.meta)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

// MARK: - Edit Collection Sheet

struct EditCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String

    let onSave: (String, String) -> Void

    init(
        name: String,
        description: String,
        onSave: @escaping (String, String) -> Void
    ) {
        _name = State(initialValue: name)
        _description = State(initialValue: description)
        self.onSave = onSave
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, description)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: StudyCollection(
                userId: UUID(),
                name: "Sermon Prep",
                description: "Preparing for Sunday's message",
                type: .sermonPrep,
                items: [
                    .verse(range: VerseRange(bookId: 43, chapter: 3, verseStart: 16, verseEnd: 17)),
                    .verse(range: VerseRange(bookId: 45, chapter: 8, verseStart: 28, verseEnd: 28))
                ]
            )
        )
    }
}
