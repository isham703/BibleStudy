import SwiftUI

// MARK: - Celestial Cathedral Palace Page
// Cosmic Sacred / Art Nouveau meets Space Opera aesthetic
// Mystical deep blues/purples, parallax starfield, nebula gradients

struct CelestialCathedralPalacePage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var currentRoom = 0
    @State private var currentPhase: MemorizationPhase = .visualize
    @State private var revealedWords: Set<Int> = []
    @State private var recallText = ""
    @State private var showRecallFeedback = false
    @State private var isComplete = false
    @State private var floatPhase: CGFloat = 0
    @State private var nebulaPhase: CGFloat = 0
    @FocusState private var isRecallFocused: Bool

    private let rooms = PalaceRoom.psalm23Rooms
    private let accentColor = Color.celestialPurple

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
                        style: .celestial,
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
                        style: .celestial
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

            // Aurora overlay at top
            auroraOverlay
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatPhase = 1
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                nebulaPhase = 1
            }
        }
        .onChange(of: currentRoom) { _, _ in
            resetRoomState()
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            // Cosmic void base
            Color.celestialDeep

            // Nebula gradients (slowly drifting)
            celestialNebulaLayer

            // 3-layer starfield
            starfieldLayer

            // Current room ambient color
            RadialGradient(
                colors: [
                    rooms[currentRoom].primaryColor.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .animation(.easeInOut(duration: 1), value: currentRoom)
        }
    }

    private var celestialNebulaLayer: some View {
        GeometryReader { geo in
            ZStack {
                // Purple nebula
                Circle()
                    .fill(Color.celestialPurple.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(
                        x: -100 + nebulaPhase * 50,
                        y: -200 + nebulaPhase * 30
                    )

                // Pink nebula
                Circle()
                    .fill(Color.celestialPink.opacity(0.1))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(
                        x: 100 - nebulaPhase * 40,
                        y: 100 + nebulaPhase * 20
                    )

                // Cyan accent
                Circle()
                    .fill(Color.celestialCyan.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(
                        x: nebulaPhase * 60 - 30,
                        y: 200 - nebulaPhase * 40
                    )
            }
            .opacity(UIAccessibility.isReduceMotionEnabled ? 0.5 : 1)
        }
    }

    private var starfieldLayer: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Static dim stars (40)
                ForEach(0..<40, id: \.self) { i in
                    let seed = Double(i)
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.4)))
                        .frame(width: CGFloat.random(in: 1...2))
                        .position(
                            x: CGFloat(seed * 23.7).truncatingRemainder(dividingBy: geo.size.width),
                            y: CGFloat(seed * 17.3).truncatingRemainder(dividingBy: geo.size.height)
                        )
                }

                // Layer 2: Twinkling stars (15) - only if reduce motion disabled
                if !UIAccessibility.isReduceMotionEnabled {
                    ForEach(0..<15, id: \.self) { i in
                        let seed = Double(i + 100)
                        Circle()
                            .fill(Color.white)
                            .frame(width: CGFloat.random(in: 2...3))
                            .position(
                                x: CGFloat(seed * 31.1).truncatingRemainder(dividingBy: geo.size.width),
                                y: CGFloat(seed * 19.7).truncatingRemainder(dividingBy: geo.size.height)
                            )
                            .opacity(0.3 + floatPhase * 0.5 * Double((i % 3) + 1) / 3)
                    }
                }

                // Layer 3: Bright drifting stars (5)
                ForEach(0..<5, id: \.self) { i in
                    let seed = Double(i + 200)
                    Circle()
                        .fill(Color.celestialStarlight)
                        .frame(width: 4)
                        .shadow(color: .white, radius: 4)
                        .position(
                            x: CGFloat(seed * 47.3).truncatingRemainder(dividingBy: geo.size.width),
                            y: CGFloat(seed * 29.1).truncatingRemainder(dividingBy: geo.size.height)
                        )
                        .offset(
                            x: UIAccessibility.isReduceMotionEnabled ? 0 : floatPhase * CGFloat(i % 2 == 0 ? 10 : -10),
                            y: UIAccessibility.isReduceMotionEnabled ? 0 : floatPhase * CGFloat(i % 2 == 0 ? -5 : 5)
                        )
                }
            }
        }
    }

    private var auroraOverlay: some View {
        VStack {
            LinearGradient(
                colors: [
                    Color.celestialAurora.opacity(UIAccessibility.isReduceMotionEnabled ? 0.2 : 0.3 + floatPhase * 0.1),
                    Color.celestialPurple.opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 200)
            .blur(radius: 30)
            .allowsHitTesting(false)

            Spacer()
        }
    }

    // MARK: - Current Room Content

    private var currentRoomContent: some View {
        let room = rooms[currentRoom]

        return VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            Spacer()

            // Room icon with cosmic glow
            ZStack {
                // Outer glow rings
                Circle()
                    .stroke(room.primaryColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(1 + floatPhase * 0.15)

                Circle()
                    .fill(room.primaryColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [room.primaryColor.opacity(0.4), room.primaryColor.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: room.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, room.primaryColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: room.primaryColor.opacity(0.8), radius: 15)
            }
            .accessibleAnimation(HomeShowcaseTheme.Animation.pulse, value: floatPhase)

            // Visual cue (Visualize phase)
            if currentPhase == .visualize {
                Text(room.visualCue)
                    .font(.custom("CormorantGaramond-Italic", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.celestialStarlight.opacity(0.7))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                    .transition(.opacity)

                // Phrase displayed prominently
                Text(room.phrase)
                    .font(.custom("Cinzel-Regular", size: 26, relativeTo: .title))
                    .foregroundStyle(Color.celestialStarlight)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                    .shadow(color: accentColor.opacity(0.5), radius: 10)
                    .transition(.opacity)
            }

            // Connect phase - tap to reveal
            if currentPhase == .connect {
                PhraseRevealView(
                    phrase: room.phrase,
                    revealedWords: $revealedWords,
                    accentColor: room.primaryColor,
                    style: .celestial,
                    onWordRevealed: { _ in HomeShowcaseHaptics.celestialWordReveal() },
                    onAllRevealed: {
                        HomeShowcaseHaptics.celestialPhaseComplete()
                        advancePhase()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Recall phase - type from memory
            if currentPhase == .recall {
                RecallInputView(
                    expectedPhrase: room.phrase,
                    inputText: $recallText,
                    showFeedback: $showRecallFeedback,
                    isFocused: $isRecallFocused,
                    accentColor: room.primaryColor,
                    style: .celestial,
                    onCheck: {
                        HomeShowcaseHaptics.celestialRoomComplete()
                        advanceRoom()
                    },
                    onSkip: {
                        advanceRoom()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer()
        }
        .accessibleAnimation(HomeShowcaseTheme.Animation.contemplative, value: currentPhase)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.lg) {
            // Progress bar - constellation dots
            HStack(spacing: HomeShowcaseTheme.Spacing.lg) {
                ForEach(0..<rooms.count, id: \.self) { index in
                    ZStack {
                        // Glow for completed/current
                        if index <= currentRoom {
                            Circle()
                                .fill(rooms[index].primaryColor.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .blur(radius: 4)
                        }

                        Circle()
                            .fill(index <= currentRoom ? rooms[index].primaryColor : Color.white.opacity(0.2))
                            .frame(width: 10, height: 10)
                            .shadow(color: index <= currentRoom ? rooms[index].primaryColor : .clear, radius: 4)
                    }
                }
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            // Continue button (Visualize phase only)
            if currentPhase == .visualize {
                Button(action: {
                    HomeShowcaseHaptics.celestialPress()
                    advancePhase()
                }) {
                    HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                        Text("Continue")
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                    .padding(.vertical, HomeShowcaseTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, Color.celestialPink.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: accentColor.opacity(0.5), radius: 10)
                    )
                }
            }
        }
        .padding(.bottom, HomeShowcaseTheme.Spacing.xxl)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent.delay(0.6), value: isVisible)
    }

    // MARK: - Navigation Actions

    private func advancePhase() {
        if let nextPhase = currentPhase.next {
            withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                currentPhase = nextPhase
                showRecallFeedback = false
            }
        } else {
            advanceRoom()
        }
    }

    private func advanceRoom() {
        if currentRoom < rooms.count - 1 {
            withAnimation(.easeInOut(duration: 1)) {
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
    CelestialCathedralPalacePage()
}
