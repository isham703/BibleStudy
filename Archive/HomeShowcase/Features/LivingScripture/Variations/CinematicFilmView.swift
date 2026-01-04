import SwiftUI

// MARK: - Cinematic Film View
// Film noir narrative experience with dreamlike, intimate atmosphere

struct CinematicFilmView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = ShowcaseFlowState()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Atmospheric background
            atmosphericBackground

            // Content
            VStack(spacing: 0) {
                // Close button and scene indicator
                headerBar

                Spacer()

                // Main narrative content
                narrativeContent

                Spacer()

                // User interaction area
                if let prompt = flowState.currentScene.prompt {
                    interactionArea(prompt: prompt)
                } else {
                    finalScene
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            flowState.onAppear()
        }
        .onDisappear {
            flowState.onDisappear()
        }
    }

    // MARK: - Atmospheric Background

    private var atmosphericBackground: some View {
        ZStack {
            // Base - deep warm black
            Color.cinematicVoid

            // Mood-based gradient
            LinearGradient(
                colors: flowState.currentScene.mood.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.6)

            // Vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.7)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )

            // Breathing light effect
            RadialGradient(
                colors: [
                    flowState.currentScene.mood.color.opacity(0.15 + flowState.breathePhase * 0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )

            // Film grain overlay
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            Spacer()

            // Scene indicator
            HStack(spacing: 8) {
                ForEach(0..<flowState.sceneCount, id: \.self) { index in
                    Circle()
                        .fill(index == flowState.currentSceneIndex ? flowState.currentScene.mood.color : .white.opacity(0.2))
                        .frame(
                            width: index == flowState.currentSceneIndex ? 8 : 6,
                            height: index == flowState.currentSceneIndex ? 8 : 6
                        )
                        .animation(.spring(duration: 0.3), value: flowState.currentSceneIndex)
                }
            }

            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding(.top, 60)
    }

    // MARK: - Narrative Content

    private var narrativeContent: some View {
        VStack(spacing: 32) {
            // Main narration - large, centered
            Text(flowState.currentScene.narration)
                .font(.system(size: 32, weight: .light, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.8), value: flowState.currentSceneIndex)

            // Description - smaller, atmospheric
            Text(flowState.currentScene.description)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.3), value: flowState.currentSceneIndex)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Interaction Area

    private func interactionArea(prompt: String) -> some View {
        VStack(spacing: 20) {
            // AI prompt
            Text(prompt)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(flowState.currentScene.mood.color)
                .italic()
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: flowState.currentSceneIndex)

            // User input
            HStack(spacing: 12) {
                TextField("", text: $flowState.userResponse, prompt: Text("Speak your heart...").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(flowState.currentScene.mood.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .focused($isInputFocused)

                // Continue button
                Button(action: {
                    HomeShowcaseHaptics.cardPress()
                    flowState.advanceScene()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(flowState.currentScene.mood.color)
                        )
                }
            }
            .opacity(flowState.textOpacity)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: flowState.currentSceneIndex)
        }
    }

    // MARK: - Final Scene

    private var finalScene: some View {
        VStack(spacing: 24) {
            // Embrace animation
            ZStack {
                Circle()
                    .fill(flowState.currentScene.mood.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + flowState.breathePhase * 0.15)

                Circle()
                    .fill(flowState.currentScene.mood.color.opacity(0.3))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            Text("You are home.")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(.white)

            Text("The father's love never left you.")
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(.white.opacity(0.7))

            Button(action: { dismiss() }) {
                Text("Return")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(flowState.currentScene.mood.color)
                    )
            }
            .padding(.top, 20)
        }
        .opacity(flowState.textOpacity)
    }
}

// MARK: - Preview

#Preview {
    CinematicFilmView()
}
