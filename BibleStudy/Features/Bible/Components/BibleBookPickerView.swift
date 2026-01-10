import SwiftUI

// MARK: - Bible Book Picker View
// Two-phase passage selector with Bible indigo/vellum theme
// Phase 1: Book selection → Phase 2: Chapter selection

struct BibleBookPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let currentBookId: Int
    let currentChapter: Int
    let onSelect: (Int, Int) -> Void

    @State private var selectedTestament: Testament = .old
    @State private var navigationPath = NavigationPath()
    @State private var searchText: String = ""
    @State private var isAppeared = false

    @Namespace private var bookNamespace

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BibleBookSelectionPhase(
                selectedTestament: $selectedTestament,
                searchText: $searchText,
                isAppeared: $isAppeared,
                currentBookId: currentBookId,
                namespace: bookNamespace,
                onBookSelected: { book in
                    navigationPath.append(book)
                },
                onDismiss: { dismiss() }
            )
            .navigationDestination(for: Book.self) { book in
                BibleChapterSelectionPhase(
                    book: book,
                    currentBookId: currentBookId,
                    currentChapter: currentChapter,
                    namespace: bookNamespace,
                    onChapterSelected: { chapter in
                        onSelect(book.id, chapter)
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(0.1)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Phase 1: Book Selection

private struct BibleBookSelectionPhase: View {
    @Binding var selectedTestament: Testament
    @Binding var searchText: String
    @Binding var isAppeared: Bool
    let currentBookId: Int
    let namespace: Namespace.ID
    let onBookSelected: (Book) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                // Testament toggle
                testamentPicker
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                // Books content
                booksContent
                    .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .navigationTitle("Select Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color.tertiaryText)

            TextField("Search books...", text: $searchText)
                .font(Typography.Command.body)
                .foregroundStyle(Color.primaryText)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    withAnimation(Theme.Animation.fade) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Testament Picker

    private var testamentPicker: some View {
        HStack(spacing: 0) {
            ForEach([Testament.old, Testament.new], id: \.self) { testament in
                Button {
                    withAnimation(Theme.Animation.settle) {
                        selectedTestament = testament
                    }
                    HapticService.shared.lightTap()
                } label: {
                    Text(testament == .old ? "Old Testament" : "New Testament")
                        .font(Typography.Command.caption.weight(.medium))
                        .foregroundStyle(
                            selectedTestament == testament
                                ? Color.white
                                : Color.tertiaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm + 2)
                        .background(
                            Group {
                                if selectedTestament == testament {
                                    RoundedRectangle(cornerRadius: Theme.Radius.input - 2)
                                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Books Content

    @ViewBuilder
    private var booksContent: some View {
        if searchText.isEmpty {
            LazyVStack(spacing: Theme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(categoriesForTestament, id: \.self) { category in
                    Section {
                        bookGrid(for: category)
                    } header: {
                        BibleCategoryHeader(category: category)
                            .id(category)
                    }
                }
            }
            .padding(.top, Theme.Spacing.md)
        } else {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(filteredBooks, id: \.id) { book in
                    BibleSearchResultRow(
                        book: book,
                        isCurrent: book.id == currentBookId
                    ) {
                        HapticService.shared.lightTap()
                        onBookSelected(book)
                    }
                }

                if filteredBooks.isEmpty {
                    emptySearchState
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
    }

    private func bookGrid(for category: BookCategory) -> some View {
        let books = Book.books(inCategory: category)
        let columns = [
            GridItem(.adaptive(minimum: 95, maximum: 110), spacing: Theme.Spacing.sm)
        ]

        return LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                BibleBookGridItem(
                    book: book,
                    isCurrent: book.id == currentBookId,
                    animationDelay: isAppeared ? Double(index) * 0.02 : 0,
                    namespace: namespace
                ) {
                    HapticService.shared.lightTap()
                    onBookSelected(book)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var emptySearchState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "text.book.closed")
                .font(Typography.Icon.xxl.weight(.light))
                .foregroundStyle(Color.tertiaryText)

            Text("No books found")
                .font(Typography.Command.callout.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Text("Try a different search term")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }

    // MARK: - Computed Properties

    private var categoriesForTestament: [BookCategory] {
        switch selectedTestament {
        case .old:
            return [.pentateuch, .historical, .wisdom, .prophets, .theTwelve]
        case .new:
            return [.gospels, .acts, .paulineEpistles, .generalEpistles, .revelation]
        }
    }

    private var filteredBooks: [Book] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return Book.all.filter { book in
            book.name.lowercased().contains(query) ||
            book.abbreviation.lowercased().contains(query)
        }
    }
}

// MARK: - Phase 2: Chapter Selection

private struct BibleChapterSelectionPhase: View {
    let book: Book
    let currentBookId: Int
    let currentChapter: Int
    let namespace: Namespace.ID
    let onChapterSelected: (Int) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAppeared = false
    @State private var selectedChapter: Int = 1

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        let stickyButtonPadding: CGFloat = 100

        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Book header card
                bookHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                // Chapter grid
                chapterGrid
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.bottom, stickyButtonPadding)
        }
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom) {
            confirmButton
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if book.id == currentBookId {
                selectedChapter = currentChapter
            }
            withAnimation(Theme.Animation.settle.delay(0.15)) {
                isAppeared = true
            }
        }
    }

    // MARK: - Book Header

    private var bookHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Book icon/initial
            ZStack {
                Circle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                    .frame(width: 64, height: 64)

                Text(String(book.name.prefix(1)))
                    .font(Typography.Scripture.title)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

            VStack(spacing: Theme.Spacing.xs) {
                Text(book.name)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.primaryText)

                Text("\(book.chapters) chapters")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(1...book.chapters, id: \.self) { chapter in
                BibleChapterCell(
                    chapter: chapter,
                    isSelected: selectedChapter == chapter,
                    isCurrent: book.id == currentBookId && chapter == currentChapter,
                    animationDelay: isAppeared ? Double(chapter) * 0.008 : 0
                ) {
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.fade) {
                        selectedChapter = chapter
                    }
                }
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            HapticService.shared.mediumTap()
            onChapterSelected(selectedChapter)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Go to \(book.abbreviation) \(selectedChapter)")
                    .font(Typography.Command.callout.weight(.semibold))

                Image(systemName: "arrow.right")
                    .font(Typography.Icon.sm.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Color.appBackground
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Supporting Components

private struct BibleCategoryHeader: View {
    let category: BookCategory

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(category.rawValue)
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.appBackground)
    }
}

private struct BibleBookGridItem: View {
    let book: Book
    let isCurrent: Bool
    let animationDelay: Double
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAppeared = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.xs) {
                // Book initial circle
                ZStack {
                    Circle()
                        .fill(isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                        .frame(width: 44, height: 44)

                    Text(String(book.name.prefix(1)))
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(isCurrent ? .white : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
                .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

                // Book name
                Text(book.abbreviation)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(
                        isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium) : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 10)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }
}

private struct BibleSearchResultRow: View {
    let book: Book
    let isCurrent: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Book initial
                ZStack {
                    Circle()
                        .fill(isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                        .frame(width: 36, height: 36)

                    Text(String(book.name.prefix(1)))
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(isCurrent ? .white : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.name)
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color.primaryText)

                    Text("\(book.chapters) chapters")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(Typography.Command.meta.weight(.medium))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct BibleChapterCell: View {
    let chapter: Int
    let isSelected: Bool
    let isCurrent: Bool
    let animationDelay: Double
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAppeared = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text("\(chapter)")
                .font(Typography.Command.callout.weight(isSelected ? .bold : .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 52, height: 52)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                .overlay(borderOverlay)
                .scaleEffect(isPressed ? 0.92 : 1)
                .opacity(isAppeared ? 1 : 0)
                .scaleEffect(isAppeared ? 1 : 0.8)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isCurrent {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        } else {
            return Color.primaryText
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        } else if isCurrent {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle)
        } else {
            return Color.surfaceBackground
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .stroke(
                isSelected ? Color.clear : (isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium) : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)),
                lineWidth: Theme.Stroke.hairline
            )
    }
}

// MARK: - Preview

#Preview("Bible Book Picker") {
    BibleBookPickerView(
        currentBookId: 1,
        currentChapter: 3
    ) { bookId, chapter in
        print("Selected: \(bookId):\(chapter)")
    }
}
