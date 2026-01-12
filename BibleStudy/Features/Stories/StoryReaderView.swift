import SwiftUI

// MARK: - Story Reader View
// Full-screen story reading experience with timeline navigation

struct StoryReaderView: View {
    let story: Story
    @State private var viewModel: StoryReaderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showVerseSheet = false
    @State private var selectedVerseRange: VerseRange?
    @State private var showStoryInfo = false

    init(story: Story) {
        self.story = story
        self._viewModel = State(initialValue: StoryReaderViewModel(story: story))
    }

    var body: some View {
        VStack(spacing: 0) {
            // AI-generated content disclaimer
            if story.generationMode == .ai {
                AIDisclaimerBanner()
            }

            // Timeline
            TimelineView(
                segments: viewModel.segments,
                currentIndex: viewModel.currentIndex,
                completedIndices: viewModel.completedIndices,
                onSegmentTap: { index in
                    viewModel.goToSegment(index)
                }
            )
            .background(Color("AppSurface"))

            Divider()

            // Content area with gesture navigation
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { index, segment in
                    SegmentContentView(
                        segment: segment,
                        onVerseAnchorTap: { range in
                            selectedVerseRange = range
                            showVerseSheet = true
                        },
                        existingReflection: viewModel.getReflection(for: segment.id),
                        onSaveReflection: { text in
                            viewModel.saveReflection(text, for: segment.id)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.appBackground)

            // Navigation bar
            SegmentNavigationBar(
                currentIndex: viewModel.currentIndex,
                totalSegments: viewModel.segments.count,
                onPrevious: viewModel.previousSegment,
                onNext: viewModel.nextSegment,
                onComplete: {
                    viewModel.markCurrentAsComplete()
                    if viewModel.isComplete {
                        dismiss()
                    } else {
                        viewModel.nextSegment()
                    }
                }
            )
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showStoryInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showVerseSheet) {
            if let range = selectedVerseRange {
                VersePreviewSheet(verseRange: range)
                    .environment(BibleService.shared)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showStoryInfo) {
            StoryInfoSheet(story: story)
                .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadProgress()
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Story Reader View Model
@Observable
@MainActor
final class StoryReaderViewModel {
    // MARK: - Dependencies
    private let storyService = StoryService.shared

    // MARK: - State
    let story: Story
    var segments: [StorySegment] = []
    var currentIndex: Int = 0
    var completedIndices: Set<Int> = []
    var progress: StoryProgress?

    // MARK: - Computed
    var isComplete: Bool {
        completedIndices.count >= segments.count
    }

    var currentSegment: StorySegment? {
        guard currentIndex >= 0 && currentIndex < segments.count else { return nil }
        return segments[currentIndex]
    }

    // MARK: - Initialization
    init(story: Story) {
        self.story = story
        self.segments = story.segments
    }

    // MARK: - Loading
    func loadProgress() async {
        do {
            // Try to get or create progress
            if let existing = storyService.progressMap[story.id] {
                self.progress = existing
                self.currentIndex = existing.currentSegmentIndex
                // Map completed segment IDs to indices
                for (index, segment) in segments.enumerated() {
                    if existing.completedSegmentIds.contains(segment.id) {
                        completedIndices.insert(index)
                    }
                }
            } else {
                // Start new progress
                let newProgress = try await storyService.startStory(story)
                self.progress = newProgress
            }
        } catch {
            print("Failed to load story progress: \(error)")
        }
    }

    // MARK: - Navigation
    func goToSegment(_ index: Int) {
        guard index >= 0 && index < segments.count else { return }
        withAnimation(Theme.Animation.settle) {
            currentIndex = index
        }
        updateProgress()
    }

    func previousSegment() {
        goToSegment(currentIndex - 1)
    }

    func nextSegment() {
        goToSegment(currentIndex + 1)
    }

    func markCurrentAsComplete() {
        completedIndices.insert(currentIndex)
        Task {
            guard let segment = currentSegment else { return }
            try? await storyService.completeSegment(segmentId: segment.id, in: story.id)
        }
    }

    private func updateProgress() {
        guard var progress = progress else { return }
        progress.currentSegmentIndex = currentIndex
        progress.lastReadAt = Date()
        self.progress = progress
        // Persist progress update
        Task {
            try? await storyService.updateProgress(progress)
        }
    }

    // MARK: - Reflections

    func getReflection(for segmentId: UUID) -> String? {
        progress?.reflectionNotes[segmentId]
    }

    func saveReflection(_ text: String, for segmentId: UUID) {
        Task {
            try? await storyService.saveReflection(text, for: segmentId, in: story.id)
            // Update local progress
            if var progress = progress {
                progress.reflectionNotes[segmentId] = text
                self.progress = progress
            }
        }
    }
}

// MARK: - AI Disclaimer Banner
struct AIDisclaimerBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(Typography.Command.caption)

            Text("Narrative retelling (AI-generated)")
                .font(Typography.Command.caption)

            Spacer()

            Image(systemName: "info.circle")
                .font(Typography.Command.caption)
        }
        .foregroundStyle(Color("AppAccentAction"))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
    }
}

// MARK: - Segment Navigation Bar
struct SegmentNavigationBar: View {
    let currentIndex: Int
    let totalSegments: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onComplete: () -> Void

    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex >= totalSegments - 1 }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Previous button
            Button(action: onPrevious) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(Typography.Command.subheadline)
            }
            .disabled(isFirst)
            .opacity(isFirst ? 0.4 : 1)

            Spacer()

            // Progress indicator
            Text("\(currentIndex + 1) of \(totalSegments)")
                .font(Typography.Command.caption.monospacedDigit())
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()

            // Next/Complete button
            if isLast {
                Button(action: onComplete) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Complete")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(Typography.Command.subheadline)
                    .fontWeight(.semibold)
                }
                .tint(Color("FeedbackSuccess"))
            } else {
                Button(action: onNext) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(Typography.Command.subheadline)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Color("AppSurface"))
        .overlay(
            Divider(),
            alignment: .top
        )
    }
}

// MARK: - Story Info Sheet
struct StoryInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let story: Story

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Description
                    Text(story.description)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Divider()

                    // Metadata
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        InfoRow(label: "Type", value: story.type.displayName)
                        InfoRow(label: "Reading Level", value: story.readingLevel.displayName)
                        InfoRow(label: "Duration", value: "\(story.estimatedMinutes) minutes", useMonospacedDigits: true)
                        InfoRow(label: "Segments", value: "\(story.segments.count)", useMonospacedDigits: true)

                        if story.generationMode == .ai {
                            Divider()

                            // Provenance for AI stories
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Generation Info")
                                    .font(Typography.Scripture.heading)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                if let modelId = story.modelId {
                                    InfoRow(label: "Model", value: modelId)
                                }
                                if let date = story.generatedAt {
                                    InfoRow(label: "Generated", value: date.formatted(date: .abbreviated, time: .omitted))
                                }

                                Text("This story is an AI-generated retelling based on the source scripture. Always refer to the original text for authoritative guidance.")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .padding(.top, Theme.Spacing.xs)
                            }
                        }
                    }

                    // Source verses
                    if !story.verseAnchors.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Source Scripture")
                                .font(Typography.Scripture.heading)
                                .foregroundStyle(Color("AppTextPrimary"))

                            ForEach(story.verseAnchors, id: \.id) { anchor in
                                Text(anchor.reference)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppAccentAction"))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("About This Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    var useMonospacedDigits: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .font(useMonospacedDigits ? Typography.Command.body.monospacedDigit() : Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StoryReaderView(
            story: Story(
                slug: "creation",
                title: "The Creation Story",
                subtitle: "Genesis 1-2",
                description: "Experience the wonder of God speaking the universe into existence.",
                type: .narrative,
                readingLevel: .adult,
                isPrebuilt: true,
                verseAnchors: [
                    VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 31)
                ],
                estimatedMinutes: 12,
                generationMode: .ai,
                modelId: "gpt-4o",
                generatedAt: Date(),
                segments: [
                    StorySegment(
                        storyId: UUID(),
                        order: 1,
                        title: "In the Beginning",
                        content: "Before time itself began...",
                        timelineLabel: "Day 1",
                        mood: .peaceful
                    ),
                    StorySegment(
                        storyId: UUID(),
                        order: 2,
                        title: "Waters Above and Below",
                        content: "On the second day...",
                        timelineLabel: "Day 2",
                        mood: .peaceful
                    )
                ]
            )
        )
    }
}
