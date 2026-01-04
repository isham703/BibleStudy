import Combine
import SwiftUI

// MARK: - Living Commentary Models
// Shared data models for all Living Commentary variants
// Aesthetic: Illuminated Editorial — medieval scriptorium meets modern AI

// MARK: - Marginalia Insight

/// A single insight that appears as marginalia alongside Scripture text
struct MarginaliaInsight: Identifiable, Equatable {
    let id = UUID()
    let phrase: String
    let type: InsightType
    let title: String
    let content: String
    let icon: String

    static func == (lhs: MarginaliaInsight, rhs: MarginaliaInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Insight Type

/// Categories of marginalia insights with distinct visual identities
enum InsightType: CaseIterable {
    case connection   // Cross-references (Amber)
    case greek        // Original language (Indigo)
    case theology     // Doctrinal concepts (Green)
    case question     // Personal reflection (Pink)

    var label: String {
        switch self {
        case .connection: return "Connection"
        case .greek: return "Original Greek"
        case .theology: return "Theology"
        case .question: return "Personal"
        }
    }

    var color: Color {
        switch self {
        case .connection: return Color(hex: "f59e0b") // Amber
        case .greek: return Color(hex: "6366f1")      // Indigo
        case .theology: return Color(hex: "10b981")   // Green
        case .question: return Color(hex: "ec4899")   // Pink
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
}

// MARK: - Demo Data

/// Pre-generated marginalia for John 1:1 (cost-efficient, no API calls)
enum LivingCommentaryDemoData {

    static let verseReference = "John 1:1"
    static let verseText = "In the beginning was the Word, and the Word was with God, and the Word was God."
    static let bookName = "John"
    static let chapterNumber = 1

    static let insights: [MarginaliaInsight] = [
        MarginaliaInsight(
            phrase: "In the beginning",
            type: .connection,
            title: "Genesis Echo",
            content: "John deliberately mirrors Genesis 1:1 — 'In the beginning God created...' He's making a profound theological claim: Jesus existed before creation itself.",
            icon: "link"
        ),
        MarginaliaInsight(
            phrase: "the Word",
            type: .greek,
            title: "Λόγος (Logos)",
            content: "The Greek 'Logos' meant far more than 'word.' To Greek philosophers, it was the rational principle ordering the universe. John bridges Jewish and Greek thought, declaring Jesus as the cosmic Word.",
            icon: "textformat.abc"
        ),
        MarginaliaInsight(
            phrase: "was with God",
            type: .theology,
            title: "Distinct yet United",
            content: "The preposition 'with' (πρός) suggests intimate face-to-face relationship. The Word is distinct from the Father, yet eternally present with Him — the mystery of the Trinity.",
            icon: "person.2.fill"
        ),
        MarginaliaInsight(
            phrase: "was God",
            type: .question,
            title: "A Question for You",
            content: "You've explored this verse before. Last time you wondered about the Trinity. Has your understanding shifted? What feels different reading it now?",
            icon: "questionmark.circle.fill"
        )
    ]

    /// Verse segments for immersive scroll variant
    static let verseSegments: [(text: String, insight: MarginaliaInsight?)] = [
        ("In the beginning", insights[0]),
        ("was", nil),
        ("the Word,", insights[1]),
        ("and the Word was with God,", insights[2]),
        ("and the Word", nil),
        ("was God.", insights[3])
    ]
}

// MARK: - Streaming State

/// Tracks AI streaming simulation state for each insight
class InsightStreamingState: ObservableObject {
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
    /// Living Commentary palette
    static let commentaryParchment = Color(hex: "faf8f5")
    static let commentaryCardBackground = Color(hex: "f5f3f0")
    static let commentaryText = Color(hex: "1a1a1a")
    static let commentaryAccent = Color(hex: "6366f1")
    static let commentaryGold = Color(hex: "d4a853")
}
