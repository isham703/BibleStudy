import SwiftUI

// MARK: - Bible Chapter Footer
// Disciplined chapter end marker with optional artwork image and next chapter action
// Design: end marker → artwork image (optional) → next chapter row

struct BibleChapterFooter: View {
    let chapter: Int
    let canGoForward: Bool
    let nextLocation: BibleLocation?
    let onNextChapter: () -> Void

    // Optional: Book name for loading chapter artwork from Supabase Storage
    // When provided, displays a ChapterFooterImage at chapter end
    var bookName: String?
    var bottomSafeAreaInset: CGFloat? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var imageFailed = false

    var body: some View {
        VStack(spacing: 0) {
            // Single hairline separator + chapter marker (no ornament)
            chapterEndMarker
                .padding(.bottom, Theme.Spacing.xxl)

            // Next chapter row - shown ABOVE image
            if canGoForward, let nextLocation = nextLocation {
                nextChapterRow(nextLocation: nextLocation)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            // Chapter artwork image (optional - loads from Supabase Storage)
            // This is the final visual element at the end of the chapter
            if let bookName = bookName, !imageFailed {
                chapterArtwork(bookName: bookName)
            } else {
                // Breathing room when no image
                Spacer()
                    .frame(height: 100)
            }
        }
        .frame(maxWidth: .infinity)
        // swiftlint:disable:next hardcoded_padding_edge
        .padding(.top, 60)
        .onChange(of: chapter) { _, _ in
            // Reset image state when chapter changes
            imageFailed = false
        }
    }

    // MARK: - Chapter Artwork
    // Loads Renaissance-style artwork from Supabase Storage
    // Path: chapter-images/{book}/{chapter}.webp
    // If image doesn't exist, triggers imageFailed state

    @ViewBuilder
    private func chapterArtwork(bookName: String) -> some View {
        ChapterFooterImage(
            book: bookName,
            chapter: chapter,
            bottomSafeAreaInset: bottomSafeAreaInset,
            onImageFailed: {
                withAnimation(Theme.Animation.fade) {
                    imageFailed = true
                }
            }
        )
    }

    // MARK: - Chapter End Marker
    // Single separator + neutral chapter label (no tint, no flourish)

    private var chapterEndMarker: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Single hairline separator
            Rectangle()
                .fill(Color.appDivider)
                .frame(width: 100, height: Theme.Stroke.hairline)

            // Chapter label - neutral, not tinted
            Text("END OF CHAPTER \(chapter)")
                .font(Typography.Command.caption)
                .tracking(3)
                .foregroundStyle(Color("TertiaryText"))
        }
    }

    // MARK: - Next Chapter Row
    // Ruled row (not card) - feels like manual index entry

    private func nextChapterRow(nextLocation: BibleLocation) -> some View {
        Button {
            onNextChapter()
        } label: {
            VStack(spacing: 0) {
                // Top rule
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: Theme.Stroke.hairline)

                // Content row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        // "NEXT" label - manual tag style
                        Text("NEXT")
                            .font(Typography.Command.caption)
                            .tracking(2.2)
                            .foregroundStyle(Color("TertiaryText").opacity(0.65))

                        // Destination - serif, primary text
                        if let book = nextLocation.book {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(book.name)
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("\(nextLocation.chapter)")
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }

                    Spacer()

                    // Chevron affordance - neutral, not tinted
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding(.vertical, Theme.Spacing.lg)

                // Bottom rule
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: Theme.Stroke.hairline)
            }
        }
        .buttonStyle(.plain)
        .opacity(isPressed ? Theme.Opacity.pressed : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("With Artwork") {
    ScrollView {
        VStack {
            Text("Chapter content would be here...")
                .foregroundStyle(Color("AppTextPrimary"))
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.vertical, 100)

            BibleChapterFooter(
                chapter: 1,
                canGoForward: true,
                nextLocation: BibleLocation(bookId: 1, chapter: 2),
                onNextChapter: { print("Next chapter") },
                bookName: "Genesis"
            )
        }
    }
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}

#Preview("Without Artwork") {
    ScrollView {
        VStack {
            Text("Chapter content would be here...")
                .foregroundStyle(Color("AppTextPrimary"))
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.vertical, 100)

            BibleChapterFooter(
                chapter: 1,
                canGoForward: true,
                nextLocation: BibleLocation(bookId: 43, chapter: 2),
                onNextChapter: { print("Next chapter") }
            )
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
    .background(Color("AppBackground"))
}

#Preview("No Next Chapter") {
    BibleChapterFooter(
        chapter: 21,
        canGoForward: false,
        nextLocation: nil,
        onNextChapter: {}
    )
    .padding(.horizontal, Theme.Spacing.xl)
    .background(Color("AppBackground"))
}
