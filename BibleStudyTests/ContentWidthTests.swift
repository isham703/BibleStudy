import XCTest
@testable import BibleStudy

final class ContentWidthTests: XCTestCase {
    func testResolvedWidthCapsAtMaxWidthWhenAvailableIsLarger() {
        let resolved = ContentWidth.wide.resolvedWidth(for: 900)
        XCTAssertEqual(resolved, 600)
    }

    func testResolvedWidthClampsToAvailableWidthWhenScreenIsSmaller() {
        let resolved = ContentWidth.compact.resolvedWidth(for: 360)
        XCTAssertEqual(resolved, 360)
    }

    func testResolvedWidthUsesAvailableWidthForFull() {
        let resolved = ContentWidth.full.resolvedWidth(for: 820)
        XCTAssertEqual(resolved, 820)
    }
}
