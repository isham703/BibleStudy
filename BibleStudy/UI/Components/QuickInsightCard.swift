import SwiftUI

// MARK: - Quick Insight Card
// Compact AI insight that appears above the selection toolbar
// Enhanced with illuminated manuscript aesthetic:
// - Staggered content reveal animation
// - Gold glow border effect
// - Spring-based appear/disappear animation

struct QuickInsightCard: View {
    let insight: QuickInsightOutput?
    let isLoading: Bool
    var onAction: ((QuickInsightAction) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Animation State
    @State private var showContent = false
    @State private var showIcon = false
    @State private var showText = false
    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with dismiss button
            HStack {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.scholarAccent)
                        .font(Typography.UI.caption1)
                        .opacity(showIcon ? 1 : 0)
                        .scaleEffect(showIcon ? 1 : 0.5)

                    Text("Quick Insight")
                        .font(Typography.UI.warmSubheadline)
                        .foregroundStyle(Color.secondaryText)
                        .opacity(showIcon ? 1 : 0)
                }

                Spacer()

                Button {
                    dismissWithAnimation()
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
                .opacity(showIcon ? 1 : 0)
            }

            if isLoading {
                loadingContent
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 4)
            } else if let insight = insight {
                insightContent(insight)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.elevatedBackground.opacity(AppTheme.Opacity.nearOpaque))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        // MARK: - Gold Glow Border (Illuminated Manuscript)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.divineGold.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thick + 1)
                .blur(radius: AppTheme.Blur.subtle)
        )
        // MARK: - Warm Gold Shadow
        .shadow(AppTheme.Shadow.medium)
        // MARK: - Appear Animation
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.95)
        .offset(y: showContent ? 0 : 8)
        .onAppear {
            startAppearAnimation()
        }
    }

    // MARK: - Animation Methods

    private func startAppearAnimation() {
        withAnimation(AppTheme.Animation.sacredSpring) {
            showContent = true
        }

        // Staggered content reveal
        withAnimation(AppTheme.Animation.standard.delay(0.0)) {
            showIcon = true
        }
        withAnimation(AppTheme.Animation.standard.delay(0.1)) {
            showText = true
        }
        withAnimation(AppTheme.Animation.standard.delay(0.2)) {
            showActions = true
        }
    }

    private func dismissWithAnimation() {
        withAnimation(AppTheme.Animation.quick) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onDismiss?()
        }
    }

    // MARK: - Loading State
    private var loadingContent: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ProgressView()
                .scaleEffect(AppTheme.Scale.reduced)
            Text("Analyzing passage...")
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Insight Content
    @ViewBuilder
    private func insightContent(_ insight: QuickInsightOutput) -> some View {
        // Summary text with ink-bleed animation effect
        Text(insight.summary)
            .font(Typography.UI.body)
            .foregroundStyle(Color.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showText ? 1 : 0)
            .blur(radius: showText ? 0 : 4)
            .offset(y: showText ? 0 : 4)

        // Key term (if present)
        if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(term)
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.scholarAccent)
                Text("—")
                    .foregroundStyle(Color.tertiaryText)
                Text(meaning)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 4)
        }

        // Action buttons
        actionButtons
            .opacity(showActions ? 1 : 0)
            .offset(y: showActions ? 0 : 8)

        // Grounding sources (trust UX)
        groundingRow(insight)
            .opacity(showActions ? 1 : 0)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(QuickInsightAction.allCases, id: \.self) { action in
                    actionButton(action)
                }
            }
        }
    }

    private func actionButton(_ action: QuickInsightAction) -> some View {
        Button {
            onAction?(action)
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: action.icon)
                    .font(Typography.UI.caption2)
                Text(action.buttonTitle)
                    .font(Typography.UI.caption1)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.surfaceBackground)
            .foregroundStyle(Color.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grounding Row (Trust UX)
    private func groundingRow(_ insight: QuickInsightOutput) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "checkmark.shield")
                .font(Typography.UI.caption2)
            Text("Based on: \(insight.groundingSources.joined(separator: ", "))")
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(Color.tertiaryText)
    }
}

// MARK: - CaseIterable for QuickInsightAction
extension QuickInsightAction: CaseIterable {
    static var allCases: [QuickInsightAction] {
        [.explainMore, .understand, .showContext, .viewLanguage, .seeCrossRefs]
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.xl) {
        // Loading state
        QuickInsightCard(
            insight: nil,
            isLoading: true
        )

        // With insight
        QuickInsightCard(
            insight: QuickInsightOutput(
                summary: "This verse establishes God's creative power through speech, setting the pattern for divine action throughout Genesis.",
                keyTerm: "יְהִי (yehi)",
                keyTermMeaning: "let there be - jussive command form",
                suggestedAction: .viewLanguage
            ),
            isLoading: false
        ) { action in
            print("Action: \(action)")
        } onDismiss: {
            print("Dismissed")
        }
    }
    .padding()
    .background(Color.appBackground)
}
