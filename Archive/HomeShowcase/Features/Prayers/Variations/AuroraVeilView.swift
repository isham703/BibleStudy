import SwiftUI

// MARK: - Aurora Veil View
// Luminous glass with animated aurora background

struct AuroraVeilView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var auroraPhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var floatOffset: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    private let variant = PrayersShowcaseVariant.auroraVeil

    var body: some View {
        ZStack {
            // Aurora background
            auroraBackground

            VStack(spacing: 0) {
                // Header
                header
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(1.4), value: isVisible)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch flowState.phase {
                        case .input:
                            inputPhase
                        case .generating:
                            generatingPhase
                        case .displaying:
                            displayingPhase
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }

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
        .onAppear {
            startEntranceAnimation()
        }
        .onDisappear {
            flowState.cancelReveal()
        }
    }

    // MARK: - Aurora Background

    private var auroraBackground: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Base void
                Color.auroraVoid

                // Aurora bands
                if !reduceMotion {
                    auroraBands(time: time)
                } else {
                    staticAurora
                }

                // Star field
                starField
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.8), value: isVisible)

                // Atmospheric glow
                RadialGradient(
                    colors: [
                        Color.auroraViolet.opacity(0.15),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 50,
                    endRadius: 400
                )
                .scaleEffect(reduceMotion ? 1.0 : 1 + auroraPhase * 0.1)
            }
        }
        .ignoresSafeArea()
    }

    private func auroraBands(time: TimeInterval) -> some View {
        ZStack {
            // Band 1 - Violet (8s cycle)
            EllipticalGradient(
                colors: [
                    Color.auroraViolet.opacity(0.4),
                    Color.auroraViolet.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.8
            )
            .frame(width: 600, height: 200)
            .rotationEffect(.degrees(sin(time / 8 * .pi * 2) * 10))
            .offset(
                x: sin(time / 8 * .pi * 2) * 50,
                y: -100 + sin(time / 6 * .pi * 2) * 30
            )
            .blur(radius: 60)

            // Band 2 - Teal (12s cycle)
            EllipticalGradient(
                colors: [
                    Color.auroraTeal.opacity(0.3),
                    Color.auroraTeal.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.7
            )
            .frame(width: 500, height: 180)
            .rotationEffect(.degrees(sin(time / 12 * .pi * 2) * 15))
            .offset(
                x: sin(time / 12 * .pi * 2 + 1) * 60,
                y: -50 + sin(time / 10 * .pi * 2) * 40
            )
            .blur(radius: 50)

            // Band 3 - Rose (16s cycle)
            EllipticalGradient(
                colors: [
                    Color.auroraRose.opacity(0.25),
                    Color.auroraRose.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            .frame(width: 400, height: 150)
            .rotationEffect(.degrees(sin(time / 16 * .pi * 2) * 20))
            .offset(
                x: sin(time / 16 * .pi * 2 + 2) * 40,
                y: sin(time / 14 * .pi * 2) * 50
            )
            .blur(radius: 40)
        }
    }

    private var staticAurora: some View {
        LinearGradient(
            colors: [
                Color.auroraViolet.opacity(0.3),
                Color.auroraTeal.opacity(0.2),
                Color.auroraRose.opacity(0.15),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var starField: some View {
        Canvas { context, size in
            for i in 0..<50 {
                let seed = Double(i * 137)
                let x = CGFloat(seed.truncatingRemainder(dividingBy: size.width))
                let y = CGFloat((seed * 1.7).truncatingRemainder(dividingBy: size.height))
                let starSize = CGFloat.random(in: 1...2)
                let opacity = CGFloat.random(in: 0.3...0.8)

                let rect = CGRect(
                    x: x,
                    y: y,
                    width: starSize,
                    height: starSize
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.6))
            }

            Spacer()

            Text("PRAYERS FROM THE DEEP")
                .font(.system(size: 13, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.auroraViolet)

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: - Glass Card

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.auroraViolet.opacity(0.15),
                                    Color.auroraTeal.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    AngularGradient(
                        colors: [.auroraViolet, .auroraTeal, .auroraRose, .auroraViolet],
                        center: .center,
                        angle: .degrees(rotationAngle)
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.auroraViolet.opacity(0.3), radius: 30, y: 10)
        .offset(y: reduceMotion ? 0 : floatOffset)
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.auroraViolet.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(reduceMotion ? 1.0 : 1 + auroraPhase * 0.1)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.auroraViolet, .auroraTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(duration: 0.6).delay(1.0), value: isVisible)

            // Title
            VStack(spacing: 12) {
                Text("What's on your heart?")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)

                Text("Share your thoughts, and I'll weave a prayer from the aurora.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: isVisible)

            // Glass card with input
            glassCard {
                VStack(spacing: 20) {
                    PrayerInputField(
                        text: $flowState.inputText,
                        variant: variant,
                        placeholder: "e.g., \"I'm anxious about my son who has drifted away...\"",
                        isFocused: $isInputFocused
                    )

                    PrayerTraditionSelector(
                        selectedTradition: $flowState.selectedTradition,
                        variant: variant
                    )
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 60)
            .animation(.spring(duration: 0.6).delay(1.0), value: isVisible)

            Spacer()

            // Generate button
            Button(action: generatePrayer) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Text("Weave Prayer")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.auroraViolet, .auroraTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.auroraViolet.opacity(0.5), radius: 20, y: 8)
            }
            .disabled(!flowState.canGenerate)
            .opacity(flowState.canGenerate ? 1 : 0.5)
            .scaleEffect(flowState.canGenerate ? 1 : 0.95)
            .animation(.spring(duration: 0.3), value: flowState.canGenerate)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // Pulsing rings
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.auroraViolet, .auroraTeal, .auroraRose, .auroraViolet],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(60 + i * 40), height: CGFloat(60 + i * 40))
                        .scaleEffect(reduceMotion ? 1.0 : 1 + auroraPhase * CGFloat(0.1 + Double(i) * 0.05))
                        .opacity(0.8 - Double(i) * 0.2)
                        .rotationEffect(.degrees(rotationAngle * (i % 2 == 0 ? 1 : -1)))
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.auroraViolet, .auroraTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Weaving your prayer...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)

                Text(flowState.selectedTradition.rawValue)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.6))
            }

            Spacer()
        }
    }

    // MARK: - Displaying Phase

    private var displayingPhase: some View {
        VStack(spacing: 24) {
            if let prayer = flowState.generatedPrayer {
                glassCard {
                    PrayerDisplayView(
                        prayer: prayer,
                        variant: variant,
                        revealedWordCount: prayer.words.count,
                        isRevealComplete: true
                    )
                }
                .transition(.opacity.combined(with: .offset(y: 30)))
            }

            Spacer().frame(height: 20)

            PrayerActionToolbar(
                variant: variant,
                onSave: { flowState.showActionToast("Saved") },
                onShare: { flowState.showActionToast("Shared") },
                onNew: { resetFlow() }
            )
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func startEntranceAnimation() {
        guard !reduceMotion else {
            isVisible = true
            return
        }

        withAnimation(.easeOut(duration: 0.8)) {
            isVisible = true
        }

        // Aurora pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            auroraPhase = 1
        }

        // Border rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Card float
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }
    }

    private func generatePrayer() {
        isInputFocused = false
        withAnimation(.spring(duration: 0.4)) {
            flowState.startGeneration(duration: 3.0)
        }
    }

    private func resetFlow() {
        withAnimation(.spring(duration: 0.4)) {
            flowState.reset()
        }
    }
}

// MARK: - Preview

#Preview {
    AuroraVeilView()
}
