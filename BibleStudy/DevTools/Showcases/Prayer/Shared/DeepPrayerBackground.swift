import SwiftUI

// MARK: - Deep Prayer Background
// Reusable animated background with breathing rose glow effect

struct DeepPrayerBackground: View {
    /// Breathing animation phase (0 to 1)
    var breathePhase: CGFloat = 0

    /// Whether to show the gold accent
    var showGoldAccent: Bool = true

    /// Intensity of the rose glow (0 to 1)
    var glowIntensity: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Base: Deep sacred navy
            DeepPrayerColors.sacredNavy

            // Rose breathing glow from center
            RadialGradient(
                colors: [
                    DeepPrayerColors.roseAccent.opacity(baseGlowOpacity + animatedGlowOpacity),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            // Optional gold accent from top-trailing
            if showGoldAccent {
                RadialGradient(
                    colors: [
                        DeepPrayerColors.goldAccent.opacity(0.05 * glowIntensity),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 300
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Computed Properties

    private var baseGlowOpacity: Double {
        0.08 * glowIntensity
    }

    private var animatedGlowOpacity: Double {
        guard !reduceMotion else { return 0 }
        return breathePhase * 0.04 * glowIntensity
    }
}

// MARK: - Animated Background Wrapper

struct AnimatedDeepPrayerBackground: View {
    @State private var breathePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var showGoldAccent: Bool = true
    var glowIntensity: Double = 1.0
    var breathingDuration: Double = 4.0

    var body: some View {
        DeepPrayerBackground(
            breathePhase: breathePhase,
            showGoldAccent: showGoldAccent,
            glowIntensity: glowIntensity
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: breathingDuration)
                .repeatForever(autoreverses: true)
            ) {
                breathePhase = 1
            }
        }
    }
}

// MARK: - View Modifier for Easy Application

extension View {
    /// Applies the deep prayer background with optional breathing animation
    func deepPrayerBackground(
        animated: Bool = true,
        showGoldAccent: Bool = true,
        glowIntensity: Double = 1.0,
        breathingDuration: Double = 4.0
    ) -> some View {
        self.background {
            if animated {
                AnimatedDeepPrayerBackground(
                    showGoldAccent: showGoldAccent,
                    glowIntensity: glowIntensity,
                    breathingDuration: breathingDuration
                )
            } else {
                DeepPrayerBackground(
                    showGoldAccent: showGoldAccent,
                    glowIntensity: glowIntensity
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Deep Prayer Background") {
    VStack(spacing: 24) {
        Text("Prayers from the Deep")
            .font(Typography.Scripture.title.weight(.medium))
            .foregroundStyle(DeepPrayerColors.primaryText)

        Text("Contemplative. Intimate. Sacred.")
            .font(Typography.Command.subheadline)
            .foregroundStyle(DeepPrayerColors.secondaryText)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .deepPrayerBackground()
}

#Preview("Static Background") {
    VStack {
        Text("No Animation")
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .deepPrayerBackground(animated: false)
}
