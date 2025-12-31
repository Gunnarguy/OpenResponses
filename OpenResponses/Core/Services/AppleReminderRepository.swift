import Foundation

#if canImport(EventKit)
import EventKit

/// Provides read/write access to Apple Reminders with async conveniences.
public final class AppleReminderRepository {
    private let permissionManager: EventKitPermissionManager
    private let isoFormatter: ISO8601DateFormatter

    public init(permissionManager: EventKitPermissionManager = .shared) {
        self.permissionManager = permissionManager
        self.isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    /// Fetches reminders optionally constrained by due date and list identifiers.
    func fetchReminders(
        dueBetween start: Date?,
        end: Date?,
        listIDs: [String]?,
        limit: Int
    ) async throws -> [AppleReminderSummary] {
        try await permissionManager.ensureAccess(for: .reminder)
        guard limit > 0 else { return [] }

        let store = permissionManager.store
        let calendars = selectCalendars(from: store, matching: listIDs)
        let predicate = store.predicateForReminders(in: calendars)

        let reminders = try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }

        let filtered = reminders
            .filter { reminder in
                guard let start else { return true }
                guard let due = reminder.dueDateComponents?.date else { return false }
                if let end { return due >= start && due <= end }
                return due >= start
            }
            .sorted(by: { lhs, rhs in
                let lhsDate = lhs.dueDateComponents?.date ?? .distantFuture
                let rhsDate = rhs.dueDateComponents?.date ?? .distantFuture
                return lhsDate < rhsDate
            })
            .prefix(limit)

        return filtered.map { reminder in
            let hasTime: Bool
            if let components = reminder.dueDateComponents {
                hasTime = components.hour != nil || components.minute != nil || components.second != nil
            } else {
                hasTime = false
            }
            return AppleReminderSummary(
                identifier: reminder.calendarItemIdentifier,
                calendarIdentifier: reminder.calendar?.calendarIdentifier ?? "",
                calendarTitle: reminder.calendar?.title ?? "Reminders",
                title: reminder.title,
                dueDateISO8601: reminder.dueDateComponents?.date.map { isoFormatter.string(from: $0) },
                hasDueTime: hasTime,
                completed: reminder.isCompleted,
                completionDateISO8601: reminder.completionDate.map { isoFormatter.string(from: $0) },
                priority: reminder.priority,
                notes: reminder.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    /// Convenience wrapper for ISO8601 date strings and completion filter.
    public func fetchReminders(
        startISO8601: String?,
        endISO8601: String?,
        completed: Bool?,
        listIdentifiers: [String]?
    ) async throws -> [AppleReminderSummary] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let start = startISO8601.flatMap { formatter.date(from: $0) }
        let end = endISO8601.flatMap { formatter.date(from: $0) }
        
        // Fetch all reminders
        var allReminders = try await fetchReminders(
            dueBetween: start,
            end: end,
            listIDs: listIdentifiers,
            limit: 100
        )
        
        // Filter by completion status if specified
        if let completed {
            allReminders = allReminders.filter { $0.completed == completed }
        }
        
        return allReminders
    }

    /// Creates a new reminder in the user\'s default list or the list matching `listIdentifier`.
    public func createReminder(
        title: String,
        notes: String?,
        dueDate: Date?,
        listIdentifier: String?
    ) async throws -> AppleReminderSummary {
        try await permissionManager.ensureAccess(for: .reminder)
        let store = permissionManager.store
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes

        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: dueDate)
            reminder.dueDateComponents?.calendar = Calendar.current
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

        let hasTime: Bool
        if let components = reminder.dueDateComponents {
            hasTime = components.hour != nil || components.minute != nil || components.second != nil
        } else {
            hasTime = false
        }

        return AppleReminderSummary(
            identifier: reminder.calendarItemIdentifier,
            calendarIdentifier: reminder.calendar.calendarIdentifier,
            calendarTitle: reminder.calendar.title,
            title: reminder.title,
            dueDateISO8601: reminder.dueDateComponents?.date.map { isoFormatter.string(from: $0) },
            hasDueTime: hasTime,
            completed: reminder.isCompleted,
            completionDateISO8601: reminder.completionDate.map { isoFormatter.string(from: $0) },
            priority: reminder.priority,
            notes: reminder.notes
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
