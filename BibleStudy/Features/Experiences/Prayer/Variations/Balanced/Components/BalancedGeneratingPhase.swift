import SwiftUI

// MARK: - Balanced Generating Phase
// Contemplative waiting animation with breathing circles

struct BalancedGeneratingPhase: View {
    let tradition: PrayerTradition
    var breathePhase: CGFloat

    @State private var textOpacity: Double = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Breathing circles animation
            BreathingCircleAnimation(
                breathePhase: breathePhase,
                ringCount: 3,
                baseSize: 80,
                ringSpacing: 40
            )

            // Status text
            VStack(spacing: 12) {
                Text("Crafting your prayer...")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)

                Text(traditionMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
                    .opacity(reduceMotion ? 1.0 : textOpacity)
            }

            Spacer()
        }
        .onAppear {
            startTextPulse()
        }
    }

    // MARK: - Tradition-specific message

    private var traditionMessage: String {
        switch tradition {
        case .psalmicLament:
            return "Drawing from the well of the Psalms"
        case .desertFathers:
            return "Entering the silence of the desert"
        case .celtic:
            return "Weaving the threads of creation"
        case .ignatian:
            return "Opening the imagination to God"
        }
    }

    // MARK: - Animation

    private func startTextPulse() {
        guard !reduceMotion else {
            textOpacity = 1.0
            return
        }
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            textOpacity = 1.0
        }
    }
}

// MARK: - Preview

#Preview("Generating Phase") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        BalancedGeneratingPhase(
            tradition: .psalmicLament,
            breathePhase: 0.5
        )
    }
}

#Preview("All Traditions") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        TabView {
            ForEach(PrayerTradition.allCases) { tradition in
                BalancedGeneratingPhase(
                    tradition: tradition,
                    breathePhase: 0.5
                )
                .tag(tradition)
            }
        }
        .tabViewStyle(.page)
    }
}
