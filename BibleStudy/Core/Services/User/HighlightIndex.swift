import Foundation

// MARK: - Highlight Index
// Provides O(1) lookup for verse → highlight color
// Expands range highlights into per-verse dictionary

struct HighlightIndex {
    // Maps each verse number to its highlight color
    private let verseMap: [Int: HighlightColor]

    // Store original highlights for future overlap support
    private let sourceHighlights: [Highlight]

    // MARK: - Initialization

    /// Build index from highlights array
    /// Expands range highlights (verseStart...verseEnd) into individual verse entries
    init(highlights: [Highlight]) {
        var map: [Int: HighlightColor] = [:]

        for highlight in highlights {
            // Expand range into individual verses
            for verse in highlight.verseStart...highlight.verseEnd {
                // Later highlights override earlier ones (most recent wins)
                map[verse] = highlight.color
            }
        }

        self.verseMap = map
        self.sourceHighlights = highlights
    }

    // MARK: - Lookup

    /// O(1) lookup for verse highlight color
    func color(for verse: Int) -> HighlightColor? {
        verseMap[verse]
    }

    /// Check if verse has any highlight
    func hasHighlight(for verse: Int) -> Bool {
        verseMap[verse] != nil
    }

    // MARK: - Future: Multiple Overlapping Highlights

    /// Get all colors for a verse (supports overlapping highlights)
    /// Currently returns single color, but designed for future extensibility
    func allColors(for verse: Int) -> [HighlightColor] {
        sourceHighlights
            .filter { $0.verseStart <= verse && verse <= $0.verseEnd }
            .map { $0.color }
    }

    /// Get all highlights covering a verse
    func highlights(for verse: Int) -> [Highlight] {
        sourceHighlights
            .filter { $0.verseStart <= verse && verse <= $0.verseEnd }
    }
}
