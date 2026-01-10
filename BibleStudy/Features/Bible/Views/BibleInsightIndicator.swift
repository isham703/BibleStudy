import SwiftUI

// MARK: - Insight Indicator
// Sacred trefoil design - three gold dots arranged in triangular pattern
// Indicates available insights for a verse with tap-to-reveal interaction
// Design: Illuminated manuscript aesthetic with subtle animations

struct BibleInsightIndicator: View {
    // MARK: - Properties

    /// Number of available insights for this verse
    let count: Int

    /// Whether this verse's lens container is currently expanded
    let isExpanded: Bool

    /// Action when indicator is tapped
    let onTap: () -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var isPressed = false
    @State private var hasAppeared = false
    @State private var glowOpacity: Double = 0
    @State private var showTooltip = false

    // MARK: - First Use Tracking

    /// Track if user has tapped any indicator (learns the pattern)
    @AppStorage("hasUsedInsightIndicator") private var hasUsedIndicator = false

    // MARK: - Constants

    private let dotSize: CGFloat = 3.5
    private let topDotSize: CGFloat = 3
    private let spacing: CGFloat = 2.5
    private let containerWidth: CGFloat = 18
    private let containerHeight: CGFloat = 14

    // MARK: - Body

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        let accentSeal = Colors.Semantic.accentSeal(for: themeMode)

        Button(action: {
            HapticService.shared.lightTap()
            hasUsedIndicator = true  // User has learned the pattern
            showTooltip = false
            onTap()
        }) {
            ZStack {
                // Glow effect (subtle, appears on press and when expanded)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentSeal.opacity(glowOpacity * 0.3),
                                accentSeal.opacity(glowOpacity * 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: containerWidth * 1.2
                        )
                    )
                    .frame(width: containerWidth * 1.8, height: containerHeight * 1.8)
                    .opacity(isExpanded || isPressed ? 1 : 0)

                // Trefoil container
                VStack(spacing: 0) {
                    // Top dot (smaller)
                    Circle()
                        .fill(dotColor)
                        .frame(width: topDotSize, height: topDotSize)

                    Spacer()
                        .frame(height: spacing)

                    // Bottom two dots
                    HStack(spacing: spacing * 2) {
                        Circle()
                            .fill(dotColor)
                            .frame(width: dotSize, height: dotSize)

                        Circle()
                            .fill(dotColor)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
                .frame(width: containerWidth, height: containerHeight)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))

                // Count badge (only visible when count > 1 and not expanded)
                if count > 1 && !isExpanded {
                    countBadge
                        .offset(x: 8, y: -6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: containerWidth + 12, height: containerHeight + 6)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 1.05 : 1.0)
            // Tooltip overlay (outside frame to prevent clipping)
            .overlay(alignment: .top) {
                if showTooltip && !isExpanded {
                    insightTooltip
                        .offset(y: -32)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                        .zIndex(100)
                }
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if reduceMotion {
                isPressed = pressing
                glowOpacity = pressing ? 1.0 : (isExpanded ? 0.6 : 0)
                showTooltip = pressing  // Show tooltip on long press
            } else {
                withAnimation(Theme.Animation.fade) {
                    isPressed = pressing
                    showTooltip = pressing  // Show tooltip on long press
                }
                withAnimation(Theme.Animation.slowFade) {
                    glowOpacity = pressing ? 1.0 : (isExpanded ? 0.6 : 0)
                }
            }
        }, perform: {})
        .onAppear {
            if !reduceMotion {
                // Gentle entrance pulse
                withAnimation(Theme.Animation.settle.delay(0.3)) {
                    hasAppeared = true
                }

                // Show tooltip briefly on first scroll to help users understand the indicator
                // Shows for first few indicators until user has learned the pattern
                if !hasUsedIndicator && count > 0 {
                    // Stagger the tooltip appearance based on verse position to avoid visual chaos
                    let delay = Double.random(in: 0.8...1.5)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // Only show if still not used (user might have tapped another one)
                        guard !hasUsedIndicator else { return }
                        // swiftlint:disable:next hardcoded_with_animation hardcoded_animation_ease
                        withAnimation(.easeOut(duration: 0.25)) {
                            showTooltip = true
                        }
                        // Auto-hide after 3 seconds (longer for better visibility)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            // swiftlint:disable:next hardcoded_with_animation hardcoded_animation_ease
                            withAnimation(.easeOut(duration: 0.4)) {
                                showTooltip = false
                            }
                        }
                    }
                }
            } else {
                hasAppeared = true
            }
        }
        .onChange(of: isExpanded) { _, newValue in
            if reduceMotion {
                glowOpacity = newValue ? 0.6 : 0
            } else {
                withAnimation(Theme.Animation.slowFade) {
                    glowOpacity = newValue ? 0.6 : 0
                }
            }
        }
        .accessibilityLabel("\(count) insight\(count == 1 ? "" : "s") available")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand insights")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Dot Color

    private var dotColor: Color {
        let themeMode = ThemeMode.current(from: colorScheme)
        let accentSeal = Colors.Semantic.accentSeal(for: themeMode)

        if isExpanded {
            return accentSeal
        } else if isPressed {
            return accentSeal.opacity(Theme.Opacity.high)
        } else {
            return accentSeal.opacity(hasAppeared ? Theme.Opacity.strong : Theme.Opacity.medium)
        }
    }

    // MARK: - Count Badge

    private var countBadge: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        let accentSeal = Colors.Semantic.accentSeal(for: themeMode)

        return Text("\(count)")
            // swiftlint:disable:next hardcoded_font_custom
            .font(.system(size: 10, weight: .semibold, design: .serif))
            .foregroundStyle(accentSeal)
            .padding(.horizontal, Theme.Spacing.xs)
            // swiftlint:disable:next hardcoded_padding_edge
            .padding(.vertical, 1)  // Minimal badge padding
            .background(
                Capsule()
                    .fill(accentSeal.opacity(Theme.Opacity.light))
            )
    }

    // MARK: - Insight Tooltip

    private var insightTooltip: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        let accentSeal = Colors.Semantic.accentSeal(for: themeMode)

        return Text("\(count) insight\(count == 1 ? "" : "s")")
            // swiftlint:disable:next hardcoded_font_system
            .font(Typography.Icon.xxs)
            .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(accentSeal)
                    .shadow(color: Color.black.opacity(Theme.Opacity.light), radius: 4, y: 2)
            )
            .fixedSize()
    }
}

// MARK: - Preview

#Preview("Insight Indicator States") {
    struct PreviewContainer: View {
        @State private var expanded1 = false
        @State private var expanded2 = false
        @State private var expanded3 = false

        var body: some View {
            VStack(spacing: Theme.Spacing.xxl + Theme.Spacing.sm) {
                // Rest state
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Rest (1 insight)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(.secondary)

                    BibleInsightIndicator(count: 1, isExpanded: false, onTap: {})
                }

                // Multiple insights
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Multiple (3 insights)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(.secondary)

                    BibleInsightIndicator(count: 3, isExpanded: false, onTap: {})
                }

                // Expanded state
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Expanded")
                        .font(Typography.Command.caption)
                        .foregroundStyle(.secondary)

                    BibleInsightIndicator(count: 2, isExpanded: true, onTap: {})
                }

                // Interactive
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Interactive (tap to toggle)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Theme.Spacing.xxl + Theme.Spacing.sm) {
                        BibleInsightIndicator(count: 1, isExpanded: expanded1) {
                            withAnimation(Theme.Animation.settle) {
                                expanded1.toggle()
                            }
                        }

                        BibleInsightIndicator(count: 4, isExpanded: expanded2) {
                            withAnimation(Theme.Animation.settle) {
                                expanded2.toggle()
                            }
                        }

                        BibleInsightIndicator(count: 2, isExpanded: expanded3) {
                            withAnimation(Theme.Animation.settle) {
                                expanded3.toggle()
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.xxl + Theme.Spacing.sm)
            .background(Color.bibleInsightParchment)
        }
    }

    return PreviewContainer()
}

#Preview("Indicator in Verse Context") {
    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("In the beginning was the Word, and the Word was with God, and the Word was God.")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            BibleInsightIndicator(count: 3, isExpanded: false, onTap: {})
        }

        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("The same was in the beginning with God.")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            BibleInsightIndicator(count: 1, isExpanded: true, onTap: {})
        }
    }
    .padding(Theme.Spacing.xxl + Theme.Spacing.xs)
    .background(Color.bibleInsightParchment)
}
