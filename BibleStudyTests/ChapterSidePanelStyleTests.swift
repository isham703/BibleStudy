import SwiftUI
import XCTest
@testable import BibleStudy

final class ChapterSidePanelStyleTests: XCTestCase {
    func testSelectedFillUsesSelectionBackgroundInBothModes() {
        XCTAssertEqual(ChapterSidePanel.selectedChapterFillName(for: .light), "SelectionBackground")
        XCTAssertEqual(ChapterSidePanel.selectedChapterFillName(for: .dark), "SelectionBackground")
    }

    func testSelectedTextUsesPrimaryInBothModes() {
        XCTAssertEqual(ChapterSidePanel.selectedChapterTextName(for: .light), "AppTextPrimary")
        XCTAssertEqual(ChapterSidePanel.selectedChapterTextName(for: .dark), "AppTextPrimary")
    }

    func testUnselectedTextUsesSecondaryInBothModes() {
        XCTAssertEqual(ChapterSidePanel.unselectedChapterTextName(for: .light), "AppTextSecondary")
        XCTAssertEqual(ChapterSidePanel.unselectedChapterTextName(for: .dark), "AppTextSecondary")
    }
}
