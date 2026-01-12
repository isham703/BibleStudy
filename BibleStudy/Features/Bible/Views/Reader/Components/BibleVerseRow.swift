import SwiftUI

// MARK: - Bible Verse Row
// Individual verse display with selection, highlighting, and audio playback states
// Supports tap for selection, long-press for insights sheet

struct BibleVerseRow: View {
    let verse: Verse
    let isSelected: Bool
    let isInRange: Bool
    let highlightColor: HighlightColor?
    let selectionMode: BibleSelectionMode
    let isSpokenVerse: Bool
    let fontSize: ScriptureFontSize
    let scriptureFont: ScriptureFont
    let lineSpacing: CGFloat
    let flashOpacity: Double
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onBoundsChange: (CGRect) -> Void

    @State private var isPressed = false
    private let verseNumberWidth: CGFloat = 28
    // 4pt: selection should read as highlight band, not card. One-off, not tokenized.
    // swiftlint:disable:next hardcoded_corner_radius
    private let verseCornerRadius: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
                // Verse number - always muted (functional UI, not sacred)
                // Per design feedback: don't let number become hero even when selected
                Text("\(verse.verse)")
                    .readingVerseNumber()
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(width: verseNumberWidth, alignment: .trailing)

                // Verse text
                Text(verse.text)
                    .readingVerse(size: fontSize, font: scriptureFont, lineSpacing: lineSpacing)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Tight vertical (6pt), standard horizontal (16pt) = highlight band, not card
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.md)
        .background(verseBackground)
        .overlay(flashOverlay)
        .overlay(spokenUnderline, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: verseCornerRadius))
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: onLongPress)
        .background(selectionBoundsReader)
        .frame(minHeight: Theme.Size.minTapTarget)
    }

    // MARK: - Verse Background

    @ViewBuilder
    private var verseBackground: some View {
        RoundedRectangle(cornerRadius: verseCornerRadius)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected || isInRange {
            // Selection: temporary "I tapped this" state
            // Asset Catalog handles light/dark variants automatically
            return Color("SelectionBackground")
        } else if isSpokenVerse {
            return Color("SelectionBackground")
        } else if let highlight = highlightColor {
            // Highlight: persistent "I marked this" state (stronger to differentiate)
            // Asset Catalog handles light/dark variants automatically
            return highlight.color
        } else {
            return Color.clear
        }
    }

    // MARK: - Flash Overlay

    @ViewBuilder
    private var flashOverlay: some View {
        if flashOpacity > 0 {
            RoundedRectangle(cornerRadius: verseCornerRadius)
                .fill(Color("AppAccentAction").opacity(flashOpacity * 0.4))
        }
    }

    @ViewBuilder
    private var spokenUnderline: some View {
        if isSpokenVerse {
            Rectangle()
                .fill(Color("AppAccentAction"))
                .frame(height: 2)
                .padding(.leading, verseNumberWidth + Theme.Spacing.md)
                .padding(.trailing, Theme.Spacing.sm)
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.bottom, 2)
        }
    }

    private var selectionBoundsReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    if isSelected {
                        onBoundsChange(geo.frame(in: .global))
                    }
                }
                .onChange(of: isSelected) { _, newValue in
                    if newValue {
                        onBoundsChange(geo.frame(in: .global))
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    let verse = Verse(
        bookId: 43,
        chapter: 1,
        verse: 1,
        text: "In the beginning was the Word, and the Word was with God, and the Word was God."
    )

    VStack(spacing: Theme.Spacing.md) {
        BibleVerseRow(
            verse: verse,
            isSelected: false,
            isInRange: false,
            highlightColor: nil,
            selectionMode: .none,
            isSpokenVerse: false,
            fontSize: .medium,
            scriptureFont: .newYork,
            lineSpacing: 1.5,
            flashOpacity: 0,
            onTap: {},
            onLongPress: {},
            onBoundsChange: { _ in }
        )

        BibleVerseRow(
            verse: verse,
            isSelected: true,
            isInRange: false,
            highlightColor: nil,
            selectionMode: .single,
            isSpokenVerse: false,
            fontSize: .medium,
            scriptureFont: .newYork,
            lineSpacing: 1.5,
            flashOpacity: 0,
            onTap: {},
            onLongPress: {},
            onBoundsChange: { _ in }
        )

        BibleVerseRow(
            verse: verse,
            isSelected: false,
            isInRange: false,
            highlightColor: .amber,
            selectionMode: .none,
            isSpokenVerse: false,
            fontSize: .medium,
            scriptureFont: .newYork,
            lineSpacing: 1.5,
            flashOpacity: 0,
            onTap: {},
            onLongPress: {},
            onBoundsChange: { _ in }
        )
    }
    .padding()
    .background(Color("AppBackground"))
}
