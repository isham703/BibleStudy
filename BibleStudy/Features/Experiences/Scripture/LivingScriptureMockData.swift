import Foundation
import SwiftUI

// MARK: - Living Scripture Mood
// The emotional atmosphere of each scene

enum LivingScriptureMood: String, CaseIterable {
    // Shared moods
    case contemplative
    case excited
    case desolate
    case broken
    case redemption
    // Peter's Denial moods
    case defiant
    case fearful
    // Burning Bush moods
    case awed
    case holy
    case commissioned

    var moodColor: Color {
        switch self {
        case .contemplative: return Color(hex: "C9A227")
        case .excited: return Color(hex: "E74C3C")
        case .desolate: return Color(hex: "2C3E50")
        case .broken: return Color(hex: "1A1A2E")
        case .redemption: return Color(hex: "D4A853")
        case .defiant: return Color(hex: "C74A4A")
        case .fearful: return Color(hex: "7B5DAF")
        case .awed: return Color(hex: "E8A830")
        case .holy: return Color(hex: "F4E9CD")
        case .commissioned: return Color(hex: "F39C12")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .contemplative: return [Color(hex: "2C1810"), Color(hex: "0A0908")]
        case .excited: return [Color(hex: "2D1F1F"), Color(hex: "0A0908")]
        case .desolate: return [Color(hex: "0F1419"), Color(hex: "0A0908")]
        case .broken: return [Color(hex: "0A0A14"), Color(hex: "050508")]
        case .redemption: return [Color(hex: "1A1408"), Color(hex: "0A0908")]
        case .defiant: return [Color(hex: "2A1515"), Color(hex: "0A0808")]
        case .fearful: return [Color(hex: "1A1525"), Color(hex: "08050A")]
        case .awed: return [Color(hex: "2E1F10"), Color(hex: "0A0805")]
        case .holy: return [Color(hex: "2A2618"), Color(hex: "0A0908")]
        case .commissioned: return [Color(hex: "2E1F10"), Color(hex: "0A0805")]
        }
    }
}

// MARK: - Living Scripture Scene
// A single scene in the narrative journey

struct LivingScriptureScene: Identifiable {
    let id = UUID()
    let narration: String
    let description: String
    let ambient: String
    let mood: LivingScriptureMood
    let prompt: String?

    var isFinalScene: Bool {
        prompt == nil
    }
}

// MARK: - Story Data

enum StoryData {
    // MARK: - The Prodigal Son (Luke 15:11-32)
    // Theme: Departure → Desolation → Redemption
    static let prodigalSon: [LivingScriptureScene] = [
        LivingScriptureScene(
            narration: "The road stretches endlessly before you.",
            description: "Dust coats your sandals. Your father's house is three days behind. The coins in your pouch feel heavier than they should.",
            ambient: "desert_wind",
            mood: .contemplative,
            prompt: "What are you feeling right now?"
        ),
        LivingScriptureScene(
            narration: "The city rises from the horizon.",
            description: "Music and laughter spill from open doorways. Merchants call out their wares. Everything you've ever wanted is finally within reach.",
            ambient: "city_bustle",
            mood: .excited,
            prompt: "What do you do first?"
        ),
        LivingScriptureScene(
            narration: "The last coin slips through your fingers.",
            description: "The room is empty now. The friends who filled it have vanished like morning mist. Your stomach aches. When did you last eat?",
            ambient: "silence",
            mood: .desolate,
            prompt: "Where do you go from here?"
        ),
        LivingScriptureScene(
            narration: "The pigs don't even look up.",
            description: "Their slop smells better than anything you've tasted in days. You reach toward it, and something breaks inside you. You remember your father's servants eating bread...",
            ambient: "pig_sounds",
            mood: .broken,
            prompt: "What do you want to say to your father?"
        ),
        LivingScriptureScene(
            narration: "You see him before he sees you.",
            description: "But no — he's already running. An old man, running. His robes fly behind him. He's weeping. He's reaching for you.",
            ambient: "running_footsteps",
            mood: .redemption,
            prompt: nil
        )
    ]

    // MARK: - Peter's Denial (Luke 22:54-62)
    // Theme: Confidence → Fear → Shame → Grace
    static let petersDenial: [LivingScriptureScene] = [
        LivingScriptureScene(
            narration: "You swore you would die for Him.",
            description: "The words still echo in your ears. 'Lord, I am ready to go with you to prison and to death.' He looked at you then with such sadness. Now soldiers are dragging Him away.",
            ambient: "night_chaos",
            mood: .defiant,
            prompt: "What do you do?"
        ),
        LivingScriptureScene(
            narration: "The courtyard fire flickers.",
            description: "You've followed at a distance. The warmth draws you in, but so do the shadows. Faces glow orange in the firelight. A servant girl stares at you.",
            ambient: "crackling_fire",
            mood: .fearful,
            prompt: "She's walking toward you..."
        ),
        LivingScriptureScene(
            narration: "\"I don't know Him.\"",
            description: "The words leave your mouth before you can stop them. Your voice sounds foreign. Someone else's voice. The servant girl turns away, unconvinced.",
            ambient: "murmuring_crowd",
            mood: .broken,
            prompt: "How do you feel?"
        ),
        LivingScriptureScene(
            narration: "\"Your accent gives you away.\"",
            description: "Three times now. Three times you've denied even knowing His name. Somewhere in the distance, a rooster crows. The sound pierces you like a sword.",
            ambient: "rooster_crow",
            mood: .desolate,
            prompt: "What is breaking inside you?"
        ),
        LivingScriptureScene(
            narration: "He turns and looks at you.",
            description: "Through the crowd, through the chaos, through the torchlight — His eyes find yours. No anger. No condemnation. Only love. Only sorrow. Only grace.",
            ambient: "silence",
            mood: .redemption,
            prompt: nil
        )
    ]

    // MARK: - The Burning Bush (Exodus 3:1-14)
    // Theme: Ordinary → Holy → Called
    static let burningBush: [LivingScriptureScene] = [
        LivingScriptureScene(
            narration: "The sheep scatter across the hillside.",
            description: "Forty years in this wilderness. Forty years since Egypt, since the palace, since... everything. You are a shepherd now. Nothing more.",
            ambient: "sheep_bells",
            mood: .contemplative,
            prompt: "What are you thinking about?"
        ),
        LivingScriptureScene(
            narration: "A strange glow draws your eye.",
            description: "On the mountain. A bush, burning — but not consumed. The flames dance but the branches remain. Heat without destruction. Light without end.",
            ambient: "fire_crackling",
            mood: .awed,
            prompt: "Do you approach?"
        ),
        LivingScriptureScene(
            narration: "\"Remove your sandals.\"",
            description: "The voice comes from everywhere and nowhere. From the fire itself. 'The ground on which you stand is holy.' Your knees buckle. You hide your face.",
            ambient: "holy_silence",
            mood: .holy,
            prompt: "What do you feel in His presence?"
        ),
        LivingScriptureScene(
            narration: "\"I AM WHO I AM.\"",
            description: "He speaks His name — the name beyond all names. He has seen His people's suffering. He has heard their cries. And now He is sending... you?",
            ambient: "divine_presence",
            mood: .fearful,
            prompt: "Who are you to do this?"
        ),
        LivingScriptureScene(
            narration: "\"Go. I will be with you.\"",
            description: "The fire burns on, but something has changed. Not the bush — you. The shepherd's staff in your hand suddenly feels different. It is no longer just wood.",
            ambient: "wind_rising",
            mood: .commissioned,
            prompt: nil
        )
    ]

    static var defaultStory: [LivingScriptureScene] {
        prodigalSon
    }

    static var storyTitle: String {
        "The Prodigal Son"
    }

    static var finalMessage: String {
        "You are home."
    }

    static var finalSubtitle: String {
        "The father's love never left you."
    }

    // Final messages for each story
    static func finalMessage(for storyType: StoryType) -> (title: String, subtitle: String) {
        switch storyType {
        case .prodigalSon:
            return ("You are home.", "The father's love never left you.")
        case .petersDenial:
            return ("You are forgiven.", "His grace is greater than your failure.")
        case .burningBush:
            return ("You are sent.", "I AM will be with you.")
        }
    }

    enum StoryType {
        case prodigalSon
        case petersDenial
        case burningBush
    }
}
