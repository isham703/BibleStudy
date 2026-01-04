import SwiftUI

struct ScholarInlineInsightPanel: View {
    let verseRange: VerseRange
    @Bindable var viewModel: InsightViewModel
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void

    var onRequestScroll: ((String) -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?
    var existingHighlightColor: HighlightColor?
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    var onRemoveHighlight: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.InlineInsight.divider)
                .frame(height: 1)

            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.35))
                    .frame(width: 2)

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
                    accentBarWidth: 0,
                    cornerRadius: 0
                )
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
    }
}
