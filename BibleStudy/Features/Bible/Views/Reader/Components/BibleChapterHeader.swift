import SwiftUI

// MARK: - Bible Chapter Header
// Living Commentary style chapter header with book category, name, and chapter number
// Typography: Cormorant for book title (deliberate exception), system tokens for everything else

struct BibleChapterHeader: View {
    let book: Book?
    let chapter: Int
    let isVisible: Bool

    @Environment(\.colorScheme) private var colorScheme

    // Dynamic Type Support with clamping
    // Base: 52pt, Min: 40pt (small text), Max: 72pt (prevents AX5 overflow)
    // Rationale: Long names like "1 Thessalonians" need room; huge sizes break layout
    @ScaledMetric(relativeTo: .title) private var scaledTitleSize: CGFloat = Typography.TitlePage.bookTitleBaseSize

    /// Clamped book title size - prevents runaway scaling at accessibility sizes
    private var bookTitleSize: CGFloat {
        min(max(scaledTitleSize, 40), 72)
    }

    var body: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 12) {
            // Book category label (e.g., "THE GOSPEL OF", "THE BOOK OF")
            // Uses Editorial token: tracked uppercase, tertiary contrast
            Text(bookCategoryLabel)
                .editorialSectionHeader()
                .foregroundStyle(Color("TertiaryText"))

            // Book name - Cormorant Garamond (deliberate exception for title page ceremony)
            // See Typography.TitlePage documentation for rationale
            //
            // Fallback hierarchy (in order of preference):
            // 1. Single line at full size (most names)
            // 2. Two-line wrap with controlled leading (long names at AX sizes)
            // 3. Slight scale down to 0.85 (rare edge cases)
            // Never shrink below 0.85 - preserves title-page gravitas + accessibility intent
            Text(book?.name ?? "")
                .titlePageBookTitle(size: bookTitleSize)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("AppTextPrimary"))

            // Chapter label - sans metadata, medium weight (secondary tier)
            // Keeps "Chapter" as navigation metadata, not competing with book title
            Text("Chapter \(chapter)")
                .commandLabel()
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(Theme.Animation.settle.delay(0.2), value: isVisible)
    }

    // MARK: - Book Category Label

    private var bookCategoryLabel: String {
        guard let book = book else { return "THE BOOK OF" }

        switch book.category {
        case .gospels:
            return "THE GOSPEL OF"
        case .paulineEpistles:
            return "THE EPISTLE OF PAUL TO THE"
        case .generalEpistles:
            return "THE EPISTLE OF"
        case .revelation:
            return "THE BOOK OF"
        case .pentateuch:
            return "THE BOOK OF"
        case .historical:
            return "THE BOOK OF"
        case .wisdom:
            return "THE BOOK OF"
        case .prophets:
            return "THE BOOK OF"
        case .theTwelve:
            return "THE BOOK OF"
        case .acts:
            return "THE BOOK OF"
        }
    }
}

// MARK: - Editorial Divider

struct BibleEditorialDivider: View {
    let isVisible: Bool

    var body: some View {
        Rectangle()
            .fill(Color("AppTextPrimary").opacity(Theme.Opacity.subtle))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(isVisible ? 1 : 0)
            .animation(Theme.Animation.fade, value: isVisible)
    }
}

// MARK: - Preview

#Preview("Standard Names") {
    VStack(spacing: Theme.Spacing.xl) {
        BibleChapterHeader(
            book: Book.find(byId: 43), // John
            chapter: 1,
            isVisible: true
        )

        BibleEditorialDivider(isVisible: true)

        BibleChapterHeader(
            book: Book.find(byId: 1), // Genesis
            chapter: 1,
            isVisible: true
        )
    }
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Long Names (Edge Cases)") {
    VStack(spacing: Theme.Spacing.xl) {
        // Longest book names - tests 2-line wrap
        BibleChapterHeader(
            book: Book.find(byId: 52), // 1 Thessalonians
            chapter: 1,
            isVisible: true
        )

        BibleEditorialDivider(isVisible: true)

        BibleChapterHeader(
            book: Book.find(byId: 22), // Song of Solomon
            chapter: 2,
            isVisible: true
        )
    }
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Accessibility Large (AX3)") {
    VStack(spacing: Theme.Spacing.xl) {
        // Tests 2-line wrap behavior at accessibility sizes
        BibleChapterHeader(
            book: Book.find(byId: 52), // 1 Thessalonians
            chapter: 1,
            isVisible: true
        )

        BibleEditorialDivider(isVisible: true)

        BibleChapterHeader(
            book: Book.find(byId: 5), // Deuteronomy (wide forms)
            chapter: 1,
            isVisible: true
        )
    }
    .padding()
    .background(Color("AppBackground"))
    .environment(\.dynamicTypeSize, .accessibility3)
}
