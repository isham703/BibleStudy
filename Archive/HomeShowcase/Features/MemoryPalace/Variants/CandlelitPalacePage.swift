import SwiftUI

// MARK: - Candlelit Palace Page
// Gothic Romantic / Chiaroscuro aesthetic
// Warm amber glow, medieval chapel atmosphere with flickering candlelight

struct CandlelitPalacePage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var currentRoom = 0
    @State private var currentPhase: MemorizationPhase = .visualize
    @State private var revealedWords: Set<Int> = []
    @State private var recallText = ""
    @State private var showRecallFeedback = false
    @State private var isComplete = false
    @State private var floatPhase: CGFloat = 0
    @FocusState private var isRecallFocused: Bool

    private let rooms = PalaceRoom.psalm23Rooms
    private let accentColor = Color.candleAmber

    var body: some View {
        ZStack {
            // Ambient background
            ambientBackground

            VStack(spacing: 0) {
                // Header
                MemoryPalaceHeader(accentColor: accentColor, isVisible: isVisible)

                if isComplete {
                    CompletionCelebration(
                        accentColor: accentColor,
                        style: .candlelit,
                        floatPhase: floatPhase,
                        onWalkAgain: restart
                    )
                } else {
                    // Room navigator
                    RoomNavigator(
                        currentRoom: $currentRoom,
                        accentColor: rooms[currentRoom].primaryColor,
                        isVisible: isVisible,
                        onRoomTap: { _ in resetRoomState() }
                    )

                    // Phase indicator
                    PhaseIndicator(
                        currentPhase: currentPhase,
                        accentColor: accentColor,
                        style: .candlelit
                    )
                    .padding(.top, HomeShowcaseTheme.Spacing.lg)
                    .opacity(isVisible ? 1 : 0)

                    // Current room content
                    currentRoomContent
                        .id("\(currentRoom)-\(currentPhase.rawValue)")

                    Spacer()

                    // Bottom controls
                    bottomControls
                }
            }

            // Vignette overlay
            vignetteOverlay
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatPhase = 1
            }
        }
        .onChange(of: currentRoom) { _, _ in
            resetRoomState()
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            // Base color - near black
            Color(hex: "030308")

            // Current room ambient color
            rooms[currentRoom].ambientColor.opacity(0.4)
                .animation(.easeInOut(duration: 0.8), value: currentRoom)

            // Floating ember particles
            GeometryReader { geo in
                ForEach(0..<10, id: \.self) { i in
                    Circle()
                        .fill(accentColor.opacity(Double.random(in: 0.2...0.5)))
                        .frame(width: CGFloat.random(in: 3...8))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .offset(y: floatPhase * CGFloat.random(in: -30...0))
                        .blur(radius: 2)
                        .opacity(UIAccessibility.isReduceMotionEnabled ? 0 : 1)
                }
            }

            // Candle glow from bottom center
            RadialGradient(
                colors: [
                    accentColor.opacity(0.2),
                    accentColor.opacity(0.05),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 50,
                endRadius: 400
            )
        }
    }

    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.4)
            ],
            center: .center,
            startRadius: 150,
            endRadius: 500
        )
        .allowsHitTesting(false)
    }

    // MARK: - Current Room Content

    private var currentRoomContent: some View {
        let room = rooms[currentRoom]

        return VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            Spacer()

            // Room icon with glow
            ZStack {
                Circle()
                    .fill(room.primaryColor.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1 + floatPhase * 0.1)
                    .blur(radius: 20)

                Circle()
                    .fill(room.primaryColor.opacity(0.3))
                    .frame(width: 100, height: 100)

                Image(systemName: room.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(room.primaryColor)
                    .shadow(color: room.primaryColor.opacity(0.5), radius: 10)
            }
            .accessibleAnimation(HomeShowcaseTheme.Animation.pulse, value: floatPhase)

            // Visual cue (Visualize phase)
            if currentPhase == .visualize {
                Text(room.visualCue)
                    .font(.custom("CormorantGaramond-Italic", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.moonlitParchment.opacity(0.7))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                    .transition(.opacity)

                // Phrase displayed prominently
                Text(room.phrase)
                    .font(.custom("Cinzel-Regular", size: 26, relativeTo: .title))
                    .foregroundStyle(Color.moonlitParchment)
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                    .transition(.opacity)
            }

            // Connect phase - tap to reveal
            if currentPhase == .connect {
                PhraseRevealView(
                    phrase: room.phrase,
                    revealedWords: $revealedWords,
                    accentColor: room.primaryColor,
                    style: .candlelit,
                    onWordRevealed: { _ in HomeShowcaseHaptics.palaceWordReveal() },
                    onAllRevealed: {
                        HomeShowcaseHaptics.palacePhaseComplete()
                        advancePhase()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Recall phase - type from memory
            if currentPhase == .recall {
                RecallInputView(
                    expectedPhrase: room.phrase,
                    inputText: $recallText,
                    showFeedback: $showRecallFeedback,
                    isFocused: $isRecallFocused,
                    accentColor: room.primaryColor,
                    style: .candlelit,
                    onCheck: {
                        HomeShowcaseHaptics.palaceRoomComplete()
                        advanceRoom()
                    },
                    onSkip: {
                        advanceRoom()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()
        }
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent, value: currentPhase)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.lg) {
            // Progress bar
            HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                ForEach(0..<rooms.count, id: \.self) { index in
                    // Flame-shaped progress indicator
                    Image(systemName: index <= currentRoom ? "flame.fill" : "flame")
                        .font(.system(size: 14))
                        .foregroundStyle(index <= currentRoom ? rooms[index].primaryColor : Color.white.opacity(0.2))
                        .shadow(color: index <= currentRoom ? rooms[index].primaryColor.opacity(0.4) : .clear, radius: 4)
                }
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            // Continue button (Visualize phase only)
            if currentPhase == .visualize {
                Button(action: {
                    HomeShowcaseHaptics.palacePress()
                    advancePhase()
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                        .padding(.vertical, HomeShowcaseTheme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.4), radius: 8)
                        )
                }
            }
        }
        .padding(.bottom, HomeShowcaseTheme.Spacing.xxl)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent.delay(0.4), value: isVisible)
    }

    // MARK: - Navigation Actions

    private func advancePhase() {
        if let nextPhase = currentPhase.next {
            withAnimation(HomeShowcaseTheme.Animation.reverent) {
                currentPhase = nextPhase
                showRecallFeedback = false
            }
        } else {
            advanceRoom()
        }
    }

    private func advanceRoom() {
        if currentRoom < rooms.count - 1 {
            withAnimation(HomeShowcaseTheme.Animation.unfurl) {
                currentRoom += 1
                resetRoomState()
            }
        } else {
            HomeShowcaseHaptics.success()
            withAnimation(HomeShowcaseTheme.Animation.cinematic) {
                isComplete = true
            }
        }
    }

    private func resetRoomState() {
        revealedWords = []
        recallText = ""
        showRecallFeedback = false
        currentPhase = .visualize
        isRecallFocused = false
    }

    private func restart() {
        withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
            currentRoom = 0
            isComplete = false
            resetRoomState()
        }
    }
}

// MARK: - Preview

#Preview {
    CandlelitPalacePage()
}
