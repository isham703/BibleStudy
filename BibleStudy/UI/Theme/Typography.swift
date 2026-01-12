//
//  Typography.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Typographic Philosophy: "Serif for truth. Sans for command."
//  - New York (Serif) = Contemplation (scripture, readings, prompts, reflection)
//  - SF Pro (Sans) = Action (buttons, navigation, system, execution)
//  - Typography signals mode - font switching tells user when to think vs act
//
//  Hard Rules (Non-Negotiable):
//  1. Buttons are ALWAYS Sans - no poetic button labels
//  2. Serif = contemplation, Sans = execution (creates "codex + field manual" effect)
//  3. ALL CAPS only for tiny tags with tracking
//  4. Emphasis: Use italics (serif) for maxims/quotes, Use weight (sans) for system
//  5. Measure: Reading blocks constrained to max width, ~45-70 chars/line
//

import SwiftUI

// MARK: - Typography (Temporary Name - Will Be Renamed to Typography in Phase 7)

enum Typography {

    // MARK: - Scripture Tokens (New York Serif)

    /// Scripture tokens use New York serif for contemplation
    /// Use for: titles, examen prompts, readings, maxims, section headings
    enum Scripture {
        // S-Display: Hero titles ("Evening Examen")
        static let display: Font = .system(size: 34, weight: .semibold, design: .serif)
        static let displayLineSpacing: CGFloat = 5  // ~1.15 line height

        // S-Title: Screen/session titles
        static let title: Font = .system(size: 28, weight: .semibold, design: .serif)
        static let titleLineSpacing: CGFloat = 5  // ~1.18 line height

        // S-Heading: Section headers ("Daily Office")
        static let heading: Font = .system(size: 22, weight: .semibold, design: .serif)
        static let headingLineSpacing: CGFloat = 4  // ~1.20 line height

        // S-Prompt: Examination statements (questions to user)
        static let prompt: Font = .system(size: 24, weight: .regular, design: .serif)
        static let promptLineSpacing: CGFloat = 6  // ~1.25 line height

        // S-Body: Reading body text (scripture passages)
        // CRITICAL: Reading blocks must constrain to max width, target 45-70 characters/line
        static let body: Font = .system(size: 17, weight: .regular, design: .serif)
        static let bodyLineSpacing: CGFloat = 6  // ~1.45 line height

        // S-Quote: Maxims / quotations (italic for gravity)
        static let quote: Font = .system(size: 17, weight: .regular, design: .serif).italic()
        static let quoteLineSpacing: CGFloat = 6  // ~1.45 line height

        // S-Footnote: Footnotes / references
        static let footnote: Font = .system(size: 13, weight: .regular, design: .serif)
        static let footnoteLineSpacing: CGFloat = 4  // ~1.35 line height

        // S-Body with size: Dynamic sizing for user-selected font preferences
        // Used by Bible reader with ScriptureFontSize enum
        static func bodyWithSize(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }

        // RULES:
        // - Use italics for scripture-like emphasis; avoid bolding passages
        // - Keep serif text blocks narrower (measure control) for readability
        // - Target ~45-70 characters per line for reading text
    }

    // MARK: - Command Tokens (SF Pro Sans)

    /// Command tokens use SF Pro sans for action/execution
    /// Use for: buttons, navigation, labels, instructions, system states
    enum Command {
        // C-CTA: Primary buttons ("Begin", "Commit", "Review")
        static let cta: Font = .system(size: 17, weight: .semibold)
        static let ctaLineSpacing: CGFloat = 3  // ~1.20 line height

        // C-Body: Short instructions
        static let body: Font = .system(size: 17, weight: .regular)
        static let bodyLineSpacing: CGFloat = 5  // ~1.35 line height

        // C-Label: Field labels, chips
        static let label: Font = .system(size: 15, weight: .medium)
        static let labelLineSpacing: CGFloat = 3  // ~1.20 line height

        // C-Meta: Dates, tags, verse numbers (e.g., "LESSON", verse numbers)
        // HARD RULE: Verse numbers are ALWAYS sans (functional, not sacred)
        static let meta: Font = .system(size: 13, weight: .medium)
        static let metaLineSpacing: CGFloat = 2  // ~1.20 line height

        // C-Caption: Hints, helper text
        static let caption: Font = .system(size: 12, weight: .regular)
        static let captionLineSpacing: CGFloat = 2  // ~1.20 line height

        // C-ErrorTitle: Error titles
        static let errorTitle: Font = .system(size: 15, weight: .semibold)
        static let errorTitleLineSpacing: CGFloat = 3  // ~1.25 line height

        // C-ErrorBody: Error guidance
        static let errorBody: Font = .system(size: 13, weight: .regular)
        static let errorBodyLineSpacing: CGFloat = 3  // ~1.30 line height

        // C-LargeTitle: Large navigation titles
        static let largeTitle: Font = .system(size: 34, weight: .bold)

        // C-Title1: Primary titles
        static let title1: Font = .system(size: 28, weight: .bold)

        // C-Title2: Secondary titles
        static let title2: Font = .system(size: 22, weight: .bold)

        // C-Title3: Tertiary titles
        static let title3: Font = .system(size: 20, weight: .semibold)

        // C-Headline: Section headlines
        static let headline: Font = .system(size: 17, weight: .semibold)

        // C-Subheadline: Supporting text
        static let subheadline: Font = .system(size: 15, weight: .regular)

        // C-Callout: Callout text
        static let callout: Font = .system(size: 16, weight: .regular)

        // RULES:
        // - Use weight (not italics) for system emphasis
        // - Sentence case for labels, Title Case for buttons (pick one)
    }

    // MARK: - Label (Uppercase Tags)

    /// Uppercase labels for tiny tags with tracking
    /// Use for: metadata tags, small labels
    enum Label {
        static let uppercase: Font = .system(size: 12, weight: .medium)
        static let tracking: CGFloat = 2.2  // Letterspacing for ALL CAPS

        // Apply: .font(Typography.Label.uppercase).textCase(.uppercase).tracking(Typography.Label.tracking)
    }

    // MARK: - Editorial Tokens (Tracked Uppercase)

    /// Editorial tokens for section headers and labels with tracking
    /// Use for: section headers, editorial labels, references
    /// Apply with: .tracking(Typography.Editorial.sectionTracking).textCase(.uppercase)
    enum Editorial {
        // E-SectionHeader: Section headers (11pt bold + tracking)
        static let sectionHeader: Font = .system(size: 11, weight: .bold)

        // E-Label: Editorial labels (10pt bold + tracking)
        static let label: Font = .system(size: 10, weight: .bold)

        // E-LabelSmall: Small editorial labels (9pt bold + tracking)
        static let labelSmall: Font = .system(size: 9, weight: .bold)

        // Tracking Constants (Liturgical Spacing: 20-30%)
        static let sectionTracking: CGFloat = 2.5   // ~23% on 11pt
        static let labelTracking: CGFloat = 2.0     // ~20% on 10pt
        static let referenceTracking: CGFloat = 1.5 // Subtler for references
    }

    // MARK: - Icon Tokens (SF Symbol Sizes)

    /// Icon tokens for SF Symbols - use on Image(systemName:)
    /// Follows Apple's recommended icon sizing scale
    enum Icon {
        // Tiny icons (badges, indicators)
        static let xxxs: Font = .system(size: 8, weight: .medium)
        static let xxs: Font = .system(size: 10, weight: .medium)
        static let xs: Font = .system(size: 12, weight: .medium)

        // Standard icons (buttons, list rows)
        static let sm: Font = .system(size: 14, weight: .medium)
        static let md: Font = .system(size: 16, weight: .medium)
        static let base: Font = .system(size: 18, weight: .medium)

        // Large icons (empty states, feature cards)
        static let lg: Font = .system(size: 24, weight: .medium)
        static let xl: Font = .system(size: 28, weight: .medium)
        static let xxl: Font = .system(size: 32, weight: .medium)

        // Hero icons (onboarding, celebrations)
        static let hero: Font = .system(size: 40, weight: .medium)
        static let display: Font = .system(size: 76, weight: .medium)
    }

    // MARK: - Decorative Tokens (Illuminated Manuscript)

    /// Decorative tokens for illuminated manuscript effects
    /// Use for: drop caps, ornamental elements
    enum Decorative {
        // Drop cap - large illuminated first letter
        static let dropCap: Font = .system(size: 72, weight: .bold, design: .serif)
        static let dropCapCompact: Font = .system(size: 52, weight: .bold, design: .serif)
    }

    // MARK: - Title Page Tokens (Cormorant Garamond - Deliberate Exception)

    /// Title page tokens for ceremonial book/chapter headers
    /// Use for: Reader header book title ONLY
    ///
    /// WHY CORMORANT: The reader header is the one place where "ceremony" is the product.
    /// Cormorant creates a premium printed-book moment that system serif won't match.
    /// This is a deliberate, documented exception - not an accident.
    ///
    /// SCOPE: Book title only. Everything else (kicker, chapter label, controls) stays system.
    enum TitlePage {
        // TP-BookTitle: Large book name in reader header ("Genesis", "Matthew")
        // Cormorant Garamond SemiBold - deliberate luxury for title page moment
        static let bookTitle: Font = .custom("CormorantGaramond-SemiBold", size: 52)

        // Base size for Dynamic Type scaling (use with @ScaledMetric)
        static let bookTitleBaseSize: CGFloat = 52
    }
}

// MARK: - User Preference Types (Move to Settings/Models in future refactor)

/// User font size selection for Bible reading
/// This is a functional type for user preferences, not a design token
/// Consider moving to Core/Models/Settings/ in future refactor
enum ScriptureFontSize: Int, CaseIterable {
    case small = 14
    case medium = 17
    case large = 20

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}



// MARK: - View Extensions (Convenience Helpers)

@available(iOS 13.0, *)
extension View {
    // MARK: Scripture Helpers

    /// Apply Scripture display style (hero titles)
    func scriptureDisplay() -> some View {
        self
            .font(Typography.Scripture.display)
            .lineSpacing(Typography.Scripture.displayLineSpacing)
    }

    /// Apply Scripture title style (screen/session titles)
    func scriptureTitle() -> some View {
        self
            .font(Typography.Scripture.title)
            .lineSpacing(Typography.Scripture.titleLineSpacing)
    }

    /// Apply Scripture heading style (section headers)
    func scriptureHeading() -> some View {
        self
            .font(Typography.Scripture.heading)
            .lineSpacing(Typography.Scripture.headingLineSpacing)
    }

    /// Apply Scripture prompt style (examination questions)
    func scripturePrompt() -> some View {
        self
            .font(Typography.Scripture.prompt)
            .lineSpacing(Typography.Scripture.promptLineSpacing)
    }

    /// Apply Scripture body style (reading text)
    /// CRITICAL: Constrain reading width to 45-65 chars/line externally
    func scriptureBody() -> some View {
        self
            .font(Typography.Scripture.body)
            .lineSpacing(Typography.Scripture.bodyLineSpacing)
    }

    /// Apply Scripture quote style (maxims, quotations)
    func scriptureQuote() -> some View {
        self
            .font(Typography.Scripture.quote)
            .lineSpacing(Typography.Scripture.quoteLineSpacing)
    }

    /// Apply Scripture footnote style (references)
    func scriptureFootnote() -> some View {
        self
            .font(Typography.Scripture.footnote)
            .lineSpacing(Typography.Scripture.footnoteLineSpacing)
    }

    // MARK: Title Page Helpers

    /// Apply Title Page book title style (reader header book name)
    /// Uses Cormorant Garamond - deliberate exception for ceremonial title page moment
    /// NOTE: For Dynamic Type support, pass a @ScaledMetric size parameter
    func titlePageBookTitle() -> some View {
        self
            .font(Typography.TitlePage.bookTitle)
    }

    /// Apply Title Page book title with custom size (for Dynamic Type scaling)
    /// Use with @ScaledMetric(relativeTo: .title) for accessibility support
    func titlePageBookTitle(size: CGFloat) -> some View {
        self
            .font(.custom("CormorantGaramond-SemiBold", size: size))
    }

    // MARK: Command Helpers

    /// Apply Command CTA style (primary buttons)
    func commandCTA() -> some View {
        self
            .font(Typography.Command.cta)
            .lineSpacing(Typography.Command.ctaLineSpacing)
    }

    /// Apply Command body style (short instructions)
    func commandBody() -> some View {
        self
            .font(Typography.Command.body)
            .lineSpacing(Typography.Command.bodyLineSpacing)
    }

    /// Apply Command label style (field labels, chips)
    func commandLabel() -> some View {
        self
            .font(Typography.Command.label)
            .lineSpacing(Typography.Command.labelLineSpacing)
    }

    /// Apply Command meta style (dates, tags, verse numbers)
    func commandMeta() -> some View {
        self
            .font(Typography.Command.meta)
            .lineSpacing(Typography.Command.metaLineSpacing)
    }

    /// Apply Command caption style (hints, helper text)
    func commandCaption() -> some View {
        self
            .font(Typography.Command.caption)
            .lineSpacing(Typography.Command.captionLineSpacing)
    }

    /// Apply Command error title style
    func commandErrorTitle() -> some View {
        self
            .font(Typography.Command.errorTitle)
            .lineSpacing(Typography.Command.errorTitleLineSpacing)
    }

    /// Apply Command error body style
    func commandErrorBody() -> some View {
        self
            .font(Typography.Command.errorBody)
            .lineSpacing(Typography.Command.errorBodyLineSpacing)
    }

    // MARK: Label Helpers

    /// Apply uppercase label style (tiny tags with tracking)
    func uppercaseLabel() -> some View {
        self
            .font(Typography.Label.uppercase)
            .textCase(.uppercase)
            .tracking(Typography.Label.tracking)
    }
}

// MARK: - Typography Avoids (Documentation)

/*
 Typography Avoids:
 - ❌ Edge-to-edge paragraphs (constrain reading width)
 - ❌ Bolding scripture passages (use italics for gravity)
 - ❌ Italics in sans (use weight instead)
 - ❌ Poetic/metaphorical button labels

 Critical Migrations from Old System:
 - Typography.Scripture.body(size:) → Typography.Scripture.body (with .scriptureBody() helper)
 - Typography.Codex.heroSummary → Typography.Scripture.heading
 - Typography.Command.body → Typography.Command.body
 - Typography.Editorial.label → Typography.Label.uppercase
 - ALL buttons → Typography.Command.cta (with .commandCTA() helper)
 */

// MARK: - Bible Reading Layout Specification (Documentation)

/*
 Bible Reading Layout:

 Mode A - Canonical Reading (Bible chapters, Psalms, long passages):
 - Chapter Header: S-Heading (22pt semibold), SMALL CAPS, left align, letterspacing +0.5pt
   Example: "PSALM 23"
   Optional subtitle: C-Meta (sans), 70-80% opacity ("A Psalm of David")

 - Body Text: S-Body (17pt), line spacing .lineSpacing(6-7), max width 45-65 chars/line
   CRITICAL: Max width constraint required - "codex page, not blog post"
   Alignment: Left (never justified)

 - Verse Numbers: SF Pro (Command.meta), 12-13pt Medium, 60-70% opacity, slightly raised
   HARD RULE: Verse numbers are ALWAYS sans (functional, not sacred)
   Example: "¹ The Lord is my shepherd; I shall not want."

 Mode B - Meditative Reading (short passages, verse-by-verse):
 - Same typography as Mode A
 - Each verse stands alone with extra vertical spacing (16-24pt)
 - Encourages pause and deliberation

 Emphasis Rules:
 - Use italic (serif) for emphasis only
 - NO bolding scripture body
 - NO color highlights
 - If emphasis needed: use spacing, isolation, silence

 Red-Letter Treatment (Christ's words):
 - Keep New York serif
 - Subtle ivory/gold tint (felt, not seen)
 - NO font/weight change, NO red color

 Margins & Measure:
 - iPhone: 20-24pt horizontal padding
 - iPad: constrained text column (do NOT go full width)
 - Paragraph separation: 12-16pt
 - Section breaks: 24-32pt

 Dark Mode (Default):
 - Background: near-black/deep charcoal
 - Text: soft ivory (NOT pure white)
 - High contrast for night reading, not clinical

 What This Layout Achieves:
 "Scripture for men who intend to live it" - authoritative, disciplined, permanent, worthy of daily return
 */
