import SwiftUI

// MARK: - Typography
// Illuminated Manuscript Design System
// Scripture: Customizable serif (New York, Georgia, EB Garamond)
// Display: Premium serif (Cormorant Garamond, Cinzel) for headers
// UI: System sans (SF Pro) for interface elements
//
// Type Scale: Perfect Fourth (1.333 ratio)
// Base: 18pt → 14pt → 18pt → 24pt → 32pt → 42pt → 56pt → 75pt

struct Typography {

    // MARK: - Type Scale (Perfect Fourth: 1.333)
    // Each step multiplies by 1.333
    enum Scale {
        static let xs: CGFloat = 11      // Captions, footnotes
        static let sm: CGFloat = 14      // Secondary text
        static let base: CGFloat = 18    // Body text (scripture)
        static let lg: CGFloat = 22      // Section titles
        static let xl: CGFloat = 28      // Subheadings
        static let xxl: CGFloat = 32     // Book titles
        static let xxxl: CGFloat = 42    // Chapter numbers
        static let display: CGFloat = 56 // Hero text
        static let dropCap: CGFloat = 72 // Illuminated initials
    }
    // MARK: - Scripture Text Styles
    struct Scripture {
        static func body(size: CGFloat = 18) -> Font {
            .system(size: size, design: .serif)
        }

        static func bodyWithSize(_ size: ScriptureFontSize) -> Font {
            .system(size: size.rawValue, design: .serif)
        }

        static let verseNumber: Font = .system(size: 12, weight: .medium, design: .serif)

        static let chapterNumber: Font = .system(size: 48, weight: .light, design: .serif)

        static let title: Font = .system(size: 28, weight: .light, design: .serif)

        static func quote(size: CGFloat = 16) -> Font {
            .system(size: size, design: .serif).italic()
        }
    }

    // MARK: - Display Text Styles (Serif for premium headlines)
    struct Display {
        static let largeTitle: Font = .system(size: 34, weight: .medium, design: .serif)
        static let title1: Font = .system(size: 28, weight: .medium, design: .serif)
        static let title2: Font = .system(size: 22, weight: .medium, design: .serif)
        static let title3: Font = .system(size: 20, weight: .medium, design: .serif)
        static let headline: Font = .system(size: 17, weight: .semibold, design: .serif)
    }

    // MARK: - UI Text Styles
    struct UI {
        static let largeTitle: Font = .system(size: 34, weight: .bold, design: .default)
        static let title1: Font = .system(size: 28, weight: .bold, design: .default)
        static let title2: Font = .system(size: 22, weight: .bold, design: .default)
        static let title3: Font = .system(size: 20, weight: .semibold, design: .default)
        static let headline: Font = .system(size: 17, weight: .semibold, design: .default)
        static let body: Font = .system(size: 17, weight: .regular, design: .default)
        static let bodyBold: Font = .system(size: 17, weight: .bold, design: .default)
        static let callout: Font = .system(size: 16, weight: .regular, design: .default)
        static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)
        static let footnote: Font = .system(size: 13, weight: .medium, design: .default)
        static let caption1: Font = .system(size: 12, weight: .medium, design: .default)
        static let caption1Bold: Font = .system(size: 12, weight: .bold, design: .default)
        static let caption2: Font = .system(size: 11, weight: .regular, design: .default)

        // Interactive elements (Rounded for warmth)
        static let tabLabel: Font = .system(size: 10, weight: .medium, design: .rounded)
        static let buttonLabel: Font = .system(size: 17, weight: .semibold, design: .rounded)
        static let chipLabel: Font = .system(size: 14, weight: .medium, design: .rounded)

        // Warm variants for welcoming/friendly contexts
        static let warmBody: Font = .system(size: 17, weight: .regular, design: .rounded)
        static let warmHeadline: Font = .system(size: 17, weight: .semibold, design: .rounded)
        static let warmSubheadline: Font = .system(size: 15, weight: .regular, design: .rounded)

        // MARK: - Icon Fonts
        // SF Symbol icon sizes with semantic naming
        static let iconXs: Font = .system(size: Scale.xs, weight: .medium)         // 11pt - tiny icons
        static let iconXxs: Font = .system(size: Scale.xs - 1, weight: .medium)    // 10pt - chevrons, badges
        static let iconXxxs: Font = .system(size: Scale.xs - 3, weight: .medium)   // 8pt - micro chevrons
        static let iconSm: Font = .system(size: Scale.sm, weight: .medium)         // 14pt - small icons
        static let iconMd: Font = .system(size: Scale.sm + 2, weight: .medium)     // 16pt - medium icons
        static let iconLg: Font = .system(size: Scale.base, weight: .medium)       // 18pt - large icons
        static let iconXl: Font = .system(size: AppTheme.IconSize.large, weight: .medium) // 24pt - extra large icons
        static let iconXxl: Font = .system(size: AppTheme.IconSize.celebration, weight: .medium) // 36pt - oversized icons
    }

    // MARK: - Hebrew/Greek Text
    struct Language {
        static let hebrew: Font = .system(size: 20, design: .serif)
        static let greek: Font = .system(size: 18, design: .serif)
        static let transliteration: Font = .system(size: 16, design: .monospaced).italic()
        static let gloss: Font = .system(size: 14, weight: .medium, design: .default)
    }

    // MARK: - Code/Monospaced Text
    struct Code {
        static let inline: Font = .system(size: 13, design: .monospaced)
        static let block: Font = .system(size: 14, design: .monospaced)
        static let small: Font = .system(size: 11, design: .monospaced)
    }

    // MARK: - Reading Typography (NEW - Modern Scripture)
    // Verse content and biblical text with user-customizable fonts
    // Replaces Scripture + Illuminated.body* tokens

    struct Reading {
        // MARK: - Verse Text (User-Customizable Font)

        /// Primary verse text - respects user's font preference
        /// Example: Verse display in Scholar Reader, reading modes
        static func verse(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size.rawValue)
        }

        /// Poetic verse text - italic variant for poetry, quoted speech
        /// Example: Psalms, quoted passages, Words of Christ
        static func verseItalic(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size.rawValue).italic()
        }

        /// Verse emphasis - semibold for red letter editions
        /// Example: Words of Christ when emphasis needed
        static func verseEmphasis(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size.rawValue).weight(.semibold)
        }

        // MARK: - Chapter Headers

        /// Large chapter number - editorial bold serif
        /// Example: "Chapter 1" in reader headers
        static let chapterNumber: Font = .system(size: 28, weight: .bold, design: .serif)

        /// Chapter label - small tracked uppercase
        /// Example: "CHAPTER" text above number
        static let chapterLabel: Font = .system(size: 11, weight: .bold)

        // MARK: - Verse Numbers

        /// Standard verse number - bold system
        /// Example: Default verse number style
        static let verseNumber: Font = .system(size: 14, weight: .bold)

        /// Subtle verse number - light weight
        /// Example: Minimal verse number style
        static let verseNumberSubtle: Font = .system(size: 12, weight: .regular)

        // MARK: - Line Spacing

        /// Standard verse line spacing
        static let verseLineSpacing: CGFloat = 8

        /// Poetic verse line spacing (more generous)
        static let poeticLineSpacing: CGFloat = 10
    }

    // MARK: - Editorial Typography (NEW - Scholar Patterns)
    // Metadata, labels, references following editorial/newspaper conventions
    // Distinctive patterns for scholarly precision

    struct Editorial {
        // MARK: - Headers & Labels (Tracked Uppercase)

        /// Section headers - bold tracked uppercase
        /// Example: "TODAY'S STUDY", "DEEPEN YOUR UNDERSTANDING"
        /// Use with: .tracking(Editorial.sectionTracking).textCase(.uppercase)
        static let sectionHeader: Font = .system(size: 11, weight: .bold)

        /// Small label - medium tracked uppercase
        /// Example: "SCHOLARLY INSIGHT", "CONNECTION"
        /// Use with: .tracking(Editorial.labelTracking).textCase(.uppercase)
        static let label: Font = .system(size: 10, weight: .bold)

        /// Tiny label - for compact spaces
        /// Example: Chip labels, tags, badges
        static let labelSmall: Font = .system(size: 9, weight: .bold)

        // MARK: - References (Cinzel + Tracking)

        /// Scripture reference - Cinzel with tracking
        /// Example: "Gen 1:1", "Eph 2:20"
        /// Use with: .tracking(Editorial.referenceTracking)
        static var reference: Font {
            CustomFonts.cinzelRegular(size: 11)
        }

        /// Large reference - for hero displays
        /// Example: Main passage reference in study cards
        static let referenceHero: Font = .system(size: 14, weight: .semibold, design: .serif)

        /// Display reference - large decorative Cinzel
        /// Example: 72pt decorative quotes in home variants
        static var referenceDisplay: Font {
            CustomFonts.cinzelRegular(size: 32)
        }

        // MARK: - Tracking Constants (Liturgical Spacing: 20-30%)

        /// Section header tracking (~23% on 11pt)
        /// Creates contemplative, architectural spacing
        static let sectionTracking: CGFloat = 2.5

        /// Label tracking (~15% on 10pt)
        /// Legibility in small sizes
        static let labelTracking: CGFloat = 1.5

        /// Reference tracking (~27% on 11pt)
        /// Inscriptional quality for citations
        static let referenceTracking: CGFloat = 3.0
    }

    // MARK: - Insight Typography (NEW - AI Content)
    // AI-generated content (insights, commentary, chat)
    // Replaces Codex.* tokens with better fallback support

    struct Insight {
        // MARK: - Headers (Cinzel for Manuscript Feel)

        /// Insight card header - small Cinzel uppercase
        /// Example: "SCHOLARLY INSIGHT", "ILLUMINATED INSIGHT"
        static var header: Font {
            CustomFonts.cinzelRegular(size: 11)
        }

        /// Section title within insight
        /// Example: "Key Points", "Context", "Words"
        static var sectionTitle: Font {
            CustomFonts.cinzelRegular(size: 10)
        }

        // MARK: - Body (Cormorant for Readability)

        /// Hero summary - primary insight text
        /// Example: Main insight summary, chat responses
        static var heroSummary: Font {
            CustomFonts.cormorantRegular(size: 17)
        }

        /// Standard body text
        /// Example: Expanded content, detailed explanations
        static var body: Font {
            CustomFonts.cormorantRegular(size: 15)
        }

        /// Small body - compact displays
        /// Example: Dense content areas
        static var bodySmall: Font {
            CustomFonts.cormorantRegular(size: 14)
        }

        // MARK: - Emphasis Variants

        /// Italic - for marginalia, quotes, loading states
        static var italic: Font {
            CustomFonts.cormorantItalic(size: 15)
        }

        /// Emphasis - semibold for key points
        static var emphasis: Font {
            CustomFonts.cormorantSemiBold(size: 15)
        }

        // MARK: - Cross-References

        /// Reference in insight content
        static var reference: Font {
            CustomFonts.cormorantSemiBold(size: 14)
        }

        /// Quote preview
        static var quote: Font {
            CustomFonts.cormorantItalic(size: 15)
        }

        // MARK: - Line Spacing

        /// Hero summary line spacing
        static let heroLineSpacing: CGFloat = 6

        /// Body line spacing
        static let bodyLineSpacing: CGFloat = 5

        /// Caption line spacing
        static let captionLineSpacing: CGFloat = 3
    }

    // MARK: - Illuminated Manuscript Typography
    // Premium typography for the illuminated manuscript theme
    // Uses custom fonts with system fallbacks
    //
    // ⚠️ **DEPRECATED**: This struct is being phased out in favor of semantic tokens.
    //
    // **Migration Guide**:
    // - `Illuminated.body()` → Use `Typography.Reading.verse()` for scripture text
    // - `Illuminated.bodyWithSize()` → Use `Typography.Reading.verse(size:font:)` with ScriptureFontSize
    // - `Illuminated.footnote` → Use `Typography.UI.footnote` for standard footnotes
    // - `Illuminated.quote()` → Use `Typography.Reading.verseItalic()` for poetic/quoted passages
    // - Drop caps and decorative elements → Keep using Illuminated tokens (feature-specific)
    //
    // See Typography.Reading and TypographyModifiers.swift for new patterns

    struct Illuminated {

        // MARK: - Scripture Body (User-Selected Font)

        /// Scripture body with user's selected font
        static func body(size: CGFloat = Scale.base, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size)
        }

        /// Scripture body with font size enum
        static func bodyWithSize(_ size: ScriptureFontSize, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size.rawValue)
        }

        // MARK: - Drop Caps (Cinzel for Roman capitals)

        /// Large illuminated initial for paragraph/chapter starts
        /// Use Cinzel for decorative Roman capitals
        static func dropCap(size: CGFloat = Scale.dropCap) -> Font {
            DisplayFont.cinzel.font(size: size, weight: .semibold)
        }

        /// Smaller drop cap for less prominent sections
        static func dropCapSmall(size: CGFloat = Scale.display) -> Font {
            DisplayFont.cinzel.font(size: size, weight: .medium)
        }

        // MARK: - Chapter Numbers

        /// Large chapter number (56pt by default)
        static func chapterNumber(size: CGFloat = Scale.display) -> Font {
            DisplayFont.cinzel.font(size: size, weight: .regular)
        }

        /// Chapter number label ("CHAPTER" text above number)
        static var chapterLabel: Font {
            .system(size: Scale.xs, weight: .medium, design: .serif)
                .smallCaps()
        }

        // MARK: - Book Titles (Cormorant Garamond)

        /// Large book title (32pt)
        static func bookTitle(size: CGFloat = Scale.xxl) -> Font {
            DisplayFont.cormorantGaramond.font(size: size, weight: .semibold)
        }

        /// Section title within a book (22pt)
        static func sectionTitle(size: CGFloat = Scale.lg) -> Font {
            DisplayFont.cormorantGaramond.font(size: size, weight: .medium)
        }

        // MARK: - Verse Numbers

        /// Superscript verse number style
        static var verseNumberSuperscript: Font {
            .system(size: Scale.xs, weight: .medium, design: .serif)
        }

        /// Inline verse number (same baseline as text)
        static var verseNumberInline: Font {
            .system(size: Scale.sm, weight: .semibold, design: .serif)
        }

        /// Marginal verse number (for margin placement)
        static var verseNumberMarginal: Font {
            .system(size: Scale.sm, weight: .regular, design: .serif)
        }

        /// Ornamental verse number (with decorative styling)
        static var verseNumberOrnamental: Font {
            DisplayFont.cinzel.font(size: Scale.sm, weight: .regular)
        }

        // MARK: - Footnotes & References

        /// Footnote text
        static var footnote: Font {
            .system(size: Scale.xs, weight: .regular, design: .serif)
        }

        /// Cross-reference text
        static var crossReference: Font {
            .system(size: Scale.xs, weight: .medium, design: .serif)
        }

        // MARK: - Quotes & Special Text

        /// Block quote style (Words of Christ, etc.)
        static func quote(size: CGFloat = Scale.base) -> Font {
            .system(size: size, design: .serif).italic()
        }

        /// Words of Christ (red letter)
        static func wordsOfChrist(size: CGFloat = Scale.base, font: ScriptureFont = .newYork) -> Font {
            font.font(size: size)
        }

        // MARK: - Navigation & UI Headers

        /// Navigation bar title (book name)
        static var navTitle: Font {
            DisplayFont.cormorantGaramond.font(size: Scale.lg, weight: .semibold)
        }

        /// Tab bar labels (minimal)
        static var tabLabel: Font {
            .system(size: 10, weight: .medium, design: .rounded)
        }
    }

    // MARK: - Codex Typography (AI Insight Components)
    // Dedicated typography for Illuminated Insight cards, Deep Study Sheet, and Context Menu
    // Uses Cinzel for headers (Roman inscriptional) and CormorantGaramond for body (humanist serif)
    // Creates authentic manuscript aesthetic with intentional hierarchy
    //
    // ⚠️ **DEPRECATED**: This struct is being replaced by Typography.Insight with semantic tokens.
    //
    // **Migration Guide**:
    // - `Codex.heroSummary` → Use `Typography.Insight.heroSummary` or `.insightHeroSummary()` modifier
    // - `Codex.body` → Use `Typography.Insight.body` or `.insightBody()` modifier
    // - `Codex.emphasis` → Use `Typography.Insight.emphasis` or `.insightEmphasis()` modifier
    // - `Codex.italic` → Use `Typography.Insight.italic` or `.insightItalic()` modifier
    // - `Codex.illuminatedHeader` → Use `Typography.Insight.header` or `.insightHeader()` modifier
    // - `Codex.sectionLabel` → Use `Typography.Editorial.label` or `.editorialLabel()` modifier
    //
    // See Typography.Insight and TypographyModifiers.swift for new patterns

    struct Codex {
        // MARK: - Headers (Cinzel - Roman Capitals)

        /// "ILLUMINATED INSIGHT" header - small caps with generous tracking
        static let illuminatedHeader: Font = .custom("Cinzel-Regular", size: 11)

        /// Category labels in book lists
        static let sectionLabel: Font = .custom("Cinzel-Regular", size: 10)

        /// Book initial glyph for headers
        static let bookInitial: Font = .custom("Cinzel-Regular", size: 28)

        /// Small Cinzel initial for search results
        static let inlineInitial: Font = .custom("Cinzel-Regular", size: 16)

        /// Chapter titles in Deep Study Sheet
        static let chapterTitle: Font = .custom("Cinzel-Regular", size: 14)

        /// Large verse reference in Deep Study header
        static let verseReference: Font = .custom("CormorantGaramond-Bold", size: 22)

        // MARK: - Body Text (CormorantGaramond - Humanist Serif)

        /// Hero summary - primary insight text (InlineInsightCard, Context Menu)
        static let heroSummary: Font = .custom("CormorantGaramond-Regular", size: 17)

        /// Standard body text in expanded sections
        static let body: Font = .custom("CormorantGaramond-Regular", size: 15)

        /// Smaller body for dense content areas
        static let bodySmall: Font = .custom("CormorantGaramond-Regular", size: 14)

        // MARK: - Emphasis Variants

        /// Semi-bold for emphasis (key points, references)
        static let emphasis: Font = .custom("CormorantGaramond-SemiBold", size: 15)

        /// Italic for loading states, marginalia, quotes
        static let italic: Font = .custom("CormorantGaramond-Italic", size: 15)

        /// Small italic for scholar's notes, secondary info
        static let italicSmall: Font = .custom("CormorantGaramond-Italic", size: 13)

        /// Tiny italic for attribution lines
        static let italicTiny: Font = .custom("CormorantGaramond-Italic", size: 11)

        // MARK: - Captions & Labels

        /// Caption text for section labels, metadata
        static let caption: Font = .custom("CormorantGaramond-Regular", size: 13)

        /// Small caption for tertiary information
        static let captionSmall: Font = .custom("CormorantGaramond-Regular", size: 12)

        /// Bold caption for emphasized labels
        static let captionBold: Font = .custom("CormorantGaramond-SemiBold", size: 13)

        // MARK: - Cross-References

        /// Reference labels (book:chapter:verse)
        static let reference: Font = .custom("CormorantGaramond-SemiBold", size: 14)

        /// Preview quote text
        static let quotePreview: Font = .custom("CormorantGaramond-Italic", size: 15)

        // MARK: - Original Language

        /// Greek script (SBL Greek Unicode)
        static let greek: Font = .custom("SBLGreek", size: 18)

        /// Greek in compact displays
        static let greekSmall: Font = .custom("SBLGreek", size: 16)

        /// Transliteration (italic)
        static let transliteration: Font = .custom("CormorantGaramond-Italic", size: 14)

        /// Gloss/translation of terms
        static let gloss: Font = .custom("CormorantGaramond-SemiBold", size: 13)

        // MARK: - Decorative

        /// Chapter symbols (✦, 𝔏, 𝔗, ℭ, 𝔘)
        static let chapterSymbol: Font = .custom("CormorantGaramond-Bold", size: 28)

        /// Colophon text
        static let colophon: Font = .custom("CormorantGaramond-Regular", size: 12)

        // MARK: - Line Spacing

        /// Standard line spacing for body text
        static let bodyLineSpacing: CGFloat = 5

        /// Generous line spacing for hero summaries
        static let heroLineSpacing: CGFloat = 6

        /// Tight line spacing for captions
        static let captionLineSpacing: CGFloat = 3

        // MARK: - Tracking (Letter Spacing)

        /// Header tracking for Cinzel
        static let headerTracking: CGFloat = 2.5

        /// Title tracking
        static let titleTracking: CGFloat = 1.5

        /// Body tracking (minimal)
        static let bodyTracking: CGFloat = 0.3
    }
}

// MARK: - Illuminated Layout Constants
// Margins and spacing based on manuscript design principles

extension Typography {
    enum Layout {
        /// Left margin (wider for thumb grip)
        static let marginLeft: CGFloat = 28

        /// Right margin
        static let marginRight: CGFloat = 20

        /// Top margin
        static let marginTop: CGFloat = 32

        /// Bottom margin (space for navigation)
        static let marginBottom: CGFloat = 48

        /// Maximum reading width (optimal ~66 characters per line)
        static let maxReadingWidth: CGFloat = 540

        /// Generous line height for meditation (1.6x)
        static let lineHeightMultiplier: CGFloat = 1.6

        /// Standard paragraph spacing
        static let paragraphSpacing: CGFloat = 16

        /// Verse spacing (verse-per-line mode)
        static let verseSpacing: CGFloat = 8

        /// Drop cap indent (how far text wraps around drop cap)
        static let dropCapIndent: CGFloat = 48

        /// Drop cap lines (how many lines drop cap spans)
        static let dropCapLines: Int = 3
    }
}

// MARK: - Scripture Font Size Options
enum ScriptureFontSize: CGFloat, CaseIterable {
    case extraSmall = 14
    case small = 16
    case medium = 18
    case large = 20
    case extraLarge = 22
    case huge = 24

    var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .huge: return "Huge"
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .extraSmall: return 6
        case .small: return 7
        case .medium: return 8
        case .large: return 9
        case .extraLarge: return 10
        case .huge: return 12
        }
    }
}

// MARK: - Verse Number Style Options
// Different styles for displaying verse numbers

enum VerseNumberStyle: String, CaseIterable, Codable {
    case superscript = "superscript"    // Traditional superscript (default)
    case inline = "inline"              // Same baseline as text
    case marginal = "marginal"          // In the margin
    case ornamental = "ornamental"      // Decorative Cinzel font
    case minimal = "minimal"            // Subtle, nearly hidden

    var displayName: String {
        switch self {
        case .superscript: return "Superscript"
        case .inline: return "Inline"
        case .marginal: return "Marginal"
        case .ornamental: return "Ornamental"
        case .minimal: return "Minimal"
        }
    }

    var manuscriptDescription: String {
        switch self {
        case .superscript: return "Traditional raised numbers"
        case .inline: return "Numbers on the same line"
        case .marginal: return "Numbers in the margin"
        case .ornamental: return "Decorative Roman numerals"
        case .minimal: return "Subtle, unobtrusive"
        }
    }

    /// Font for this verse number style
    var font: Font {
        switch self {
        case .superscript: return Typography.Illuminated.verseNumberSuperscript
        case .inline: return Typography.Illuminated.verseNumberInline
        case .marginal: return Typography.Illuminated.verseNumberMarginal
        case .ornamental: return Typography.Illuminated.verseNumberOrnamental
        case .minimal: return .system(size: 10, weight: .light, design: .serif)
        }
    }

    /// Opacity for verse number
    var opacity: Double {
        switch self {
        case .superscript, .inline, .ornamental: return 1.0
        case .marginal: return 0.8
        case .minimal: return 0.5
        }
    }
}

// MARK: - Drop Cap Style Options
// Different illuminated initial styles

enum DropCapStyle: String, CaseIterable, Codable {
    case none = "none"              // No drop cap
    case simple = "simple"          // Large first letter, no decoration
    case illuminated = "illuminated" // Gold accent, glow effect
    case uncial = "uncial"          // Celtic/medieval style
    case floriate = "floriate"      // Floral/vine decoration
    case versal = "versal"          // Manuscript versal letter

    var displayName: String {
        switch self {
        case .none: return "None"
        case .simple: return "Simple"
        case .illuminated: return "Illuminated"
        case .uncial: return "Uncial"
        case .floriate: return "Floriate"
        case .versal: return "Versal"
        }
    }

    var manuscriptDescription: String {
        switch self {
        case .none: return "No decorative initial"
        case .simple: return "Clean, large first letter"
        case .illuminated: return "Golden glow, luxurious"
        case .uncial: return "Celtic monastery style"
        case .floriate: return "Vine and flower motifs"
        case .versal: return "Classic manuscript initial"
        }
    }

    /// Whether this style uses gold/accent coloring
    var usesGoldAccent: Bool {
        switch self {
        case .none, .simple: return false
        case .illuminated, .uncial, .floriate, .versal: return true
        }
    }
}

// MARK: - View Extension for Typography
extension View {
    func scriptureStyle(size: ScriptureFontSize = .medium) -> some View {
        self
            .font(Typography.Scripture.bodyWithSize(size))
            .lineSpacing(size.lineSpacing)
    }

    func verseNumberStyle() -> some View {
        self
            .font(Typography.Scripture.verseNumber)
            .foregroundStyle(Color.verseNumber)
    }

    /// Apply illuminated scripture style with custom font
    func illuminatedScriptureStyle(
        size: ScriptureFontSize = .medium,
        font: ScriptureFont = .newYork,
        lineSpacing: LineSpacing = .normal
    ) -> some View {
        self
            .font(Typography.Illuminated.bodyWithSize(size, font: font))
            .lineSpacing(lineSpacing.value + size.lineSpacing)
    }

    /// Apply verse number style based on preference
    func verseNumberStyle(_ style: VerseNumberStyle) -> some View {
        self
            .font(style.font)
            .opacity(style.opacity)
            .foregroundStyle(Color.verseNumber)
    }

    /// Apply drop cap styling
    func dropCapStyle(
        _ style: DropCapStyle = .illuminated,
        size: CGFloat = Typography.Scale.dropCap
    ) -> some View {
        self
            .font(Typography.Illuminated.dropCap(size: size))
            .foregroundStyle(style.usesGoldAccent ? Color.divineGold : Color.primaryText)
    }

    /// Apply chapter number styling
    func chapterNumberStyle() -> some View {
        self
            .font(Typography.Illuminated.chapterNumber())
            .foregroundStyle(Color.divineGold)
    }

    /// Apply book title styling
    func bookTitleStyle() -> some View {
        self
            .font(Typography.Illuminated.bookTitle())
            .foregroundStyle(Color.primaryText)
    }

    /// Apply illuminated manuscript margins
    func illuminatedMargins() -> some View {
        self.padding(EdgeInsets(
            top: Typography.Layout.marginTop,
            leading: Typography.Layout.marginLeft,
            bottom: Typography.Layout.marginBottom,
            trailing: Typography.Layout.marginRight
        ))
    }

    /// Constrain to optimal reading width
    func readingWidth() -> some View {
        self.frame(maxWidth: Typography.Layout.maxReadingWidth)
    }
}
