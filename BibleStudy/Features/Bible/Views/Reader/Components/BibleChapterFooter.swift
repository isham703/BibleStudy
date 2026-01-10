import SwiftUI

// MARK: - Bible Chapter Footer
// Manuscript colophon style footer with chapter completion ornament
// Includes optional "Continue Reading" invitation to next chapter

struct BibleChapterFooter: View {
    let chapter: Int
    let canGoForward: Bool
    let nextLocation: BibleLocation?
    let onNextChapter: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Elegant chapter closing ornament
            chapterClosingOrnament
                .padding(.bottom, Theme.Spacing.xxl)

            // Next chapter invitation (conditional)
            if canGoForward, let nextLocation = nextLocation {
                nextChapterInvitation(nextLocation: nextLocation)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            // Breathing room
            Spacer()
                .frame(height: 100)
        }
        .frame(maxWidth: .infinity)
        // swiftlint:disable:next hardcoded_padding_edge
        .padding(.top, 60)
    }

    // MARK: - Chapter Closing Ornament

    private var chapterClosingOrnament: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Triple-line flourish
            VStack(spacing: Theme.Spacing.xs) {
                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    .frame(width: 80, height: Theme.Stroke.hairline)
                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium + 0.05))
                    .frame(width: 120, height: Theme.Stroke.hairline)
                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    .frame(width: 80, height: Theme.Stroke.hairline)
            }

            // Chapter completion label
            Text("CHAPTER \(chapter)")
                .font(Typography.Icon.xxs.weight(.medium))
                .tracking(4)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))
        }
    }

    // MARK: - Next Chapter Invitation

    private func nextChapterInvitation(nextLocation: BibleLocation) -> some View {
        Button {
            onNextChapter()
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // "Continue reading" label
                Text("CONTINUE READING")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .tracking(2.5)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))

                // Destination with elegant typography
                HStack(spacing: Theme.Spacing.sm) {
                    if let book = nextLocation.book {
                        // swiftlint:disable:next hardcoded_font_custom
                        Text(book.name)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                        // swiftlint:disable:next hardcoded_font_custom
                        Text("\(nextLocation.chapter)")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
                    }
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .padding(.horizontal, Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint / 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .strokeBorder(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle + 0.02), lineWidth: Theme.Stroke.hairline)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack {
            Text("Chapter content would be here...")
                .foregroundStyle(Colors.Surface.textPrimary(for: .dark))
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
    .background(Colors.Surface.background(for: .dark))
}

#Preview("No Next Chapter") {
    BibleChapterFooter(
        chapter: 21,
        canGoForward: false,
        nextLocation: nil,
        onNextChapter: {}
    )
    .padding(.horizontal, Theme.Spacing.xl)
    .background(Colors.Surface.background(for: .dark))
}
