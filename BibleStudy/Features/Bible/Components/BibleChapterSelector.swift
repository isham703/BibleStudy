import SwiftUI

// MARK: - Bible Chapter Selector
// A clearly tappable chapter selector for the Bible reader toolbar
// Design: Pill-shaped button with book + chapter and dropdown indicator
// Provides clear visual affordance that it's interactive

struct BibleChapterSelector: View {
    let reference: String
    let bookName: String
    let chapter: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.xs) {
                // Book icon
                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                // Reference text
                Text(reference)
                    .font(Typography.Command.meta.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                // Dropdown chevron - the key affordance
                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(selectorBackground)
            .clipShape(Capsule())
            .overlay(selectorBorder)
            // swiftlint:disable:next hardcoded_scale_effect
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Select chapter")
        .accessibilityHint("Currently reading \(bookName) chapter \(chapter). Double tap to change book or chapter.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Background

    private var selectorBackground: some View {
        Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
    }

    // MARK: - Border

    private var selectorBorder: some View {
        Capsule()
            .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.tertiary), lineWidth: Theme.Stroke.hairline)
    }
}

// MARK: - Alternative Compact Style

/// A more minimal chapter selector for constrained spaces
struct BibleChapterSelectorCompact: View {
    let reference: String
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Text(reference)
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxxs.weight(.bold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
            .clipShape(Capsule())
            // swiftlint:disable:next hardcoded_scale_effect
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Chapter Selector") {
    VStack(spacing: Theme.Spacing.xxl) {
        // Standard style
        VStack(spacing: Theme.Spacing.sm) {
            Text("Standard")
                // swiftlint:disable:next hardcoded_swiftui_text_style
                .font(.caption)
                .foregroundStyle(.secondary)

            BibleChapterSelector(
                reference: "Gen 1",
                bookName: "Genesis",
                chapter: 1
            ) {
                print("Tapped")
            }
        }

        // Different references
        VStack(spacing: Theme.Spacing.sm) {
            Text("Various Books")
                // swiftlint:disable:next hardcoded_swiftui_text_style
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.lg) {
                BibleChapterSelector(
                    reference: "Ps 119",
                    bookName: "Psalms",
                    chapter: 119
                ) {}

                BibleChapterSelector(
                    reference: "Matt 5",
                    bookName: "Matthew",
                    chapter: 5
                ) {}

                BibleChapterSelector(
                    reference: "Rev 22",
                    bookName: "Revelation",
                    chapter: 22
                ) {}
            }
        }

        // Compact style
        VStack(spacing: Theme.Spacing.sm) {
            Text("Compact")
                // swiftlint:disable:next hardcoded_swiftui_text_style
                .font(.caption)
                .foregroundStyle(.secondary)

            BibleChapterSelectorCompact(
                reference: "John 3"
            ) {
                print("Tapped compact")
            }
        }

        // In context (simulated toolbar)
        VStack(spacing: Theme.Spacing.sm) {
            Text("In Toolbar Context")
                // swiftlint:disable:next hardcoded_swiftui_text_style
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()

                BibleChapterSelector(
                    reference: "Eph 2",
                    bookName: "Ephesians",
                    chapter: 2
                ) {}

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Icon.sm)
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.sm)
                }
                .foregroundStyle(Color.primary.opacity(Theme.Opacity.overlay))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Color.appBackground)
        }
    }
    .padding()
    .background(Color.appBackground)
}
