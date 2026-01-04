import SwiftUI

// MARK: - Home Page Variant
// Enum defining the three home page design variations
// Each variant showcases AI features as doorways to deeper experiences

enum HomePageVariant: String, CaseIterable, Identifiable {
    case liturgicalHours = "Liturgical Hours"
    case candlelitSanctuary = "Candlelit Sanctuary"
    case scholarsAtrium = "Scholar's Atrium"
    case sacredThreshold = "Sacred Threshold"

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .liturgicalHours:
            return "Time-Aware Sanctuary"
        case .candlelitSanctuary:
            return "Nocturnal Contemplation"
        case .scholarsAtrium:
            return "Editorial Manuscript"
        case .sacredThreshold:
            return "Architectural Journey"
        }
    }

    var description: String {
        switch self {
        case .liturgicalHours:
            return "Automatically adapts to the time of day. Dawn, Meridian, Afternoon, Vespers, and Compline - each with unique atmosphere."
        case .candlelitSanctuary:
            return "Intimate, devotional design for evening and bedtime use. Starfield background with breathing candlelight."
        case .scholarsAtrium:
            return "Intellectual, revelatory light-mode design for daytime study. Marginalia-style annotations."
        case .sacredThreshold:
            return "Exploratory, adventurous design with room-based navigation. Architectural pillars frame the journey."
        }
    }

    var icon: String {
        switch self {
        case .liturgicalHours:
            return "clock.fill"
        case .candlelitSanctuary:
            return "moon.stars.fill"
        case .scholarsAtrium:
            return "text.book.closed.fill"
        case .sacredThreshold:
            return "building.columns.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .liturgicalHours:
            return SanctuaryTimeOfDay.current.primaryColor
        case .candlelitSanctuary:
            return .candleAmber
        case .scholarsAtrium:
            return .scholarIndigo
        case .sacredThreshold:
            return .thresholdPurple
        }
    }

    var backgroundStyle: BackgroundStyle {
        switch self {
        case .liturgicalHours:
            return SanctuaryTimeOfDay.current.isLightMode ? .light : .dark
        case .candlelitSanctuary:
            return .dark
        case .scholarsAtrium:
            return .light
        case .sacredThreshold:
            return .dark
        }
    }

    enum BackgroundStyle {
        case light, dark
    }

    // MARK: - Color Palette for Preview Strip

    func paletteColor(_ index: Int) -> Color {
        switch self {
        case .liturgicalHours:
            // Show colors from all five times
            return [.dawnRose, .meridianAmber, .afternoonOchre, .vespersIndigo][index]
        case .candlelitSanctuary:
            return [.candleAmber, .roseIncense, .nightVoid, .starlight][index]
        case .scholarsAtrium:
            return [.scholarIndigo, .theologyGreen, .vellumCream, .scholarInk][index]
        case .sacredThreshold:
            return [.thresholdPurple, .thresholdGold, .thresholdRose, .thresholdBlue][index]
        }
    }

    // MARK: - Badge for Special Features

    var badge: String? {
        switch self {
        case .liturgicalHours:
            return "NEW"
        default:
            return nil
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var page: some View {
        switch self {
        case .liturgicalHours:
            TimeAwareSanctuaryPage()
        case .candlelitSanctuary:
            CandlelitSanctuaryPage()
        case .scholarsAtrium:
            ScholarsAtriumPage()
        case .sacredThreshold:
            SacredThresholdPage()
        }
    }
}
