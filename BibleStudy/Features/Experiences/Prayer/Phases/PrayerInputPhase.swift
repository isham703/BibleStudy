import SwiftUI

// MARK: - Prayer Input Phase
// Handles input phase UI where users select category and enter their intention
// Hero-style design with gradient header and large pill selection rows

struct PrayerInputPhase: View {
    @Bindable var flowState: PrayerFlowState
    @FocusState.Binding var isTextFieldFocused: Bool
    let illuminationPhase: CGFloat
    let onCreatePrayer: () -> Void
    var onViewRecentPrayers: (() -> Void)?
    @State private var isAwakened = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Hero Header
            HeroHeader(imageName: "PrayerHero")

            // Main Content
            VStack(spacing: Theme.Spacing.lg) {
                // Title Block
                titleBlock
                    .padding(.top, -Theme.Spacing.lg)

                // Category Selection (pill rows)
                categorySelection

                // Prayer Intention Input
                intentionInput

                // Create Button
                createButton
                    .padding(.top, Theme.Spacing.xs)

                // Recent prayers hint
                recentHint
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Begin Prayer")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)

            Text("Choose your focus")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Begin Prayer. Choose your focus")
    }

    // MARK: - Category Selection

    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section Label
            Text("I'm bringing...")
                .font(Typography.Command.label)
                .foregroundStyle(Color("AppTextSecondary"))

            // Category Chips - horizontal scroll with edge fade cue
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(PrayerCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: flowState.selectedCategory == category,
                            action: {
                                withAnimation(Theme.Animation.fade) {
                                    flowState.selectedCategory = category
                                }
                            }
                        )
                    }
                }
                // Generous trailing padding ensures last chip is fully visible past fade
                .padding(.trailing, 56)
            }
            // Edge fade overlay signals scrollable content without clipping
            .overlay(alignment: .trailing) {
                LinearGradient(
                    colors: [
                        .clear,
                        colorScheme == .dark ? Color.warmCharcoal : Color.appBackground
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 32)
                .allowsHitTesting(false)
            }
            .accessibilityLabel("Prayer intention selection")
            .accessibilityHint("Swipe to browse categories, double tap to select")
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
    }

    // MARK: - Intention Input

    private var intentionInput: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Field label - sentence case for consistency with "I'm bringing..."
            Text("Your intention")
                .font(Typography.Command.label)
                .foregroundStyle(Color("AppTextSecondary"))

            // Input card
            ZStack(alignment: .topLeading) {
                // Text Editor
                TextEditor(text: $flowState.inputText)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .focused($isTextFieldFocused)

                // Placeholder - visible but clearly placeholder
                if flowState.inputText.isEmpty {
                    Text("What's on your heart?")
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .allowsHitTesting(false)
                        .padding(.top, 8)
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
                    .stroke(
                        isTextFieldFocused
                            ? Color("HighlightBlue")
                            : Color("AppTextSecondary").opacity(Theme.Opacity.disabled),
                        lineWidth: isTextFieldFocused ? 2 : Theme.Stroke.hairline
                    )
            )
            // Stronger focus feedback
            .shadow(
                color: isTextFieldFocused ? Color("HighlightBlue").opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 0
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 12)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
        .accessibilityLabel("Prayer intention")
        .accessibilityHint("Enter what's on your heart")
        .accessibilityValue(flowState.inputText.isEmpty ? "Empty" : "\(flowState.inputText.count) characters entered")
    }

    // MARK: - Create Button

    private var createButton: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: {
                HapticService.shared.mediumTap()
                onCreatePrayer()
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(Typography.Icon.sm)
                    Text("Generate Prayer")
                        .font(Typography.Command.cta)
                }
                // Enabled: white on warm bronze (harmonizes with candlelit palette)
                // Disabled: visible but locked (reads as "next step")
                .foregroundStyle(
                    flowState.canGenerate
                        ? .white
                        : Color("AppTextSecondary")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            flowState.canGenerate
                                ? Color("AccentBronze")
                                : Color.appSurface
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(
                            flowState.canGenerate ? Color.clear : Color.appDivider,
                            lineWidth: Theme.Stroke.control
                        )
                )
            }
            .disabled(!flowState.canGenerate)

            // Helper text when disabled
            if !flowState.canGenerate {
                Text("Add your intention above to continue")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
        .accessibilityLabel(flowState.canGenerate ? "Generate Prayer" : "Generate Prayer, disabled")
        .accessibilityHint(flowState.canGenerate ? "Double tap to generate your personalized prayer" : "Enter your intention first")
    }

    // MARK: - Recent Hint

    private var recentHint: some View {
        Group {
            if let onViewRecentPrayers = onViewRecentPrayers {
                Button {
                    HapticService.shared.lightTap()
                    onViewRecentPrayers()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(Typography.Icon.sm)
                        Text("View recent prayers")
                            .font(Typography.Command.label)
                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.xs)
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
            }
        }
    }
}

// MARK: - Preview

#Preview("Input Phase") {
    @Previewable @State var flowState = PrayerFlowState()
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color("AppBackground").ignoresSafeArea()
        PrayerInputPhase(
            flowState: flowState,
            isTextFieldFocused: $focused,
            illuminationPhase: 0.5,
            onCreatePrayer: {}
        )
    }
}
