import SwiftUI

// MARK: - Illuminated Capital View
// Gold-decorated first letter with breathing glow effect
// Inspired by medieval illuminated manuscripts

struct IlluminatedCapitalView: View {
    let letter: String
    let isVisible: Bool

    @State private var glowIntensity: Double = AppTheme.Opacity.medium

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Typography for illuminated capitals using the new Illuminated design system
    private var illuminatedFont: Font {
        Typography.Illuminated.dropCap(size: Typography.Scale.display)
    }

    var body: some View {
        ZStack {
            // Outer glow layer
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(Color.divineGold)
                .blur(radius: AppTheme.Blur.medium)
                .opacity(glowIntensity * AppTheme.Opacity.strong)

            // Inner glow layer
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(Color.divineGold)
                .blur(radius: AppTheme.Blur.subtle)
                .opacity(glowIntensity * AppTheme.Opacity.pressed)

            // Main letter
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.divineGold,
                            Color.divineGold.opacity(AppTheme.Opacity.nearOpaque),
                            Color.illuminatedGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.divineGold.opacity(AppTheme.Opacity.disabled),
                    radius: AppTheme.Blur.subtle,
                    x: 0,
                    y: 2
                )
        }
        .frame(width: 56, height: 56)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : AppTheme.Scale.reduced)
        .onAppear {
            startBreathingAnimation()
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        guard !respectsReducedMotion else {
            glowIntensity = AppTheme.Opacity.heavy
            return
        }

        // Very subtle breathing: 0.3 → 0.5 opacity over 4 seconds
        // Using slow animation repeated for ambient effect
        withAnimation(
            AppTheme.Animation.slow
                .repeatForever(autoreverses: true)
                .speed(0.1) // Slow down to ~4 seconds
        ) {
            glowIntensity = AppTheme.Opacity.heavy
        }
    }
}

// MARK: - Compact Illuminated Capital
// Smaller variant for inline use

struct CompactIlluminatedCapital: View {
    let letter: String

    @State private var glowIntensity: Double = AppTheme.Opacity.disabled

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Compact illuminated capital font (slightly smaller than full)
    private var compactFont: Font {
        Typography.Illuminated.dropCapSmall()
    }

    var body: some View {
        ZStack {
            // Glow layer
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Color.divineGold)
                .blur(radius: AppTheme.Blur.subtle)
                .opacity(glowIntensity * AppTheme.Opacity.heavy)

            // Main letter
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Color.divineGold)
        }
        .frame(width: 40, height: 40)
        .onAppear {
            guard !respectsReducedMotion else { return }

            withAnimation(
                AppTheme.Animation.slow
                    .repeatForever(autoreverses: true)
                    .speed(0.1)
            ) {
                glowIntensity = AppTheme.Opacity.strong
            }
        }
    }
}

// MARK: - Decorative Border
// Optional ornamental frame for illuminated capitals

struct IlluminatedBorder: View {
    @State private var shimmerOffset: CGFloat = -1

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.divineGold.opacity(AppTheme.Opacity.medium),
                        Color.divineGold.opacity(AppTheme.Opacity.strong),
                        Color.divineGold.opacity(AppTheme.Opacity.medium)
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0),
                    endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 1)
                ),
                lineWidth: AppTheme.Border.regular
            )
            .onAppear {
                guard !respectsReducedMotion else {
                    shimmerOffset = 0
                    return
                }

                // Slow shimmer animation using standard animation with speed modifier
                withAnimation(
                    AppTheme.Animation.slow
                        .repeatForever(autoreverses: false)
                        .speed(0.13) // ~3 seconds
                ) {
                    shimmerOffset = 1.5
                }
            }
    }
}

// MARK: - Preview

#Preview("Illuminated Capital") {
    VStack(spacing: AppTheme.Spacing.xxxl) {
        Text("Illuminated Capitals")
            .font(Typography.UI.headline)

        HStack(spacing: AppTheme.Spacing.xl) {
            IlluminatedCapitalView(letter: "W", isVisible: true)
            IlluminatedCapitalView(letter: "B", isVisible: true)
            IlluminatedCapitalView(letter: "T", isVisible: true)
        }

        Text("Compact Variant")
            .font(Typography.UI.headline)

        HStack(spacing: AppTheme.Spacing.lg) {
            CompactIlluminatedCapital(letter: "A")
            CompactIlluminatedCapital(letter: "M")
            CompactIlluminatedCapital(letter: "S")
        }

        Text("With Border")
            .font(Typography.UI.headline)

        ZStack {
            IlluminatedBorder()
            IlluminatedCapitalView(letter: "G", isVisible: true)
        }
        .frame(width: 80, height: 80)
    }
    .padding()
    .background(Color.appBackground)
}
