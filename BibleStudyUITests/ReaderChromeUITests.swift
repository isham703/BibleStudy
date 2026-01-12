import XCTest

final class ReaderChromeUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["-ui_testing_reader"]
        app.launch()
    }

    func testReaderToolbarButtonsUseSingleCircleSizing() {
        let backButton = app.buttons["ReaderToolbarBackButton"]
        let menuButton = app.buttons["ReaderToolbarReadingMenuButton"]
        let chapterButton = app.buttons["ReaderToolbarChapterButton"]

        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        XCTAssertTrue(chapterButton.waitForExistence(timeout: 5))

        let expectedSize: CGFloat = 44
        XCTAssertEqual(backButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(backButton.frame.size.height, expectedSize, accuracy: 1)
        XCTAssertEqual(menuButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(menuButton.frame.size.height, expectedSize, accuracy: 1)
        XCTAssertEqual(chapterButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(chapterButton.frame.size.height, expectedSize, accuracy: 1)
    }

    func testChapterPanelHeaderDividerIsHidden() {
        let chapterTitle = app.staticTexts["Genesis"]
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: 5))

        let chapterButton = app.buttons["ReaderToolbarChapterButton"]
        XCTAssertTrue(chapterButton.waitForExistence(timeout: 5))

        let panel = app.descendants(matching: .any)["ReaderChapterPanel"]
        if !panel.waitForExistence(timeout: 1) {
            chapterButton.tap()
        }
        XCTAssertTrue(panel.waitForExistence(timeout: 5))

        let divider = app.descendants(matching: .any)["ReaderChapterPanelHeaderDivider"]
        XCTAssertFalse(divider.exists)
    }
}
