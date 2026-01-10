import SwiftUI

// MARK: - Search Section
// Full-text search with reference detection and results display
// Uses SearchService for FTS5 search

struct SearchSection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(BibleService.self) private var bibleService
    @Bindable var state: ReadingMenuState
    let onNavigate: ((VerseRange) -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Search Header
            subpageHeader(title: "Search Scripture")

            // Search Bar
            searchBar

            // Search Results
            searchResults
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Subpage Header

    private func subpageHeader(title: String) -> some View {
        HStack {
            // Back button
            Button {
                state.navigateToMenu()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Command.caption.weight(.semibold))
                    Text("Back")
                        .font(Typography.Command.subheadline)
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()

            Text(title)
                .font(Typography.Scripture.body.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.Command.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tertiaryText)

            TextField("John 3:16 or search words...", text: $state.query)
                .font(Typography.Scripture.body)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    performSearch(state.query)
                }
                .onChange(of: state.query) { _, newValue in
                    performSearch(newValue)
                }

            if !state.query.isEmpty {
                Button {
                    state.query = ""
                    state.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResults: some View {
        if state.isSearching {
            // Loading
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                Text("Searching...")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(height: 200)
        } else if state.query.isEmpty {
            // Hints
            searchHints
        } else if let ref = detectedReference {
            // Reference card
            referenceCard(ref)
        } else if !state.results.isEmpty {
            // Results
            resultsList
        } else {
            // No results
            Text("No results for \"\(state.query)\"")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
                .frame(height: 200)
        }
    }

    // MARK: - Search Hints

    private var searchHints: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("QUICK EXAMPLES")
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            HStack(spacing: Theme.Spacing.sm) {
                hintChip("John 3:16")
                hintChip("love")
                hintChip("Rom 8")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hintChip(_ text: String) -> some View {
        Button {
            state.query = text
            performSearch(text)
        } label: {
            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                .clipShape(Capsule())
        }
    }

    // MARK: - Reference Card

    private func referenceCard(_ ref: ParsedReference) -> some View {
        Button {
            let range = VerseRange(
                bookId: ref.book.id,
                chapter: ref.chapter,
                verseStart: ref.verseStart ?? 1,
                verseEnd: ref.verseEnd ?? ref.verseStart ?? 1
            )
            onNavigate?(range)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(Typography.Icon.xl)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go to \(ref.displayText)")
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(Color.primaryText)

                    Text("Jump to this reference")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(Theme.Spacing.md)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(state.results.prefix(5)) { result in
                    Button {
                        onNavigate?(result.verseRange)
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                .fill(result.verse.bookId <= 39 ? Color.navyDeep : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .frame(width: Theme.Stroke.control)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.verse.reference)
                                    .font(Typography.Scripture.footnote.weight(.semibold))
                                    .foregroundStyle(Color.primaryText)

                                Text(result.highlightedSnippet)
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Color.primaryText)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Color.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    }
                    .buttonStyle(.plain)
                }

                if state.results.count > 5 {
                    Text("+ \(state.results.count - 5) more results")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .frame(maxHeight: 300)
    }

    // MARK: - Reference Detection

    private var detectedReference: ParsedReference? {
        guard !state.query.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        if case .success(let ref) = ReferenceParser.parse(state.query) {
            return ref
        }
        return nil
    }

    // MARK: - Search Logic

    private func performSearch(_ query: String) {
        state.searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            state.results = []
            state.isSearching = false
            return
        }

        // Don't search if it's just a reference
        if detectedReference != nil {
            state.results = []
            state.isSearching = false
            return
        }

        state.isSearching = true

        state.searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300)) // Debounce

            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await SearchService.shared.search(
                    query: query,
                    translationId: bibleService.currentTranslationId,
                    limit: 20
                )

                await MainActor.run {
                    state.results = searchResults
                    state.isSearching = false
                }
            } catch {
                await MainActor.run {
                    state.results = []
                    state.isSearching = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var state = ReadingMenuState()

        var body: some View {
            SearchSection(state: state, onNavigate: { range in
                print("Navigate to \(range)")
            })
            .environment(BibleService.shared)
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
