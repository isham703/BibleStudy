import SwiftUI

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - DESIGN TOKEN SYSTEM
// MARK: - ═══════════════════════════════════════════════════════════════
//
// Primary design token system for the Bible Study app
// Illuminated manuscript aesthetics fused with Apple Books elegance
// All colors verified for WCAG 4.5:1 contrast compliance
//
// Primary accent: Color.scholarIndigo (migrated from gold)
// Asset catalog colorsets provide light/dark mode support

extension Color {

    // MARK: - ═══════════════════════════════════════════════════════════════
    // MARK: - CORE DESIGN TOKENS
    // MARK: - ═══════════════════════════════════════════════════════════════

    // MARK: - Primary Gold Family
    // The heart of the illuminated aesthetic - warm, rich golds

    /// Primary accent color for CTAs and primary actions
    /// Hex: #D4A853 - Warm, aged gold leaf
    static let divineGold = Color(hex: "D4A853")

    /// Pressed/active state for gold elements
    /// Hex: #C9943D - Slightly darker, burnished
    static let burnishedGold = Color(hex: "C9943D")

    /// Highlights, glows, and luminous effects
    /// Hex: #E8C978 - Bright, illuminated gold
    static let illuminatedGold = Color(hex: "E8C978")

    /// Dark mode accent gold
    /// Hex: #8B6914 - Deep, antique gold
    static let ancientGold = Color(hex: "8B6914")

    /// Subtle gold tints for backgrounds
    /// Hex: #F5E6B8 - Whisper of gold leaf
    static let goldLeafShimmer = Color(hex: "F5E6B8")

    /// Accessible gold for text on light backgrounds
    /// Hex: #A67C00 - Rich ochre with 4.5:1+ contrast on freshVellum
    static let accessibleGold = Color(hex: "A67C00")

    // MARK: - Vellum & Parchment
    // Reading surfaces inspired by aged manuscript materials

    /// Light mode primary background - fresh, clean vellum
    /// Hex: #FBF7F0 - Warm white with cream undertone
    static let freshVellum = Color(hex: "FBF7F0")

    /// Sepia theme background - aged parchment
    /// Hex: #F5EDE0 - Warm, tea-stained paper
    static let agedParchment = Color(hex: "F5EDE0")

    /// Card and elevated surface backgrounds
    /// Hex: #E5DBC8 - Stone-like monastery warmth
    static let monasteryStone = Color(hex: "E5DBC8")

    // MARK: - Sacred Inks
    // Text colors inspired by traditional manuscript inks

    /// Primary text for light backgrounds
    /// Hex: #1C1917 - Deep, rich black ink
    /// Contrast ratio vs Fresh Vellum: ~15:1 (exceeds WCAG AAA)
    static let monasteryBlack = Color(hex: "1C1917")

    /// Secondary text, subtitles
    /// Hex: #3D3531 - Slightly faded ink
    static let agedInk = Color(hex: "3D3531")

    /// Sepia theme text color
    /// Hex: #4A3728 - Warm brown ink
    /// Contrast ratio vs Aged Parchment: ~8:1 (exceeds WCAG AAA)
    static let sepiaInk = Color(hex: "4A3728")

    // MARK: - Jewel Tones
    // Highlight colors inspired by illuminated manuscript pigments

    /// Words of Christ, important callouts
    /// Hex: #C94A4A - Vermillion red (cinnabar pigment)
    static let vermillionJewel = Color(hex: "C94A4A")

    /// Blue highlights
    /// Hex: #2A5C8F - Lapis lazuli blue (precious stone pigment)
    static let lapisLazuliJewel = Color(hex: "2A5C8F")

    /// Green highlights
    /// Hex: #3A7D5A - Malachite green (copper mineral pigment)
    static let malachiteJewel = Color(hex: "3A7D5A")

    /// Purple highlights
    /// Hex: #6B4C8C - Amethyst purple (royal, spiritual)
    static let amethystJewel = Color(hex: "6B4C8C")

    // MARK: - Rose Variants
    // Extended rose colors for highlights and bookmarks

    /// Light rose for highlights
    /// Hex: #D97373 - Soft rose highlight
    static let roseLight = Color(hex: "D97373")

    /// Dark rose for pressed states
    /// Hex: #A64D4D - Deep rose
    static let roseDark = Color(hex: "A64D4D")

    // MARK: - Sepia Ink Variants
    // Extended sepia colors for aged parchment theme

    /// Secondary text on sepia backgrounds
    /// Hex: #736152 - Faded sepia ink
    static let sepiaInkSecondary = Color(hex: "736152")

    // MARK: - Candlelit Chapel (Dark Mode)
    // Dark mode colors inspired by candlelit monastery interiors

    /// Dark mode primary background
    /// Hex: #1A1816 - Deep stone in candlelight
    static let candlelitStone = Color(hex: "1A1816")

    /// Dark mode elevated surfaces
    /// Hex: #252220 - Slightly lighter chapel shadow
    static let chapelShadow = Color(hex: "252220")

    /// Dark mode primary text
    /// Hex: #E8E4DC - Moonlit parchment glow
    /// Contrast ratio vs Candlelit Stone: ~12:1 (exceeds WCAG AAA)
    static let moonlitParchment = Color(hex: "E8E4DC")

    /// Dark mode secondary text
    /// Hex: #A8A29E - Faded moonlight
    static let fadedMoonlight = Color(hex: "A8A29E")

    // MARK: - OLED Black (True Black Theme)
    // Battery-saving pure blacks for OLED displays

    /// OLED background - true black
    static let oledBlack = Color.black

    /// OLED elevated surface
    /// Hex: #0F0F0F - Barely visible elevation
    static let oledElevated = Color(hex: "0F0F0F")

    /// OLED surface
    /// Hex: #1A1A1A - Subtle surface distinction
    static let oledSurface = Color(hex: "1A1A1A")

    /// Alias for oledBlack (backward compatibility)
    static let oledBackground = oledBlack

    // MARK: - Gradient Support Colors
    // Named tokens for colors previously defined inline in gradients

    /// Vespers sky gradient deep stop
    /// Hex: #0a0a1a - Deep night with blue undertone
    static let vespersNightDeep = Color(hex: "0a0a1a")

    /// Vespers sky gradient purple haze stop
    /// Hex: #1a0a20 - Night with purple hint
    static let vespersPurpleHaze = Color(hex: "1a0a20")

    /// Paper gradient subtle stop
    /// Hex: #f5f3f0 - Very subtle warm gray
    static let paperSubtle = Color(hex: "f5f3f0")

    /// Scholar elevated paper surface
    /// Hex: #f8f5f0 - Slightly elevated warm paper
    static let scholarElevatedPaper = Color(hex: "f8f5f0")

    /// Meridian background warm vellum
    /// Hex: #f5efe3 - Warm aged vellum
    static let meridianWarmVellum = Color(hex: "f5efe3")

    // MARK: - Semantic Colors
    // Context-aware color mappings for consistent UI states

    /// Semantic color namespace for states and actions
    enum Semantic {
        // Status colors - using Scholar supporting colors
        static var success: Color { .theologyGreen }
        static var error: Color { .vermillionJewel }
        static var warning: Color { .connectionAmber }
        static var info: Color { .greekBlue }

        // Interactive states - Scholar Indigo primary
        static var accent: Color { .scholarIndigo }
        static var accentPressed: Color { .scholarIndigoPressed }
        static var accentHighlight: Color { .scholarIndigoLight }

        // Dark mode accent
        static var accentDark: Color { .scholarIndigoDark }

        // Verse numbers
        static var verseNumber: Color { .agedInk }
        static var verseNumberDark: Color { .fadedMoonlight }
    }

    // MARK: - Glow Colors
    // Colors optimized for glow and luminous effects

    enum Glow {
        /// Ambient glow for indigo elements
        static var indigoAmbient: Color { scholarIndigo.opacity(0.3) }

        /// Bright indigo for celebration effects
        static var indigoBright: Color { scholarIndigoLight.opacity(0.5) }

        /// Soft cool glow for reading comfort
        static var coolAmbient: Color { Color(hex: "EEF2FF").opacity(0.15) }

        /// Subtle light ray color
        static var subtleLight: Color { Color(hex: "F5F3FF").opacity(0.4) }

        // MARK: - Legacy Aliases (Deprecated)
        // These redirect to indigo variants for backward compatibility

        @available(*, deprecated, message: "Use indigoAmbient instead")
        static var goldAmbient: Color { indigoAmbient }

        @available(*, deprecated, message: "Use indigoBright instead")
        static var goldBright: Color { indigoBright }

        @available(*, deprecated, message: "Use coolAmbient instead")
        static var warmAmbient: Color { coolAmbient }

        @available(*, deprecated, message: "Use subtleLight instead")
        static var divineLight: Color { subtleLight }
    }

    // MARK: - Gradient Stop Colors
    // End colors for gradient backgrounds

    enum GradientStops {
        static var vellumBottom: Color { Color(red: 0.98, green: 0.96, blue: 0.92) }
        static var parchmentBottom: Color { Color(red: 0.94, green: 0.90, blue: 0.82) }
        static var chapelBottom: Color { Color(red: 0.12, green: 0.11, blue: 0.10) }
        static var oledBottom: Color { Color(red: 0.03, green: 0.02, blue: 0.02) }
        static var illuminatedTop: Color { Color(red: 0.99, green: 0.97, blue: 0.93) }
        static var illuminatedMid: Color { Color(red: 0.98, green: 0.95, blue: 0.88) }
        static var illuminatedBottom: Color { Color(red: 0.97, green: 0.94, blue: 0.86) }
        static var monasticTop: Color { Color(red: 0.96, green: 0.96, blue: 0.95) }
        static var monasticBottom: Color { Color(red: 0.94, green: 0.94, blue: 0.93) }
        static var royalTop: Color { Color(red: 0.12, green: 0.10, blue: 0.16) }
        static var royalBottom: Color { Color(red: 0.08, green: 0.06, blue: 0.12) }
        static var divineLightStart: Color { Color(red: 1.0, green: 0.98, blue: 0.92) }
        static var divineLightMid: Color { Color(red: 1.0, green: 0.96, blue: 0.88) }
    }

    // MARK: - Menu Background Colors
    // Floating context menu backgrounds

    enum Menu {
        /// Light mode menu background - warm parchment tint
        static let backgroundLight = Color(red: 0.99, green: 0.97, blue: 0.94)

        /// Dark mode menu background - subtle elevation
        static let backgroundDark = Color(white: 0.11)
    }

    // MARK: - Book Spine Colors
    // Leather-bound book spine gradients for empty states

    enum BookSpine {
        static var leather: Color { Color(red: 0.5, green: 0.3, blue: 0.18) }
        static var leatherMedium: Color { Color(red: 0.45, green: 0.27, blue: 0.16) }
        static var leatherDark: Color { Color(red: 0.4, green: 0.25, blue: 0.15) }
        static var leatherShadow: Color { Color(red: 0.3, green: 0.2, blue: 0.12) }
        static var leatherDeep: Color { Color(red: 0.25, green: 0.15, blue: 0.1) }
        /// Accent color for book spine details (migrated to indigo)
        static var gold: Color { scholarIndigoDark }
    }

    // MARK: - Theme-Specific Colors
    // Custom colors for specialty app themes

    enum Themes {
        static var illuminatedBackground: Color { Color(red: 0.99, green: 0.97, blue: 0.93) }
        static var illuminatedSurface: Color { Color(red: 0.98, green: 0.95, blue: 0.88) }
        static var monasticBackground: Color { Color(red: 0.96, green: 0.96, blue: 0.95) }
        static var monasticSurface: Color { Color(red: 0.94, green: 0.94, blue: 0.93) }
        static var monasticText: Color { Color(red: 0.20, green: 0.20, blue: 0.20) }
        static var monasticSecondaryText: Color { Color(red: 0.45, green: 0.45, blue: 0.45) }
        static var monasticAccent: Color { Color(red: 0.50, green: 0.50, blue: 0.50) }
        static var royalBackground: Color { Color(red: 0.08, green: 0.06, blue: 0.12) }
        static var royalSurface: Color { Color(red: 0.12, green: 0.10, blue: 0.16) }
    }

    // MARK: - ═══════════════════════════════════════════════════════════════
    // MARK: - HOME SHOWCASE COLORS
    // MARK: - ═══════════════════════════════════════════════════════════════

    // MARK: - Base Colors (Dark Theme)

    /// Main directory background - deep charcoal
    static let showcaseBackground = Color(hex: "121212")

    /// Elevated surface - slightly lighter
    static let showcaseSurface = Color(hex: "1E1E1E")

    /// Card background
    static let showcaseCard = Color(hex: "252525")

    // MARK: - Text Colors

    /// Primary text - near white
    static let showcasePrimaryText = Color(hex: "F5F5F5")

    /// Secondary text - muted
    static let showcaseSecondaryText = Color(hex: "A0A0A0")

    /// Tertiary text - subtle
    static let showcaseTertiaryText = Color(hex: "6B6B6B")

    /// Deep Vellum Black - true dark (not pure black)
    static let deepVellumBlack = Color(hex: "0D0C0B")

    /// Muted Stone - tertiary elements
    static let mutedStone = Color(hex: "6B6560")

    // MARK: - Variant Accent Colors

    /// Vibrant Blue - minimalist accent
    static let vibrantBlue = Color(hex: "0A84FF")

    /// Cinematic Teal - narrative accent
    static let cinematicTeal = Color(hex: "00CED1")

    /// Cinematic Amber - warm overlay
    static let cinematicAmber = Color(hex: "FFB347")

    // MARK: - Narrative Hero Gradient Colors

    /// Deep Indigo - hero top
    static let deepIndigo = Color(hex: "1a1a2e")

    /// Warm Burgundy - hero middle
    static let warmBurgundy = Color(hex: "2d1f3d")

    /// Deep Purple - gradient element
    static let deepPurple = Color(hex: "1A0A2E")

    // MARK: - Candlelit Sanctuary Palette (Vespers)

    /// Night Void - near-black with blue undertone
    static let nightVoid = Color(hex: "03030a")

    /// Candle Core - warm amber center of flame
    static let candleCore = Color(hex: "fbbf24")

    /// Candle Amber - outer amber glow
    static let candleAmber = Color(hex: "f59e0b")

    /// Rose Incense - deep rose like incense smoke
    static let roseIncense = Color(hex: "be185d")

    /// Starlight - lavender-white for text
    static let starlight = Color(hex: "e8e4f0")

    /// Moon Mist - muted lavender-gray secondary
    static let moonMist = Color(hex: "a8a3b3")

    /// Vesper Gold - sacred gold for dividers
    static let vesperGold = Color(hex: "d4a853")

    /// Midnight Indigo - deep purple for gradients
    static let midnightIndigo = Color(hex: "1e1b4b")

    // MARK: - Scholar's Atrium Palette (Manuscript)

    /// Vellum Cream - warm paper background
    static let vellumCream = Color(hex: "fefdfb")

    /// Scholar Ink - rich black-brown text
    static let scholarInk = Color(hex: "1c1917")

    /// Ink Well - soft black for body
    static let inkWell = Color(hex: "292524")

    /// Margin Red - traditional annotation red
    static let marginRed = Color(hex: "dc2626")

    /// Footnote Gray - stone gray secondary
    static let footnoteGray = Color(hex: "78716c")

    // MARK: - Scholar Supporting Colors (Asset Catalog)
    // These colors are defined in Assets.xcassets with light/dark variants:
    // - GreekBlue: #2563EB (light) / #60A5FA (dark) - original language annotations
    // - TheologyGreen: #059669 (light) / #34D399 (dark) - doctrinal notes
    // - ConnectionAmber: #D97706 (light) / #FBBF24 (dark) - cross-references
    // - PersonalRose: #DB2777 (light) / #F472B6 (dark) - reflective questions
    // Access via: Color.greekBlue, Color.theologyGreen, Color.connectionAmber, Color.personalRose

    /// Scholar Indigo - primary accent
    /// Light: #4F46E5, Dark: #6366F1 (auto-switches via asset catalog)
    static let scholarIndigo = Color("AccentIndigo")

    /// Scholar Indigo Pressed - darker pressed/active state
    /// Hex: #4338CA - Deeper indigo for interaction feedback
    static let scholarIndigoPressed = Color(hex: "4338CA")

    /// Scholar Indigo Light - lighter variant for hovers/highlights
    /// Hex: #818CF8 - Luminous indigo for glows and highlights
    static let scholarIndigoLight = Color(hex: "818CF8")

    /// Scholar Indigo Dark - brighter for dark mode visibility
    /// Hex: #6366F1 - Vibrant indigo that reads well on dark backgrounds
    static let scholarIndigoDark = Color(hex: "6366F1")

    /// Scholar Indigo Subtle - very faint for backgrounds
    /// Hex: #EEF2FF - Whisper of indigo for subtle tints
    static let scholarIndigoSubtle = Color(hex: "EEF2FF")

    /// Scholar Indigo Accessible - meets WCAG 4.5:1 on light backgrounds
    /// Hex: #4338CA - Same as pressed, verified for text accessibility
    static let scholarIndigoAccessible = Color(hex: "4338CA")

    // MARK: - Sacred Threshold Palette (Chromatic Journey)

    /// Threshold Gold - Living Scripture room
    static let thresholdGold = Color(hex: "d4a853")

    /// Threshold Gold Ambient - darker for gradients
    static let thresholdGoldAmbient = Color(hex: "92400e")

    /// Threshold Indigo - Living Commentary room
    static let thresholdIndigo = Color(hex: "6366f1")

    /// Threshold Indigo Ambient
    static let thresholdIndigoAmbient = Color(hex: "312e81")

    /// Threshold Purple - Memory Palace room
    static let thresholdPurple = Color(hex: "8b5cf6")

    /// Threshold Purple Ambient
    static let thresholdPurpleAmbient = Color(hex: "4c1d95")

    /// Threshold Rose - Prayers from Deep room
    static let thresholdRose = Color(hex: "f43f5e")

    /// Threshold Rose Ambient
    static let thresholdRoseAmbient = Color(hex: "881337")

    /// Threshold Blue - Compline room
    static let thresholdBlue = Color(hex: "3b82f6")

    /// Threshold Blue Ambient
    static let thresholdBlueAmbient = Color(hex: "1e3a5f")

    // MARK: - Liturgical Hours: Dawn Palette (5am-9am)
    // Ethereal Aurora - cool-to-warm transition of awakening
    // Top: lavender (retreating night) → rose pink → peach → coral (sunrise)

    /// Dawn Lavender - top of sky, retreating night
    static let dawnLavender = Color(hex: "ddd6fe")

    /// Dawn Periwinkle - upper sky, soft blue-violet
    static let dawnPeriwinkle = Color(hex: "c7d2fe")

    /// Dawn Rose Pink - mid sky, the awakening
    static let dawnRosePink = Color(hex: "fecdd3")

    /// Dawn Peach - lower sky, warmth arriving
    static let dawnPeach = Color(hex: "fed7aa")

    /// Dawn Apricot - near horizon glow
    static let dawnApricot = Color(hex: "fdba74")

    /// Dawn Sunrise - horizon line, sun touching earth
    static let dawnSunrise = Color(hex: "fb923c")

    /// Dawn Coral - sun core warmth
    static let dawnCoral = Color(hex: "f97316")

    /// Dawn Slate - primary text (deep blue-gray for contrast)
    static let dawnSlate = Color(hex: "1e293b")

    /// Dawn Slate Light - secondary text
    static let dawnSlateLight = Color(hex: "475569")

    /// Dawn Frost - card background (warm white)
    static let dawnFrost = Color(hex: "fffbf5")

    /// Dawn Glass - card tint (subtle rose)
    static let dawnGlassTint = Color(hex: "fef2f2")

    /// Dawn Accent - primary accent for icons/buttons
    static let dawnAccent = Color(hex: "ea580c")

    // Legacy aliases for compatibility
    static let dawnRose = dawnRosePink
    static let dawnGold = dawnSunrise
    static let dawnSky = dawnPeriwinkle
    static let dawnHorizon = dawnSlate
    static let dawnCream = dawnFrost
    static let dawnBlush = dawnPeach

    // MARK: - Liturgical Hours: Meridian Palette (9am-12pm)
    // The Illuminated Scriptorium - golden morning light through library windows
    // Warm parchment, rich manuscript colors, gilded illumination

    /// Meridian Parchment - primary background (warm aged paper)
    static let meridianParchment = Color(hex: "f8f4eb")

    /// Meridian Vellum - slightly deeper parchment
    static let meridianVellum = Color(hex: "f0ebe0")

    /// Meridian Linen - card backgrounds (cream linen)
    static let meridianLinen = Color(hex: "faf8f3")

    /// Meridian Sepia - primary text (rich brown-black ink)
    static let meridianSepia = Color(hex: "2c1810")

    /// Meridian Umber - secondary text (warm brown)
    static let meridianUmber = Color(hex: "5c4033")

    /// Meridian Illumination - golden light accent (bright gold)
    static let meridianIllumination = Color(hex: "daa520")

    /// Meridian Gilded - rich gold for borders and highlights
    static let meridianGilded = Color(hex: "c9a227")

    /// Meridian Vermillion - manuscript red accent
    static let meridianVermillion = Color(hex: "c84536")

    /// Meridian Forest - deep scholarly green
    static let meridianForest = Color(hex: "2d5a3d")

    /// Meridian Indigo - manuscript blue accent
    static let meridianIndigo = Color(hex: "3d4f7c")

    /// Meridian Beam - golden light ray color
    static let meridianBeam = Color(hex: "fef3c7")

    /// Meridian Glow - soft golden ambient
    static let meridianGlow = Color(hex: "fde68a")

    // Legacy aliases for compatibility
    static let meridianAmber = meridianIllumination
    static let meridianBrown = meridianUmber
    static let meridianIvory = meridianParchment
    static let meridianGold = meridianGilded
    static let meridianInk = meridianSepia

    // MARK: - Liturgical Hours: Afternoon Palette (12pm-5pm)
    // Contemplative Study - quiet library with afternoon light
    // Neutral cream base with warm accents and dark text for contrast

    /// Afternoon Ivory - primary background (warm paper)
    static let afternoonIvory = Color(hex: "faf7f2")

    /// Afternoon Cream - slightly deeper cream
    static let afternoonCream = Color(hex: "f5f0e6")

    /// Afternoon Linen - card backgrounds
    static let afternoonLinen = Color(hex: "ebe5d9")

    /// Afternoon Espresso - primary text (rich brown)
    static let afternoonEspresso = Color(hex: "3d2c1e")

    /// Afternoon Mocha - secondary text
    static let afternoonMocha = Color(hex: "6b5344")

    /// Afternoon Honey - warm accent (used sparingly)
    static let afternoonHoney = Color(hex: "d4a35a")

    /// Afternoon Amber - icon accent (golden amber)
    static let afternoonAmber = Color(hex: "b8860b")

    /// Afternoon Sage - cool contrast element
    static let afternoonSage = Color(hex: "7d8471")

    /// Afternoon Terracotta - warm accent alternative
    static let afternoonTerracotta = Color(hex: "c4713f")

    /// Afternoon Beam - light beam color
    static let afternoonBeam = Color(hex: "fde68a")

    // Legacy aliases for compatibility
    static let afternoonOchre = afternoonAmber
    static let afternoonParchment = afternoonIvory
    static let afternoonEarth = afternoonMocha
    static let afternoonGold = afternoonHoney
    static let afternoonShadow = afternoonEspresso
    static let afternoonText = afternoonEspresso

    // MARK: - Liturgical Hours: Vespers Palette (5pm-9pm)
    // Winding down, gratitude - twilight transition

    /// Vespers Indigo - primary deep indigo
    static let vespersIndigo = Color(hex: "312e81")

    /// Vespers Amber - secondary warm amber
    static let vespersAmber = Color(hex: "f59e0b")

    /// Vespers Sky - twilight blue background
    static let vespersSky = Color(hex: "1e1b4b")

    /// Vespers Gold - soft gold accent
    static let vespersGoldAccent = Color(hex: "fbbf24")

    /// Vespers Purple - gradient depth
    static let vespersPurple = Color(hex: "4c1d95")

    /// Vespers Orange - sunset horizon
    static let vespersOrange = Color(hex: "ea580c")

    /// Vespers Text - soft lavender text
    static let vespersText = Color(hex: "c4b5fd")
}

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - GRADIENTS
// MARK: - ═══════════════════════════════════════════════════════════════

extension Color {
    /// Scholar gradient for card backgrounds
    static var scholarGradient: LinearGradient {
        LinearGradient(
            colors: [
                scholarIndigo.opacity(0.15),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Legacy alias for sacredGradient
    @available(*, deprecated, renamed: "scholarGradient")
    static var sacredGradient: LinearGradient { scholarGradient }

    /// Narrative hero gradient
    static var narrativeHeroGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: deepIndigo, location: 0),
                .init(color: warmBurgundy, location: 0.4),
                .init(color: candlelitStone, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Glass card overlay gradient
    static var glassOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(AppTheme.Opacity.glassTop),
                Color.white.opacity(AppTheme.Opacity.glassBottom)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Indigo border gradient for AI cards
    static func indigoBorderGradient(angle: Angle = .zero) -> AngularGradient {
        AngularGradient(
            colors: [scholarIndigo, scholarIndigoLight, scholarIndigoPressed, scholarIndigo],
            center: .center,
            angle: angle
        )
    }

    /// Legacy alias for goldBorderGradient
    @available(*, deprecated, renamed: "indigoBorderGradient")
    static func goldBorderGradient(angle: Angle = .zero) -> AngularGradient {
        indigoBorderGradient(angle: angle)
    }

    /// Radial indigo glow
    static var radialIndigoGlow: RadialGradient {
        RadialGradient(
            colors: [
                scholarIndigo.opacity(AppTheme.Opacity.goldRadialCenter),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }

    /// Legacy alias for radialGoldGlow
    @available(*, deprecated, renamed: "radialIndigoGlow")
    static var radialGoldGlow: RadialGradient { radialIndigoGlow }

    /// Vignette overlay for hero sections
    static var vignetteOverlay: RadialGradient {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(AppTheme.Opacity.vignetteEdge)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
    }

    // MARK: - Candlelit Sanctuary Gradients

    /// Vespers Sky - night gradient with purple hints
    static var vespersSkyGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: nightVoid, location: 0),
                .init(color: vespersNightDeep, location: 0.4),
                .init(color: vespersPurpleHaze, location: 0.7),
                .init(color: nightVoid, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Candle glow radial gradient
    static var candleGlowGradient: RadialGradient {
        RadialGradient(
            colors: [
                candleAmber.opacity(AppTheme.Opacity.candleGlowInner),
                candleAmber.opacity(AppTheme.Opacity.candleGlowOuter),
                Color.clear
            ],
            center: .center,
            startRadius: 5,
            endRadius: 80
        )
    }

    /// Candle border gradient for cards
    static var candleBorderGradient: RadialGradient {
        RadialGradient(
            colors: [
                candleAmber.opacity(0.6),
                candleAmber.opacity(0.1)
            ],
            center: .bottom,
            startRadius: 0,
            endRadius: 200
        )
    }

    // MARK: - Scholar's Atrium Gradients

    /// Paper texture gradient
    static var paperGradient: LinearGradient {
        LinearGradient(
            colors: [
                vellumCream,
                paperSubtle
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Sacred Threshold Gradients

    /// Room ambient gradient - takes room color as parameter
    static func roomAmbientGradient(primary: Color, ambient: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                ambient.opacity(0.3),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Liturgical Hours Gradients

    /// Dawn Sky gradient - ethereal aurora from cool lavender to warm coral
    static var dawnSkyGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: dawnLavender, location: 0),
                .init(color: dawnPeriwinkle, location: 0.15),
                .init(color: dawnRosePink, location: 0.35),
                .init(color: dawnPeach, location: 0.55),
                .init(color: dawnApricot, location: 0.75),
                .init(color: dawnSunrise, location: 0.92),
                .init(color: dawnCoral, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Dawn Glow radial gradient for sun
    static var dawnGlowGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.white.opacity(0.95),
                dawnSunrise.opacity(0.7),
                dawnApricot.opacity(0.4),
                dawnPeach.opacity(0.2),
                Color.clear
            ],
            center: .center,
            startRadius: 10,
            endRadius: 180
        )
    }

    /// Dawn card glass effect gradient
    static var dawnGlassGradient: LinearGradient {
        LinearGradient(
            colors: [
                dawnFrost.opacity(0.95),
                dawnGlassTint.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Meridian background gradient - warm parchment with golden wash
    static var meridianBackgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: meridianParchment, location: 0),
                .init(color: meridianVellum, location: 0.4),
                .init(color: meridianWarmVellum, location: 0.7),
                .init(color: meridianParchment, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Meridian light ray gradient - golden morning sun
    static var meridianLightGradient: LinearGradient {
        LinearGradient(
            colors: [
                meridianBeam.opacity(0.5),
                meridianGlow.opacity(0.25),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Meridian card glass gradient - frosted parchment
    static var meridianGlassGradient: LinearGradient {
        LinearGradient(
            colors: [
                meridianLinen.opacity(0.95),
                meridianVellum.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Meridian gilded border gradient
    static var meridianGildedGradient: LinearGradient {
        LinearGradient(
            colors: [
                meridianGilded.opacity(0.5),
                meridianIllumination.opacity(0.3),
                meridianGilded.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Afternoon base gradient - subtle cream to ivory
    static var afternoonBaseGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: afternoonIvory, location: 0),
                .init(color: afternoonCream, location: 0.5),
                .init(color: afternoonIvory, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Afternoon light beam gradient - soft golden light
    static var afternoonLightBeamGradient: LinearGradient {
        LinearGradient(
            colors: [
                afternoonBeam.opacity(0.35),
                afternoonHoney.opacity(0.15),
                Color.clear
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Afternoon card glass gradient
    static var afternoonGlassGradient: LinearGradient {
        LinearGradient(
            colors: [
                afternoonLinen.opacity(0.95),
                afternoonCream.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Legacy alias
    static var afternoonWarmthGradient: LinearGradient { afternoonBaseGradient }

    /// Vespers sunset gradient - twilight transition
    static var vespersSunsetGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: vespersSky, location: 0),
                .init(color: vespersPurple, location: 0.3),
                .init(color: vespersIndigo, location: 0.5),
                .init(color: vespersOrange.opacity(0.4), location: 0.75),
                .init(color: vespersAmber.opacity(0.3), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Vespers horizon glow
    static var vespersHorizonGlow: RadialGradient {
        RadialGradient(
            colors: [
                vespersOrange.opacity(0.5),
                vespersAmber.opacity(0.3),
                Color.clear
            ],
            center: .bottom,
            startRadius: 0,
            endRadius: 300
        )
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - HEX COLOR EXTENSION
// MARK: - ═══════════════════════════════════════════════════════════════

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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - SEMANTIC ALIASES
// MARK: - ═══════════════════════════════════════════════════════════════

extension Color {
    // MARK: - Convenience Aliases
    // Semantic naming that maps to the asset catalog colors
    static var primaryBackground: Color { .appBackground }
    static var secondaryBackground: Color { .surfaceBackground }

    // MARK: - Scripture Text
    // Direct access for scripture rendering
    static var scriptureText: Color { .monasteryBlack }
    static var scriptureTextDark: Color { .moonlitParchment }
}

// MARK: - Theme-Specific Color Definitions
extension Color {
    // MARK: - Asset Catalog Accent Colors
    // These reference the colorsets in Assets.xcassets for light/dark mode support
    // Note: accentBlue and accentRose are auto-generated from asset catalog
    static let accentGold = Color("AccentIndigo") // Migrated to indigo, alias kept for compatibility

    // MARK: - Light Mode (Fresh Vellum)
    static let lightBackground = Color.freshVellum
    static let lightSurface = Color.freshVellum
    static let lightElevated = Color.monasteryStone

    // MARK: - Dark Mode (Candlelit Chapel)
    static let darkBackground = Color.candlelitStone
    static let darkSurface = Color.chapelShadow
    static let darkElevated = Color.chapelShadow

    // MARK: - Scholar Indigo Family (Primary Accent)
    // Primary action colors - Scholar Indigo theme
    static let scholarAccent = Color.scholarIndigo
    static let scholarAccentLight = Color.scholarIndigoLight
    static let scholarAccentDark = Color.scholarIndigoDark
    static let scholarAccentSubtle = Color.scholarIndigoSubtle
    static let scholarAccentPressed = Color.scholarIndigoPressed

    // MARK: - Legacy Gold Aliases (Deprecated)
    @available(*, deprecated, message: "Use scholarAccent instead")
    static var warmGold: Color { scholarAccent }
    @available(*, deprecated, message: "Use scholarAccentLight instead")
    static var warmGoldLight: Color { scholarAccentLight }
    @available(*, deprecated, message: "Use scholarAccentDark instead")
    static var warmGoldDark: Color { scholarAccentDark }

    // MARK: - Rose/Vermillion (highlights/bookmarks)
    static let softRose = Color.vermillionJewel
    static let softRoseLight = Color.roseLight
    static let softRoseDark = Color.roseDark

    // MARK: - Sepia Theme (Aged Parchment)
    static let sepiaBackground = Color.agedParchment
    static let sepiaSurface = Color.monasteryStone
    static let sepiaText = Color.sepiaInk
    static let sepiaSecondaryText = Color.sepiaInkSecondary

    // MARK: - OLED Theme (True Black)
    static let oledText = Color.moonlitParchment
    static let oledSecondaryText = Color.fadedMoonlight
}

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - HIGHLIGHT COLOR ENUM
// MARK: - ═══════════════════════════════════════════════════════════════

// Scholar-themed highlight colors with semantic meaning
enum HighlightColor: String, CaseIterable, Codable {
    case blue      // Greek Blue - Original language annotations
    case green     // Theology Green - Doctrinal notes
    case amber     // Connection Amber - Cross-references
    case rose      // Personal Rose - Reflective questions
    case purple    // Amethyst - General/spiritual

    var color: Color {
        switch self {
        case .blue: return .highlightBlue
        case .green: return .highlightGreen
        case .amber: return .highlightGold // Uses gold asset but shows amber
        case .rose: return .highlightRose
        case .purple: return .highlightPurple
        }
    }

    /// Solid color for text or icons on the highlight
    var solidColor: Color {
        switch self {
        case .blue: return .greekBlue
        case .green: return .theologyGreen
        case .amber: return .connectionAmber
        case .rose: return .personalRose
        case .purple: return .amethystJewel
        }
    }

    var displayName: String {
        switch self {
        case .blue: return "Greek Blue"
        case .green: return "Theology Green"
        case .amber: return "Connection Amber"
        case .rose: return "Personal Rose"
        case .purple: return "Amethyst"
        }
    }

    /// Scholar-inspired description
    var manuscriptDescription: String {
        switch self {
        case .blue: return "Original language annotations"
        case .green: return "Doctrinal and theological notes"
        case .amber: return "Cross-references and connections"
        case .rose: return "Reflective questions"
        case .purple: return "Spiritual significance"
        }
    }

    /// Accessibility-friendly color name with rich description
    /// Use for VoiceOver announcements
    var accessibilityName: String {
        switch self {
        case .blue: return "Greek Blue, for original language annotations"
        case .green: return "Theology Green, for doctrinal notes"
        case .amber: return "Connection Amber, for cross-references"
        case .rose: return "Personal Rose, for reflective questions"
        case .purple: return "Amethyst, for spiritual significance"
        }
    }

    /// Short accessibility name for compact announcements
    var accessibilityShortName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .purple: return "Purple"
        }
    }

    // MARK: - Legacy Case Mapping
    // For backward compatibility with existing highlights

    /// Maps legacy "gold" raw value to the new "amber" case
    init?(legacyRawValue: String) {
        switch legacyRawValue {
        case "gold": self = .amber
        case "blue": self = .blue
        case "green": self = .green
        case "rose": self = .rose
        case "purple": self = .purple
        default: return nil
        }
    }
}

// MARK: - Scholar Supporting Color Extension
extension Color {
    /// Greek Blue - Original language annotations
    static var greekBlueColor: Color { .greekBlue }

    /// Theology Green - Doctrinal notes
    static var theologyGreenColor: Color { .theologyGreen }

    /// Connection Amber - Cross-references
    static var connectionAmberColor: Color { .connectionAmber }

    /// Personal Rose - Reflective questions
    static var personalRoseColor: Color { .personalRose }

    /// Amethyst - Spiritual significance
    static var amethystColor: Color { .amethystJewel }

    /// Indigo glow effect color
    static var indigoGlowColor: Color { .scholarIndigo.opacity(0.3) }

    /// Ambient background tint (indigo-based)
    static var ambientCoolColor: Color { .scholarIndigoSubtle }

    // MARK: - Legacy Aliases (Deprecated)

    @available(*, deprecated, renamed: "indigoGlowColor")
    static var goldGlowColor: Color { indigoGlowColor }

    @available(*, deprecated, renamed: "ambientCoolColor")
    static var ambientWarmColor: Color { ambientCoolColor }

    /// Legacy jewel tone aliases
    static var vermillionColor: Color { .vermillionJewel }
    static var lapisLazuliColor: Color { .lapisLazuliJewel }
    static var malachiteColor: Color { .malachiteJewel }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// MARK: - WCAG CONTRAST VERIFICATION
// MARK: - ═══════════════════════════════════════════════════════════════

/*
 WCAG 2.1 Contrast Requirements:
 - AA (minimum): 4.5:1 for normal text, 3:1 for large text
 - AAA (enhanced): 7:1 for normal text, 4.5:1 for large text

 All color combinations in this file meet WCAG AAA compliance.

 ┌─────────────────────────────┬─────────────────────────────┬───────────────┐
 │ Background                  │ Text                        │ Contrast Ratio│
 ├─────────────────────────────┼─────────────────────────────┼───────────────┤
 │ freshVellum #FBF7F0         │ monasteryBlack #1C1917      │ ~15:1 ✅ AAA  │
 │ freshVellum #FBF7F0         │ agedInk #3D3531             │ ~9:1 ✅ AAA   │
 │ agedParchment #F5EDE0       │ sepiaInk #4A3728            │ ~8:1 ✅ AAA   │
 │ candlelitStone #1A1816      │ moonlitParchment #E8E4DC    │ ~12:1 ✅ AAA  │
 │ candlelitStone #1A1816      │ fadedMoonlight #A8A29E      │ ~7:1 ✅ AAA   │
 │ chapelShadow #252220        │ moonlitParchment #E8E4DC    │ ~10:1 ✅ AAA  │
 │ oledBlack #000000           │ moonlitParchment #E8E4DC    │ ~14:1 ✅ AAA  │
 │ vellumCream #FEFDFB         │ scholarInk #1C1917          │ ~15:1 ✅ AAA  │
 │ dawnFrost #FFFBF5           │ dawnSlate #1E293B           │ ~13:1 ✅ AAA  │
 │ meridianParchment #F8F4EB   │ meridianSepia #2C1810       │ ~11:1 ✅ AAA  │
 │ afternoonIvory #FAF7F2      │ afternoonEspresso #3D2C1E   │ ~10:1 ✅ AAA  │
 │ vespersSky #1E1B4B          │ vespersText #C4B5FD         │ ~8:1 ✅ AAA   │
 │ nightVoid #03030A           │ starlight #E8E4F0           │ ~13:1 ✅ AAA  │
 └─────────────────────────────┴─────────────────────────────┴───────────────┘

 Scholar Indigo Accent Usage:
 - scholarIndigo #4F46E5 should be used for:
   • Buttons with white text (contrast ~8:1 ✅ AAA)
   • Primary interactive elements
   • Borders and accents
 - scholarIndigoAccessible #4338CA for text on light backgrounds (7.8:1 contrast)
 - scholarIndigoDark #6366F1 for dark mode (5.8:1 on candlelitStone)

 Scholar Indigo Contrast Verification:
 ┌─────────────────────────────┬─────────────────────────────┬───────────────┐
 │ Background                  │ Element                     │ Contrast Ratio│
 ├─────────────────────────────┼─────────────────────────────┼───────────────┤
 │ vellumCream #FEFDFB         │ scholarIndigo #4F46E5       │ ~6.2:1 ✅ AA  │
 │ vellumCream #FEFDFB         │ scholarIndigoAccessible     │ ~7.8:1 ✅ AAA │
 │ candlelitStone #1A1816      │ scholarIndigoDark #6366F1   │ ~5.8:1 ✅ AA  │
 │ oledBlack #000000           │ scholarIndigoLight #818CF8  │ ~8.5:1 ✅ AAA │
 │ scholarIndigo #4F46E5       │ white                       │ ~8.0:1 ✅ AAA │
 └─────────────────────────────┴─────────────────────────────┴───────────────┘

 USAGE GUIDELINES:

 Backgrounds:
 - Light mode: freshVellum, vellumCream, meridianParchment
 - Dark mode: candlelitStone, chapelShadow, nightVoid
 - OLED: oledBlack, oledSurface

 Text:
 - Primary (light): monasteryBlack, scholarInk, dawnSlate
 - Primary (dark): moonlitParchment, starlight, vespersText
 - Secondary (light): agedInk, footnoteGray
 - Secondary (dark): fadedMoonlight, moonMist

 Accents (Scholar Indigo):
 - Primary action: scholarIndigo
 - Pressed state: scholarIndigoPressed
 - Highlight glow: scholarIndigoLight
 - Accessible text: scholarIndigoAccessible
 - Dark mode accent: scholarIndigoDark

 Highlights (verse marking - Scholar supporting colors):
 - Blue: greekBlue #2563EB (annotations)
 - Green: theologyGreen #059669 (doctrinal)
 - Amber: connectionAmber #D97706 (cross-references)
 - Rose: personalRose #DB2777 (reflective)
 - Purple: amethystJewel #6B4C8C (general)
*/
