import SwiftUI

// MARK: - Breathe View

/// Standalone breathing exercise experience with pattern selection and session tracking.
struct BreatheView: View {
    @Environment(AppState.self) private var appState
    @State private var state = BreathingState()

    private let circleSize: CGFloat = 280

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Aurora background
                BreathingAuroraBackground.forPattern(state.selectedPattern, isActive: state.isActive)
                    .ignoresSafeArea()

                // Dark overlay for contrast
                Color.black.opacity(Theme.Opacity.focusStroke)
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xxl + 6) {
                    // Header
                    headerView

                    // Main breathing visualization
                    BreathingVisualization(
                        scale: state.breathScale,
                        isActive: state.isActive,
                        phase: state.currentPhase,
                        color: state.selectedPattern.color,
                        iconStyle: .standard,
                        circleSize: circleSize
                    )
                    .frame(height: 230)
                    .onTapGesture {
                        state.toggle()
                    }

                    // Phase display
                    phaseDisplay
                        .frame(height: 70)
                        .animation(Theme.Animation.fade, value: state.currentPhase)

                    // Flexible spacer
                    Color.clear.frame(height: max(0, (geometry.size.height - 750) / 2))

                    // Session stats
                    if state.cyclesCompleted > 0 || state.isActive {
                        SessionStats(
                            cyclesCompleted: state.cyclesCompleted,
                            totalTime: state.totalTime,
                            pattern: state.selectedPattern
                        )
                        .padding(.horizontal, Theme.Spacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Pattern selector
                    PatternSelector(
                        selectedPattern: Binding(
                            get: { state.selectedPattern },
                            set: { state.selectPattern($0) }
                        ),
                        patterns: BreathingPattern.patterns
                    )
                    .disabled(state.isActive)
                    .opacity(state.isActive ? 0.5 : 1)

                    // Control button
                    controlButton
                        .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 10))

                    Spacer()
                }
                .padding(.top, max(60, geometry.safeAreaInsets.top + 20))
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            appState.hideTabBar = true
        }
        .onDisappear {
            state.stop()
            appState.hideTabBar = false
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Breathe")
                // swiftlint:disable:next hardcoded_font_system
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(state.selectedPattern.description)
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                .multilineTextAlignment(.center)
        }
        .scaleEffect(state.isActive ? 0.7 : 1.0)
        .padding(.horizontal, Theme.Spacing.xxl + 16)
        .padding(.top, Theme.Spacing.sm + 2)
    }

    // MARK: - Phase Display

    private var phaseDisplay: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(state.currentPhase.rawValue)
                // swiftlint:disable:next hardcoded_font_system
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.opacity)

            if state.isActive && state.currentPhase != .idle {
                Text(state.phaseTimeRemaining)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
            }
        }
    }

    // MARK: - Control Button

    private var controlButton: some View {
        Button {
            state.toggle()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: state.isActive ? "stop.fill" : "play.fill")
                    .font(Typography.Icon.md.weight(.semibold))

                Text(state.isActive ? "Stop Session" : "Start Session")
                    .font(Typography.Command.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                Capsule()
                    .fill(state.isActive ? Color.red.opacity(Theme.Opacity.pressed) : state.selectedPattern.color)
            )
            .shadow(
                color: (state.isActive ? Color.red : state.selectedPattern.color).opacity(Theme.Opacity.disabled),
                radius: 12
            )
        }
    }
}

// MARK: - Preview

#Preview {
    BreatheView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
