import SwiftUI

// MARK: - Paragraph Mode View
// Displays verses in flowing paragraph format with verse numbers as superscripts

struct ParagraphModeView: View {
    let verses: [Verse]
    let selectedVerses: Set<Int>
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let onSelectVerse: (Int) -> Void
    /// Closure to retrieve highlight color for a given verse number
    /// Returns nil if verse is not highlighted
    let getHighlightColor: (Int) -> HighlightColor?

    var body: some View {
        // Build attributed text with all verses
        Text(buildAttributedText())
            .font(Typography.Scripture.bodyWithSize(fontSize))
            .foregroundStyle(Color.primaryText)
            .lineSpacing(lineSpacing)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(buildAccessibilityLabel())
    }

    private func buildAttributedText() -> AttributedString {
        var result = AttributedString()

        for (index, verse) in verses.enumerated() {
            // Superscript verse number
            var verseNumber = AttributedString("\(verse.verse)")
            verseNumber.font = Typography.UI.caption2
            verseNumber.foregroundColor = Color.verseNumber
            verseNumber.baselineOffset = 4

            result.append(verseNumber)
            result.append(AttributedString(" "))

            // Verse text with background color based on state priority
            var verseText = AttributedString(verse.text)

            // Priority 1: Selection state (interactive UI)
            if selectedVerses.contains(verse.verse) {
                verseText.backgroundColor = Color.selectedBackground
            }
            // Priority 2: Saved highlight (persistent user annotation)
            else if let highlightColor = getHighlightColor(verse.verse) {
                verseText.backgroundColor = highlightColor.color
            }
            // Note: Audio playback and preserved highlights not supported in paragraph mode
            // as it's unclear which word in the flowing text should be highlighted

            result.append(verseText)

            // Add space between verses (except last)
            if index < verses.count - 1 {
                result.append(AttributedString(" "))
            }
        }

        return result
    }

    private func buildAccessibilityLabel() -> String {
        verses.map { "Verse \($0.verse). \($0.text)" }.joined(separator: " ")
    }
}

// MARK: - Preview

#Preview {
    ParagraphModeView(
        verses: [
            Verse(bookId: 1, chapter: 1, verse: 1, text: "In the beginning God created the heaven and the earth."),
            Verse(bookId: 1, chapter: 1, verse: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep.")
        ],
        selectedVerses: [1],
        fontSize: .medium,
        lineSpacing: 6,
        onSelectVerse: { _ in },
        getHighlightColor: { _ in nil }
    )
}
