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
            withAnimation(ScholarPalette.Animation.cardUnfurl.delay(0.1)) {
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
                    .padding(.horizontal, ScholarPalette.Spacing.lg)
                    .padding(.top, ScholarPalette.Spacing.sm)

                // Testament toggle
                testamentPicker
                    .padding(.horizontal, ScholarPalette.Spacing.lg)
                    .padding(.top, ScholarPalette.Spacing.md)

                // Books content
                booksContent
                    .padding(.bottom, ScholarPalette.Spacing.xxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ScholarPalette.vellum)
        .navigationTitle("Select Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ScholarPalette.vellum, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(ScholarPalette.accent)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: ScholarPalette.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ScholarPalette.footnote)

            TextField("Search books...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(ScholarPalette.ink)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    withAnimation(ScholarPalette.Animation.selection) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ScholarPalette.footnote)
                }
            }
        }
        .padding(.horizontal, ScholarPalette.Spacing.md)
        .padding(.vertical, ScholarPalette.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                .stroke(ScholarPalette.accent.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Testament Picker

    private var testamentPicker: some View {
        HStack(spacing: 0) {
            ForEach([Testament.old, Testament.new], id: \.self) { testament in
                Button {
                    withAnimation(ScholarPalette.Animation.chipExpand) {
                        selectedTestament = testament
                    }
                    HapticService.shared.lightTap()
                } label: {
                    Text(testament == .old ? "Old Testament" : "New Testament")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            selectedTestament == testament
                                ? Color.white
                                : ScholarPalette.footnote
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScholarPalette.Spacing.sm + 2)
                        .background(
                            Group {
                                if selectedTestament == testament {
                                    RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small - 2)
                                        .fill(ScholarPalette.accent)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ScholarPalette.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                .stroke(ScholarPalette.accent.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Books Content

    @ViewBuilder
    private var booksContent: some View {
        if searchText.isEmpty {
            LazyVStack(spacing: ScholarPalette.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(categoriesForTestament, id: \.self) { category in
                    Section {
                        bookGrid(for: category)
                    } header: {
                        ScholarCategoryHeader(category: category)
                            .id(category)
                    }
                }
            }
            .padding(.top, ScholarPalette.Spacing.md)
        } else {
            LazyVStack(spacing: ScholarPalette.Spacing.sm) {
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
            .padding(.horizontal, ScholarPalette.Spacing.lg)
            .padding(.top, ScholarPalette.Spacing.md)
        }
    }

    private func bookGrid(for category: BookCategory) -> some View {
        let books = Book.books(inCategory: category)
        let columns = [
            GridItem(.adaptive(minimum: 95, maximum: 110), spacing: ScholarPalette.Spacing.sm)
        ]

        return LazyVGrid(columns: columns, spacing: ScholarPalette.Spacing.sm) {
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
        .padding(.horizontal, ScholarPalette.Spacing.lg)
    }

    private var emptySearchState: some View {
        VStack(spacing: ScholarPalette.Spacing.md) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ScholarPalette.footnote)

            Text("No books found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ScholarPalette.ink)

            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundStyle(ScholarPalette.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ScholarPalette.Spacing.xxl)
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
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: ScholarPalette.Spacing.sm)
    ]

    var body: some View {
        let stickyButtonPadding: CGFloat = 100

        ScrollView {
            VStack(spacing: ScholarPalette.Spacing.xl) {
                // Book header card
                bookHeader
                    .padding(.horizontal, ScholarPalette.Spacing.lg)
                    .padding(.top, ScholarPalette.Spacing.md)

                // Chapter grid
                chapterGrid
                    .padding(.horizontal, ScholarPalette.Spacing.lg)
            }
            .padding(.bottom, stickyButtonPadding)
        }
        .background(ScholarPalette.vellum)
        .safeAreaInset(edge: .bottom) {
            confirmButton
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ScholarPalette.vellum, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if book.id == currentBookId {
                selectedChapter = currentChapter
            }
            withAnimation(ScholarPalette.Animation.cardUnfurl.delay(0.15)) {
                isAppeared = true
            }
        }
    }

    // MARK: - Book Header

    private var bookHeader: some View {
        VStack(spacing: ScholarPalette.Spacing.md) {
            // Book icon/initial
            ZStack {
                Circle()
                    .fill(ScholarPalette.accentSubtle)
                    .frame(width: 64, height: 64)

                Text(String(book.name.prefix(1)))
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(ScholarPalette.accent)
            }
            .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

            VStack(spacing: ScholarPalette.Spacing.xs) {
                Text(book.name)
                    .font(.custom("CormorantGaramond-SemiBold", size: 20))
                    .foregroundStyle(ScholarPalette.ink)

                Text("\(book.chapters) chapters")
                    .font(.system(size: 13))
                    .foregroundStyle(ScholarPalette.footnote)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ScholarPalette.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.card)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.card)
                .stroke(ScholarPalette.accent.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Chapter Grid

    private var chapterGrid: some View {
        LazyVGrid(columns: columns, spacing: ScholarPalette.Spacing.sm) {
            ForEach(1...book.chapters, id: \.self) { chapter in
                ScholarChapterCell(
                    chapter: chapter,
                    isSelected: selectedChapter == chapter,
                    isCurrent: book.id == currentBookId && chapter == currentChapter,
                    animationDelay: isAppeared ? Double(chapter) * 0.008 : 0
                ) {
                    HapticService.shared.lightTap()
                    withAnimation(ScholarPalette.Animation.selection) {
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
            HStack(spacing: ScholarPalette.Spacing.sm) {
                Text("Go to \(book.abbreviation) \(selectedChapter)")
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScholarPalette.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.card)
                    .fill(ScholarPalette.accent)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ScholarPalette.Spacing.lg)
        .padding(.vertical, ScholarPalette.Spacing.md)
        .background(
            ScholarPalette.vellum
                .shadow(color: ScholarPalette.Shadow.elevated, radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Supporting Components

private struct ScholarCategoryHeader: View {
    let category: BookCategory

    var body: some View {
        HStack {
            Text(category.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(ScholarPalette.accent)

            Spacer()
        }
        .padding(.horizontal, ScholarPalette.Spacing.lg)
        .padding(.vertical, ScholarPalette.Spacing.sm)
        .background(ScholarPalette.vellum)
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
            VStack(spacing: ScholarPalette.Spacing.xs) {
                // Book initial circle
                ZStack {
                    Circle()
                        .fill(isCurrent ? ScholarPalette.accent : ScholarPalette.accentSubtle)
                        .frame(width: 44, height: 44)

                    Text(String(book.name.prefix(1)))
                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
                        .foregroundStyle(isCurrent ? .white : ScholarPalette.accent)
                }
                .matchedGeometryEffect(id: "book-\(book.id)", in: namespace)

                // Book name
                Text(book.abbreviation)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isCurrent ? ScholarPalette.accent : ScholarPalette.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScholarPalette.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                    .stroke(
                        isCurrent ? ScholarPalette.accent.opacity(0.3) : ScholarPalette.accent.opacity(0.08),
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
            withAnimation(ScholarPalette.Animation.cardUnfurl.delay(animationDelay)) {
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
            HStack(spacing: ScholarPalette.Spacing.md) {
                // Book initial
                ZStack {
                    Circle()
                        .fill(isCurrent ? ScholarPalette.accent : ScholarPalette.accentSubtle)
                        .frame(width: 36, height: 36)

                    Text(String(book.name.prefix(1)))
                        .font(.custom("CormorantGaramond-SemiBold", size: 16))
                        .foregroundStyle(isCurrent ? .white : ScholarPalette.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ScholarPalette.ink)

                    Text("\(book.chapters) chapters")
                        .font(.system(size: 12))
                        .foregroundStyle(ScholarPalette.footnote)
                }

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ScholarPalette.accent)
                        .padding(.horizontal, ScholarPalette.Spacing.sm)
                        .padding(.vertical, ScholarPalette.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(ScholarPalette.accentSubtle)
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ScholarPalette.footnote)
            }
            .padding(ScholarPalette.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                    .stroke(ScholarPalette.accent.opacity(0.08), lineWidth: 1)
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
                .clipShape(RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small))
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
            withAnimation(ScholarPalette.Animation.chipExpand.delay(animationDelay)) {
                isAppeared = true
            }
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isCurrent {
            return ScholarPalette.accent
        } else {
            return ScholarPalette.ink
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ScholarPalette.accent
        } else if isCurrent {
            return ScholarPalette.accentSubtle
        } else {
            return Color.white
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
            .stroke(
                isSelected ? Color.clear : (isCurrent ? ScholarPalette.accent.opacity(0.3) : ScholarPalette.accent.opacity(0.08)),
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
