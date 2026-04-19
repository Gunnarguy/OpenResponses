import Foundation

#if canImport(EventKit)
import EventKit

/// Provides read/write access to Apple Reminders with async conveniences.
public final class AppleReminderRepository {
    private let permissionManager: EventKitPermissionManager
    private let isoFormatter: ISO8601DateFormatter

    public init(permissionManager: EventKitPermissionManager = .shared) {
        self.permissionManager = permissionManager
        self.isoFormatter = AppleDateUtilities.makeOutputFormatter()
    }

    /// Fetches reminders using the EventKit predicates documented for incomplete and completed reminders.
    func fetchReminders(
        dueBetween start: Date?,
        end: Date?,
        completed: Bool?,
        listIDs: [String]?,
        limit: Int
    ) async throws -> [AppleReminderSummary] {
        try await permissionManager.ensureAccess(for: .reminder)
        guard limit > 0 else { return [] }
        if let start, let end, start > end {
            throw AppleDataAccessError.invalidDateRange
        }

        let store = permissionManager.store
        let calendars = selectCalendars(from: store, matching: listIDs)

        let reminders: [EKReminder]
        switch completed {
        case .some(false):
            reminders = try await fetchReminderObjects(
                matching: store.predicateForIncompleteReminders(
                    withDueDateStarting: start,
                    ending: end,
                    calendars: calendars
                )
            )
        case .some(true):
            reminders = try await fetchReminderObjects(
                matching: store.predicateForCompletedReminders(
                    withCompletionDateStarting: start,
                    ending: end,
                    calendars: calendars
                )
            )
        case nil:
            reminders = try await fetchReminderObjects(
                matching: store.predicateForReminders(in: calendars)
            )
        }

        let filtered = reminders
            .filter { reminder in
                matches(reminder: reminder, start: start, end: end, completed: completed)
            }
            .sorted { lhs, rhs in
                let lhsDate = sortDate(for: lhs, completed: completed) ?? .distantFuture
                let rhsDate = sortDate(for: rhs, completed: completed) ?? .distantFuture
                if lhsDate == rhsDate {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhsDate < rhsDate
            }
            .prefix(limit)

        return filtered.map { summary(for: $0) }
    }

    /// Convenience wrapper for ISO8601 date strings and completion filter.
    public func fetchReminders(
        startISO8601: String?,
        endISO8601: String?,
        completed: Bool?,
        listIdentifiers: [String]?
    ) async throws -> [AppleReminderSummary] {
        let start = try parseDate(startISO8601)
        let end = try parseDate(endISO8601)

        return try await fetchReminders(
            dueBetween: start,
            end: end,
            completed: completed,
            listIDs: listIdentifiers,
            limit: 100
        )
    }

    /// Creates a new reminder in the user's default list or the list matching `listIdentifier`.
    public func createReminder(
        title: String,
        notes: String?,
        dueDate: Date?,
        priority: Int?,
        listIdentifier: String?
    ) async throws -> AppleReminderSummary {
        try await permissionManager.ensureAccess(for: .reminder)
        let store = permissionManager.store
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority ?? 0

        if let dueDate {
            let dueComponents = AppleDateUtilities.makeReminderDateComponents(from: dueDate)
            reminder.startDateComponents = dueComponents
            reminder.dueDateComponents = dueComponents
        }

        if let listIdentifier,
           let calendar = store.calendar(withIdentifier: listIdentifier) {
            reminder.calendar = calendar
        } else {
            guard let defaultCalendar = store.defaultCalendarForNewReminders() else {
                throw AppleDataAccessError.operationUnavailable("Unable to determine default reminder list.")
            }
            reminder.calendar = defaultCalendar
        }

        try store.save(reminder, commit: true)

        return AppleReminderSummary(
            identifier: reminder.calendarItemIdentifier,
            calendarIdentifier: reminder.calendar.calendarIdentifier,
            calendarTitle: reminder.calendar.title,
            title: reminder.title,
            dueDateISO8601: reminder.dueDateComponents?.date.map { isoFormatter.string(from: $0) },
            hasDueTime: AppleDateUtilities.hasClockTime(reminder.dueDateComponents),
            completed: reminder.isCompleted,
            completionDateISO8601: reminder.completionDate.map { isoFormatter.string(from: $0) },
            priority: reminder.priority,
            notes: reminder.notes
        )
    }

    private func parseDate(_ rawValue: String?) throws -> Date? {
        guard let rawValue else { return nil }
        guard let parsed = AppleDateUtilities.parseQueryDate(rawValue) else {
            throw AppleDataAccessError.invalidDate(rawValue)
        }
        return parsed
    }

    private func fetchReminderObjects(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            permissionManager.store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func matches(
        reminder: EKReminder,
        start: Date?,
        end: Date?,
        completed: Bool?
    ) -> Bool {
        if let completed, reminder.isCompleted != completed {
            return false
        }

        guard start != nil || end != nil else {
            return true
        }

        let relevantDate: Date?
        if completed == true {
            relevantDate = reminder.completionDate
        } else {
            relevantDate = reminder.dueDateComponents?.date
        }

        guard let relevantDate else { return false }
        if let start, relevantDate < start { return false }
        if let end, relevantDate > end { return false }
        return true
    }

    private func sortDate(for reminder: EKReminder, completed: Bool?) -> Date? {
        if completed == true {
            return reminder.completionDate ?? reminder.dueDateComponents?.date
        }
        return reminder.dueDateComponents?.date ?? reminder.completionDate
    }

    private func summary(for reminder: EKReminder) -> AppleReminderSummary {
        AppleReminderSummary(
            identifier: reminder.calendarItemIdentifier,
            calendarIdentifier: reminder.calendar?.calendarIdentifier ?? "",
            calendarTitle: reminder.calendar?.title ?? "Reminders",
            title: reminder.title,
            dueDateISO8601: reminder.dueDateComponents?.date.map { isoFormatter.string(from: $0) },
            hasDueTime: AppleDateUtilities.hasClockTime(reminder.dueDateComponents),
            completed: reminder.isCompleted,
            completionDateISO8601: reminder.completionDate.map { isoFormatter.string(from: $0) },
            priority: reminder.priority,
            notes: reminder.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func selectCalendars(from store: EKEventStore, matching identifiers: [String]?) -> [EKCalendar]? {
        guard let identifiers, !identifiers.isEmpty else { return nil }
        let knownCalendars = store.calendars(for: .reminder)
        let set = Set(identifiers)
        let filtered = knownCalendars.filter { set.contains($0.calendarIdentifier) }
        return filtered.isEmpty ? nil : filtered
    }
}
#endif
