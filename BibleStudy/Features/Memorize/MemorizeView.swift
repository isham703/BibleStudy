import SwiftUI

// MARK: - Memorize View
// Main practice view for scripture memorization

struct MemorizeView: View {
    let item: MemorizationItem
    let onComplete: (ReviewQuality) -> Void
    let onSkip: () -> Void

    @State private var hintLevel: Int = 0
    @State private var userInput: String = ""
    @State private var showingAnswer: Bool = false
    @State private var answerResult: AnswerResult?
    @State private var isTypingMode: Bool = false
    @FocusState private var isInputFocused: Bool

    private let maxHintLevels = 4

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
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
        VStack(spacing: AppTheme.Spacing.sm) {
            // Reference
            Text(item.reference)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Mastery badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: item.masteryLevel.icon)
                Text(item.masteryLevel.displayName)
            }
            .font(Typography.UI.caption1)
            .foregroundStyle(masteryColor)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(masteryColor.opacity(AppTheme.Opacity.light))
            )

            // Stats row
            HStack(spacing: AppTheme.Spacing.lg) {
                statItem(label: "Reviews", value: "\(item.totalReviews)")
                statItem(label: "Accuracy", value: "\(Int(item.accuracy * 100))%")
                statItem(label: "Streak", value: "\(item.repetitions)")
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text(value)
                .font(Typography.UI.headline.monospacedDigit())
                .foregroundStyle(Color.primaryText)
            Text(label)
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private var masteryColor: Color {
        switch item.masteryLevel {
        case .learning: return .accentBlue
        case .reviewing: return .scholarAccent
        case .mastered: return .success
        }
    }

    // MARK: - Hint Section

    private var hintSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Mode toggle
            Picker("Mode", selection: $isTypingMode) {
                Text("Recall").tag(false)
                Text("Type").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Spacing.xl)

            // Hint card
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                if showingAnswer {
                    // Show full text
                    Text(item.verseText)
                        .font(Typography.Scripture.body())
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(6)
                } else {
                    // Show hint based on level
                    Text(currentHint)
                        .font(Typography.Scripture.body())
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(6)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(showingAnswer ? Color.success.opacity(AppTheme.Opacity.heavy) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
                        .font(Typography.UI.caption1)
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
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<maxHintLevels, id: \.self) { level in
                Circle()
                    .fill(level <= hintLevel ? Color.scholarAccent : Color.cardBorder)
                    .frame(width: AppTheme.ComponentSize.indicator, height: AppTheme.ComponentSize.indicator)
            }
        }
    }

    // MARK: - Typing Input Section

    private var typingInputSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Text input
            TextField("Type the verse...", text: $userInput, axis: .vertical)
                .font(Typography.Scripture.body())
                .lineLimit(5...10)
                .padding()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
                )
                .focused($isInputFocused)

            // Result feedback
            if let result = answerResult {
                resultFeedback(result)
            }

            // Action buttons
            HStack(spacing: AppTheme.Spacing.md) {
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
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(result.feedbackMessage)
        }
        .font(Typography.UI.subheadline)
        .foregroundStyle(result.isCorrect ? Color.success : Color.error)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill((result.isCorrect ? Color.success : Color.error).opacity(AppTheme.Opacity.subtle))
        )
    }

    // MARK: - Review Buttons Section

    private var reviewButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if !showingAnswer {
                Button("Show Answer") {
                    withAnimation {
                        showingAnswer = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("How well did you remember?")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)

                qualityButtons
            }
        }
    }

    private var qualityButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                qualityButton(.completeBlackout, color: .error)
                qualityButton(.incorrectButRemembered, color: .warning)
                qualityButton(.correctDifficult, color: .info)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                qualityButton(.correctWithHesitation, color: .scholarAccent)
                qualityButton(.perfectRecall, color: .success)
            }
        }
    }

    private func qualityButton(_ quality: ReviewQuality, color: Color) -> some View {
        Button {
            onComplete(quality)
        } label: {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: quality.icon)
                    .font(Typography.UI.title3)
                Text(quality.displayName)
                    .font(Typography.UI.caption2)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(color.opacity(AppTheme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(color.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
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
