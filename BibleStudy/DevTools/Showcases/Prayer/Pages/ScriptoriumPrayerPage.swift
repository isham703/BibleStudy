// ScriptoriumPrayerPage.swift
// BibleStudy
//
// "The Scriptorium" - Scholarly Reflection
// AI-powered prayer generation with Stoic-Roman aesthetic
// Warm typography, drop caps, and contemplative pacing

import SwiftUI

// MARK: - Scriptorium Prayer Page

struct ScriptoriumPrayerPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var flowState = ScriptoriumFlowState()
    @State private var isAwakened = false
    @State private var illuminationPhase: CGFloat = 0

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch flowState.phase {
                    case .input:
                        ScriptoriumInputPhase(
                            flowState: flowState,
                            isAwakened: isAwakened,
                            illuminationPhase: illuminationPhase
                        )
                    case .generating:
                        ScriptoriumGeneratingPhase(
                            flowState: flowState,
                            illuminationPhase: illuminationPhase
                        )
                    case .displaying:
                        ScriptoriumDisplayPhase(flowState: flowState)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("THE SCRIPTORIUM")
                    .font(Typography.Editorial.sectionHeader)
                    .tracking(Typography.Editorial.sectionTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                illuminationPhase = 1
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Parchment-like warm gradient
            RadialGradient(
                colors: [
                    Color("HighlightAmber").opacity(Theme.Opacity.subtle),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Secondary warm glow
            RadialGradient(
                colors: [
                    Color("AccentBronze").opacity(Theme.Opacity.subtle / 2),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Flow State

@Observable
final class ScriptoriumFlowState {
    var phase: ScriptoriumPhase = .input
    var intentionText: String = ""
    var selectedMood: PrayerMood = .peace
    var generatedPrayer: ScriptoriumPrayer?

    func beginGeneration() {
        phase = .generating
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.generatedPrayer = ScriptoriumPrayer(
                content: "Gracious Father, in this hour of uncertainty, I bring before You the anxieties that trouble my spirit. You who numbered the stars and called them each by name, You who know the sparrow's fall—surely You see my small struggles and hear my quiet pleas. Grant me the wisdom to discern Your path, the courage to walk in faith when the way is dark, and the patience to wait upon Your perfect timing. Let Your peace, which guards the hearts of those who trust in You, settle over my troubled thoughts like morning dew upon the meadow.",
                amen: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
                mood: self.selectedMood,
                scripture: "Philippians 4:6-7"
            )
            self.phase = .displaying
        }
    }

    func reset() {
        withAnimation(Theme.Animation.fade) {
            phase = .input
            intentionText = ""
            generatedPrayer = nil
        }
    }
}

enum ScriptoriumPhase {
    case input
    case generating
    case displaying
}

enum PrayerMood: String, CaseIterable, Identifiable {
    case peace = "Peace"
    case guidance = "Guidance"
    case gratitude = "Gratitude"
    case strength = "Strength"
    case healing = "Healing"
    case confession = "Confession"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .peace: return "leaf.fill"
        case .guidance: return "star.fill"
        case .gratitude: return "heart.fill"
        case .strength: return "flame.fill"
        case .healing: return "cross.fill"
        case .confession: return "arrow.uturn.backward"
        }
    }

    var prompt: String {
        switch self {
        case .peace: return "What steals your peace?"
        case .guidance: return "Where do you need direction?"
        case .gratitude: return "What fills your heart with thanks?"
        case .strength: return "What battle do you face?"
        case .healing: return "What wound needs tending?"
        case .confession: return "What burden do you carry?"
        }
    }
}

struct ScriptoriumPrayer {
    let content: String
    let amen: String
    let mood: PrayerMood
    let scripture: String
}

// MARK: - Input Phase

private struct ScriptoriumInputPhase: View {
    @Bindable var flowState: ScriptoriumFlowState
    let isAwakened: Bool
    let illuminationPhase: CGFloat
    @FocusState private var isTextFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Illuminated header
            illuminatedHeader
                .padding(.top, Theme.Spacing.xxl)

            // Mood selection
            moodSection

            // Intention input with manuscript styling
            intentionSection

            // Generate button
            generateButton
        }
    }

    private var illuminatedHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Illuminated P initial
            ZStack {
                // Glow
                Text("P")
                    .font(Typography.Decorative.dropCap)
                    .foregroundStyle(Color("HighlightAmber").opacity(0.3 + illuminationPhase * 0.2))
                    .blur(radius: 15)

                // Main letter
                Text("P")
                    .font(Typography.Decorative.dropCap)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("HighlightAmber"),
                                Color("AccentBronze")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            Text("rayerful Reflection")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)

            Text("The scribes write. The Spirit speaks.")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .italic()
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Manuscript flourish
            manuscriptFlourish
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
        }
    }

    private var manuscriptFlourish: some View {
        HStack(spacing: Theme.Spacing.sm) {
            flourishLine
            Image(systemName: "leaf.fill")
                .font(Typography.Icon.xxs.weight(.ultraLight))
                .foregroundStyle(Color("HighlightAmber").opacity(Theme.Opacity.textTertiary))
                .rotationEffect(.degrees(-45))
            flourishLine
        }
    }

    private var flourishLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color("HighlightAmber").opacity(Theme.Opacity.textTertiary),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: Theme.Spacing.xxl * 1.5, height: Theme.Stroke.hairline)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("WHAT STIRS YOUR SOUL?")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach(PrayerMood.allCases) { mood in
                    MoodCard(
                        mood: mood,
                        isSelected: flowState.selectedMood == mood,
                        action: {
                            withAnimation(Theme.Animation.fade) {
                                flowState.selectedMood = mood
                            }
                        }
                    )
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(flowState.selectedMood.prompt.uppercased())
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            VStack(alignment: .leading, spacing: 0) {
                TextEditor(text: $flowState.intentionText)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .focused($isTextFocused)

                // Ruled lines for manuscript effect
                VStack(spacing: Typography.Scripture.bodyLineSpacing + 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .fill(Color("HighlightAmber").opacity(Theme.Opacity.subtle))
                            .frame(height: Theme.Stroke.hairline)
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("HighlightAmber").opacity(Theme.Opacity.divider),
                                Color.appDivider
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
    }

    private var generateButton: some View {
        Button {
            flowState.beginGeneration()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "pencil.and.scribble")
                    .font(Typography.Icon.sm)
                Text("Inscribe My Prayer")
                    .font(Typography.Command.cta)
            }
            .foregroundStyle(Color("AppBackground"))
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color("HighlightAmber"), Color("AccentBronze")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .disabled(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.Opacity.disabled : 1)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }
}

// MARK: - Mood Card

private struct MoodCard: View {
    let mood: PrayerMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: mood.icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(isSelected ? Color("HighlightAmber") : Color("AppTextSecondary"))

                Text(mood.rawValue)
                    .font(Typography.Command.label)
                    .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(isSelected ? Color.appSurface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(
                        isSelected ? Color("HighlightAmber").opacity(Theme.Opacity.textTertiary) : Color.appDivider,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generating Phase

private struct ScriptoriumGeneratingPhase: View {
    @Bindable var flowState: ScriptoriumFlowState
    let illuminationPhase: CGFloat
    @State private var quillOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
                .frame(height: 80)

            // Animated illuminated letter
            ZStack {
                // Outer glow
                Text("P")
                    .font(Typography.Decorative.dropCap)
                    .foregroundStyle(Color("HighlightAmber").opacity(0.2 + illuminationPhase * 0.3))
                    .blur(radius: 25)

                // Main letter
                Text("P")
                    .font(Typography.Decorative.dropCap)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("HighlightAmber"),
                                Color("AccentBronze")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Quill writing animation
                Image(systemName: "pencil.tip")
                    .font(.system(size: 20))
                    .foregroundStyle(Color("AccentBronze"))
                    .offset(x: 30 + quillOffset, y: 20 - quillOffset)
            }

            VStack(spacing: Theme.Spacing.md) {
                Text("The scribe writes...")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: flowState.selectedMood.icon)
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("HighlightAmber"))

                    Text("A prayer of " + flowState.selectedMood.rawValue.lowercased())
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                quillOffset = 5
            }
        }
    }
}

// MARK: - Display Phase

private struct ScriptoriumDisplayPhase: View {
    @Bindable var flowState: ScriptoriumFlowState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Prayer manuscript
            if let prayer = flowState.generatedPrayer {
                manuscriptCard(prayer)
                    .padding(.top, Theme.Spacing.xl)
            }

            // Scripture reference
            if let prayer = flowState.generatedPrayer {
                scriptureReference(prayer.scripture)
            }

            // Actions
            actionButtons

            // New prayer
            newPrayerButton
        }
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isRevealed = true
            }
        }
    }

    private func manuscriptCard(_ prayer: ScriptoriumPrayer) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Mood badge
            HStack {
                Image(systemName: prayer.mood.icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("HighlightAmber"))

                Text("A Prayer of " + prayer.mood.rawValue)
                    .font(Typography.Editorial.label)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()
            }

            // Drop cap + prayer content
            HStack(alignment: .top, spacing: 0) {
                Text(String(prayer.content.prefix(1)))
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("HighlightAmber"), Color("AccentBronze")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 50, alignment: .leading)
                    .offset(y: -8)

                Text(String(prayer.content.dropFirst()))
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
            }

            // Amen with flourish
            HStack {
                flourishLine
                Text(prayer.amen)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .italic()
                flourishLine
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("HighlightAmber").opacity(colorScheme == .dark ? 0.4 : 0.25),
                            Color.appDivider
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 20)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isRevealed)
    }

    private var flourishLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color("HighlightAmber").opacity(Theme.Opacity.textTertiary),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: Theme.Spacing.lg, height: Theme.Stroke.hairline)
    }

    private func scriptureReference(_ reference: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "book.closed.fill")
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("HighlightAmber"))

            Text("Anchored to \(reference)")
                .font(Typography.Command.meta)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Capsule()
                .fill(Color.appSurface)
        )
        .overlay(
            Capsule()
                .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
        )
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isRevealed)
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ScriptoriumActionButton(icon: "doc.on.doc", label: "Copy") { }
            ScriptoriumActionButton(icon: "square.and.arrow.up", label: "Share") { }
            ScriptoriumActionButton(icon: "bookmark", label: "Save") { }
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isRevealed)
    }

    private var newPrayerButton: some View {
        Button {
            flowState.reset()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(Typography.Icon.sm)
                Text("Begin Anew")
                    .font(Typography.Command.label)
            }
            .foregroundStyle(Color("HighlightAmber"))
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .stroke(Color("HighlightAmber").opacity(Theme.Opacity.textTertiary), lineWidth: Theme.Stroke.hairline)
            )
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isRevealed)
    }
}

// MARK: - Action Button

private struct ScriptoriumActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color.appSurface)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                        )

                    Image(systemName: icon)
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ScriptoriumPrayerPage()
    }
}
