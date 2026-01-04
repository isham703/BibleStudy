import XCTest
@testable import BibleStudy

final class ScholarInsightSummaryTests: XCTestCase {
    func testSummaryReturnsFirstTwoSentences() {
        let text = "First sentence. Second sentence. Third sentence."
        let summary = ScholarInsightSummary.heroSummary(from: text)
        XCTAssertEqual(summary, "First sentence. Second sentence.")
    }
}
