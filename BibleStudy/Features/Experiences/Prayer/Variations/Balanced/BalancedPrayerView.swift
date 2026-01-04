import SwiftUI

// MARK: - Balanced Prayer View
// Full-screen immersive phases with breathing animations
// Visual Density: Medium | Animation: Moderate | Interaction: Full-screen

struct BalancedPrayerView: View {
    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Animated background
            AnimatedDeepPrayerBackground(breathingDuration: 4.0)

            // Content based on phase
            Group {
                switch flowState.phase {
                case .input:
                    BalancedInputPhase(
                        text: $flowState.inputText,
                        selectedTradition: $flowState.selectedTradition,
                        canGenerate: flowState.canGenerate,
                        onGenerate: {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                flowState.startGeneration(duration: 3.0)
                            }
                        }
                    )
                case .generating:
                    BalancedGeneratingPhase(
                        tradition: flowState.selectedTradition,
                        breathePhase: breathePhase
                    )
                case .displaying:
                    BalancedDisplayPhase(
                        prayer: flowState.generatedPrayer ?? MockPrayer.psalmicLament,
                        tradition: flowState.selectedTradition,
                        onSave: { flowState.showActionToast("Saved") },
                        onShare: { flowState.showActionToast("Shared") },
                        onNew: {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                flowState.reset()
                            }
                        }
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)).animation(.easeOut(duration: 0.6)),
                removal: .opacity.animation(.easeIn(duration: 0.3))
            ))

            // Toast overlay
            if flowState.showToast {
                VStack {
                    Spacer()

                    Text(flowState.toastMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DeepPrayerColors.primaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(DeepPrayerColors.surfaceElevated)
                                .overlay(
                                    Capsule()
                                        .stroke(DeepPrayerColors.roseBorder, lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
            startBreathingAnimation()
        }
        .onDisappear {
            flowState.reset()
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            breathePhase = 1
        }
    }
}

// MARK: - Preview

#Preview("Balanced Prayer") {
    BalancedPrayerView()
}
