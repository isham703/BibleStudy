import SwiftUI

// MARK: - AI Feature
// Navigation model for AI-powered Bible study experiences
// Used by Sanctuary views and Sacred Threshold to navigate to feature POCs

enum AIFeature: String, CaseIterable, Identifiable {
    case livingScripture = "Living Scripture"
    case scriptureFindsYou = "Scripture Finds You"
    case theApprentice = "The Apprentice"
    case illuminate = "Illuminate"
    case theThread = "The Thread"
    case livingCommentary = "Living Commentary"
    case prayersFromDeep = "Prayers From the Deep"
    case memoryPalace = "Memory Palace"
    case compline = "Compline"

    var id: String { rawValue }
    var title: String { rawValue }

    // MARK: - Display Properties

    var subtitle: String {
        switch self {
        case .livingScripture: return "Step inside biblical narratives as a first-person experience"
        case .scriptureFindsYou: return "Context-aware verses that surface when you need them"
        case .theApprentice: return "Your personal AI study companion that grows with you"
        case .illuminate: return "AI-generated sacred art for any verse"
        case .theThread: return "Conversations with historical figures about scripture"
        case .livingCommentary: return "Dynamic marginalia that adapts to your questions"
        case .prayersFromDeep: return "AI crafts prayers in the language of the Psalms"
        case .memoryPalace: return "Visual journeys for scripture memorization"
        case .compline: return "AI-led evening prayer experience"
        }
    }

    var icon: String {
        switch self {
        case .livingScripture: return "book.pages.fill"
        case .scriptureFindsYou: return "sparkle.magnifyingglass"
        case .theApprentice: return "bubble.left.and.bubble.right.fill"
        case .illuminate: return "paintpalette.fill"
        case .theThread: return "person.2.wave.2.fill"
        case .livingCommentary: return "text.book.closed.fill"
        case .prayersFromDeep: return "hands.sparkles.fill"
        case .memoryPalace: return "building.columns.fill"
        case .compline: return "moon.stars.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .livingScripture: return [Color(hex: "ec4899"), Color(hex: "8b5cf6")]
        case .scriptureFindsYou: return [Color(hex: "06b6d4"), Color(hex: "3b82f6")]
        case .theApprentice: return [Color(hex: "f59e0b"), Color(hex: "ef4444")]
        case .illuminate: return [Color(hex: "d4a853"), Color(hex: "a855f7")]
        case .theThread: return [Color(hex: "10b981"), Color(hex: "059669")]
        case .livingCommentary: return [Color(hex: "6366f1"), Color(hex: "8b5cf6")]
        case .prayersFromDeep: return [Color(hex: "f43f5e"), Color(hex: "ec4899")]
        case .memoryPalace: return [Color(hex: "14b8a6"), Color(hex: "06b6d4")]
        case .compline: return [Color(hex: "1e3a5f"), Color(hex: "312e81")]
        }
    }

    // MARK: - Card Labels (for Sanctuary views)

    var cardLabel: String {
        switch self {
        case .livingScripture: return "SCRIPTURE"
        case .scriptureFindsYou: return "DISCOVER"
        case .theApprentice: return "COMPANION"
        case .illuminate: return "ART"
        case .theThread: return "DIALOGUE"
        case .livingCommentary: return "COMMENTARY"
        case .prayersFromDeep: return "PRAYERS"
        case .memoryPalace: return "MEMORY"
        case .compline: return "COMPLINE"
        }
    }

    var cardTitle: String {
        switch self {
        case .livingScripture: return "Living Scripture"
        case .scriptureFindsYou: return "Scripture Finds You"
        case .theApprentice: return "The Apprentice"
        case .illuminate: return "Illuminate"
        case .theThread: return "The Thread"
        case .livingCommentary: return "Living Commentary"
        case .prayersFromDeep: return "Prayers from the Deep"
        case .memoryPalace: return "Memory Palace"
        case .compline: return "Compline"
        }
    }

    var cardSubtitle: String {
        switch self {
        case .livingScripture: return "Enter the Prodigal's story"
        case .scriptureFindsYou: return "Discover timely verses"
        case .theApprentice: return "Your study companion"
        case .illuminate: return "Sacred visual art"
        case .theThread: return "Conversations with history"
        case .livingCommentary: return "Study John 1"
        case .prayersFromDeep: return "Craft a prayer"
        case .memoryPalace: return "Memorize Psalm 23"
        case .compline: return "Begin your evening prayer"
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .livingScripture:
            LivingScripturePOC()
        case .scriptureFindsYou:
            ScriptureFindsYouPOC()
        case .theApprentice:
            TheApprenticePOC()
        case .illuminate:
            IlluminatePOC()
        case .theThread:
            TheThreadPOC()
        case .livingCommentary:
            LivingCommentaryPOC()
        case .prayersFromDeep:
            PrayersFromDeepPOC()
        case .memoryPalace:
            MemoryPalacePOC()
        case .compline:
            ComplinePOC()
        }
    }
}

// MARK: - Feature Sets for Different Times

extension AIFeature {
    /// Features shown in Dawn Sanctuary (morning devotion focus)
    static var dawnFeatures: [AIFeature] {
        [.livingScripture, .livingCommentary, .prayersFromDeep, .memoryPalace]
    }

    /// Features shown in Meridian Sanctuary (study focus)
    static var meridianFeatures: [AIFeature] {
        [.livingScripture, .livingCommentary, .prayersFromDeep, .memoryPalace]
    }

    /// Features shown in Afternoon Sanctuary (contemplation focus)
    static var afternoonFeatures: [AIFeature] {
        [.livingScripture, .livingCommentary, .prayersFromDeep, .memoryPalace]
    }

    /// Features shown in Vespers Sanctuary (evening reflection focus)
    static var vespersFeatures: [AIFeature] {
        [.livingScripture, .livingCommentary, .prayersFromDeep, .compline]
    }

    /// Features shown in Compline Sanctuary (night prayer focus)
    static var complineFeatures: [AIFeature] {
        [.prayersFromDeep, .memoryPalace, .livingScripture, .compline]
    }

    /// Features for Sacred Threshold rooms
    static var thresholdFeatures: [AIFeature] {
        [.livingScripture, .livingCommentary, .memoryPalace, .prayersFromDeep, .compline]
    }
}
