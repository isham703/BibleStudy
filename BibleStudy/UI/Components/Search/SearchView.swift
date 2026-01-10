import SwiftUI

// MARK: - Search View
// Full-text verse search with FTS5

struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchService.SearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedBook: Book?
    @State private var showBookPicker = false

    @Environment(BibleService.self) private var bibleService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var onNavigate: ((VerseRange) -> Void)?

    // MARK: - Reference Detection

    /// Try to parse the query as a Bible reference
    private var detectedReference: ParsedReference? {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        if case .success(let ref) = ReferenceParser.parse(query) {
            return ref
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scope bar (translation + book filter)
            scopeBar

            // Search bar
            searchBar

            // Book filter chips
            bookFilterChips

            // Content
            content
        }
        .background(Color.appBackground)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showBookPicker) {
            BookFilterSheet(selectedBook: $selectedBook) {
                performSearch(query)
            }
        }
    }

    // MARK: - Scope Bar

    private var scopeBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Translation badge
            Text(bibleService.currentTranslation?.abbreviation ?? "KJV")
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                .clipShape(Capsule())

            Text("•")
                .foregroundStyle(Color.tertiaryText)

            // Book filter
            Button {
                showBookPicker = true
            } label: {
                HStack(spacing: 2) {
                    Text(selectedBook?.name ?? "All Books")
                        .font(Typography.Command.caption)
                        .foregroundStyle(selectedBook != nil ? Color.primaryText : Color.secondaryText)

                    Image(systemName: "chevron.down")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Spacer()

            // Result count
            if !results.isEmpty {
                Text("\(results.count) results")
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.elevatedBackground)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tertiaryText)

            TextField("Search or go to reference...", text: $query)
                .font(Typography.Command.body)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    performSearch(query)
                }
                .onChange(of: query) { _, newValue in
                    performSearch(newValue)
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Book Filter Chips

    private var bookFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // All books chip
                BookFilterChip(
                    title: "All",
                    isSelected: selectedBook == nil
                ) {
                    selectedBook = nil
                    performSearch(query)
                }

                // Testament groups
                BookFilterChip(
                    title: "Old Testament",
                    isSelected: false,
                    showChevron: true
                ) {
                    // Could expand to show OT books
                }

                BookFilterChip(
                    title: "New Testament",
                    isSelected: false,
                    showChevron: true
                ) {
                    // Could expand to show NT books
                }

                // Selected book indicator
                if let book = selectedBook {
                    BookFilterChip(
                        title: book.name,
                        isSelected: true
                    ) {
                        selectedBook = nil
                        performSearch(query)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isSearching {
            loadingState
        } else if query.isEmpty {
            emptyStateInitial
        } else if detectedReference != nil || !results.isEmpty {
            resultsWithReferenceCard
        } else {
            emptyStateNoResults
        }
    }

    /// Shows reference card (if detected) followed by search results
    private var resultsWithReferenceCard: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Reference card (appears at top when query looks like a reference)
                if let ref = detectedReference {
                    ReferenceGoToCard(reference: ref) {
                        let range = VerseRange(
                            bookId: ref.book.id,
                            chapter: ref.chapter,
                            verseStart: ref.verseStart ?? 1,
                            verseEnd: ref.verseEnd ?? ref.verseStart ?? 1
                        )
                        onNavigate?(range)
                        dismiss()
                    }
                }

                // Search results
                ForEach(results) { result in
                    SearchResultCard(result: result) {
                        onNavigate?(result.verseRange)
                        dismiss()
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text("Searching...")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateInitial: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "text.magnifyingglass")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("Search the Bible")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            // Go to reference examples
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Go to a reference:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("John 3:16", "jump to verse")
                syntaxHint("Gen 1", "jump to chapter")
                syntaxHint("Rom 8:28-30", "verse range")
            }
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))

            // Word search examples
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Or search for words:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("love", "matches love, loves, loving")
                syntaxHint("\"love one another\"", "exact phrase")
                syntaxHint("grace AND mercy", "both words")
            }
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateNoResults: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("No results for \"\(query)\"")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            Text("Try different keywords or check your spelling")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Search tips:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("love", "matches love, loves, loving")
                syntaxHint("\"exact phrase\"", "use quotes for phrases")
                syntaxHint("grace AND mercy", "both words required")
            }
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func syntaxHint(_ example: String, _ description: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(example)
                // swiftlint:disable:next hardcoded_font_system
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.primaryText)

            Text("— \(description)")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Search Execution

    private func performSearch(_ query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            isSearching = true
            defer { isSearching = false }

            // Debounce 300ms
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            do {
                results = try await SearchService.shared.search(
                    query: query,
                    translationId: bibleService.currentTranslationId,
                    bookId: selectedBook?.id
                )
            } catch {
                results = []
                print("Search error: \(error)")
            }
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: SearchService.SearchResult
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Book color indicator
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(bookColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Reference
                    Text(result.verse.reference)
                        .font(Typography.Command.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    // Highlighted snippet
                    Text(result.highlightedSnippet)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var bookColor: Color {
        // Color based on testament - using accentAction for both for consistency
        return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed)
    }
}

// MARK: - Reference Go To Card

struct ReferenceGoToCard: View {
    let reference: ParsedReference
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(Typography.Command.title2)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go to")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)

                    Text(reference.displayText)
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color.primaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Filter Chip

struct BookFilterChip: View {
    let title: String
    let isSelected: Bool
    var showChevron: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(title)
                    .font(Typography.Command.caption)

                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(Typography.Command.meta)
                }
            }
            .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Filter Sheet

struct BookFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedBook: Book?
    var onSelect: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // All books option
                Button {
                    selectedBook = nil
                    onSelect()
                    dismiss()
                } label: {
                    HStack {
                        Text("All Books")
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        if selectedBook == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        }
                    }
                }

                // Old Testament
                Section("Old Testament") {
                    ForEach(Book.oldTestament, id: \.id) { book in
                        bookRow(book)
                    }
                }

                // New Testament
                Section("New Testament") {
                    ForEach(Book.newTestament, id: \.id) { book in
                        bookRow(book)
                    }
                }
            }
            .navigationTitle("Filter by Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func bookRow(_ book: Book) -> some View {
        Button {
            selectedBook = book
            onSelect()
            dismiss()
        } label: {
            HStack {
                Text(book.name)
                    .foregroundStyle(Color.primaryText)
                Spacer()
                if selectedBook?.id == book.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView()
            .environment(BibleService.shared)
    }
}
