import SwiftUI

// MARK: - Story Explorer View
// Browse and discover biblical stories

struct StoryExplorerView: View {
    @State private var viewModel = StoryExplorerViewModel()
    @State private var showGenerateSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading stories...")
            } else if viewModel.stories.isEmpty {
                EmptyStateView(
                    icon: "book.pages",
                    title: "No Stories Yet",
                    message: "Biblical narrative cards will appear here. Start exploring to discover them."
                )
            } else {
                storiesContent
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search stories")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Stories Content
    private var storiesContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Filter bar
                filterBar

                // Featured story (if available)
                if let featured = viewModel.featuredStory {
                    FeaturedStoryCard(story: featured, progress: viewModel.getProgress(for: featured))
                }

                // Story grid
                storyGrid
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    StoryFilterChip(
                        label: "All",
                        isSelected: viewModel.selectedType == nil,
                        action: { viewModel.selectedType = nil }
                    )

                    ForEach(StoryType.allCases, id: \.self) { type in
                        StoryFilterChip(
                            label: type.displayName,
                            icon: type.icon,
                            isSelected: viewModel.selectedType == type,
                            action: { viewModel.selectedType = type }
                        )
                    }
                }
            }

            // Reading level selector
            StoryReadingLevelSelector(
                selectedLevel: $viewModel.selectedLevel,
                showAllOption: true,
                showAll: $viewModel.showAllLevels
            )
        }
    }

    // MARK: - Story Grid
    private var storyGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: AppTheme.Spacing.md
        ) {
            ForEach(viewModel.filteredStories) { story in
                NavigationLink(value: story) {
                    StoryCard(
                        story: story,
                        progress: viewModel.getProgress(for: story)
                    )
                }
            }
        }
    }
}

// MARK: - Story Explorer View Model
@Observable
@MainActor
final class StoryExplorerViewModel {
    // MARK: - Dependencies
    private let storyService = StoryService.shared

    // MARK: - State
    var stories: [Story] = []
    var isLoading = false
    var searchText = ""
    var selectedType: StoryType?
    var selectedLevel: StoryReadingLevel = .adult
    var showAllLevels = true

    // MARK: - Computed Properties
    var filteredStories: [Story] {
        var result = stories

        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { story in
                story.title.lowercased().contains(query) ||
                story.description.lowercased().contains(query) ||
                (story.subtitle?.lowercased().contains(query) ?? false)
            }
        }

        // Filter by type
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        // Filter by reading level
        if !showAllLevels {
            result = result.filter { $0.readingLevel == selectedLevel }
        }

        return result
    }

    var featuredStory: Story? {
        // Return a story in progress, or the first prebuilt story
        if let inProgress = stories.first(where: { story in
            storyService.progressMap[story.id] != nil &&
            storyService.progressMap[story.id]?.completedAt == nil
        }) {
            return inProgress
        }
        return nil
    }

    // MARK: - Loading
    func load() async {
        isLoading = true

        await storyService.loadStories()
        stories = storyService.prebuiltStories

        isLoading = false
    }

    func getProgress(for story: Story) -> StoryProgress? {
        storyService.progressMap[story.id]
    }
}

// MARK: - Story Filter Chip
struct StoryFilterChip: View {
    let label: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Typography.UI.caption1)
                }
                Text(label)
                    .font(Typography.UI.chipLabel)
            }
            .foregroundStyle(isSelected ? .white : Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.scholarAccent : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.quick, value: isSelected)
    }
}

// MARK: - Featured Story Card
struct FeaturedStoryCard: View {
    let story: Story
    let progress: StoryProgress?

    var body: some View {
        NavigationLink(value: story) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(progress != nil ? "Continue Reading" : "Featured Story")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.scholarAccent)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        Text(story.title)
                            .font(Typography.Display.title3)
                            .foregroundStyle(Color.primaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.scholarAccent)
                }

                // Subtitle
                if let subtitle = story.subtitle {
                    Text(subtitle)
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.scholarAccent)
                }

                // Description
                Text(story.description)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)

                // Progress (if started)
                if let progress = progress, !story.segments.isEmpty {
                    let percentage = progress.progressPercentage(totalSegments: story.segments.count)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Text("\(Int(percentage * 100))% complete")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                            Spacer()
                        }
                        ProgressView(value: percentage)
                            .tint(Color.scholarAccent)
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.scholarAccent.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StoryExplorerView()
            .navigationTitle("Stories")
    }
}
