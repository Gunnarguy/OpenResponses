import XCTest
@testable import OpenResponses

final class AppleDateUtilitiesTests: XCTestCase {

    func testParseISO8601_WithNil_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601(nil))
    }

    func testParseISO8601_WithEmptyString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601(""))
    }

    func testParseISO8601_WithWhitespaceString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601("   "))
        XCTAssertNil(AppleDateUtilities.parseISO8601("\t\n"))
    }

    func testParseISO8601_WithValidDate_ReturnsDate() {
        let date = AppleDateUtilities.parseISO8601("2023-10-25T14:30:00Z")
        XCTAssertNotNil(date)
    }

}
