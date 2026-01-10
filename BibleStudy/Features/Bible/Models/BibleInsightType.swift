import Combine
import SwiftUI

// MARK: - Bible Insight Type
// Categories of marginalia insights with distinct visual identities
// Core to the Bible feature

/// Categories of marginalia insights with distinct visual identities
enum BibleInsightType: CaseIterable {
    case connection   // Cross-references (Amber)
    case greek        // Original language (Indigo)
    case theology     // Doctrinal concepts (Green)
    case question     // Personal reflection (Pink)

    /// Display label for UI (updated for Reading Mode)
    var label: String {
        switch self {
        case .connection: return "Connections"
        case .greek: return "Greek"
        case .theology: return "Theology"
        case .question: return "Reflection"
        }
    }

    /// Display color (wax seal aesthetic)
    var color: Color {
        switch self {
        case .connection: return .connectionAmber
        case .greek: return .greekBlue
        case .theology: return .theologyGreen
        case .question: return .personalRose
        }
    }

    /// SF Symbol icon for this insight type
    var icon: String {
        switch self {
        case .theology: return "sparkles"
        case .question: return "questionmark.circle"
        case .greek: return "character.book.closed"
        case .connection: return "arrow.triangle.branch"
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .connection: return 0.12
        case .greek: return 0.10
        case .theology: return 0.10
        case .question: return 0.12
        }
    }

    // MARK: - Persistence

    /// Key for persisting to UserDefaults/AppStorage
    var persistenceKey: String {
        switch self {
        case .connection: return "connection"
        case .greek: return "greek"
        case .theology: return "theology"
        case .question: return "question"
        }
    }

    /// Create from persistence key
    static func from(rawValue: String) -> BibleInsightType? {
        switch rawValue {
        case "connection": return .connection
        case "greek": return .greek
        case "theology": return .theology
        case "question": return .question
        default: return nil
        }
    }
}

// MARK: - Marginalia Insight

/// A single insight that appears as marginalia alongside Scripture text
struct MarginaliaInsight: Identifiable, Equatable {
    let id = UUID()
    let phrase: String
    let type: BibleInsightType
    let title: String
    let content: String
    let icon: String

    static func == (lhs: MarginaliaInsight, rhs: MarginaliaInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Streaming State

/// Tracks AI streaming simulation state for each insight
class BibleInsightStreamingState: ObservableObject {
    @Published var streamedInsights: Set<UUID> = []
    @Published var currentlyStreaming: UUID?
    @Published var displayedText: [UUID: String] = [:]

    func hasStreamed(_ insight: MarginaliaInsight) -> Bool {
        streamedInsights.contains(insight.id)
    }

    func markAsStreamed(_ insight: MarginaliaInsight) {
        streamedInsights.insert(insight.id)
    }

    func startStreaming(_ insight: MarginaliaInsight) {
        currentlyStreaming = insight.id
        displayedText[insight.id] = ""
    }

    func appendCharacter(_ char: Character, for insight: MarginaliaInsight) {
        displayedText[insight.id, default: ""].append(char)
    }

    func finishStreaming(_ insight: MarginaliaInsight) {
        currentlyStreaming = nil
        displayedText[insight.id] = insight.content
        markAsStreamed(insight)
    }
}

// MARK: - Color Extension

extension Color {
    /// Bible insight palette - adaptive colors from asset catalog
    /// These automatically respond to light/dark mode
    static var bibleInsightParchment: Color { .appBackground }
    static var bibleInsightCardBackground: Color { .surfaceBackground }
    static var bibleInsightText: Color { .primaryText }
    static var bibleInsightAccent: Color { Color.accentIndigo }
    static var bibleInsightGold: Color { Color.accentBronze }
}
