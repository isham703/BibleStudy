import SwiftUI

// MARK: - Illuminated Capital View
// Gold-decorated first letter with breathing glow effect
// Inspired by medieval illuminated manuscripts

struct IlluminatedCapitalView: View {
    let letter: String
    let isVisible: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var glowIntensity: Double = Theme.Opacity.secondary

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Typography for illuminated capitals - large serif for manuscript effect
    private var illuminatedFont: Font {
        Typography.Decorative.dropCap
    }

    var body: some View {
        ZStack {
            // Outer glow layer
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                .blur(radius: 8)
                .opacity(glowIntensity * Theme.Opacity.primary)

            // Inner glow layer
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                .blur(radius: 4)
                .opacity(glowIntensity * Theme.Opacity.pressed)

            // Main letter
            Text(letter.uppercased())
                .font(illuminatedFont)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)),
                            Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary),
                            Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
        .frame(width: 56, height: 56)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .onAppear {
            startBreathingAnimation()
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        guard !respectsReducedMotion else {
            glowIntensity = Theme.Opacity.secondary
            return
        }

        // Very subtle breathing: 0.3 → 0.5 opacity over 4 seconds
        // Using slow animation repeated for ambient effect
        withAnimation(
            Theme.Animation.slowFade
                .repeatForever(autoreverses: true)
                .speed(0.1) // Slow down to ~4 seconds
        ) {
            glowIntensity = Theme.Opacity.secondary
        }
    }
}

// MARK: - Compact Illuminated Capital
// Smaller variant for inline use

struct CompactIlluminatedCapital: View {
    let letter: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var glowIntensity: Double = Theme.Opacity.disabled

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Compact illuminated capital font (slightly smaller than full)
    private var compactFont: Font {
        Typography.Decorative.dropCapCompact
    }

    var body: some View {
        ZStack {
            // Glow layer
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                .blur(radius: 4)
                .opacity(glowIntensity * Theme.Opacity.secondary)

            // Main letter
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
        .frame(width: 40, height: 40)
        .onAppear {
            guard !respectsReducedMotion else { return }

            withAnimation(
                Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                    .speed(0.1)
            ) {
                glowIntensity = Theme.Opacity.primary
            }
        }
    }
}

// MARK: - Decorative Border
// Optional ornamental frame for illuminated capitals

struct IlluminatedBorder: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmerOffset: CGFloat = -1

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary),
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary),
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary)
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0),
                    endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 1)
                ),
                lineWidth: Theme.Stroke.control
            )
            .onAppear {
                guard !respectsReducedMotion else {
                    shimmerOffset = 0
                    return
                }

                // Slow shimmer animation using standard animation with speed modifier
                withAnimation(
                    Theme.Animation.slowFade
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
    VStack(spacing: Theme.Spacing.xxl) {
        Text("Illuminated Capitals")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl) {
            IlluminatedCapitalView(letter: "W", isVisible: true)
            IlluminatedCapitalView(letter: "B", isVisible: true)
            IlluminatedCapitalView(letter: "T", isVisible: true)
        }

        Text("Compact Variant")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.lg) {
            CompactIlluminatedCapital(letter: "A")
            CompactIlluminatedCapital(letter: "M")
            CompactIlluminatedCapital(letter: "S")
        }

        Text("With Border")
            .font(Typography.Command.headline)

        ZStack {
            IlluminatedBorder()
            IlluminatedCapitalView(letter: "G", isVisible: true)
        }
        .frame(width: 80, height: 80)
    }
    .padding()
    .background(Color.appBackground)
}
