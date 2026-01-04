import Foundation

// MARK: - Topic
// Represents a biblical topic or theme

struct Topic: Identifiable, Codable, Hashable {
    let id: UUID
    let slug: String
    let name: String
    let description: String?
    let level: Int

    var isTopLevel: Bool { level == 0 }

    init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        description: String? = nil,
        level: Int = 0
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.description = description
        self.level = level
    }

    init(from dto: TopicDTO) {
        self.id = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.description = dto.description
        self.level = dto.level
    }
}

// MARK: - Topic Verse
// Maps a topic to specific Bible verses

struct TopicVerse: Identifiable, Codable {
    let id: UUID
    let topicId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let relevanceScore: Double

    var range: VerseRange {
        VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }

    var reference: String {
        range.reference
    }
}

// MARK: - Topic with Verses
struct TopicWithVerses: Identifiable {
    let topic: Topic
    var verses: [TopicVerse]
    var relatedTopics: [Topic]
    var childTopics: [Topic]

    var id: UUID { topic.id }
    var name: String { topic.name }
    var description: String? { topic.description }

    var verseCount: Int { verses.count }
}

// MARK: - Topic Search Result
struct TopicSearchResult: Identifiable {
    let topic: Topic
    let similarity: Double

    var id: UUID { topic.id }
}
