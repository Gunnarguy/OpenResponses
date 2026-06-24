import XCTest
@testable import OpenResponses

final class AppleDataModelsTests: XCTestCase {

    func testHasClockTime() {
        // 1. Test nil components
        XCTAssertFalse(AppleDateUtilities.hasClockTime(nil), "hasClockTime should return false for nil components")

        // 2. Test components without clock time
        var dateOnlyComponents = DateComponents()
        dateOnlyComponents.year = 2024
        dateOnlyComponents.month = 5
        dateOnlyComponents.day = 10
        XCTAssertFalse(AppleDateUtilities.hasClockTime(dateOnlyComponents), "hasClockTime should return false for components without hour, minute, or second")

        // 3. Test components with only hour
        var hourComponents = DateComponents()
        hourComponents.hour = 14
        XCTAssertTrue(AppleDateUtilities.hasClockTime(hourComponents), "hasClockTime should return true for components with hour")

        // 4. Test components with only minute
        var minuteComponents = DateComponents()
        minuteComponents.minute = 30
        XCTAssertTrue(AppleDateUtilities.hasClockTime(minuteComponents), "hasClockTime should return true for components with minute")

        // 5. Test components with only second
        var secondComponents = DateComponents()
        secondComponents.second = 45
        XCTAssertTrue(AppleDateUtilities.hasClockTime(secondComponents), "hasClockTime should return true for components with second")

        // 6. Test components with full clock time
        var fullTimeComponents = DateComponents()
        fullTimeComponents.year = 2024
        fullTimeComponents.month = 5
        fullTimeComponents.day = 10
        fullTimeComponents.hour = 14
        fullTimeComponents.minute = 30
        fullTimeComponents.second = 45
        XCTAssertTrue(AppleDateUtilities.hasClockTime(fullTimeComponents), "hasClockTime should return true for components with full clock time")
    }
}
