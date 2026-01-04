import Foundation
import GRDB

// MARK: - Segment Mood
// Emotional tone for UI styling

enum SegmentMood: String, CaseIterable, Codable, Sendable {
    case joyful
    case solemn
    case dramatic
    case peaceful
    case triumphant
    case sorrowful
    case hopeful
    case warning

    var displayName: String {
        rawValue.capitalized
    }

    /// Maps to app color assets for mood-based styling
    var accentColorName: String {
        switch self {
        case .joyful: return "HighlightGold"
        case .solemn: return "SecondaryText"
        case .dramatic: return "HighlightRose"
        case .peaceful: return "HighlightBlue"
        case .triumphant: return "HighlightGold"
        case .sorrowful: return "HighlightPurple"
        case .hopeful: return "HighlightGreen"
        case .warning: return "Warning"
        }
    }

    var icon: String {
        switch self {
        case .joyful: return "sun.max.fill"
        case .solemn: return "moon.fill"
        case .dramatic: return "bolt.fill"
        case .peaceful: return "leaf.fill"
        case .triumphant: return "crown.fill"
        case .sorrowful: return "drop.fill"
        case .hopeful: return "sunrise.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Key Term Highlight
// A term highlighted for special attention in a segment

struct KeyTermHighlight: Codable, Hashable, Sendable {
    let term: String                    // "light", "covenant"
    let originalWord: String?           // Hebrew/Greek if applicable
    let briefMeaning: String            // One-line explanation

    /// Decode from JSON string in nonisolated context
    nonisolated static func fromJSON(_ jsonString: String) -> KeyTermHighlight? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        // Use manual decoding to avoid MainActor-isolated Codable
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let term = dict["term"] as? String,
              let briefMeaning = dict["briefMeaning"] as? String else { return nil }
        let originalWord = dict["originalWord"] as? String
        return KeyTermHighlight(term: term, originalWord: originalWord, briefMeaning: briefMeaning)
    }

    /// Encode to JSON string in nonisolated context
    nonisolated func toJSON() -> String? {
        var dict: [String: Any] = [
            "term": term,
            "briefMeaning": briefMeaning
        ]
        if let originalWord = originalWord {
            dict["originalWord"] = originalWord
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Story Segment
// A single segment/scene within a story

struct StorySegment: Identifiable, Hashable {
    let id: UUID
    let storyId: UUID
    let order: Int                      // Position in timeline (1, 2, 3...)
    let title: String                   // "Day One: Light"
    let content: String                 // Narrative text for this segment
    let verseAnchor: VerseRange?        // Specific verse(s) this segment covers
    let timelineLabel: String?          // "Day 1", "Year 1 of Reign", "~30 AD"
    let location: String?               // "Garden of Eden", "Mount Sinai"
    let keyCharacters: [UUID]           // References to StoryCharacter IDs
    let mood: SegmentMood?              // Emotional tone for UI styling
    let reflectionQuestion: String?     // Optional reflection prompt
    let keyTerm: KeyTermHighlight?      // One term to highlight

    // MARK: - Computed Properties

    var reference: String? {
        verseAnchor?.reference
    }

    var shortReference: String? {
        verseAnchor?.shortReference
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        storyId: UUID,
        order: Int,
        title: String,
        content: String,
        verseAnchor: VerseRange? = nil,
        timelineLabel: String? = nil,
        location: String? = nil,
        keyCharacters: [UUID] = [],
        mood: SegmentMood? = nil,
        reflectionQuestion: String? = nil,
        keyTerm: KeyTermHighlight? = nil
    ) {
        self.id = id
        self.storyId = storyId
        self.order = order
        self.title = title
        self.content = content
        self.verseAnchor = verseAnchor
        self.timelineLabel = timelineLabel
        self.location = location
        self.keyCharacters = keyCharacters
        self.mood = mood
        self.reflectionQuestion = reflectionQuestion
        self.keyTerm = keyTerm
    }
}

// MARK: - GRDB Support
extension StorySegment: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "story_segments" }

    enum Columns: String, ColumnExpression {
        case id
        case storyId = "story_id"
        case order = "order_index"
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

    nonisolated init(row: Row) {
        id = row[Columns.id]
        storyId = row[Columns.storyId]
        order = row[Columns.order]
        title = row[Columns.title]
        content = row[Columns.content]
        timelineLabel = row[Columns.timelineLabel]
        location = row[Columns.location]

        // Decode JSON fields using nonisolated helpers
        if let anchorJSON: String = row[Columns.verseAnchor] {
            verseAnchor = VerseRange.fromJSON(anchorJSON)
        } else {
            verseAnchor = nil
        }

        if let charactersJSON: String = row[Columns.keyCharacters],
           let data = charactersJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            keyCharacters = decoded
        } else {
            keyCharacters = []
        }

        if let moodString: String = row[Columns.mood] {
            mood = SegmentMood(rawValue: moodString)
        } else {
            mood = nil
        }

        reflectionQuestion = row[Columns.reflectionQuestion]

        if let keyTermJSON: String = row[Columns.keyTerm] {
            keyTerm = KeyTermHighlight.fromJSON(keyTermJSON)
        } else {
            keyTerm = nil
        }
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.storyId] = storyId
        container[Columns.order] = order
        container[Columns.title] = title
        container[Columns.content] = content
        container[Columns.timelineLabel] = timelineLabel
        container[Columns.location] = location
        container[Columns.mood] = mood?.rawValue
        container[Columns.reflectionQuestion] = reflectionQuestion

        // Encode JSON fields using nonisolated helpers
        container[Columns.verseAnchor] = verseAnchor?.toJSON()

        if let data = try? JSONEncoder().encode(keyCharacters),
           let json = String(data: data, encoding: .utf8) {
            container[Columns.keyCharacters] = json
        } else {
            container[Columns.keyCharacters] = "[]"
        }

        container[Columns.keyTerm] = keyTerm?.toJSON()
    }
}

