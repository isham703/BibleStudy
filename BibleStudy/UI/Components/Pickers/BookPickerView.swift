import SwiftUI

// MARK: - Book Picker View
// Two-phase passage selector following iOS navigation patterns
// Phase 1: Book selection → Phase 2: Chapter selection (via navigation push)

struct BookPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let currentBookId: Int
    let currentChapter: Int
    let onSelect: (Int, Int) -> Void

    @State private var selectedTestament: Testament = .old
    @State private var navigationPath = NavigationPath()
    @State private var searchText: String = ""
    @State private var isAppeared = false

    // Animation namespace for matched geometry
    @Namespace private var bookNamespace

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BookSelectionPhase(
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
                ChapterSelectionPhase(
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
            // Start fresh - no pre-selection based on current book
            withAnimation(Theme.Animation.settle.delay(0.1)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Phase 1: Book Selection

private struct BookSelectionPhase: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTestament: Testament
    @Binding var searchText: String
    @Binding var isAppeared: Bool
    let currentBookId: Int
    let namespace: Namespace.ID
    let onBookSelected: (Book) -> Void
    let onDismiss: () -> Void

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
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
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
                } label: {
                    Text(testament == .old ? "Old Testament" : "New Testament")
                        .font(Typography.Command.meta)
                        .foregroundStyle(
                            selectedTestament == testament
                                ? Color.white
                                : Color.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm + 2)
                        .background(
                            Group {
                                if selectedTestament == testament {
                                    RoundedRectangle(cornerRadius: Theme.Radius.button - 2)
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
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Books Content

    @ViewBuilder
    private var booksContent: some View {
        if searchText.isEmpty {
            // Category-grouped view
            LazyVStack(spacing: Theme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(categoriesForTestament, id: \.self) { category in
                    Section {
                        bookGrid(for: category)
                    } header: {
                        CategoryHeader(category: category)
                            .id(category)
                    }
                }
            }
            .padding(.top, Theme.Spacing.md)
        } else {
            // Search results
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(filteredBooks, id: \.id) { book in
                    SearchResultRow(
                        book: book,
                        isCurrent: book.id == currentBookId
                    ) {
                        triggerHaptic()
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
                BookGridItem(
                    book: book,
                    animationDelay: isAppeared ? Double(index) * 0.02 : 0,
                    namespace: namespace
                ) {
                    triggerHaptic()
                    onBookSelected(book)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var emptySearchState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "text.book.closed")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.tertiaryText)

            Text("No books found")
                .font(Typography.Command.headline)
                .foregroundStyle(Color.secondaryText)

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

    private func triggerHaptic() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }
}

// MARK: - Phase 2: Chapter Selection

private struct ChapterSelectionPhase: View {
    @Environment(\.colorScheme) private var colorScheme
    let book: Book
    let currentBookId: Int
    let currentChapter: Int
    let namespace: Namespace.ID
    let onChapterSelected: (Int) -> Void

    @State private var isAppeared = false
    @State private var selectedChapter: Int = 1

    // Responsive grid columns
    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        let stickyButtonPadding = Theme.Spacing.xxl + Theme.Spacing.xxl + Theme.Spacing.lg

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
            .padding(.bottom, stickyButtonPadding) // Space for sticky button
        }
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom) {
            confirmButton
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set initial chapter to current if this is the current book
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
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    .frame(width: 64, height: 64)

                Text(String(book.name.prefix(1)))
                    .font(Typography.Scripture.display)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

            VStack(spacing: Theme.Spacing.xs) {
                Text(book.name)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.primaryText)

                Text("\(book.chapters) chapters • \(book.testament.displayName)")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            // Category badge
            Text(book.category.rawValue)
                .font(Typography.Command.meta)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header with "Read All" option
            HStack {
                Text("SELECT CHAPTER")
                    .font(Typography.Scripture.heading)
                    .tracking(2.5)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                // Read entire book button
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    // Select chapter 1 to start reading entire book
                    onChapterSelected(1)
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "book.pages")
                            .font(Typography.Icon.xxs)
                        Text("Read All")
                            .font(Typography.Command.caption)
                    }
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    )
                }
                .buttonStyle(.plain)
            }

            // Grid
            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(1...book.chapters, id: \.self) { chapter in
                    ChapterGridItem(
                        chapter: chapter,
                        isSelected: selectedChapter == chapter,
                        isCurrent: book.id == currentBookId && chapter == currentChapter,
                        animationDelay: isAppeared ? Double(chapter - 1) * 0.008 : 0
                    ) {
                        selectChapter(chapter)
                    }
                }
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            onChapterSelected(selectedChapter)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Go to \(book.abbreviation) \(selectedChapter)")
                    .font(Typography.Command.cta)

                Image(systemName: "arrow.right")
                    .font(Typography.Icon.sm)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .shadow(
                        color: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(ConfirmButtonStyle())
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    private func selectChapter(_ chapter: Int) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        withAnimation(Theme.Animation.fade) {
            selectedChapter = chapter
        }
    }
}

// MARK: - Category Header

private struct CategoryHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let category: BookCategory

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20, height: Theme.Stroke.hairline)

            Text(category.rawValue.uppercased())
                .font(Typography.Command.label)
                .tracking(2.5)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Color.appBackground.opacity(Theme.Opacity.nearOpaque))
    }
}

// MARK: - Book Grid Item

private struct BookGridItem: View {
    let book: Book
    let animationDelay: Double
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isAppeared = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(book.abbreviation)
                    .font(Typography.Command.headline)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(book.chapters) ch")
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(GridItemButtonStyle())
        .opacity(isAppeared ? 1 : 0)
        .offset(y: isAppeared ? 0 : 8)
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Chapter Grid Item

private struct ChapterGridItem: View {
    @Environment(\.colorScheme) private var colorScheme
    let chapter: Int
    let isSelected: Bool
    let isCurrent: Bool
    let animationDelay: Double
    let action: () -> Void

    @State private var isAppeared = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                Circle()
                    .fill(backgroundColor)
                    .shadow(
                        color: isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.quarter) : .clear,
                        radius: 6,
                        x: 0,
                        y: 2
                    )

                // Border for unselected
                if !isSelected {
                    Circle()
                        .stroke(
                            isCurrent ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.cardBorder,
                            lineWidth: isCurrent ? Theme.Stroke.control : Theme.Stroke.hairline
                        )
                }

                // Chapter number
                Text("\(chapter)")
                    .font(Typography.Command.body.monospacedDigit())
                    .foregroundStyle(isSelected ? .white : Color.primaryText)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(GridItemButtonStyle())
        .opacity(isAppeared ? 1 : 0)
        .scaleEffect(isAppeared ? 1 : 0.85)
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        } else {
            return Color.surfaceBackground
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let book: Book
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Book initial
                ZStack {
                    Circle()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                        .frame(width: 40, height: 40)

                    Text(String(book.name.prefix(1)))
                        .font(Typography.Scripture.title)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }

                // Book info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(book.name)
                            .font(Typography.Command.headline)
                            .foregroundStyle(Color.primaryText)

                        if isCurrent {
                            Text("Current")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                                )
                        }
                    }

                    Text("\(book.chapters) chapters • \(book.category.rawValue)")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Button Styles

private struct GridItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

private struct ConfirmButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Public Book Button (for use in ContentsSheet)

struct BookButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let book: Book
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(book.abbreviation)
                    .font(Typography.Command.headline)
                    .foregroundStyle(isSelected ? .white : Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(book.chapters) ch")
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(isSelected ? .white.opacity(Theme.Opacity.pressed) : Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(GridItemButtonStyle())
    }
}

// MARK: - Public Chapter Button (for use in ContentsSheet)

struct ChapterButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let chapter: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(chapter)")
                .font(Typography.Command.body.monospacedDigit())
                .foregroundStyle(isSelected ? .white : Color.primaryText)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.surfaceBackground)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
                )
        }
        .buttonStyle(GridItemButtonStyle())
    }
}

// MARK: - Preview

#Preview("Book Picker") {
    BookPickerView(
        currentBookId: 1,
        currentChapter: 3
    ) { bookId, chapter in
        print("Selected: \(bookId):\(chapter)")
    }
}

#Preview("Chapter Selection") {
    NavigationStack {
        ChapterSelectionPhase(
            book: Book.genesis,
            currentBookId: 1,
            currentChapter: 3,
            namespace: Namespace().wrappedValue,
            onChapterSelected: { chapter in
                print("Selected chapter: \(chapter)")
            }
        )
    }
}
