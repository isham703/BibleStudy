import SwiftUI

// MARK: - Comprehension Views
// UI components for AI-powered reading comprehension features (Phase 5)

// MARK: - Simplify Passage View

struct SimplifyPassageView: View {
    let verseRange: VerseRange
    let verseText: String
    let onClose: () -> Void

    @State private var selectedLevel: ReadingLevel = .intermediate
    @State private var isLoading = false
    @State private var simplifiedOutput: SimplifiedPassageOutput?
    @State private var error: String?

    private let aiService: AIServiceProtocol = OpenAIProvider.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Original text
                    OriginalTextSection(
                        reference: verseRange.reference,
                        text: verseText
                    )

                    // Reading level picker
                    ReadingLevelPicker(selectedLevel: $selectedLevel)
                        .onChange(of: selectedLevel) { _, _ in
                            Task {
                                await loadSimplified()
                            }
                        }

                    Divider()

                    // Simplified output
                    if isLoading {
                        AILoadingView(message: "Simplifying passage")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.xxxl)
                    } else if let output = simplifiedOutput {
                        SimplifiedOutputSection(output: output)
                    } else if let error = error {
                        ErrorSection(message: error) {
                            Task { await loadSimplified() }
                        }
                    } else {
                        // Initial prompt
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "text.redaction")
                                .font(Typography.UI.largeTitle)
                                .foregroundStyle(Color.accentGold)

                            Text("Tap a reading level above to see this passage simplified")
                                .font(Typography.UI.warmBody)
                                .foregroundStyle(Color.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xxxl)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Simplify Passage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
        .task {
            await loadSimplified()
        }
    }

    private func loadSimplified() async {
        isLoading = true
        error = nil

        do {
            simplifiedOutput = try await aiService.simplifyPassage(
                verseRange: verseRange,
                verseText: verseText,
                level: selectedLevel
            )
        } catch {
            self.error = error.localizedDescription
            // Provide sample fallback
            simplifiedOutput = getSampleSimplified()
        }

        isLoading = false
    }

    private func getSampleSimplified() -> SimplifiedPassageOutput {
        SimplifiedPassageOutput(
            simplified: "In the beginning, God made everything—the sky and the earth. He spoke, and it all came to be.",
            keyTermsExplained: [
                .init(term: "created", explanation: "Made something from nothing"),
                .init(term: "heavens", explanation: "The sky and everything above")
            ],
            oneLineSummary: "God created the entire universe by His word."
        )
    }
}

// MARK: - Original Text Section

struct OriginalTextSection: View {
    let reference: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Original")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text(reference)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }

            Text(text)
                .font(Typography.Scripture.body())
                .foregroundStyle(Color.primaryText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.surfaceBackground)
                )
        }
    }
}

// MARK: - Reading Level Picker

struct ReadingLevelPicker: View {
    @Binding var selectedLevel: ReadingLevel

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Reading Level")
                .font(Typography.UI.caption1Bold)
                .foregroundStyle(Color.secondaryText)

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(ReadingLevel.allCases, id: \.self) { level in
                    ReadingLevelButton(
                        level: level,
                        isSelected: selectedLevel == level
                    ) {
                        selectedLevel = level
                    }
                }
            }
        }
    }
}

struct ReadingLevelButton: View {
    let level: ReadingLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(level.displayName)
                    .font(Typography.UI.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(level.description)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.light) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentGold : Color.primaryText)
    }
}

// MARK: - Simplified Output Section

struct SimplifiedOutputSection: View {
    let output: SimplifiedPassageOutput

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // One-line summary
            if !output.oneLineSummary.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(Color.accentGold)
                        Text("In one sentence")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.accentGold)
                    }

                    Text(output.oneLineSummary)
                        .font(Typography.UI.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primaryText)
                }
            }

            // Simplified text
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "text.redaction")
                        .foregroundStyle(Color.accentBlue)
                    Text("Simplified")
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.accentBlue)
                }

                Text(output.simplified)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.accentBlue.opacity(AppTheme.Opacity.faint))
                    )
            }

            // Key terms explained
            if let terms = output.keyTermsExplained, !terms.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "character.book.closed")
                            .foregroundStyle(Color.info)
                        Text("Key terms explained")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.info)
                    }

                    ForEach(terms) { term in
                        KeyTermRow(term: term.term, explanation: term.explanation)
                    }
                }
            }
        }
    }
}

struct KeyTermRow: View {
    let term: String
    let explanation: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(term)
                .font(Typography.UI.caption1Bold)
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(Color.surfaceBackground)
                )

            Text(explanation)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

// MARK: - Error Section

struct ErrorSection: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.UI.title1)
                .foregroundStyle(Color.warning)

            Text(message)
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .font(Typography.UI.body)
                .foregroundStyle(Color.accentGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxl)
    }
}

// MARK: - Comprehension Questions View

struct ComprehensionQuestionsView: View {
    let verseRange: VerseRange
    let verseText: String
    let onClose: () -> Void

    @State private var isLoading = false
    @State private var questionsOutput: ComprehensionQuestionsOutput?
    @State private var selectedPassageType: PassageType = .narrative
    @State private var revealedHints: Set<String> = []
    @State private var error: String?

    private let aiService: AIServiceProtocol = OpenAIProvider.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Passage reference
                    HStack {
                        Image(systemName: "book")
                            .foregroundStyle(Color.accentGold)
                        Text(verseRange.reference)
                            .font(Typography.UI.headline)
                            .foregroundStyle(Color.primaryText)
                    }

                    // Passage type selector
                    PassageTypePicker(selectedType: $selectedPassageType)
                        .onChange(of: selectedPassageType) { _, _ in
                            Task { await loadQuestions() }
                        }

                    Divider()

                    // Questions
                    if isLoading {
                        AILoadingView(message: "Generating questions")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.xxxl)
                    } else if let output = questionsOutput {
                        QuestionsSection(
                            questions: output.questions,
                            revealedHints: $revealedHints
                        )
                    } else if let error = error {
                        ErrorSection(message: error) {
                            Task { await loadQuestions() }
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Comprehension Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadQuestions() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await loadQuestions()
        }
    }

    private func loadQuestions() async {
        isLoading = true
        error = nil
        revealedHints.removeAll()

        do {
            questionsOutput = try await aiService.generateComprehensionQuestions(
                verseRange: verseRange,
                verseText: verseText,
                passageType: selectedPassageType
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Passage Type Picker

struct PassageTypePicker: View {
    @Binding var selectedType: PassageType

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Passage Type")
                .font(Typography.UI.caption1Bold)
                .foregroundStyle(Color.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(PassageType.allCases, id: \.self) { type in
                        PassageTypeChip(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

struct PassageTypeChip: View {
    let type: PassageType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(Typography.UI.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.accentGold : Color.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.light) : Color.surfaceBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: AppTheme.Border.thin)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Questions Section

struct QuestionsSection: View {
    let questions: [ComprehensionQuestionsOutput.ComprehensionQuestion]
    @Binding var revealedHints: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Reflection Questions")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            ForEach(questions) { question in
                QuestionCard(
                    question: question,
                    isHintRevealed: revealedHints.contains(question.id)
                ) {
                    revealedHints.insert(question.id)
                }
            }
        }
    }
}

struct QuestionCard: View {
    let question: ComprehensionQuestionsOutput.ComprehensionQuestion
    let isHintRevealed: Bool
    let onRevealHint: () -> Void

    var questionType: ComprehensionQuestionsOutput.QuestionType {
        question.questionType
    }

    var typeColor: Color {
        switch questionType {
        case .observation: return Color.accentBlue
        case .interpretation: return Color.accentGold
        case .application: return Color.accentRose
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Type badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: questionType.icon)
                    .font(Typography.UI.caption1)
                Text(questionType.displayName)
                    .font(Typography.UI.caption2)
            }
            .foregroundStyle(typeColor)

            // Question text
            Text(question.question)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)

            // Hint
            if let hint = question.hint, !hint.isEmpty {
                if isHintRevealed {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.warning)
                        Text(hint)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .italic()
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(Color.warning.opacity(AppTheme.Opacity.subtle))
                    )
                } else {
                    Button {
                        withAnimation(AppTheme.Animation.quick) {
                            onRevealHint()
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "lightbulb")
                                .font(Typography.UI.caption1)
                            Text("Need a hint?")
                                .font(Typography.UI.caption1)
                        }
                        .foregroundStyle(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(typeColor.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Phrase Selector Sheet
// Allows users to tap words/phrases in the verse to get clarification

struct PhraseSelectorSheet: View {
    let verseRange: VerseRange
    let verseText: String
    let onClose: () -> Void

    @State private var selectedPhrase: String?
    @State private var showingClarification = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Instructions
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "hand.tap")
                            .foregroundStyle(Color.accentGold)
                        Text("Tap any word or phrase to get a quick explanation")
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                    )

                    // Reference
                    Text(verseRange.reference)
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.secondaryText)

                    // Tappable words
                    TappableTextView(
                        text: verseText,
                        onWordTap: { word in
                            selectedPhrase = word
                            showingClarification = true
                        }
                    )

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Clarify a Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
            .sheet(isPresented: $showingClarification) {
                if let phrase = selectedPhrase {
                    PhraseClarificationSheet(
                        phrase: phrase,
                        verseRange: verseRange,
                        verseText: verseText,
                        onClose: { showingClarification = false }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }
}

// MARK: - Tappable Text View
// Renders text with each word individually tappable

struct TappableTextView: View {
    let text: String
    let onWordTap: (String) -> Void

    private var words: [WordItem] {
        text.split(separator: " ", omittingEmptySubsequences: true)
            .enumerated()
            .map { WordItem(id: $0.offset, word: String($0.element)) }
    }

    var body: some View {
        FlowLayout(spacing: AppTheme.Spacing.xs) {
            ForEach(words) { item in
                TappableWord(word: item.word) {
                    onWordTap(item.word)
                }
            }
        }
    }
}

struct WordItem: Identifiable {
    let id: Int
    let word: String
}

struct TappableWord: View {
    let word: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(word)
            .font(Typography.Scripture.body())
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(isPressed ? Color.accentGold.opacity(AppTheme.Opacity.lightMedium) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(Color.cardBorder.opacity(AppTheme.Opacity.heavy), lineWidth: AppTheme.Border.hairline)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(AppTheme.Animation.quick) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppTheme.Animation.quick) {
                        isPressed = false
                    }
                    onTap()
                }
            }
    }
}

// MARK: - Phrase Clarification Sheet
// Full sheet version of phrase clarification

struct PhraseClarificationSheet: View {
    let phrase: String
    let verseRange: VerseRange
    let verseText: String
    let onClose: () -> Void

    @State private var isLoading = true
    @State private var clarification: PhraseClarificationOutput?

    private let aiService: AIServiceProtocol = OpenAIProvider.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // The phrase being clarified
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Selected phrase")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)

                        Text("\"\(phrase)\"")
                            .font(Typography.Scripture.body())
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentGold)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                            )
                    }

                    Divider()

                    // Clarification content
                    if isLoading {
                        AILoadingView(message: "Getting clarification")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.xxxl)
                    } else if let output = clarification {
                        ClarificationContent(output: output)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Phrase Clarification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
        .task {
            await loadClarification()
        }
    }

    private func loadClarification() async {
        isLoading = true

        do {
            clarification = try await aiService.clarifyPhrase(
                phrase: phrase,
                verseRange: verseRange,
                verseText: verseText
            )
        } catch {
            clarification = PhraseClarificationOutput(
                clarification: "This phrase is significant in the context of the passage.",
                simpleVersion: "A key part of the verse.",
                whyItMatters: "Understanding this helps grasp the full meaning."
            )
        }

        isLoading = false
    }
}

struct ClarificationContent: View {
    let output: PhraseClarificationOutput

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Main clarification
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "text.magnifyingglass")
                        .foregroundStyle(Color.accentBlue)
                    Text("What it means")
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.accentBlue)
                }

                Text(output.clarification)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(4)
            }

            // Simple version
            if !output.simpleVersion.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(Color.accentGold)
                        Text("In simple terms")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.accentGold)
                    }

                    Text(output.simpleVersion)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(Color.surfaceBackground)
                        )
                }
            }

            // Why it matters
            if !output.whyItMatters.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.warning)
                        Text("Why it matters")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.warning)
                    }

                    Text(output.whyItMatters)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }
}

// MARK: - Phrase Clarification Popover

struct PhraseClarificationView: View {
    let phrase: String
    let verseRange: VerseRange
    let verseText: String

    @State private var isLoading = true
    @State private var clarification: PhraseClarificationOutput?

    private let aiService: AIServiceProtocol = OpenAIProvider.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Phrase being clarified
            HStack {
                Text("\"\(phrase)\"")
                    .font(Typography.UI.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryText)
                    .italic()
                Spacer()
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(AppTheme.Scale.reduced)
                    Text("Clarifying...")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                }
            } else if let output = clarification {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    // Clarification
                    Text(output.clarification)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)

                    // Simple version
                    if !output.simpleVersion.isEmpty {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "text.bubble")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.accentGold)
                            Text("Simply put: \(output.simpleVersion)")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }

                    // Why it matters
                    if !output.whyItMatters.isEmpty {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "lightbulb")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.info)
                            Text(output.whyItMatters)
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 8, y: 4)
        .task {
            await loadClarification()
        }
    }

    private func loadClarification() async {
        isLoading = true

        do {
            clarification = try await aiService.clarifyPhrase(
                phrase: phrase,
                verseRange: verseRange,
                verseText: verseText
            )
        } catch {
            // Fallback
            clarification = PhraseClarificationOutput(
                clarification: "This phrase refers to the key action or concept in the verse.",
                simpleVersion: "A simpler way to say this.",
                whyItMatters: "This is significant because it reveals an important truth."
            )
        }

        isLoading = false
    }
}

// MARK: - Previews

#Preview("Simplify Passage") {
    SimplifyPassageView(
        verseRange: .genesis1_1,
        verseText: "In the beginning God created the heaven and the earth.",
        onClose: {}
    )
}

#Preview("Comprehension Questions") {
    ComprehensionQuestionsView(
        verseRange: .genesis1_1,
        verseText: "In the beginning God created the heaven and the earth.",
        onClose: {}
    )
}

#Preview("Phrase Clarification") {
    PhraseClarificationView(
        phrase: "In the beginning",
        verseRange: .genesis1_1,
        verseText: "In the beginning God created the heaven and the earth."
    )
    .padding()
    .background(Color.appBackground)
}
