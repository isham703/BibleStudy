import SwiftUI

// MARK: - Prayers From the Deep View
// AI-crafted prayers in the Sacred Manuscript medieval scriptorium style

struct PrayersFromDeepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0
    @State private var borderProgress: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Background
            manuscriptBackground

            VStack(spacing: 0) {
                // Header
                header
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.8), value: isVisible)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
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
                    PrayerToast(message: flowState.toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }

            // Illuminated border frame
            illuminatedBorder
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: isVisible)
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

    // MARK: - Background

    private var manuscriptBackground: some View {
        ZStack {
            // Base vellum gradient
            LinearGradient(
                colors: [
                    Color.prayerVellum,
                    Color.prayerVellum.opacity(0.95),
                    Color(hex: "E8DCC8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Parchment texture (noise overlay)
            Canvas { context, size in
                for _ in 0..<200 {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.prayerOxide.opacity(0.03))
                    )
                }
            }

            // Vignette edges
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.prayerUmber.opacity(0.15)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )

            // Candlelight glow from bottom
            RadialGradient(
                colors: [
                    Color.prayerCandlelight.opacity(0.3 + breathePhase * 0.1),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 400
            )
            .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * 0.05)
        }
        .ignoresSafeArea()
    }

    // MARK: - Illuminated Border

    private var illuminatedBorder: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 20
            let rect = CGRect(
                x: inset,
                y: inset + 50,
                width: geometry.size.width - inset * 2,
                height: geometry.size.height - inset * 2 - 50
            )

            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color.prayerGold.opacity(0.2),
                        lineWidth: 4
                    )
                    .blur(radius: 4)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                // Main border (animated stroke)
                RoundedRectangle(cornerRadius: 8)
                    .trim(from: 0, to: reduceMotion ? 1 : borderProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.prayerGold, .prayerOxide, .prayerGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                // Corner ornaments
                cornerOrnaments(in: rect)
            }
        }
    }

    private func cornerOrnaments(in rect: CGRect) -> some View {
        let ornamentSize: CGFloat = 12
        let offset: CGFloat = 6

        return ZStack {
            // Top-left
            Circle()
                .fill(Color.prayerGold)
                .frame(width: ornamentSize, height: ornamentSize)
                .position(x: rect.minX + offset, y: rect.minY + offset)

            // Top-right
            Circle()
                .fill(Color.prayerGold)
                .frame(width: ornamentSize, height: ornamentSize)
                .position(x: rect.maxX - offset, y: rect.minY + offset)

            // Bottom-left
            Circle()
                .fill(Color.prayerGold)
                .frame(width: ornamentSize, height: ornamentSize)
                .position(x: rect.minX + offset, y: rect.maxY - offset)

            // Bottom-right
            Circle()
                .fill(Color.prayerGold)
                .frame(width: ornamentSize, height: ornamentSize)
                .position(x: rect.maxX - offset, y: rect.maxY - offset)
        }
        .opacity(borderProgress)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.prayerOxide.opacity(0.6))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("PRAYERS FROM THE DEEP")
                    .font(.custom("Cinzel-Regular", size: 11))
                    .tracking(4)
                    .foregroundStyle(Color.prayerGold)
            }

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)

            // Icon
            ZStack {
                Circle()
                    .fill(Color.prayerGold.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * 0.1)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.prayerGold)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(1.0), value: isVisible)

            // Title
            VStack(spacing: 12) {
                Text("What's on your heart?")
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(Color.prayerUmber)

                Text("Describe your situation, and I'll craft a prayer in the tradition of the ancients.")
                    .font(.custom("CormorantGaramond-Italic", size: 16))
                    .foregroundStyle(Color.prayerOxide.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(1.2), value: isVisible)

            // Input field
            PrayerInputField(
                text: $flowState.inputText,
                placeholder: "e.g., \"I'm anxious about my son who has drifted away...\"",
                isFocused: $isInputFocused
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(duration: 0.6).delay(1.4), value: isVisible)

            // Tradition selector
            VStack(spacing: 12) {
                Text("PRAYER TRADITION")
                    .font(.custom("Cinzel-Regular", size: 10))
                    .tracking(2)
                    .foregroundStyle(Color.prayerOxide.opacity(0.6))

                PrayerTraditionSelector(
                    selectedTradition: $flowState.selectedTradition
                )
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(1.8), value: isVisible)

            Spacer()

            // Generate button
            Button(action: generatePrayer) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Text("Craft Prayer")
                }
                .font(.custom("Cinzel-Regular", size: 16))
                .foregroundStyle(Color.prayerCandlelight)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(Color.prayerVermillion)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.prayerGold.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.prayerVermillion.opacity(0.3), radius: 12, y: 4)
            }
            .disabled(!flowState.canGenerate)
            .opacity(flowState.canGenerate ? 1 : 0.5)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        VStack(spacing: 32) {
            Spacer()

            // Quill animation
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.prayerGold.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                        .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * CGFloat(0.1 + Double(i) * 0.05))
                }

                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.prayerGold)
                    .rotationEffect(.degrees(reduceMotion ? 0 : breathePhase * 5))
            }

            VStack(spacing: 12) {
                Text("The ink flows...")
                    .font(.custom("CormorantGaramond-Italic", size: 22))
                    .foregroundStyle(Color.prayerUmber)

                Text("Crafting in the tradition of \(flowState.selectedTradition.rawValue)")
                    .font(.custom("CormorantGaramond-Italic", size: 14))
                    .foregroundStyle(Color.prayerOxide.opacity(0.6))
            }

            Spacer()
        }
    }

    // MARK: - Displaying Phase

    private var displayingPhase: some View {
        VStack(spacing: 24) {
            if let prayer = flowState.generatedPrayer {
                PrayerDisplayView(prayer: prayer)
                    .transition(.opacity.combined(with: .offset(y: 20)))
            }

            Spacer().frame(height: 20)

            PrayerActionToolbar(
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
            borderProgress = 1
            return
        }

        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = true
        }

        // Border animation
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            borderProgress = 1
        }

        // Breathing animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathePhase = 1
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
    PrayersFromDeepView()
}
