import SwiftUI

// MARK: - Quick Jump Sheet
// Fast Bible reference navigation with fuzzy matching and recent searches

struct QuickJumpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var parseResult: Result<ParsedReference, ReferenceParseError>?
    @State private var recentSearches: [RecentSearch] = []
    @State private var suggestions: [Book] = []
    @FocusState private var isSearchFocused: Bool

    let onNavigate: (BibleLocation) -> Void

    private let recentSearchesKey = "QuickJump.RecentSearches"
    private let maxRecentSearches = 10

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Field
                searchField

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        // Parse result or error
                        if !searchText.isEmpty {
                            parseResultView
                        }

                        // Book suggestions
                        if !suggestions.isEmpty && parseResult == nil {
                            suggestionsSection
                        }

                        // Recent searches
                        if !recentSearches.isEmpty && searchText.isEmpty {
                            recentSearchesSection
                        }

                        // Quick examples when empty
                        if searchText.isEmpty && recentSearches.isEmpty {
                            examplesSection
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.md)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Go to Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecentSearches()
                isSearchFocused = true
            }
            .onChange(of: searchText) { _, newValue in
                updateParseResult(newValue)
                updateSuggestions(newValue)
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tertiaryText)

            TextField("John 3:16, Gen 1, Rom 8:28-30...", text: $searchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($isSearchFocused)
                .onSubmit {
                    if case .success(let ref) = parseResult {
                        navigateTo(ref)
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
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

    // MARK: - Parse Result View

    @ViewBuilder
    private var parseResultView: some View {
        switch parseResult {
        case .success(let ref):
            Button {
                navigateTo(ref)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(ref.displayText)
                            .font(Typography.Display.headline)
                            .foregroundStyle(Color.primaryText)

                        Text(ref.book.testament.displayName)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.accentBlue)
                }
                .padding(AppTheme.Spacing.md)
                .background(Color.selectedBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .buttonStyle(.plain)

        case .failure(let error):
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.warning)

                Text(error.localizedDescription)
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

        case .none:
            EmptyView()
        }
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Books")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)

            ForEach(suggestions) { book in
                Button {
                    searchText = "\(book.name) "
                } label: {
                    HStack {
                        Text(book.name)
                            .font(Typography.UI.body)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Text("\(book.chapters) ch.")
                            .font(Typography.UI.caption1.monospacedDigit())
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recent Searches Section

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Recent")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
                    .textCase(.uppercase)

                Spacer()

                Button("Clear") {
                    clearRecentSearches()
                }
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.accentBlue)
            }

            ForEach(recentSearches) { search in
                Button {
                    navigateTo(search)
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.tertiaryText)
                            .font(Typography.UI.caption1)

                        Text(search.displayText)
                            .font(Typography.UI.body)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Examples Section

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Examples")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                exampleRow("John 3:16", description: "Single verse")
                exampleRow("Genesis 1", description: "Entire chapter")
                exampleRow("Rom 8:28-30", description: "Verse range")
                exampleRow("Ps 23", description: "Using abbreviation")
            }
        }
    }

    private func exampleRow(_ reference: String, description: String) -> some View {
        Button {
            searchText = reference
        } label: {
            HStack {
                Text(reference)
                    .font(Typography.UI.body.monospaced())
                    .foregroundStyle(Color.accentBlue)

                Text("- \(description)")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)

                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func updateParseResult(_ input: String) {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            parseResult = nil
            return
        }

        // Only parse if there's a chapter number
        let hasNumber = input.contains(where: { $0.isNumber })
        if hasNumber {
            parseResult = ReferenceParser.parse(input)
        } else {
            parseResult = nil
        }
    }

    private func updateSuggestions(_ input: String) {
        // Only show suggestions if no valid parse yet and input has text
        if case .success = parseResult {
            suggestions = []
        } else {
            suggestions = ReferenceParser.suggestions(for: input, limit: 5)
        }
    }

    private func navigateTo(_ ref: ParsedReference) {
        saveRecentSearch(ref)
        onNavigate(ref.location)
        dismiss()
    }

    private func navigateTo(_ search: RecentSearch) {
        // Move to top of recents
        if let index = recentSearches.firstIndex(where: { $0.id == search.id }) {
            recentSearches.remove(at: index)
            recentSearches.insert(search, at: 0)
            saveRecentSearches()
        }
        onNavigate(search.location)
        dismiss()
    }

    // MARK: - Persistence

    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let searches = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return
        }
        recentSearches = searches
    }

    private func saveRecentSearch(_ ref: ParsedReference) {
        let search = RecentSearch(reference: ref)

        // Remove duplicate if exists
        recentSearches.removeAll { $0.reference == ref }

        // Add to front
        recentSearches.insert(search, at: 0)

        // Limit count
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    private func saveRecentSearches() {
        guard let data = try? JSONEncoder().encode(recentSearches) else { return }
        UserDefaults.standard.set(data, forKey: recentSearchesKey)
    }

    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
}

// MARK: - Recent Search Model

struct RecentSearch: Identifiable, Codable, Equatable {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int?
    let verseEnd: Int?
    let timestamp: Date

    init(reference: ParsedReference) {
        self.id = UUID()
        self.bookId = reference.book.id
        self.chapter = reference.chapter
        self.verseStart = reference.verseStart
        self.verseEnd = reference.verseEnd
        self.timestamp = Date()
    }

    var location: BibleLocation {
        BibleLocation(bookId: bookId, chapter: chapter, verse: verseStart)
    }

    var reference: ParsedReference? {
        guard let book = Book.find(byId: bookId) else { return nil }
        return ParsedReference(
            book: book,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }

    var displayText: String {
        guard let book = Book.find(byId: bookId) else { return "" }
        if let start = verseStart, let end = verseEnd, start != end {
            return "\(book.name) \(chapter):\(start)-\(end)"
        } else if let verse = verseStart {
            return "\(book.name) \(chapter):\(verse)"
        }
        return "\(book.name) \(chapter)"
    }
}

// MARK: - Preview

#Preview {
    QuickJumpSheet { location in
        print("Navigate to: \(location.reference)")
    }
}
