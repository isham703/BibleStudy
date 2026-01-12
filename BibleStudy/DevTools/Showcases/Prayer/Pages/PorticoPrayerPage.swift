// PorticoPrayerPage.swift
// BibleStudy
//
// "The Portico" - Classical Order
// AI-powered prayer generation with clean architectural clarity
// Minimal, focused, action-oriented with clear visual hierarchy

import SwiftUI

// MARK: - Portico Prayer Page

struct PorticoPrayerPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var flowState = PorticoFlowState()
    @State private var isAwakened = false

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch flowState.phase {
                    case .input:
                        PorticoInputPhase(flowState: flowState, isAwakened: isAwakened)
                    case .generating:
                        PorticoGeneratingPhase(flowState: flowState)
                    case .displaying:
                        PorticoDisplayPhase(flowState: flowState)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("THE PORTICO")
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

            // Subtle columnar accent
            VStack {
                LinearGradient(
                    colors: [
                        Color("HighlightBlue").opacity(Theme.Opacity.subtle / 2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Flow State

@Observable
final class PorticoFlowState {
    var phase: PorticoPhase = .input
    var intentionText: String = ""
    var selectedFocus: PrayerFocus = .burden
    var generatedPrayer: PorticoPrayer?

    func beginGeneration() {
        phase = .generating
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.generatedPrayer = PorticoPrayer(
                content: "Lord, I stand before You with this weight upon my shoulders. You know every thought before I speak it, every fear before I name it. In Your wisdom, show me the path forward. In Your strength, steady my steps. I release this burden into Your capable hands, trusting that You work all things together for good. Grant me peace in the waiting, patience in the uncertainty, and faith that does not waver. You are my refuge and my fortress, my God in whom I trust.",
                closing: "Amen.",
                focus: self.selectedFocus
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

enum PorticoPhase {
    case input
    case generating
    case displaying
}

enum PrayerFocus: String, CaseIterable, Identifiable {
    case burden = "A Burden"
    case decision = "A Decision"
    case relationship = "A Relationship"
    case fear = "A Fear"
    case thanksgiving = "Thanksgiving"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .burden: return "scalemass.fill"
        case .decision: return "arrow.triangle.branch"
        case .relationship: return "person.2.fill"
        case .fear: return "bolt.shield.fill"
        case .thanksgiving: return "hands.clap.fill"
        }
    }

    var placeholder: String {
        switch self {
        case .burden: return "Describe what weighs on you..."
        case .decision: return "What choice do you face?"
        case .relationship: return "Who is on your heart?"
        case .fear: return "What causes you to fear?"
        case .thanksgiving: return "What fills you with gratitude?"
        }
    }
}

struct PorticoPrayer {
    let content: String
    let closing: String
    let focus: PrayerFocus
}

// MARK: - Input Phase

private struct PorticoInputPhase: View {
    @Bindable var flowState: PorticoFlowState
    let isAwakened: Bool
    @FocusState private var isTextFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Header
            headerSection
                .padding(.top, Theme.Spacing.xl)

            // Focus selection
            focusSection

            // Input area
            inputSection

            // Generate button
            generateButton

            // Recent prayers hint
            recentHint
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Architectural icon
            Image(systemName: "building.columns")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Color("HighlightBlue"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            Text("Bring Your Request")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)

            Text("A prayer will be crafted for your intention")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("I'M BRINGING...")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(PrayerFocus.allCases) { focus in
                        FocusPill(
                            focus: focus,
                            isSelected: flowState.selectedFocus == focus,
                            action: {
                                withAnimation(Theme.Animation.fade) {
                                    flowState.selectedFocus = focus
                                }
                            }
                        )
                    }
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $flowState.intentionText)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
                    .focused($isTextFocused)

                if flowState.intentionText.isEmpty {
                    Text(flowState.selectedFocus.placeholder)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("TertiaryText"))
                        .allowsHitTesting(false)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
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
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    private var generateButton: some View {
        Button {
            flowState.beginGeneration()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.sm)
                Text("Generate Prayer")
                    .font(Typography.Command.cta)
            }
            .foregroundStyle(Color("AppBackground"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color("HighlightBlue"))
            )
        }
        .disabled(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(flowState.intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.Opacity.disabled : 1)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
    }

    private var recentHint: some View {
        Button {
            // Show recent prayers
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(Typography.Icon.sm)
                Text("View recent prayers")
                    .font(Typography.Command.label)
            }
            .foregroundStyle(Color("AppTextSecondary"))
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }
}

// MARK: - Focus Pill

private struct FocusPill: View {
    let focus: PrayerFocus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: focus.icon)
                    .font(Typography.Icon.sm)
                Text(focus.rawValue)
                    .font(Typography.Command.label)
            }
            .foregroundStyle(isSelected ? Color("AppBackground") : Color("AppTextSecondary"))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color("HighlightBlue") : Color.appSurface)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.appDivider,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generating Phase

private struct PorticoGeneratingPhase: View {
    @Bindable var flowState: PorticoFlowState
    @State private var progressWidth: CGFloat = 0
    @State private var dotOpacity: Double = 1

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
                .frame(height: 100)

            // Animated columns
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("HighlightBlue").opacity(0.6 - Double(index) * 0.15))
                        .frame(width: 4, height: 60)
                        .offset(y: progressWidth * CGFloat(index + 1) * 2)
                }
            }

            VStack(spacing: Theme.Spacing.md) {
                Text("Generating your prayer")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: 4) {
                    Text("Please wait")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))

                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color("AppTextSecondary"))
                            .frame(width: 4, height: 4)
                            .opacity(dotOpacity)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: dotOpacity
                            )
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appDivider)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("HighlightBlue"))
                        .frame(width: geometry.size.width * progressWidth, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                progressWidth = 1
            }
            dotOpacity = 0.3
        }
    }
}

// MARK: - Display Phase

private struct PorticoDisplayPhase: View {
    @Bindable var flowState: PorticoFlowState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Success indicator
            successHeader
                .padding(.top, Theme.Spacing.xl)

            // Prayer card
            if let prayer = flowState.generatedPrayer {
                prayerCard(prayer)
            }

            // Quick actions
            quickActions

            // Secondary actions
            secondaryActions

            // New prayer
            newPrayerButton
        }
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isRevealed = true
            }
        }
    }

    private var successHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.Icon.lg)
                .foregroundStyle(Color("FeedbackSuccess"))

            Text("Prayer Generated")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isRevealed)
    }

    private func prayerCard(_ prayer: PorticoPrayer) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Focus badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: prayer.focus.icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("HighlightBlue"))

                Text(prayer.focus.rawValue)
                    .font(Typography.Editorial.label)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Prayer content
            Text(prayer.content)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.bodyLineSpacing)

            // Closing
            Text(prayer.closing)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .fontWeight(.medium)
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
                            Color("HighlightBlue").opacity(colorScheme == .dark ? 0.3 : 0.2),
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
        .animation(Theme.Animation.slowFade.delay(0.15), value: isRevealed)
    }

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuickActionButton(icon: "doc.on.doc", label: "Copy", color: Color("HighlightBlue")) { }
            QuickActionButton(icon: "square.and.arrow.up", label: "Share", color: Color("HighlightBlue")) { }
            QuickActionButton(icon: "bookmark", label: "Save", color: Color("HighlightBlue")) { }
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isRevealed)
    }

    private var secondaryActions: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Button {
                // Regenerate
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(Typography.Icon.sm)
                    Text("Regenerate")
                        .font(Typography.Command.label)
                }
                .foregroundStyle(Color("AppTextSecondary"))
            }

            Button {
                // Edit intention
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "pencil")
                        .font(Typography.Icon.sm)
                    Text("Edit Intention")
                        .font(Typography.Command.label)
                }
                .foregroundStyle(Color("AppTextSecondary"))
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
                Image(systemName: "plus")
                    .font(Typography.Icon.sm)
                Text("New Prayer")
                    .font(Typography.Command.cta)
            }
            .foregroundStyle(Color("AppBackground"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color("HighlightBlue"))
            )
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isRevealed)
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(color)

                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PorticoPrayerPage()
    }
}
