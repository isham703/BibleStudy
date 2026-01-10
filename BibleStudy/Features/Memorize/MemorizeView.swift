import SwiftUI

// MARK: - Memorize View
// Main practice view for scripture memorization

struct MemorizeView: View {
    let item: MemorizationItem
    let onComplete: (ReviewQuality) -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var hintLevel: Int = 0
    @State private var userInput: String = ""
    @State private var showingAnswer: Bool = false
    @State private var answerResult: AnswerResult?
    @State private var isTypingMode: Bool = false
    @FocusState private var isInputFocused: Bool

    private let maxHintLevels = 4

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header with reference and mastery
                headerSection

                // Hint display area
                hintSection

                // Progress indicator
                hintProgressIndicator

                // Input or review buttons
                if isTypingMode {
                    typingInputSection
                } else {
                    reviewButtonsSection
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    onSkip()
                }
                .foregroundStyle(Color.secondaryText)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Reference
            Text(item.reference)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            // Mastery badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: item.masteryLevel.icon)
                Text(item.masteryLevel.displayName)
            }
            .font(Typography.Command.caption)
            .foregroundStyle(masteryColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(masteryColor.opacity(Theme.Opacity.light))
            )

            // Stats row
            HStack(spacing: Theme.Spacing.lg) {
                statItem(label: "Reviews", value: "\(item.totalReviews)")
                statItem(label: "Accuracy", value: "\(Int(item.accuracy * 100))%")
                statItem(label: "Streak", value: "\(item.repetitions)")
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Typography.Command.headline.monospacedDigit())
                .foregroundStyle(Color.primaryText)
            Text(label)
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private var masteryColor: Color {
        switch item.masteryLevel {
        case .learning: return .accentBlue
        case .reviewing: return Color.accentIndigo
        case .mastered: return .success
        }
    }

    // MARK: - Hint Section

    private var hintSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Mode toggle
            Picker("Mode", selection: $isTypingMode) {
                Text("Recall").tag(false)
                Text("Type").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.xl)

            // Hint card
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if showingAnswer {
                    // Show full text
                    Text(item.verseText)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(6)
                } else {
                    // Show hint based on level
                    Text(currentHint)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(6)
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(showingAnswer ? Color.success.opacity(Theme.Opacity.heavy) : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )

            // Hint level controls
            if !showingAnswer {
                HStack {
                    Button {
                        withAnimation {
                            if hintLevel > 0 {
                                hintLevel -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(hintLevel > 0 ? Color.primaryText : Color.tertiaryText)
                    }
                    .disabled(hintLevel == 0)

                    Text("Hint Level \(hintLevel + 1)/\(maxHintLevels)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)
                        .frame(width: 100)

                    Button {
                        withAnimation {
                            if hintLevel < maxHintLevels - 1 {
                                hintLevel += 1
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(hintLevel < maxHintLevels - 1 ? Color.primaryText : Color.tertiaryText)
                    }
                    .disabled(hintLevel >= maxHintLevels - 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var currentHint: String {
        MemorizationService.generateProgressiveHint(text: item.verseText, level: hintLevel)
    }

    // MARK: - Progress Indicator

    private var hintProgressIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<maxHintLevels, id: \.self) { level in
                Circle()
                    .fill(level <= hintLevel ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.cardBorder)
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Typing Input Section

    private var typingInputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Text input
            TextField("Type the verse...", text: $userInput, axis: .vertical)
                .font(Typography.Scripture.body)
                .lineLimit(5...10)
                .padding()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
                )
                .focused($isInputFocused)

            // Result feedback
            if let result = answerResult {
                resultFeedback(result)
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.md) {
                if answerResult == nil {
                    Button("Check Answer") {
                        checkTypedAnswer()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Show Answer") {
                        withAnimation {
                            showingAnswer = true
                            answerResult = .incorrect
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    qualityButtons
                }
            }
        }
    }

    private func checkTypedAnswer() {
        let result = MemorizationService.checkAnswer(userInput: userInput, expectedText: item.verseText)
        withAnimation {
            answerResult = result
            showingAnswer = true
        }
    }

    private func resultFeedback(_ result: AnswerResult) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(result.feedbackMessage)
        }
        .font(Typography.Command.subheadline)
        .foregroundStyle(result.isCorrect ? Color.success : Color.error)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill((result.isCorrect ? Color.success : Color.error).opacity(Theme.Opacity.subtle))
        )
    }

    // MARK: - Review Buttons Section

    private var reviewButtonsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !showingAnswer {
                Button("Show Answer") {
                    withAnimation {
                        showingAnswer = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("How well did you remember?")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.secondaryText)

                qualityButtons
            }
        }
    }

    private var qualityButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                qualityButton(.completeBlackout, color: .error)
                qualityButton(.incorrectButRemembered, color: .warning)
                qualityButton(.correctDifficult, color: .info)
            }

            HStack(spacing: Theme.Spacing.sm) {
                qualityButton(.correctWithHesitation, color: Color.accentIndigo)
                qualityButton(.perfectRecall, color: .success)
            }
        }
    }

    private func qualityButton(_ quality: ReviewQuality, color: Color) -> some View {
        Button {
            onComplete(quality)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: quality.icon)
                    .font(Typography.Command.title3)
                Text(quality.displayName)
                    .font(Typography.Command.meta)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(color.opacity(Theme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(color.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MemorizeView(
            item: MemorizationItem(
                userId: UUID(),
                bookId: 1,
                chapter: 1,
                verseStart: 1,
                verseEnd: 1,
                verseText: "In the beginning God created the heaven and the earth.",
                masteryLevel: .learning,
                totalReviews: 5,
                correctReviews: 3
            ),
            onComplete: { _ in },
            onSkip: {}
        )
    }
}
