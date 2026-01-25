import SwiftUI

// MARK: - Search View
// Full-text verse search with FTS5

struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchService.SearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedBook: Book?
    @State private var selectedTestament: Testament?
    @State private var showBookPicker = false
    @State private var recentSearches: [String] = []

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
            BookFilterSheet(
                selectedBook: $selectedBook,
                selectedTestament: $selectedTestament
            ) {
                performSearch(query)
            }
        }
        .onAppear {
            loadRecentSearches()
        }
    }

    // MARK: - Scope Bar

    /// Returns the display text for the current scope filter
    private var scopeDisplayText: String {
        if let book = selectedBook {
            return book.name
        } else if let testament = selectedTestament {
            return testament == .old ? "Old Testament" : "New Testament"
        }
        return "All Books"
    }

    /// Whether any scope filter is active
    private var hasScopeFilter: Bool {
        selectedBook != nil || selectedTestament != nil
    }

    private var scopeBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Unified scope button: Translation + Book scope
            Button {
                showBookPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(bibleService.currentTranslation?.abbreviation ?? "KJV")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccentAction"))

                    Text("·")
                        .foregroundStyle(Color("TertiaryText"))

                    Text(scopeDisplayText)
                        .font(Typography.Command.caption)
                        .foregroundStyle(hasScopeFilter ? Color("AppTextPrimary") : Color("AppTextSecondary"))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background(Color("AppSurface"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(hasScopeFilter ? Color("AppAccentAction").opacity(0.3) : Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )
            }

            Spacer()

            // Result count
            if !results.isEmpty {
                Text("\(results.count) results")
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("TertiaryText"))

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
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
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
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateInitial: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Recent searches (if any)
                if !recentSearches.isEmpty {
                    recentSearchesSection
                }

                // Search guidance
                searchGuidanceSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Recent")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))

                Spacer()

                Button {
                    withAnimation(Theme.Animation.fade) {
                        recentSearches = []
                        saveRecentSearches()
                    }
                } label: {
                    Text("Clear")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }

            ForEach(recentSearches.prefix(5), id: \.self) { search in
                Button {
                    query = search
                    performSearch(search)
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))

                        Text(search)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var searchGuidanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Go to reference examples
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Go to a reference:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.bottom, 2)

                tappableExample("John 3:16", "jump to verse")
                tappableExample("Gen 1", "jump to chapter")
                tappableExample("Rom 8:28-30", "verse range")
            }

            Divider()
                .background(Color("AppDivider"))

            // Word search examples
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Or search for words:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.bottom, 2)

                tappableExample("love", "matches love, loves, loving")
                tappableExample("\"love one another\"", "exact phrase")
                tappableExample("grace AND mercy", "both words")
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func tappableExample(_ example: String, _ description: String) -> some View {
        Button {
            query = example
            performSearch(example)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text(example)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppAccentAction"))

                Text("— \(description)")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()
            }
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyStateNoResults: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Color("TertiaryText"))

            Text("No results for \"\(query)\"")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Try different keywords or check your spelling")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Try these searches:")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.bottom, 2)

                tappableExample("love", "matches love, loves, loving")
                tappableExample("\"love one another\"", "exact phrase")
                tappableExample("grace AND mercy", "both words")
            }
            .padding(Theme.Spacing.md)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Execution

    private func performSearch(_ query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
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
                // Determine book IDs to search based on testament or specific book selection
                let bookIds: [Int]?
                if let book = selectedBook {
                    bookIds = [book.id]
                } else if let testament = selectedTestament {
                    bookIds = (testament == .old ? Book.oldTestament : Book.newTestament).map(\.id)
                } else {
                    bookIds = nil
                }

                results = try await SearchService.shared.search(
                    query: trimmedQuery,
                    translationId: bibleService.currentTranslationId,
                    bookIds: bookIds
                )

                // Save to recent searches if we got results
                if !results.isEmpty {
                    await MainActor.run {
                        addToRecentSearches(trimmedQuery)
                    }
                }
            } catch {
                results = []
                print("Search error: \(error)")
            }
        }
    }

    // MARK: - Recent Searches

    private static let recentSearchesKey = "SearchView.recentSearches"
    private static let maxRecentSearches = 10

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
    }

    private func addToRecentSearches(_ search: String) {
        // Don't add duplicates - move existing to top
        recentSearches.removeAll { $0.lowercased() == search.lowercased() }
        recentSearches.insert(search, at: 0)

        // Keep only the most recent
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }

        saveRecentSearches()
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
                        .foregroundStyle(Color("AppTextPrimary"))

                    // Highlighted snippet
                    Text(result.highlightedSnippet)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var bookColor: Color {
        // Color based on testament - using accentAction for both for consistency
        return Color("AppAccentAction").opacity(Theme.Opacity.pressed)
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
                    .foregroundStyle(Color("AppAccentAction"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go to")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text(reference.displayText)
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppAccentAction").opacity(Theme.Opacity.focusStroke), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Filter Sheet

struct BookFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(BibleService.self) private var bibleService
    @Binding var selectedBook: Book?
    @Binding var selectedTestament: Testament?
    var onSelect: () -> Void

    /// Whether no filter is active (all books)
    private var isAllSelected: Bool {
        selectedBook == nil && selectedTestament == nil
    }

    /// Whether Old Testament filter is active (but no specific book)
    private var isOldTestamentSelected: Bool {
        selectedBook == nil && selectedTestament == .old
    }

    /// Whether New Testament filter is active (but no specific book)
    private var isNewTestamentSelected: Bool {
        selectedBook == nil && selectedTestament == .new
    }

    var body: some View {
        NavigationStack {
            List {
                // Translation section
                Section {
                    ForEach(bibleService.availableTranslations, id: \.id) { translation in
                        Button {
                            bibleService.setTranslation(translation.id)
                            onSelect()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(translation.abbreviation)
                                        .font(Typography.Command.body)
                                        .foregroundStyle(Color("AppTextPrimary"))

                                    Text(translation.name)
                                        .font(Typography.Command.caption)
                                        .foregroundStyle(Color("TertiaryText"))
                                }

                                Spacer()

                                if translation.id == bibleService.currentTranslationId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Translation")
                }

                // Scope section
                Section {
                    scopeRow("All Books", isSelected: isAllSelected) {
                        selectedBook = nil
                        selectedTestament = nil
                        onSelect()
                        dismiss()
                    }

                    scopeRow("Old Testament", subtitle: "39 books", isSelected: isOldTestamentSelected) {
                        selectedBook = nil
                        selectedTestament = .old
                        onSelect()
                        dismiss()
                    }

                    scopeRow("New Testament", subtitle: "27 books", isSelected: isNewTestamentSelected) {
                        selectedBook = nil
                        selectedTestament = .new
                        onSelect()
                        dismiss()
                    }
                } header: {
                    Text("Search In")
                }

                // Specific book section (progressive disclosure via NavigationLink)
                Section {
                    NavigationLink {
                        bookPickerList
                    } label: {
                        HStack {
                            Text(selectedBook != nil ? "Book: \(selectedBook!.name)" : "Choose a specific book")
                                .foregroundStyle(selectedBook != nil ? Color("AppTextPrimary") : Color("AppTextSecondary"))

                            Spacer()

                            if selectedBook != nil {
                                Button {
                                    selectedBook = nil
                                    onSelect()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color("TertiaryText"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Specific Book")
                }
            }
            .navigationTitle("Search Filters")
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

    // MARK: - Scope Row

    private func scopeRow(
        _ title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
    }

    // MARK: - Book Picker List

    private var bookPickerList: some View {
        List {
            Section("Old Testament") {
                ForEach(Book.oldTestament, id: \.id) { book in
                    bookRow(book)
                }
            }

            Section("New Testament") {
                ForEach(Book.newTestament, id: \.id) { book in
                    bookRow(book)
                }
            }
        }
        .navigationTitle("Choose Book")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bookRow(_ book: Book) -> some View {
        Button {
            selectedBook = book
            selectedTestament = nil  // Clear testament when selecting specific book
            onSelect()
            dismiss()
        } label: {
            HStack {
                Text(book.name)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                if selectedBook?.id == book.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color("AppAccentAction"))
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
