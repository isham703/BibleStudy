import SwiftUI

// MARK: - Home Showcase Typography
// Font definitions for the Home Page Showcase app

enum HomeShowcaseTypography {

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

        /// Verse text - elegant serif
        static var verse: Font {
            if let _ = UIFont(name: cormorantItalic, size: 28) {
                return Font.custom(cormorantItalic, size: 28)
            }
            return Font.system(size: 28, weight: .regular, design: .serif).italic()
        }

        /// Reference - tracked Cinzel
        static var reference: Font {
            if let _ = UIFont(name: cinzelRegular, size: 12) {
                return Font.custom(cinzelRegular, size: 12)
            }
            return Font.system(size: 12, weight: .medium)
        }

        /// Action text - medium weight
        static let action = Font.system(size: 16, weight: .medium)

        /// Section header - uppercase tracked
        static var sectionHeader: Font {
            if let _ = UIFont(name: cinzelRegular, size: 11) {
                return Font.custom(cinzelRegular, size: 11)
            }
            return Font.system(size: 11, weight: .medium)
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
        /// Hero title - tracked Cinzel
        static var heroTitle: Font {
            if let _ = UIFont(name: cinzelRegular, size: 13) {
                return Font.custom(cinzelRegular, size: 13)
            }
            return Font.system(size: 13, weight: .medium)
        }

        /// Hero greeting - large Cormorant
        static var heroGreeting: Font {
            if let _ = UIFont(name: cormorantSemiBold, size: 32) {
                return Font.custom(cormorantSemiBold, size: 32)
            }
            return Font.system(size: 32, weight: .semibold, design: .serif)
        }

        /// Hero stats
        static let heroStats = Font.system(size: 15, weight: .medium)

        /// Section header - tracked Cinzel
        static var sectionHeader: Font {
            if let _ = UIFont(name: cinzelRegular, size: 11) {
                return Font.custom(cinzelRegular, size: 11)
            }
            return Font.system(size: 11, weight: .medium)
        }

        /// Verse text - italic Cormorant
        static var verse: Font {
            if let _ = UIFont(name: cormorantItalic, size: 24) {
                return Font.custom(cormorantItalic, size: 24)
            }
            return Font.system(size: 24, weight: .regular, design: .serif).italic()
        }

        /// Decorative quote mark
        static var decorativeQuote: Font {
            if let _ = UIFont(name: cinzelRegular, size: 72) {
                return Font.custom(cinzelRegular, size: 72)
            }
            return Font.system(size: 72, weight: .light, design: .serif)
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
        /// Greeting - whisper light
        static var greeting: Font {
            if let _ = UIFont(name: cormorantRegular, size: 15) {
                return Font.custom(cormorantRegular, size: 15)
            }
            return Font.system(size: 15, weight: .light, design: .serif)
        }

        /// Verse text - elegant italic
        static var verse: Font {
            if let _ = UIFont(name: cormorantItalic, size: 26) {
                return Font.custom(cormorantItalic, size: 26)
            }
            return Font.system(size: 26, weight: .regular, design: .serif).italic()
        }

        /// Reference - tracked Cinzel uppercase
        static var reference: Font {
            if let _ = UIFont(name: cinzelRegular, size: 11) {
                return Font.custom(cinzelRegular, size: 11)
            }
            return Font.system(size: 11, weight: .medium)
        }

        /// Feature label - small tracked Cinzel
        static var featureLabel: Font {
            if let _ = UIFont(name: cinzelRegular, size: 10) {
                return Font.custom(cinzelRegular, size: 10)
            }
            return Font.system(size: 10, weight: .medium)
        }

        /// Feature title - Cormorant semibold
        static var featureTitle: Font {
            if let _ = UIFont(name: cormorantSemiBold, size: 18) {
                return Font.custom(cormorantSemiBold, size: 18)
            }
            return Font.system(size: 18, weight: .semibold, design: .serif)
        }

        /// Feature subtitle - system light
        static let featureSubtitle = Font.system(size: 13, weight: .light)

        /// Duration text - small Cinzel
        static var duration: Font {
            if let _ = UIFont(name: cinzelRegular, size: 9) {
                return Font.custom(cinzelRegular, size: 9)
            }
            return Font.system(size: 9, weight: .regular)
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
        static let sectionHeader = Font.system(size: 11, weight: .bold)

        /// Scripture reference - semibold
        static let scriptureRef = Font.system(size: 14, weight: .semibold, design: .serif)

        /// Scripture text - regular serif
        static var scriptureText: Font {
            if let _ = UIFont(name: cormorantRegular, size: 19) {
                return Font.custom(cormorantRegular, size: 19)
            }
            return Font.system(size: 19, weight: .regular, design: .serif)
        }

        /// Marginalia label - small bold tracked
        static let marginLabel = Font.system(size: 9, weight: .bold)

        /// Marginalia body - regular serif
        static var marginBody: Font {
            if let _ = UIFont(name: cormorantRegular, size: 15) {
                return Font.custom(cormorantRegular, size: 15)
            }
            return Font.system(size: 15, weight: .regular, design: .serif)
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
            .font(HomeShowcaseTypography.Minimalist.sectionHeader)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Dashboard section header style
    func dashboardHeader() -> some View {
        self
            .font(HomeShowcaseTypography.Dashboard.sectionHeader)
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Narrative section header style
    func narrativeHeader() -> some View {
        self
            .font(HomeShowcaseTypography.Narrative.sectionHeader)
            .tracking(4)
            .textCase(.uppercase)
            .foregroundStyle(Color.divineGold)
    }

    /// Gold reference style
    func goldReference() -> some View {
        self
            .font(HomeShowcaseTypography.Minimalist.reference)
            .tracking(3)
            .foregroundStyle(Color.divineGold)
    }
}
