import SwiftUI
import UIKit

// MARK: - Custom Fonts
// Centralized font loading with availability checks and system fallbacks
// Used by Typography tokens to reduce duplication

struct CustomFonts {

    // MARK: - Cormorant Garamond

    /// Cormorant Garamond Regular with system serif fallback
    /// Use: Verse text, AI insight body, reading content
    static func cormorantRegular(size: CGFloat) -> Font {
        if UIFont(name: "CormorantGaramond-Regular", size: size) != nil {
            return .custom("CormorantGaramond-Regular", size: size)
        }
        return .system(size: size, design: .serif)
    }

    /// Cormorant Garamond Italic with system serif italic fallback
    /// Use: Poetic verses, quotes, marginalia, emphasized content
    static func cormorantItalic(size: CGFloat) -> Font {
        if UIFont(name: "CormorantGaramond-Italic", size: size) != nil {
            return .custom("CormorantGaramond-Italic", size: size)
        }
        return .system(size: size, design: .serif).italic()
    }

    /// Cormorant Garamond SemiBold with system serif semibold fallback
    /// Use: Emphasis, cross-references, key points in insights
    static func cormorantSemiBold(size: CGFloat) -> Font {
        if UIFont(name: "CormorantGaramond-SemiBold", size: size) != nil {
            return .custom("CormorantGaramond-SemiBold", size: size)
        }
        return .system(size: size, weight: .semibold, design: .serif)
    }

    // MARK: - Cinzel

    /// Cinzel Regular with system medium fallback
    /// Use: References, decorative headers, manuscript accents
    static func cinzelRegular(size: CGFloat) -> Font {
        if UIFont(name: "Cinzel-Regular", size: size) != nil {
            return .custom("Cinzel-Regular", size: size)
        }
        // Fallback to medium weight system font for similar visual weight
        return .system(size: size, weight: .medium)
    }

    // MARK: - Availability Checking

    /// Check if a custom font is available in the bundle
    /// Use this for conditional features or debugging font loading issues
    static func isAvailable(_ fontName: String) -> Bool {
        UIFont(name: fontName, size: 12) != nil
    }

    /// Log all available custom fonts (useful for debugging)
    static func logAvailableCustomFonts() {
        let customFonts = [
            "CormorantGaramond-Regular",
            "CormorantGaramond-Italic",
            "CormorantGaramond-SemiBold",
            "Cinzel-Regular"
        ]

        for fontName in customFonts {
            let available = isAvailable(fontName)
            print("📘 \(fontName): \(available ? "✅ Available" : "❌ Not available")")
        }
    }
}
