import SwiftUI
import UIKit

// MARK: - The Portico
// Classical order design - clean architectural clarity
// AI-crafted prayers using intention-based categories

struct PrayersFromDeepView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var flowState = PrayerFlowState()
    @State private var illuminationPhase: CGFloat = 0
    @State private var isSaving = false
    @State private var showRecentPrayers = false
    @FocusState private var isTextFieldFocused: Bool

    private let prayerService = PrayerService.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch flowState.phase {
                    case .input:
                        PrayerInputPhase(
                            flowState: flowState,
                            isTextFieldFocused: $isTextFieldFocused,
                            illuminationPhase: illuminationPhase,
                            onCreatePrayer: createPrayer,
                            onViewRecentPrayers: { showRecentPrayers = true }
                        )
                        .ignoresSafeArea(edges: .top)
                    case .generating:
                        PrayerGeneratingPhase(
                            selectedCategory: flowState.selectedCategory,
                            intentionText: flowState.inputText,
                            reduceMotion: reduceMotion,
                            onCancel: cancelGeneration
                        )
                    case .displaying:
                        if let prayer = flowState.generatedPrayer {
                            PrayerDisplayPhase(
                                prayer: prayer,
                                selectedCategory: flowState.selectedCategory,
                                onCopy: { copyPrayer(prayer) },
                                onShare: { sharePrayer(prayer) },
                                onSave: { savePrayer(prayer) },
                                onNewPrayer: resetPrayer,
                                onRegenerate: regeneratePrayer,
                                onEditIntention: editIntention
                            )
                        }
                    }
                }
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
            .scrollClipDisabled()
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)

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
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .sheet(isPresented: $flowState.showCrisisModal) {
            CrisisHelpModal(onDismiss: { flowState.dismissCrisisModal() })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRecentPrayers) {
            RecentPrayersSheet(prayerService: prayerService)
                .presentationDetents([.medium, .large])
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
        // Dark mode: warm charcoal for candlelit feel (matches HeroHeader curve)
        // Light mode: standard app background
        Group {
            if colorScheme == .dark {
                Color.warmCharcoal.ignoresSafeArea()
            } else {
                Color.appBackground.ignoresSafeArea()
            }
        }
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        VStack {
            Spacer()

            Text(flowState.toastMessage)
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                )
                .padding(.bottom, Theme.Spacing.xxl * 2)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel(flowState.toastMessage)
    }

    // MARK: - Error Overlay

    private func errorOverlay(for error: PrayerGenerationError) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss by tapping background
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.settle) {
                        flowState.clearError()
                    }
                }

            VStack(spacing: Theme.Spacing.md) {
                // Error icon
                Image(systemName: errorIcon(for: error))
                    .font(Typography.Icon.xxl.weight(.regular))
                    .foregroundStyle(Color("FeedbackWarning"))

                // Error title
                Text("Unable to Generate Prayer")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)

                // Error detail - raised contrast for readability
                Text(errorMessage(for: error))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.appTextPrimary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.sm)

                // Reassurance (user's input preserved)
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("FeedbackSuccess"))
                    Text("Your intention is saved")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                // Primary action - Try Again
                Button(action: {
                    HapticService.shared.mediumTap()
                    withAnimation(Theme.Animation.settle) {
                        flowState.clearError()
                        // Retry generation
                        flowState.startCategoryGeneration(duration: 3.0)
                    }
                }) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(Typography.Icon.sm)
                        Text("Try Again")
                            .font(Typography.Command.cta)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color("AppAccentAction"))
                    )
                }
                .padding(.top, Theme.Spacing.xs)

                // Secondary action - Edit request (styled as interactive link)
                Button(action: {
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.settle) {
                        flowState.clearError()
                        flowState.phase = .input
                    }
                }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Edit Request")
                            .font(Typography.Command.label.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.xs)
                    }
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .padding(Theme.Spacing.xl)
            .padding(.horizontal, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            // Removed accent stroke - clean modal edge
            .padding(.horizontal, Theme.Spacing.lg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(errorMessage(for: error)). Your intention is saved.")
            .accessibilityHint("Try again to regenerate, or edit your request")
        }
    }

    // MARK: - Error Helpers

    private func errorIcon(for error: PrayerGenerationError) -> String {
        switch error {
        case .networkError:
            return "wifi.slash"
        case .rateLimited:
            return "clock.badge.exclamationmark"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    private func errorMessage(for error: PrayerGenerationError) -> String {
        switch error {
        case .networkError:
            return "Unable to connect. Please check your internet and try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .generationFailed:
            return "Something went wrong. Please try again."
        default:
            return error.localizedDescription
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

    private func cancelGeneration() {
        HapticService.shared.warning()
        withAnimation(Theme.Animation.settle) {
            flowState.cancelAllTasks()
            flowState.phase = .input
        }
    }

    private func resetPrayer() {
        withAnimation(Theme.Animation.slowFade) {
            flowState.reset()
        }
    }

    private func regeneratePrayer() {
        HapticService.shared.mediumTap()
        withAnimation(Theme.Animation.slowFade) {
            flowState.phase = .generating
            flowState.startCategoryGeneration(duration: 3.0)
        }
    }

    private func editIntention() {
        HapticService.shared.lightTap()
        withAnimation(Theme.Animation.slowFade) {
            flowState.phase = .input
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
