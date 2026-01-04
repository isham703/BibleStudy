import SwiftUI

// MARK: - Memorization Phase
// The three phases of interaction in each memory palace room
// Visualize → Connect → Recall creates a progressive learning experience

enum MemorizationPhase: Int, CaseIterable {
    case visualize = 0
    case connect = 1
    case recall = 2

    // MARK: - Display Properties

    var title: String {
        switch self {
        case .visualize:
            return "Visualize"
        case .connect:
            return "Connect"
        case .recall:
            return "Recall"
        }
    }

    var instruction: String {
        switch self {
        case .visualize:
            return "Absorb the imagery and scripture"
        case .connect:
            return "Tap each word to reveal"
        case .recall:
            return "Type the phrase from memory"
        }
    }

    var icon: String {
        switch self {
        case .visualize:
            return "eye.fill"
        case .connect:
            return "hand.tap.fill"
        case .recall:
            return "brain.head.profile"
        }
    }

    // MARK: - Phase Count

    static var count: Int {
        allCases.count
    }

    // MARK: - Navigation

    var next: MemorizationPhase? {
        switch self {
        case .visualize:
            return .connect
        case .connect:
            return .recall
        case .recall:
            return nil
        }
    }

    var previous: MemorizationPhase? {
        switch self {
        case .visualize:
            return nil
        case .connect:
            return .visualize
        case .recall:
            return .connect
        }
    }

    var isFirst: Bool {
        self == .visualize
    }

    var isLast: Bool {
        self == .recall
    }
}

// MARK: - Text Normalization for Recall Validation

extension String {
    /// Normalizes text for recall validation
    /// - Strips punctuation
    /// - Normalizes whitespace (collapses multiple spaces)
    /// - Case-insensitive (lowercased)
    func normalizedForRecall() -> String {
        self.lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters).joined()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Checks if this string matches another for recall purposes
    func matchesRecall(_ other: String) -> Bool {
        self.normalizedForRecall() == other.normalizedForRecall()
    }
}
