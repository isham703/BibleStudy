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

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Animation State
    @State private var showContent = false
    @State private var showIcon = false
    @State private var showText = false
    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with dismiss button
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        .font(Typography.Command.caption)
                        .opacity(showIcon ? 1 : 0)
                        .scaleEffect(showIcon ? 1 : 0.5)

                    Text("Quick Insight")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .opacity(showIcon ? 1 : 0)
                }

                Spacer()

                Button {
                    dismissWithAnimation()
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.Command.caption)
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
        .padding(Theme.Spacing.md)
        .background(Color.elevatedBackground.opacity(Theme.Opacity.nearOpaque))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        // MARK: - Accent Seal Border
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.hairline)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.control + 1)
                .blur(radius: 4)
        )
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
        withAnimation(Theme.Animation.settle) {
            showContent = true
        }

        // Staggered content reveal
        withAnimation(Theme.Animation.settle.delay(0.0)) {
            showIcon = true
        }
        withAnimation(Theme.Animation.settle.delay(0.1)) {
            showText = true
        }
        withAnimation(Theme.Animation.settle.delay(0.2)) {
            showActions = true
        }
    }

    private func dismissWithAnimation() {
        withAnimation(Theme.Animation.fade) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onDismiss?()
        }
    }

    // MARK: - Loading State
    private var loadingContent: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Analyzing passage...")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Insight Content
    @ViewBuilder
    private func insightContent(_ insight: QuickInsightOutput) -> some View {
        // Summary text with ink-bleed animation effect
        Text(insight.summary)
            .font(Typography.Command.body)
            .foregroundStyle(Color.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showText ? 1 : 0)
            .blur(radius: showText ? 0 : 4)
            .offset(y: showText ? 0 : 4)

        // Key term (if present)
        if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
            HStack(spacing: Theme.Spacing.xs) {
                Text(term)
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                Text("—")
                    .foregroundStyle(Color.tertiaryText)
                Text(meaning)
                    .font(Typography.Command.caption)
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
            HStack(spacing: Theme.Spacing.sm) {
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
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: action.icon)
                    .font(Typography.Command.meta)
                Text(action.buttonTitle)
                    .font(Typography.Command.caption)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Color.surfaceBackground)
            .foregroundStyle(Color.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grounding Row (Trust UX)
    private func groundingRow(_ insight: QuickInsightOutput) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.shield")
                .font(Typography.Command.meta)
            Text("Based on: \(insight.groundingSources.joined(separator: ", "))")
                .font(Typography.Command.meta)
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
    VStack(spacing: Theme.Spacing.xl) {
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
