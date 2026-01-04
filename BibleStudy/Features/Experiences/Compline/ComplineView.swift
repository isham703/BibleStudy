import SwiftUI

// MARK: - Compline POC
// AI-led evening prayer experience
// Aesthetic: Nocturnal, contemplative, candlelit serenity

struct ComplineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var isVisible = false
    @State private var currentSection = 0
    @State private var breathePhase: CGFloat = 0
    @State private var candleFlicker: CGFloat = 0
    @State private var showingReflection = false
    @State private var reflectionText = ""
    @State private var isComplete = false
    @FocusState private var isReflectionFocused: Bool

    private let sections: [ComplineSection] = [
        ComplineSection(
            type: .opening,
            title: "The Opening",
            instruction: "Begin by taking three slow breaths",
            content: nil,
            response: "O God, come to my assistance.\nO Lord, make haste to help me.",
            icon: "moon.stars.fill"
        ),
        ComplineSection(
            type: .psalm,
            title: "Psalm 91",
            instruction: "Let these words settle into your heart",
            content: """
            You who dwell in the shelter of the Most High,
            who abide in the shadow of the Almighty,
            say to the Lord, "My refuge and fortress,
            my God in whom I trust."

            He will shelter you with his pinions,
            and under his wings you may take refuge.
            """,
            response: nil,
            icon: "book.fill"
        ),
        ComplineSection(
            type: .examination,
            title: "Examination",
            instruction: "Review your day with gentle honesty",
            content: """
            Where did you notice God's presence today?

            Where did you resist grace?

            What are you grateful for?
            """,
            response: nil,
            icon: "eye.fill"
        ),
        ComplineSection(
            type: .confession,
            title: "Confession",
            instruction: "Release what burdens you",
            content: "I confess to almighty God,\nand to you, my brothers and sisters,\nthat I have sinned\nthrough my own fault,\nin my thoughts and in my words,\nin what I have done,\nand in what I have failed to do.",
            response: "May almighty God have mercy on you,\nforgive you your sins,\nand bring you to everlasting life.",
            icon: "heart.fill"
        ),
        ComplineSection(
            type: .canticle,
            title: "Nunc Dimittis",
            instruction: "The Song of Simeon",
            content: """
            Lord, now you let your servant go in peace;
            your word has been fulfilled.

            My own eyes have seen the salvation
            which you have prepared
            in the sight of every people:

            A light to reveal you to the nations
            and the glory of your people Israel.
            """,
            response: nil,
            icon: "sparkles"
        ),
        ComplineSection(
            type: .blessing,
            title: "Blessing",
            instruction: "Receive this blessing for the night",
            content: nil,
            response: "May the Lord Almighty grant you\na peaceful night\nand a perfect end.\n\nAmen.",
            icon: "hands.sparkles.fill"
        )
    ]

    var body: some View {
        ZStack {
            // Night sky background
            nightBackground

            VStack(spacing: 0) {
                // Header
                header

                if isComplete {
                    completionView
                } else {
                    // Progress
                    progressIndicator

                    // Content
                    ScrollView(showsIndicators: false) {
                        currentSectionView
                            .padding(.bottom, 100)
                    }

                    // Navigation
                    navigationControls
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .onAppear {
            appState.hideTabBar = true
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                candleFlicker = 1
            }
        }
        .onDisappear {
            appState.hideTabBar = false
        }
    }

    // MARK: - Background

    private var nightBackground: some View {
        ZStack {
            // Deep night blue
            Color(hex: "050510")

            // Stars
            GeometryReader { geo in
                ForEach(0..<30, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.5)
                        )
                        .blur(radius: 0.5)
                        .opacity(0.3 + breathePhase * 0.3)
                }
            }

            // Candlelight glow at bottom
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color(hex: "f59e0b").opacity(0.08 + candleFlicker * 0.04),
                        Color(hex: "f59e0b").opacity(0.02),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(height: 500)
            }

            // Moon glow
            RadialGradient(
                colors: [
                    Color(hex: "e0e7ff").opacity(0.1),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 200
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
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("COMPLINE")
                    .font(.custom("Cinzel-Regular", size: 10))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "e0e7ff"))

                Text("Night Prayer")
                    .font(.custom("CormorantGaramond-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Time
            Text(timeString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<sections.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentSection ?
                          Color(hex: "e0e7ff") :
                          Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, 24)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
    }

    // MARK: - Current Section View

    private var currentSectionView: some View {
        let section = sections[currentSection]

        return VStack(spacing: 32) {
            // Section icon
            ZStack {
                Circle()
                    .fill(Color(hex: "e0e7ff").opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + breathePhase * 0.05)

                Image(systemName: section.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "e0e7ff"))
            }
            .padding(.top, 40)

            // Title and instruction
            VStack(spacing: 12) {
                Text(section.title)
                    .font(.custom("Cinzel-Regular", size: 28))
                    .foregroundStyle(.white)

                Text(section.instruction)
                    .font(.custom("CormorantGaramond-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Content based on type
            switch section.type {
            case .opening:
                breathingExercise
            case .psalm, .canticle:
                if let content = section.content {
                    scriptureView(content)
                }
            case .examination:
                examinationView(section)
            case .confession:
                confessionView(section)
            case .blessing:
                blessingView(section)
            }

            // Response if available
            if let response = section.response {
                responseView(response)
            }
        }
        .padding(.horizontal, 24)
        .id(currentSection)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 20)),
            removal: .opacity
        ))
    }

    // MARK: - Section Views

    private var breathingExercise: some View {
        VStack(spacing: 24) {
            // Breathing circle
            ZStack {
                Circle()
                    .stroke(Color(hex: "e0e7ff").opacity(0.3), lineWidth: 2)
                    .frame(width: 150, height: 150)

                Circle()
                    .fill(Color(hex: "e0e7ff").opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(0.5 + breathePhase * 0.5)

                Text(breathePhase > 0.5 ? "Breathe out..." : "Breathe in...")
                    .font(.custom("CormorantGaramond-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(height: 160)

            Text("Match your breath to the circle")
                .font(.custom("CormorantGaramond-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 20)
    }

    private func scriptureView(_ content: String) -> some View {
        Text(content)
            .font(.custom("CormorantGaramond-Regular", size: 18))
            .foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(10)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }

    private func examinationView(_ section: ComplineSection) -> some View {
        VStack(spacing: 24) {
            if let content = section.content {
                Text(content)
                    .font(.custom("CormorantGaramond-Regular", size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
            }

            // Reflection input
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(duration: 0.4)) {
                        showingReflection.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showingReflection ? "chevron.up" : "pencil")
                        Text(showingReflection ? "Close" : "Write a reflection")
                    }
                    .font(.custom("CormorantGaramond-SemiBold", size: 14))
                    .foregroundStyle(Color(hex: "e0e7ff"))
                }

                if showingReflection {
                    TextEditor(text: $reflectionText)
                        .font(.custom("CormorantGaramond-Regular", size: 15))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        .focused($isReflectionFocused)
                }
            }
        }
        .padding(.vertical, 16)
    }

    private func confessionView(_ section: ComplineSection) -> some View {
        VStack(spacing: 32) {
            if let content = section.content {
                Text(content)
                    .font(.custom("CormorantGaramond-Regular", size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }
        }
    }

    private func blessingView(_ section: ComplineSection) -> some View {
        VStack(spacing: 24) {
            // Candle visualization
            ZStack {
                // Flame glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "f59e0b").opacity(0.4),
                                Color(hex: "f59e0b").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 80)
                    .offset(y: -40)
                    .scaleEffect(1 + candleFlicker * 0.1)

                // Flame
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "fbbf24"), Color(hex: "f59e0b"), Color(hex: "ea580c")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -20 + candleFlicker * 2)

                // Candle base
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "fef3c7"))
                    .frame(width: 20, height: 50)
                    .offset(y: 25)
            }
            .frame(height: 100)
        }
    }

    private func responseView(_ response: String) -> some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color(hex: "e0e7ff").opacity(0.2))
                .frame(width: 40, height: 1)

            Text(response)
                .font(.custom("CormorantGaramond-SemiBold", size: 16))
                .foregroundStyle(Color(hex: "e0e7ff"))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
        }
        .padding(.top, 24)
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 40) {
            Button(action: previousSection) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(currentSection > 0 ? .white : .white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            }
            .disabled(currentSection == 0)

            Button(action: nextSection) {
                HStack(spacing: 8) {
                    Text(currentSection == sections.count - 1 ? "Amen" : "Continue")
                    Image(systemName: currentSection == sections.count - 1 ? "moon.stars.fill" : "chevron.right")
                }
                .font(.custom("Cinzel-Regular", size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color(hex: "4f46e5").opacity(0.5))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "e0e7ff").opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: "050510")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: -50)
        )
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 40) {
            Spacer()

            // Moon and stars
            ZStack {
                // Star field
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat.random(in: 8...16)))
                        .foregroundStyle(Color(hex: "e0e7ff").opacity(0.5))
                        .offset(
                            x: CGFloat.random(in: -80...80),
                            y: CGFloat.random(in: -60...60)
                        )
                }

                // Moon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "f5f5f5"),
                                Color(hex: "e0e7ff"),
                                Color(hex: "c7d2fe")
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "e0e7ff").opacity(0.3), radius: 30)
            }

            VStack(spacing: 16) {
                Text("Rest now in peace")
                    .font(.custom("Cinzel-Regular", size: 28))
                    .foregroundStyle(.white)

                Text("The prayer of Compline is complete.\nMay you sleep in God's protection.")
                    .font(.custom("CormorantGaramond-Regular", size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Final blessing
            VStack(spacing: 12) {
                Text("May the Lord bless you and keep you.")
                    .font(.custom("CormorantGaramond-Regular", size: 17))
                    .foregroundStyle(Color(hex: "e0e7ff"))
                    .italic()

                Text("Numbers 6:24")
                    .font(.custom("Cinzel-Regular", size: 10))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )

            Spacer()

            Button(action: { dismiss() }) {
                Text("Good Night")
                    .font(.custom("Cinzel-Regular", size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color(hex: "1e1b4b"))
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "e0e7ff").opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func previousSection() {
        guard currentSection > 0 else { return }
        isReflectionFocused = false
        withAnimation(.spring(duration: 0.5)) {
            currentSection -= 1
        }
    }

    private func nextSection() {
        isReflectionFocused = false
        if currentSection < sections.count - 1 {
            withAnimation(.spring(duration: 0.5)) {
                currentSection += 1
            }
        } else {
            withAnimation(.spring(duration: 0.6)) {
                isComplete = true
            }
        }
    }
}

// MARK: - Compline Section Model

struct ComplineSection {
    let type: ComplineSectionType
    let title: String
    let instruction: String
    let content: String?
    let response: String?
    let icon: String
}

enum ComplineSectionType {
    case opening
    case psalm
    case examination
    case confession
    case canticle
    case blessing
}

// MARK: - Preview

#Preview {
    ComplineView()
        .environment(AppState())
}
