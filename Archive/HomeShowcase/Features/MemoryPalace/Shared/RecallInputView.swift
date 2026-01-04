import SwiftUI

// MARK: - Recall Input View
// Text input for the Recall phase where users type the phrase from memory
// Includes validation feedback and Skip button

struct RecallInputView: View {
    let expectedPhrase: String
    @Binding var inputText: String
    @Binding var showFeedback: Bool
    @FocusState.Binding var isFocused: Bool
    let accentColor: Color
    let style: RecallInputStyle
    let onCheck: () -> Void
    let onSkip: () -> Void

    enum RecallInputStyle {
        case candlelit
        case scholarly
        case celestial
    }

    @State private var isCorrect: Bool = false
    @State private var hasChecked: Bool = false

    var body: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            // Instruction
            Text("Type the phrase from memory")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(style == .scholarly ? Color.footnoteGray : Color.white.opacity(0.6))

            // Text field with style-specific appearance
            textFieldView

            // Feedback message
            if showFeedback && hasChecked {
                feedbackMessage
            }

            // Action buttons
            HStack(spacing: HomeShowcaseTheme.Spacing.xl) {
                // Skip button
                Button(action: onSkip) {
                    HStack(spacing: HomeShowcaseTheme.Spacing.xs) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                        Text("Skip")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(style == .scholarly ? Color.footnoteGray : Color.white.opacity(0.6))
                    .frame(minWidth: HomeShowcaseTheme.Size.touchTarget)
                    .frame(height: HomeShowcaseTheme.Size.touchTarget)
                }

                // Check button
                Button(action: checkAnswer) {
                    HStack(spacing: HomeShowcaseTheme.Spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Check")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                    .frame(height: HomeShowcaseTheme.Size.touchTarget)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
                }
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
    }

    // MARK: - Text Field

    @ViewBuilder
    private var textFieldView: some View {
        switch style {
        case .candlelit:
            candlelitTextField
        case .scholarly:
            scholarlyTextField
        case .celestial:
            celestialTextField
        }
    }

    private var candlelitTextField: some View {
        TextField("", text: $inputText, prompt: Text("Enter phrase...").foregroundStyle(Color.white.opacity(0.3)))
            .font(.custom("CormorantGaramond-Regular", size: 20, relativeTo: .title3))
            .foregroundStyle(Color.moonlitParchment)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
            .padding(.vertical, HomeShowcaseTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                            .stroke(feedbackBorderColor, lineWidth: showFeedback && hasChecked ? 2 : 1)
                    )
                    .shadow(color: showFeedback && isCorrect ? Color.green.opacity(0.3) : .clear, radius: 8)
            )
            .modifier(ShakeEffect(shakes: showFeedback && hasChecked && !isCorrect ? 2 : 0))
    }

    private var scholarlyTextField: some View {
        VStack(spacing: 4) {
            TextField("", text: $inputText, prompt: Text("Enter phrase...").foregroundStyle(Color.footnoteGray))
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color.scholarInk)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)

            // Underline
            Rectangle()
                .fill(showFeedback && hasChecked ? feedbackBorderColor : Color.scholarInk.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
        .modifier(ShakeEffect(shakes: showFeedback && hasChecked && !isCorrect ? 2 : 0))
    }

    private var celestialTextField: some View {
        TextField("", text: $inputText, prompt: Text("Enter phrase...").foregroundStyle(Color.white.opacity(0.3)))
            .font(.custom("CormorantGaramond-Regular", size: 20, relativeTo: .title3))
            .foregroundStyle(Color.celestialStarlight)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
            .padding(.vertical, HomeShowcaseTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                            .stroke(
                                showFeedback && hasChecked
                                    ? feedbackBorderColor
                                    : accentColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .modifier(ShakeEffect(shakes: showFeedback && hasChecked && !isCorrect ? 2 : 0))
    }

    // MARK: - Feedback

    private var feedbackBorderColor: Color {
        if !hasChecked { return accentColor.opacity(0.3) }
        return isCorrect ? Color.green : Color.red.opacity(0.7)
    }

    private var feedbackMessage: some View {
        HStack(spacing: HomeShowcaseTheme.Spacing.xs) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(isCorrect ? "Perfect!" : "Not quite. Try again or skip.")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isCorrect ? Color.green : Color.red.opacity(0.8))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Actions

    private func checkAnswer() {
        hasChecked = true
        isCorrect = inputText.matchesRecall(expectedPhrase)

        withAnimation(HomeShowcaseTheme.Animation.quick) {
            showFeedback = true
        }

        if isCorrect {
            onCheck()
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: sin(CGFloat(shakes) * .pi * 2) * 8, y: 0)
        )
    }
}

// MARK: - Preview

#Preview("Recall Input") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var showFeedback = false
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack(spacing: 40) {
                // Candlelit
                ZStack {
                    Color(hex: "030308")
                    RecallInputView(
                        expectedPhrase: "The Lord",
                        inputText: $text,
                        showFeedback: $showFeedback,
                        isFocused: $isFocused,
                        accentColor: .candleAmber,
                        style: .candlelit,
                        onCheck: {},
                        onSkip: {}
                    )
                }
                .frame(height: 200)

                // Scholarly
                ZStack {
                    Color.vellumCream
                    RecallInputView(
                        expectedPhrase: "I shall not want",
                        inputText: $text,
                        showFeedback: $showFeedback,
                        isFocused: $isFocused,
                        accentColor: .scholarIndigo,
                        style: .scholarly,
                        onCheck: {},
                        onSkip: {}
                    )
                }
                .frame(height: 200)
            }
        }
    }

    return PreviewWrapper()
}
