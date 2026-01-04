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
        HStack(spacing: AppTheme.Spacing.sm) {
            // Translation badge
            Text(bibleService.currentTranslation?.abbreviation ?? "KJV")
                .font(Typography.UI.caption1Bold)
                .foregroundStyle(Color.accentGold)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(Color.accentGold.opacity(AppTheme.Opacity.light))
                .clipShape(Capsule())

            Text("•")
                .foregroundStyle(Color.tertiaryText)

            // Book filter
            Button {
                showBookPicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Text(selectedBook?.name ?? "All Books")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(selectedBook != nil ? Color.primaryText : Color.secondaryText)

                    Image(systemName: "chevron.down")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Spacer()

            // Result count
            if !results.isEmpty {
                Text("\(results.count) results")
                    .font(Typography.UI.caption2.monospacedDigit())
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color.elevatedBackground)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tertiaryText)

            TextField("Search or go to reference...", text: $query)
                .font(Typography.UI.body)
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
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Book Filter Chips

    private var bookFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
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
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .padding(.bottom, AppTheme.Spacing.sm)
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
            LazyVStack(spacing: AppTheme.Spacing.md) {
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
            .padding(AppTheme.Spacing.md)
        }
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
            Text("Searching...")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateInitial: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "text.magnifyingglass")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("Search the Bible")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Go to reference examples
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Go to a reference:")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("John 3:16", "jump to verse")
                syntaxHint("Gen 1", "jump to chapter")
                syntaxHint("Rom 8:28-30", "verse range")
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            // Word search examples
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Or search for words:")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("love", "matches love, loves, loving")
                syntaxHint("\"love one another\"", "exact phrase")
                syntaxHint("grace AND mercy", "both words")
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateNoResults: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("No results for \"\(query)\"")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Text("Try different keywords or check your spelling")
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Search tips:")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)

                syntaxHint("love", "matches love, loves, loving")
                syntaxHint("\"exact phrase\"", "use quotes for phrases")
                syntaxHint("grace AND mercy", "both words required")
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func syntaxHint(_ example: String, _ description: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(example)
                .font(Typography.Code.inline)
                .foregroundStyle(Color.primaryText)

            Text("— \(description)")
                .font(Typography.UI.caption1)
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

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Book color indicator
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                    .fill(bookColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    // Reference
                    Text(result.verse.reference)
                        .font(Typography.UI.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    // Highlighted snippet
                    Text(result.highlightedSnippet)
                        .font(Typography.Scripture.body(size: 15))
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    private var bookColor: Color {
        // Color based on testament
        if result.verse.bookId <= 39 {
            return Color.accentBlue.opacity(AppTheme.Opacity.pressed) // OT
        } else {
            return Color.accentGold.opacity(AppTheme.Opacity.pressed) // NT
        }
    }
}

// MARK: - Reference Go To Card

struct ReferenceGoToCard: View {
    let reference: ParsedReference
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(Typography.UI.title2)
                    .foregroundStyle(Color.accentGold)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Go to")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)

                    Text(reference.displayText)
                        .font(Typography.UI.headline)
                        .foregroundStyle(Color.primaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.accentGold.opacity(AppTheme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(Color.accentGold.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Text(title)
                    .font(Typography.UI.caption1)

                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(Typography.UI.caption2)
                }
            }
            .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.lightMedium) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Filter Sheet

struct BookFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
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
                                .foregroundStyle(Color.accentGold)
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
                        .foregroundStyle(Color.accentGold)
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
