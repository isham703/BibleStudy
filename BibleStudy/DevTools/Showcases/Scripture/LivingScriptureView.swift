import SwiftUI

// MARK: - Living Scripture View
// Immersive second-person biblical narrative experience
// Dreamlike, intimate, cinematic - like entering a memory

struct LivingScriptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var flowState: LivingScriptureFlowState

    let storyType: StoryData.StoryType

    init(storyType: StoryData.StoryType = .prodigalSon) {
        self.storyType = storyType
        _flowState = State(initialValue: LivingScriptureFlowState(storyType: storyType))
    }

    var body: some View {
        ZStack {
            // Atmospheric background
            atmosphericBackground

            // Content
            VStack(spacing: 0) {
                // Header with close and progress
                headerSection

                Spacer()

                // Main narrative content
                narrativeContent

                Spacer()

                // User interaction or final scene
                if flowState.isAtFinalScene {
                    finalSceneContent
                } else if let prompt = flowState.currentScene.prompt {
                    promptContent(prompt: prompt)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            appState.hideTabBar = true
            flowState.startExperience()
        }
        .onDisappear {
            appState.hideTabBar = false
            flowState.reset()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(Typography.Icon.md)
                    .foregroundStyle(.white.opacity(Theme.Opacity.medium))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(Theme.Opacity.overlay)))
            }

            Spacer()

            // Scene indicator
            sceneProgressIndicator

            Spacer()

            Color.clear.frame(width: 40)
        }
        .padding(.top, 60)
    }

    private var sceneProgressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<flowState.scenes.count, id: \.self) { index in
                Circle()
                    .fill(
                        index == flowState.currentSceneIndex
                            ? flowState.currentScene.mood.moodColor
                            : Color.white.opacity(Theme.Opacity.quarter)
                    )
                    .frame(
                        width: index == flowState.currentSceneIndex ? 8 : 6,
                        height: index == flowState.currentSceneIndex ? 8 : 6
                    )
                    .scaleEffect(
                        index == flowState.currentSceneIndex
                            ? 1 + flowState.breathePhase * 0.15
                            : 1
                    )
                    .animation(Theme.Animation.settle, value: flowState.currentSceneIndex)
            }
        }
    }

    // MARK: - Narrative Content

    private var narrativeContent: some View {
        VStack(spacing: 24) {
            // Narration - the voice in your head
            Text(flowState.currentScene.narration)
                .font(Typography.Scripture.title.weight(.light))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            // Description - the world around you
            Text(flowState.currentScene.description)
                .font(Typography.Scripture.body)
                .italic()
                .foregroundStyle(.white.opacity(Theme.Opacity.midHeavy))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(maxWidth: 320)
        }
        .opacity(flowState.textOpacity)
    }

    // MARK: - Prompt Content

    private func promptContent(prompt: String) -> some View {
        VStack(spacing: 20) {
            // Prompt text
            Text(prompt)
                .font(Typography.Scripture.body)
                .italic()
                .foregroundStyle(flowState.currentScene.mood.moodColor.opacity(Theme.Opacity.high))
                .multilineTextAlignment(.center)

            // Text field
            TextField("", text: $flowState.userResponse, prompt: Text("Share your thoughts...").foregroundStyle(.white.opacity(Theme.Opacity.subtle)))
                .font(Typography.Scripture.footnote)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(.white.opacity(Theme.Opacity.overlay))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(flowState.currentScene.mood.moodColor.opacity(Theme.Opacity.subtle), lineWidth: 1)
                )

            // Continue button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                flowState.advanceScene()
            }) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(Typography.Command.label)
                    Image(systemName: "arrow.right")
                        .font(Typography.Command.meta.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(flowState.currentScene.mood.moodColor.opacity(Theme.Opacity.pressed))
                )
            }
        }
        .opacity(flowState.textOpacity)
    }

    // MARK: - Final Scene Content

    private var finalSceneContent: some View {
        VStack(spacing: 24) {
            // Embrace animation
            ZStack {
                Circle()
                    .fill(flowState.currentScene.mood.moodColor.opacity(Theme.Opacity.light))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + flowState.breathePhase * 0.15)

                Circle()
                    .fill(flowState.currentScene.mood.moodColor.opacity(Theme.Opacity.subtle))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.fill")
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(.white)
            }

            Text(flowState.finalMessage.title)
                .font(Typography.Scripture.title.weight(.light))
                .foregroundStyle(.white)

            Text(flowState.finalMessage.subtitle)
                .font(Typography.Scripture.body)
                .foregroundStyle(.white.opacity(Theme.Opacity.heavy))

            Button(action: {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }) {
                Text("Return")
                    .font(Typography.Icon.md)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(flowState.currentScene.mood.moodColor))
            }
            .padding(.top, 20)
        }
        .opacity(flowState.textOpacity)
    }

    // MARK: - Atmospheric Background

    private var atmosphericBackground: some View {
        ZStack {
            // Base - deep warm black
            Color.surfaceDeep

            // Mood-based gradient
            LinearGradient(
                colors: flowState.currentScene.mood.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(Theme.Opacity.tertiary)
            .animation(.easeInOut(duration: 0.8), value: flowState.currentSceneIndex)

            // Vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.heavy)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )

            // Breathing light effect
            RadialGradient(
                colors: [
                    flowState.currentScene.mood.moodColor.opacity(0.15 + flowState.breathePhase * 0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .animation(.easeInOut(duration: 0.8), value: flowState.currentSceneIndex)

            // Film grain overlay
            Rectangle()
                .fill(Color.white.opacity(Theme.Opacity.faint))
                .blendMode(.overlay)
        }
    }
}

// MARK: - Preview

#Preview {
    LivingScriptureView(storyType: .prodigalSon)
        .environment(AppState())
}
