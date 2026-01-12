import SwiftUI

// MARK: - Story Card
// Card component for story grid display

struct StoryCard: View {
    let story: Story
    let progress: StoryProgress?

    @Environment(\.colorScheme) private var colorScheme

    private var isInProgress: Bool {
        guard let progress = progress else { return false }
        return progress.isStarted && !progress.isCompleted
    }

    private var isCompleted: Bool {
        progress?.isCompleted ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Subtitle (e.g., "Genesis 1-2")
            if let subtitle = story.subtitle {
                Text(subtitle)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))
                    .lineLimit(1)
            }

            // Description
            Text(story.description)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: Theme.Spacing.sm)

            // Footer with metadata and progress
            HStack {
                // Duration or progress text
                if let progress = progress, isInProgress, !story.segments.isEmpty {
                    let percent = Int(progress.progressPercentage(totalSegments: story.segments.count) * 100)
                    Text("\(percent)% complete")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color("AppAccentAction"))
                } else {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(Typography.Command.meta)
                        Text("\(story.estimatedMinutes) min")
                            .font(Typography.Command.meta.monospacedDigit())
                    }
                    .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()

                // Reading level indicator
                ReadingLevelBadge(level: story.readingLevel)
            }

            // Progress bar (if in progress)
            if let progress = progress, isInProgress, !story.segments.isEmpty {
                ProgressView(value: progress.progressPercentage(totalSegments: story.segments.count))
                    .tint(Color("AppAccentAction"))
                    .frame(height: 3)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(isCompleted ? Color("FeedbackSuccess").opacity(Theme.Opacity.textSecondary) : Color.clear, lineWidth: Theme.Stroke.control)
        )
        .shadow(color: .black.opacity(Theme.Opacity.overlay), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Continue Badge
struct ContinueBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "play.fill")
                .font(Typography.Command.meta)
            Text("Continue")
                .font(Typography.Command.meta)
        }
        .foregroundStyle(Color("AppAccentAction"))
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
        )
    }
}

// MARK: - Completed Badge
struct CompletedBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.Command.meta)
            Text("Done")
                .font(Typography.Command.meta)
        }
        .foregroundStyle(Color("FeedbackSuccess"))
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color("FeedbackSuccess").opacity(Theme.Opacity.selectionBackground))
        )
    }
}

// MARK: - Story Type Badge
struct StoryTypeBadge: View {
    let type: StoryType

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: type.icon)
                .font(Typography.Command.meta)
            Text(type.displayName)
                .font(Typography.Command.meta)
        }
        .foregroundStyle(type.storyColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(type.storyColor.opacity(Theme.Opacity.selectionBackground))
        )
    }
}

// MARK: - Reading Level Badge
struct ReadingLevelBadge: View {
    let level: StoryReadingLevel

    var body: some View {
        Text(level.shortLabel)
            .font(Typography.Command.meta)
            .foregroundStyle(Color("AppTextSecondary"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
    }
}

// MARK: - AI Generated Badge
struct AIGeneratedBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "sparkles")
                .font(Typography.Command.meta)
            Text("AI")
                .font(Typography.Command.meta)
        }
        .foregroundStyle(Color("AppAccentAction"))
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
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
        spacing: Theme.Spacing.md
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
