import SwiftUI

// MARK: - Card Style
// Configuration for time-aware feature cards
// Encapsulates all visual properties that vary by time of day

struct CardStyle {
    // MARK: - Colors

    let textColor: Color
    let secondaryTextColor: Color
    let backgroundColor: Color
    let backgroundOpacity: Double

    // MARK: - Effects

    let useMaterial: Bool
    let borderGradient: [Color]
    let shadowOpacity: Double
    let pressedShadowOpacity: Double
    let brightnessOnPress: Double

    // MARK: - Sizing

    let cornerRadius: CGFloat
    let padding: CGFloat
    let borderWidth: CGFloat
    let shadowRadius: CGFloat

    // MARK: - Typography

    let titleFont: Font
    let subtitleFont: Font
    let labelFont: Font
    let iconSize: CGFloat

    // MARK: - Roman Style (Unified - Uses Surface Layer)
    // Theme-aware style that responds to Light/Dark modes via Asset Catalog
    // Uses imperialPurple accent and stoic neutrals for monumental clarity

    static func roman(isPrimary: Bool, colorScheme: ColorScheme = .light) -> CardStyle {
        let isDark = colorScheme == .dark

        return CardStyle(
            // Text colors from Surface layer
            textColor: Color("AppTextPrimary"),
            secondaryTextColor: Color("AppTextSecondary"),
            // Card background
            backgroundColor: isDark ? .white : Color.appBackground,
            backgroundOpacity: isDark ? 0.06 : 0.9,
            // Effects
            useMaterial: !isDark,
            borderGradient: isPrimary
                ? [Color("AppAccentAction").opacity(isDark ? 0.5 : 0.35),
                   Color("AccentBronze").opacity(isDark ? 0.3 : 0.2),
                   Color("AppAccentAction").opacity(isDark ? 0.2 : 0.15)]
                : [Color("AppAccentAction").opacity(isDark ? 0.2 : 0.15),
                   Color("FeedbackInfo").opacity(isDark ? 0.1 : 0.08)],
            shadowOpacity: isDark ? 0.2 : 0.12,
            pressedShadowOpacity: isDark ? 0.3 : 0.18,
            brightnessOnPress: isDark ? 0.03 : 0,
            // Sizing - Roman monumental proportions
            cornerRadius: isPrimary ? 16 : 12,
            padding: isPrimary ? 20 : 16,
            borderWidth: isPrimary ? 1.5 : 1,
            shadowRadius: isPrimary ? 18 : 12,
            // Typography - Roman gravitas
            titleFont: isPrimary
                ? Typography.Scripture.heading  // Serif for headings
                // swiftlint:disable:next hardcoded_font_system
                : .system(size: 15, weight: .semibold),  // Secondary card title
            subtitleFont: Typography.Command.body,
            labelFont: Typography.Command.meta,  // Sans uppercase for labels
            iconSize: isPrimary ? 24 : 18
        )
    }
}
