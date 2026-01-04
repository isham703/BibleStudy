import SwiftUI

// MARK: - Prayers Showcase Variant
// Enum defining the three prayer page design variations

enum PrayersShowcaseVariant: String, CaseIterable, Identifiable {
    case sacredManuscript = "Sacred Manuscript"
    case desertSilence = "Desert Silence"
    case auroraVeil = "Aurora Veil"

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .sacredManuscript:
            return "Illuminated Medieval"
        case .desertSilence:
            return "Contemplative Minimal"
        case .auroraVeil:
            return "Luminous Glass"
        }
    }

    var description: String {
        switch self {
        case .sacredManuscript:
            return "Medieval scriptorium at twilight. Gold leaf catches candlelight as prayers materialize like sacred artifacts from the Book of Kells."
        case .desertSilence:
            return "A desert hermitage at dawn. Words appear one at a time, like thoughts arising in meditation. The silence between words matters."
        case .auroraVeil:
            return "Northern lights captured in glass. Luminous, alive, otherworldly. Cards float on layers of crystalline aurora light."
        }
    }

    var icon: String {
        switch self {
        case .sacredManuscript:
            return "book.closed.fill"
        case .desertSilence:
            return "circle"
        case .auroraVeil:
            return "sparkles"
        }
    }

    var accentColor: Color {
        switch self {
        case .sacredManuscript:
            return .manuscriptGold
        case .desertSilence:
            return .desertSand
        case .auroraVeil:
            return .auroraViolet
        }
    }

    var backgroundStyle: BackgroundStyle {
        switch self {
        case .sacredManuscript:
            return .light
        case .desertSilence:
            return .light
        case .auroraVeil:
            return .dark
        }
    }

    enum BackgroundStyle {
        case light, dark
    }

    // MARK: - Color Palette for Preview Strip

    func paletteColor(_ index: Int) -> Color {
        switch self {
        case .sacredManuscript:
            return [.manuscriptGold, .manuscriptVermillion, .manuscriptVellum, .manuscriptUmber][index]
        case .desertSilence:
            return [.desertSumiInk, .desertAsh, .desertSand, .desertDawnMist][index]
        case .auroraVeil:
            return [.auroraViolet, .auroraTeal, .auroraRose, .auroraVoid][index]
        }
    }

    // MARK: - Badge for Special Features

    var badge: String? {
        switch self {
        case .desertSilence:
            return "SIGNATURE"
        default:
            return nil
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var page: some View {
        switch self {
        case .sacredManuscript:
            SacredManuscriptView()
        case .desertSilence:
            DesertSilenceView()
        case .auroraVeil:
            AuroraVeilView()
        }
    }
}

// MARK: - Prayers Showcase Colors

extension Color {
    // Sacred Manuscript palette
    static let manuscriptVellum = Color(hex: "F5EBD7")
    static let manuscriptUmber = Color(hex: "2C1810")
    static let manuscriptGold = Color(hex: "C9A227")
    static let manuscriptVermillion = Color(hex: "C84536")
    static let manuscriptOxide = Color(hex: "8B6914")
    static let manuscriptCandlelight = Color(hex: "FFEFD5")

    // Desert Silence palette
    static let desertDawnMist = Color(hex: "FAF8F5")
    static let desertSumiInk = Color(hex: "1A1A1A")
    static let desertAsh = Color(hex: "9A9590")
    static let desertSand = Color(hex: "C4B8A8")
    static let desertDawnBlush = Color(hex: "F5E6E0")

    // Aurora Veil palette
    static let auroraVoid = Color(hex: "0A0E1A")
    static let auroraViolet = Color(hex: "7C3AED")
    static let auroraTeal = Color(hex: "06B6D4")
    static let auroraRose = Color(hex: "EC4899")
    static let auroraGreen = Color(hex: "10B981")
    static let auroraStarlight = Color(hex: "E2E8F0")
}
