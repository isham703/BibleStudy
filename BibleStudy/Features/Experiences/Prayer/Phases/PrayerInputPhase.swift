import SwiftUI

// MARK: - Prayer Input Phase
// Handles input phase UI where users select category and enter their intention
// Features illuminated header, category chips, and text input

struct PrayerInputPhase: View {
    @Bindable var flowState: PrayerFlowState
    @FocusState.Binding var isTextFieldFocused: Bool
    let illuminationPhase: CGFloat
    let onCreatePrayer: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Main Content
            VStack(spacing: Theme.Spacing.lg) {
                // Category Selection
                categorySelection

                // Prayer Intention Input
                intentionInput
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer(minLength: 100)

            // Create Button
            createButton
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Ornamental top border
            Rectangle()
                .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                .frame(height: Theme.Stroke.hairline)
                .padding(.horizontal, Theme.Spacing.md)
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.top, 80)  // Large header offset

            // Illuminated initial
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentBronze.opacity(Theme.Opacity.medium),
                                Color.accentBronze.opacity(Theme.Opacity.subtle),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + illuminationPhase * 0.1)

                // Inner circle
                Circle()
                    .fill(Color.surfaceRaised)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.decorativeGold.opacity(0.15),
                                        Color.accentBronze,
                                        Color.feedbackWarning
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: Theme.Stroke.control
                            )
                    )

                // Letter P (for Prayer)
                Text("P")
                    .font(Typography.Scripture.display)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.decorativeGold.opacity(0.15), Color.accentBronze],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Title
            VStack(spacing: Theme.Spacing.sm) {
                Text("PRAYER")
                    .font(Typography.Scripture.display)
                    .tracking(6)
                    .foregroundColor(Color.accentBronze)

                Text("from the Deep")
                    .font(Typography.Scripture.body)
                    .italic()
                    .foregroundColor(Color.textPrimary)
            }

            // Subtitle
            Text("Let the Spirit guide your words as you pour out your heart in sacred conversation")
                .font(Typography.Scripture.body)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl + 16)
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(4)

            Rectangle()
                .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                .frame(height: Theme.Stroke.hairline)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.bottom, Theme.Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayers from the Deep. Let the Spirit guide your words as you pour out your heart in sacred conversation")
    }

    // MARK: - Category Selection

    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section Label
            Text("INTENTION")
                .font(Typography.Editorial.label)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(PrayerCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: flowState.selectedCategory == category,
                            action: { flowState.selectedCategory = category }
                        )
                    }
                }
            }
            .accessibilityLabel("Prayer intention selection")
            .accessibilityHint("Swipe to browse categories, double tap to select")
        }
    }

    // MARK: - Intention Input

    private var intentionInput: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section Label
            Text("YOUR HEART'S CRY")
                .font(Typography.Editorial.label)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))

            // Input Area
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(
                                Color.accentBronze.opacity(isTextFieldFocused ? Theme.Opacity.heavy : Theme.Opacity.light),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )

                // Text Editor
                TextEditor(text: $flowState.inputText)
                    .font(Typography.Scripture.body)
                    .foregroundColor(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .padding(Theme.Spacing.lg)
                    .frame(minHeight: 140)

                // Placeholder
                if flowState.inputText.isEmpty {
                    Text("Share what weighs on your heart, what fills you with joy, or where you seek divine guidance...")
                        .font(Typography.Scripture.body)
                        .foregroundColor(Color.textSecondary.opacity(Theme.Opacity.strong))
                        .padding(Theme.Spacing.xl)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityLabel("Your heart's cry")
            .accessibilityHint("Enter what weighs on your heart or fills you with joy")
            .accessibilityValue(flowState.inputText.isEmpty ? "Empty" : "\(flowState.inputText.count) characters entered")
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: {
            HapticService.shared.mediumTap()
            onCreatePrayer()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.md)
                Text("Create Prayer")
                    .font(Typography.Scripture.heading)
            }
            .foregroundColor(Color.surfaceParchment)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                Capsule()
                    .fill(Color.accentBronze)
                    .shadow(color: Color.accentBronze.opacity(Theme.Opacity.disabled), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(!flowState.canGenerate)
        .opacity(flowState.canGenerate ? 1 : Theme.Opacity.strong)
        .accessibilityLabel(flowState.canGenerate ? "Create Prayer" : "Create Prayer, disabled")
        .accessibilityHint(flowState.canGenerate ? "Double tap to generate your personalized prayer" : "Enter your intention first")
        .padding(.bottom, Theme.Spacing.xxl + 16)
    }
}

// MARK: - Preview

#Preview("Input Phase") {
    @Previewable @State var flowState = PrayerFlowState()
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color.surfaceParchment.ignoresSafeArea()
        PrayerInputPhase(
            flowState: flowState,
            isTextFieldFocused: $focused,
            illuminationPhase: 0.5,
            onCreatePrayer: {}
        )
    }
}
