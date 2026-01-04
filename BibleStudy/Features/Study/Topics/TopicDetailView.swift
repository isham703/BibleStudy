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
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
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
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(description)
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
        }
    }

    // MARK: - Key Passages Section
    private var keyPassagesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Key Passages")
                .font(Typography.Display.headline)
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Related Topics")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Subtopics")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(verse.reference)
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.accentGold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }

            if let text = verseText {
                Text(text)
                    .font(Typography.Scripture.body())
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
    }
}

// MARK: - Topic Chip
struct TopicChip: View {
    let topic: Topic

    var body: some View {
        Text(topic.name)
            .font(Typography.UI.caption1Bold)
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.secondaryBackground)
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
