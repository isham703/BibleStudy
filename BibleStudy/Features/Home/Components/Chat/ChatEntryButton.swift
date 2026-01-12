import SwiftUI

// MARK: - Mock Chat Entry Button
// Floating AI chat entry point with glass styling

struct ChatEntryButton: View {
    @State private var floatOffset: CGFloat = 0
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bubble.left.fill")
                .font(Typography.Icon.md.weight(.medium))
                .foregroundStyle(Color("AccentBronze"))

            Text("Ask AI anything...")
                .font(Typography.Command.subheadline.weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.textSecondary))
        )
        .background(
            Capsule()
                .fill(
                    // swiftlint:disable:next hardcoded_opacity
                    LinearGradient(
                        colors: [
                            Color("AppTextPrimary").opacity(Theme.Opacity.overlay),
                            Color("AppTextPrimary").opacity(Theme.Opacity.subtle)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    Color("AppTextPrimary").opacity(Theme.Opacity.subtle),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .shadow(color: .black.opacity(Theme.Opacity.selectionBackground), radius: 16, y: 8)
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
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(color)

                if let _ = numericValue, hasAnimated {
                    Text("\(displayedValue)")
                        .font(Typography.Command.title3.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .contentTransition(.numericText())
                } else {
                    Text(value)
                        .font(Typography.Command.title3.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }

            Text(label)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.textSecondary))
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface.opacity(Theme.Opacity.subtle))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Color("AppTextPrimary").opacity(Theme.Opacity.subtle),
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
    ZStack {
        Color.appBackground.ignoresSafeArea()

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
                    color: Color("AccentBronze")
                )

                MockMetricPill(
                    icon: "sparkles",
                    value: "5",
                    label: "due",
                    color: Color("AppAccentAction")
                )
            }
            .padding(.horizontal)
        }
    }
}
