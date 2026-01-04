import SwiftUI

// MARK: - Mock Chat Entry Button
// Floating AI chat entry point with glass styling

struct ChatEntryButton: View {
    @State private var floatOffset: CGFloat = 0
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.divineGold)

            Text("Ask AI anything...")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.fadedMoonlight)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.5))
        )
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .offset(y: floatOffset)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onAppear {
            withAnimation(AppTheme.Animation.float) {
                floatOffset = 3
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
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
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)

                if let _ = numericValue, hasAnimated {
                    Text("\(displayedValue)")
                        .font(SanctuaryTypography.Dashboard.metricNumber)
                        .foregroundStyle(Color.moonlitParchment)
                        .contentTransition(.numericText())
                } else {
                    Text(value)
                        .font(SanctuaryTypography.Dashboard.metricNumber)
                        .foregroundStyle(Color.moonlitParchment)
                }
            }

            Text(label)
                .font(SanctuaryTypography.Dashboard.metricLabel)
                .foregroundStyle(Color.fadedMoonlight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(.ultraThinMaterial.opacity(0.3))
        )
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.glassOverlay)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .onAppear {
            guard let target = numericValue else { return }

            // Animate count up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasAnimated = true
                withAnimation(.easeOut(duration: 1.0)) {
                    displayedValue = target
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VStack(spacing: 30) {
            ChatEntryButton()
                .padding(.horizontal)

            HStack(spacing: AppTheme.Spacing.sm) {
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
                    color: .divineGold
                )

                MockMetricPill(
                    icon: "sparkles",
                    value: "5",
                    label: "due",
                    color: .lapisLazuli
                )
            }
            .padding(.horizontal)
        }
    }
}
