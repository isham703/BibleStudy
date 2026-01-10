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

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    private let verseNumberWidth: CGFloat = 28

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Verse number
                Text("\(verse.verse)")
                    .readingVerseNumber()
                    .foregroundStyle(isSelected ? Colors.Semantic.accentAction(for: themeMode) : Colors.Surface.textPrimary(for: themeMode))
                    .frame(width: verseNumberWidth, alignment: .trailing)

                // Verse text
                Text(verse.text)
                    .readingVerse(size: fontSize, font: scriptureFont, lineSpacing: lineSpacing)
                    .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(verseBackground)
        .overlay(verseOverlay)
        .overlay(flashOverlay)
        .overlay(spokenUnderline, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: onLongPress)
        .background(selectionBoundsReader)
        .frame(minHeight: 60)
    }

    // MARK: - Verse Background

    @ViewBuilder
    private var verseBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected || isInRange {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
        } else if isSpokenVerse {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
        } else if let highlight = highlightColor {
            return highlight.color.opacity(Theme.Opacity.light)
        } else {
            return Color.clear
        }
    }

    // MARK: - Verse Overlay

    @ViewBuilder
    private var verseOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .stroke(overlayColor, lineWidth: isSelected ? 1.5 : 1)
    }

    private var overlayColor: Color {
        if isSelected {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary)
        } else if isInRange {
            return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.tertiary)
        } else {
            return Color.clear
        }
    }

    @ViewBuilder
    private var flashOverlay: some View {
        if flashOpacity > 0 {
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(flashOpacity * 0.4))
        }
    }

    @ViewBuilder
    private var spokenUnderline: some View {
        if isSpokenVerse {
            Rectangle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
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
    .background(Colors.Surface.background(for: .dark))
}
