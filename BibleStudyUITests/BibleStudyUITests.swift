import XCTest

final class BibleStudyUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_testing_reader"]
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
    }
}
