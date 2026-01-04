import SwiftUI
import UIKit

// MARK: - Prayers From the Deep
// AI crafts prayers in sacred traditions - Balanced variation
// Full-screen immersive phases with breathing animations

struct PrayersFromDeepView: View {
    @Environment(AppState.self) private var appState
    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0
    @State private var isSaving = false

    private let prayerService = PrayerService.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Animated background
            AnimatedDeepPrayerBackground(breathingDuration: 4.0)
                .ignoresSafeArea()

            // Content based on phase
            Group {
                switch flowState.phase {
                case .input:
                    inputPhase
                case .generating:
                    generatingPhase
                case .displaying:
                    displayPhase
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

            // Error overlay (non-crisis errors)
            if flowState.hasError, let error = flowState.error {
                errorOverlay(for: error)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationTitle("Prayers from the Deep")
        .navigationBarTitleDisplayMode(.inline)
        // Crisis modal sheet (self-harm detected)
        .sheet(isPresented: $flowState.showCrisisModal) {
            CrisisHelpModal(
                onDismiss: { flowState.dismissCrisisModal() }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            appState.hideTabBar = true
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
            startBreathingAnimation()
        }
        .onDisappear {
            appState.hideTabBar = false
            flowState.reset()
        }
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
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
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        BalancedGeneratingPhase(
            tradition: flowState.selectedTradition,
            breathePhase: breathePhase
        )
    }

    // MARK: - Display Phase

    @ViewBuilder
    private var displayPhase: some View {
        if let prayer = flowState.generatedPrayer {
            BalancedDisplayPhase(
                prayer: prayer,
                tradition: flowState.selectedTradition,
                onSave: { savePrayer(prayer) },
                onShare: { sharePrayer(prayer) },
                onNew: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        flowState.reset()
                    }
                }
            )
        } else {
            // Fallback - should not happen in normal flow
            BalancedDisplayPhase(
                prayer: MockPrayer.psalmicLament,
                tradition: flowState.selectedTradition,
                onSave: { },
                onShare: { },
                onNew: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        flowState.reset()
                    }
                }
            )
        }
    }

    // MARK: - Save Prayer

    private func savePrayer(_ prayer: Prayer) {
        guard !isSaving else { return }
        isSaving = true

        Task {
            do {
                try await prayerService.savePrayer(prayer)
                flowState.showActionToast("Prayer saved")
            } catch {
                flowState.showActionToast("Could not save prayer")
            }
            isSaving = false
        }
    }

    // MARK: - Share Prayer

    private func sharePrayer(_ prayer: Prayer) {
        let shareText = """
        \(prayer.content)

        \(prayer.amen)

        — A prayer in the \(prayer.tradition.displayName) tradition
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        flowState.showActionToast("Sharing prayer")
    }

    // MARK: - Error Overlay

    private func errorOverlay(for error: PrayerGenerationError) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        flowState.clearError()
                    }
                }

            // Error card
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DeepPrayerColors.roseAccent)

                Text(error.localizedDescription)
                    .font(.system(size: 16))
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        flowState.clearError()
                    }
                }) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(DeepPrayerColors.roseAccent)
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DeepPrayerColors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DeepPrayerColors.roseBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
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

#Preview("Prayers From the Deep") {
    PrayersFromDeepView()
}
