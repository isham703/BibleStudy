import SwiftUI

// MARK: - Scholarly Study Palace Page
// Contemporary Editorial / Swiss Modernist aesthetic
// Clean light-mode design with typography focus, marginalia annotations

struct ScholarlyStudyPalacePage: View {
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
    private let accentColor = Color.scholarIndigo

    var body: some View {
        ZStack {
            // Background
            background

            VStack(spacing: 0) {
                // Header
                MemoryPalaceHeaderLight(accentColor: accentColor, isVisible: isVisible)

                if isComplete {
                    CompletionCelebration(
                        accentColor: accentColor,
                        style: .scholarly,
                        floatPhase: floatPhase,
                        onWalkAgain: restart
                    )
                } else {
                    // Room navigator (light variant)
                    RoomNavigatorLight(
                        currentRoom: $currentRoom,
                        accentColor: accentColor,
                        isVisible: isVisible,
                        onRoomTap: { _ in resetRoomState() }
                    )

                    // Horizontal rule
                    Rectangle()
                        .fill(Color.scholarInk.opacity(0.1))
                        .frame(height: 0.5)
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                        .padding(.top, HomeShowcaseTheme.Spacing.md)

                    // Phase indicator
                    PhaseIndicator(
                        currentPhase: currentPhase,
                        accentColor: accentColor,
                        style: .scholarly
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
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
        .onChange(of: currentRoom) { _, _ in
            resetRoomState()
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            // Warm white base
            Color(hex: "FAF8F4")

            // Subtle vellum overlay
            Color(hex: "F5F0E6").opacity(0.5)

            // Paper texture (subtle noise effect via overlapping rectangles)
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.scholarInk.opacity(0.005))
                        .frame(
                            width: CGFloat.random(in: 50...200),
                            height: CGFloat.random(in: 50...200)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .rotationEffect(.degrees(Double.random(in: 0...90)))
                }
            }
            .opacity(0.5)
        }
    }

    // MARK: - Current Room Content

    private var currentRoomContent: some View {
        let room = rooms[currentRoom]

        return VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            Spacer()

            // Marginalia-style room number and name
            HStack(alignment: .top, spacing: HomeShowcaseTheme.Spacing.lg) {
                // Room number in red (marginalia style)
                Text("\(currentRoom + 1).")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.marginRed)

                VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.xs) {
                    Text(room.name.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color.footnoteGray)

                    // Simple room icon
                    Image(systemName: room.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(accentColor)
                        .padding(.top, HomeShowcaseTheme.Spacing.sm)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            // Visual cue (Visualize phase)
            if currentPhase == .visualize {
                VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
                    Text(room.visualCue)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(Color.footnoteGray)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Phrase displayed prominently
                    Text(room.phrase)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.scholarInk)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Decorative underline
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 80, height: 3)
                }
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                .transition(.opacity)
            }

            // Connect phase - tap to reveal
            if currentPhase == .connect {
                PhraseRevealView(
                    phrase: room.phrase,
                    revealedWords: $revealedWords,
                    accentColor: accentColor,
                    style: .scholarly,
                    onWordRevealed: { _ in HomeShowcaseHaptics.studyWordReveal() },
                    onAllRevealed: {
                        HomeShowcaseHaptics.studyPhaseComplete()
                        advancePhase()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            // Recall phase - type from memory
            if currentPhase == .recall {
                RecallInputView(
                    expectedPhrase: room.phrase,
                    inputText: $recallText,
                    showFeedback: $showRecallFeedback,
                    isFocused: $isRecallFocused,
                    accentColor: accentColor,
                    style: .scholarly,
                    onCheck: {
                        HomeShowcaseHaptics.studyRoomComplete()
                        advanceRoom()
                    },
                    onSkip: {
                        advanceRoom()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            Spacer()
        }
        .accessibleAnimation(HomeShowcaseTheme.Animation.quick, value: currentPhase)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.lg) {
            // Progress bar - simple rectangles
            HStack(spacing: HomeShowcaseTheme.Spacing.xs) {
                ForEach(0..<rooms.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentRoom ? accentColor : Color.scholarInk.opacity(0.1))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            // Continue button (Visualize phase only)
            if currentPhase == .visualize {
                Button(action: {
                    HomeShowcaseHaptics.studyPress()
                    advancePhase()
                }) {
                    HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                    .padding(.vertical, HomeShowcaseTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                            .fill(accentColor)
                    )
                }
            }
        }
        .padding(.bottom, HomeShowcaseTheme.Spacing.xxl)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.quick.delay(0.2), value: isVisible)
    }

    // MARK: - Navigation Actions

    private func advancePhase() {
        if let nextPhase = currentPhase.next {
            withAnimation(HomeShowcaseTheme.Animation.quick) {
                currentPhase = nextPhase
                showRecallFeedback = false
            }
        } else {
            advanceRoom()
        }
    }

    private func advanceRoom() {
        if currentRoom < rooms.count - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentRoom += 1
                resetRoomState()
            }
        } else {
            HomeShowcaseHaptics.success()
            withAnimation(HomeShowcaseTheme.Animation.standard) {
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
        withAnimation(HomeShowcaseTheme.Animation.quick) {
            currentRoom = 0
            isComplete = false
            resetRoomState()
        }
    }
}

// MARK: - Preview

#Preview {
    ScholarlyStudyPalacePage()
}
