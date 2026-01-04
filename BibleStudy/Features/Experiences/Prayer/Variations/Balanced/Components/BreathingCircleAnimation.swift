import SwiftUI

// MARK: - Breathing Circle Animation
// Concentric rings that expand and contract with breathing rhythm

struct BreathingCircleAnimation: View {
    /// Breathing phase from 0 to 1
    var breathePhase: CGFloat

    /// Number of concentric rings
    var ringCount: Int = 3

    /// Base size of the innermost ring
    var baseSize: CGFloat = 80

    /// Ring spacing
    var ringSpacing: CGFloat = 40

    /// Primary color for the rings
    var color: Color = DeepPrayerColors.roseAccent

    /// Center icon
    var centerIcon: String = "hands.sparkles.fill"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Concentric rings
            ForEach(0..<ringCount, id: \.self) { index in
                ring(at: index)
            }

            // Center icon
            Image(systemName: centerIcon)
                .font(.system(size: 32))
                .foregroundStyle(color)
        }
    }

    // MARK: - Ring View

    private func ring(at index: Int) -> some View {
        let size = baseSize + CGFloat(index) * ringSpacing
        let opacity = 0.3 - Double(index) * 0.1
        let scaleOffset = CGFloat(0.1 + Double(index) * 0.05)

        return Circle()
            .stroke(color.opacity(max(opacity, 0.05)), lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * scaleOffset)
    }
}

// MARK: - Animated Breathing Circle

struct AnimatedBreathingCircle: View {
    @State private var breathePhase: CGFloat = 0

    var ringCount: Int = 3
    var baseSize: CGFloat = 80
    var ringSpacing: CGFloat = 40
    var color: Color = DeepPrayerColors.roseAccent
    var centerIcon: String = "hands.sparkles.fill"
    var breathingDuration: Double = 4.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        BreathingCircleAnimation(
            breathePhase: breathePhase,
            ringCount: ringCount,
            baseSize: baseSize,
            ringSpacing: ringSpacing,
            color: color,
            centerIcon: centerIcon
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

// MARK: - Preview

#Preview("Breathing Circles") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        AnimatedBreathingCircle()
    }
}

#Preview("Static Circles") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        VStack(spacing: 60) {
            BreathingCircleAnimation(breathePhase: 0)
            BreathingCircleAnimation(breathePhase: 0.5)
            BreathingCircleAnimation(breathePhase: 1)
        }
        .scaleEffect(0.6)
    }
}
