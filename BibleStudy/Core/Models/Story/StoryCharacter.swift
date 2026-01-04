import Foundation
import GRDB

// MARK: - Character Role
// The role a character plays in the story

enum CharacterRole: String, CaseIterable, Codable, Sendable {
    case protagonist   // Main character
    case antagonist    // Opposing force
    case supporting    // Supporting character
    case divine        // God, Jesus, Holy Spirit
    case messenger     // Angels, prophets delivering messages

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .protagonist: return "star.fill"
        case .antagonist: return "xmark.circle.fill"
        case .supporting: return "person.fill"
        case .divine: return "sparkles"
        case .messenger: return "envelope.fill"
        }
    }
}

// MARK: - Story Character
// A character appearing in a biblical story

struct StoryCharacter: Identifiable, Hashable {
    let id: UUID
    let name: String                    // "Moses", "David"
    let title: String?                  // "Deliverer of Israel", "King"
    let description: String             // Character overview
    let role: CharacterRole
    let firstAppearance: VerseRange?    // Where they first appear
    let keyVerses: [VerseRange]         // Important verses about them
    let iconName: String?               // SF Symbol or custom icon

    // MARK: - Computed Properties

    var displayTitle: String {
        if let title = title {
            return "\(name), \(title)"
        }
        return name
    }

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        name: String,
        title: String? = nil,
        description: String,
        role: CharacterRole,
        firstAppearance: VerseRange? = nil,
        keyVerses: [VerseRange] = [],
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.role = role
        self.firstAppearance = firstAppearance
        self.keyVerses = keyVerses
        self.iconName = iconName
    }
}

// MARK: - GRDB Support
extension StoryCharacter: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "story_characters" }

    enum Columns: String, ColumnExpression {
        case id
        case name
        case title
        case description
        case role
        case firstAppearance = "first_appearance"
        case keyVerses = "key_verses"
        case iconName = "icon_name"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        title = row[Columns.title]
        description = row[Columns.description]
        role = CharacterRole(rawValue: row[Columns.role]) ?? .supporting
        iconName = row[Columns.iconName]

        // Decode JSON fields using nonisolated helpers
        if let appearanceJSON: String = row[Columns.firstAppearance] {
            firstAppearance = VerseRange.fromJSON(appearanceJSON)
        } else {
            firstAppearance = nil
        }

        if let versesJSON: String = row[Columns.keyVerses] {
            keyVerses = VerseRange.arrayFromJSON(versesJSON) ?? []
        } else {
            keyVerses = []
        }
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.title] = title
        container[Columns.description] = description
        container[Columns.role] = role.rawValue
        container[Columns.iconName] = iconName

        // Encode JSON fields using nonisolated helpers
        container[Columns.firstAppearance] = firstAppearance?.toJSON()
        container[Columns.keyVerses] = VerseRange.arrayToJSON(keyVerses) ?? "[]"
    }
}


// MARK: - Common Biblical Characters
extension StoryCharacter {
    static let god = StoryCharacter(
        name: "God",
        title: "Creator and Sustainer",
        description: "The eternal God, Creator of heaven and earth",
        role: .divine,
        firstAppearance: VerseRange(bookId: 1, chapter: 1, verse: 1),
        iconName: "sparkles"
    )

    static let jesus = StoryCharacter(
        name: "Jesus",
        title: "Son of God",
        description: "The Messiah, Son of God, Savior of the world",
        role: .divine,
        firstAppearance: VerseRange(bookId: 40, chapter: 1, verse: 1),
        iconName: "cross"
    )
}
