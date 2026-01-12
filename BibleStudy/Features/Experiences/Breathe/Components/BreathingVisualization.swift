import SwiftUI

// MARK: - Breathing Visualization

/// Complete breathing visualization combining rings, main disc, and pulsing core.
struct BreathingVisualization: View {
    let scale: CGFloat
    let isActive: Bool
    let phase: BreathingPhase
    let color: Color
    var iconStyle: BreathingIconStyle = .standard
    var circleSize: CGFloat = 280
    var ringCount: Int = 4

    var body: some View {
        ZStack {
            // Outer decorative rings
            BreathingRingStack(
                scale: scale,
                color: color,
                ringCount: ringCount,
                baseSize: circleSize
            )

            // Main breathing disc
            mainDisc

            // Glowing core with phase icon
            PulsingCore(
                isActive: isActive,
                color: color,
                phase: phase,
                iconStyle: iconStyle
            )
            .scaleEffect(scale * 0.8)
        }
    }

    // MARK: - Main Disc

    private var mainDisc: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(Theme.Opacity.disabled),
                        color.opacity(Theme.Opacity.selectionBackground),
                        color.opacity(Theme.Opacity.subtle)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: circleSize / 2
                )
            )
            .frame(width: circleSize, height: circleSize)
            .scaleEffect(scale)
            .shadow(color: color.opacity(Theme.Opacity.focusStroke), radius: 24)
    }
}

// MARK: - Compline Breathing Visualization

/// Simplified visualization for Compline with preset styling.
struct ComplineBreathingVisualization: View {
    let scale: CGFloat
    let isActive: Bool
    let phase: BreathingPhase

    private let starlightColor = Color("AccentBronze").opacity(0.3)

    var body: some View {
        BreathingVisualization(
            scale: scale,
            isActive: isActive,
            phase: phase,
            color: starlightColor,
            iconStyle: .compline,
            circleSize: 200,
            ringCount: 3
        )
    }
}

// MARK: - Preview

#Preview("Breathing Visualization - Standalone") {
    ZStack {
        Color.black.ignoresSafeArea()

        BreathingVisualization(
            scale: 0.85,
            isActive: true,
            phase: .inhale,
            color: .indigo,
            iconStyle: .standard
        )
    }
}

#Preview("Breathing Visualization - Compline") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        ComplineBreathingVisualization(
            scale: 0.7,
            isActive: true,
            phase: .hold1
        )
    }
}
