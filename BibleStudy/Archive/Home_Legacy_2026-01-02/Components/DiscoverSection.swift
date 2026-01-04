import SwiftUI

// MARK: - Discover Section
// Horizontal carousel of Stories and Topics for exploration

struct DiscoverSection: View {
    let stories: [Story]
    let topics: [Topic]
    let onStoryTap: (Story) -> Void
    let onTopicTap: (Topic) -> Void
    let onSeeAllStories: () -> Void
    let onSeeAllTopics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Section header
            HomeSectionHeader(title: "Discover", onSeeAll: onSeeAllStories)

            // Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    // Stories
                    ForEach(stories.prefix(5)) { story in
                        Button {
                            onStoryTap(story)
                        } label: {
                            CompactStoryCard(story: story)
                        }
                        .buttonStyle(.plain)
                    }

                    // Topics
                    ForEach(topics.prefix(4)) { topic in
                        Button {
                            onTopicTap(topic)
                        } label: {
                            CompactTopicCard(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .padding(.horizontal, -AppTheme.Spacing.md)
        }
    }
}

// MARK: - Home Section Header
// Reusable section header for Home screen with optional "See All" action

struct HomeSectionHeader: View {
    let title: String
    let onSeeAll: (() -> Void)?

    init(title: String, onSeeAll: (() -> Void)? = nil) {
        self.title = title
        self.onSeeAll = onSeeAll
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            // Title with decorative first letter
            Text(title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Spacer()

            if let onSeeAll = onSeeAll {
                Button(action: onSeeAll) {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Text("See All")
                            .font(Typography.UI.subheadline)
                        Image(systemName: "arrow.right")
                            .font(Typography.UI.caption1)
                    }
                    .foregroundStyle(Color.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Compact Story Card

struct CompactStoryCard: View {
    let story: Story

    private var typeColor: Color {
        switch story.type {
        case .narrative:
            return .accentGold
        case .character:
            return .lapisLazuli
        case .thematic:
            return .amethyst
        case .parable:
            return .malachite
        case .prophecy:
            return .vermillion
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Type badge
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "book.pages")
                    .font(Typography.UI.iconXxs)
                Text("Story")
                    .font(Typography.UI.caption2)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundStyle(typeColor)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(typeColor.opacity(AppTheme.Opacity.subtle + 0.02))
            )

            Spacer()

            // Title
            Text(story.title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Subtitle
            if let subtitle = story.subtitle {
                Text(subtitle)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
            }

            // Reading time
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "clock")
                    .font(Typography.UI.iconXxs)
                Text("\(story.estimatedMinutes) min")
                    .font(Typography.UI.caption2.monospacedDigit())
            }
            .foregroundStyle(Color.tertiaryText)
        }
        .padding(AppTheme.Spacing.md)
        .frame(width: 160, height: 180)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Compact Topic Card

struct CompactTopicCard: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Type badge
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "tag")
                    .font(Typography.UI.iconXxs)
                Text("Topic")
                    .font(Typography.UI.caption2)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundStyle(Color.lapisLazuli)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(Color.lapisLazuli.opacity(AppTheme.Opacity.subtle + 0.02))
            )

            Spacer()

            // Name
            Text(topic.name)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description
            if let description = topic.description {
                Text(description)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(width: 160, height: 180)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("Discover Section") {
    let sampleStories = [
        Story(
            slug: "creation",
            title: "The Creation",
            subtitle: "Genesis 1-2",
            description: "In the beginning...",
            type: .narrative,
            readingLevel: .adult,
            verseAnchors: [VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 31)],
            estimatedMinutes: 12
        ),
        Story(
            slug: "exodus",
            title: "The Exodus",
            subtitle: "Exodus 1-15",
            description: "Moses leads Israel",
            type: .narrative,
            readingLevel: .adult,
            verseAnchors: [VerseRange(bookId: 2, chapter: 1, verseStart: 1, verseEnd: 22)],
            estimatedMinutes: 15
        )
    ]

    let sampleTopics = [
        Topic(slug: "faith", name: "Faith", description: "Trusting God's promises"),
        Topic(slug: "grace", name: "Grace", description: "Unmerited divine favor")
    ]

    DiscoverSection(
        stories: sampleStories,
        topics: sampleTopics,
        onStoryTap: { _ in },
        onTopicTap: { _ in },
        onSeeAllStories: {},
        onSeeAllTopics: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Compact Story Card") {
    CompactStoryCard(
        story: Story(
            slug: "david-goliath",
            title: "David & Goliath",
            subtitle: "1 Samuel 17",
            description: "Faith conquers giants",
            type: .character,
            readingLevel: .adult,
            verseAnchors: [VerseRange(bookId: 9, chapter: 17, verseStart: 1, verseEnd: 58)],
            estimatedMinutes: 8
        )
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Compact Topic Card") {
    CompactTopicCard(
        topic: Topic(
            slug: "redemption",
            name: "Redemption",
            description: "God's plan to restore humanity"
        )
    )
    .padding()
    .background(Color.appBackground)
}
