import SwiftUI

// MARK: - Icon Style

/// Determines which icon set to use for phase display.
enum BreathingIconStyle {
    case standard   // Arrows for inhale/exhale
    case compline   // Spiritual icons (wind, leaf, etc.)
}

// MARK: - Pulsing Core

/// The glowing core inside the breathing circle, with a gentle pulsing effect.
struct PulsingCore: View {
    let isActive: Bool
    let color: Color
    let phase: BreathingPhase
    var iconStyle: BreathingIconStyle = .standard

    @State private var innerPulse = false

    var body: some View {
        ZStack {
            // Outer glow that expands/contracts
            Circle()
                .fill(
                    // swiftlint:disable:next hardcoded_gradient_radius
                    RadialGradient(
                        colors: [color.opacity(Theme.Opacity.disabled), color.opacity(0), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                // swiftlint:disable:next hardcoded_scale_effect
                .scaleEffect(innerPulse ? 1.2 : 1.0)

            // Core disk with radial gradient for depth
            Circle()
                .fill(
                    // swiftlint:disable:next hardcoded_gradient_radius
                    RadialGradient(
                        colors: [.white, color.opacity(Theme.Opacity.pressed), color.opacity(Theme.Opacity.disabled)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 60, height: 60)
                // swiftlint:disable:next hardcoded_shadow_radius
                .shadow(color: color.opacity(Theme.Opacity.strong), radius: 20)

            // Phase icon
            Image(systemName: phaseIcon)
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.lg)
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating, value: isActive)
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                // swiftlint:disable:next hardcoded_animation_ease
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    innerPulse = true
                }
            } else {
                withAnimation(Theme.Animation.settle) {
                    innerPulse = false
                }
            }
        }
    }

    // MARK: - Icon Selection

    private var phaseIcon: String {
        switch iconStyle {
        case .standard:
            return phase.icon
        case .compline:
            return phase.complineIcon
        }
    }
}

// MARK: - Compline Core

/// Specialized pulsing core for Compline with spiritual iconography.
struct ComplinePulsingCore: View {
    let isActive: Bool
    let phase: BreathingPhase

    var body: some View {
        PulsingCore(
            isActive: isActive,
            color: Color.indigoTint,
            phase: phase,
            iconStyle: .compline
        )
    }
}

// MARK: - Preview

#Preview("Pulsing Core - Standard") {
    ZStack {
        Color.black.ignoresSafeArea()

        PulsingCore(
            isActive: true,
            color: .indigo,
            phase: .inhale,
            iconStyle: .standard
        )
    }
}

#Preview("Pulsing Core - Compline") {
    ZStack {
        Color.slateDeep.ignoresSafeArea()

        PulsingCore(
            isActive: true,
            color: Color.indigoTint,
            phase: .exhale,
            iconStyle: .compline
        )
    }
}
