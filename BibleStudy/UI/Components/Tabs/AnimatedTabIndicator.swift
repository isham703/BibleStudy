//
//  AnimatedTabIndicator.swift
//  BibleStudy
//
//  Animated sliding underline indicator for tab bars.
//  Position and opacity interpolate based on scroll progress.
//
//  Motion: Uses Theme.Animation.settle (260ms easeOut) - NO springs
//

import SwiftUI

// MARK: - Animated Tab Indicator

/// A sliding underline indicator that follows scroll progress between tabs.
///
/// The indicator slides smoothly between tab positions based on `scrollProgress`,
/// with a subtle opacity fade during transitions.
///
/// Usage:
/// ```swift
/// AnimatedTabIndicator(
///     tabCount: 2,
///     tabWidths: [100, 100],
///     scrollProgress: scrollProgress
/// )
/// ```
struct AnimatedTabIndicator: View {
    /// Number of tabs
    let tabCount: Int

    /// Width of each tab (for position calculation)
    let tabWidths: [CGFloat]

    /// Continuous scroll progress: 0.0 = first tab, 1.0 = second tab, etc.
    let scrollProgress: CGFloat

    /// Height of the indicator line
    var indicatorHeight: CGFloat = 2

    /// Scale factor for indicator width (0.5 = 50% of tab width, centered)
    var widthScale: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .fill(Color("AppTextPrimary"))
            .frame(width: scaledWidth, height: indicatorHeight)
            .frame(width: totalTabsWidth, alignment: .leading)
            .offset(x: centeredOffset)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(indicatorOpacity)
            .animation(
                reduceMotion ? .none : Theme.Animation.settle,
                value: scrollProgress
            )
    }

    /// Total width of all tabs combined (for centering the indicator container)
    private var totalTabsWidth: CGFloat {
        tabWidths.reduce(0, +)
    }

    /// Scaled width of the indicator (narrower than full tab width)
    private var scaledWidth: CGFloat {
        currentWidth * widthScale
    }

    /// Offset that centers the scaled indicator within each tab
    private var centeredOffset: CGFloat {
        // Start with the base offset to the tab position
        let baseOffset = indicatorOffset
        // Add centering offset: (fullWidth - scaledWidth) / 2
        let centeringOffset = currentWidth * (1 - widthScale) / 2
        return baseOffset + centeringOffset
    }

    // MARK: - Computed Properties

    /// Current width of the indicator (interpolates between tab widths)
    private var currentWidth: CGFloat {
        guard tabCount > 0, !tabWidths.isEmpty else { return 0 }

        let clampedProgress = max(0, min(CGFloat(tabCount - 1), scrollProgress))
        let lowerIndex = Int(clampedProgress)
        let upperIndex = min(lowerIndex + 1, tabCount - 1)
        let fraction = clampedProgress - CGFloat(lowerIndex)

        let lowerWidth = tabWidths[safe: lowerIndex] ?? 0
        let upperWidth = tabWidths[safe: upperIndex] ?? lowerWidth

        return lowerWidth + (upperWidth - lowerWidth) * fraction
    }

    /// X offset for the indicator position
    private var indicatorOffset: CGFloat {
        guard tabCount > 0, !tabWidths.isEmpty else { return 0 }

        let clampedProgress = max(0, min(CGFloat(tabCount - 1), scrollProgress))
        let lowerIndex = Int(clampedProgress)
        let fraction = clampedProgress - CGFloat(lowerIndex)

        // Calculate offset to the start of the lower tab
        var offset: CGFloat = 0
        for i in 0..<lowerIndex {
            offset += tabWidths[safe: i] ?? 0
        }

        // Add fractional progress toward the next tab
        if lowerIndex < tabCount - 1 {
            let currentWidth = tabWidths[safe: lowerIndex] ?? 0
            offset += currentWidth * fraction
        }

        return offset
    }

    /// Opacity with subtle fade during transitions
    private var indicatorOpacity: Double {
        let fractionalPart = scrollProgress.truncatingRemainder(dividingBy: 1.0)
        let distanceFromRest = abs(fractionalPart - 0.5) * 2

        // Slight fade (30%) during mid-transition, full opacity at rest
        return Theme.Opacity.textPrimary * (1.0 - (1.0 - distanceFromRest) * 0.3)
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("Animated Tab Indicator") {
    AnimatedTabIndicatorPreview()
}

private struct AnimatedTabIndicatorPreview: View {
    @State private var scrollProgress: CGFloat = 0.0

    private let tabWidths: [CGFloat] = [80, 60]

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Text("Scroll Progress: \(scrollProgress, specifier: "%.2f")")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))

            // Simulated tab labels
            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { index in
                    Text(index == 0 ? "Sources" : "Notes")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: tabWidths[index])
                }
            }

            // Indicator
            AnimatedTabIndicator(
                tabCount: 2,
                tabWidths: tabWidths,
                scrollProgress: scrollProgress
            )

            // Slider to simulate scrolling
            Slider(value: $scrollProgress, in: 0...1)
                .padding(.horizontal, Theme.Spacing.xxl)

            // Quick jump buttons
            HStack(spacing: Theme.Spacing.lg) {
                Button("Sources") {
                    withAnimation(Theme.Animation.settle) {
                        scrollProgress = 0
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Notes") {
                    withAnimation(Theme.Animation.settle) {
                        scrollProgress = 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.Spacing.xxl)
        .background(Color("AppBackground"))
    }
}
