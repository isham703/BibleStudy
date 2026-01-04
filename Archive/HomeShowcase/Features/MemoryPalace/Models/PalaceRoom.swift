import SwiftUI

// MARK: - Palace Room Model
// Represents a room in the memory palace with associated scripture phrase
// Each room has visual cues to aid memorization through spatial association

struct PalaceRoom: Identifiable {
    let id: Int
    let name: String
    let phrase: String
    let icon: String
    let primaryColor: Color
    let ambientColor: Color
    let visualCue: String

    // MARK: - Psalm 23:1 Rooms

    /// The 5 rooms for memorizing Psalm 23:1
    /// "The Lord is my shepherd, I shall not want."
    static let psalm23Rooms: [PalaceRoom] = [
        PalaceRoom(
            id: 0,
            name: "Throne Room",
            phrase: "The Lord",
            icon: "crown.fill",
            primaryColor: Color(hex: "D4A853"),
            ambientColor: Color(hex: "3d2a0a"),
            visualCue: "A majestic golden throne radiating divine light"
        ),
        PalaceRoom(
            id: 1,
            name: "Shepherd's Quarters",
            phrase: "is my shepherd",
            icon: "figure.walk",
            primaryColor: Color(hex: "10b981"),
            ambientColor: Color(hex: "0a2e1a"),
            visualCue: "A shepherd's staff rests against stone walls"
        ),
        PalaceRoom(
            id: 2,
            name: "Mirror Chamber",
            phrase: "I",
            icon: "person.fill",
            primaryColor: Color(hex: "3b82f6"),
            ambientColor: Color(hex: "0a1a3e"),
            visualCue: "Your reflection gazes from an ornate mirror"
        ),
        PalaceRoom(
            id: 3,
            name: "Treasure Vault",
            phrase: "shall not",
            icon: "xmark.circle",
            primaryColor: Color(hex: "ef4444"),
            ambientColor: Color(hex: "3e0a0a"),
            visualCue: "A vault sealed shut, nothing enters or exits"
        ),
        PalaceRoom(
            id: 4,
            name: "Garden of Abundance",
            phrase: "want",
            icon: "leaf.fill",
            primaryColor: Color(hex: "059669"),
            ambientColor: Color(hex: "0a2e1a"),
            visualCue: "Overflowing gardens with every fruit imaginable"
        )
    ]

    // MARK: - Computed Properties

    /// The complete verse reference
    static let verseReference = "Psalm 23:1"

    /// The complete verse text
    static let fullVerse = "The Lord is my shepherd, I shall not want."

    /// Total number of rooms
    static var roomCount: Int {
        psalm23Rooms.count
    }

    /// Words in the phrase for tap-to-reveal
    var words: [String] {
        phrase.split(separator: " ").map(String.init)
    }

    /// Word count for validation
    var wordCount: Int {
        words.count
    }
}
