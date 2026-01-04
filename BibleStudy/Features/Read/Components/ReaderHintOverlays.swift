import SwiftUI

// MARK: - Swipe Hint Overlay
// Shows animated arrows at screen edges to teach swipe navigation

struct SwipeHintOverlay: View {
    let opacity: Double
    @State private var animateLeft = false
    @State private var animateRight = false

    var body: some View {
        HStack {
            // Left edge hint (swipe right to go back)
            VStack {
                Spacer()
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(Typography.UI.title3)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.left")
                        .font(Typography.UI.subheadline)
                        .fontWeight(.medium)
                        .opacity(AppTheme.Opacity.strong)
                }
                .foregroundStyle(Color.accentGold)
                .offset(x: animateLeft ? 8 : 0)
                .animation(
                    AppTheme.Animation.reduced(AppTheme.Animation.slow.repeatForever(autoreverses: true)),
                    value: animateLeft
                )
                Spacer()
            }
            .frame(width: AppTheme.IconContainer.large)
            .background(
                LinearGradient(
                    colors: [Color.appBackground.opacity(AppTheme.Opacity.overlay), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            Spacer()

            // Right edge hint (swipe left to go forward)
            VStack {
                Spacer()
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.right")
                        .font(Typography.UI.subheadline)
                        .fontWeight(.medium)
                        .opacity(AppTheme.Opacity.strong)
                    Image(systemName: "chevron.right")
                        .font(Typography.UI.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.accentGold)
                .offset(x: animateRight ? -8 : 0)
                .animation(
                    AppTheme.Animation.reduced(AppTheme.Animation.slow.repeatForever(autoreverses: true)),
                    value: animateRight
                )
                Spacer()
            }
            .frame(width: AppTheme.IconContainer.large)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.appBackground.opacity(AppTheme.Opacity.overlay)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            animateLeft = true
            animateRight = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Insight Hint Overlay
// Shows hint to tap a verse for AI insights (after onboarding)

struct InsightHintOverlay: View {
    let opacity: Double
    @State private var animateTap = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                // Animated tap icon
                ZStack {
                    Circle()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateTap ? 1.3 : 1.0)
                        .opacity(animateTap ? 0 : 0.5)

                    Image(systemName: "hand.tap.fill")
                        .font(Typography.UI.title1)
                        .foregroundStyle(Color.accentGold)
                        .offset(y: animateTap ? -4 : 0)
                }
                .animation(
                    AppTheme.Animation.reduced(AppTheme.Animation.slow.repeatForever(autoreverses: true)),
                    value: animateTap
                )

                Text("Tap a verse for insights")
                    .font(Typography.UI.headline)
                    .foregroundStyle(Color.primaryText)

                Text("Get AI-powered explanations, cross-references, and more")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .padding(.vertical, AppTheme.Spacing.xl)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.elevatedBackground)
                    .shadow(color: .black.opacity(AppTheme.Opacity.medium), radius: 16, y: 8)
            )
            .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()
                .frame(height: 120)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            animateTap = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Reading Menu Hint Overlay
// Shows hint pointing to the reading menu button (Apple Books-style chrome)

struct ReadingMenuHintOverlay: View {
    let opacity: Double
    @State private var animatePulse = false

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                    // Hint card
                    VStack(spacing: AppTheme.Spacing.sm) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "hand.point.down.fill")
                                .font(Typography.UI.title2)
                                .foregroundStyle(Color.accentGold)
                                .scaleEffect(animatePulse ? 1.1 : 1.0)
                                .animation(
                                    AppTheme.Animation.reduced(AppTheme.Animation.slow.repeatForever(autoreverses: true)),
                                    value: animatePulse
                                )

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text("Tap for reading controls")
                                    .font(Typography.UI.headline)
                                    .foregroundStyle(Color.primaryText)

                                Text("Access contents, search, settings & more")
                                    .font(Typography.UI.caption1)
                                    .foregroundStyle(Color.secondaryText)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.elevatedBackground)
                            .shadow(color: .black.opacity(AppTheme.Opacity.medium), radius: 12, y: -4)
                    )

                    // Arrow pointing down-right to the button
                    Image(systemName: "arrow.turn.right.down")
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.accentGold)
                        .padding(.trailing, AppTheme.Spacing.xl)
                }
                .padding(.trailing, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxxl + AppTheme.Spacing.xxxl) // Position above the menu button
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            animatePulse = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Swipe Hint") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SwipeHintOverlay(opacity: 1.0)
    }
}

#Preview("Insight Hint") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        InsightHintOverlay(opacity: 1.0)
    }
}

#Preview("Reading Menu Hint") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ReadingMenuHintOverlay(opacity: 1.0)
    }
}
