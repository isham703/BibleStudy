//
//  ModernLuminousPage.swift
//  BibleStudy
//
//  Style B: Clean, elevated design with subtle gradients, floating elements, and focused AI interaction
//  Uses Scholar Indigo as primary accent with modern glass morphism effects
//

import SwiftUI

struct ModernLuminousPage: View {
    @State private var prayerIntent: String = ""
    @State private var selectedMood: PrayerMood = .peaceful
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showResult = false
    @State private var pulseAnimation = false
    @FocusState private var isInputFocused: Bool

    enum PrayerMood: String, CaseIterable {
        case grateful = "Grateful"
        case peaceful = "Peaceful"
        case seeking = "Seeking"
        case hopeful = "Hopeful"
        case surrendered = "Surrendered"

        var emoji: String {
            switch self {
            case .grateful: return "🙏"
            case .peaceful: return "🕊️"
            case .seeking: return "🔍"
            case .hopeful: return "✨"
            case .surrendered: return "🤲"
            }
        }

        var gradient: [Color] {
            switch self {
            case .grateful: return [Color(hex: "F472B6"), Color(hex: "DB2777")]
            case .peaceful: return [Color.skyBlue, Color(hex: "2563EB")]
            case .seeking: return [Color.yellowAmber, Color(hex: "D97706")]
            case .hopeful: return [Color.emeraldGreen, Color(hex: "059669")]
            case .surrendered: return [Color(hex: "A78BFA"), Color(hex: "7C3AED")]
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    aiAssistantSection
                    moodSelectionSection
                    intentInputSection

                    if showResult {
                        resultSection
                    }

                    Spacer(minLength: 120)
                }
            }

            // Generate FAB
            VStack {
                Spacer()
                generateButton
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0F0F12"),
                    Color(hex: "1A1A24"),
                    Color(hex: "0F0F12")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Floating orbs
            GeometryReader { geo in
                ZStack {
                    // Top right orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentIndigo.opacity(Theme.Opacity.divider),
                                    Color.accentIndigo.opacity(Theme.Opacity.faint),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: geo.size.width * 0.3, y: -100)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)

                    // Bottom left orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentIndigoLight.opacity(Theme.Opacity.overlay),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: -geo.size.width * 0.4, y: geo.size.height * 0.6)
                        .scaleEffect(pulseAnimation ? 0.9 : 1.1)
                }
            }

            // Noise texture
            Rectangle()
                .fill(Color.white.opacity(Theme.Opacity.faint))
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)

            // Floating badge
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.emeraldGreen)
                    .frame(width: 6, height: 6)
                Text("AI-Powered")
                    .font(Typography.Command.meta.weight(.semibold))
                    .foregroundColor(Color.stoneGray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(Theme.Opacity.overlay), lineWidth: 1)
                    )
            )

            // Title
            Text("Create Your Prayer")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Subtitle
            Text("Let AI help you articulate what's in your heart")
                .font(Typography.Command.callout)
                .foregroundColor(Color.stoneGray)
        }
        .padding(.bottom, 32)
    }

    // MARK: - AI Assistant Section

    private var aiAssistantSection: some View {
        HStack(spacing: 16) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentIndigo, Color.accentIndigoLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "sparkles")
                    .font(Typography.Command.title3)
                    .foregroundColor(.white)
            }

            // Message bubble
            VStack(alignment: .leading, spacing: 4) {
                Text("Prayer Assistant")
                    .font(Typography.Icon.xs.weight(.semibold))
                    .foregroundColor(Color.accentIndigo)

                Text("I'll help transform your thoughts and feelings into a meaningful prayer. Share what's on your heart.")
                    .font(Typography.Command.caption)
                    .foregroundColor(Color.decorativeMarble)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    // MARK: - Mood Selection

    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label
            Text("How are you feeling?")
                .font(Typography.Icon.sm)
                .foregroundColor(Color.stoneGray)
                .padding(.horizontal, 24)

            // Mood pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PrayerMood.allCases, id: \.self) { mood in
                        MoodPill(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            action: {
                                withAnimation(Theme.Animation.settle) {
                                    selectedMood = mood
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Intent Input Section

    private var intentInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label
            Text("What would you like to pray about?")
                .font(Typography.Icon.sm)
                .foregroundColor(Color.stoneGray)

            // Input field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.xl)
                            .stroke(
                                isInputFocused
                                    ? LinearGradient(
                                        colors: [Color.accentIndigo.opacity(Theme.Opacity.medium), Color.accentIndigoLight.opacity(Theme.Opacity.subtle)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(Theme.Opacity.overlay), Color.white.opacity(Theme.Opacity.faint)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: 1
                            )
                    )

                TextEditor(text: $prayerIntent)
                    .font(Typography.Command.callout)
                    .foregroundColor(Color.decorativeMarble)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .padding(20)
                    .frame(minHeight: 160)

                if prayerIntent.isEmpty {
                    Text("Example: I'm struggling with anxiety about my job situation and need guidance...")
                        .font(Typography.Command.callout)
                        .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.medium))
                        .padding(24)
                        .allowsHitTesting(false)
                }
            }

            // Suggestion chips
            HStack(spacing: 8) {
                SuggestionChip(text: "Family") { prayerIntent += " my family" }
                SuggestionChip(text: "Health") { prayerIntent += " health concerns" }
                SuggestionChip(text: "Decisions") { prayerIntent += " a big decision" }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: 20) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.accentIndigo.opacity(Theme.Opacity.subtle), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
                .padding(.top, 20)

            // Result label
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.emeraldGreen)
                Text("Prayer Generated")
                    .font(Typography.Command.meta.weight(.semibold))
                    .foregroundColor(Color.emeraldGreen)
            }

            // Prayer card
            VStack(alignment: .leading, spacing: 16) {
                Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                    .font(Typography.Scripture.body)
                    .foregroundColor(Color.decorativeMarble)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)

                // Footer
                HStack {
                    Label("Inspired by Philippians 4:6-7", systemImage: "book.closed")
                        .font(Typography.Command.caption)
                        .foregroundColor(Color.accentIndigo)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 12) {
                        IconActionButton(icon: "doc.on.doc") {}
                        IconActionButton(icon: "square.and.arrow.up") {}
                        IconActionButton(icon: "heart") {}
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentIndigo.opacity(Theme.Opacity.overlay), Color.accentIndigoLight.opacity(Theme.Opacity.faint)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                            .stroke(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: {
            withAnimation(Theme.Animation.settle) {
                isGenerating = true
            }
            // Simulate AI generation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(Theme.Animation.settle) {
                    isGenerating = false
                    showResult = true
                }
            }
        }) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(Typography.Icon.base.weight(.semibold))
                }

                Text(isGenerating ? "Creating..." : "Generate Prayer")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.accentIndigo, Color.accentIndigoLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .shadow(color: Color.accentIndigo.opacity(Theme.Opacity.lightMedium), radius: 20, x: 0, y: 10)
        }
        .disabled(isGenerating)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var samplePrayer: String {
        """
        Heavenly Father, in this moment of stillness I bring my anxious thoughts to You. You know the weight I carry about my work situation, the uncertainty that clouds my mind.

        I surrender these worries into Your capable hands. Help me trust in Your timing and Your plan, even when the path ahead seems unclear. Fill me with Your peace that transcends all understanding.

        Guide my decisions and open doors according to Your will. Give me wisdom to recognize Your leading and courage to follow where You direct.

        In Jesus' name, Amen.
        """
    }
}

// MARK: - Mood Pill

struct MoodPill: View {
    let mood: ModernLuminousPage.PrayerMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(mood.emoji)
                    .font(Typography.Command.caption)
                Text(mood.rawValue)
                    .font(Typography.Command.meta)
            }
            .foregroundColor(isSelected ? .white : Color.stoneGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: mood.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(Theme.Opacity.faint), Color.white.opacity(Theme.Opacity.faint)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.clear : Color.white.opacity(Theme.Opacity.overlay),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(Typography.Icon.xxs.weight(.bold))
                Text(text)
                    .font(Typography.Icon.xs)
            }
            .foregroundColor(Color.accentIndigo)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.overlay))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Action Button

struct IconActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.Command.callout)
                .foregroundColor(Color.stoneGray)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(Theme.Opacity.faint))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ModernLuminousPage()
}
