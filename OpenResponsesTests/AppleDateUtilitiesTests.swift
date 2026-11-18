import XCTest
#if canImport(EventKit)
import EventKit
#endif
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
        XCTAssertNil(AppleDateUtilities.parseQueryDate("2024/05/10 12:00"))
        XCTAssertNil(AppleDateUtilities.parseQueryDate("2024-13-10T12:00:00"))
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

    func testParseISO8601_WithNilOrEmptyString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601(nil))
        XCTAssertNil(AppleDateUtilities.parseISO8601(""))
        XCTAssertNil(AppleDateUtilities.parseISO8601("   "))
        XCTAssertNil(AppleDateUtilities.parseISO8601("\n\t "))
    }

    func testParseISO8601_WithValidString_NoFractionalSeconds() {
        let validString = "2023-10-25T14:30:00Z"
        let parsedDate = AppleDateUtilities.parseISO8601(validString)
        XCTAssertNotNil(parsedDate)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate!)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 25)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)
    }

    func testParseISO8601_WithValidString_WithFractionalSeconds() {
        let validString = "2023-10-25T14:30:00.123Z"
        let parsedDate = AppleDateUtilities.parseISO8601(validString)
        XCTAssertNotNil(parsedDate)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: parsedDate!)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 25)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)

        // 123 milliseconds is 123_000_000 nanoseconds
        if let nanosecond = components.nanosecond {
            let diff = abs(nanosecond - 123_000_000)
            XCTAssertLessThan(diff, 1_000_000, "Nanoseconds should be approximately 123,000,000")
        } else {
            XCTFail("Nanoseconds should not be nil")
        }
    }

    func testParseISO8601_WithInvalidString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601("invalid-date"))
        XCTAssertNil(AppleDateUtilities.parseISO8601("2023/10/25 14:30:00"))
        XCTAssertNil(AppleDateUtilities.parseISO8601("2023-10-25")) // Missing time part
    }

    // MARK: - Dates the model writes without an offset (2026-10-21: 2.9 rejected "2026-11-04T18:30:00", so every
    // Calendar and Reminders call from a photographed schedule failed)

    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private func parts(_ date: Date?, in zone: TimeZone) -> DateComponents? {
        guard let date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
    }

    private func assertLocal(_ value: String, _ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ s: Int,
                             file: StaticString = #filePath, line: UInt = #line) {
        let c = parts(AppleDateUtilities.parseToolDate(value, timeZone: losAngeles), in: losAngeles)
        XCTAssertNotNil(c, "\(value) did not parse", file: file, line: line)
        XCTAssertEqual([c?.year, c?.month, c?.day, c?.hour, c?.minute, c?.second], [y, mo, d, h, mi, s], value, file: file, line: line)
    }

    func testParseToolDate_LocalDateTimeIsReadInTheGivenTimeZone() {
        assertLocal("2026-11-04T18:30:00", 2026, 11, 4, 18, 30, 0)
        assertLocal("2026-11-04T18:30", 2026, 11, 4, 18, 30, 0)
        assertLocal("2026-11-04 18:30:00", 2026, 11, 4, 18, 30, 0)
        assertLocal("2026-11-04 18:30", 2026, 11, 4, 18, 30, 0)
        assertLocal("  2026-11-04T18:30:00 \n", 2026, 11, 4, 18, 30, 0)
        // November is standard time in Los Angeles (-08:00): 18:30 there is 02:30 UTC the next day.
        let utc = parts(AppleDateUtilities.parseToolDate("2026-11-04T18:30:00", timeZone: losAngeles), in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual([utc?.day, utc?.hour, utc?.minute], [5, 2, 30])
        // July is daylight time (-07:00): 09:00 there is 16:00 UTC.
        let summer = parts(AppleDateUtilities.parseToolDate("2026-07-04T09:00:00", timeZone: losAngeles), in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(summer?.hour, 16)
    }

    func testParseToolDate_LocalFractionalSeconds() {
        let c = parts(AppleDateUtilities.parseToolDate("2026-11-04T18:30:00.123", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([c?.hour, c?.minute, c?.second], [18, 30, 0])
        XCTAssertLessThan(abs((c?.nanosecond ?? 0) - 123_000_000), 1_000_000)
        let micro = parts(AppleDateUtilities.parseToolDate("2026-11-04T18:30:00.123456", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([micro?.hour, micro?.minute, micro?.second], [18, 30, 0])
    }

    func testParseToolDate_OffsetAndZuluMeanExactlyThatInstant() {
        let expected = AppleDateUtilities.parseISO8601("2026-11-05T02:30:00Z")
        XCTAssertNotNil(expected)
        XCTAssertEqual(AppleDateUtilities.parseToolDate("2026-11-04T18:30:00-08:00", timeZone: losAngeles), expected)
        XCTAssertEqual(AppleDateUtilities.parseToolDate("2026-11-05T02:30:00Z", timeZone: losAngeles), expected)
        // An offset wins over the device's zone: the same text gives the same instant whatever the zone.
        XCTAssertEqual(AppleDateUtilities.parseToolDate("2026-11-05T02:30:00Z", timeZone: TimeZone(identifier: "Asia/Tokyo")!), expected)
        let fractional = parts(AppleDateUtilities.parseToolDate("2026-11-04T18:30:00.123Z", timeZone: losAngeles), in: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual([fractional?.hour, fractional?.minute], [18, 30])
        XCTAssertLessThan(abs((fractional?.nanosecond ?? 0) - 123_000_000), 1_000_000)
    }

    func testParseToolDate_BareDateIsMidnightInTheGivenTimeZone() {
        assertLocal("2026-11-04", 2026, 11, 4, 0, 0, 0)
        XCTAssertTrue(AppleDateUtilities.isDateOnly("2026-11-04"))
        XCTAssertTrue(AppleDateUtilities.isDateOnly(" 2026-11-04 "))
        XCTAssertFalse(AppleDateUtilities.isDateOnly("2026-11-04T18:30:00"))
        XCTAssertFalse(AppleDateUtilities.isDateOnly(nil))
    }

    func testParseToolDate_RejectsWhatIsNotADate() {
        for value in ["", "   ", "tomorrow", "Nov 4 2026", "2026/11/04 18:30", "2026-13-04T18:30:00", "2026-11-31T10:00:00",
                      "2026-11-04T25:00:00", "2026-11-04T18:30:00.", "2026-11-04T18:30:00 PM"] {
            XCTAssertNil(AppleDateUtilities.parseToolDate(value, timeZone: losAngeles), value)
        }
        XCTAssertNil(AppleDateUtilities.parseToolDate(nil))
    }

    func testParseISO8601_StaysStrictForTheFileConverter() {
        // FileConverterService counts values that parse here to call a column "Date/Time"; that test is unchanged.
        XCTAssertNil(AppleDateUtilities.parseISO8601("2026-11-04T18:30:00"))
        XCTAssertNil(AppleDateUtilities.parseISO8601("2026-11-04"))
    }

    func testParseQueryDate_LocalValuesAndBareEndDates() {
        let noon = parts(AppleDateUtilities.parseQueryDate("2024-05-10T12:00:00", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([noon?.day, noon?.hour, noon?.minute], [10, 12, 0])
        let start = parts(AppleDateUtilities.parseQueryDate("2024-05-10", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([start?.day, start?.hour, start?.minute, start?.second], [10, 0, 0, 0])
        // As the end of a range, a bare date means the whole of that day.
        let end = parts(AppleDateUtilities.parseQueryDate("2024-05-10", timeZone: losAngeles, endOfDay: true), in: losAngeles)
        XCTAssertEqual([end?.day, end?.hour, end?.minute, end?.second], [10, 23, 59, 59])
        // A time of day is kept as written even as an end.
        let endNoon = parts(AppleDateUtilities.parseQueryDate("2024-05-10T12:00:00", timeZone: losAngeles, endOfDay: true), in: losAngeles)
        XCTAssertEqual([endNoon?.day, endNoon?.hour], [10, 12])
    }

    func testReminderComponentsWithoutATimeHaveNoClockTime() throws {
        let date = try XCTUnwrap(AppleDateUtilities.parseToolDate("2026-11-04", timeZone: losAngeles))
        let dayOnly = AppleDateUtilities.makeReminderDateComponents(from: date, timeZone: losAngeles, includeTime: false)
        XCTAssertEqual([dayOnly.year, dayOnly.month, dayOnly.day], [2026, 11, 4])
        XCTAssertFalse(AppleDateUtilities.hasClockTime(dayOnly))
        XCTAssertNil(dayOnly.timeZone)
        let timed = AppleDateUtilities.makeReminderDateComponents(from: date, timeZone: losAngeles)
        XCTAssertTrue(AppleDateUtilities.hasClockTime(timed))
        XCTAssertEqual(timed.timeZone, losAngeles)
    }

    // MARK: - What the tools call (AppleProvider.createEvent, createReminder; the Calendar and Reminders queries)

    func testEventInterval_AcceptsLocalTimesAndRefusesABareDate() throws {
        let interval = try AppleDateUtilities.eventInterval(startISO8601: "2026-11-04T18:30:00", endISO8601: "2026-11-04T19:30",
                                                            timeZone: losAngeles)
        XCTAssertEqual([parts(interval.start, in: losAngeles)?.hour, parts(interval.end, in: losAngeles)?.hour], [18, 19])
        XCTAssertThrowsError(try AppleDateUtilities.eventInterval(startISO8601: "2026-11-04", endISO8601: "2026-11-04", timeZone: losAngeles)) { error in
            guard case .dateNeedsTime(let value)? = error as? AppleDataAccessError, value == "2026-11-04" else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try AppleDateUtilities.eventInterval(startISO8601: "2026-11-04T18:30:00", endISO8601: "soon", timeZone: losAngeles)) { error in
            guard case .invalidDate(let value)? = error as? AppleDataAccessError, value == "soon" else { return XCTFail("\(error)") }
        }
        let zulu = try AppleDateUtilities.eventInterval(startISO8601: "2026-11-05T02:30:00Z", endISO8601: "2026-11-05T03:30:00Z", timeZone: losAngeles)
        XCTAssertEqual(zulu.start, AppleDateUtilities.parseISO8601("2026-11-05T02:30:00Z"))
    }

    func testReminderDue_ABareDateHasNoTime() throws {
        let day = try XCTUnwrap(try AppleDateUtilities.reminderDue("2026-11-03", timeZone: losAngeles))
        XCTAssertFalse(day.hasTime)
        XCTAssertEqual(parts(day.date, in: losAngeles)?.day, 3)
        let evening = try XCTUnwrap(try AppleDateUtilities.reminderDue("2026-11-03T19:00:00", timeZone: losAngeles))
        XCTAssertTrue(evening.hasTime)
        XCTAssertEqual(parts(evening.date, in: losAngeles)?.hour, 19)
        XCTAssertNil(try AppleDateUtilities.reminderDue(nil))
        XCTAssertThrowsError(try AppleDateUtilities.reminderDue("next Tuesday"))
    }

    func testQueryRange_ABareEndCoversTheDay() throws {
        let range = try AppleDateUtilities.queryRange(startISO8601: "2026-11-04", endISO8601: "2026-11-04", timeZone: losAngeles)
        XCTAssertEqual([parts(range.start, in: losAngeles)?.hour, parts(range.end, in: losAngeles)?.hour, parts(range.end, in: losAngeles)?.second], [0, 23, 59])
        let open = try AppleDateUtilities.queryRange(startISO8601: nil, endISO8601: nil, timeZone: losAngeles)
        XCTAssertNil(open.start); XCTAssertNil(open.end)
        XCTAssertThrowsError(try AppleDateUtilities.queryRange(startISO8601: "2026-11-04", endISO8601: "whenever", timeZone: losAngeles))
    }

    // MARK: - Edges the review found

    func testDaylightSavingGapsAndRepeats() throws {
        // Santiago skips midnight when daylight time starts (2026-09-06): a bare date is the day's real start, not nil.
        let santiago = try XCTUnwrap(TimeZone(identifier: "America/Santiago"))
        let start = try XCTUnwrap(AppleDateUtilities.parseToolDate("2026-09-06", timeZone: santiago))
        XCTAssertEqual([parts(start, in: santiago)?.day, parts(start, in: santiago)?.hour], [6, 1])
        let end = try XCTUnwrap(AppleDateUtilities.parseQueryDate("2026-09-06", timeZone: santiago, endOfDay: true))
        XCTAssertEqual([parts(end, in: santiago)?.day, parts(end, in: santiago)?.hour], [6, 23])
        // 02:30 doesn't exist in Los Angeles on 2026-03-08; it moves forward by the hour skipped, to 03:30.
        let skipped = parts(AppleDateUtilities.parseToolDate("2026-03-08T02:30:00", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([skipped?.day, skipped?.hour, skipped?.minute], [8, 3, 30])
        // 01:30 happens twice on 2026-11-01; either one is a valid reading.
        let repeated = parts(AppleDateUtilities.parseToolDate("2026-11-01T01:30:00", timeZone: losAngeles), in: losAngeles)
        XCTAssertEqual([repeated?.hour, repeated?.minute], [1, 30])
    }

    func testOffsetWithoutSecondsAndOtherDigitsAndFractions() {
        XCTAssertEqual(AppleDateUtilities.parseToolDate("2026-11-04T18:30-08:00", timeZone: TimeZone(identifier: "Asia/Tokyo")!),
                       AppleDateUtilities.parseISO8601("2026-11-05T02:30:00Z"))
        XCTAssertEqual(AppleDateUtilities.parseToolDate("2026-11-05T02:30Z", timeZone: losAngeles),
                       AppleDateUtilities.parseISO8601("2026-11-05T02:30:00Z"))
        for value in ["２０２６-１１-０４", "2026-11-04T18:30:00.½", "2026-11-04T18:30.5", "2026-11-04T18:30:00+25:00", "2026-11-04T18:30:00,5"] {
            XCTAssertNil(AppleDateUtilities.parseToolDate(value, timeZone: losAngeles), value)
        }
        XCTAssertFalse(AppleDateUtilities.isDateOnly("２０２６-１１-０４"))
    }

    func testQueryBoundariesMeanTheSameWithOrWithoutSeconds() {
        // A UTC midnight or 23:59:59 in a query means the local day's boundary, however it is spelled.
        let withSeconds = AppleDateUtilities.parseQueryDate("2026-11-04T00:00:00Z", timeZone: losAngeles)
        XCTAssertNotNil(withSeconds)
        XCTAssertEqual(AppleDateUtilities.parseQueryDate("2026-11-04T00:00Z", timeZone: losAngeles), withSeconds)
        XCTAssertEqual(AppleDateUtilities.parseQueryDate("2026-11-04 00:00:00Z", timeZone: losAngeles), withSeconds)
        XCTAssertEqual(parts(withSeconds, in: losAngeles)?.hour, 0)
    }

    /// EventKit round trip for a due day with no time.  It needs Reminders access, which a CI simulator doesn't grant, so
    /// it skips there; locally `xcrun simctl privacy <udid> grant reminders Gunndamental.OpenResponses` before the run.
    @MainActor
    func testDayOnlyReminderSavesWithNoTime() async throws {
        #if canImport(EventKit)
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            throw XCTSkip("Reminders access isn't granted to the test host")
        }
        let provider = AppleProvider()
        let detail = try await provider.createReminder(title: "OpenResponses test: day-only reminder", notes: nil,
                                                       dueDateISO8601: "2026-11-03", priority: nil, listIdentifier: nil)
        defer {
            let store = EventKitPermissionManager.shared.store
            if let saved = store.calendarItem(withIdentifier: detail.identifier) as? EKReminder { try? store.remove(saved, commit: true) }
        }
        XCTAssertFalse(detail.hasDueTime)
        let saved = try XCTUnwrap(EventKitPermissionManager.shared.store.calendarItem(withIdentifier: detail.identifier) as? EKReminder)
        XCTAssertEqual([saved.dueDateComponents?.year, saved.dueDateComponents?.month, saved.dueDateComponents?.day], [2026, 11, 3])
        XCTAssertNil(saved.dueDateComponents?.hour)
        XCTAssertFalse(AppleDateUtilities.hasClockTime(saved.dueDateComponents))
        #else
        throw XCTSkip("EventKit is not available")
        #endif
    }
}
