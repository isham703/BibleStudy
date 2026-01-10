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
struct InsightPreview: View {
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .onAppear {
            startRevealAnimation()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Decorative sparkle
            Image(systemName: "sparkle")
                .font(Typography.Icon.xxs.weight(.medium))
                .foregroundStyle(Color.accentBronze)

            // "Quick Insight" header
            Text("Quick Insight")
                .font(Typography.Command.meta.weight(.medium))
                .tracking(headerTracking)
                .foregroundStyle(Color.surfaceRaised)

            Spacer()

            // Tap to expand hint
            if insight != nil && onTapToExpand != nil {
                HStack(spacing: 2) {
                    Text("Tap for more")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)

                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Shimmer placeholder lines
            ForEach(0..<2, id: \.self) { index in
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(shimmerGradient)
                    .frame(height: 14)
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
                .init(color: Color.tertiaryText.opacity(Theme.Opacity.subtle), location: 0),
                .init(color: Color.tertiaryText.opacity(Theme.Opacity.lightMedium), location: shimmerPhase),
                .init(color: Color.tertiaryText.opacity(Theme.Opacity.subtle), location: 1)
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
            .font(Typography.Scripture.body)
            .italic()
            .foregroundStyle(Color.primaryText)
            .lineLimit(maxLines)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showBody ? 1 : 0)
            .blur(radius: showBody ? 0 : 2)
            .offset(y: showBody ? 0 : Theme.Spacing.xs)

        // Key term (if present)
        if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
            keyTermView(term: term, meaning: meaning)
                .opacity(showKeyTerm ? 1 : 0)
                .offset(y: showKeyTerm ? 0 : Theme.Spacing.xs)
        }
    }

    private func keyTermView(term: String, meaning: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Term in Cinzel with gold
            Text(term)
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Color.accentBronze)

            // Em dash
            Text("—")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)

            // Meaning
            Text(meaning)
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
        }
    }

    // MARK: - Animations

    private func startRevealAnimation() {
        // Staggered reveal
        withAnimation(Theme.Animation.settle) {
            showHeader = true
        }

        withAnimation(Theme.Animation.slowFade.delay(0.1)) {
            showBody = true
        }

        withAnimation(Theme.Animation.settle.delay(0.2)) {
            showKeyTerm = true
        }
    }

    private func startShimmerAnimation() {
        withAnimation(Theme.Animation.fade) {
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
        InsightPreview(
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
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.fade, value: isPressed)
    }
}

// MARK: - Insight Divider

/// A decorative divider for the insight section using manuscript styling
struct InsightSectionDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Previews

#Preview("Insight Preview - Loading") {
    ZStack {
        Color.offWhite.ignoresSafeArea()

        VStack {
            InsightPreview(
                insight: nil,
                isLoading: true
            )
            .frame(maxWidth: 260)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.offWhite)
                    .stroke(Color.accentBronze, lineWidth: Theme.Stroke.hairline)
            )
        }
    }
}

#Preview("Insight Preview - With Content") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            // Light mode
            InsightPreview(
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
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.offWhite)
                    .stroke(Color.accentBronze, lineWidth: Theme.Stroke.hairline)
            )

            // Dark mode preview
            InsightPreview(
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
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.surfaceRaised)
                    .stroke(Color.accentBronze, lineWidth: Theme.Stroke.hairline)
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
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.offWhite)
                .stroke(Color.accentBronze, lineWidth: Theme.Stroke.hairline)
        )
    }
}
