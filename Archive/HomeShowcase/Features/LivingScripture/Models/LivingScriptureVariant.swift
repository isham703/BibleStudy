import SwiftUI

// MARK: - Living Scripture Variant
// Enum defining the three immersive narrative design variations

enum LivingScriptureVariant: String, CaseIterable, Identifiable {
    case cinematicFilm = "Cinematic Film"
    case ancientScroll = "Ancient Scroll"
    case stainedGlass = "Stained Glass"

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .cinematicFilm:
            return "Film Noir Narrative"
        case .ancientScroll:
            return "Papyrus Journey"
        case .stainedGlass:
            return "Cathedral Light"
        }
    }

    var description: String {
        switch self {
        case .cinematicFilm:
            return "Dreamlike, intimate, cinematic. Enter a memory with vignette edges, mood-based lighting, and breathing atmospheric effects."
        case .ancientScroll:
            return "Weathered papyrus unfurls as you journey. Sepia tones, hand-drawn borders, and text that materializes like ancient ink."
        case .stainedGlass:
            return "Light streams through cathedral windows. Each scene painted in jewel tones with divine radiance and sacred geometry."
        }
    }

    var icon: String {
        switch self {
        case .cinematicFilm:
            return "film"
        case .ancientScroll:
            return "scroll.fill"
        case .stainedGlass:
            return "window.ceiling"
        }
    }

    var accentColor: Color {
        switch self {
        case .cinematicFilm:
            return .cinematicGold
        case .ancientScroll:
            return .scrollSepia
        case .stainedGlass:
            return .glassAmethyst
        }
    }

    var backgroundStyle: BackgroundStyle {
        switch self {
        case .cinematicFilm:
            return .dark
        case .ancientScroll:
            return .light
        case .stainedGlass:
            return .dark
        }
    }

    enum BackgroundStyle {
        case light, dark
    }

    // MARK: - Color Palette for Preview Strip

    func paletteColor(_ index: Int) -> Color {
        switch self {
        case .cinematicFilm:
            return [.cinematicGold, .cinematicMood, .cinematicVoid, .cinematicWarm][index]
        case .ancientScroll:
            return [.scrollSepia, .scrollPapyrus, .scrollInk, .scrollBorder][index]
        case .stainedGlass:
            return [.glassAmethyst, .glassRuby, .glassEmerald, .glassSapphire][index]
        }
    }

    // MARK: - Badge for Special Features

    var badge: String? {
        switch self {
        case .cinematicFilm:
            return "IMMERSIVE"
        default:
            return nil
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var page: some View {
        switch self {
        case .cinematicFilm:
            CinematicFilmView()
        case .ancientScroll:
            AncientScrollView()
        case .stainedGlass:
            StainedGlassView()
        }
    }
}

// MARK: - Living Scripture Colors

extension Color {
    // Cinematic Film palette
    static let cinematicVoid = Color(hex: "0A0908")
    static let cinematicGold = Color(hex: "D4AF37")
    static let cinematicMood = Color(hex: "2C1810")
    static let cinematicWarm = Color(hex: "1A1408")

    // Ancient Scroll palette
    static let scrollPapyrus = Color(hex: "F4E4BC")
    static let scrollSepia = Color(hex: "8B7355")
    static let scrollInk = Color(hex: "2C2416")
    static let scrollBorder = Color(hex: "A0845C")

    // Stained Glass palette
    static let glassAmethyst = Color(hex: "9B59B6")
    static let glassRuby = Color(hex: "C0392B")
    static let glassEmerald = Color(hex: "27AE60")
    static let glassSapphire = Color(hex: "2980B9")
    static let glassGold = Color(hex: "F1C40F")
    static let glassVoid = Color(hex: "1A0A2E")
}
