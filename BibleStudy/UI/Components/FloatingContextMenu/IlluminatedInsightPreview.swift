//
//  IlluminatedInsightPreview.swift
//  BibleStudy
//
//  Compact AI insight preview for the IlluminatedContextMenu.
//  Uses Cormorant Garamond for body text and Cinzel for headers,
//  matching the illuminated manuscript aesthetic.
//

import SwiftUI

// MARK: - Illuminated Insight Preview

/// A compact AI insight preview with manuscript typography.
/// Embedded within the IlluminatedContextMenu for unified display.
struct IlluminatedInsightPreview: View {
    /// The insight data to display
    let insight: QuickInsightOutput?

    /// Whether the insight is still loading
    let isLoading: Bool

    /// Called when user taps to see full insight
    var onTapToExpand: (() -> Void)?

    // MARK: - Animation State

    @State private var showHeader = false
    @State private var showBody = false
    @State private var showKeyTerm = false
    @State private var shimmerPhase: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let headerTracking: CGFloat = 1.5
    private let maxLines: Int = 3

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            headerView
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 4)

            if isLoading {
                loadingView
            } else if let insight = insight {
                insightContentView(insight)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .onAppear {
            startRevealAnimation()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Decorative sparkle
            Image(systemName: "sparkle")
                .font(Typography.UI.iconXxs.weight(.medium))
                .foregroundStyle(Color.divineGold)

            // "Quick Insight" in Cinzel with tracking
            Text("Quick Insight")
                .font(DisplayFont.cinzel.font(size: Typography.Scale.xs, weight: .medium))
                .tracking(headerTracking)
                .foregroundStyle(Color.agedInk)

            Spacer()

            // Tap to expand hint
            if insight != nil && onTapToExpand != nil {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Text("Tap for more")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)

                    Image(systemName: "chevron.right")
                        .font(Typography.UI.iconXxxs)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // Shimmer placeholder lines
            ForEach(0..<2, id: \.self) { index in
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(shimmerGradient)
                    .frame(height: Typography.Scale.sm)
                    .frame(maxWidth: index == 1 ? 180 : .infinity)
            }
        }
        .onAppear {
            startShimmerAnimation()
        }
    }

    private var shimmerGradient: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: Color.tertiaryText.opacity(AppTheme.Opacity.subtle), location: 0),
                .init(color: Color.tertiaryText.opacity(AppTheme.Opacity.lightMedium), location: shimmerPhase),
                .init(color: Color.tertiaryText.opacity(AppTheme.Opacity.subtle), location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Insight Content

    @ViewBuilder
    private func insightContentView(_ insight: QuickInsightOutput) -> some View {
        // Summary text in Cormorant Garamond italic
        Text(insight.summary)
            .font(DisplayFont.cormorantGaramond.font(size: Typography.Scale.base - 3, weight: .regular))
            .italic()
            .foregroundStyle(Color.primaryText)
            .lineLimit(maxLines)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showBody ? 1 : 0)
            .blur(radius: showBody ? 0 : AppTheme.Spacing.xxs)
            .offset(y: showBody ? 0 : AppTheme.Spacing.xs)

        // Key term (if present)
        if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
            keyTermView(term: term, meaning: meaning)
                .opacity(showKeyTerm ? 1 : 0)
                .offset(y: showKeyTerm ? 0 : AppTheme.Spacing.xs)
        }
    }

    private func keyTermView(term: String, meaning: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Term in Cinzel with gold
            Text(term)
                .font(DisplayFont.cinzel.font(size: Typography.Scale.sm, weight: .medium))
                .foregroundStyle(Color.divineGold)

            // Em dash
            Text("—")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)

            // Meaning
            Text(meaning)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
        }
    }

    // MARK: - Animations

    private func startRevealAnimation() {
        // Staggered reveal
        withAnimation(AppTheme.Animation.standard) {
            showHeader = true
        }

        withAnimation(AppTheme.Animation.slow.delay(0.1)) {
            showBody = true
        }

        withAnimation(AppTheme.Animation.standard.delay(0.2)) {
            showKeyTerm = true
        }
    }

    private func startShimmerAnimation() {
        withAnimation(AppTheme.Animation.shimmer.repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
    }
}

// MARK: - Tappable Insight Preview

/// A wrapper that makes the insight preview tappable to expand
struct TappableInsightPreview: View {
    let insight: QuickInsightOutput?
    let isLoading: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        IlluminatedInsightPreview(
            insight: insight,
            isLoading: isLoading,
            onTapToExpand: onTap
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticService.shared.lightTap()
            onTap()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(AppTheme.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.Animation.quick, value: isPressed)
    }
}

// MARK: - Insight Divider

/// A decorative divider for the insight section using manuscript styling
struct InsightSectionDivider: View {
    var body: some View {
        OrnamentalDivider(
            style: .flourish,
            color: Color.divineGold.opacity(AppTheme.Opacity.strong)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Previews

#Preview("Insight Preview - Loading") {
    ZStack {
        Color.agedParchment.ignoresSafeArea()

        VStack {
            IlluminatedInsightPreview(
                insight: nil,
                isLoading: true
            )
            .frame(maxWidth: 260)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.agedParchment)
                    .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
            )
        }
    }
}

#Preview("Insight Preview - With Content") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.xl) {
            // Light mode
            IlluminatedInsightPreview(
                insight: QuickInsightOutput(
                    summary: "This verse establishes God's creative power through speech, setting the pattern for divine action throughout Genesis.",
                    keyTerm: "יְהִי (yehi)",
                    keyTermMeaning: "let there be - jussive command",
                    suggestedAction: .viewLanguage
                ),
                isLoading: false,
                onTapToExpand: {}
            )
            .frame(maxWidth: 260)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.agedParchment)
                    .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
            )

            // Dark mode preview
            IlluminatedInsightPreview(
                insight: QuickInsightOutput(
                    summary: "The Hebrew word 'bara' is used exclusively for divine creation, emphasizing the uniqueness of God's creative act.",
                    keyTerm: "בָּרָא (bara)",
                    keyTermMeaning: "to create (divine action)",
                    suggestedAction: .viewLanguage
                ),
                isLoading: false
            )
            .frame(maxWidth: 260)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.chapelShadow)
                    .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
            )
            .environment(\.colorScheme, .dark)
        }
    }
}

#Preview("Tappable Insight") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        TappableInsightPreview(
            insight: QuickInsightOutput(
                summary: "The concept of 'light' here represents both physical illumination and spiritual enlightenment.",
                keyTerm: "אוֹר (or)",
                keyTermMeaning: "light, illumination",
                suggestedAction: .explainMore
            ),
            isLoading: false,
            onTap: { print("Tapped!") }
        )
        .frame(maxWidth: 260)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(Color.agedParchment)
                .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
        )
    }
}
