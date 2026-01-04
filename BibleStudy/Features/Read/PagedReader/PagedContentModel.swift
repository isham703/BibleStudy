//
//  PagedContentModel.swift
//  BibleStudy
//
//  Calculates page layout for e-reader style Bible reading
//

import SwiftUI

// MARK: - Paged Content Model

/// Splits chapter content into pages based on available size and font settings
struct PagedContentModel {
    /// A single page containing a subset of verses
    struct Page: Identifiable {
        let id: Int // Page number (0-indexed)
        let verses: [Verse]

        var startVerse: Int { verses.first?.verse ?? 0 }
        var endVerse: Int { verses.last?.verse ?? 0 }
    }

    /// Calculate pages for a chapter given the available size and settings
    static func calculatePages(
        chapter: Chapter,
        availableSize: CGSize,
        fontSize: ScriptureFontSize,
        lineSpacing: CGFloat,
        contentPadding: CGFloat = AppTheme.Spacing.lg * 2 // Horizontal padding
    ) -> [Page] {
        let verses = chapter.verses
        guard !verses.isEmpty else { return [] }

        // Calculate available height (leave room for page indicator)
        let pageIndicatorHeight: CGFloat = 40
        let verticalPadding: CGFloat = AppTheme.Spacing.xl * 2
        let availableHeight = availableSize.height - pageIndicatorHeight - verticalPadding

        // Calculate available width
        let availableWidth = availableSize.width - contentPadding

        // Estimate line height based on font size (rawValue is the point size)
        let baseLineHeight = fontSize.rawValue * 1.4 + lineSpacing
        let verseNumberHeight: CGFloat = 0 // Verse number is inline

        // Calculate pages
        var pages: [Page] = []
        var currentPageVerses: [Verse] = []
        var currentPageHeight: CGFloat = 0
        var pageIndex = 0

        for verse in verses {
            // Estimate height for this verse
            let verseHeight = estimateVerseHeight(
                verse: verse,
                availableWidth: availableWidth,
                fontSize: fontSize,
                lineHeight: baseLineHeight
            ) + verseNumberHeight + AppTheme.Spacing.sm // Spacing between verses

            // Check if verse fits on current page
            if currentPageHeight + verseHeight > availableHeight && !currentPageVerses.isEmpty {
                // Create page with current verses
                pages.append(Page(id: pageIndex, verses: currentPageVerses))
                pageIndex += 1
                currentPageVerses = []
                currentPageHeight = 0
            }

            // Add verse to current page
            currentPageVerses.append(verse)
            currentPageHeight += verseHeight
        }

        // Add remaining verses as final page
        if !currentPageVerses.isEmpty {
            pages.append(Page(id: pageIndex, verses: currentPageVerses))
        }

        return pages
    }

    /// Estimate the height required to render a verse
    private static func estimateVerseHeight(
        verse: Verse,
        availableWidth: CGFloat,
        fontSize: ScriptureFontSize,
        lineHeight: CGFloat
    ) -> CGFloat {
        // Estimate characters per line based on font size
        // Average character width is roughly 0.5 * font size for typical fonts
        let avgCharWidth = fontSize.rawValue * 0.5
        let charsPerLine = max(1, Int(availableWidth / avgCharWidth))

        // Include verse number prefix in text length (e.g., "1 ")
        let verseNumberPrefix = "\(verse.verse) "
        let totalLength = verseNumberPrefix.count + verse.text.count

        // Calculate number of lines
        let numberOfLines = max(1, Int(ceil(Double(totalLength) / Double(charsPerLine))))

        return CGFloat(numberOfLines) * lineHeight
    }

    /// Find the page index that contains a specific verse
    static func pageIndex(for verseNumber: Int, in pages: [Page]) -> Int? {
        pages.firstIndex { page in
            verseNumber >= page.startVerse && verseNumber <= page.endVerse
        }
    }
}
