import SwiftUI

// MARK: - NoteTemplate UI Extensions
// UI-only styling - lives in Theme layer to avoid SwiftUI dependency in Core models
// Design: Each template has a distinct accent color for visual differentiation

extension NoteTemplate {
    /// Accent color for template-based theming
    /// Used by indicators, chips, and card borders
    var accentColor: Color {
        switch self {
        case .freeform:
            return Color("AppAccentAction")     // Default purple
        case .observation:
            return Color("FeedbackSuccess")     // Green - seeing/observing
        case .application:
            return Color("FeedbackWarning")     // Amber - warmth/action
        case .questions:
            return Color("FeedbackError")       // Red - matches Reflection tab CTA
        case .exegesis:
            return Color("AccentBronze")        // Bronze - scholarly/deep
        case .prayer:
            return Color("AccentGold")          // Gold - spiritual/sacred
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        "\(displayName) note"
    }
}
