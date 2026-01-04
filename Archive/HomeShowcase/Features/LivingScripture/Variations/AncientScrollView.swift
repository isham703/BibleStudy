import SwiftUI

// MARK: - Ancient Scroll View
// Papyrus journey with weathered textures and sepia tones

struct AncientScrollView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = ShowcaseFlowState()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Papyrus background
            papyrusBackground

            // Content
            VStack(spacing: 0) {
                // Header
                headerBar

                Spacer()

                // Scroll content area
                scrollContent

                Spacer()

                // Interaction area
                if let prompt = flowState.currentScene.prompt {
                    interactionArea(prompt: prompt)
                } else {
                    finalScene
                }
            }
            .padding(.horizontal, 28)
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

    // MARK: - Papyrus Background

    private var papyrusBackground: some View {
        ZStack {
            // Base papyrus color
            Color.scrollPapyrus

            // Subtle texture gradient
            LinearGradient(
                colors: [
                    Color(hex: "E8D9B8"),
                    Color.scrollPapyrus,
                    Color(hex: "F0E2C8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Weathered edges
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.scrollSepia.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.scrollSepia.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
            }

            // Side weathering
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.scrollSepia.opacity(0.15), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60)
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.scrollSepia.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60)
            }

            // Subtle noise texture
            Rectangle()
                .fill(Color.scrollSepia.opacity(0.03))
                .blendMode(.multiply)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.scrollInk.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.scrollSepia.opacity(0.2)))
            }
            Spacer()

            // Scene indicator - scroll markers
            HStack(spacing: 12) {
                ForEach(0..<flowState.sceneCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index == flowState.currentSceneIndex ? flowState.currentScene.mood.scrollTint : Color.scrollSepia.opacity(0.3))
                        .frame(width: index == flowState.currentSceneIndex ? 20 : 12, height: 4)
                        .animation(.spring(duration: 0.3), value: flowState.currentSceneIndex)
                }
            }

            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding(.top, 60)
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        VStack(spacing: 0) {
            // Decorative top border
            decorativeBorder

            VStack(spacing: 28) {
                // Main narration
                Text(flowState.currentScene.narration)
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(Color.scrollInk)
                    .multilineTextAlignment(.center)
                    .opacity(flowState.textOpacity)
                    .animation(.easeInOut(duration: 0.8), value: flowState.currentSceneIndex)

                // Ornamental divider
                ScrollDivider(color: flowState.currentScene.mood.scrollTint)
                    .frame(width: 100)
                    .opacity(flowState.textOpacity)

                // Description
                Text(flowState.currentScene.description)
                    .font(.custom("CormorantGaramond-Regular", size: 17))
                    .foregroundStyle(Color.scrollInk.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .opacity(flowState.textOpacity)
                    .animation(.easeInOut(duration: 0.8).delay(0.3), value: flowState.currentSceneIndex)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)

            // Decorative bottom border
            decorativeBorder
        }
    }

    private var decorativeBorder: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(flowState.currentScene.mood.scrollTint.opacity(0.4))
                .frame(height: 1)
            Circle()
                .fill(flowState.currentScene.mood.scrollTint.opacity(0.6))
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(flowState.currentScene.mood.scrollTint.opacity(0.4))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Interaction Area

    private func interactionArea(prompt: String) -> some View {
        VStack(spacing: 16) {
            // Prompt
            Text(prompt)
                .font(.custom("CormorantGaramond-Italic", size: 16))
                .foregroundStyle(flowState.currentScene.mood.scrollTint)
                .opacity(flowState.textOpacity)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: flowState.currentSceneIndex)

            // Input field
            HStack(spacing: 12) {
                TextField("", text: $flowState.userResponse, prompt: Text("Write upon the scroll...").foregroundColor(Color.scrollSepia.opacity(0.5)))
                    .font(.custom("CormorantGaramond-Regular", size: 17))
                    .foregroundStyle(Color.scrollInk)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(flowState.currentScene.mood.scrollTint.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .focused($isInputFocused)

                Button(action: {
                    HomeShowcaseHaptics.cardPress()
                    flowState.advanceScene()
                }) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.scrollPapyrus)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(flowState.currentScene.mood.scrollTint)
                        )
                }
            }
            .opacity(flowState.textOpacity)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: flowState.currentSceneIndex)
        }
    }

    // MARK: - Final Scene

    private var finalScene: some View {
        VStack(spacing: 20) {
            // Seal icon
            ZStack {
                Circle()
                    .fill(flowState.currentScene.mood.scrollTint.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + flowState.breathePhase * 0.1)

                Circle()
                    .stroke(flowState.currentScene.mood.scrollTint.opacity(0.4), lineWidth: 2)
                    .frame(width: 70, height: 70)

                Image(systemName: "seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(flowState.currentScene.mood.scrollTint)
            }

            Text("You are home.")
                .font(.custom("CormorantGaramond-SemiBold", size: 26))
                .foregroundStyle(Color.scrollInk)

            Text("The father's love never left you.")
                .font(.custom("CormorantGaramond-Regular", size: 16))
                .foregroundStyle(Color.scrollInk.opacity(0.7))

            Button(action: { dismiss() }) {
                Text("Close the Scroll")
                    .font(.custom("CormorantGaramond-SemiBold", size: 15))
                    .foregroundStyle(Color.scrollPapyrus)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(flowState.currentScene.mood.scrollTint)
                    )
            }
            .padding(.top, 16)
        }
        .opacity(flowState.textOpacity)
    }
}

// MARK: - Scroll Divider

private struct ScrollDivider: View {
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, color.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center diamond
            Rectangle()
                .fill(color)
                .frame(width: 6, height: 6)
                .rotationEffect(.degrees(45))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.6), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

// MARK: - Preview

#Preview {
    AncientScrollView()
}
