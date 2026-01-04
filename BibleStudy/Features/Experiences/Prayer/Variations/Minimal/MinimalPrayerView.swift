import SwiftUI

// MARK: - Minimal Prayer View
// Clean, card-based interface with subtle animations and generous whitespace
// Visual Density: Light | Animation: Subtle | Interaction: Cards

struct MinimalPrayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Static background (minimal animation)
            DeepPrayerBackground(
                breathePhase: reduceMotion ? 0 : breathePhase,
                glowIntensity: 0.6  // Subtler glow for minimal style
            )

            VStack(spacing: 0) {
                // Header
                header

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
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
            startSubtleBreathing()
        }
        .onDisappear {
            flowState.reset()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
            }

            Spacer()

            Text("MINIMAL")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(DeepPrayerColors.roseAccent)

            Spacer()

            // Balance the layout
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Icon (subtle scale)
                ZStack {
                    Circle()
                        .fill(DeepPrayerColors.roseAccent.opacity(0.08))
                        .frame(width: 80, height: 80)
                        .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * 0.03)

                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DeepPrayerColors.roseAccent.opacity(0.8))
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: isVisible)

                // Input card
                MinimalInputCard(
                    text: $flowState.inputText,
                    placeholder: "What's on your heart?"
                )
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.15), value: isVisible)

                // Tradition picker
                MinimalTraditionPicker(selectedTradition: $flowState.selectedTradition)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.2), value: isVisible)

                Spacer(minLength: 60)

                // Generate button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        flowState.startGeneration(duration: 2.0)  // Shorter for minimal
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Craft Prayer")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(DeepPrayerColors.roseAccent)
                    )
                }
                .disabled(!flowState.canGenerate)
                .opacity(flowState.canGenerate ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.25), value: isVisible)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            // Simple pulsing indicator
            ZStack {
                Circle()
                    .stroke(DeepPrayerColors.roseAccent.opacity(0.2), lineWidth: 1)
                    .frame(width: 100, height: 100)
                    .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * 0.1)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DeepPrayerColors.roseAccent)
                    .opacity(reduceMotion ? 1.0 : 0.7 + breathePhase * 0.3)
            }

            Text("Crafting...")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(DeepPrayerColors.secondaryText)

            Spacer()
        }
    }

    // MARK: - Display Phase

    @ViewBuilder
    private var displayPhase: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                if let prayer = flowState.generatedPrayer {
                    MinimalPrayerDisplay(
                        prayer: prayer,
                        tradition: flowState.selectedTradition
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 120)
                } else {
                    // Fallback - should not happen in normal flow
                    MinimalPrayerDisplay(
                        prayer: MockPrayer.psalmicLament,
                        tradition: flowState.selectedTradition
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 120)
                }
            }

            // Action bar
            minimalActionBar
        }
    }

    // MARK: - Action Bar

    private var minimalActionBar: some View {
        HStack(spacing: 32) {
            actionButton(icon: "bookmark", label: "Save") {
                flowState.showActionToast("Saved")
            }
            actionButton(icon: "square.and.arrow.up", label: "Share") {
                flowState.showActionToast("Shared")
            }
            actionButton(icon: "arrow.counterclockwise", label: "New") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    flowState.reset()
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            DeepPrayerColors.sacredNavy.opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DeepPrayerColors.surfaceBorder)
                .frame(height: 0.5)
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(DeepPrayerColors.secondaryText)
        }
    }

    // MARK: - Animations

    private func startSubtleBreathing() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 8)  // Very slow for minimal
            .repeatForever(autoreverses: true)
        ) {
            breathePhase = 1
        }
    }
}

// MARK: - Preview

#Preview("Minimal Prayer") {
    MinimalPrayerView()
}
