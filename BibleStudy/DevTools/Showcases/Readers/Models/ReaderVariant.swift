import SwiftUI

// MARK: - Reader Variant
// Defines the 3 reader page variations for the showcase

enum ReaderVariant: String, CaseIterable, Identifiable {
    case illuminatedScriptorium
    case candlelitChapel
    case scholarsMarginalia

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .illuminatedScriptorium:
            return "Illuminated Scriptorium"
        case .candlelitChapel:
            return "Candlelit Chapel"
        case .scholarsMarginalia:
            return "Scholar's Marginalia"
        }
    }

    var subtitle: String {
        switch self {
        case .illuminatedScriptorium:
            return "Golden morning light • Verse by verse"
        case .candlelitChapel:
            return "Evening starlight • Paragraph flow"
        case .scholarsMarginalia:
            return "Editorial study • Annotated verses"
        }
    }

    var description: String {
        switch self {
        case .illuminatedScriptorium:
            return "A warm, parchment-toned reading experience with golden light rays, ornamental verse numbers, and elegant drop caps. Perfect for morning devotions."
        case .candlelitChapel:
            return "An intimate nighttime reading mode with starfield background, candle glow, and flowing paragraph text. Designed for evening contemplation."
        case .scholarsMarginalia:
            return "A scholarly layout with clean typography, Greek annotations, cross-references, and side marginalia. Ideal for deep study."
        }
    }

    var icon: String {
        switch self {
        case .illuminatedScriptorium:
            return "sun.max.fill"
        case .candlelitChapel:
            return "moon.stars.fill"
        case .scholarsMarginalia:
            return "text.book.closed.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .illuminatedScriptorium:
            return Color(hex: "A08460") // Lighter bronze
        case .candlelitChapel:
            return Color.accentBronze // accentSeal bronze
        case .scholarsMarginalia:
            return Color.accentIndigo // accentAction indigo
        }
    }

    var readingMode: ReadingMode {
        switch self {
        case .illuminatedScriptorium:
            return .verseByVerse
        case .candlelitChapel:
            return .paragraphFlow
        case .scholarsMarginalia:
            return .annotatedVerses
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .illuminatedScriptorium:
            return .light
        case .candlelitChapel:
            return .dark
        case .scholarsMarginalia:
            return .light
        }
    }
}

// MARK: - Reading Mode

enum ReadingMode: String {
    case verseByVerse
    case paragraphFlow
    case annotatedVerses

    var displayName: String {
        switch self {
        case .verseByVerse:
            return "Verse by Verse"
        case .paragraphFlow:
            return "Paragraph Flow"
        case .annotatedVerses:
            return "Annotated Verses"
        }
    }
}
