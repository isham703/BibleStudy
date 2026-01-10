import SwiftUI

struct BibleInlineInsightPanel: View {
    let verseRange: VerseRange
    @Bindable var viewModel: BibleInsightViewModel
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    var onRequestScroll: ((String) -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?
    var existingHighlightColor: HighlightColor?
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    var onRemoveHighlight: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(Theme.Opacity.divider))
                .frame(height: Theme.Stroke.hairline)

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Rectangle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium + 0.05))
                    .frame(width: Theme.Stroke.control)

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
                    accentBarWidth: 0,
                    cornerRadius: 0
                )
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }
}
