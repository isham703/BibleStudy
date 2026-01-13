import SwiftUI

// MARK: - Drop Cap View
// Decorative first letter with breathing glow effect

struct DropCapView: View {
    let letter: String
    let isVisible: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var glowIntensity: Double = Theme.Opacity.textSecondary

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Typography for drop caps - large decorative serif
    private var dropCapFont: Font {
        Typography.Decorative.dropCap
    }

    var body: some View {
        ZStack {
            // Outer glow layer
            Text(letter.uppercased())
                .font(dropCapFont)
                .foregroundStyle(Color("AccentBronze"))
                .blur(radius: 8)
                .opacity(glowIntensity * Theme.Opacity.textPrimary)

            // Inner glow layer
            Text(letter.uppercased())
                .font(dropCapFont)
                .foregroundStyle(Color("AccentBronze"))
                .blur(radius: 4)
                .opacity(glowIntensity * Theme.Opacity.pressed)

            // Main letter
            Text(letter.uppercased())
                .font(dropCapFont)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("AccentBronze"),
                            Color("AccentBronze").opacity(Theme.Opacity.textPrimary),
                            Color("AccentBronze").opacity(Theme.Opacity.textPrimary)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color("AccentBronze").opacity(Theme.Opacity.disabled),
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
            glowIntensity = Theme.Opacity.textSecondary
            return
        }

        // Very subtle breathing: 0.3 → 0.5 opacity over 4 seconds
        // Using slow animation repeated for ambient effect
        withAnimation(
            Theme.Animation.slowFade
                .repeatForever(autoreverses: true)
                .speed(0.1) // Slow down to ~4 seconds
        ) {
            glowIntensity = Theme.Opacity.textSecondary
        }
    }
}

// MARK: - Compact Drop Cap
// Smaller variant for inline use

struct CompactDropCap: View {
    let letter: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var glowIntensity: Double = Theme.Opacity.disabled

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Compact drop cap font (slightly smaller than full)
    private var compactFont: Font {
        Typography.Decorative.dropCapCompact
    }

    var body: some View {
        ZStack {
            // Glow layer
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Color("AccentBronze"))
                .blur(radius: 4)
                .opacity(glowIntensity * Theme.Opacity.textSecondary)

            // Main letter
            Text(letter.uppercased())
                .font(compactFont)
                .foregroundStyle(Color("AccentBronze"))
        }
        .frame(width: 40, height: 40)
        .onAppear {
            guard !respectsReducedMotion else { return }

            withAnimation(
                Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                    .speed(0.1)
            ) {
                glowIntensity = Theme.Opacity.textPrimary
            }
        }
    }
}

// MARK: - Decorative Border
// Optional ornamental frame for drop caps

struct DecorativeBorder: View {
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
                        Color("AccentBronze").opacity(Theme.Opacity.textSecondary),
                        Color("AccentBronze").opacity(Theme.Opacity.textPrimary),
                        Color("AccentBronze").opacity(Theme.Opacity.textSecondary)
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

#Preview("Drop Cap") {
    VStack(spacing: Theme.Spacing.xxl) {
        Text("Drop Caps")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl) {
            DropCapView(letter: "W", isVisible: true)
            DropCapView(letter: "B", isVisible: true)
            DropCapView(letter: "T", isVisible: true)
        }

        Text("Compact Variant")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.lg) {
            CompactDropCap(letter: "A")
            CompactDropCap(letter: "M")
            CompactDropCap(letter: "S")
        }

        Text("With Border")
            .font(Typography.Command.headline)

        ZStack {
            DecorativeBorder()
            DropCapView(letter: "G", isVisible: true)
        }
        .frame(width: 80, height: 80)
    }
    .padding()
    .background(Color.appBackground)
}
