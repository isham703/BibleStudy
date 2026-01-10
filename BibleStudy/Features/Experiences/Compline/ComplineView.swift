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
                            // swiftlint:disable:next hardcoded_padding_edge
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
            // swiftlint:disable:next hardcoded_animation_ease hardcoded_with_animation
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
            // swiftlint:disable:next hardcoded_animation_ease hardcoded_with_animation
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            // swiftlint:disable:next hardcoded_animation_ease hardcoded_with_animation
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
            Color.complineVoid

            // Stars
            GeometryReader { geo in
                ForEach(0..<30, id: \.self) { i in
                    Circle()
                        // swiftlint:disable:next hardcoded_opacity
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.5)
                        )
                        // swiftlint:disable:next hardcoded_blur_radius
                        .blur(radius: 0.5)
                        .opacity(Theme.Opacity.medium + breathePhase * Theme.Opacity.medium)
                }
            }

            // Candlelight glow at bottom
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        // swiftlint:disable:next hardcoded_opacity
                        Color.amberOrange.opacity(0.08 + candleFlicker * 0.04),
                        // swiftlint:disable:next hardcoded_opacity
                        Color.amberOrange.opacity(Theme.Opacity.faint),
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
                    Color.indigoTint.opacity(Theme.Opacity.subtle),
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
                    .font(Typography.Icon.md.weight(.medium))
                    .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.xs) {
                Text("COMPLINE")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Color.indigoTint)

                Text("Night Prayer")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
            }

            Spacer()

            // Time
            Text(timeString)
                .font(Typography.Command.meta.weight(.medium).monospaced())
                .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        // swiftlint:disable:next hardcoded_padding_edge
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
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<sections.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentSection ?
                          Color.indigoTint :
                          Color.white.opacity(Theme.Opacity.lightMedium))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, Theme.Spacing.xl)
        .opacity(isVisible ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isVisible)
    }

    // MARK: - Current Section View

    private var currentSectionView: some View {
        let section = sections[currentSection]

        return VStack(spacing: Theme.Spacing.xxl + 8) {
            // Section icon
            ZStack {
                Circle()
                    .fill(Color.indigoTint.opacity(Theme.Opacity.subtle))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + breathePhase * 0.05)

                Image(systemName: section.icon)
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(Color.indigoTint)
            }
            // swiftlint:disable:next hardcoded_padding_edge
            .padding(.top, 40)

            // Title and instruction
            VStack(spacing: Theme.Spacing.md) {
                Text(section.title)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                Text(section.instruction)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
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
        .padding(.horizontal, Theme.Spacing.xl)
        .id(currentSection)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 20)),
            removal: .opacity
        ))
    }

    // MARK: - Section Views

    private var breathingExercise: some View {
        ComplineBreathePhase()
            .padding(.vertical, Theme.Spacing.lg + 4)
    }

    private func scriptureView(_ content: String) -> some View {
        Text(content)
            // swiftlint:disable:next hardcoded_font_custom
            .font(.system(size: 18, weight: .regular, design: .serif))
            .foregroundStyle(.white.opacity(Theme.Opacity.high))
            .multilineTextAlignment(.center)
            // swiftlint:disable:next hardcoded_line_spacing
            .lineSpacing(10)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
    }

    private func examinationView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            if let content = section.content {
                Text(content)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(12)
            }

            // Reflection input
            VStack(spacing: Theme.Spacing.md) {
                Button(action: {
                    // swiftlint:disable:next hardcoded_animation_spring
                    withAnimation(Theme.Animation.settle) {
                        showingReflection.toggle()
                    }
                }) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: showingReflection ? "chevron.up" : "pencil")
                        Text(showingReflection ? "Close" : "Write a reflection")
                    }
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.indigoTint)
                }

                if showingReflection {
                    TextEditor(text: $reflectionText)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                // swiftlint:disable:next hardcoded_opacity
                                .fill(Color.white.opacity(Theme.Opacity.faint))
                        )
                        .focused($isReflectionFocused)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private func confessionView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xxl + 8) {
            if let content = section.content {
                Text(content)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(8)
            }
        }
    }

    private func blessingView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Candle visualization
            ZStack {
                // Flame glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.amberOrange.opacity(Theme.Opacity.disabled),
                                Color.amberOrange.opacity(Theme.Opacity.subtle),
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
                    .font(Typography.Icon.xxl.weight(.regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellowAmber, Color.amberOrange, Color.candleOrange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -20 + candleFlicker * 2)

                // Candle base
                // swiftlint:disable:next hardcoded_rounded_rectangle
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.creamWarm)
                    .frame(width: 20, height: 50)
                    .offset(y: 25)
            }
            .frame(height: 100)
        }
    }

    private func responseView(_ response: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Rectangle()
                .fill(Color.indigoTint.opacity(Theme.Opacity.lightMedium))
                .frame(width: 40, height: Theme.Stroke.hairline)

            Text(response)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Color.indigoTint)
                .multilineTextAlignment(.center)
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(8)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        HStack(spacing: 40) {
            Button(action: previousSection) {
                Image(systemName: "chevron.left")
                    .font(Typography.Icon.lg.weight(.medium))
                    .foregroundStyle(currentSection > 0 ? .white : .white.opacity(Theme.Opacity.lightMedium))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            // swiftlint:disable:next hardcoded_opacity
                            .fill(Color.white.opacity(Theme.Opacity.faint))
                    )
            }
            .disabled(currentSection == 0)

            Button(action: nextSection) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(currentSection == sections.count - 1 ? "Amen" : "Continue")
                    Image(systemName: currentSection == sections.count - 1 ? "moon.stars.fill" : "chevron.right")
                }
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xxl + 8)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    Capsule()
                        .fill(Color.accentIndigoLight.opacity(Theme.Opacity.heavy))
                        .overlay(
                            Capsule()
                                .stroke(Color.indigoTint.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        )
                )
            }
        }
        // swiftlint:disable:next hardcoded_padding_edge
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.complineVoid],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: -50)
        )
    }

    // MARK: - Completion View

    private var completionView: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 40) {
            Spacer()

            // Moon and stars
            ZStack {
                // Star field
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "star.fill")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(.system(size: CGFloat.random(in: 8...16)))
                        .foregroundStyle(Color.indigoTint.opacity(Theme.Opacity.heavy))
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
                                Color.textIvory,
                                Color.indigoTint,
                                Color.moonGlow
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.indigoTint.opacity(Theme.Opacity.medium), radius: 30)
            }

            VStack(spacing: Theme.Spacing.lg) {
                Text("Rest now in peace")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                Text("The prayer of Compline is complete.\nMay you sleep in God's protection.")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(Theme.Opacity.strong))
                    .multilineTextAlignment(.center)
            }

            // Final blessing
            VStack(spacing: Theme.Spacing.md) {
                Text("May the Lord bless you and keep you.")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(Color.indigoTint)
                    .italic()

                Text("Numbers 6:24")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
            }
            .padding(.vertical, Theme.Spacing.xl)
            .padding(.horizontal, Theme.Spacing.xxl + 8)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    // swiftlint:disable:next hardcoded_opacity
                    .fill(Color.white.opacity(Theme.Opacity.faint))
            )

            Spacer()

            Button(action: { dismiss() }) {
                Text("Good Night")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.horizontal, 48)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(
                        Capsule()
                            .fill(Color.indigoBackground)
                            .overlay(
                                Capsule()
                                    .stroke(Color.indigoTint.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
                            )
                    )
            }
            // swiftlint:disable:next hardcoded_padding_edge
            .padding(.bottom, 60)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Actions

    private func previousSection() {
        guard currentSection > 0 else { return }
        isReflectionFocused = false
        // swiftlint:disable:next hardcoded_animation_spring
        withAnimation(Theme.Animation.settle) {
            currentSection -= 1
        }
    }

    private func nextSection() {
        isReflectionFocused = false
        if currentSection < sections.count - 1 {
            // swiftlint:disable:next hardcoded_animation_spring
            withAnimation(Theme.Animation.settle) {
                currentSection += 1
            }
        } else {
            // swiftlint:disable:next hardcoded_animation_spring
            withAnimation(Theme.Animation.settle) {
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
