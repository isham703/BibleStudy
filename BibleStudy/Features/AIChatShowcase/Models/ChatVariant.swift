import SwiftUI

// MARK: - Chat Variant
// Defines the available AI Chat design variations for the showcase

enum ChatVariant: String, CaseIterable, Identifiable {
    case minimalStudio
    case scholarlyCompanion
    case warmSanctuary

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String {
        switch self {
        case .minimalStudio:
            return "Minimal Studio"
        case .scholarlyCompanion:
            return "Scholarly Companion"
        case .warmSanctuary:
            return "Warm Sanctuary"
        }
    }

    var subtitle: String {
        switch self {
        case .minimalStudio:
            return "Clean, modern, focused conversation"
        case .scholarlyCompanion:
            return "Research-driven with citations"
        case .warmSanctuary:
            return "Soft and contemplative dialogue"
        }
    }

    var description: String {
        switch self {
        case .minimalStudio:
            return "Ultra-clean interface with maximum whitespace. Perfect for distraction-free Bible study conversations."
        case .scholarlyCompanion:
            return "Editorial design with inline citations, cross-references, and scholarly annotations."
        case .warmSanctuary:
            return "Warm, inviting atmosphere with soft gradients and contemplative pacing."
        }
    }

    var icon: String {
        switch self {
        case .minimalStudio:
            return "bubble.left.and.bubble.right"
        case .scholarlyCompanion:
            return "text.book.closed"
        case .warmSanctuary:
            return "heart.text.square"
        }
    }

    var accentColor: Color {
        switch self {
        case .minimalStudio:
            return Color(hex: "18181b") // Zinc-900 - minimal black
        case .scholarlyCompanion:
            return .scholarIndigo
        case .warmSanctuary:
            return Color(hex: "c9943d") // Burnished gold
        }
    }

    var previewGradient: [Color] {
        switch self {
        case .minimalStudio:
            return [Color(hex: "fafafa"), Color(hex: "f4f4f5")]
        case .scholarlyCompanion:
            return [Color(hex: "f8f5f0"), Color(hex: "f5ede0")]
        case .warmSanctuary:
            return [Color(hex: "1c1917"), Color(hex: "292524")]
        }
    }

    var tags: [String] {
        switch self {
        case .minimalStudio:
            return ["Modern", "Clean", "Focused"]
        case .scholarlyCompanion:
            return ["Academic", "Citations", "Research"]
        case .warmSanctuary:
            return ["Warm", "Intimate", "Contemplative"]
        }
    }
}
