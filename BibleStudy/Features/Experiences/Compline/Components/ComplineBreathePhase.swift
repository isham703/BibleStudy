import SwiftUI

// MARK: - Compline Breathe Phase

/// 4-7-8 breathing exercise integrated into Compline Phase 1.
/// Uses spiritual iconography and Compline's night theme colors.
struct ComplineBreathePhase: View {
    @State private var state = ComplineBreathingState()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let starlightColor = Color("AppAccentAction").opacity(0.2)

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Phase instruction
            Text(state.currentPhase.rawValue)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.custom("CormorantGaramond-Medium", size: 24))
                .foregroundStyle(starlightColor)
                .contentTransition(.opacity)
                .animation(Theme.Animation.fade, value: state.currentPhase)

            // Main breathing visualization
            ZStack {
                // Aurora background (subtle for Compline)
                if !reduceMotion {
                    BreathingAppBackgroundView.compline(isActive: state.isActive)
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .opacity(Theme.Opacity.focusStroke)
                }

                // Breathing visualization
                ComplineBreathingVisualization(
                    scale: state.breathScale,
                    isActive: state.isActive,
                    phase: state.currentPhase
                )
            }
            .frame(width: 220, height: 220)
            .onTapGesture {
                state.toggle()
            }

            // Cycle progress indicator
            if state.cyclesCompleted > 0 {
                CycleCounter(
                    cyclesCompleted: state.cyclesCompleted,
                    targetCycles: 3,
                    color: starlightColor
                )
                .transition(.opacity)
            }

            // Guidance text
            VStack(spacing: Theme.Spacing.sm) {
                if state.isActive {
                    Text("4 seconds in • 7 seconds hold • 8 seconds out")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(starlightColor.opacity(Theme.Opacity.pressed))
                } else {
                    Text("Tap to begin the 4-7-8 breath")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(starlightColor.opacity(Theme.Opacity.pressed))
                }

                Text("Match your breath to the rhythm")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 12, weight: .regular, design: .serif).italic())
                    .foregroundStyle(starlightColor.opacity(Theme.Opacity.disabled))
            }
        }
        .onDisappear {
            state.stop()
        }
    }
}

// MARK: - Compline Breathe Phase with Binding

/// Version that reports completion state to parent for navigation control.
struct ComplineBreathePhaseWithBinding: View {
    @Binding var hasStartedBreathing: Bool
    @State private var state = ComplineBreathingState()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let starlightColor = Color("AppAccentAction").opacity(0.2)

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Phase instruction
            Text(state.currentPhase.rawValue)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.custom("CormorantGaramond-Medium", size: 24))
                .foregroundStyle(starlightColor)
                .contentTransition(.opacity)
                .animation(Theme.Animation.fade, value: state.currentPhase)

            // Main breathing visualization
            ZStack {
                if !reduceMotion {
                    BreathingAppBackgroundView.compline(isActive: state.isActive)
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .opacity(Theme.Opacity.focusStroke)
                }

                ComplineBreathingVisualization(
                    scale: state.breathScale,
                    isActive: state.isActive,
                    phase: state.currentPhase
                )
            }
            .frame(width: 220, height: 220)
            .onTapGesture {
                state.toggle()
                if state.isActive {
                    hasStartedBreathing = true
                }
            }

            // Cycle progress
            if state.cyclesCompleted > 0 {
                CycleCounter(
                    cyclesCompleted: state.cyclesCompleted,
                    targetCycles: 3,
                    color: starlightColor
                )
                .transition(.opacity)
            }

            // Guidance
            VStack(spacing: Theme.Spacing.sm) {
                if state.isActive {
                    Text("4 seconds in • 7 seconds hold • 8 seconds out")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(starlightColor.opacity(Theme.Opacity.pressed))
                } else {
                    Text("Tap to begin the 4-7-8 breath")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(starlightColor.opacity(Theme.Opacity.pressed))
                }

                Text("Match your breath to the rhythm")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 12, weight: .regular, design: .serif).italic())
                    .foregroundStyle(starlightColor.opacity(Theme.Opacity.disabled))
            }
        }
        .onChange(of: state.isActive) { _, isActive in
            if isActive {
                hasStartedBreathing = true
            }
        }
        .onDisappear {
            state.stop()
        }
    }
}

// MARK: - Preview

#Preview("Compline Breathe Phase") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        ComplineBreathePhase()
    }
}

#Preview("Compline Breathe - With Binding") {
    struct PreviewWrapper: View {
        @State private var hasStarted = false

        var body: some View {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                VStack {
                    ComplineBreathePhaseWithBinding(hasStartedBreathing: $hasStarted)

                    Text(hasStarted ? "User has engaged" : "Waiting...")
                        .foregroundStyle(.white.opacity(Theme.Opacity.textSecondary))
                        .padding(.top, Theme.Spacing.xl)
                }
            }
        }
    }

    return PreviewWrapper()
}
