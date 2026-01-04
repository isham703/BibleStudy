import SwiftUI

// MARK: - Warm Ask Landing View
// A warm, personal study companion experience for the Ask tab empty state
// Replaces IlluminatedBookEmptyState with context-aware suggestions

struct WarmAskLandingView: View {
    // MARK: - Environment & State
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
    private var hasAIConsent: Bool = false

    // MARK: - Callbacks
    let onSelectQuestion: (String) -> Void
    let onRequestConsent: () -> Void

    // MARK: - ViewModel
    @State private var viewModel = WarmAskLandingViewModel()

    // MARK: - Animation State
    @State private var greetingOpacity: CGFloat = 0
    @State private var contextCardOpacity: CGFloat = 0
    @State private var questionsOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat = 20

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Use vertical layout for accessibility sizes
    private var useVerticalChipLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            // 1. Personal Welcome (reuse GreetingHeader pattern)
            GreetingHeader(userName: viewModel.userName)
                .opacity(greetingOpacity)
                .offset(y: contentOffset * 0.5)

            // Warm subtitle
            Text("What's on your mind today?")
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(ScholarAskPalette.secondaryText)
                .opacity(greetingOpacity)
                .offset(y: contentOffset * 0.5)

            // 2. Reading Context Card (conditional)
            if let context = viewModel.readingContext {
                ReadingContextCard(context: context) {
                    handleQuestionTap("What can I learn from \(context.bookName) \(context.chapter)?")
                }
                .opacity(contextCardOpacity)
                .offset(y: contentOffset)
            }

            // 3. Contextual Question Suggestions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Try asking...")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(ScholarAskPalette.tertiaryText)

                if useVerticalChipLayout {
                    // Vertical stack for large Dynamic Type
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        ForEach(Array(viewModel.suggestedQuestions.enumerated()), id: \.offset) { index, question in
                            ContextualQuestionChip(
                                question: question,
                                isEnabled: hasAIConsent
                            ) {
                                handleQuestionTap(question)
                            }
                            .accessibilityLabel("Suggested question: \(question)")
                        }
                    }
                } else {
                    // Horizontal scroll for normal sizes - extend beyond parent padding
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(viewModel.suggestedQuestions.enumerated()), id: \.offset) { index, question in
                                ContextualQuestionChip(
                                    question: question,
                                    isEnabled: hasAIConsent
                                ) {
                                    handleQuestionTap(question)
                                }
                                .accessibilityLabel("Suggested question: \(question)")
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                    .padding(.horizontal, -AppTheme.Spacing.lg) // Extend to screen edges
                }
            }
            .opacity(questionsOpacity)
            .offset(y: contentOffset)

            Spacer()

            // 4. Subtle warm glow accent
            WarmAccentGlow()
                .frame(height: 60)
                .opacity(questionsOpacity * 0.3)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .onAppear {
            viewModel.loadContext(from: appState)
            startEntranceAnimation()
        }
    }

    // MARK: - Question Tap Handler

    private func handleQuestionTap(_ question: String) {
        if hasAIConsent {
            onSelectQuestion(question)
        } else {
            onRequestConsent()
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        if respectsReducedMotion {
            // Instant appearance
            greetingOpacity = 1
            contextCardOpacity = 1
            questionsOpacity = 1
            contentOffset = 0
            return
        }

        // Phase 1: Greeting fades in (0-200ms)
        withAnimation(AppTheme.Animation.standard) {
            greetingOpacity = 1
            contentOffset = 10
        }

        // Phase 2: Context card appears (100-300ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(AppTheme.Animation.sacredSpring) {
                contextCardOpacity = 1
                contentOffset = 0
            }
        }

        // Phase 3: Questions unfurl (200-500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(AppTheme.Animation.standard) {
                questionsOpacity = 1
            }
        }

        // Subtle haptic on greeting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            HapticService.shared.softTap()
        }
    }
}

// MARK: - Reading Context Card

private struct ReadingContextCard: View {
    let context: ReadingContext
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Book icon with accent circle
                ZStack {
                    Circle()
                        .fill(ScholarAskPalette.accentSubtle)
                        .frame(width: 44, height: 44)

                    Image(systemName: "book.fill")
                        .font(Typography.UI.body)
                        .foregroundStyle(ScholarAskPalette.accent)
                }

                // Context text
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(context.displayText)
                        .font(Typography.UI.bodyBold)
                        .foregroundStyle(ScholarAskPalette.primaryText)

                    Text("Have a question about this passage?")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(ScholarAskPalette.secondaryText)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(ScholarAskPalette.tertiaryText)
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(ScholarAskPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .strokeBorder(
                        ScholarAskPalette.accent.opacity(AppTheme.Opacity.light),
                        lineWidth: AppTheme.Border.thin
                    )
            )
            .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1.0)
            .animation(AppTheme.Animation.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Reading context: \(context.reference)")
        .accessibilityHint("Tap to ask a question about this passage")
    }
}

// MARK: - Contextual Question Chip

private struct ContextualQuestionChip: View {
    let question: String
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.xs) {
                // Sparkle icon
                Image(systemName: "sparkle")
                    .font(Typography.UI.iconXxs)
                    .foregroundStyle(ScholarAskPalette.accent)

                Text(question)
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(ScholarAskPalette.primaryText)
                    .lineLimit(2)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 2)
            .background(
                Capsule()
                    .fill(ScholarAskPalette.surface)
                    .overlay(
                        Capsule()
                            .strokeBorder(ScholarAskPalette.divider, lineWidth: AppTheme.Border.thin)
                    )
            )
            .opacity(isEnabled ? 1.0 : AppTheme.Opacity.disabled)
        }
        .buttonStyle(PressableChipButtonStyle())
    }
}

private struct PressableChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? AppTheme.Scale.pressed : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Warm Accent Glow

private struct WarmAccentGlow: View {
    @State private var glowIntensity: CGFloat = 0.6

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        ScholarAskPalette.accent.opacity(glowIntensity * 0.15),
                        ScholarAskPalette.accent.opacity(glowIntensity * 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .blur(radius: AppTheme.Blur.intense)
            .onAppear {
                guard !respectsReducedMotion else { return }
                withAnimation(AppTheme.Animation.pulse) {
                    glowIntensity = 0.8
                }
            }
    }
}

// MARK: - Previews

#Preview("With Reading Context") {
    WarmAskLandingView(
        onSelectQuestion: { _ in },
        onRequestConsent: {}
    )
    .environment(AppState())
    .background(Color.appBackground)
}

#Preview("Without Reading Context") {
    WarmAskLandingView(
        onSelectQuestion: { _ in },
        onRequestConsent: {}
    )
    .environment(AppState())
    .background(Color.appBackground)
}
