import SwiftUI

// MARK: - Showcase Scene

struct ShowcaseScene: Identifiable {
    let id = UUID()
    let narration: String
    let description: String
    let ambient: String
    let mood: ShowcaseMood
    let prompt: String?
}

// MARK: - Showcase Mood

enum ShowcaseMood {
    case contemplative
    case excited
    case desolate
    case broken
    case redemption

    var color: Color {
        switch self {
        case .contemplative: return Color(hex: "C9A227")
        case .excited: return Color(hex: "E74C3C")
        case .desolate: return Color(hex: "2C3E50")
        case .broken: return Color(hex: "1A1A2E")
        case .redemption: return Color(hex: "D4A853")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .contemplative: return [Color(hex: "2C1810"), Color(hex: "0A0908")]
        case .excited: return [Color(hex: "2D1F1F"), Color(hex: "0A0908")]
        case .desolate: return [Color(hex: "0F1419"), Color(hex: "0A0908")]
        case .broken: return [Color(hex: "0A0A14"), Color(hex: "050508")]
        case .redemption: return [Color(hex: "1A1408"), Color(hex: "0A0908")]
        }
    }

    // Scroll-specific colors
    var scrollTint: Color {
        switch self {
        case .contemplative: return Color(hex: "8B7355")
        case .excited: return Color(hex: "A0522D")
        case .desolate: return Color(hex: "6B5B47")
        case .broken: return Color(hex: "4A3728")
        case .redemption: return Color(hex: "C4A35A")
        }
    }

    // Stained glass colors
    var glassColor: Color {
        switch self {
        case .contemplative: return .glassAmethyst
        case .excited: return .glassRuby
        case .desolate: return .glassSapphire
        case .broken: return Color(hex: "2C2C54")
        case .redemption: return .glassGold
        }
    }
}

// MARK: - Showcase Mock Data

struct ShowcaseMockData {
    // The Prodigal Son - told in second person
    static let prodigalSonScenes: [ShowcaseScene] = [
        ShowcaseScene(
            narration: "The road stretches endlessly before you.",
            description: "Dust coats your sandals. Your father's house is three days behind. The coins in your pouch feel heavier than they should.",
            ambient: "desert_wind",
            mood: .contemplative,
            prompt: "What are you feeling right now?"
        ),
        ShowcaseScene(
            narration: "The city rises from the horizon.",
            description: "Music and laughter spill from open doorways. Merchants call out their wares. Everything you've ever wanted is finally within reach.",
            ambient: "city_bustle",
            mood: .excited,
            prompt: "What do you do first?"
        ),
        ShowcaseScene(
            narration: "The last coin slips through your fingers.",
            description: "The room is empty now. The friends who filled it have vanished like morning mist. Your stomach aches. When did you last eat?",
            ambient: "silence",
            mood: .desolate,
            prompt: "Where do you go from here?"
        ),
        ShowcaseScene(
            narration: "The pigs don't even look up.",
            description: "Their slop smells better than anything you've tasted in days. You reach toward it, and something breaks inside you. You remember your father's servants eating bread...",
            ambient: "pig_sounds",
            mood: .broken,
            prompt: "What do you want to say to your father?"
        ),
        ShowcaseScene(
            narration: "You see him before he sees you.",
            description: "But no - he's already running. An old man, running. His robes fly behind him. He's weeping. He's reaching for you.",
            ambient: "running_footsteps",
            mood: .redemption,
            prompt: nil
        )
    ]

    static var defaultScenes: [ShowcaseScene] { prodigalSonScenes }
}
