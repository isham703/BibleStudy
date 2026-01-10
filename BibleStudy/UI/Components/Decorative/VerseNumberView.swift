import SwiftUI

// MARK: - Verse Number View
// Displays verse numbers with different styles based on user preference
// Supports: superscript, inline, marginal, ornamental, minimal

struct VerseNumberView: View {
    let number: Int
    let style: VerseNumberStyle

    @Environment(\.colorScheme) private var colorScheme

    init(number: Int, style: VerseNumberStyle = .superscript) {
        self.number = number
        self.style = style
    }

    var body: some View {
        switch style {
        case .superscript:
            superscriptView
        case .inline:
            inlineView
        case .marginal:
            marginalView
        case .ornamental:
            ornamentalView
        case .minimal:
            minimalView
        }
    }

    // MARK: - Style Implementations

    /// Traditional superscript style (raised, smaller)
    private var superscriptView: some View {
        Text("\(number)")
            .font(style.font)
            .foregroundStyle(Color.verseNumber)
            .baselineOffset(6)
            .accessibilityLabel("Verse \(number)")
    }

    /// Inline style (same baseline as text)
    private var inlineView: some View {
        Text("\(number)")
            .font(style.font)
            .foregroundStyle(Color.verseNumber)
            .padding(.trailing, Theme.Spacing.xs)
            .accessibilityLabel("Verse \(number)")
    }

    /// Marginal style (for margin placement)
    private var marginalView: some View {
        Text("\(number)")
            .font(style.font)
            .foregroundStyle(Color.verseNumber.opacity(style.opacity))
            .frame(minWidth: 24, alignment: .trailing)
            .accessibilityLabel("Verse \(number)")
    }

    /// Ornamental style with Cinzel font
    private var ornamentalView: some View {
        ZStack {
            // Subtle gold glow
            Text("\(number)")
                .font(style.font)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                .blur(radius: 2)

            // Main number
            Text("\(number)")
                .font(style.font)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
        .accessibilityLabel("Verse \(number)")
    }

    /// Minimal style (very subtle)
    private var minimalView: some View {
        Text("\(number)")
            .font(style.font)
            .foregroundStyle(Color.verseNumber.opacity(style.opacity))
            .accessibilityLabel("Verse \(number)")
    }
}

// MARK: - Verse Number with Separator
// For verse-per-line mode where verse number leads the line

struct VerseLineNumber: View {
    let number: Int
    let style: VerseNumberStyle
    let width: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(
        number: Int,
        style: VerseNumberStyle = .marginal,
        width: CGFloat = Theme.Spacing.xxl
    ) {
        self.number = number
        self.style = style
        self.width = width
    }

    var body: some View {
        HStack(spacing: 0) {
            // Number
            VerseNumberView(number: number, style: style)
                .frame(width: width, alignment: .trailing)

            // Separator
            if style == .ornamental {
                // Decorative dot separator
                Circle()
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))
                    .frame(width: 3, height: 3)
                    .padding(.horizontal, Theme.Spacing.sm)
            } else {
                // Simple spacing
                Spacer()
                    .frame(width: Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Inline Verse Text
// Combines verse number with text content

struct InlineVerseText: View {
    let verseNumber: Int
    let text: String
    let verseStyle: VerseNumberStyle
    let fontSize: ScriptureFontSize
    let scriptureFont: ScriptureFont

    init(
        verseNumber: Int,
        text: String,
        verseStyle: VerseNumberStyle = .superscript,
        fontSize: ScriptureFontSize = .medium,
        scriptureFont: ScriptureFont = .newYork
    ) {
        self.verseNumber = verseNumber
        self.text = text
        self.verseStyle = verseStyle
        self.fontSize = fontSize
        self.scriptureFont = scriptureFont
    }

    var body: some View {
        switch verseStyle {
        case .superscript, .ornamental, .minimal:
            // Inline presentation
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                VerseNumberView(number: verseNumber, style: verseStyle)
                Text(text)
                    .font(Typography.Scripture.bodyWithSize(CGFloat(fontSize.rawValue)))
                    .foregroundStyle(Color.primaryText)
            }

        case .inline:
            // Number and text on same line with space
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("\(verseNumber)")
                    .font(verseStyle.font)
                    .foregroundStyle(Color.verseNumber)
                Text(text)
                    .font(Typography.Scripture.bodyWithSize(CGFloat(fontSize.rawValue)))
                    .foregroundStyle(Color.primaryText)
            }

        case .marginal:
            // Number in margin, text flows normally
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                VerseNumberView(number: verseNumber, style: verseStyle)
                    .frame(width: 24, alignment: .trailing)
                Text(text)
                    .font(Typography.Scripture.bodyWithSize(CGFloat(fontSize.rawValue)))
                    .foregroundStyle(Color.primaryText)
            }
        }
    }
}

// MARK: - Red Letter Text
// For Words of Christ (red letter editions)

struct RedLetterText: View {
    let text: String
    let fontSize: ScriptureFontSize
    let scriptureFont: ScriptureFont

    init(
        text: String,
        fontSize: ScriptureFontSize = .medium,
        scriptureFont: ScriptureFont = .newYork
    ) {
        self.text = text
        self.fontSize = fontSize
        self.scriptureFont = scriptureFont
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(Typography.Scripture.body)
            .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
    }
}

// MARK: - Preview

#Preview("Verse Number Styles") {
    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
        ForEach(VerseNumberStyle.allCases, id: \.self) { style in
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(style.displayName)
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: Theme.Spacing.xs) {
                    VerseNumberView(number: 1, style: style)
                    Text("In the beginning God created...")
                        .font(Typography.Scripture.body)
                }
            }
        }
    }
    .padding()
}

#Preview("Inline Verse Text") {
    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
        InlineVerseText(
            verseNumber: 1,
            text: "In the beginning God created the heaven and the earth.",
            verseStyle: .superscript
        )

        InlineVerseText(
            verseNumber: 2,
            text: "And the earth was without form, and void.",
            verseStyle: .ornamental
        )

        InlineVerseText(
            verseNumber: 3,
            text: "And God said, Let there be light.",
            verseStyle: .marginal
        )
    }
    .padding()
}

#Preview("Red Letter Text") {
    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
        Text("Jesus said:")
            .font(Typography.Scripture.body)
            .foregroundStyle(Color.primaryText)

        RedLetterText(
            text: "I am the way, the truth, and the life."
        )

        RedLetterText(
            text: "No man cometh unto the Father, but by me.",
            fontSize: .large
        )
    }
    .padding()
}
