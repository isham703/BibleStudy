import SwiftUI
import UIKit

// MARK: - Prayers From the Deep
// Contemplative Manuscript design - illuminated manuscript aesthetic
// AI-crafted prayers using intention-based categories

struct PrayersFromDeepView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var flowState = PrayerFlowState()
    @State private var illuminationPhase: CGFloat = 0
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool

    private let prayerService = PrayerService.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Parchment Background
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch flowState.phase {
                    case .input:
                        PrayerInputPhase(
                            flowState: flowState,
                            isTextFieldFocused: $isTextFieldFocused,
                            illuminationPhase: illuminationPhase,
                            onCreatePrayer: createPrayer
                        )
                    case .generating:
                        PrayerGeneratingPhase(
                            selectedCategory: flowState.selectedCategory,
                            illuminationPhase: illuminationPhase,
                            reduceMotion: reduceMotion
                        )
                    case .displaying:
                        if let prayer = flowState.generatedPrayer {
                            PrayerDisplayPhase(
                                prayer: prayer,
                                selectedCategory: flowState.selectedCategory,
                                onCopy: { copyPrayer(prayer) },
                                onShare: { sharePrayer(prayer) },
                                onSave: { savePrayer(prayer) },
                                onNewPrayer: resetPrayer
                            )
                        }
                    }
                }
            }
            .scrollClipDisabled()
            .scrollDismissesKeyboard(.interactively)

            // Toast overlay
            if flowState.showToast {
                toastOverlay
            }

            // Error overlay
            if flowState.hasError, let error = flowState.error {
                errorOverlay(for: error)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationTitle("Prayers from the Deep")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $flowState.showCrisisModal) {
            CrisisHelpModal(onDismiss: { flowState.dismissCrisisModal() })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            appState.hideTabBar = true
            startIlluminationAnimation()
        }
        .onDisappear {
            appState.hideTabBar = false
            flowState.reset()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Cancel ongoing generation when app backgrounds (saves battery/data)
            if newPhase == .background && flowState.phase == .generating {
                flowState.cancelAllTasks()
            }
        }
        .withPaywall()  // Show paywall when prayer quota limit is reached
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        GeometryReader { geometry in
            ZStack {
                Color.surfaceParchment

                // Vignette effect
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(Theme.Opacity.disabled)],
                    center: .center,
                    startRadius: geometry.size.width * 0.3,
                    endRadius: geometry.size.width * 0.8
                )

                // Subtle texture overlay
                Canvas { context, size in
                    for _ in 0..<50 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let path = Circle().path(in: CGRect(x: x, y: y, width: 1, height: 1))
                        context.fill(path, with: .color(Color.accentBronze.opacity(0.08)))
                    }
                }

                // Animated gold shimmer at edges
                LinearGradient(
                    colors: [
                        Color.accentBronze.opacity(0.20 + illuminationPhase * 0.35),
                        Color.clear,
                        Color.clear,
                        Color.accentBronze.opacity(0.20 + illuminationPhase * 0.35)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        VStack {
            Spacer()

            Text(flowState.toastMessage)
                .font(Typography.Command.caption.weight(.medium))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Color.surfaceRaised)
                        .overlay(
                            Capsule()
                                .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        )
                )
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.bottom, 100)  // Safe area offset for toast
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel(flowState.toastMessage)
    }

    // MARK: - Error Overlay

    private func errorOverlay(for error: PrayerGenerationError) -> some View {
        ZStack {
            Color.black.opacity(Theme.Opacity.strong)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticService.shared.warning()
                    withAnimation(Theme.Animation.settle) {
                        flowState.clearError()
                    }
                }

            VStack(spacing: Theme.Spacing.xl) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.Icon.xxl.weight(.regular))
                    .foregroundStyle(Color.accentBronze)

                Text(error.localizedDescription)
                    .font(Typography.Command.body)
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)

                Button(action: {
                    HapticService.shared.warning()
                    withAnimation(Theme.Animation.settle) {
                        flowState.clearError()
                    }
                }) {
                    Text("Try Again")
                        .font(Typography.Command.subheadline.weight(.semibold))
                        .foregroundColor(Color.surfaceParchment)
                        .padding(.horizontal, Theme.Spacing.xxl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(Color.accentBronze)
                        )
                }
                .accessibilityLabel("Try Again")
                .accessibilityHint("Double tap to dismiss error and try again")
            }
            .padding(Theme.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
                    )
            )
            .padding(.horizontal, Theme.Spacing.xxl)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    private func startIlluminationAnimation() {
        guard !reduceMotion else { return }
        withAnimation(Theme.Animation.slowFade) {
            illuminationPhase = 1
        }
    }

    private func createPrayer() {
        withAnimation(Theme.Animation.slowFade) {
            flowState.startCategoryGeneration(duration: 3.0)
        }
        HapticService.shared.success()
    }

    private func resetPrayer() {
        withAnimation(Theme.Animation.slowFade) {
            flowState.reset()
        }
    }

    private func copyPrayer(_ prayer: Prayer) {
        let text = "\(prayer.content)\n\n\(prayer.amen)"
        UIPasteboard.general.string = text
        HapticService.shared.softTap()
        flowState.showActionToast("Prayer copied")
    }

    private func savePrayer(_ prayer: Prayer) {
        guard !isSaving else { return }
        isSaving = true

        Task {
            do {
                try await prayerService.savePrayer(prayer)
                HapticService.shared.success()
                flowState.showActionToast("Prayer saved")
            } catch {
                HapticService.shared.warning()
                flowState.showActionToast("Could not save prayer")
            }
            isSaving = false
        }
    }

    private func sharePrayer(_ prayer: Prayer) {
        let categoryName = flowState.selectedCategory.rawValue.lowercased()
        let shareText = """
        \(prayer.content)

        \(prayer.amen)

        — A prayer for \(categoryName)
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        HapticService.shared.softTap()
        flowState.showActionToast("Sharing prayer")
    }
}

// MARK: - Preview

#Preview("Prayers From the Deep") {
    PrayersFromDeepView()
        .environment(AppState())
}
