import SwiftUI

// MARK: - Scholar Insight Card
// Inline AI insight card for Bible reader with indigo accent theme
// Design: Clean editorial style with indigo left accent bar
// Animation: Spring unfurl from top matching Scholar's refined motion

struct BibleInsightCard: View {
    let verseRange: VerseRange
    @Bindable var viewModel: BibleInsightViewModel
    @Binding var isVisible: Bool
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void

    var onRequestScroll: ((String) -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?
    var existingHighlightColor: HighlightColor?
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    var onRemoveHighlight: (() -> Void)?

    var body: some View {
        BibleInsightContent(
            verseRange: verseRange,
            viewModel: viewModel,
            onOpenDeepStudy: onOpenDeepStudy,
            onDismiss: onDismiss,
            onRequestScroll: onRequestScroll,
            onCopy: onCopy,
            onShare: onShare,
            existingHighlightColor: existingHighlightColor,
            onSelectHighlightColor: onSelectHighlightColor,
            onRemoveHighlight: onRemoveHighlight,
            accentBarWidth: 4,
            cornerRadius: Theme.Radius.card
        )
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(cardBorder)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private var cardBackground: some View {
        Color("AppSurface")
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .stroke(Color.gray.opacity(Theme.Opacity.divider), lineWidth: Theme.Stroke.hairline)
    }
}

#Preview("Scholar Insight Card") {
    struct PreviewContainer: View {
        @State private var isVisible = true
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("20 built on the foundation of the apostles and prophets, Christ Jesus himself being the cornerstone,")
                        .readingVerse(size: .medium, font: .newYork)
                        .padding()
                        .background(
                            // swiftlint:disable:next hardcoded_rounded_rectangle
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .stroke(Color("AppAccentAction").opacity(Theme.Opacity.focusStroke), lineWidth: Theme.Stroke.hairline)
                        )
                        .padding(.horizontal)

                    if isVisible {
                        BibleInsightCard(
                            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20),
                            viewModel: BibleInsightViewModel(verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20)),
                            isVisible: $isVisible,
                            onOpenDeepStudy: { print("Deep study") },
                            onDismiss: { isVisible = false }
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
