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

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.xs) {
                // Book icon
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.scholarIndigo)

                // Reference text
                Text(reference)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText)

                // Dropdown chevron - the key affordance
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.scholarIndigo)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(selectorBackground)
            .clipShape(Capsule())
            .overlay(selectorBorder)
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Select chapter")
        .accessibilityHint("Currently reading \(bookName) chapter \(chapter). Double tap to change book or chapter.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Background

    private var selectorBackground: some View {
        Color.scholarIndigo.opacity(0.1)
    }

    // MARK: - Border

    private var selectorBorder: some View {
        Capsule()
            .stroke(Color.scholarIndigo.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Alternative Compact Style

/// A more minimal chapter selector for constrained spaces
struct BibleChapterSelectorCompact: View {
    let reference: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Text(reference)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.scholarIndigo)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.scholarIndigo.opacity(0.06))
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Chapter Selector") {
    VStack(spacing: 32) {
        // Standard style
        VStack(spacing: 8) {
            Text("Standard")
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
        VStack(spacing: 8) {
            Text("Various Books")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
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
        VStack(spacing: 8) {
            Text("Compact")
                .font(.caption)
                .foregroundStyle(.secondary)

            BibleChapterSelectorCompact(
                reference: "John 3"
            ) {
                print("Tapped compact")
            }
        }

        // In context (simulated toolbar)
        VStack(spacing: 8) {
            Text("In Toolbar Context")
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

                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.primary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)
        }
    }
    .padding()
    .background(Color.appBackground)
}
