import SwiftUI

// MARK: - Verse With Indicator
// Displays verse text with an insight indicator at the end
// Used in Reading Mode of Living Commentary for clean verse flow
// Design: Verse text flows naturally with subtle indicator when insights are available

struct VerseWithIndicator: View {
    // MARK: - Properties

    /// The verse to display
    let verse: Verse

    /// Number of insights available for this verse (0 = no indicator)
    let insightCount: Int

    /// Whether this verse's lens container is currently expanded
    let isExpanded: Bool

    /// Action when indicator is tapped
    let onIndicatorTap: () -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Dynamic Type Support

    @ScaledMetric(relativeTo: .title) private var verseTextSize: CGFloat = 26
    @ScaledMetric(relativeTo: .caption) private var verseNumberSize: CGFloat = 12

    // MARK: - State

    @State private var parallaxOpacity: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Verse number (superscript style)
            verseNumberView

            // Verse text
            verseTextView

            // Indicator (if insights available)
            if insightCount > 0 {
                BibleInsightIndicator(
                    count: insightCount,
                    isExpanded: isExpanded,
                    onTap: onIndicatorTap
                )
                .padding(.leading, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(parallaxOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityHint(insightCount > 0 ? (isExpanded ? "Insights expanded. Double tap to collapse." : "Double tap to reveal \(insightCount) insight\(insightCount == 1 ? "" : "s").") : "")
    }

    // MARK: - Verse Number

    private var verseNumberView: some View {
        Text("\(verse.verse)")
            .font(.custom("CormorantGaramond-SemiBold", size: verseNumberSize))
            .foregroundStyle(Color.bibleInsightText.opacity(0.4))
            .baselineOffset(8)  // Superscript positioning
            .padding(.trailing, 4)
    }

    // MARK: - Verse Text

    private var verseTextView: some View {
        Text(verse.text)
            .font(.custom("CormorantGaramond-Regular", size: verseTextSize))
            .lineSpacing(10)
            .foregroundStyle(Color.bibleInsightText)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Accessibility

    private func buildAccessibilityLabel() -> String {
        var label = "Verse \(verse.verse). \(verse.text)"
        if insightCount > 0 {
            label += ". \(insightCount) insight\(insightCount == 1 ? "" : "s") available."
        }
        return label
    }

    // MARK: - Parallax Support

    /// Update parallax opacity based on scroll position
    /// Called from parent view with viewport-relative position
    func withParallaxOpacity(_ opacity: CGFloat) -> VerseWithIndicator {
        var copy = self
        copy._parallaxOpacity = State(initialValue: opacity)
        return copy
    }
}

// MARK: - Commentary Verse Row
// Container for verse + optional lens container with proper spacing
// Named to avoid conflict with VerseRow in VersePickerSheet

struct CommentaryVerseRow: View {
    let verse: Verse
    let insightCount: Int
    let isExpanded: Bool
    let selectedLens: BibleInsightType?
    let insights: [BibleInsight]
    let onIndicatorTap: () -> Void
    let onSelectLens: (BibleInsightType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Verse with indicator
            VerseWithIndicator(
                verse: verse,
                insightCount: insightCount,
                isExpanded: isExpanded,
                onIndicatorTap: onIndicatorTap
            )

            // Lens container (if expanded)
            if isExpanded && !insights.isEmpty {
                LensContainer(
                    insights: insights,
                    selectedLens: selectedLens,
                    onSelectLens: onSelectLens
                )
                .padding(.top, 16)
                .padding(.leading, 20)  // Indent to align with verse text
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Verse With Indicator") {
    struct PreviewContainer: View {
        @State private var expanded1 = false
        @State private var expanded2 = false
        @State private var expanded3 = false

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Verse with no insights
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No insights")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God."),
                            insightCount: 0,
                            isExpanded: false,
                            onIndicatorTap: {}
                        )
                    }

                    // Verse with insights (collapsed)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("With insights (collapsed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God."),
                            insightCount: 3,
                            isExpanded: false,
                            onIndicatorTap: {}
                        )
                    }

                    // Verse with insights (expanded)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("With insights (expanded)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 2, text: "The same was in the beginning with God."),
                            insightCount: 2,
                            isExpanded: true,
                            onIndicatorTap: {}
                        )
                    }

                    Divider()
                        .padding(.vertical, 20)

                    // Interactive example
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive (tap indicators)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God."),
                            insightCount: 3,
                            isExpanded: expanded1
                        ) {
                            withAnimation(AppTheme.Animation.cardUnfurl) {
                                expanded1.toggle()
                                if expanded1 {
                                    expanded2 = false
                                    expanded3 = false
                                }
                            }
                        }

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 2, text: "The same was in the beginning with God."),
                            insightCount: 2,
                            isExpanded: expanded2
                        ) {
                            withAnimation(AppTheme.Animation.cardUnfurl) {
                                expanded2.toggle()
                                if expanded2 {
                                    expanded1 = false
                                    expanded3 = false
                                }
                            }
                        }

                        VerseWithIndicator(
                            verse: Verse(bookId: 43, chapter: 1, verse: 3, text: "All things were made by him; and without him was not any thing made that was made."),
                            insightCount: 4,
                            isExpanded: expanded3
                        ) {
                            withAnimation(AppTheme.Animation.cardUnfurl) {
                                expanded3.toggle()
                                if expanded3 {
                                    expanded1 = false
                                    expanded2 = false
                                }
                            }
                        }
                    }
                }
                .padding(28)
            }
            .background(Color.bibleInsightParchment)
        }
    }

    return PreviewContainer()
}

#Preview("Golden Rule - Looks Like Normal Bible") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // All verses collapsed - should look like a normal Bible
            ForEach(1...5, id: \.self) { verseNum in
                VerseWithIndicator(
                    verse: Verse(
                        bookId: 43,
                        chapter: 1,
                        verse: verseNum,
                        text: sampleVerseText(for: verseNum)
                    ),
                    insightCount: verseNum % 2 == 0 ? 0 : Int.random(in: 1...4),
                    isExpanded: false,
                    onIndicatorTap: {}
                )
            }
        }
        .padding(28)
    }
    .background(Color.bibleInsightParchment)
}

private func sampleVerseText(for verse: Int) -> String {
    switch verse {
    case 1: return "In the beginning was the Word, and the Word was with God, and the Word was God."
    case 2: return "The same was in the beginning with God."
    case 3: return "All things were made by him; and without him was not any thing made that was made."
    case 4: return "In him was life; and the life was the light of men."
    case 5: return "And the light shineth in darkness; and the darkness comprehended it not."
    default: return "Sample verse text."
    }
}
