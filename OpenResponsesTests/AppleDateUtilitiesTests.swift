import XCTest
@testable import OpenResponses

final class AppleDateUtilitiesTests: XCTestCase {

    func testParseQueryDate_WithNilOrEmpty_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseQueryDate(nil))
        XCTAssertNil(AppleDateUtilities.parseQueryDate(""))
        XCTAssertNil(AppleDateUtilities.parseQueryDate("   "))
        XCTAssertNil(AppleDateUtilities.parseQueryDate("\n"))
    }

    func testParseQueryDate_WithInvalidString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseQueryDate("invalid-date"))
        XCTAssertNil(AppleDateUtilities.parseQueryDate("2024-05-10")) // Missing time part
        XCTAssertNil(AppleDateUtilities.parseQueryDate("2024-05-10T12:00:00")) // Missing timezone
    }

    func testParseQueryDate_WithNonBoundaryDate_ParsesNormally() {
        // A date that is not 00:00:00 or 23:59:59
        let dateStr = "2024-05-10T15:30:00Z"
        let jstTimeZone = TimeZone(identifier: "Asia/Tokyo")!

        let parsedDate = AppleDateUtilities.parseQueryDate(dateStr, timeZone: jstTimeZone)
        XCTAssertNotNil(parsedDate)

        // Non-boundary dates should simply be parsed exactly as provided in UTC, ignoring the target timeZone for shifting.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate!)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)
    }

    func testParseQueryDate_WithStartOfDayBoundary_ShiftsToProvidedTimeZone() {
        // 00:00:00 in UTC is a start-of-day boundary
        let dateStr = "2024-05-10T00:00:00Z"
        let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")! // UTC-7 or UTC-8

        let parsedDate = AppleDateUtilities.parseQueryDate(dateStr, timeZone: pstTimeZone)
        XCTAssertNotNil(parsedDate)

        // The resulting date should be exactly 00:00:00 *in the PST timezone*, not UTC.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pstTimeZone
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate!)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)

        // Double check UTC time to ensure it shifted. (00:00 in LA -> 07:00 or 08:00 in UTC depending on DST)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let utcComponents = utcCalendar.dateComponents([.hour], from: parsedDate!)
        XCTAssertTrue(utcComponents.hour == 7 || utcComponents.hour == 8)
    }

    func testParseQueryDate_WithEndOfDayBoundary_ShiftsToProvidedTimeZone() {
        // 23:59:59 in UTC is an end-of-day boundary
        let dateStr = "2024-05-10T23:59:59.999Z"
        let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!

        let parsedDate = AppleDateUtilities.parseQueryDate(dateStr, timeZone: pstTimeZone)
        XCTAssertNotNil(parsedDate)

        // The resulting date should be exactly 23:59:59 *in the PST timezone*
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pstTimeZone
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate!)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }
}
