import SwiftUI

// MARK: - Scholar Insight Card
// Inline AI insight card for Scholar reader with indigo accent theme
// Design: Clean editorial style with indigo left accent bar
// Animation: Spring unfurl from top matching Scholar's refined motion

struct ScholarInsightCard: View {
    let verseRange: VerseRange
    @Bindable var viewModel: InsightViewModel
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
        ScholarInsightContent(
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
            cornerRadius: AppTheme.CornerRadius.card
        )
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: AppTheme.Shadow.cardColor, radius: 8, x: 0, y: 4)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var cardBackground: some View {
        AppTheme.InsightCard.background
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
            .stroke(AppTheme.InsightCard.border, lineWidth: 1)
    }
}

#Preview("Scholar Insight Card") {
    struct PreviewContainer: View {
        @State private var isVisible = true

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text("20 built on the foundation of the apostles and prophets, Christ Jesus himself being the cornerstone,")
                        .readingVerse(size: .medium, font: .newYork)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.scholarIndigo.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)

                    if isVisible {
                        ScholarInsightCard(
                            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20),
                            viewModel: InsightViewModel(verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20)),
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
