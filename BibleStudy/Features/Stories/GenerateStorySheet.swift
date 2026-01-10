import SwiftUI

// MARK: - Generate Story Sheet
// UI for generating custom AI stories from selected passages

struct GenerateStorySheet: View {
    let verseRange: VerseRange
    let verseText: String
    let onStoryGenerated: (Story) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: GenerateStoryViewModel

    init(
        verseRange: VerseRange,
        verseText: String,
        onStoryGenerated: @escaping (Story) -> Void
    ) {
        self.verseRange = verseRange
        self.verseText = verseText
        self.onStoryGenerated = onStoryGenerated
        self._viewModel = State(initialValue: GenerateStoryViewModel(
            verseRange: verseRange,
            verseText: verseText
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Passage preview
                    passagePreview

                    // Story type selection
                    storyTypeSection

                    // Reading level selection
                    readingLevelSection

                    // Generate button
                    generateButton

                    // Error display
                    if let error = viewModel.error {
                        errorView(error)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if viewModel.isGenerating {
                    generatingOverlay
                }
            }
        }
    }

    // MARK: - Passage Preview

    private var passagePreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(verseRange.reference)
                .font(Typography.Command.headline)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Text(verseText)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.primaryText)
                .lineLimit(4)

            if verseText.count > 200 {
                Text("...")
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }

    // MARK: - Story Type Section

    private var storyTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Story Type")
                .font(Typography.Command.headline)
                .foregroundStyle(Color.primaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                ForEach(StoryType.allCases, id: \.self) { type in
                    StoryTypeOption(
                        type: type,
                        isSelected: viewModel.selectedType == type,
                        action: { viewModel.selectedType = type }
                    )
                }
            }
        }
    }

    // MARK: - Reading Level Section

    private var readingLevelSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Reading Level")
                    .font(Typography.Command.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button {
                    viewModel.showLevelInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.secondaryText)
                }
            }

            StoryReadingLevelPicker(selectedLevel: $viewModel.selectedLevel)
        }
        .sheet(isPresented: $viewModel.showLevelInfo) {
            StoryReadingLevelInfoSheet()
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task {
                if let story = await viewModel.generateStory() {
                    onStoryGenerated(story)
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                Text("Generate Story")
            }
            .font(Typography.Command.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(viewModel.isGenerating)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.error)

            Text(error.localizedDescription)
                .font(Typography.Command.caption)
                .foregroundStyle(Color.error)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.error.opacity(Theme.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(Theme.Opacity.heavy)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.05)
                    .tint(.white)

                Text("Generating your story...")
                    .font(Typography.Command.headline)
                    .foregroundStyle(.white)

                Text("This may take a moment")
                    .font(Typography.Command.caption)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
            }
            .padding(Theme.Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }
}

// MARK: - Story Type Option

struct StoryTypeOption: View {
    let type: StoryType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: type.icon)
                    .font(Typography.Command.title2)

                Text(type.displayName)
                    .font(Typography.Command.caption.weight(.semibold))

                Text(type.storyTypeDescription)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color(type.color).opacity(Theme.Opacity.light) : Color.surfaceBackground)
            .foregroundStyle(isSelected ? Color(type.color) : Color.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(isSelected ? Color(type.color) : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.fade, value: isSelected)
    }
}

// MARK: - Generate Story View Model

@Observable
@MainActor
final class GenerateStoryViewModel {
    // Input
    let verseRange: VerseRange
    let verseText: String

    // State
    var selectedType: StoryType = .narrative
    var selectedLevel: StoryReadingLevel = .adult
    var isGenerating = false
    var error: Error?
    var showLevelInfo = false

    // Dependencies
    private let aiProvider = OpenAIProvider.shared
    private let storyService = StoryService.shared
    private let storyCache = StoryCache.shared

    init(verseRange: VerseRange, verseText: String) {
        self.verseRange = verseRange
        self.verseText = verseText
    }

    func generateStory() async -> Story? {
        isGenerating = true
        error = nil

        do {
            // Check cache first
            if let cachedStory = storyCache.get(
                for: verseRange,
                level: selectedLevel,
                type: selectedType
            ) {
                isGenerating = false
                return cachedStory
            }

            let input = StoryGenerationInput(
                verseRange: verseRange,
                verseText: verseText,
                storyType: selectedType,
                readingLevel: selectedLevel
            )

            let output = try await aiProvider.generateStory(input: input)

            // Convert to Story model
            let story = output.toStory(
                verseAnchors: [verseRange],
                storyType: selectedType,
                readingLevel: selectedLevel,
                modelId: AppConfiguration.AI.advancedModel
            )

            // Cache the generated story
            storyCache.set(story, for: verseRange, level: selectedLevel, type: selectedType)

            // Save to database
            try await storyService.saveStory(story)

            isGenerating = false
            return story

        } catch {
            self.error = error
            isGenerating = false
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    GenerateStorySheet(
        verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 5),
        verseText: "In the beginning God created the heaven and the earth. And the earth was without form, and void; and darkness was upon the face of the deep.",
        onStoryGenerated: { _ in }
    )
}
