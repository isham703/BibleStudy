//
//  Colors.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Four-tier color architecture:
//  1. Pigments: Raw color values (near-black, soft ivory, bronze, indigo)
//  2. Surfaces: Theme-aware functions (background, surface, text, divider, control stroke)
//  3. Semantics: Role-based colors (accents, feedback colors)
//  4. StateOverlays: Centralized state management (pressed, selection, focus, disabled)
//

import SwiftUI

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Note: ThemeMode enum is defined in UserProfile.swift for persistence
// Helper extension to resolve .system mode:
extension ThemeMode {
    /// Helper: Resolve .system to actual mode based on environment
    static func current(from colorScheme: ColorScheme) -> ThemeMode {
        colorScheme == .dark ? .dark : .light
    }
}

// MARK: - Colors

/// New four-tier color system
/// Temporary name `Colors` to avoid conflict with existing Colors.swift
/// Will be renamed to `Colors` in Phase 7 when old system is deleted
enum Colors {

    // MARK: - Tier 1: Pigments (Raw Values)

    /// Raw color values - the foundational palette
    enum Pigment {
        // Dark mode pigments
        static let inkBg = Color(hex: "0B0B0C")           // Near-black (default dark mode, NOT pure black)
        static let inkText = Color(hex: "F5F5F5")         // Soft ivory (dark text, NOT pure white)
        static let inkTextSecondary = Color(hex: "6C6C6C") // Muted secondary

        // OLED mode only (NOT used in this migration - Phase 8)
        static let oledBg = Color(hex: "000000")          // Pure black reserved for OLED mode

        // Light mode pigments
        static let paperBg = Color(hex: "FAF7F2")         // Parchment warmth
        static let paperText = Color(hex: "121212")       // Ink on parchment
        static let paperStroke = Color(hex: "E6E0D6")     // Subtle dividers
    }

    // MARK: - Tier 2: Surfaces (Theme-Aware)

    /// Theme-aware surface colors - adapt to light/dark mode
    enum Surface {
        /// Main app background (near-black in dark, parchment in light)
        static func background(for mode: ThemeMode) -> Color {
            mode == .light ? Pigment.paperBg : Pigment.inkBg
        }

        /// Raised surfaces (cards, sheets)
        static func surface(for mode: ThemeMode) -> Color {
            mode == .light ? Color(hex: "F8F6F0") : Color(hex: "1A1A1A")
        }

        /// Primary text color
        static func textPrimary(for mode: ThemeMode) -> Color {
            mode == .light ? Pigment.paperText : Pigment.inkText
        }

        /// Secondary text color (70-80% opacity for hierarchy)
        static func textSecondary(for mode: ThemeMode) -> Color {
            (mode == .light ? Pigment.paperText : Pigment.inkText).opacity(0.75)
        }

        /// Tertiary text color (55-65% opacity for metadata)
        static func textTertiary(for mode: ThemeMode) -> Color {
            (mode == .light ? Pigment.paperText : Pigment.inkText).opacity(0.60)
        }

        /// Divider lines (10-16% opacity for subtlety)
        static func divider(for mode: ThemeMode) -> Color {
            (mode == .light ? Color(hex: "E6E0D6") : Color(hex: "2A2A2A")).opacity(0.15)
        }

        /// Control stroke (buttons, inputs) - contextual, not constant
        static func controlStroke(for mode: ThemeMode) -> Color {
            mode == .light ? Color(hex: "E6E0D6") : Color(hex: "2A2A2A")
        }
    }

    // MARK: - Tier 3: Semantics (Role-Based)

    /// Role-based semantic colors - accent colors and feedback states
    enum Semantic {
        /// AccentSeal: Muted bronze - used rarely like a stamp (headers, rare decorative moments)
        /// Rule: Seal = authority (rare usage)
        static func accentSeal(for mode: ThemeMode) -> Color {
            Color(hex: "8B7355")  // Same for both modes
        }

        /// AccentAction: Restrained indigo - interactive elements (links, buttons, selection)
        /// Rule: Action = usability (consistent interaction feedback)
        static func accentAction(for mode: ThemeMode) -> Color {
            mode == .light ? Color(hex: "4F46E5") : Color(hex: "6366F1")
        }

        /// OnAccentAction: Soft ivory for text on accent backgrounds (buttons)
        /// Maintains "soft ivory" doctrine - not pure white
        static func onAccentAction(for mode: ThemeMode) -> Color {
            Color(hex: "F5F5F5")  // Soft ivory, consistent with inkText
        }

        /// Error: Deep oxblood - functional, not bright red
        static func error(for mode: ThemeMode) -> Color {
            Color(hex: "8B3A3A")
        }

        /// Warning: Muted ochre - functional, not amber neon
        static func warning(for mode: ThemeMode) -> Color {
            Color(hex: "B8860B")
        }

        /// Success: Desaturated olive - functional, not green glow
        static func success(for mode: ThemeMode) -> Color {
            Color(hex: "6B7C59")
        }

        /// Info: Slate/steel - neutral
        static func info(for mode: ThemeMode) -> Color {
            Color(hex: "6B7280")
        }
    }

    // MARK: - Tier 4: State Overlays (Centralized State Management)

    /// Centralized state overlay management
    /// Prevents inconsistent state behavior across the app
    enum StateOverlay {
        /// Pressed state: 80% opacity for button feedback
        static func pressed(_ base: Color) -> Color {
            base.opacity(0.80)
        }

        /// Selection background: AccentAction at 15% opacity (verse selection, text selection)
        static func selection(_ base: Color) -> Color {
            base.opacity(0.15)
        }

        /// Focus stroke: AccentAction at 60% opacity (input focus rings)
        static func focusStroke(_ accent: Color) -> Color {
            accent.opacity(0.60)
        }

        /// Disabled state: 35% opacity
        static func disabled(_ base: Color) -> Color {
            base.opacity(0.35)
        }
    }
}

// MARK: - Highlight Colors

/// Highlight color options for verse annotations
enum HighlightColor: String, CaseIterable, Codable {
    case blue      // Greek Blue - Original language annotations
    case green     // Theology Green - Doctrinal notes
    case amber     // Connection Amber - Cross-references
    case rose      // Personal Rose - Reflective questions
    case purple    // Amethyst - General/spiritual

    var color: Color {
        switch self {
        case .blue: return Color(hex: "87CEEB")    // Light sky blue
        case .green: return Color(hex: "90EE90")   // Light green
        case .amber: return Color(hex: "F0E68C")   // Khaki/amber
        case .rose: return Color(hex: "FFB6C1")    // Light pink
        case .purple: return Color(hex: "DDA0DD")  // Plum
        }
    }

    /// Solid color for text or icons on the highlight
    var solidColor: Color {
        switch self {
        case .blue: return Color(hex: "4A90E2")     // Darker blue
        case .green: return Color(hex: "6B7C59")    // Olive green
        case .amber: return Color(hex: "B8860B")    // Dark goldenrod
        case .rose: return Color(hex: "C76E8B")     // Dusky rose
        case .purple: return Color(hex: "9370DB")   // Medium purple
        }
    }

    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .purple: return "Purple"
        }
    }

    /// Accessibility name for VoiceOver
    var accessibilityName: String {
        switch self {
        case .blue: return "Blue highlight"
        case .green: return "Green highlight"
        case .amber: return "Amber highlight"
        case .rose: return "Rose highlight"
        case .purple: return "Purple highlight"
        }
    }
}

// MARK: - Semantic Color Convenience Properties
// Static properties for mode-independent colors or dark-mode defaults
// Use these for bulk migration of hardcoded hex values

extension Color {
    // MARK: - Semantic Accents (Mode-Independent)

    /// Bronze seal - muted bronze for authority/decorative elements
    /// Maps to: Colors.Semantic.accentSeal (same in light/dark)
    static var accentBronze: Color { Color(hex: "8B7355") }

    /// Indigo action - interactive elements (dark mode default)
    /// For theme-aware usage, prefer Colors.Semantic.accentAction(for:)
    /// Note: Color.accentIndigo is auto-generated from AccentIndigo.colorset asset

    /// Indigo action light mode variant
    static var accentIndigoLight: Color { Color(hex: "4F46E5") }

    // MARK: - Semantic Feedback (Mode-Independent)

    /// Error red - oxblood for errors
    static var feedbackError: Color { Color(hex: "8B3A3A") }

    /// Warning ochre - muted amber for warnings
    static var feedbackWarning: Color { Color(hex: "B8860B") }

    /// Success olive - desaturated green for success
    static var feedbackSuccess: Color { Color(hex: "6B7C59") }

    /// Info slate - neutral gray for informational
    static var feedbackInfo: Color { Color(hex: "6B7280") }

    // MARK: - Surface Colors (Dark Mode Defaults)

    /// Near-black background (dark mode)
    static var surfaceInk: Color { Color(hex: "0B0B0C") }

    /// Raised surface (dark mode)
    static var surfaceRaised: Color { Color(hex: "1A1A1A") }

    /// Soft ivory text (dark mode)
    static var textIvory: Color { Color(hex: "F5F5F5") }

    /// Primary text alias (maps to textIvory for dark mode)
    static var textPrimary: Color { textIvory }

    /// Secondary text (muted, 75% opacity)
    static var textSecondary: Color { Color.gray.opacity(0.75) }

    /// Parchment background (light mode)
    static var surfaceParchment: Color { Color(hex: "FAF7F2") }

    /// Ink text (light mode)
    static var textInk: Color { Color(hex: "121212") }

    // MARK: - Decorative Colors

    /// Gold accent for decorative elements
    static var decorativeGold: Color { Color(hex: "D4AF37") }

    /// Taupe/stone for neutral decorative elements
    static var decorativeTaupe: Color { Color(hex: "9B8B7A") }

    /// Moonlit marble for light surfaces
    static var decorativeMarble: Color { Color(hex: "E8E4DC") }

    /// Warm cream for highlight backgrounds
    static var decorativeCream: Color { Color(hex: "F5E6B8") }

    /// Rose/dusky pink for accents
    static var decorativeRose: Color { Color(hex: "C76E8B") }

    // MARK: - UI Colors (Tailwind-inspired)

    /// Stone gray (Tailwind stone-400)
    static var stoneGray: Color { Color(hex: "A8A29E") }

    /// Light indigo tint (Tailwind indigo-100)
    static var indigoTint: Color { Color(hex: "E0E7FF") }

    /// Sky blue (Tailwind blue-400)
    static var skyBlue: Color { Color(hex: "60A5FA") }

    /// Purple accent (Tailwind purple-500)
    static var purpleAccent: Color { Color(hex: "A855F7") }

    /// Emerald green (Tailwind emerald-400)
    static var emeraldGreen: Color { Color(hex: "34D399") }

    /// Amber/orange (Tailwind amber-500)
    static var amberOrange: Color { Color(hex: "F59E0B") }

    /// Bright red (Tailwind red-500)
    static var brightRed: Color { Color(hex: "EF4444") }

    /// Fuchsia/pink (Tailwind fuchsia-400)
    static var fuchsiaPink: Color { Color(hex: "E879F9") }

    /// Yellow amber (Tailwind yellow-400)
    static var yellowAmber: Color { Color(hex: "FBBF24") }

    /// Violet (Tailwind violet-500)
    static var violetAccent: Color { Color(hex: "8B5CF6") }

    /// Blue accent (Tailwind blue-500)
    static var blueAccent: Color { Color(hex: "3B82F6") }

    /// Green teal (Tailwind emerald-500)
    static var greenTeal: Color { Color(hex: "10B981") }

    // MARK: - Dark Surface Variants

    /// Deep charcoal surface
    static var surfaceCharcoal: Color { Color(hex: "1A1816") }

    /// Dark warm surface
    static var surfaceWarm: Color { Color(hex: "252220") }

    /// Very dark background
    static var surfaceDeep: Color { Color(hex: "0A0908") }

    /// Slate gray surface (Tailwind gray-700)
    static var surfaceSlate: Color { Color(hex: "2D3748") }

    /// Medium gray surface
    static var surfaceMedium: Color { Color(hex: "3A3A3A") }

    /// Neutral gray
    static var neutralGray: Color { Color(hex: "808080") }

    /// Navy deep (for showcase backgrounds)
    static var navyDeep: Color { Color(hex: "1D4E89") }

    /// Dark ochre/bronze variant
    static var ochreDeep: Color { Color(hex: "8B6914") }

    /// Gold warm variant
    static var goldWarm: Color { Color(hex: "E8C978") }

    /// Off-white/ivory variant
    static var offWhite: Color { Color(hex: "F5F5F0") }

    /// Light gray
    static var lightGray: Color { Color(hex: "E5E5E5") }
}

// MARK: - Temporary Color Stubs (TO DELETE after production file migration)

extension Color {
    /// Legacy marble white - kept for backward compatibility
    static var marbleWhite: Color { Color(hex: "F5F5F5") }


    // Production decorative colors - TO DELETE after component migration

    /// Used in: IlluminatedIcon
    static var monasteryBlack: Color { Color(hex: "0B0B0C") }

    /// Used in: VerseNumberView
    static var verseNumber: Color { Color.gray.opacity(0.7) }

    /// Used in: Preview backgrounds
    static var chapelShadow: Color { Color(hex: "1A1A1A") }

    /// Used in: Breathe feature
    static var complineStarlight: Color { Color(hex: "E8D5B7") }

    /// Used in: DeveloperSectionView (showcase navigation)
    /// TO DELETE after DeveloperSectionView migration
    static var thresholdRose: Color { Color(hex: "C76E8B") }

    /// Used in: VellumScrollToast
    /// TO DELETE after VellumScrollToast migration
    static var burnishedGold: Color { Color(hex: "6B5844") }

    /// Legacy soft rose - kept for backward compatibility
    static var softRose: Color { Color(hex: "FFB6C1") }

    /// Faded moonlight - muted secondary text
    static var fadedMoonlight: Color { Color(hex: "A8A29E") }

    /// Moonlit marble - light surface color
    static var moonlitMarble: Color { Color(hex: "E8E4DC") }

    // MARK: - Semantic Color Convenience Aliases
    // Non-theme-aware shortcuts to semantic colors
    // Use theme-aware Colors.Semantic functions for dynamic color support

    /// Error color (red for error states)
    static var error: Color { feedbackError }

    /// Warning color (amber/orange for caution states)
    static var warning: Color { feedbackWarning }

    /// Success color (green for positive outcomes)
    static var success: Color { feedbackSuccess }

    /// Info color (gray for informational content)
    static var info: Color { feedbackInfo }

    /// Card border color (subtle divider)
    static var cardBorder: Color { Color.gray.opacity(0.15) }

    // MARK: - Theme Mode Background Colors
    // Used by BibleStudyApp for theme switching (light/dark/sepia/oled)

    static var lightBackground: Color { Color(hex: "FAF7F2") }  // Parchment
    static var darkBackground: Color { Color(hex: "0B0B0C") }   // Near-black
    static var sepiaBackground: Color { Color(hex: "F4ECD8") }  // Warm sepia
    static var oledBackground: Color { Color(hex: "000000") }   // Pure black

    static var moonlitParchment: Color { Color(hex: "E8E4DC") } // Light mode text background
    static var sepiaText: Color { Color(hex: "2C1810") }        // Sepia mode text
    static var oledText: Color { Color(hex: "F5F5F5") }         // OLED mode text (soft ivory)

    static var sepiaSurface: Color { Color(hex: "EAE0CC") }     // Sepia mode surface
    static var oledSurface: Color { Color(hex: "0F0F0F") }      // OLED mode surface (slightly raised from pure black)

    static var sepiaSecondaryText: Color { Color(hex: "5C4A3A") } // Sepia mode secondary text
    static var oledSecondaryText: Color { Color.gray.opacity(0.75) } // OLED mode secondary text

    // MARK: - Jewel Accent Colors
    // Used for feature icons and discovery carousel

    static var lapisLazuli: Color { Color(hex: "2A5C8F") }  // Deep lapis blue
    static var amethyst: Color { Color(hex: "6B4C8C") }     // Purple amethyst
    static var deepPurple: Color { Color(hex: "1A0A2E") }   // Very deep purple

    // MARK: - Surface Convenience Colors
    // Mappings from code names to Asset Catalog colors
    // Asset Catalog colors use App prefix (AppTextPrimary, AppSurface, etc.)

    static var primaryText: Color { Color("AppTextPrimary") }
    static var secondaryText: Color { Color("AppTextSecondary") }
    static var tertiaryText: Color { Color.gray.opacity(0.6) }  // No asset, computed
    static var surfaceBackground: Color { Color("AppSurface") }
    static var elevatedBackground: Color { Color("AppSurface") }
    static var selectedBackground: Color { Color.accentIndigo.opacity(0.15) }
    static var nightVoid: Color { Color(hex: "03030a") }

    // Scholar/Bible feature colors
    static var accentIndigo: Color { Color("AppAccentAction") }  // Primary interactive accent
    static var theologyGreen: Color { Color(hex: "059669") }     // Doctrinal study notes
    static var greekBlue: Color { Color(hex: "2563EB") }         // Original language annotations

    // MARK: - Roman Palette Colors
    // Used in RomanSanctuaryView and Bible features for gem-stone accents

    /// Lapis blue - Sermon recording accent
    static var lapisBlue: Color { Color(hex: "1E3A5F") }  // Deep lapis lazuli

    /// Terracotta red - Decorative accent for feature cards
    static var terracottaRed: Color { Color(hex: "A45A52") }  // Roman terracotta

    /// Malachite green - Breathe feature accent
    static var malachiteGreen: Color { Color(hex: "0D6B4F") }  // Deep malachite green

    // MARK: - Bible Feature Colors

    /// Olive green - Bible insights, journal save state
    static var bibleOlive: Color { Color(hex: "4A7C59") }

    /// Dusky rose - Bible insight reflection
    static var bibleReflection: Color { Color(hex: "9D6B7C") }

    /// Personal rose - Reflection prompts and personal application
    static var personalRose: Color { Color(hex: "C76E8B") }

    /// Connection amber - Cross-references and scripture connections
    static var connectionAmber: Color { Color(hex: "D4A574") }

    /// Purple accent - Bible study
    static var studyPurple: Color { Color(hex: "9966CC") }

    // MARK: - AI Feature Gradient Colors (Tailwind-inspired)

    /// Cyan accent - Scripture Finds You
    static var cyanAccent: Color { Color(hex: "06B6D4") }

    /// Teal accent - Memory Palace
    static var tealAccent: Color { Color(hex: "14B8A6") }

    /// Rose accent - Prayers from Deep
    static var roseAccent: Color { Color(hex: "F43F5E") }

    /// Pink accent - Prayers from Deep gradient
    static var pinkAccent: Color { Color(hex: "EC4899") }

    /// Navy accent - Compline night mode
    static var complineNavy: Color { Color(hex: "1E3A5F") }

    /// Indigo deep - Compline gradient
    static var indigoDeep: Color { Color(hex: "312E81") }

    // MARK: - Compline/Experience Colors

    /// Near-black void - Compline background
    static var complineVoid: Color { Color(hex: "050510") }

    /// Deep slate - Breathe/meditation backgrounds
    static var slateDeep: Color { Color(hex: "0F172A") }

    /// Deep indigo background - Compline moon phase
    static var indigoBackground: Color { Color(hex: "1E1B4B") }

    /// Orange glow - Candle flame
    static var candleOrange: Color { Color(hex: "EA580C") }

    /// Cream warm - Candle flame highlight
    static var creamWarm: Color { Color(hex: "FEF3C7") }

    /// Light indigo tint - Moon glow
    static var moonGlow: Color { Color(hex: "C7D2FE") }

    // MARK: - Settings/Theme Preview Colors

    /// Sepia preview background
    static var sepiaPreview: Color { Color(hex: "F5EDE0") }

    /// Pure black for OLED preview
    static var oledPreview: Color { Color(hex: "000000") }

    // MARK: - RomanBackground Colors

    /// Brown stone - Roman background variant
    static var brownStone: Color { Color(hex: "5D4E37") }

    // MARK: - ManuscriptTheme Colors

    /// Sacred navy background for manuscript
    static var manuscriptNavy: Color { Color(hex: "0A0D1A") }
}

// MARK: - SwiftUI Environment Integration

@available(iOS 13.0, *)
extension View {
    /// Helper to resolve ThemeMode from SwiftUI environment
    func resolveMode(_ colorScheme: ColorScheme) -> ThemeMode {
        ThemeMode.current(from: colorScheme)
    }
}

// MARK: - Color Opacity Ladder (Documentation)

/*
 Opacity Ladder for Contrast Hierarchy:

 - Primary text: 92-96% opacity
 - Secondary text: 70-80% opacity (implemented as 75%)
 - Metadata: 55-65% opacity (implemented as 60%)
 - Disabled: 30-40% opacity (implemented as 35%)
 - Dividers: 10-16% opacity (implemented as 15%)

 Rule: If you can't tell importance via opacity and size, hierarchy is failing

 Accessibility Constraint:
 - All text must meet WCAG AA (4.5:1 minimum)
 - Ivory (#F5F5F5) on near-black (#0B0B0C) = 14.8:1 ratio ✅
 - Test AccentAction on backgrounds for sufficient contrast
 */
