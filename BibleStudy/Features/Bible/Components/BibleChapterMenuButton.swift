import SwiftUI

// MARK: - Bible Chapter Selector Button
// Native SwiftUI Button for chapter navigation in the navigation bar
// Tapping opens the book picker sheet directly

struct BibleChapterMenuButton: View {
    let currentBook: Book?
    let currentChapter: Int
    let onTap: () -> Void

    @State private var isPressed = false

    private var reference: String {
        guard let book = currentBook else { return "—" }
        return "\(book.abbreviation) \(currentChapter)"
    }

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            onTap()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("AppAccentAction"))

                Text(reference)
                    .font(Typography.Command.meta.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))

                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .foregroundStyle(Color("AppAccentAction"))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color("ChapterSelectorBackground"))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color("ChapterSelectorBorder"), lineWidth: Theme.Stroke.hairline)
            )
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
        .accessibilityHint("Currently reading \(currentBook?.name ?? "unknown") chapter \(currentChapter). Double tap to change book or chapter.")
        .accessibilityIdentifier("ReaderToolbarChapterMenuButton")
    }
}

// MARK: - Preview

#Preview("Chapter Button - Genesis 12") {
    NavigationStack {
        VStack {
            Text("Preview Content")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                BibleChapterMenuButton(
                    currentBook: Book.find(byId: 1), // Genesis
                    currentChapter: 12,
                    onTap: { print("Open book picker") }
                )
            }
        }
    }
}

#Preview("Chapter Button - Psalms 119") {
    NavigationStack {
        VStack {
            Text("Preview Content - Psalms has 150 chapters")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                BibleChapterMenuButton(
                    currentBook: Book.find(byId: 19), // Psalms
                    currentChapter: 119,
                    onTap: { print("Open book picker") }
                )
            }
        }
    }
}
