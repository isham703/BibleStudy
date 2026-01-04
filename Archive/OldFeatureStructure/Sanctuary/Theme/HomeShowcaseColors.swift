import SwiftUI

// MARK: - Home Showcase Colors
// Color palette for the Home Page Showcase app

extension Color {

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

    // MARK: - Illuminated Manuscript Palette
    // Note: divineGold, illuminatedGold, burnishedGold, ancientGold, goldLeafShimmer
    // are defined in IlluminatedPalette.swift

    // MARK: - Candlelit Chapel (Dark Mode)
    // Note: candlelitStone, chapelShadow, moonlitParchment, fadedMoonlight
    // are defined in IlluminatedPalette.swift

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

    // MARK: - Jewel Tones (Highlights)
    // Note: vermillion, lapisLazuli, malachite, amethyst
    // are defined in Colors.swift asset catalog

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

    /// Greek Blue - original language
    static let greekBlue = Color(hex: "2563eb")

    /// Theology Green - doctrinal notes
    static let theologyGreen = Color(hex: "059669")

    /// Connection Amber - cross-references
    static let connectionAmber = Color(hex: "d97706")

    /// Personal Rose - reflective questions
    static let personalRose = Color(hex: "db2777")

    /// Scholar Indigo - primary accent
    static let scholarIndigo = Color(hex: "4f46e5")

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

// MARK: - Gradients

extension Color {
    /// Sacred gradient for card backgrounds
    static var sacredGradient: LinearGradient {
        LinearGradient(
            colors: [
                divineGold.opacity(0.15),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gold border gradient for AI cards
    static func goldBorderGradient(angle: Angle = .zero) -> AngularGradient {
        AngularGradient(
            colors: [divineGold, illuminatedGold, burnishedGold, divineGold],
            center: .center,
            angle: angle
        )
    }

    /// Radial gold glow
    static var radialGoldGlow: RadialGradient {
        RadialGradient(
            colors: [
                divineGold.opacity(0.2),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }

    /// Vignette overlay for hero sections
    static var vignetteOverlay: RadialGradient {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.3)
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
                .init(color: Color(hex: "0a0a1a"), location: 0.4),
                .init(color: Color(hex: "1a0a20"), location: 0.7),
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
                candleAmber.opacity(0.4),
                candleAmber.opacity(0.1),
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
                Color(hex: "f5f3f0")
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
                .init(color: Color(hex: "f5efe3"), location: 0.7),
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

// MARK: - Hex Color Extension
// Note: init(hex:) is defined in SanctuaryColors.swift - removed duplicate here
