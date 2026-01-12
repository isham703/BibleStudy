import SwiftUI

// MARK: - Interpretive Badge Explanation Sheet
// Small sheet explaining what "Interpretive" means

struct InterpretiveBadgeSheet: View {
    let onDismiss: () -> Void         // Back to FlatInsightView

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header with Back/Close navigation
            HStack(spacing: Theme.Spacing.md) {
                // Back button
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Back")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }
                .buttonStyle(.plain)

                Spacer()

                // Title with icon
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("FeedbackInfo"))

                    Text("About Interpretive")
                        .font(Typography.Scripture.footnote.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText)
                }

                Spacer()

                // Close button (dismisses entire sheet stack)
                Button {
                    HapticService.shared.lightTap()
                    sheetState?.dismissAll()
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2)))
                }
                .buttonStyle(.plain)
            }

            // Explanation
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Insights marked as \"Interpretive\" represent theological synthesis or application rather than direct textual facts.")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed + 0.05))
                    .lineSpacing(Typography.Scripture.footnoteLineSpacing)

                // Types grid
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    typeRow(
                        icon: "quote.bubble",
                        title: "Textual",
                        description: "Direct from the original text",
                        color: Color("FeedbackSuccess")
                    )
                    typeRow(
                        icon: "sparkles",
                        title: "Interpretive",
                        description: "Theological synthesis; may vary by tradition",
                        color: Color("FeedbackInfo")
                    )
                    typeRow(
                        icon: "clock",
                        title: "Historical",
                        description: "Based on historical context",
                        color: Color("AccentBronze")
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.bibleInsightCardBackground)
    }

    private func typeRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.xs)
                .foregroundStyle(color)
                .frame(width: Theme.Spacing.xl)

            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(alignment: .leading, spacing: 1) {  // Tight title/description spacing
                Text(title)
                    .font(Typography.Icon.xs.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText)

                Text(description)
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
            }
        }
        .padding(.vertical, Theme.Spacing.xxs)
    }
}
