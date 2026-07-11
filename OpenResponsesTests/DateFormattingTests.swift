import XCTest
@testable import OpenResponses

final class DateFormattingTests: XCTestCase {
    
    func testParseISO8601Valid() {
        let isoStr = "2026-07-10T15:30:45.123Z"
        let date = AppleDateUtilities.parseISO8601(isoStr)
        XCTAssertNotNil(date)
        
        let formatted = AppleDateUtilities.formatISO8601(date!)
        XCTAssertEqual(formatted, isoStr)
    }
    
    func testParseISO8601Invalid() {
        let invalidStr = "not-a-date"
        let date = AppleDateUtilities.parseISO8601(invalidStr)
        XCTAssertNil(date)
    }
}
