// CloisterPrayerPage.swift
// BibleStudy
//
// "The Cloister" - Monastic Discipline
// AI-powered prayer generation with structured, reverent flow
// Emphasizes silence, intention, and guided contemplation

import SwiftUI

// MARK: - Cloister Prayer Page

struct CloisterPrayerPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var flowState = CloisterFlowState()
    @State private var isAwakened = false

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch flowState.phase {
                    case .input:
                        CloisterInputPhase(flowState: flowState, isAwakened: isAwakened)
                    case .generating:
                        CloisterGeneratingPhase(flowState: flowState)
                    case .displaying:
                        CloisterDisplayPhase(flowState: flowState)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("THE CLOISTER")
                    .font(Typography.Editorial.sectionHeader)
                    .tracking(Typography.Editorial.sectionTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Subtle vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.subtle)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Top accent glow
            VStack {
                LinearGradient(
                    colors: [
                        Color("AccentBronze").opacity(Theme.Opacity.subtle / 2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Flow State

@Observable
final class CloisterFlowState {
    var phase: CloisterPhase = .input
    var intentionText: String = ""
    var selectedTradition: CloisterTradition = .general
    var generatedPrayer: CloisterGeneratedPrayer?

    func beginGeneration() {
        phase = .generating
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.generatedPrayer = CloisterGeneratedPrayer(
                content: "Almighty God, who sees the burdens I carry and knows the anxieties of my heart, grant me the peace that surpasses understanding. In this moment of uncertainty, steady my thoughts and calm my spirit. Help me to trust in Your providence, knowing that You work all things for the good of those who love You. Remove from me the weight of worry, and replace it with the lightness of faith. May I walk forward not in fear, but in confidence that You hold my future in Your hands.",
                amen: "Through Christ our Lord, Amen.",
                tradition: self.selectedTradition
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

enum CloisterPhase {
    case input
    case generating
    case displaying
}

enum CloisterTradition: String, CaseIterable, Identifiable {
    case general = "General"
    case contemplative = "Contemplative"
    case liturgical = "Liturgical"
    case scripture = "Scripture-Based"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "hands.clap"
        case .contemplative: return "leaf"
        case .liturgical: return "book.closed"
        case .scripture: return "text.book.closed"
        }
    }

    var description: String {
        switch self {
        case .general: return "Universal language"
        case .contemplative: return "Meditative silence"
        case .liturgical: return "Historic forms"
        case .scripture: return "Biblical phrases"
        }
    }
}

struct CloisterGeneratedPrayer {
    let content: String
    let amen: String
    let tradition: CloisterTradition
}

// MARK: - Input Phase

private struct CloisterInputPhase: View {
    @Bindable var flowState: CloisterFlowState
    let isAwakened: Bool
    @FocusState private var isTextFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Header
            headerSection
                .padding(.top, Theme.Spacing.xxl)

            // Tradition selection
            traditionSection

            // Intention input
            intentionSection

            // Generate button
            generateButton
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Cross icon
            Image(systemName: "cross")
                .font(Typography.Icon.xxl.weight(.ultraLight))
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            Text("Enter the Silence")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)

            Text("Share what weighs upon your heart")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Ornamental divider
            ornamentalDivider
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
        }
    }

    private var ornamentalDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color("AccentBronze").opacity(Theme.Opacity.textTertiary)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)

            Image(systemName: "sparkle")
                .font(Typography.Icon.xxs.weight(.light))
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color("AccentBronze").opacity(Theme.Opacity.textTertiary), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)
        }
    }

    private var traditionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("TRADITION")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(CloisterTradition.allCases) { tradition in
                        TraditionPill(
                            tradition: tradition,
                            isSelected: flowState.selectedTradition == tradition,
                            action: {
                                withAnimation(Theme.Animation.fade) {
                                    flowState.selectedTradition = tradition
                                }
                            }
                        )
                    }
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("YOUR INTENTION")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                TextEditor(text: $flowState.intentionText)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .focused($isTextFocused)

                if flowState.intentionText.isEmpty {
                    Text("What troubles you? What do you seek guidance for? What fills you with gratitude?")
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("TertiaryText"))
                        .allowsHitTesting(false)
                        .padding(.top, -132)
                        .padding(.leading, 4)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
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
                Image(systemName: "sparkles")
                    .font(Typography.Icon.sm)
                Text("Craft My Prayer")
                    .font(Typography.Command.cta)
            }
            .foregroundStyle(Color("AppBackground"))
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                Capsule()
                    .fill(Color("AccentBronze"))
            )
        }
        .disabled(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.Opacity.disabled : 1)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }
}

// MARK: - Tradition Pill

private struct TraditionPill: View {
    let tradition: CloisterTradition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: tradition.icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(isSelected ? Color("AccentBronze") : Color("AppTextSecondary"))

                Text(tradition.rawValue)
                    .font(Typography.Command.label)
                    .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))

                Text(tradition.description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(width: 90)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(isSelected ? Color.appSurface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isSelected ? Color("AccentBronze").opacity(Theme.Opacity.textTertiary) : Color.appDivider,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generating Phase

private struct CloisterGeneratingPhase: View {
    @Bindable var flowState: CloisterFlowState
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
                .frame(height: 100)

            // Animated cross
            ZStack {
                // Outer glow
                Image(systemName: "cross")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(Color("AccentBronze").opacity(0.3 + pulsePhase * 0.2))
                    .blur(radius: 20)

                // Inner cross
                Image(systemName: "cross")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(Color("AccentBronze"))
            }

            VStack(spacing: Theme.Spacing.md) {
                Text("Crafting your prayer...")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(flowState.selectedTradition.rawValue + " tradition")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.referenceTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }
}

// MARK: - Display Phase

private struct CloisterDisplayPhase: View {
    @Bindable var flowState: CloisterFlowState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Compact header
            compactHeader
                .padding(.top, Theme.Spacing.xl)

            // Prayer card
            if let prayer = flowState.generatedPrayer {
                prayerCard(prayer)
            }

            // Actions
            actionButtons

            // New prayer button
            newPrayerButton
        }
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isRevealed = true
            }
        }
    }

    private var compactHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(Typography.Icon.lg)
                .foregroundStyle(Color("FeedbackSuccess"))

            Text("Your Prayer")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isRevealed)
    }

    private func prayerCard(_ prayer: CloisterGeneratedPrayer) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Drop cap + prayer text
            HStack(alignment: .top, spacing: 0) {
                Text(String(prayer.content.prefix(1)))
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentBronze"), Color("AccentBronze").opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, alignment: .leading)
                    .offset(y: -6)

                Text(String(prayer.content.dropFirst()))
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
            }

            // Amen
            Text(prayer.amen)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .italic()

            // Divider
            Rectangle()
                .fill(Color.appDivider)
                .frame(height: Theme.Stroke.hairline)

            // Tradition attribution
            HStack {
                Image(systemName: prayer.tradition.icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("TertiaryText"))

                Text(prayer.tradition.rawValue + " Tradition")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Text(formattedDate())
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
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
                            Color("AccentBronze").opacity(colorScheme == .dark ? 0.3 : 0.2),
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
        .animation(Theme.Animation.slowFade.delay(0.2), value: isRevealed)
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.xl) {
            CloisterActionButton(icon: "doc.on.doc", label: "Copy") {
                // Copy action
            }
            CloisterActionButton(icon: "square.and.arrow.up", label: "Share") {
                // Share action
            }
            CloisterActionButton(icon: "bookmark", label: "Save") {
                // Save action
            }
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
                Text("New Prayer")
                    .font(Typography.Command.label)
            }
            .foregroundStyle(Color("AccentBronze"))
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .stroke(Color("AccentBronze").opacity(Theme.Opacity.textTertiary), lineWidth: Theme.Stroke.hairline)
            )
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isRevealed)
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Action Button

private struct CloisterActionButton: View {
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
        CloisterPrayerPage()
    }
}
