import SwiftUI

// MARK: - Stained Glass View
// Cathedral light experience with jewel tones and divine radiance

struct StainedGlassView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = ShowcaseFlowState()
    @FocusState private var isInputFocused: Bool
    @State private var lightRayPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Cathedral background
            cathedralBackground

            // Content
            VStack(spacing: 0) {
                // Header
                headerBar

                Spacer()

                // Glass panel content
                glassPanel

                Spacer()

                // Interaction area
                if let prompt = flowState.currentScene.prompt {
                    interactionArea(prompt: prompt)
                } else {
                    finalScene
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            flowState.onAppear()
            startLightAnimation()
        }
        .onDisappear {
            flowState.onDisappear()
        }
    }

    private func startLightAnimation() {
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            lightRayPhase = 1
        }
    }

    // MARK: - Cathedral Background

    private var cathedralBackground: some View {
        ZStack {
            // Deep void base
            Color.glassVoid

            // Divine light rays
            GeometryReader { geo in
                ZStack {
                    // Primary light cone
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width * 0.5, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width * 0.2, y: geo.size.height))
                        path.addLine(to: CGPoint(x: geo.size.width * 0.8, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                flowState.currentScene.mood.glassColor.opacity(0.15 + lightRayPhase * 0.1),
                                flowState.currentScene.mood.glassColor.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Secondary light beams
                    ForEach(0..<3, id: \.self) { index in
                        Path { path in
                            let startX = geo.size.width * (0.3 + Double(index) * 0.2)
                            path.move(to: CGPoint(x: startX, y: 0))
                            path.addLine(to: CGPoint(x: startX - 30, y: geo.size.height * 0.7))
                            path.addLine(to: CGPoint(x: startX + 30, y: geo.size.height * 0.7))
                            path.closeSubpath()
                        }
                        .fill(flowState.currentScene.mood.glassColor.opacity(0.08 + lightRayPhase * 0.05))
                    }
                }
            }

            // Radial glow from center
            RadialGradient(
                colors: [
                    flowState.currentScene.mood.glassColor.opacity(0.2 + flowState.breathePhase * 0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )

            // Dust particles / divine sparkle
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.3 + Double.random(in: 0...0.3)))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .blur(radius: 0.5)
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
            }
            Spacer()

            // Scene indicator - glass gems
            HStack(spacing: 10) {
                ForEach(0..<flowState.sceneCount, id: \.self) { index in
                    glassGem(isActive: index == flowState.currentSceneIndex, index: index)
                }
            }

            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding(.top, 60)
    }

    private func glassGem(isActive: Bool, index: Int) -> some View {
        let colors: [Color] = [.glassAmethyst, .glassRuby, .glassEmerald, .glassSapphire, .glassGold]
        let color = colors[index % colors.count]

        return ZStack {
            // Glow
            if isActive {
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4)
            }

            // Gem
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.9), color],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: isActive ? 12 : 8, height: isActive ? 12 : 8)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isActive ? 0.5 : 0.2), lineWidth: 0.5)
                )
        }
        .animation(.spring(duration: 0.3), value: flowState.currentSceneIndex)
    }

    // MARK: - Glass Panel

    private var glassPanel: some View {
        VStack(spacing: 24) {
            // Main narration
            Text(flowState.currentScene.narration)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: flowState.currentScene.mood.glassColor.opacity(0.5), radius: 10)
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.8), value: flowState.currentSceneIndex)

            // Glass divider
            HStack(spacing: 8) {
                glassDividerLine
                glassOrnament
                glassDividerLine
            }
            .frame(width: 200)
            .opacity(flowState.textOpacity)

            // Description
            Text(flowState.currentScene.description)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.3), value: flowState.currentSceneIndex)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    flowState.currentScene.mood.glassColor.opacity(0.6),
                                    flowState.currentScene.mood.glassColor.opacity(0.2),
                                    flowState.currentScene.mood.glassColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: flowState.currentScene.mood.glassColor.opacity(0.3), radius: 20, y: 10)
    }

    private var glassDividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, flowState.currentScene.mood.glassColor.opacity(0.5), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var glassOrnament: some View {
        ZStack {
            // Inner diamond
            Rectangle()
                .fill(flowState.currentScene.mood.glassColor)
                .frame(width: 8, height: 8)
                .rotationEffect(.degrees(45))

            // Outer glow
            Rectangle()
                .fill(flowState.currentScene.mood.glassColor.opacity(0.3))
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(45))
                .blur(radius: 2)
        }
    }

    // MARK: - Interaction Area

    private func interactionArea(prompt: String) -> some View {
        VStack(spacing: 16) {
            // Prompt
            Text(prompt)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(flowState.currentScene.mood.glassColor)
                .italic()
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: flowState.currentSceneIndex)

            // Input
            HStack(spacing: 12) {
                TextField("", text: $flowState.userResponse, prompt: Text("Offer your prayer...").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(flowState.currentScene.mood.glassColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .focused($isInputFocused)

                Button(action: {
                    HomeShowcaseHaptics.cardPress()
                    flowState.advanceScene()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [flowState.currentScene.mood.glassColor, flowState.currentScene.mood.glassColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: flowState.currentScene.mood.glassColor.opacity(0.5), radius: 8)
                }
            }
            .opacity(flowState.textOpacity)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: flowState.currentSceneIndex)
        }
    }

    // MARK: - Final Scene

    private var finalScene: some View {
        VStack(spacing: 20) {
            // Divine symbol
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.glassGold.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(1 + flowState.breathePhase * 0.1)

                // Cross pattern
                ZStack {
                    Rectangle()
                        .fill(Color.glassGold)
                        .frame(width: 4, height: 50)
                    Rectangle()
                        .fill(Color.glassGold)
                        .frame(width: 50, height: 4)
                }
                .shadow(color: Color.glassGold.opacity(0.8), radius: 10)

                // Center gem
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color.glassGold],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 16, height: 16)
            }

            Text("You are home.")
                .font(.system(size: 26, weight: .light, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: Color.glassGold.opacity(0.5), radius: 8)

            Text("The father's love never left you.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.white.opacity(0.7))

            Button(action: { dismiss() }) {
                Text("Leave the Cathedral")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.glassGold, Color.glassGold.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.glassGold.opacity(0.4), radius: 8)
            }
            .padding(.top, 16)
        }
        .opacity(flowState.textOpacity)
    }
}

// MARK: - Preview

#Preview {
    StainedGlassView()
}
