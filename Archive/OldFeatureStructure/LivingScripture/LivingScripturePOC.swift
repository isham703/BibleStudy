import SwiftUI

// MARK: - Living Scripture POC
// First-person immersive biblical narrative experience
// Aesthetic: Dreamlike, intimate, cinematic - like entering a memory

struct LivingScripturePOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentScene = 0
    @State private var isVisible = false
    @State private var showingResponse = false
    @State private var userResponse = ""
    @State private var breathePhase: CGFloat = 0
    @State private var textOpacity: Double = 0
    @FocusState private var isInputFocused: Bool

    // The Prodigal Son - told in second person
    private let scenes: [ImmersiveScene] = [
        ImmersiveScene(
            narration: "The road stretches endlessly before you.",
            description: "Dust coats your sandals. Your father's house is three days behind. The coins in your pouch feel heavier than they should.",
            ambient: "desert_wind",
            mood: .contemplative,
            prompt: "What are you feeling right now?"
        ),
        ImmersiveScene(
            narration: "The city rises from the horizon.",
            description: "Music and laughter spill from open doorways. Merchants call out their wares. Everything you've ever wanted is finally within reach.",
            ambient: "city_bustle",
            mood: .excited,
            prompt: "What do you do first?"
        ),
        ImmersiveScene(
            narration: "The last coin slips through your fingers.",
            description: "The room is empty now. The friends who filled it have vanished like morning mist. Your stomach aches. When did you last eat?",
            ambient: "silence",
            mood: .desolate,
            prompt: "Where do you go from here?"
        ),
        ImmersiveScene(
            narration: "The pigs don't even look up.",
            description: "Their slop smells better than anything you've tasted in days. You reach toward it, and something breaks inside you. You remember your father's servants eating bread...",
            ambient: "pig_sounds",
            mood: .broken,
            prompt: "What do you want to say to your father?"
        ),
        ImmersiveScene(
            narration: "You see him before he sees you.",
            description: "But no — he's already running. An old man, running. His robes fly behind him. He's weeping. He's reaching for you.",
            ambient: "running_footsteps",
            mood: .redemption,
            prompt: nil
        )
    ]

    var currentSceneData: ImmersiveScene {
        scenes[min(currentScene, scenes.count - 1)]
    }

    var body: some View {
        ZStack {
            // Atmospheric background
            atmosphericBackground

            // Content
            VStack(spacing: 0) {
                // Close button
                closeButton

                Spacer()

                // Main narrative content
                narrativeContent

                Spacer()

                // User interaction area
                if let prompt = currentSceneData.prompt {
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
            withAnimation(.easeIn(duration: 2.0)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            // Fade in text after initial delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 1.5)) {
                    textOpacity = 1
                }
            }
        }
    }

    // MARK: - Atmospheric Background

    private var atmosphericBackground: some View {
        ZStack {
            // Base - deep warm black
            Color(hex: "0a0908")

            // Mood-based gradient
            moodGradient
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
                    moodColor.opacity(0.15 + breathePhase * 0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )

            // Film grain overlay (simulated)
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
    }

    private var moodGradient: some View {
        LinearGradient(
            colors: moodGradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var moodColor: Color {
        switch currentSceneData.mood {
        case .contemplative: return Color(hex: "c9a227")
        case .excited: return Color(hex: "e74c3c")
        case .desolate: return Color(hex: "2c3e50")
        case .broken: return Color(hex: "1a1a2e")
        case .redemption: return Color(hex: "d4a853")
        }
    }

    private var moodGradientColors: [Color] {
        switch currentSceneData.mood {
        case .contemplative: return [Color(hex: "2c1810"), Color(hex: "0a0908")]
        case .excited: return [Color(hex: "2d1f1f"), Color(hex: "0a0908")]
        case .desolate: return [Color(hex: "0f1419"), Color(hex: "0a0908")]
        case .broken: return [Color(hex: "0a0a14"), Color(hex: "050508")]
        case .redemption: return [Color(hex: "1a1408"), Color(hex: "0a0908")]
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
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
                ForEach(0..<scenes.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentScene ? moodColor : .white.opacity(0.2))
                        .frame(width: index == currentScene ? 8 : 6, height: index == currentScene ? 8 : 6)
                        .animation(.spring(duration: 0.3), value: currentScene)
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
            Text(currentSceneData.narration)
                .font(.system(size: 32, weight: .light, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.8), value: currentScene)

            // Description - smaller, atmospheric
            Text(currentSceneData.description)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.3), value: currentScene)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Interaction Area

    private func interactionArea(prompt: String) -> some View {
        VStack(spacing: 20) {
            // AI prompt
            Text(prompt)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(moodColor)
                .italic()
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: currentScene)

            // User input
            HStack(spacing: 12) {
                TextField("", text: $userResponse, prompt: Text("Speak your heart...").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(moodColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .focused($isInputFocused)

                // Continue button
                Button(action: advanceScene) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(moodColor)
                        )
                }
            }
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.6).delay(0.8), value: currentScene)
        }
    }

    // MARK: - Final Scene

    private var finalScene: some View {
        VStack(spacing: 24) {
            // Embrace animation
            ZStack {
                Circle()
                    .fill(moodColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + breathePhase * 0.15)

                Circle()
                    .fill(moodColor.opacity(0.3))
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
                            .fill(moodColor)
                    )
            }
            .padding(.top, 20)
        }
        .opacity(textOpacity)
    }

    // MARK: - Actions

    private func advanceScene() {
        // Fade out
        withAnimation(.easeOut(duration: 0.5)) {
            textOpacity = 0
        }

        // Advance after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if currentScene < scenes.count - 1 {
                currentScene += 1
                userResponse = ""

                // Fade in new scene
                withAnimation(.easeIn(duration: 1.0)) {
                    textOpacity = 1
                }
            }
        }
    }
}

// MARK: - Immersive Scene Model

struct ImmersiveScene {
    let narration: String
    let description: String
    let ambient: String
    let mood: SceneMood
    let prompt: String?
}

enum SceneMood {
    case contemplative
    case excited
    case desolate
    case broken
    case redemption
}

// MARK: - Preview

#Preview {
    LivingScripturePOC()
}
