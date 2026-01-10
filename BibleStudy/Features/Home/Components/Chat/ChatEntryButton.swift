import SwiftUI

// MARK: - Mock Chat Entry Button
// Floating AI chat entry point with glass styling

struct ChatEntryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var floatOffset: CGFloat = 0
    @State private var isPressed = false

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bubble.left.fill")
                .font(Typography.Icon.md.weight(.medium))
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))

            Text("Ask AI anything...")
                .font(Typography.Command.subheadline.weight(.medium))
                .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.secondary))
        )
        .background(
            Capsule()
                .fill(
                    // swiftlint:disable:next hardcoded_opacity
                    LinearGradient(
                        colors: [
                            Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.overlay),
                            Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.faint)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.faint),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .shadow(color: .black.opacity(Theme.Opacity.lightMedium), radius: 16, y: 8)
        .offset(y: floatOffset)
        // swiftlint:disable:next hardcoded_scale_effect
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onAppear {
            withAnimation(Theme.Animation.fade) {
                floatOffset = 3
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            // swiftlint:disable:next hardcoded_animation_spring
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }
}

// MARK: - Metric Pill
// Glass metric pill for dashboard header

struct MockMetricPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var displayedValue: Int = 0
    @State private var hasAnimated = false

    private var numericValue: Int? {
        Int(value)
    }

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(color)

                if let _ = numericValue, hasAnimated {
                    Text("\(displayedValue)")
                        .font(SanctuaryTypography.Dashboard.metricNumber)
                        .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
                        .contentTransition(.numericText())
                } else {
                    Text(value)
                        .font(SanctuaryTypography.Dashboard.metricNumber)
                        .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
                }
            }

            Text(label)
                .font(SanctuaryTypography.Dashboard.metricLabel)
                .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.secondary))
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Colors.Surface.surface(for: themeMode).opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.faint),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .onAppear {
            guard let target = numericValue else { return }

            // Animate count up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasAnimated = true
                withAnimation(Theme.Animation.slowFade) {
                    displayedValue = target
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 30) {
            ChatEntryButton()
                .padding(.horizontal)

            HStack(spacing: Theme.Spacing.sm) {
                MockMetricPill(
                    icon: "flame.fill",
                    value: "14",
                    label: "streak",
                    color: .orange
                )

                MockMetricPill(
                    icon: "book.fill",
                    value: "Day 8",
                    label: "of John",
                    color: Colors.Semantic.accentSeal(for: themeMode)
                )

                MockMetricPill(
                    icon: "sparkles",
                    value: "5",
                    label: "due",
                    color: Colors.Semantic.accentAction(for: themeMode)
                )
            }
            .padding(.horizontal)
        }
    }
}
