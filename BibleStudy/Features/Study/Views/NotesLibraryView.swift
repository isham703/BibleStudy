import SwiftUI

// MARK: - Notes Library View
// Hierarchical notes browser with filter bar, template chips, and grouped list
// Displays: Book > Chapter > Notes

struct NotesLibraryView: View {
    @State private var viewModel = NotesLibraryViewModel()
    @State private var showSortSheet = false
    @State private var showNoteEditor = false
    @State private var selectedNote: Note?

    let onNavigate: ((VerseRange) -> Void)?

    init(onNavigate: ((VerseRange) -> Void)? = nil) {
        self.onNavigate = onNavigate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Filter chips
            filterChips

            // Sort/Group options button
            sortButton

            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isEmpty {
                emptyState
            } else if viewModel.isSearchEmpty {
                noResultsState
            } else {
                notesList
            }
        }
        .background(Color.appBackground)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showSortSheet) {
            sortSheet
        }
        .sheet(isPresented: $showNoteEditor) {
            if let note = selectedNote {
                NoteEditor(
                    range: note.range,
                    existingNote: note,
                    allNotes: viewModel.notes,
                    onSave: { content, template, linkedIds in
                        Task {
                            var updated = note
                            updated.content = content
                            updated.template = template
                            updated.linkedNoteIds = linkedIds
                            updated.updatedAt = Date()
                            updated.needsSync = true
                            try? await UserContentService.shared.updateNote(updated)
                            await viewModel.load()
                        }
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("TertiaryText"))

            TextField("Search notes...", text: $viewModel.searchQuery)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // All filter
                NoteTemplateFilterChip(
                    template: nil,
                    count: viewModel.noteStats.total,
                    isSelected: viewModel.selectedTemplateFilter == nil
                ) {
                    viewModel.selectedTemplateFilter = nil
                }

                // Template filters
                ForEach(NoteTemplate.allCases, id: \.self) { template in
                    NoteTemplateFilterChip(
                        template: template,
                        count: viewModel.noteStats.count(for: template),
                        isSelected: viewModel.selectedTemplateFilter == template
                    ) {
                        viewModel.selectedTemplateFilter = template
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Sort Button

    private var sortButton: some View {
        HStack {
            Spacer()

            Button {
                showSortSheet = true
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: viewModel.groupOption.icon)
                        .font(Typography.Icon.xs)
                    Text(viewModel.groupOption.rawValue)
                        .font(Typography.Command.caption)
                    Image(systemName: "chevron.down")
                        .font(Typography.Icon.xxs)
                }
                .foregroundStyle(Color("AppAccentAction"))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Notes List

    private var notesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedNotes) { group in
                    Section {
                        if let chapters = group.chapters {
                            // Hierarchical: Book > Chapter > Notes
                            ForEach(chapters) { chapterGroup in
                                chapterSection(chapterGroup, bookName: group.title)
                            }
                        } else {
                            // Flat list
                            ForEach(group.notes) { note in
                                noteCard(note)
                            }
                        }
                    } header: {
                        if let title = group.title {
                            sectionHeader(title, template: group.template)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func chapterSection(_ chapterGroup: ChapterSubgroup, bookName: String?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Chapter header
            Text("Chapter \(chapterGroup.chapter)")
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.leading, Theme.Spacing.sm)

            // Notes in chapter
            ForEach(chapterGroup.notes) { note in
                noteCard(note)
            }
        }
    }

    private func sectionHeader(_ title: String, template: NoteTemplate?) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let template = template {
                Image(systemName: template.icon)
                    .font(Typography.Icon.sm)
                    .foregroundStyle(template.accentColor)
            }

            Text(title)
                .font(Typography.Command.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Color.appBackground)
    }

    private func noteCard(_ note: Note) -> some View {
        Button {
            selectedNote = note
            showNoteEditor = true
        } label: {
            NoteLibraryCard(
                note: note,
                onTap: {
                    selectedNote = note
                    showNoteEditor = true
                },
                onNavigate: {
                    onNavigate?(note.range)
                },
                onDelete: {
                    Task {
                        await viewModel.deleteNote(note)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .tint(Color("AppAccentAction"))
            Text("Loading notes...")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "note.text")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("TertiaryText"))

            Text("No Notes Yet")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Long-press any verse to add your first note.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("TertiaryText"))

            Text("No Results")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Try adjusting your search or filters.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        NavigationStack {
            List {
                Section("Sort By") {
                    ForEach(NoteSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .frame(width: Theme.Size.iconSizeLarge)

                                Text(option.rawValue)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                        }
                    }
                }

                Section("Group By") {
                    ForEach(NoteGroupOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.groupOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .frame(width: Theme.Size.iconSizeLarge)

                                Text(option.rawValue)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if viewModel.groupOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort & Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSortSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Note Library Card

struct NoteLibraryCard: View {
    let note: Note
    let onTap: () -> Void
    let onNavigate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Template color indicator
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(note.template.accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Reference + template badge
                HStack {
                    Text(note.reference)
                        .font(Typography.Command.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    HStack(spacing: 2) {
                        Image(systemName: note.template.icon)
                            .font(Typography.Icon.xxs)
                        Text(note.template.displayName)
                            .font(Typography.Command.meta)
                    }
                    .foregroundStyle(note.template.accentColor)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(note.template.accentColor.opacity(Theme.Opacity.subtle))
                    )

                    Spacer()
                }

                // Content preview (Serif)
                Text(note.preview)
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)

                // Date
                Text(note.updatedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button { onTap() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button { onNavigate() } label: {
                Label("Go to Verse", systemImage: "arrow.right")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotesLibraryView { range in
            print("Navigate to \(range)")
        }
    }
}
