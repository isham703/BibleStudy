import Foundation

// MARK: - Topic Service
// Manages topics and semantic search

@MainActor
@Observable
final class TopicService {
    // MARK: - Singleton
    static let shared = TopicService()

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared

    // MARK: - State
    var topics: [Topic] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - Fetch Topics

    func loadTopics() async {
        isLoading = true
        error = nil

        do {
            let dtos = try await supabase.getTopics()
            topics = dtos.map { Topic(from: $0) }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func getTopLevelTopics() -> [Topic] {
        topics.filter { $0.isTopLevel }
    }

    func getSubtopics(of parent: Topic) -> [Topic] {
        // Would query topic_edges table
        topics.filter { $0.level > parent.level }
    }

    // MARK: - Semantic Search

    func searchTopics(query: String) async throws -> [TopicSearchResult] {
        // In production: generate embedding and search
        // For now, use simple text matching
        let lowercaseQuery = query.lowercased()

        return topics
            .filter { topic in
                topic.name.lowercased().contains(lowercaseQuery) ||
                (topic.description?.lowercased().contains(lowercaseQuery) ?? false)
            }
            .map { TopicSearchResult(topic: $0, similarity: 0.8) }
    }

    func searchTopicsWithEmbedding(embedding: [Float]) async throws -> [TopicSearchResult] {
        // TODO: Re-enable once Swift 6 Sendable issues with Supabase RPC are resolved
        // let dtos = try await supabase.searchTopics(embedding: embedding, limit: 10)
        // return dtos.map { dto in
        //     TopicSearchResult(topic: Topic(from: dto), similarity: 0.9)
        // }

        // For now, return empty results - vector search requires the RPC function
        return []
    }

    // MARK: - Sample Data

    func getSampleTopics() -> [Topic] {
        [
            Topic(slug: "salvation", name: "Salvation", description: "God's plan to redeem humanity through faith", level: 0),
            Topic(slug: "faith", name: "Faith", description: "Trust and belief in God", level: 0),
            Topic(slug: "love", name: "Love", description: "God's love and how we should love others", level: 0),
            Topic(slug: "prayer", name: "Prayer", description: "Communication with God", level: 0),
            Topic(slug: "wisdom", name: "Wisdom", description: "Divine wisdom and understanding", level: 0),
            Topic(slug: "forgiveness", name: "Forgiveness", description: "God's forgiveness and forgiving others", level: 0),
            Topic(slug: "holy-spirit", name: "Holy Spirit", description: "The third person of the Trinity", level: 0),
            Topic(slug: "creation", name: "Creation", description: "God as creator of all things", level: 0),
            Topic(slug: "grace", name: "Grace", description: "Unmerited favor from God", level: 1),
            Topic(slug: "redemption", name: "Redemption", description: "Being bought back from sin", level: 1),
            Topic(slug: "hope", name: "Hope", description: "Confident expectation in God's promises", level: 1),
            Topic(slug: "worship", name: "Worship", description: "Honoring and praising God", level: 1)
        ]
    }

    func getSampleTopicVerses(for topic: Topic) -> [TopicVerse] {
        switch topic.slug {
        case "salvation":
            return [
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 43, chapter: 3, verseStart: 16, verseEnd: 16, relevanceScore: 1.0),
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 45, chapter: 10, verseStart: 9, verseEnd: 10, relevanceScore: 0.95),
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 49, chapter: 2, verseStart: 8, verseEnd: 9, relevanceScore: 0.9)
            ]
        case "creation":
            return [
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 1, chapter: 1, verseStart: 1, verseEnd: 1, relevanceScore: 1.0),
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 1, chapter: 1, verseStart: 27, verseEnd: 27, relevanceScore: 0.9),
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 43, chapter: 1, verseStart: 3, verseEnd: 3, relevanceScore: 0.85)
            ]
        case "love":
            return [
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 62, chapter: 4, verseStart: 8, verseEnd: 8, relevanceScore: 1.0),
                TopicVerse(id: UUID(), topicId: topic.id, bookId: 43, chapter: 3, verseStart: 16, verseEnd: 16, relevanceScore: 0.95)
            ]
        default:
            return []
        }
    }
}
