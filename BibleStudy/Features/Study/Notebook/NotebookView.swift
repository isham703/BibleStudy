import SwiftUI

// MARK: - Notebook View
// Displays user's highlights and notes

struct NotebookView: View {
    @State private var viewModel = NotebookViewModel()
    @State private var selectedNote: Note?

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading your notes...")
            } else if viewModel.isEmpty {
                emptyState
            } else if viewModel.isSearchEmpty {
                searchEmptyState
            } else {
                contentList
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search highlights & notes")
        .task {
            await viewModel.load()
        }
        .sheet(item: $selectedNote) { note in
            NoteEditor(
                range: note.range,
                existingNote: note,
                allNotes: viewModel.notes,
                onSave: { content, template, linkedNoteIds in
                    Task {
                        await viewModel.updateNote(note, content: content, template: template, linkedNoteIds: linkedNoteIds)
                    }
                },
                onDelete: {
                    Task {
                        await viewModel.deleteNote(note)
                        selectedNote = nil
                    }
                }
            )
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        EmptyStateView.noNotes
    }

    // MARK: - Search Empty State
    private var searchEmptyState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results",
            message: "Try a different search term",
            animation: .noTopics
        )
    }

    // MARK: - Content List
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                // Filter Picker
                Picker("Filter", selection: $viewModel.filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)

                // Highlights Section
                if viewModel.filterMode != .notes && !viewModel.filteredHighlights.isEmpty {
                    highlightsSection
                }

                // Notes Section
                if viewModel.filterMode != .highlights && !viewModel.filteredNotes.isEmpty {
                    notesSection
                }
            }
            .padding(.vertical, AppTheme.Spacing.md)
        }
    }

    // MARK: - Highlights Section
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Highlights")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, AppTheme.Spacing.md)

            ForEach(viewModel.filteredHighlights) { highlight in
                HighlightCard(
                    highlight: highlight,
                    verseText: nil, // Would fetch verse text
                    onTap: {
                        // Navigate to verse
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .contextMenu {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteHighlight(highlight)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Notes")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, AppTheme.Spacing.md)

            ForEach(viewModel.filteredNotes) { note in
                NoteCard(note: note) {
                    selectedNote = note
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .contextMenu {
                    Button {
                        selectedNote = note
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        NotebookView()
            .navigationTitle("Notebook")
    }
}
