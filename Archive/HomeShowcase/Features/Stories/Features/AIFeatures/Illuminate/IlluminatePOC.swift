import SwiftUI

// MARK: - Illuminate POC
// AI-generated sacred art for any verse
// Aesthetic: Manuscript-inspired, generative, gold and ink

struct IlluminatePOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var isGenerating = false
    @State private var showingResult = false
    @State private var selectedStyle = 0
    @State private var generationProgress: CGFloat = 0
    @State private var glowPhase: CGFloat = 0

    private let verse = "Be still, and know that I am God."
    private let reference = "Psalm 46:10"

    private let styles: [IlluminationStyle] = [
        IlluminationStyle(name: "Celtic Manuscript", icon: "scroll.fill", colors: [Color(hex: "d4a853"), Color(hex: "2c2520")]),
        IlluminationStyle(name: "Byzantine Icon", icon: "sparkles", colors: [Color(hex: "c9a227"), Color(hex: "1a1a2e")]),
        IlluminationStyle(name: "Modern Sacred", icon: "square.on.square", colors: [Color(hex: "6366f1"), Color(hex: "0f172a")])
    ]

    var body: some View {
        ZStack {
            // Parchment-inspired background
            parchmentBackground

            VStack(spacing: 0) {
                // Header
                header

                if showingResult {
                    generatedArtView
                } else if isGenerating {
                    generatingView
                } else {
                    configurationView
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
    }

    // MARK: - Background

    private var parchmentBackground: some View {
        ZStack {
            Color(hex: "0f0d0a")

            // Warm ambient
            RadialGradient(
                colors: [
                    Color(hex: "d4a853").opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("ILLUMINATE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "d4a853"))
            }

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Verse preview
            VStack(spacing: 16) {
                Text("\u{201C}\(verse)\u{201D}")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .italic()

                Text(reference)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "d4a853"))
            }
            .padding(.horizontal, 32)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

            // Style selector
            VStack(spacing: 16) {
                Text("Choose Illumination Style")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)
                    .textCase(.uppercase)

                HStack(spacing: 16) {
                    ForEach(Array(styles.enumerated()), id: \.offset) { index, style in
                        styleCard(style: style, index: index)
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            Spacer()

            // Generate button
            Button(action: startGeneration) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18))
                    Text("Create Illumination")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "0f0d0a"))
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "e8c978"), Color(hex: "d4a853")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color(hex: "d4a853").opacity(0.4), radius: 20)
            }
            .padding(.bottom, 60)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: isVisible)
        }
    }

    private func styleCard(style: IlluminationStyle, index: Int) -> some View {
        Button(action: { selectedStyle = index }) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: style.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: style.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedStyle == index ? Color(hex: "d4a853") : .clear, lineWidth: 2)
                )

                Text(style.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated generation visualization
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(Color(hex: "d4a853").opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(1 + glowPhase * 0.1)

                // Progress ring
                Circle()
                    .trim(from: 0, to: generationProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "e8c978"), Color(hex: "d4a853")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 8) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "d4a853"))
                        .rotationEffect(.degrees(glowPhase * 10))

                    Text("\(Int(generationProgress * 100))%")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack(spacing: 12) {
                Text("Illuminating...")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                Text("The AI is crafting gold leaf details")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }

    // MARK: - Generated Art View

    private var generatedArtView: some View {
        VStack(spacing: 24) {
            Spacer()

            // The "generated" illuminated manuscript
            ZStack {
                // Parchment base
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "f5f0e6"))
                    .frame(width: 320, height: 400)

                // Celtic border pattern
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "d4a853"), Color(hex: "c9943d"), Color(hex: "d4a853")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .frame(width: 300, height: 380)

                // Inner border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: "d4a853").opacity(0.5), lineWidth: 1)
                    .frame(width: 280, height: 360)

                VStack(spacing: 20) {
                    // Drop cap
                    ZStack {
                        Text("B")
                            .font(.custom("Cinzel-Regular", size: 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "d4a853"), Color(hex: "b8942e")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hex: "d4a853").opacity(0.5), radius: 4)

                        // Decorative swirl
                        Circle()
                            .stroke(Color(hex: "d4a853").opacity(0.3), lineWidth: 1)
                            .frame(width: 90, height: 90)
                    }

                    // Verse text
                    Text("e still, and know")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color(hex: "2c2520"))

                    Text("that I am God")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color(hex: "2c2520"))

                    // Decorative divider
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color(hex: "d4a853"))
                            .frame(width: 40, height: 1)
                        Diamond()
                            .fill(Color(hex: "d4a853"))
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color(hex: "d4a853"))
                            .frame(width: 40, height: 1)
                    }

                    // Reference
                    Text("Psalm 46:10")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "d4a853"))
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .scaleEffect(showingResult ? 1 : 0.8)
            .opacity(showingResult ? 1 : 0)
            .animation(.spring(duration: 0.8, bounce: 0.2), value: showingResult)

            // Actions
            HStack(spacing: 32) {
                actionButton(icon: "square.and.arrow.down", label: "Save")
                actionButton(icon: "square.and.arrow.up", label: "Share")
                actionButton(icon: "arrow.counterclockwise", label: "Regenerate")
            }
            .padding(.top, 16)

            Spacer()

            // New verse button
            Button(action: reset) {
                Text("Illuminate another verse")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "d4a853"))
            }
            .padding(.bottom, 40)
        }
    }

    private func actionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Actions

    private func startGeneration() {
        isGenerating = true
        generationProgress = 0

        // Animate progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            generationProgress += 0.02
            if generationProgress >= 1.0 {
                timer.invalidate()
                withAnimation(.spring(duration: 0.5)) {
                    isGenerating = false
                    showingResult = true
                }
            }
        }
    }

    private func reset() {
        withAnimation(.easeOut(duration: 0.3)) {
            showingResult = false
            generationProgress = 0
        }
    }
}

// MARK: - Illumination Style Model

struct IlluminationStyle {
    let name: String
    let icon: String
    let colors: [Color]
}

// MARK: - Diamond Shape

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    IlluminatePOC()
}
