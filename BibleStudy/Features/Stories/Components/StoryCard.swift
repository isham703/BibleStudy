import SwiftUI

// MARK: - Story Card
// Card component for story grid display

struct StoryCard: View {
    let story: Story
    let progress: StoryProgress?

    private var isInProgress: Bool {
        guard let progress = progress else { return false }
        return progress.isStarted && !progress.isCompleted
    }

    private var isCompleted: Bool {
        progress?.isCompleted ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with type badge and status
            HStack {
                StoryTypeBadge(type: story.type)
                Spacer()
                if isCompleted {
                    CompletedBadge()
                } else if isInProgress {
                    ContinueBadge()
                } else if story.generationMode == .ai {
                    AIGeneratedBadge()
                }
            }

            // Title
            Text(story.title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Subtitle (e.g., "Genesis 1-2")
            if let subtitle = story.subtitle {
                Text(subtitle)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.scholarAccent)
                    .lineLimit(1)
            }

            // Description
            Text(story.description)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: AppTheme.Spacing.sm)

            // Footer with metadata and progress
            HStack {
                // Duration or progress text
                if let progress = progress, isInProgress, !story.segments.isEmpty {
                    let percent = Int(progress.progressPercentage(totalSegments: story.segments.count) * 100)
                    Text("\(percent)% complete")
                        .font(Typography.UI.caption2.monospacedDigit())
                        .foregroundStyle(Color.scholarAccent)
                } else {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(Typography.UI.caption2)
                        Text("\(story.estimatedMinutes) min")
                            .font(Typography.UI.caption2.monospacedDigit())
                    }
                    .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                // Reading level indicator
                ReadingLevelBadge(level: story.readingLevel)
            }

            // Progress bar (if in progress)
            if let progress = progress, isInProgress, !story.segments.isEmpty {
                ProgressView(value: progress.progressPercentage(totalSegments: story.segments.count))
                    .tint(Color.scholarAccent)
                    .frame(height: AppTheme.Divider.thick)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(isCompleted ? Color.highlightGreen.opacity(AppTheme.Opacity.heavy) : Color.clear, lineWidth: AppTheme.Border.regular)
        )
        .shadow(AppTheme.Shadow.small)
    }
}

// MARK: - Continue Badge
struct ContinueBadge: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "play.fill")
                .font(Typography.UI.caption2)
            Text("Continue")
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(Color.scholarAccent)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.scholarAccent.opacity(AppTheme.Opacity.light))
        )
    }
}

// MARK: - Completed Badge
struct CompletedBadge: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.UI.caption2)
            Text("Done")
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(Color.highlightGreen)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.highlightGreen.opacity(AppTheme.Opacity.light))
        )
    }
}

// MARK: - Story Type Badge
struct StoryTypeBadge: View {
    let type: StoryType

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: type.icon)
                .font(Typography.UI.caption2)
            Text(type.displayName)
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(type.storyColor)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(type.storyColor.opacity(AppTheme.Opacity.light))
        )
    }
}

// MARK: - Reading Level Badge
struct ReadingLevelBadge: View {
    let level: StoryReadingLevel

    var body: some View {
        Text(level.shortLabel)
            .font(Typography.UI.caption2)
            .foregroundStyle(Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - AI Generated Badge
struct AIGeneratedBadge: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "sparkles")
                .font(Typography.UI.caption2)
            Text("AI")
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(Color.accentBlue)
        .padding(.horizontal, AppTheme.Spacing.xs)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.accentBlue.opacity(AppTheme.Opacity.light))
        )
    }
}

// MARK: - Story Type Color Helper
extension StoryType {
    var storyColor: Color {
        Color(self.color)
    }
}

// MARK: - Preview
#Preview {
    LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: AppTheme.Spacing.md
    ) {
        StoryCard(
            story: Story(
                slug: "creation",
                title: "The Creation Story",
                subtitle: "Genesis 1-2",
                description: "Experience the wonder of God speaking the universe into existence.",
                type: .narrative,
                readingLevel: .adult,
                isPrebuilt: true,
                verseAnchors: [],
                estimatedMinutes: 12,
                generationMode: .prebuilt
            ),
            progress: nil
        )

        StoryCard(
            story: Story(
                slug: "prodigal",
                title: "The Prodigal Son",
                subtitle: "Luke 15:11-32",
                description: "A father's love for his wayward son.",
                type: .parable,
                readingLevel: .teen,
                isPrebuilt: true,
                verseAnchors: [],
                estimatedMinutes: 8,
                generationMode: .ai,
                modelId: "gpt-4o"
            ),
            progress: StoryProgress(
                userId: UUID(),
                storyId: UUID(),
                currentSegmentIndex: 2,
                completedSegmentIds: [UUID(), UUID()]
            )
        )
    }
    .padding()
    .background(Color.appBackground)
}
