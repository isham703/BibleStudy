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
    ///     .foregroundStyle(Color.scholarIndigo)
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
    ///     .foregroundStyle(Color.scholarIndigo)
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
    ///     .foregroundStyle(Color.divineGold)
    /// ```
    func editorialReference() -> some View {
        self
            .font(Typography.Editorial.reference)
            .tracking(Typography.Editorial.referenceTracking)
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
    ///     .foregroundStyle(Color.primaryText)
    /// ```
    func editorialReferenceHero() -> some View {
        self
            .font(Typography.Editorial.referenceHero)
    }

    // MARK: - Reading Modifiers

    /// Verse text - respects user font preference with proper spacing
    ///
    /// Example: Main scripture display in readers
    ///
    /// **Includes:**
    /// - Font: User-selected (NewYork, Georgia, EB Garamond)
    /// - Line spacing: 8pt (contemplative reading)
    ///
    /// ```swift
    /// Text(verse.text)
    ///     .readingVerse(size: appState.scriptureFontSize, font: appState.scriptureFont)
    ///     .foregroundStyle(Color.primaryText)
    /// ```
    func readingVerse(size: ScriptureFontSize, font: ScriptureFont, lineSpacing: CGFloat? = nil) -> some View {
        self
            .font(Typography.Reading.verse(size: size, font: font))
            .lineSpacing(lineSpacing ?? Typography.Reading.verseLineSpacing)
    }

    /// Poetic verse - italic variant with generous spacing
    ///
    /// Example: Psalms, quoted passages
    ///
    /// **Includes:**
    /// - Font: User-selected italic
    /// - Line spacing: 10pt (poetic breathing room)
    ///
    /// ```swift
    /// Text(psalm.text)
    ///     .readingVersePoetic(size: appState.scriptureFontSize, font: appState.scriptureFont)
    ///     .foregroundStyle(Color.primaryText)
    /// ```
    func readingVersePoetic(size: ScriptureFontSize, font: ScriptureFont) -> some View {
        self
            .font(Typography.Reading.verseItalic(size: size, font: font))
            .lineSpacing(Typography.Reading.poeticLineSpacing)
    }

    /// Verse number - standard bold style
    ///
    /// Example: Default verse number display
    ///
    /// ```swift
    /// Text("\(verse.verse)")
    ///     .readingVerseNumber()
    ///     .foregroundStyle(Color.verseNumber)
    /// ```
    func readingVerseNumber() -> some View {
        self
            .font(Typography.Reading.verseNumber)
    }

    /// Chapter number - large bold serif
    ///
    /// Example: "Chapter 1" in reader headers
    ///
    /// ```swift
    /// Text("Chapter \(chapter)")
    ///     .readingChapterNumber()
    ///     .foregroundStyle(Color.primaryText)
    /// ```
    func readingChapterNumber() -> some View {
        self
            .font(Typography.Reading.chapterNumber)
    }

    // MARK: - Insight Modifiers

    /// Hero summary - primary AI insight text with spacing
    ///
    /// Example: Main insight summary, chat responses
    ///
    /// **Includes:**
    /// - Font: Cormorant Garamond Regular 17pt
    /// - Line spacing: 6pt
    ///
    /// ```swift
    /// Text(structured.summary)
    ///     .insightHeroSummary()
    ///     .foregroundStyle(AppTheme.InsightCard.heroText)
    /// ```
    func insightHeroSummary() -> some View {
        self
            .font(Typography.Insight.heroSummary)
            .lineSpacing(Typography.Insight.heroLineSpacing)
    }

    /// Insight body - standard AI content with spacing
    ///
    /// Example: Expanded content, detailed explanations
    ///
    /// **Includes:**
    /// - Font: Cormorant Garamond Regular 15pt
    /// - Line spacing: 5pt
    ///
    /// ```swift
    /// Text(explanation)
    ///     .insightBody()
    ///     .foregroundStyle(Color.primaryText)
    /// ```
    func insightBody() -> some View {
        self
            .font(Typography.Insight.body)
            .lineSpacing(Typography.Insight.bodyLineSpacing)
    }

    /// Insight header - Cinzel small caps for manuscript feel
    ///
    /// Example: "SCHOLARLY INSIGHT", "ILLUMINATED INSIGHT"
    ///
    /// **Includes:**
    /// - Font: Cinzel Regular 11pt
    ///
    /// ```swift
    /// Text("SCHOLARLY INSIGHT")
    ///     .insightHeader()
    ///     .foregroundStyle(Color.scholarIndigo)
    /// ```
    func insightHeader() -> some View {
        self
            .font(Typography.Insight.header)
    }

    /// Insight emphasis - semibold for key points
    ///
    /// Example: Highlighted terms, key concepts
    ///
    /// ```swift
    /// Text(keyTerm)
    ///     .insightEmphasis()
    ///     .foregroundStyle(Color.scholarIndigo)
    /// ```
    func insightEmphasis() -> some View {
        self
            .font(Typography.Insight.emphasis)
    }

    /// Insight italic - for quotes, marginalia
    ///
    /// Example: Block quotes, scholar's notes
    ///
    /// ```swift
    /// Text(quote)
    ///     .insightItalic()
    ///     .foregroundStyle(Color.secondaryText)
    /// ```
    func insightItalic() -> some View {
        self
            .font(Typography.Insight.italic)
    }

    /// Insight reference - semibold for cross-references
    ///
    /// Example: "See also John 3:16"
    ///
    /// ```swift
    /// Text(crossRef.reference)
    ///     .insightReference()
    ///     .foregroundStyle(Color.scholarIndigo)
    /// ```
    func insightReference() -> some View {
        self
            .font(Typography.Insight.reference)
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
