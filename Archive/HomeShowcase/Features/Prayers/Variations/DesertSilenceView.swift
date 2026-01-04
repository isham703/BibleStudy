import SwiftUI

// MARK: - Desert Silence View
// Contemplative minimal with word-by-word prayer reveal

struct DesertSilenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0
    @State private var ruleProgress: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    private let variant = PrayersShowcaseVariant.desertSilence

    var body: some View {
        ZStack {
            // Background
            silenceBackground

            VStack(spacing: 0) {
                // Header
                header
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.8), value: isVisible)

                // Content
                contentView

                // Toast
                if flowState.showToast {
                    PrayerToast(message: flowState.toastMessage, variant: variant)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap anywhere to skip word-by-word reveal
            if flowState.phase == .displaying && !flowState.isRevealComplete {
                flowState.skipToFullReveal()
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
        .onDisappear {
            flowState.cancelReveal()
        }
    }

    // MARK: - Background

    private var silenceBackground: some View {
        ZStack {
            // Base dawn mist
            Color.desertDawnMist

            // Subtle gradient (cooler top, warmer bottom)
            LinearGradient(
                colors: [
                    Color(hex: "F5F3F0"),
                    Color.desertDawnMist,
                    Color.desertDawnBlush.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Dawn blush in corners
            RadialGradient(
                colors: [
                    Color.desertDawnBlush.opacity(0.05),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )

            RadialGradient(
                colors: [
                    Color.desertDawnBlush.opacity(0.05),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.desertAsh)
            }

            Spacer()

            // Minimal header - just a thin line
            Rectangle()
                .fill(Color.desertAsh.opacity(0.3))
                .frame(width: 40, height: 1)

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 48)
        .padding(.top, 80)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch flowState.phase {
        case .input:
            inputPhase
        case .generating:
            generatingPhase
        case .displaying:
            displayingPhase
        }
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                // Minimal prompt
                Text("What's on your heart?")
                    .font(.system(size: 19, weight: .ultraLight))
                    .tracking(0.5)
                    .foregroundStyle(Color.desertSumiInk)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.8), value: isVisible)

                // Input field
                PrayerInputField(
                    text: $flowState.inputText,
                    variant: variant,
                    placeholder: "",
                    isFocused: $isInputFocused
                )
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(1.2), value: isVisible)

                // Horizontal rule
                Rectangle()
                    .fill(Color.desertAsh)
                    .frame(height: 1)
                    .scaleEffect(x: ruleProgress, anchor: .center)
                    .frame(maxWidth: 320)

                // Tradition selector
                PrayerTraditionSelector(
                    selectedTradition: $flowState.selectedTradition,
                    variant: variant
                )
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(1.5), value: isVisible)
            }
            .frame(maxWidth: 320)

            Spacer()

            // Generate button (minimal)
            Button(action: generatePrayer) {
                Text("begin")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(
                        flowState.canGenerate
                        ? Color.desertSumiInk
                        : Color.desertAsh
                    )
            }
            .disabled(!flowState.canGenerate)
            .padding(.bottom, 64)
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Generating Phase (The Stillness)

    private var generatingPhase: some View {
        VStack {
            Spacer()

            // Single breathing circle
            Circle()
                .fill(Color.desertAsh.opacity(0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(reduceMotion ? 1.0 : 0.9 + breathePhase * 0.2)

            Spacer()
        }
    }

    // MARK: - Displaying Phase (Word-by-word reveal)

    private var displayingPhase: some View {
        VStack(spacing: 0) {
            Spacer()

            if let prayer = flowState.generatedPrayer {
                // Prayer with word-by-word reveal
                PrayerDisplayView(
                    prayer: prayer,
                    variant: variant,
                    revealedWordCount: flowState.revealedWordCount,
                    isRevealComplete: flowState.isRevealComplete
                )
                .frame(maxWidth: 320)

                // Skip hint (fades after a few seconds)
                if !flowState.isRevealComplete {
                    Text("tap to reveal")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color.desertAsh.opacity(0.4))
                        .padding(.top, 40)
                }
            }

            Spacer()

            // Action icons (only after reveal complete)
            if flowState.isRevealComplete {
                PrayerActionToolbar(
                    variant: variant,
                    onSave: { flowState.showActionToast("Saved") },
                    onShare: { flowState.showActionToast("Shared") },
                    onNew: { resetFlow() }
                )
                .transition(.opacity)
                .padding(.bottom, 64)
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Actions

    private func startEntranceAnimation() {
        guard !reduceMotion else {
            isVisible = true
            ruleProgress = 1
            return
        }

        withAnimation(.easeOut(duration: 0.6)) {
            isVisible = true
        }

        // Rule draws from center
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            ruleProgress = 1
        }

        // Breathing animation (slower for stillness)
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathePhase = 1
        }
    }

    private func generatePrayer() {
        isInputFocused = false

        withAnimation(.easeOut(duration: 0.4)) {
            flowState.startGeneration(duration: 4.0) // Longer pause for stillness
        }

        // Start word reveal after generation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if reduceMotion {
                // Skip word-by-word, show full text
                flowState.skipToFullReveal()
            } else {
                flowState.startWordReveal()
            }
        }
    }

    private func resetFlow() {
        withAnimation(.easeOut(duration: 0.4)) {
            flowState.reset()
        }
    }
}

// MARK: - Preview

#Preview {
    DesertSilenceView()
}
