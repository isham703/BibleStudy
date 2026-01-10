import SwiftUI

// MARK: - Bible Chapter Header
// Living Commentary style chapter header with book category, name, and chapter number
// Elegant typography with Cormorant font and decorative elements

struct BibleChapterHeader: View {
    let book: Book?
    let chapter: Int
    let isVisible: Bool

    @Environment(\.colorScheme) private var colorScheme

    // Dynamic Type Support
    @ScaledMetric(relativeTo: .title) private var chapterTitleSize: CGFloat = 52
    @ScaledMetric(relativeTo: .footnote) private var chapterLabelSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var headerLabelSize: CGFloat = 11

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 12) {
            // Book category label (e.g., "THE GOSPEL OF", "THE BOOK OF")
            Text(bookCategoryLabel)
                // swiftlint:disable:next hardcoded_font_system
                .font(.system(size: headerLabelSize, weight: .medium))
                .tracking(3)
                .foregroundStyle(Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.disabled))

            // Book name - large Cormorant font
            Text(book?.name ?? "")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.custom("CormorantGaramond-SemiBold", size: chapterTitleSize))
                .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))

            // Chapter with decorative lines
            // swiftlint:disable:next hardcoded_stack_spacing
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium))
                    .frame(width: 40, height: Theme.Stroke.hairline)

                Text("Chapter \(chapter)")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(.system(size: chapterLabelSize, weight: .semibold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium))
                    .frame(width: 40, height: Theme.Stroke.hairline)
            }
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        Rectangle()
            .fill(Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.subtle))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(isVisible ? 1 : 0)
            .animation(Theme.Animation.settle.delay(0.3), value: isVisible)
    }
}

// MARK: - Preview

#Preview {
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
    .background(Colors.Surface.background(for: .dark))
}
