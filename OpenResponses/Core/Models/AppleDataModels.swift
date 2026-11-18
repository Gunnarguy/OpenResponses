import Foundation

/// Errors thrown when interacting with Apple system data such as Calendar, Reminders, or Notes.
public enum AppleDataAccessError: LocalizedError {
    case frameworkUnavailable
    case accessDenied(entity: String)
    case accessRestricted(entity: String)
    case writeOnlyAccess(entity: String)
    case invalidDate(String)
    case dateNeedsTime(String)
    case invalidDateRange
    case invalidCalendar
    case calendarNotWritable
    case missingConfiguration(String)
    case operationUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "System frameworks required for this feature are not available on this device."
        case .accessDenied(let entity):
            return "Access to your \(entity) is denied. Enable permissions in Settings and try again."
        case .accessRestricted(let entity):
            return "Access to your \(entity) is restricted on this device."
        case .writeOnlyAccess(let entity):
            return "Only write access is available for \(entity). Reading existing data is not permitted."
        case .invalidDate(let value):
            return "The provided date is not a valid ISO 8601 timestamp: \(value)"
        case .dateNeedsTime(let value):
            return "Calendar events need a time of day, and \(value) is a date only. Give a start and end time, for example 2026-11-04T18:30:00."
        case .invalidDateRange:
            return "The requested date range is invalid. Ensure the start date is on or before the end date."
        case .invalidCalendar:
            return "The specified calendar could not be found or is not available."
        case .calendarNotWritable:
            return "The selected calendar does not allow modifications."
        case .missingConfiguration(let detail):
            return "Missing configuration: \(detail). Update your settings and retry."
        case .operationUnavailable(let reason):
            return reason
        }
    }
}

enum AppleDateUtilities {
    private static let dayBoundaryRegex = try? NSRegularExpression(
        // Seconds and a T are optional, as parseLocalDate allows, so "2026-11-04T00:00Z" is the same boundary as "T00:00:00Z".
        pattern: #"^([0-9]{4})-([0-9]{2})-([0-9]{2})[T ]([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.[0-9]+)?)?(Z|[+-][0-9]{2}:[0-9]{2})$"#
    )

    nonisolated static func formatISO8601(_ date: Date) -> String {
        return date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    static func makeGregorianCalendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func parseISO8601(_ rawValue: String?) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        let fractionalStrategy = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = try? Date(rawValue, strategy: fractionalStrategy) {
            return date
        }

        let standardStrategy = Date.ISO8601FormatStyle(includingFractionalSeconds: false)
        if let date = try? Date(rawValue, strategy: standardStrategy) {
            return date
        }

        return nil
    }

    /// A date the model passes to the Calendar or Reminders tools.  The schemas ask for the device's offset, but models
    /// often leave it out ("2026-11-04T18:30:00"), which ISO 8601 allows; 2.9 rejected every such call (2026-10-21, a
    /// photographed schedule: all twelve Calendar and Reminders calls failed).  A value with an offset or Z means exactly
    /// that instant; a local date-time or a bare date is read in `timeZone`, the device's own by default.
    /// `parseISO8601` stays strict: the file converter uses it to recognise date columns.
    static func parseToolDate(_ rawValue: String?, timeZone: TimeZone = .current) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }
        return parseISO8601(rawValue) ?? parseLocalDate(rawValue, timeZone: timeZone)
    }

    /// Whether a value is a bare calendar date ("2026-11-04"), with no time of day.
    static func isDateOnly(_ rawValue: String?) -> Bool {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return value.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"#, options: .regularExpression) != nil
    }

    /// ASCII digits only: ICU's `\d` also matches other scripts' digits ("２０２６").
    private static let localDateRegex = try? NSRegularExpression(
        pattern: #"^([0-9]{4})-([0-9]{2})-([0-9]{2})(?:[T ]([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]{1,9}))?)?(Z|[+-][0-9]{2}:[0-9]{2})?)?$"#
    )

    /// What `parseISO8601` refuses but means one moment: no offset (read in `timeZone`), no seconds, a space for the T,
    /// or a bare date (the start of that day).  Each field is checked, so an impossible date or time (November 31, 25:00)
    /// is refused.  The moment comes from Calendar, so a local time that a daylight-saving change skips moves forward by
    /// the gap, and a midnight that is skipped (Santiago, Havana, Cairo) becomes the day's real start.
    private static func parseLocalDate(_ value: String, timeZone: TimeZone) -> Date? {
        guard let regex = localDateRegex,
              let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value))
        else { return nil }
        func field(_ index: Int) -> Substring? { Range(match.range(at: index), in: value).map { value[$0] } }
        func number(_ index: Int) -> Int? { field(index).flatMap { Int($0) } }
        guard let year = number(1), let month = number(2), let day = number(3), (1...12).contains(month) else { return nil }

        var zone = timeZone
        if let designator = field(8) {
            if designator == "Z" {
                zone = TimeZone(secondsFromGMT: 0) ?? timeZone
            } else {
                let sign = designator.hasPrefix("-") ? -1 : 1
                guard let hours = Int(designator.dropFirst().prefix(2)), let minutes = Int(designator.suffix(2)),
                      hours <= 23, minutes <= 59, let offset = TimeZone(secondsFromGMT: sign * (hours * 3600 + minutes * 60))
                else { return nil }
                zone = offset
            }
        }

        let calendar = makeGregorianCalendar(timeZone: zone)
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth), daysInMonth.contains(day)
        else { return nil }
        let hour = number(4) ?? 0, minute = number(5) ?? 0, second = number(6) ?? 0
        guard hour <= 23, minute <= 59, second <= 59 else { return nil }
        let nanosecond = field(7).flatMap { Int(String($0).padding(toLength: 9, withPad: "0", startingAt: 0)) } ?? 0
        if field(4) == nil {
            // A bare date: the start of that day, which is not midnight where a daylight-saving change skips midnight.
            guard let noon = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else { return nil }
            return calendar.startOfDay(for: noon)
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day,
                                                  hour: hour, minute: minute, second: second, nanosecond: nanosecond))
    }

    /// An event's start and end from the Calendar tool.  A bare date is refused with a message asking for times: the app
    /// makes timed events only, and a bare start and end would make an event of no length at midnight.
    static func eventInterval(startISO8601: String, endISO8601: String, timeZone: TimeZone = .current) throws -> (start: Date, end: Date) {
        for value in [startISO8601, endISO8601] where isDateOnly(value) {
            throw AppleDataAccessError.dateNeedsTime(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let start = parseToolDate(startISO8601, timeZone: timeZone) else { throw AppleDataAccessError.invalidDate(startISO8601) }
        guard let end = parseToolDate(endISO8601, timeZone: timeZone) else { throw AppleDataAccessError.invalidDate(endISO8601) }
        return (start, end)
    }

    /// A reminder's due date from the Reminders tool, and whether it has a time of day: a bare date is a due day only.
    static func reminderDue(_ rawValue: String?, timeZone: TimeZone = .current) throws -> (date: Date, hasTime: Bool)? {
        guard let rawValue else { return nil }
        guard let date = parseToolDate(rawValue, timeZone: timeZone) else { throw AppleDataAccessError.invalidDate(rawValue) }
        return (date, !isDateOnly(rawValue))
    }

    /// The range of a Calendar or Reminders query.  A bare end date covers that whole day ("through November 4").
    static func queryRange(startISO8601: String?, endISO8601: String?, timeZone: TimeZone = .current) throws -> (start: Date?, end: Date?) {
        func parse(_ value: String?, endOfDay: Bool) throws -> Date? {
            guard let value else { return nil }
            guard let date = parseQueryDate(value, timeZone: timeZone, endOfDay: endOfDay) else { throw AppleDataAccessError.invalidDate(value) }
            return date
        }
        return (try parse(startISO8601, endOfDay: false), try parse(endISO8601, endOfDay: true))
    }

    /// `endOfDay`: a bare date stands for the last second of that day, as the end of a range ("through November 4").
    static func parseQueryDate(_ rawValue: String?, timeZone: TimeZone = .current, endOfDay: Bool = false) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        // What the strict parser refuses (no offset, no seconds, a bare date) is read as parseToolDate reads it (2026-10-21).
        guard let parsed = parseISO8601(rawValue) ?? parseLocalDate(rawValue, timeZone: timeZone) else { return nil }
        if endOfDay, isDateOnly(rawValue) {
            let calendar = makeGregorianCalendar(timeZone: timeZone)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: parsed) else { return parsed }
            return calendar.startOfDay(for: nextDay).addingTimeInterval(-1)
        }

        guard let components = utcDayBoundaryComponents(from: rawValue) else {
            return parsed
        }

        var localComponents = components
        localComponents.calendar = makeGregorianCalendar(timeZone: timeZone)
        localComponents.timeZone = timeZone
        return localComponents.calendar?.date(from: localComponents) ?? parsed
    }

    static func hasClockTime(_ components: DateComponents?) -> Bool {
        guard let components else { return false }
        return components.hour != nil || components.minute != nil || components.second != nil
    }

    /// `includeTime: false` leaves the hour, minute and second out (and the time zone, so the day floats): a due day with no time.
    static func makeReminderDateComponents(from date: Date, timeZone: TimeZone = .current, includeTime: Bool = true) -> DateComponents {
        let calendar = makeGregorianCalendar(timeZone: timeZone)
        var components = calendar.dateComponents(includeTime ? [.year, .month, .day, .hour, .minute, .second] : [.year, .month, .day], from: date)
        components.calendar = calendar
        components.timeZone = includeTime ? timeZone : nil   // a due day with no time is the same day wherever you are
        return components
    }

    private static func utcDayBoundaryComponents(from rawValue: String) -> DateComponents? {
        guard let dayBoundaryRegex else { return nil }

        let range = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        guard let match = dayBoundaryRegex.firstMatch(in: rawValue, options: [], range: range),
              match.numberOfRanges == 8
        else {
            return nil
        }

        func capture(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: rawValue) else { return nil }
            return String(rawValue[range])
        }

        guard
            let yearString = capture(1),
            let monthString = capture(2),
            let dayString = capture(3),
            let hourString = capture(4),
            let minuteString = capture(5),
            let timeZoneDesignator = capture(7),
            let year = Int(yearString),
            let month = Int(monthString),
            let day = Int(dayString),
            let hour = Int(hourString),
            let minute = Int(minuteString),
            let second = Int(capture(6) ?? "0")
        else {
            return nil
        }

        let isUTC = timeZoneDesignator == "Z" || timeZoneDesignator == "+00:00" || timeZoneDesignator == "-00:00"
        let isStartOfDay = hour == 0 && minute == 0 && second == 0
        let isEndOfDay = hour == 23 && minute == 59 && second == 59
        guard isUTC, isStartOfDay || isEndOfDay else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return components
    }
}

/// Lightweight value describing an event pulled from the user\'s Apple Calendar.
public struct AppleCalendarItemSummary: Codable, Hashable {
    public let identifier: String
    public let calendarIdentifier: String
    public let calendarTitle: String
    public let title: String
    public let startDateISO8601: String
    public let endDateISO8601: String
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let attendees: [String]?
    
    public init(
        identifier: String,
        calendarIdentifier: String,
        calendarTitle: String,
        title: String,
        startDateISO8601: String,
        endDateISO8601: String,
        isAllDay: Bool,
        location: String?,
        notes: String?,
        attendees: [String]?
    ) {
        self.identifier = identifier
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.title = title
        self.startDateISO8601 = startDateISO8601
        self.endDateISO8601 = endDateISO8601
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.attendees = attendees
    }
}

/// Lightweight value describing a reminder pulled from Apple Reminders.
public struct AppleReminderSummary: Codable, Hashable {
    public let identifier: String
    public let calendarIdentifier: String
    public let calendarTitle: String
    public let title: String
    public let dueDateISO8601: String?
    public let hasDueTime: Bool
    public let completed: Bool
    public let completionDateISO8601: String?
    public let priority: Int
    public let notes: String?
    
    public init(
        identifier: String,
        calendarIdentifier: String,
        calendarTitle: String,
        title: String,
        dueDateISO8601: String?,
        hasDueTime: Bool,
        completed: Bool,
        completionDateISO8601: String?,
        priority: Int,
        notes: String?
    ) {
        self.identifier = identifier
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.title = title
        self.dueDateISO8601 = dueDateISO8601
        self.hasDueTime = hasDueTime
        self.completed = completed
        self.completionDateISO8601 = completionDateISO8601
        self.priority = priority
        self.notes = notes
    }
}
