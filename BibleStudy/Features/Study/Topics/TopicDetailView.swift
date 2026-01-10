import SwiftUI

// MARK: - Topic Detail View
// Shows topic details with related verses

struct TopicDetailView: View {
    let topic: Topic
    @State private var viewModel: TopicDetailViewModel

    init(topic: Topic) {
        self.topic = topic
        _viewModel = State(initialValue: TopicDetailViewModel(topic: topic))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Description
                if let description = topic.description {
                    descriptionSection(description)
                }

                // Key Passages
                if !viewModel.verses.isEmpty {
                    keyPassagesSection
                }

                // Related Topics
                if !viewModel.relatedTopics.isEmpty {
                    relatedTopicsSection
                }

                // Subtopics
                if !viewModel.subtopics.isEmpty {
                    subtopicsSection
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(description)
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
        }
    }

    // MARK: - Key Passages Section
    private var keyPassagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Key Passages")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            ForEach(viewModel.verses) { verse in
                TopicVerseCard(
                    verse: verse,
                    verseText: viewModel.getVerseText(for: verse)
                )
            }
        }
    }

    // MARK: - Related Topics Section
    private var relatedTopicsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Related Topics")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.relatedTopics) { related in
                        NavigationLink(value: related) {
                            TopicChip(topic: related)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subtopics Section
    private var subtopicsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Subtopics")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.subtopics) { subtopic in
                        NavigationLink(value: subtopic) {
                            TopicChip(topic: subtopic)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Topic Verse Card
struct TopicVerseCard: View {
    let verse: TopicVerse
    let verseText: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(verse.reference)
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }

            if let text = verseText {
                Text(text)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - Topic Chip
struct TopicChip: View {
    let topic: Topic

    var body: some View {
        Text(topic.name)
            .font(Typography.Command.caption.weight(.semibold))
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.surfaceRaised)
            .clipShape(Capsule())
    }
}

// MARK: - Topic Detail View Model
@Observable
@MainActor
final class TopicDetailViewModel {
    // MARK: - Dependencies
    private let topicService = TopicService.shared
    private let bibleService = BibleService.shared

    // MARK: - State
    let topic: Topic
    var verses: [TopicVerse] = []
    var relatedTopics: [Topic] = []
    var subtopics: [Topic] = []
    var verseTexts: [UUID: String] = [:]
    var isLoading: Bool = false

    // MARK: - Initialization
    init(topic: Topic) {
        self.topic = topic
    }

    // MARK: - Loading
    func load() async {
        isLoading = true

        // Load sample data for development
        verses = topicService.getSampleTopicVerses(for: topic)

        // Load related topics
        let allTopics = topicService.getSampleTopics()
        relatedTopics = allTopics.filter { $0.level == topic.level && $0.id != topic.id }.prefix(4).map { $0 }
        subtopics = allTopics.filter { $0.level > topic.level }.prefix(3).map { $0 }

        // Load verse texts
        for verse in verses {
            if let verseData = try? await bibleService.getVerses(range: verse.range) {
                verseTexts[verse.id] = verseData.map { $0.text }.joined(separator: " ")
            }
        }

        isLoading = false
    }

    func getVerseText(for verse: TopicVerse) -> String? {
        verseTexts[verse.id]
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TopicDetailView(topic: Topic(
            slug: "salvation",
            name: "Salvation",
            description: "God's plan to redeem humanity through faith in Jesus Christ.",
            level: 0
        ))
    }
}
