import SwiftUI

// MARK: - Home Page Variant
// Defines the home page design variations for the showcase directory
// Design Direction: Stoic Vibes - Muted, contemplative, Roman/classical influences

enum HomePageVariant: String, CaseIterable, Identifiable {
    case theForum
    case thePortico
    case theMeditationChamber
    case theStoa
    case theAtrium
    case theScriptorium
    case theThreshold
    case theBasilica
    case theMonument
    case theTriumph

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .theForum:
            return "The Forum"
        case .thePortico:
            return "The Portico"
        case .theMeditationChamber:
            return "The Meditation Chamber"
        case .theStoa:
            return "The Stoa"
        case .theAtrium:
            return "The Atrium"
        case .theScriptorium:
            return "The Scriptorium"
        case .theThreshold:
            return "The Threshold"
        case .theBasilica:
            return "The Basilica"
        case .theMonument:
            return "The Monument"
        case .theTriumph:
            return "The Triumph"
        }
    }

    var subtitle: String {
        switch self {
        case .theForum:
            return "Centered wisdom layout"
        case .thePortico:
            return "Column-divided sections"
        case .theMeditationChamber:
            return "Intimate contemplation"
        case .theStoa:
            return "Exaggerated minimalism"
        case .theAtrium:
            return "Radiant courtyard focus"
        case .theScriptorium:
            return "Manuscript illumination"
        case .theThreshold:
            return "Dawn awakening hope"
        case .theBasilica:
            return "Imperial columned grandeur"
        case .theMonument:
            return "Marble virtue heroics"
        case .theTriumph:
            return "Spiritual conquest glory"
        }
    }

    var description: String {
        switch self {
        case .theForum:
            return "A clean, centered layout inspired by Roman public gathering spaces. Features a prominent daily wisdom quote as the focal point, minimal navigation, and generous whitespace for clarity of thought."
        case .thePortico:
            return "Structured layout with column-like section dividers, inspired by the philosophical porticos where Stoics taught. Balanced composition with clear visual hierarchy."
        case .theMeditationChamber:
            return "A dark, intimate design with warm amber accents like candlelight. Focuses on personal reflection with muted tones and contemplative atmosphere."
        case .theStoa:
            return "Bold, exaggerated minimalism inspired by the Stoa Poikile where Zeno taught. Deep navy blue palette symbolizing wisdom, with oversized typography and marble texture accents."
        case .theAtrium:
            return "Inspired by the Roman house atrium with its central impluvium. Light radiates from a focal point, with cards arranged around it. Time-aware gradients simulate natural light from above."
        case .theScriptorium:
            return "A manuscript-inspired design evoking medieval scriptoriums. Parchment tones on dark backgrounds, illuminated drop capitals, and scroll-like sections focused on reading and study."
        case .theThreshold:
            return "An awakening design using the Dawn palette. Soft lavender and coral gradients symbolize new beginnings and hope. Features morning devotional focus with gentle, encouraging visual hierarchy."
        case .theBasilica:
            return "A grand imperial design inspired by Roman basilicas and Vatican architecture. Soaring columns, vaulted ceilings, and imperial purple accents create an atmosphere of divine majesty. Emphasizes spiritual conquest through monumental scale."
        case .theMonument:
            return "A sculptural design inspired by Vatican marble statues and heroic Roman figures. Cool stone tones with moonlit highlights evoke draped apostles in heroic poses. Celebrates inner virtue and stoic resilience through timeless forms."
        case .theTriumph:
            return "A victorious design inspired by Roman triumphal arches. Laurel wreaths crown achievements, eagles watch from above, and crosses stand as scepters of spiritual authority. Celebrates divine legacy and the triumph of faith."
        }
    }

    var icon: String {
        switch self {
        case .theForum:
            return "building.columns.fill"
        case .thePortico:
            return "rectangle.split.3x1"
        case .theMeditationChamber:
            return "flame.fill"
        case .theStoa:
            return "textformat.size.larger"
        case .theAtrium:
            return "square.on.square.dashed"
        case .theScriptorium:
            return "scroll.fill"
        case .theThreshold:
            return "sunrise.fill"
        case .theBasilica:
            return "building.columns.circle.fill"
        case .theMonument:
            return "figure.stand"
        case .theTriumph:
            return "crown.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .theForum:
            return Color.decorativeTaupe // stoicTaupe
        case .thePortico:
            return Color.accentIndigo // accentAction
        case .theMeditationChamber:
            return Color.accentBronze // accentSeal
        case .theStoa:
            return Color(hex: "5B7C99") // Stoic navy/steel blue
        case .theAtrium:
            return Color(hex: "C9A959") // Warm bronze
        case .theScriptorium:
            return Color(hex: "8B4513") // Saddle brown/sepia
        case .theThreshold:
            return Color(hex: "FFB84D") // dawnSunrise
        case .theBasilica:
            return Color.accentIndigo // accentAction
        case .theMonument:
            return Color.decorativeMarble // moonlitMarble
        case .theTriumph:
            return Color.accentBronze // accentSeal
        }
    }

    var previewGradient: [Color] {
        switch self {
        case .theForum:
            return [
                Color(hex: "2C2825"),
                Color.surfaceCharcoal
            ]
        case .thePortico:
            return [
                Color(hex: "1A1428"),
                Color(hex: "0D0A14")
            ]
        case .theMeditationChamber:
            return [
                Color(hex: "1F1A12"),
                Color(hex: "0A0806")
            ]
        case .theStoa:
            return [
                Color(hex: "1A2633"), // Deep navy
                Color(hex: "0D1318")
            ]
        case .theAtrium:
            return [
                Color(hex: "1E1A14"), // Warm dark
                Color(hex: "2A2418")  // Bronze undertone
            ]
        case .theScriptorium:
            return [
                Color(hex: "1C1410"), // Dark parchment
                Color(hex: "0E0A08")
            ]
        case .theThreshold:
            return [
                Color(hex: "2F4F4F") // dawnSlate,
                Color(hex: "2F4F4F") // dawnSlate.opacity(Theme.Opacity.pressed)
            ]
        case .theBasilica:
            return [
                Color.surfaceInk // forumNight,
                Color.surfaceMedium // shadowStone
            ]
        case .theMonument:
            return [
                Color(hex: "4A5568") // stoicSlate,
                Color.surfaceSlate // stoicCharcoal
            ]
        case .theTriumph:
            return [
                Color.surfaceInk // forumNight,
                Color.surfaceMedium // shadowStone.opacity(Theme.Opacity.pressed)
            ]
        }
    }

    var tags: [String] {
        switch self {
        case .theForum:
            return ["Centered", "Minimal", "Wisdom"]
        case .thePortico:
            return ["Structured", "Balanced", "Classical"]
        case .theMeditationChamber:
            return ["Dark", "Intimate", "Warm"]
        case .theStoa:
            return ["Bold", "Navy", "Marble"]
        case .theAtrium:
            return ["Radiant", "Bronze", "Courtyard"]
        case .theScriptorium:
            return ["Manuscript", "Sepia", "Scholarly"]
        case .theThreshold:
            return ["Dawn", "Coral", "Hopeful"]
        case .theBasilica:
            return ["Imperial", "Columned", "Majestic"]
        case .theMonument:
            return ["Marble", "Heroic", "Virtue"]
        case .theTriumph:
            return ["Victory", "Laurel", "Conquest"]
        }
    }

    var colorScheme: ColorScheme {
        .dark
    }
}

// MARK: - Stoic Design Philosophy
// Reference for design direction across all variants:
//
// COLOR PALETTE:
// - Deep slate (#1A1A1A to #2C2825)
// - Warm stone (#D2B48C - stoicTaupe)
// - Aged parchment (#F0E8DC)
// - Muted ivory (#F5F5F5)
//
// TYPOGRAPHY:
// - Headers: Serif (Cinzel for inscriptional, System serif for elegant)
// - Body: Clean sans-serif or light serif
// - Quotes: Cormorant Italic for wisdom passages
//
// VISUAL ELEMENTS:
// - Subtle marble/stone textures (via gradients, not images)
// - Classical iconography (columns, laurels, scrolls)
// - Generous whitespace for meditation
// - Muted gold accents (laurelGold) used sparingly
//
// ATMOSPHERE:
// - Calm, meditative
// - Wisdom-focused hierarchy (quotes prominent)
// - Minimal ornamentation
// - Considered restraint
