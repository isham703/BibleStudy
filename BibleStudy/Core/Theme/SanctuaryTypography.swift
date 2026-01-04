import SwiftUI

// MARK: - Home Showcase Typography
// Font definitions for the Home Page Showcase app
//
// **Purpose**: Variant-specific typography for home page showcases
//
// **Strategy**:
// - References global Typography tokens where patterns align (e.g., Scholar.sectionHeader → Typography.Editorial.sectionHeader)
// - Uses CustomFonts helpers for centralized font loading
// - Keeps only variant-specific customizations (unique sizes, decorative elements)
//
// **Guidelines**:
// - For new typography needs, check global Typography first
// - Only add variant-specific tokens here if they differ from global patterns
// - Document why each token is variant-specific (e.g., "variant-specific 72pt decorative quote")

enum SanctuaryTypography {

    // MARK: - Custom Font Names

    private static let cinzelRegular = "Cinzel-Regular"
    private static let cormorantSemiBold = "CormorantGaramond-SemiBold"
    private static let cormorantRegular = "CormorantGaramond-Regular"
    private static let cormorantItalic = "CormorantGaramond-Italic"

    // MARK: - Type Scale (Perfect Fourth: 1.333)

    enum Scale {
        static let xs: CGFloat = 11
        static let sm: CGFloat = 13
        static let base: CGFloat = 15
        static let md: CGFloat = 17
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 28
        static let xxxl: CGFloat = 34
        static let display: CGFloat = 42
        static let hero: CGFloat = 32
        static let dropCap: CGFloat = 72
    }

    // MARK: - Minimalist Typography (Swiss Editorial)

    enum Minimalist {
        /// Greeting - whisper weight
        static let greeting = Font.system(size: 14, weight: .light)

        /// Verse text - elegant serif (variant-specific 28pt italic)
        static var verse: Font {
            CustomFonts.cormorantItalic(size: 28)
        }

        /// Reference - tracked Cinzel (variant-specific 12pt)
        static var reference: Font {
            CustomFonts.cinzelRegular(size: 12)
        }

        /// Action text - medium weight
        static let action = Font.system(size: 16, weight: .medium)

        /// Section header - uppercase tracked
        static var sectionHeader: Font {
            CustomFonts.cinzelRegular(size: 11)
        }
    }

    // MARK: - Feature-Rich Typography (Dashboard)

    enum Dashboard {
        /// Greeting - semibold warm
        static let greeting = Font.system(size: 24, weight: .semibold)

        /// Date - subtle
        static let date = Font.system(size: 14, weight: .regular)

        /// Section header - uppercase tracked gold
        static let sectionHeader = Font.system(size: 11, weight: .medium)

        /// Card title - semibold
        static let cardTitle = Font.system(size: 17, weight: .semibold)

        /// Card body - regular
        static let cardBody = Font.system(size: 15, weight: .regular)

        /// Metric number - bold large
        static let metricNumber = Font.system(size: 20, weight: .bold)

        /// Metric label - regular small
        static let metricLabel = Font.system(size: 12, weight: .regular)

        /// Progress text
        static let progressText = Font.system(size: 13, weight: .medium)

        /// Button text
        static let button = Font.system(size: 15, weight: .semibold)
    }

    // MARK: - Narrative Typography (Cinematic)

    enum Narrative {
        /// Hero title - tracked Cinzel (variant-specific 13pt)
        static var heroTitle: Font {
            CustomFonts.cinzelRegular(size: 13)
        }

        /// Hero greeting - large Cormorant (variant-specific 32pt)
        static var heroGreeting: Font {
            CustomFonts.cormorantSemiBold(size: 32)
        }

        /// Hero stats
        static let heroStats = Font.system(size: 15, weight: .medium)

        /// Section header - tracked Cinzel
        static var sectionHeader: Font {
            CustomFonts.cinzelRegular(size: 11)
        }

        /// Verse text - italic Cormorant (variant-specific 24pt)
        static var verse: Font {
            CustomFonts.cormorantItalic(size: 24)
        }

        /// Decorative quote mark (variant-specific 72pt)
        static var decorativeQuote: Font {
            CustomFonts.cinzelRegular(size: 72)
        }

        /// Card title - bold
        static let cardTitle = Font.system(size: 20, weight: .bold)

        /// Card subtitle
        static let cardSubtitle = Font.system(size: 15, weight: .regular)

        /// CTA button
        static let ctaButton = Font.system(size: 15, weight: .semibold)
    }

    // MARK: - UI Typography (Shared)

    enum UI {
        /// Large title
        static let largeTitle = Font.system(size: Scale.xxxl, weight: .bold)

        /// Title
        static let title = Font.system(size: Scale.xxl, weight: .bold)

        /// Headline
        static let headline = Font.system(size: Scale.md, weight: .semibold)

        /// Body
        static let body = Font.system(size: Scale.md, weight: .regular)

        /// Caption
        static let caption = Font.system(size: 12, weight: .medium)

        /// Small caption
        static let captionSmall = Font.system(size: 11, weight: .regular)

        /// Badge text
        static let badge = Font.system(size: 9, weight: .bold)
    }

    // MARK: - Candlelit Sanctuary Typography (Vespers)
    // Whisper-weight hierarchy - everything feels hushed

    enum Candlelit {
        /// Greeting - whisper light (variant-specific 15pt Cormorant)
        static var greeting: Font {
            CustomFonts.cormorantRegular(size: 15)
        }

        /// Verse text - elegant italic (variant-specific 26pt)
        static var verse: Font {
            CustomFonts.cormorantItalic(size: 26)
        }

        /// Reference - tracked Cinzel uppercase
        static var reference: Font {
            CustomFonts.cinzelRegular(size: 11)
        }

        /// Feature label - small tracked Cinzel (variant-specific 10pt)
        static var featureLabel: Font {
            CustomFonts.cinzelRegular(size: 10)
        }

        /// Feature title - Cormorant semibold (variant-specific 18pt)
        static var featureTitle: Font {
            CustomFonts.cormorantSemiBold(size: 18)
        }

        /// Feature subtitle - system light
        static let featureSubtitle = Font.system(size: 13, weight: .light)

        /// Duration text - small Cinzel (variant-specific 9pt)
        static var duration: Font {
            CustomFonts.cinzelRegular(size: 9)
        }
    }

    // MARK: - Scholar's Atrium Typography (Manuscript)
    // Editorial precision - newspaper-like authority

    enum Scholar {
        /// Header - system bold uppercase
        static let header = Font.system(size: 13, weight: .bold)

        /// Date - system regular
        static let date = Font.system(size: 14, weight: .regular)

        /// Section header - bold tracked uppercase
        /// References global Typography.Editorial.sectionHeader
        static let sectionHeader = Typography.Editorial.sectionHeader

        /// Scripture reference - semibold
        /// References global Typography.Editorial.referenceHero
        static let scriptureRef = Typography.Editorial.referenceHero

        /// Scripture text - regular serif (variant-specific 19pt size)
        /// Uses CustomFonts helper for centralized font loading
        static var scriptureText: Font {
            CustomFonts.cormorantRegular(size: 19)
        }

        /// Marginalia label - small bold tracked
        static let marginLabel = Font.system(size: 9, weight: .bold)

        /// Marginalia body - regular serif
        /// Uses CustomFonts helper for centralized font loading
        static var marginBody: Font {
            CustomFonts.cormorantRegular(size: 15)
        }

        /// Chip text - medium
        static let chipText = Font.system(size: 10, weight: .medium)
    }

    // MARK: - Sacred Threshold Typography (Cinematic)
    // Bold, theatrical, impact-focused

    enum Threshold {
        /// Header title - bold tracked uppercase
        static let headerTitle = Font.system(size: 14, weight: .bold)

        /// Header subtitle - regular
        static let headerSubtitle = Font.system(size: 13, weight: .regular)

        /// Room name - large bold
        static let roomName = Font.system(size: 32, weight: .bold, design: .serif)

        /// Room description - regular
        static let roomDescription = Font.system(size: 16, weight: .regular)

        /// Progress text - medium
        static let progressText = Font.system(size: 11, weight: .medium)

        /// CTA button - semibold
        static let ctaButton = Font.system(size: 15, weight: .semibold)

        /// Swipe hint - light
        static let swipeHint = Font.system(size: 12, weight: .light)
    }
}

// MARK: - Text Style Modifiers

extension Text {
    /// Minimalist section header style
    func minimalistHeader() -> some View {
        self
            .font(SanctuaryTypography.Minimalist.sectionHeader)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Dashboard section header style
    func dashboardHeader() -> some View {
        self
            .font(SanctuaryTypography.Dashboard.sectionHeader)
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Narrative section header style
    func narrativeHeader() -> some View {
        self
            .font(SanctuaryTypography.Narrative.sectionHeader)
            .tracking(4)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Gold reference style
    func goldReference() -> some View {
        self
            .font(SanctuaryTypography.Minimalist.reference)
            .tracking(3)
            .foregroundStyle(Color.divineGold)
    }
}
