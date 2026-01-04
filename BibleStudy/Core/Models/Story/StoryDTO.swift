import Foundation

// MARK: - Story DTOs
// Separate Codable types for JSON decoding to avoid circular reference issues with GRDB

// MARK: - Stories Bundle
struct StoriesBundle: Codable {
    let version: Int
    let stories: [StoryDTO]
}

// MARK: - Story DTO
struct StoryDTO: Codable {
    let id: String
    let slug: String
    let title: String
    let subtitle: String?
    let description: String
    let type: String
    let readingLevel: String
    let isPrebuilt: Bool?
    let verseAnchors: [VerseRangeDTO]
    let estimatedMinutes: Int
    let userId: String?
    let isPublic: Bool?
    let generationMode: String
    let modelId: String?
    let promptVersion: Int?
    let schemaVersion: Int?
    let generatedAt: String?
    let sourcePassageIds: [String]?
    let createdAt: String?
    let updatedAt: String?
    let segments: [StorySegmentDTO]
    let characters: [StoryCharacterDTO]?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, subtitle, description, type
        case readingLevel = "reading_level"
        case isPrebuilt = "is_prebuilt"
        case verseAnchors = "verse_anchors"
        case estimatedMinutes = "estimated_minutes"
        case userId = "user_id"
        case isPublic = "is_public"
        case generationMode = "generation_mode"
        case modelId = "model_id"
        case promptVersion = "prompt_version"
        case schemaVersion = "schema_version"
        case generatedAt = "generated_at"
        case sourcePassageIds = "source_passage_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case segments, characters
    }

    func toStory() -> Story {
        let storyId = UUID(uuidString: id) ?? UUID()

        let storySegments = segments.map { dto in
            dto.toSegment(storyId: storyId)
        }

        let storyCharacters = characters?.map { $0.toCharacter() } ?? []

        return Story(
            id: storyId,
            slug: slug,
            title: title,
            subtitle: subtitle,
            description: description,
            type: StoryType(rawValue: type) ?? .narrative,
            readingLevel: StoryReadingLevel(rawValue: readingLevel) ?? .adult,
            isPrebuilt: isPrebuilt ?? true,
            verseAnchors: verseAnchors.map { $0.toVerseRange() },
            estimatedMinutes: estimatedMinutes,
            userId: userId.flatMap { UUID(uuidString: $0) },
            isPublic: isPublic ?? false,
            generationMode: GenerationMode(rawValue: generationMode) ?? .prebuilt,
            modelId: modelId,
            promptVersion: promptVersion ?? 1,
            schemaVersion: schemaVersion ?? 1,
            generatedAt: generatedAt.flatMap { ISO8601DateFormatter().date(from: $0) },
            sourcePassageIds: sourcePassageIds ?? [],
            segments: storySegments,
            characters: storyCharacters
        )
    }
}

// MARK: - Story Segment DTO
struct StorySegmentDTO: Codable {
    let id: String
    let storyId: String
    let order: Int
    let title: String
    let content: String
    let verseAnchor: VerseRangeDTO?
    let timelineLabel: String?
    let location: String?
    let keyCharacters: [String]?
    let mood: String?
    let reflectionQuestion: String?
    let keyTerm: KeyTermDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case storyId = "story_id"
        case order
        case title
        case content
        case verseAnchor = "verse_anchor"
        case timelineLabel = "timeline_label"
        case location
        case keyCharacters = "key_characters"
        case mood
        case reflectionQuestion = "reflection_question"
        case keyTerm = "key_term"
    }

    func toSegment(storyId: UUID) -> StorySegment {
        StorySegment(
            id: UUID(uuidString: id) ?? UUID(),
            storyId: storyId,
            order: order,
            title: title,
            content: content,
            verseAnchor: verseAnchor?.toVerseRange(),
            timelineLabel: timelineLabel,
            location: location,
            keyCharacters: keyCharacters?.compactMap { UUID(uuidString: $0) } ?? [],
            mood: mood.flatMap { SegmentMood(rawValue: $0) },
            reflectionQuestion: reflectionQuestion,
            keyTerm: keyTerm?.toKeyTerm()
        )
    }
}

// MARK: - Story Character DTO
struct StoryCharacterDTO: Codable {
    let id: String?
    let name: String
    let title: String?
    let description: String
    let role: String
    let firstAppearance: VerseRangeDTO?
    let keyVerses: [VerseRangeDTO]?
    let iconName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, title, description, role
        case firstAppearance = "first_appearance"
        case keyVerses = "key_verses"
        case iconName = "icon_name"
    }

    func toCharacter() -> StoryCharacter {
        StoryCharacter(
            id: id.flatMap { UUID(uuidString: $0) } ?? UUID(),
            name: name,
            title: title,
            description: description,
            role: CharacterRole(rawValue: role) ?? .supporting,
            firstAppearance: firstAppearance?.toVerseRange(),
            keyVerses: keyVerses?.map { $0.toVerseRange() } ?? [],
            iconName: iconName
        )
    }
}

// MARK: - Verse Range DTO
struct VerseRangeDTO: Codable {
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int

    func toVerseRange() -> VerseRange {
        VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
}

// MARK: - Key Term DTO
struct KeyTermDTO: Codable {
    let term: String
    let originalWord: String?
    let briefMeaning: String

    func toKeyTerm() -> KeyTermHighlight {
        KeyTermHighlight(
            term: term,
            originalWord: originalWord,
            briefMeaning: briefMeaning
        )
    }
}
