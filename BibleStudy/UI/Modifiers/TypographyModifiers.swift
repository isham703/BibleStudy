import SwiftUI

// MARK: - Typography View Modifiers
// Correct-by-default typography application
// Encapsulates font + tracking + line spacing + text case atomically
//
// Why this matters:
// - Developers can't forget to apply tracking or line spacing
// - Ensures consistent application across the app
// - Single source of truth for each typography pattern

extension View {

    // MARK: - Editorial Modifiers

    /// Section header - tracked uppercase for metadata
    ///
    /// Example: "TODAY'S STUDY", "DEEPEN YOUR UNDERSTANDING"
    ///
    /// **Includes:**
    /// - Font: System bold 11pt
    /// - Tracking: 2.5px (liturgical spacing)
    /// - Text case: Uppercase
    ///
    /// ```swift
    /// Text("TODAY'S STUDY")
    ///     .editorialSectionHeader()
    ///     .foregroundStyle(Color("AppAccentAction"))
    /// ```
    func editorialSectionHeader() -> some View {
        self
            .font(Typography.Editorial.sectionHeader)
            .tracking(Typography.Editorial.sectionTracking)
            .textCase(.uppercase)
    }

    /// Small label - tracked uppercase for chips and tags
    ///
    /// Example: "SCHOLARLY INSIGHT", "CONNECTION"
    ///
    /// **Includes:**
    /// - Font: System bold 10pt
    /// - Tracking: 1.5px
    /// - Text case: Uppercase
    ///
    /// ```swift
    /// Text("SCHOLARLY INSIGHT")
    ///     .editorialLabel()
    ///     .foregroundStyle(Color("AppAccentAction"))
    /// ```
    func editorialLabel() -> some View {
        self
            .font(Typography.Editorial.label)
            .tracking(Typography.Editorial.labelTracking)
            .textCase(.uppercase)
    }

    /// Reference - Cinzel with tracking for scripture citations
    ///
    /// Example: "Gen 1:1", "Eph 2:20"
    ///
    /// **Includes:**
    /// - Font: Cinzel Regular 11pt (with system fallback)
    /// - Tracking: 3.0px (inscriptional quality)
    ///
    /// ```swift
    /// Text("Gen 1:1")
    ///     .editorialReference()
    ///     .foregroundStyle(Color("AccentBronze"))
    /// ```
    func editorialReference() -> some View {
        self
            .font(Typography.Command.meta)
            .tracking(1.5)  // Reference tracking for citations
    }

    /// Hero reference - large serif for prominent displays
    ///
    /// Example: Main passage reference in study cards
    ///
    /// **Includes:**
    /// - Font: System semibold serif 14pt
    ///
    /// ```swift
    /// Text("Genesis 1:1-5")
    ///     .editorialReferenceHero()
    ///     .foregroundStyle(Color("AppTextPrimary"))
    /// ```
    func editorialReferenceHero() -> some View {
        self
            .font(Typography.Command.meta)
    }

    // MARK: - Reading Modifiers

    /// Verse text - New York serif with proper spacing
    ///
    /// Example: Main scripture display in readers
    ///
    /// **Includes:**
    /// - Font: New York serif (system built-in)
    /// - Line spacing: 6pt (contemplative reading per design system)
    ///
    /// ```swift
    /// Text(verse.text)
    ///     .readingVerse(size: appState.scriptureFontSize, font: appState.scriptureFont)
    ///     .foregroundStyle(Color("AppTextPrimary"))
    /// ```
    func readingVerse(size: ScriptureFontSize, font: ScriptureFont, lineSpacing: CGFloat? = nil) -> some View {
        self
            .font(Typography.Scripture.body)
            .lineSpacing(lineSpacing ?? Typography.Scripture.bodyLineSpacing)
    }

    /// Poetic verse - italic variant with generous spacing
    ///
    /// Example: Psalms, quoted passages
    ///
    /// **Includes:**
    /// - Font: New York serif italic
    /// - Line spacing: 6pt (same as body for consistency)
    ///
    /// ```swift
    /// Text(psalm.text)
    ///     .readingVersePoetic(size: appState.scriptureFontSize, font: appState.scriptureFont)
    ///     .foregroundStyle(Color("AppTextPrimary"))
    /// ```
    func readingVersePoetic(size: ScriptureFontSize, font: ScriptureFont) -> some View {
        self
            .font(Typography.Scripture.quote)
            .lineSpacing(Typography.Scripture.quoteLineSpacing)
    }

    /// Verse number - SF Pro sans (functional, not sacred)
    ///
    /// Example: Default verse number display
    ///
    /// **HARD RULE**: Verse numbers are ALWAYS sans (functional, not sacred)
    ///
    /// ```swift
    /// Text("\(verse.verse)")
    ///     .readingVerseNumber()
    ///     .foregroundStyle(Color("TertiaryText"))
    /// ```
    func readingVerseNumber() -> some View {
        self
            .font(Typography.Command.meta)
    }

    /// Chapter number - Scripture heading style
    ///
    /// Example: "Chapter 1" in reader headers
    ///
    /// ```swift
    /// Text("Chapter \(chapter)")
    ///     .readingChapterNumber()
    ///     .foregroundStyle(Color("AppTextPrimary"))
    /// ```
    func readingChapterNumber() -> some View {
        self
            .font(Typography.Scripture.heading)
    }

    // MARK: - Insight Modifiers

    /// Hero summary - primary AI insight text with spacing
    ///
    /// Example: Main insight summary, chat responses
    ///
    /// **Includes:**
    /// - Font: New York serif (Scripture heading)
    /// - Line spacing: 4pt
    ///
    /// ```swift
    /// Text(structured.summary)
    ///     .insightHeroSummary()
    ///     .foregroundStyle(Color.white)
    /// ```
    func insightHeroSummary() -> some View {
        self
            .font(Typography.Scripture.heading)
            .lineSpacing(Typography.Scripture.headingLineSpacing)
    }

    /// Insight body - standard AI content with spacing
    ///
    /// Example: Expanded content, detailed explanations
    ///
    /// **Includes:**
    /// - Font: New York serif (Scripture body)
    /// - Line spacing: 6pt
    ///
    /// ```swift
    /// Text(explanation)
    ///     .insightBody()
    ///     .foregroundStyle(Color("AppTextPrimary"))
    /// ```
    func insightBody() -> some View {
        self
            .font(Typography.Scripture.body)
            .lineSpacing(Typography.Scripture.bodyLineSpacing)
    }

    /// Insight header - uppercase label for tags
    ///
    /// Example: "SCHOLARLY INSIGHT", "ILLUMINATED INSIGHT"
    ///
    /// **Includes:**
    /// - Font: SF Pro Medium 12pt uppercase with tracking
    ///
    /// ```swift
    /// Text("SCHOLARLY INSIGHT")
    ///     .insightHeader()
    ///     .foregroundStyle(Color("AppAccentAction"))
    /// ```
    func insightHeader() -> some View {
        self
            .uppercaseLabel()
    }

    /// Insight emphasis - semibold for key points
    ///
    /// Example: Highlighted terms, key concepts
    ///
    /// ```swift
    /// Text(keyTerm)
    ///     .insightEmphasis()
    ///     .foregroundStyle(Color("AppAccentAction"))
    /// ```
    func insightEmphasis() -> some View {
        self
            .font(Typography.Command.label)
    }

    /// Insight italic - for quotes, marginalia
    ///
    /// Example: Block quotes, scholar's notes
    ///
    /// ```swift
    /// Text(quote)
    ///     .insightItalic()
    ///     .foregroundStyle(Color("AppTextSecondary"))
    /// ```
    func insightItalic() -> some View {
        self
            .font(Typography.Scripture.quote)
    }

    /// Insight reference - semibold for cross-references
    ///
    /// Example: "See also John 3:16"
    ///
    /// ```swift
    /// Text(crossRef.reference)
    ///     .insightReference()
    ///     .foregroundStyle(Color("AppAccentAction"))
    /// ```
    func insightReference() -> some View {
        self
            .font(Typography.Command.label)
    }
}

// MARK: - Migration Helpers
// Convenience extensions for common patterns during migration

extension View {
    /// Apply editorial section header with custom color
    ///
    /// Convenience method that combines typography + color
    ///
    /// ```swift
    /// Text("TODAY'S STUDY")
    ///     .editorialSectionHeader(color: .scholarIndigo)
    /// ```
    func editorialSectionHeader(color: Color) -> some View {
        self
            .editorialSectionHeader()
            .foregroundStyle(color)
    }

    /// Apply editorial label with custom color
    ///
    /// ```swift
    /// Text("SCHOLARLY INSIGHT")
    ///     .editorialLabel(color: .scholarIndigo)
    /// ```
    func editorialLabel(color: Color) -> some View {
        self
            .editorialLabel()
            .foregroundStyle(color)
    }

    /// Apply editorial reference with custom color
    ///
    /// ```swift
    /// Text("Gen 1:1")
    ///     .editorialReference(color: .divineGold)
    /// ```
    func editorialReference(color: Color) -> some View {
        self
            .editorialReference()
            .foregroundStyle(color)
    }
}
