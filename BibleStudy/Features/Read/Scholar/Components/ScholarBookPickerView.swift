import SwiftUI

// MARK: - Scholar Book Picker View
// Two-phase passage selector with Scholar indigo/vellum theme
// Phase 1: Book selection → Phase 2: Chapter selection

struct ScholarBookPickerView: View {
    @Environment(\.dismiss) private var dismiss

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
            ScholarBookSelectionPhase(
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
                ScholarChapterSelectionPhase(
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
            withAnimation(AppTheme.Animation.cardUnfurl.delay(0.1)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - Phase 1: Book Selection

private struct ScholarBookSelectionPhase: View {
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
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(Color.scholarIndigo)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.tertiaryText)

            TextField("Search books...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(Color.primaryText)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    withAnimation(AppTheme.Animation.selection) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(Color.scholarIndigo.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Testament Picker

    private var testamentPicker: some View {
        HStack(spacing: 0) {
            ForEach([Testament.old, Testament.new], id: \.self) { testament in
                Button {
                    withAnimation(AppTheme.Animation.chipExpand) {
                        selectedTestament = testament
                    }
                    HapticService.shared.lightTap()
                } label: {
                    Text(testament == .old ? "Old Testament" : "New Testament")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            selectedTestament == testament
                                ? Color.white
                                : Color.tertiaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm + 2)
                        .background(
                            Group {
                                if selectedTestament == testament {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small - 2)
                                        .fill(Color.scholarIndigo)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(Color.scholarIndigo.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Books Content

    @ViewBuilder
    private var booksContent: some View {
        if searchText.isEmpty {
            LazyVStack(spacing: AppTheme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(categoriesForTestament, id: \.self) { category in
                    Section {
                        bookGrid(for: category)
                    } header: {
                        ScholarCategoryHeader(category: category)
                            .id(category)
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.md)
        } else {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(filteredBooks, id: \.id) { book in
                    ScholarSearchResultRow(
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
                ScholarBookGridItem(
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
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var emptySearchState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.tertiaryText)

            Text("No books found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primaryText)

            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundStyle(Color.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
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

private struct ScholarChapterSelectionPhase: View {
    let book: Book
    let currentBookId: Int
    let currentChapter: Int
    let namespace: Namespace.ID
    let onChapterSelected: (Int) -> Void

    @State private var isAppeared = false
    @State private var selectedChapter: Int = 1

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: AppTheme.Spacing.sm)
    ]

    var body: some View {
        let stickyButtonPadding: CGFloat = 100

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
            withAnimation(AppTheme.Animation.cardUnfurl.delay(0.15)) {
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
                    .fill(Color.scholarIndigo.opacity(0.1))
                    .frame(width: 64, height: 64)

                Text(String(book.name.prefix(1)))
                    .font(CustomFonts.cormorantSemiBold(size: 28))
                    .foregroundStyle(Color.scholarIndigo)
            }
            .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(book.name)
                    .font(CustomFonts.cormorantSemiBold(size: 20))
                    .foregroundStyle(Color.primaryText)

                Text("\(book.chapters) chapters")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.scholarIndigo.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
            ForEach(1...book.chapters, id: \.self) { chapter in
                ScholarChapterCell(
                    chapter: chapter,
                    isSelected: selectedChapter == chapter,
                    isCurrent: book.id == currentBookId && chapter == currentChapter,
                    animationDelay: isAppeared ? Double(chapter) * 0.008 : 0
                ) {
                    HapticService.shared.lightTap()
                    withAnimation(AppTheme.Animation.selection) {
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
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Go to \(book.abbreviation) \(selectedChapter)")
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.scholarIndigo)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Color.appBackground
                .shadow(color: AppTheme.Shadow.elevatedColor, radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Supporting Components

private struct ScholarCategoryHeader: View {
    let category: BookCategory

    var body: some View {
        HStack {
            Text(category.rawValue)
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color.appBackground)
    }
}

private struct ScholarBookGridItem: View {
    let book: Book
    let isCurrent: Bool
    let animationDelay: Double
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isAppeared = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.xs) {
                // Book initial circle
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.scholarIndigo : Color.scholarIndigo.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text(String(book.name.prefix(1)))
                        .font(CustomFonts.cormorantSemiBold(size: 18))
                        .foregroundStyle(isCurrent ? .white : Color.scholarIndigo)
                }
                .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

                // Book name
                Text(book.abbreviation)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isCurrent ? Color.scholarIndigo : Color.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(
                        isCurrent ? Color.scholarIndigo.opacity(0.3) : Color.scholarIndigo.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 10)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(AppTheme.Animation.cardUnfurl.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }
}

private struct ScholarSearchResultRow: View {
    let book: Book
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Book initial
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.scholarIndigo : Color.scholarIndigo.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Text(String(book.name.prefix(1)))
                        .font(CustomFonts.cormorantSemiBold(size: 16))
                        .foregroundStyle(isCurrent ? .white : Color.scholarIndigo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primaryText)

                    Text("\(book.chapters) chapters")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.scholarIndigo)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.scholarIndigo.opacity(0.1))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(Color.scholarIndigo.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ScholarChapterCell: View {
    let chapter: Int
    let isSelected: Bool
    let isCurrent: Bool
    let animationDelay: Double
    let onTap: () -> Void

    @State private var isAppeared = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text("\(chapter)")
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 52, height: 52)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .overlay(borderOverlay)
                .scaleEffect(isPressed ? 0.92 : 1)
                .opacity(isAppeared ? 1 : 0)
                .scaleEffect(isAppeared ? 1 : 0.8)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(AppTheme.Animation.chipExpand.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isCurrent {
            return Color.scholarIndigo
        } else {
            return Color.primaryText
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.scholarIndigo
        } else if isCurrent {
            return Color.scholarIndigo.opacity(0.1)
        } else {
            return Color.surfaceBackground
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .stroke(
                isSelected ? Color.clear : (isCurrent ? Color.scholarIndigo.opacity(0.3) : Color.scholarIndigo.opacity(0.08)),
                lineWidth: 1
            )
    }
}

// MARK: - Preview

#Preview("Scholar Book Picker") {
    ScholarBookPickerView(
        currentBookId: 1,
        currentChapter: 3
    ) { bookId, chapter in
        print("Selected: \(bookId):\(chapter)")
    }
}
