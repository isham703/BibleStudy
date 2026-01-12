import SwiftUI

// MARK: - Breathing Pattern Model

/// Describes a breathing technique with phase durations and presentation details.
struct BreathingPattern: Identifiable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    let inhale: Double
    let hold1: Double
    let exhale: Double
    let hold2: Double
    let description: String
    let color: Color

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        inhale: Double,
        hold1: Double,
        exhale: Double,
        hold2: Double,
        description: String,
        color: Color
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.inhale = inhale
        self.hold1 = hold1
        self.exhale = exhale
        self.hold2 = hold2
        self.description = description
        self.color = color
    }

    /// Total duration of one full breathing cycle.
    var totalCycle: Double {
        inhale + hold1 + exhale + hold2
    }

    // MARK: - Preset Patterns (3 patterns - excluding Energize)

    static let patterns: [BreathingPattern] = [calm, box, sleep]

    /// Simple 4-4 breathing for relaxation
    static let calm = BreathingPattern(
        name: "Calm",
        icon: "leaf.fill",
        inhale: 4, hold1: 0, exhale: 4, hold2: 0,
        description: "Simple 4-4 breathing for relaxation",
        color: .mint
    )

    /// Navy SEAL box breathing technique for focus
    static let box = BreathingPattern(
        name: "Box",
        icon: "square.fill",
        inhale: 4, hold1: 4, exhale: 4, hold2: 4,
        description: "Navy SEAL technique for focus",
        color: .cyan
    )

    /// Dr. Weil's 4-7-8 sleep technique (default for Compline)
    static let sleep = BreathingPattern(
        name: "4-7-8",
        icon: "moon.fill",
        inhale: 4, hold1: 7, exhale: 8, hold2: 0,
        description: "Dr. Weil's sleep technique",
        color: .indigo
    )

    // MARK: - Compline-Specific

    /// Night-themed variant for Compline integration
    static let complineSleep = BreathingPattern(
        name: "4-7-8",
        icon: "moon.stars.fill",
        inhale: 4, hold1: 7, exhale: 8, hold2: 0,
        description: "Calming breath for peaceful rest",
        color: Color("AppAccentAction").opacity(0.2) // Compline starlight
    )
}

// MARK: - Breathing Phase

/// Represents the current phase of the breathing exercise.
enum BreathingPhase: String, Equatable {
    case inhale = "Breathe In"
    case hold1 = "Hold"
    case exhale = "Breathe Out"
    case hold2 = "Rest"
    case idle = "Tap to Begin"

    /// Visual scale to apply to the breathing circle for each phase.
    var scale: CGFloat {
        switch self {
        case .inhale: return 1.0
        case .hold1: return 1.0
        case .exhale: return 0.6
        case .hold2: return 0.6
        case .idle: return 0.7
        }
    }

    /// Whether the phase should animate the circle size.
    var shouldAnimate: Bool {
        switch self {
        case .inhale, .exhale:
            return true
        case .hold1, .hold2, .idle:
            return false
        }
    }

    /// SF Symbol icon for the phase.
    var icon: String {
        switch self {
        case .inhale: return "arrow.down"
        case .exhale: return "arrow.up"
        case .hold1, .hold2: return "pause.fill"
        case .idle: return "play.fill"
        }
    }

    /// Compline-specific icons with spiritual context.
    var complineIcon: String {
        switch self {
        case .inhale: return "wind"
        case .hold1: return "pause.circle"
        case .exhale: return "leaf"
        case .hold2: return "moon.zzz"
        case .idle: return "play.circle"
        }
    }
}
