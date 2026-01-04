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
            withAnimation(AppTheme.Animation.unfurl.delay(0.1)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Phase 1: Book Selection

private struct BookSelectionPhase: View {
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
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.sm)

                // Testament toggle
                testamentPicker
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Books content
                booksContent
                    .padding(.bottom, AppTheme.Spacing.xxl)
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
                .foregroundStyle(Color.accentGold)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.UI.iconSm)
                .foregroundStyle(Color.tertiaryText)

            TextField("Search books...", text: $searchText)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.UI.iconSm)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }

    // MARK: - Testament Picker

    private var testamentPicker: some View {
        HStack(spacing: 0) {
            ForEach([Testament.old, Testament.new], id: \.self) { testament in
                Button {
                    withAnimation(AppTheme.Animation.sacredSpring) {
                        selectedTestament = testament
                    }
                } label: {
                    Text(testament == .old ? "Old Testament" : "New Testament")
                        .font(Typography.UI.chipLabel)
                        .foregroundStyle(
                            selectedTestament == testament
                                ? Color.white
                                : Color.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm + 2)
                        .background(
                            Group {
                                if selectedTestament == testament {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium - 2)
                                        .fill(Color.accentGold)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }

    // MARK: - Books Content

    @ViewBuilder
    private var booksContent: some View {
        if searchText.isEmpty {
            // Category-grouped view
            LazyVStack(spacing: AppTheme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(categoriesForTestament, id: \.self) { category in
                    Section {
                        bookGrid(for: category)
                    } header: {
                        CategoryHeader(category: category)
                            .id(category)
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.md)
        } else {
            // Search results
            LazyVStack(spacing: AppTheme.Spacing.sm) {
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
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)
        }
    }

    private func bookGrid(for category: BookCategory) -> some View {
        let books = Book.books(inCategory: category)
        let columns = [
            GridItem(.adaptive(minimum: 95, maximum: 110), spacing: AppTheme.Spacing.sm)
        ]

        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
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
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var emptySearchState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "text.book.closed")
                .font(Typography.UI.iconXxl)
                .foregroundStyle(Color.tertiaryText)

            Text("No books found")
                .font(Typography.UI.headline)
                .foregroundStyle(Color.secondaryText)

            Text("Try a different search term")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxl)
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
    let book: Book
    let currentBookId: Int
    let currentChapter: Int
    let namespace: Namespace.ID
    let onChapterSelected: (Int) -> Void

    @State private var isAppeared = false
    @State private var selectedChapter: Int = 1

    // Responsive grid columns
    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: AppTheme.Spacing.sm)
    ]

    var body: some View {
        let stickyButtonPadding = AppTheme.Spacing.xxxl + AppTheme.Spacing.xxl + AppTheme.Spacing.lg

        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Book header card
                bookHeader
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Chapter grid
                chapterGrid
                    .padding(.horizontal, AppTheme.Spacing.lg)
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
            withAnimation(AppTheme.Animation.sacredSpring.delay(0.15)) {
                isAppeared = true
            }
        }
    }

    // MARK: - Book Header

    private var bookHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Book icon/initial
            ZStack {
                Circle()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                    .frame(width: 64, height: 64)

                Text(String(book.name.prefix(1)))
                    .font(Typography.Codex.bookInitial)
                    .foregroundStyle(Color.accentGold)
            }
            .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(book.name)
                    .font(Typography.Codex.verseReference)
                    .foregroundStyle(Color.primaryText)

                Text("\(book.chapters) chapters • \(book.testament.displayName)")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
            }

            // Category badge
            Text(book.category.rawValue)
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.accentGold)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header with "Read All" option
            HStack {
                Text("SELECT CHAPTER")
                    .font(Typography.Codex.illuminatedHeader)
                    .tracking(Typography.Codex.headerTracking)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                // Read entire book button
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    // Select chapter 1 to start reading entire book
                    onChapterSelected(1)
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "book.pages")
                            .font(Typography.UI.iconXxs)
                        Text("Read All")
                            .font(Typography.UI.caption1)
                    }
                    .foregroundStyle(Color.accentGold)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                    )
                }
                .buttonStyle(.plain)
            }

            // Grid
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
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
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Go to \(book.abbreviation) \(selectedChapter)")
                    .font(Typography.UI.buttonLabel)

                Image(systemName: "arrow.right")
                    .font(Typography.UI.iconSm)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.accentGold)
                    .shadow(
                        color: Color.accentGold.opacity(AppTheme.Opacity.medium),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(ConfirmButtonStyle())
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    private func selectChapter(_ chapter: Int) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        withAnimation(AppTheme.Animation.quick) {
            selectedChapter = chapter
        }
    }
}

// MARK: - Category Header

private struct CategoryHeader: View {
    let category: BookCategory

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.accentGold.opacity(AppTheme.Opacity.disabled)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20, height: AppTheme.Divider.thin)

            Text(category.rawValue.uppercased())
                .font(Typography.Codex.sectionLabel)
                .tracking(Typography.Codex.headerTracking)
                .foregroundStyle(Color.accentGold.opacity(AppTheme.Opacity.pressed))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentGold.opacity(AppTheme.Opacity.disabled), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Color.appBackground.opacity(AppTheme.Opacity.nearOpaque))
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
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(book.abbreviation)
                    .font(Typography.UI.headline)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(book.chapters) ch")
                    .font(Typography.UI.caption2.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(GridItemButtonStyle())
        .opacity(isAppeared ? 1 : 0)
        .offset(y: isAppeared ? 0 : 8)
        .onAppear {
            withAnimation(AppTheme.Animation.sacredSpring.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Chapter Grid Item

private struct ChapterGridItem: View {
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
                        color: isSelected ? Color.accentGold.opacity(AppTheme.Opacity.quarter) : .clear,
                        radius: 6,
                        x: 0,
                        y: 2
                    )

                // Border for unselected
                if !isSelected {
                    Circle()
                        .stroke(
                            isCurrent ? Color.accentGold : Color.cardBorder,
                            lineWidth: isCurrent ? AppTheme.Border.medium : AppTheme.Border.thin
                        )
                }

                // Chapter number
                Text("\(chapter)")
                    .font(Typography.UI.body.monospacedDigit())
                    .foregroundStyle(isSelected ? .white : Color.primaryText)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(GridItemButtonStyle())
        .opacity(isAppeared ? 1 : 0)
        .scaleEffect(isAppeared ? 1 : 0.85)
        .onAppear {
            withAnimation(AppTheme.Animation.sacredSpring.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentGold
        } else {
            return Color.surfaceBackground
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let book: Book
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Book initial
                ZStack {
                    Circle()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                        .frame(width: 40, height: 40)

                    Text(String(book.name.prefix(1)))
                        .font(Typography.Codex.inlineInitial)
                        .foregroundStyle(Color.accentGold)
                }

                // Book info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(book.name)
                            .font(Typography.UI.headline)
                            .foregroundStyle(Color.primaryText)

                        if isCurrent {
                            Text("Current")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.accentGold)
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                                )
                        }
                    }

                    Text("\(book.chapters) chapters • \(book.category.rawValue)")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXxs)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

private struct ConfirmButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Public Book Button (for use in ContentsSheet)

struct BookButton: View {
    let book: Book
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(book.abbreviation)
                    .font(Typography.UI.headline)
                    .foregroundStyle(isSelected ? .white : Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(book.chapters) ch")
                    .font(Typography.UI.caption2.monospacedDigit())
                    .foregroundStyle(isSelected ? .white.opacity(AppTheme.Opacity.pressed) : Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? Color.accentGold : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(GridItemButtonStyle())
    }
}

// MARK: - Public Chapter Button (for use in ContentsSheet)

struct ChapterButton: View {
    let chapter: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(chapter)")
                .font(Typography.UI.body.monospacedDigit())
                .foregroundStyle(isSelected ? .white : Color.primaryText)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentGold : Color.surfaceBackground)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
