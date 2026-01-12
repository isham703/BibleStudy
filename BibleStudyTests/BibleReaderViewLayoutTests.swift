import XCTest
@testable import BibleStudy

final class BibleReaderViewLayoutTests: XCTestCase {
    func testEditorialDividerShowsWhenContentVisibleAndPanelClosed() {
        let result = BibleReaderView.Layout.shouldShowEditorialDivider(
            isContentVisible: true,
            isChapterPanelPresented: false
        )

        XCTAssertTrue(result)
    }

    func testEditorialDividerHidesWhenPanelPresented() {
        let result = BibleReaderView.Layout.shouldShowEditorialDivider(
            isContentVisible: true,
            isChapterPanelPresented: true
        )

        XCTAssertFalse(result)
    }

    func testEditorialDividerHidesWhenContentNotVisible() {
        let result = BibleReaderView.Layout.shouldShowEditorialDivider(
            isContentVisible: false,
            isChapterPanelPresented: false
        )

        XCTAssertFalse(result)
    }
}
