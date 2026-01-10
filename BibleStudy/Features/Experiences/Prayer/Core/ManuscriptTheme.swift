import SwiftUI

// MARK: - Manuscript Theme
// DEPRECATED: Use StoicTheme for new code
// Centralized theming for Prayers from the Deep
// Illuminated manuscript aesthetic with gold and parchment colors
//
// MIGRATION: This file provides backward compatibility.
// New components should use StoicTheme directly.
// Existing references will compile but generate warnings.

@available(*, deprecated, renamed: "StoicTheme", message: "Migrate to StoicTheme for Roman/Stoic design system")
enum ManuscriptTheme {

    // MARK: - Primary Gold Colors

    /// Divine Gold - Primary accent (#D4A853)
    /// Note: Uses bronze seal hex directly for static constant in deprecated layer
    static let gold = Color.accentBronze

    /// Illuminated Gold - Highlight variant (#E8C978)
    static let goldHighlight = Color.accentBronze

    /// Ancient Gold - Deep/shadow variant (#8B6914)
    static let goldDeep = Color.ochreDeep

    /// Burnished Gold - Border/gradient variant (#C9943D)
    static let goldBurnished = Color.accentBronze

    // MARK: - Background Colors

    /// Dark Parchment - Primary background (#1A1816)
    static let parchment = Color.surfaceInk

    /// Elevated Surface - Cards/inputs (#252220)
    static let surface = Color.surfaceRaised

    // MARK: - Text Colors

    /// Primary Text - High contrast (#E8E4DC)
    static let textPrimary = Color.moonlitParchment

    /// Secondary Text - Muted (#A8A29E)
    static let textSecondary = Color.fadedMoonlight

    // MARK: - Crisis Modal Colors

    /// Rose Accent for crisis modal (#F43F5E)
    static let roseAccent = Color.roseAccent

    /// Rose Highlight background
    static let roseHighlight = roseAccent.opacity(Theme.Opacity.medium)

    /// Surface Border
    static let surfaceBorder = Color.white.opacity(Theme.Opacity.subtle)

    /// Sacred Navy background for crisis modal (#0A0D1A)
    static let sacredNavy = Color.manuscriptNavy

    // MARK: - Gradients

    /// Gold gradient for buttons and highlights
    static let goldGradient = LinearGradient(
        colors: [goldHighlight, gold, goldBurnished],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold border gradient for cards (focused state)
    // swiftlint:disable:next hardcoded_gradient_colors
    static let goldBorderGradient = LinearGradient(
        colors: [gold.opacity(Theme.Opacity.heavy), goldDeep.opacity(Theme.Opacity.medium)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle gold border for unfocused state
    // swiftlint:disable:next hardcoded_gradient_colors
    static let goldBorderSubtle = LinearGradient(
        colors: [gold.opacity(Theme.Opacity.light), goldDeep.opacity(Theme.Opacity.subtle)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography

    enum Font {
        /// Cinzel for headers and emphasis
        static func cinzel(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .custom("Cinzel", size: size).weight(weight)
        }

        /// Cormorant Garamond for body text
        static func cormorant(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .custom("Cormorant Garamond", size: size).weight(weight)
        }

        /// System font for UI elements
        static func system(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            // swiftlint:disable:next hardcoded_font_system
            .system(size: size, weight: weight)
        }
    }

    // MARK: - Opacity Values

    enum Opacity {
        static let goldGlow: CGFloat = 0.08
        static let goldGlowAnimated: CGFloat = 0.04
        static let borderFocused: CGFloat = 0.5
        static let borderUnfocused: CGFloat = 0.15
        static let shadowColor: CGFloat = 0.4
        static let textureOverlay: CGFloat = 0.03
    }

    // MARK: - Animation Constants (Deprecated)

    @available(*, deprecated, message: "Use Theme.Animation for unified animation system")
    enum Animation {
        static let illuminationDuration: TimeInterval = 8.0
        static let phaseTransition: TimeInterval = 0.6
        static let toastDuration: TimeInterval = 2.0
    }

    // MARK: - Spacing

    enum Spacing {
        static let horizontalPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 28
        static let dividerPadding: CGFloat = 40
    }
}
