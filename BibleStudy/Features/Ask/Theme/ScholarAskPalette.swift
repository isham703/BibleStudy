import SwiftUI

// MARK: - Scholar Ask Palette
// Scholarly Companion color scheme for the Ask AI chat feature
// Warm vellum backgrounds, indigo accents, editorial typography

enum ScholarAskPalette {

    // MARK: - Backgrounds
    /// Warm vellum background - main chat background
    static let background = Color(hex: "f8f5f0")
    /// Pure white for message surfaces
    static let surface = Color.white
    /// Light cream for input areas
    static let inputBackground = Color.white

    // MARK: - Text Colors
    /// Primary text - deep ink
    static let primaryText = Color(hex: "1c1917")
    /// Secondary text - muted
    static let secondaryText = Color(hex: "44403c")
    /// Tertiary text - subtle
    static let tertiaryText = Color(hex: "78716c")
    /// Placeholder text
    static let placeholder = Color(hex: "a8a29e")

    // MARK: - Accent Colors
    /// Primary accent - scholar indigo
    static let accent = Color.scholarIndigo
    /// Subtle accent for backgrounds
    static let accentSubtle = Color.scholarIndigo.opacity(0.08)
    /// Citation accent - green
    static let citation = Color(hex: "059669")
    /// Cross-reference accent
    static let crossReference = Color(hex: "f59e0b")

    // MARK: - Message Bubbles
    /// User message bubble background
    static let userBubble = Color.scholarIndigo
    /// User message text
    static let userText = Color.white
    /// AI message bubble background
    static let aiBubble = Color.white
    /// AI message text
    static let aiText = Color(hex: "1c1917")
    /// AI message border
    static let aiBorder = Color(hex: "e7e5e4")

    // MARK: - Interactive Elements
    /// Divider color
    static let divider = Color(hex: "e7e5e4")
    /// Card border
    static let cardBorder = Color(hex: "e5e5e5")

    // MARK: - Opacity Constants
    enum Opacity {
        static let subtle: CGFloat = 0.08
        static let light: CGFloat = 0.15
        static let medium: CGFloat = 0.3
        static let strong: CGFloat = 0.6
    }

    // MARK: - Shadows
    static let shadow = Color.scholarIndigo.opacity(0.06)
}
