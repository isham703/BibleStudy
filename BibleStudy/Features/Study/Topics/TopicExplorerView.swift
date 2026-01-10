import SwiftUI

// MARK: - Topic Explorer View
// Browse and search biblical topics

struct TopicExplorerView: View {
    @State private var viewModel = TopicExplorerViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading topics...")
            } else if viewModel.topics.isEmpty {
                EmptyStateView.noTopics
            } else {
                topicsGrid
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search topics")
        .task {
            await viewModel.load()
        }
        .navigationDestination(for: Topic.self) { topic in
            TopicDetailView(topic: topic)
        }
    }

    // MARK: - Topics Grid
    private var topicsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Theme.Spacing.md
            ) {
                ForEach(viewModel.filteredTopics) { topic in
                    NavigationLink(value: topic) {
                        TopicCard(topic: topic, verseCount: viewModel.getVerseCount(for: topic))
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
    }
}

// MARK: - Topic Card
struct TopicCard: View {
    let topic: Topic
    let verseCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(topic.name)
                .font(Typography.Command.headline)
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)

            if let description = topic.description {
                Text(description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            HStack {
                Image(systemName: "book.closed")
                    .font(Typography.Command.caption)
                Text("\(verseCount) verses")
                    .font(Typography.Command.meta.monospacedDigit())
            }
            .foregroundStyle(Color.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - Topic Explorer View Model
@Observable
@MainActor
final class TopicExplorerViewModel {
    // MARK: - Dependencies
    private let topicService = TopicService.shared

    // MARK: - State
    var topics: [Topic] = []
    var isLoading: Bool = false
    var searchText: String = ""

    // MARK: - Computed Properties
    var filteredTopics: [Topic] {
        if searchText.isEmpty {
            return topics.filter { $0.isTopLevel }
        }

        let query = searchText.lowercased()
        return topics.filter { topic in
            topic.name.lowercased().contains(query) ||
            (topic.description?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Loading
    func load() async {
        isLoading = true

        await topicService.loadTopics()

        if topicService.topics.isEmpty {
            // Use sample data for development
            topics = topicService.getSampleTopics()
        } else {
            topics = topicService.topics
        }

        isLoading = false
    }

    func getVerseCount(for topic: Topic) -> Int {
        // Would query topic_verses
        topicService.getSampleTopicVerses(for: topic).count
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TopicExplorerView()
            .navigationTitle("Topics")
    }
}
