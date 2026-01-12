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
                            .padding(.bottom, Theme.Spacing.xxl * 2)
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
            withAnimation(Theme.Animation.slowFade) {
                isVisible = true
            }
            withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: true)) {
                breathePhase = 1
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
            Color("AppBackground")

            // Subtle accent gradient
            RadialGradient(
                colors: [
                    Color("AppAccentAction").opacity(Theme.Opacity.subtle),
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
                    .foregroundStyle(.white.opacity(Theme.Opacity.textSecondary))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.xs) {
                Text("COMPLINE")
                    .font(Typography.Editorial.label)
                    .tracking(Typography.Editorial.labelTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(Color("AppAccentAction").opacity(0.2))

                Text("Night Prayer")
                    .font(Typography.Command.caption)
                    .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
            }

            Spacer()

            // Time
            Text(timeString)
                .font(Typography.Command.meta.weight(.medium).monospaced())
                .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.xxl + Theme.Spacing.sm)
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
                          Color("AppAccentAction").opacity(0.2) :
                          Color.white.opacity(Theme.Opacity.selectionBackground))
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

        return VStack(spacing: Theme.Spacing.xxl + Theme.Spacing.xs) {
            // Section icon
            ZStack {
                Circle()
                    .fill(Color("AppAccentAction").opacity(0.2).opacity(Theme.Opacity.subtle))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + breathePhase * 0.05)

                Image(systemName: section.icon)
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(Color("AppAccentAction").opacity(0.2))
            }
            .padding(.top, Theme.Spacing.xl + Theme.Spacing.sm)

            // Title and instruction
            VStack(spacing: Theme.Spacing.md) {
                Text(section.title)
                    .font(Typography.Scripture.title)
                    .foregroundStyle(.white)

                Text(section.instruction)
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(.white.opacity(Theme.Opacity.textSecondary))
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
            .padding(.vertical, Theme.Spacing.lg)
    }

    private func scriptureView(_ content: String) -> some View {
        Text(content)
            .font(Typography.Scripture.body)
            .foregroundStyle(.white.opacity(Theme.Opacity.textPrimary))
            .multilineTextAlignment(.center)
            .lineSpacing(Typography.Scripture.bodyLineSpacing)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
    }

    private func examinationView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            if let content = section.content {
                Text(content)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
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
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppAccentAction").opacity(0.2))
                }

                if showingReflection {
                    TextEditor(text: $reflectionText)
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                // swiftlint:disable:next hardcoded_opacity
                                .fill(Color.white.opacity(Theme.Opacity.subtle))
                        )
                        .focused($isReflectionFocused)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private func confessionView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xxl + Theme.Spacing.xs) {
            if let content = section.content {
                Text(content)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
            }
        }
    }

    private func blessingView(_ section: ComplineSection) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Simplified candle visualization (static, no animation)
            ZStack {
                // Subtle glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("FeedbackWarning").opacity(Theme.Opacity.disabled),
                                Color("FeedbackWarning").opacity(Theme.Opacity.subtle),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 80)
                    .offset(y: -40)

                // Flame
                Image(systemName: "flame.fill")
                    .font(Typography.Icon.xxl.weight(.regular))
                    .foregroundStyle(Color("FeedbackWarning"))
                    .offset(y: -20)

                // Candle base
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color("AccentBronze").opacity(0.2))
                    .frame(width: 20, height: 50)
                    .offset(y: 25)
            }
            .frame(height: 100)
        }
    }

    private func responseView(_ response: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Rectangle()
                .fill(Color("AppAccentAction").opacity(0.2).opacity(Theme.Opacity.selectionBackground))
                .frame(width: 40, height: Theme.Stroke.hairline)

            Text(response)
                .font(Typography.Scripture.body.weight(.semibold))
                .foregroundStyle(Color("AppAccentAction").opacity(0.2))
                .multilineTextAlignment(.center)
                .lineSpacing(Typography.Scripture.bodyLineSpacing)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: Theme.Spacing.xl + Theme.Spacing.sm) {
            Button(action: previousSection) {
                Image(systemName: "chevron.left")
                    .font(Typography.Icon.lg.weight(.medium))
                    .foregroundStyle(currentSection > 0 ? .white : .white.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            // swiftlint:disable:next hardcoded_opacity
                            .fill(Color.white.opacity(Theme.Opacity.subtle))
                    )
            }
            .disabled(currentSection == 0)

            Button(action: nextSection) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(currentSection == sections.count - 1 ? "Amen" : "Continue")
                    Image(systemName: currentSection == sections.count - 1 ? "moon.stars.fill" : "chevron.right")
                }
                .font(Typography.Command.label)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xxl + Theme.Spacing.xs)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                        .overlay(
                            Capsule()
                                .stroke(Color("AppAccentAction").opacity(Theme.Opacity.focusStroke), lineWidth: Theme.Stroke.hairline)
                        )
                )
            }
        }
        .padding(.bottom, Theme.Spacing.xl + Theme.Spacing.sm)
        .background(
            LinearGradient(
                colors: [Color.clear, Color("AppBackground")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: -50)
        )
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Theme.Spacing.xl + Theme.Spacing.sm) {
            Spacer()

            // Moon icon (simplified, no star field)
            Image(systemName: "moon.stars.fill")
                .font(Typography.Icon.display)
                .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))

            VStack(spacing: Theme.Spacing.lg) {
                Text("Rest now in peace")
                    .font(Typography.Scripture.title)
                    .foregroundStyle(.white)

                Text("The prayer of Compline is complete.\nMay you sleep in God's protection.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
            }

            // Final blessing
            VStack(spacing: Theme.Spacing.md) {
                Text("May the Lord bless you and keep you.")
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(Color("AppAccentAction").opacity(0.2))

                Text("Numbers 6:24")
                    .font(Typography.Editorial.label)
                    .tracking(Typography.Editorial.labelTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(Theme.Opacity.disabled))
            }
            .padding(.vertical, Theme.Spacing.xl)
            .padding(.horizontal, Theme.Spacing.xxl + Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    // swiftlint:disable:next hardcoded_opacity
                    .fill(Color.white.opacity(Theme.Opacity.subtle))
            )

            Spacer()

            Button(action: { dismiss() }) {
                Text("Good Night")
                    .font(Typography.Command.label)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(
                        Capsule()
                            .fill(Color("AppAccentAction").opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(Color("AppAccentAction").opacity(0.2).opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
                            )
                    )
            }
            .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.sm)
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
