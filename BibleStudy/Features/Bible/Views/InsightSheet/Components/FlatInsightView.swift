import SwiftUI

// MARK: - Flat Insight View (No Card Border)
// Dense typography for fast scanning - annotation, not scripture

struct FlatInsightView: View {
    let insight: BibleInsight

    /// Optional: Callback for writing a note (Reflection CTA)
    var onWriteNote: ((BibleInsight) -> Void)?

    // MARK: - Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.insightSheetState) private var sheetState
    @State private var showInterpretiveExplanation = false
    @State private var isSavedToJournal = false

    /// Is this a reflection/question type insight?
    private var isReflection: Bool {
        insight.insightType == .question
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Title (compact)
            Text(insight.title)
                .font(Typography.Scripture.footnote.weight(.medium))
                .foregroundStyle(Color.bibleInsightText)

            // Content (dense, fast to scan)
            Text(insight.content)
                .font(Typography.Scripture.footnote)
                .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))

            // Interpretive badge (tappable) - Sources are accessed via footer row
            if insight.isInterpretive {
                interpretiveBadge
                    .padding(.top, Theme.Spacing.xxs)
            }

            // Reflection CTA (only for question-type insights)
            if isReflection {
                reflectionCTA
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .sheet(isPresented: $showInterpretiveExplanation) {
            InterpretiveBadgeSheet(
                onDismiss: { showInterpretiveExplanation = false }
            )
            .environment(\.insightSheetState, sheetState)
            // swiftlint:disable:next hardcoded_presentation_detent
            .presentationDetents([.height(320)])  // Slightly taller for new header
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Reflection CTA

    private var reflectionCTA: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Write a note button
            Button {
                HapticService.shared.mediumTap()
                onWriteNote?(insight)
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: "square.and.pencil")
                        .font(Typography.Icon.xxs.weight(.medium))
                    Text("Write a note")
                        .font(Typography.Icon.xxs.weight(.medium))
                }
                .foregroundStyle(Color("FeedbackError"))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs + 1)
                .background(
                    Capsule()
                        .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)

            // Save to journal button
            Button {
                HapticService.shared.lightTap()
                withAnimation(Theme.Animation.settle) {
                    isSavedToJournal.toggle()
                }
                // TODO: Actually save to journal
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: isSavedToJournal ? "bookmark.fill" : "bookmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                    Text(isSavedToJournal ? "Saved" : "Save question")
                        .font(Typography.Icon.xxs.weight(.medium))
                }
                .foregroundStyle(isSavedToJournal ? Color("FeedbackError") : Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs + 1)
                .background(
                    Capsule()
                        .fill(isSavedToJournal ? Color("FeedbackError").opacity(Theme.Opacity.subtle) : Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var interpretiveBadge: some View {
        Button {
            HapticService.shared.lightTap()
            showInterpretiveExplanation = true
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "info.circle")
                    .font(Typography.Icon.xxxs)
                Text("Interpretive")
                    .font(Typography.Icon.xxs.weight(.medium))
            }
            .foregroundStyle(Color("FeedbackInfo"))
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(Color("FeedbackInfo").opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap to learn what interpretive means")
    }
}
