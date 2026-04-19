import Foundation

/// Errors thrown when interacting with Apple system data such as Calendar, Reminders, or Notes.
public enum AppleDataAccessError: LocalizedError {
    case frameworkUnavailable
    case accessDenied(entity: String)
    case accessRestricted(entity: String)
    case writeOnlyAccess(entity: String)
    case invalidDate(String)
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
        pattern: #"^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})$"#
    )

    static func makeOutputFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
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

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: rawValue) {
            return parsed
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: rawValue)
    }

    static func parseQueryDate(_ rawValue: String?, timeZone: TimeZone = .current) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        guard let parsed = parseISO8601(rawValue) else {
            return nil
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

    static func makeReminderDateComponents(from date: Date, timeZone: TimeZone = .current) -> DateComponents {
        let calendar = makeGregorianCalendar(timeZone: timeZone)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.calendar = calendar
        components.timeZone = timeZone
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
            let secondString = capture(6),
            let timeZoneDesignator = capture(7),
            let year = Int(yearString),
            let month = Int(monthString),
            let day = Int(dayString),
            let hour = Int(hourString),
            let minute = Int(minuteString),
            let second = Int(secondString)
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
