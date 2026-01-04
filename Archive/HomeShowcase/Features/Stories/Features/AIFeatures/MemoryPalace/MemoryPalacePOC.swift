import SwiftUI

// MARK: - Memory Palace POC
// Visual journeys for scripture memorization
// Aesthetic: Architectural, spatial, dreamlike navigation

struct MemoryPalacePOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var currentRoom = 0
    @State private var showingVerse = false
    @State private var revealedWords: Set<Int> = []
    @State private var floatPhase: CGFloat = 0
    @State private var isComplete = false

    private let verse = "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters."
    private let reference = "Psalm 23:1-2"

    private let rooms: [POCRoom] = [
        POCRoom(
            name: "The Entrance Hall",
            icon: "door.left.hand.open",
            color: Color(hex: "6366f1"),
            phrase: "The Lord is my shepherd;",
            visualCue: "A golden shepherd's staff leans against the grand doorway",
            ambientColor: Color(hex: "1a1a3e")
        ),
        POCRoom(
            name: "The Great Room",
            icon: "building.columns.fill",
            color: Color(hex: "8b5cf6"),
            phrase: "I shall not want.",
            visualCue: "An overflowing cornucopia sits on a marble table",
            ambientColor: Color(hex: "2a1a3e")
        ),
        POCRoom(
            name: "The Garden",
            icon: "leaf.fill",
            color: Color(hex: "10b981"),
            phrase: "He maketh me to lie down",
            visualCue: "A soft bed of moss beneath an ancient olive tree",
            ambientColor: Color(hex: "0a2e1a")
        ),
        POCRoom(
            name: "The Meadow",
            icon: "sun.max.fill",
            color: Color(hex: "f59e0b"),
            phrase: "in green pastures:",
            visualCue: "Rolling emerald hills stretch to the horizon",
            ambientColor: Color(hex: "2e2a0a")
        ),
        POCRoom(
            name: "The Still Waters",
            icon: "water.waves",
            color: Color(hex: "06b6d4"),
            phrase: "he leadeth me beside the still waters.",
            visualCue: "A crystalline pool reflects infinite stars",
            ambientColor: Color(hex: "0a1a2e")
        )
    ]

    var body: some View {
        ZStack {
            // Ambient background
            ambientBackground

            VStack(spacing: 0) {
                // Header
                header

                if isComplete {
                    completionView
                } else {
                    // Room navigation
                    roomNavigator

                    // Current room content
                    currentRoomView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))

                    Spacer()

                    // Progress and controls
                    bottomControls
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatPhase = 1
            }
        }
    }

    // MARK: - Background

    private var ambientBackground: some View {
        ZStack {
            // Base - current room color
            rooms[currentRoom].ambientColor
                .animation(.easeInOut(duration: 0.8), value: currentRoom)

            // Floating particles
            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { i in
                    Circle()
                        .fill(rooms[currentRoom].color.opacity(0.3))
                        .frame(width: CGFloat.random(in: 4...12))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .offset(y: floatPhase * CGFloat.random(in: -20...20))
                        .blur(radius: 2)
                }
            }

            // Radial glow from center
            RadialGradient(
                colors: [
                    rooms[currentRoom].color.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .animation(.easeInOut(duration: 0.8), value: currentRoom)

            // Architectural frame overlay
            architecturalFrame
        }
    }

    private var architecturalFrame: some View {
        GeometryReader { geo in
            // Corner pillars
            Group {
                // Top left
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 150)
                    .position(x: 20, y: 100)

                // Top right
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 40, height: 150)
                    .position(x: geo.size.width - 20, y: 100)

                // Arch at top
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 60))
                    path.addQuadCurve(
                        to: CGPoint(x: geo.size.width - 40, y: 60),
                        control: CGPoint(x: geo.size.width / 2, y: -20)
                    )
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 1).delay(0.5), value: isVisible)
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
                Text("MEMORY PALACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(rooms[currentRoom].color)

                Text(reference)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Room Navigator

    private var roomNavigator: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(rooms.enumerated()), id: \.offset) { index, room in
                        Button(action: {
                            withAnimation(.spring(duration: 0.5)) {
                                currentRoom = index
                                showingVerse = false
                                revealedWords = []
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(currentRoom == index ? room.color : Color.white.opacity(0.1))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: room.icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(currentRoom == index ? .white : .white.opacity(0.5))
                                }

                                Text(room.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(currentRoom == index ? .white : .white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 24)
            }
            .onChange(of: currentRoom) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .padding(.top, 24)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
    }

    // MARK: - Current Room View

    private var currentRoomView: some View {
        let room = rooms[currentRoom]

        return VStack(spacing: 24) {
            Spacer()

            // Room icon with glow
            ZStack {
                Circle()
                    .fill(room.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1 + floatPhase * 0.1)

                Circle()
                    .fill(room.color.opacity(0.3))
                    .frame(width: 100, height: 100)

                Image(systemName: room.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(room.color)
                    .shadow(color: room.color.opacity(0.5), radius: 10)
            }

            // Visual cue
            Text(room.visualCue)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Phrase with tap to reveal
            VStack(spacing: 16) {
                if showingVerse {
                    phraseRevealView(phrase: room.phrase)
                } else {
                    Button(action: {
                        withAnimation(.spring(duration: 0.5)) {
                            showingVerse = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "eye")
                            Text("Reveal Scripture")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(room.color.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(room.color.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .frame(height: 120)

            Spacer()
        }
        .id(currentRoom)
    }

    private func phraseRevealView(phrase: String) -> some View {
        let words = phrase.split(separator: " ").map(String.init)

        return VStack(spacing: 16) {
            // Tap words to reveal
            POCFlowLayout(spacing: 8) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    Button(action: {
                        _ = withAnimation(.spring(duration: 0.3)) {
                            revealedWords.insert(index)
                        }
                        checkCompletion()
                    }) {
                        Text(revealedWords.contains(index) ? word : "•••")
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .foregroundStyle(revealedWords.contains(index) ? .white : .white.opacity(0.3))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(revealedWords.contains(index) ?
                                          rooms[currentRoom].color.opacity(0.3) :
                                          Color.white.opacity(0.05))
                            )
                    }
                }
            }
            .padding(.horizontal, 32)

            Text("Tap each word to reveal")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Progress bar
            HStack(spacing: 8) {
                ForEach(0..<rooms.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentRoom ? rooms[index].color : Color.white.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)

            // Navigation buttons
            HStack(spacing: 40) {
                Button(action: previousRoom) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(currentRoom > 0 ? .white : .white.opacity(0.3))
                }
                .disabled(currentRoom == 0)

                Button(action: nextRoom) {
                    HStack(spacing: 8) {
                        Text(currentRoom == rooms.count - 1 ? "Complete" : "Next")
                        Image(systemName: currentRoom == rooms.count - 1 ? "checkmark" : "chevron.right")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(rooms[currentRoom].color)
                    )
                }
            }
        }
        .padding(.bottom, 40)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Trophy
            ZStack {
                Circle()
                    .fill(Color(hex: "f59e0b").opacity(0.2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(1 + floatPhase * 0.1)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: "f59e0b"))
            }

            VStack(spacing: 12) {
                Text("Memory Anchored!")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text("You've walked through all 5 rooms")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Full verse
            VStack(spacing: 16) {
                Text("\u{201C}\(verse)\u{201D}")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)

                Text(reference)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "f59e0b"))
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 24)

            Spacer()

            // Actions
            HStack(spacing: 24) {
                Button(action: restart) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Walk Again")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                }

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color(hex: "f59e0b"))
                        )
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func previousRoom() {
        guard currentRoom > 0 else { return }
        withAnimation(.spring(duration: 0.5)) {
            currentRoom -= 1
            showingVerse = false
            revealedWords = []
        }
    }

    private func nextRoom() {
        if currentRoom < rooms.count - 1 {
            withAnimation(.spring(duration: 0.5)) {
                currentRoom += 1
                showingVerse = false
                revealedWords = []
            }
        } else {
            withAnimation(.spring(duration: 0.6)) {
                isComplete = true
            }
        }
    }

    private func checkCompletion() {
        let words = rooms[currentRoom].phrase.split(separator: " ")
        if revealedWords.count == words.count {
            // Auto-advance after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                nextRoom()
            }
        }
    }

    private func restart() {
        withAnimation(.spring(duration: 0.5)) {
            currentRoom = 0
            showingVerse = false
            revealedWords = []
            isComplete = false
        }
    }
}

// MARK: - POC Room Model (distinct from shared PalaceRoom)

private struct POCRoom {
    let name: String
    let icon: String
    let color: Color
    let phrase: String
    let visualCue: String
    let ambientColor: Color
}

// MARK: - Flow Layout (POC-local copy)

private struct POCFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX)
            }

            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    MemoryPalacePOC()
}
