import Foundation

/// Errors thrown when interacting with Apple system data such as Calendar, Reminders, or Notes.
public enum AppleDataAccessError: LocalizedError {
    case frameworkUnavailable
    case accessDenied(entity: String)
    case accessRestricted(entity: String)
    case writeOnlyAccess(entity: String)
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
