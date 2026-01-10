import SwiftUI

// MARK: - Sanctuary Time of Day
// DEPRECATED: Time-awareness removed in Roman/Stoic design system
// Kept for backward compatibility with DevTools showcases
//
// The Roman design uses fixed layout with Bible Reading as primary CTA
// instead of changing emphasis based on time of day.

@available(*, deprecated, message: "Time-awareness removed - use RomanSanctuaryView with fixed layout")
enum SanctuaryTimeOfDay: String, CaseIterable, Identifiable, Equatable {
    case dawn       // 5am-9am   - Lauds/Morning Prayer
    case meridian   // 9am-12pm  - Terce/Sext
    case afternoon  // 12pm-5pm  - None/Midday
    case vespers    // 5pm-9pm   - Vespers/Evening Prayer
    case compline   // 9pm-5am   - Compline/Night Prayer

    var id: String { rawValue }

    // MARK: - Time Detection

    static var current: SanctuaryTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9: return .dawn
        case 9..<12: return .meridian
        case 12..<17: return .afternoon
        case 17..<21: return .vespers
        default: return .compline
        }
    }

    // MARK: - Display Properties

    var name: String {
        switch self {
        case .dawn: return "Dawn"
        case .meridian: return "Meridian"
        case .afternoon: return "Afternoon"
        case .vespers: return "Vespers"
        case .compline: return "Compline"
        }
    }

    var liturgicalName: String {
        switch self {
        case .dawn: return "Lauds"
        case .meridian: return "Terce"
        case .afternoon: return "Sext"
        case .vespers: return "Vespers"
        case .compline: return "Compline"
        }
    }

    var greeting: String {
        switch self {
        case .dawn: return "Good morning"
        case .meridian: return "Good morning"
        case .afternoon: return "Good afternoon"
        case .vespers: return "Good evening"
        case .compline: return "Good evening"
        }
    }

    var timeRange: String {
        switch self {
        case .dawn: return "5am - 9am"
        case .meridian: return "9am - 12pm"
        case .afternoon: return "12pm - 5pm"
        case .vespers: return "5pm - 9pm"
        case .compline: return "9pm - 5am"
        }
    }

    var mood: String {
        switch self {
        case .dawn: return "Awakening hope, fresh starts"
        case .meridian: return "Focused study, clarity"
        case .afternoon: return "Pause, contemplation"
        case .vespers: return "Winding down, gratitude"
        case .compline: return "Deep rest, sacred silence"
        }
    }

    // MARK: - Scripture & Content

    var verse: String {
        switch self {
        case .dawn:
            return "This is the day the Lord has made; let us rejoice and be glad in it."
        case .meridian:
            return "I am the light of the world. Whoever follows me will not walk in darkness."
        case .afternoon:
            return "Be still, and know that I am God."
        case .vespers:
            return "Let my prayer be counted as incense before you."
        case .compline:
            return "Your word is a lamp to my feet and a light to my path."
        }
    }

    var verseReference: String {
        switch self {
        case .dawn: return "Psalm 118:24"
        case .meridian: return "John 8:12"
        case .afternoon: return "Psalm 46:10"
        case .vespers: return "Psalm 141:2"
        case .compline: return "Psalm 119:105"
        }
    }

    // MARK: - Primary Feature

    var primaryCTA: String {
        switch self {
        case .dawn: return "Morning Devotion"
        case .meridian: return "Continue Study"
        case .afternoon: return "Pause & Reflect"
        case .vespers: return "Evening Prayer"
        case .compline: return "Compline"
        }
    }

    var primaryIcon: String {
        switch self {
        case .dawn: return "sun.max.fill"
        case .meridian: return "text.book.closed.fill"
        case .afternoon: return "leaf.fill"
        case .vespers: return "moon.fill"
        case .compline: return "moon.stars.fill"
        }
    }

    var primaryDescription: String {
        switch self {
        case .dawn: return "Start the day in the Word"
        case .meridian: return "Deep dive into commentary"
        case .afternoon: return "2-minute breathing meditation"
        case .vespers: return "Reflect on your day"
        case .compline: return "Begin your night prayer"
        }
    }

    // MARK: - Colors

    var primaryColor: Color {
        switch self {
        case .dawn: return .dawnAccent  // Orange accent for dawn
        case .meridian: return .meridianIllumination  // Bright gold illumination
        case .afternoon: return .afternoonAmber
        case .vespers: return .vespersAmber
        case .compline: return .candleAmber
        }
    }

    var secondaryColor: Color {
        switch self {
        case .dawn: return .dawnSunrise
        case .meridian: return .meridianVermillion  // Manuscript red accent
        case .afternoon: return .afternoonHoney
        case .vespers: return .vespersIndigo
        case .compline: return .roseIncense
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dawn: return .dawnLavender  // Cool lavender at top
        case .meridian: return .meridianParchment  // Warm parchment base
        case .afternoon: return .afternoonIvory  // Warm ivory base
        case .vespers: return .vespersSky
        case .compline: return .nightVoid
        }
    }

    var textColor: Color {
        switch self {
        case .dawn: return .dawnSlate  // Dark slate for contrast
        case .meridian: return .meridianSepia  // Rich sepia brown-black
        case .afternoon: return .afternoonEspresso  // Rich espresso brown
        case .vespers: return .vespersText
        case .compline: return .starlight
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .dawn: return .dawnSlateLight  // Lighter slate for secondary
        case .meridian: return .meridianUmber  // Warm brown secondary
        case .afternoon: return .afternoonMocha  // Mocha brown
        case .vespers: return .vespersText.opacity(Theme.Opacity.heavy)
        case .compline: return .moonMist
        }
    }

    var accentGoldColor: Color {
        switch self {
        case .dawn: return .dawnSunrise  // Warm sunrise orange
        case .meridian: return .meridianGilded  // Rich gilded gold
        case .afternoon: return .afternoonHoney  // Warm honey gold
        case .vespers: return .vespersGoldAccent
        case .compline: return .vesperGold
        }
    }

    // MARK: - Color Scheme

    var colorScheme: ColorScheme {
        switch self {
        case .dawn, .meridian, .afternoon:
            return .light
        case .vespers, .compline:
            return .dark
        }
    }

    var isLightMode: Bool {
        colorScheme == .light
    }

    // MARK: - Animation Properties

    var animationDirection: AnimationDirection {
        switch self {
        case .dawn: return .upward
        case .meridian: return .horizontal
        case .afternoon: return .settling
        case .vespers: return .downward
        case .compline: return .breathing
        }
    }

    var animationSpeed: AnimationSpeed {
        switch self {
        case .dawn: return .medium
        case .meridian: return .quick
        case .afternoon: return .slow
        case .vespers: return .mediumSlow
        case .compline: return .verySlow
        }
    }

    enum AnimationDirection {
        case upward, horizontal, settling, downward, breathing
    }

    enum AnimationSpeed {
        case quick, medium, mediumSlow, slow, verySlow

        var duration: Double {
            switch self {
            case .quick: return 0.3
            case .medium: return 0.5
            case .mediumSlow: return 0.7
            case .slow: return 1.0
            case .verySlow: return 1.5
            }
        }

        var breathingDuration: Double {
            switch self {
            case .quick: return 2.0
            case .medium: return 3.0
            case .mediumSlow: return 3.5
            case .slow: return 4.0
            case .verySlow: return 5.0
            }
        }
    }

    // MARK: - Navigation

    var previous: SanctuaryTimeOfDay? {
        guard let index = SanctuaryTimeOfDay.allCases.firstIndex(of: self), index > 0 else {
            return nil
        }
        return SanctuaryTimeOfDay.allCases[index - 1]
    }

    var next: SanctuaryTimeOfDay? {
        guard let index = SanctuaryTimeOfDay.allCases.firstIndex(of: self),
              index < SanctuaryTimeOfDay.allCases.count - 1 else {
            return nil
        }
        return SanctuaryTimeOfDay.allCases[index + 1]
    }
}

// MARK: - Preview Helper

extension SanctuaryTimeOfDay {
    /// Force a specific time for preview/testing purposes
    static func forHour(_ hour: Int) -> SanctuaryTimeOfDay {
        switch hour {
        case 5..<9: return .dawn
        case 9..<12: return .meridian
        case 12..<17: return .afternoon
        case 17..<21: return .vespers
        default: return .compline
        }
    }
}

// MARK: - Design Properties Extension

extension SanctuaryTimeOfDay {
    /// Whether this is an evening time period (uses dark mode)
    var isEvening: Bool {
        self == .vespers || self == .compline
    }

    /// Animation offset for header elements (direction varies by time)
    var headerAnimationOffset: CGSize {
        switch self {
        case .dawn:
            return CGSize(width: 0, height: -15)  // Upward - awakening
        case .meridian:
            return CGSize(width: -15, height: 0)  // Horizontal - focused clarity
        case .afternoon:
            return CGSize(width: 0, height: 10)   // Downward - settling
        case .vespers, .compline:
            return CGSize(width: 0, height: 8)    // Gentle downward - evening peace
        }
    }

    /// Animation offset for verse/content elements
    var contentAnimationOffset: CGSize {
        switch self {
        case .dawn:
            return CGSize(width: 0, height: -15)
        case .meridian:
            return CGSize(width: 20, height: 0)
        case .afternoon:
            return CGSize(width: 0, height: 10)
        case .vespers:
            return CGSize(width: 0, height: 10)
        case .compline:
            return CGSize(width: 0, height: 8)
        }
    }

    /// Flame color for streak badges
    var streakColor: Color {
        switch self {
        case .dawn: return .dawnAccent
        case .meridian: return .meridianIllumination
        case .afternoon: return .afternoonAmber
        case .vespers: return .vespersAmber
        case .compline: return .candleAmber
        }
    }

    /// Reference/accent text color for verse citations
    var referenceColor: Color {
        switch self {
        case .dawn: return .dawnAccent
        case .meridian: return .meridianIllumination
        case .afternoon: return .afternoonAmber
        case .vespers: return .vespersGoldAccent
        case .compline: return .candleAmber
        }
    }
}
