import Foundation

#if canImport(EventKit)
import EventKit

/// Provides read operations for Apple Calendar data with lightweight summaries.
public final class AppleCalendarRepository {
    private let permissionManager: EventKitPermissionManager
    private let isoFormatter: ISO8601DateFormatter

    public init(permissionManager: EventKitPermissionManager = .shared) {
        self.permissionManager = permissionManager
        self.isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    /// Fetches events within the provided date range.
    /// - Parameters:
    ///   - start: Start date (defaults to start of today when nil).
    ///   - end: End date (defaults to 7 days after start when nil).
    ///   - calendarIDs: Optional subset of calendar identifiers to include.
    ///   - limit: Max number of events to return.
    ///   - includeNotes: Toggle to copy event notes into the summary.
    func fetchEvents(
        start: Date?,
        end: Date?,
        calendarIDs: [String]?,
        limit: Int,
        includeNotes: Bool
    ) async throws -> [AppleCalendarItemSummary] {
        try await permissionManager.ensureAccess(for: .event)

        guard limit > 0 else { return [] }

        let store = permissionManager.store
        let effectiveStart = start ?? Calendar.current.startOfDay(for: Date())
        let effectiveEnd = end ?? Calendar.current.date(byAdding: .day, value: 7, to: effectiveStart) ?? effectiveStart
        guard effectiveStart <= effectiveEnd else { throw AppleDataAccessError.invalidDateRange }

        let calendars = selectCalendars(from: store, matching: calendarIDs)
        let predicate = store.predicateForEvents(withStart: effectiveStart, end: effectiveEnd, calendars: calendars)
        let events = store.events(matching: predicate)
            .sorted(by: { $0.startDate < $1.startDate })
            .prefix(limit)

        return events.map { event in
            AppleCalendarItemSummary(
                identifier: event.eventIdentifier,
                calendarIdentifier: event.calendar.calendarIdentifier,
                calendarTitle: event.calendar.title,
                title: event.title ?? "(No Title)",
                startDateISO8601: isoFormatter.string(from: event.startDate),
                endDateISO8601: isoFormatter.string(from: event.endDate ?? event.startDate),
                isAllDay: event.isAllDay,
                location: event.location?.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: includeNotes ? event.notes?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                attendees: event.attendees?.compactMap { $0.name }
            )
        }
    }
    
    /// Convenience wrapper for ISO8601 date strings.
    public func fetchEvents(
        startISO8601: String,
        endISO8601: String,
        calendarIdentifiers: [String]?
    ) async throws -> [AppleCalendarItemSummary] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let start = formatter.date(from: startISO8601)
        let end = formatter.date(from: endISO8601)
        
        return try await fetchEvents(
            start: start,
            end: end,
            calendarIDs: calendarIdentifiers,
            limit: 100,
            includeNotes: true
        )
    }

    private func selectCalendars(from store: EKEventStore, matching identifiers: [String]?) -> [EKCalendar]? {
        guard let identifiers, !identifiers.isEmpty else { return nil }
        let knownCalendars = store.calendars(for: .event)
        let calendarSet = Set(identifiers)
        let filtered = knownCalendars.filter { calendarSet.contains($0.calendarIdentifier) }
        return filtered.isEmpty ? nil : filtered
    }
    
    /// Creates a new calendar event.
    /// - Parameters:
    ///   - title: Event title
    ///   - startDate: Event start date/time
    ///   - endDate: Event end date/time
    ///   - location: Optional event location
    ///   - notes: Optional event notes
    ///   - calendarIdentifier: Optional specific calendar (uses default if nil)
    /// - Returns: Summary of the created event
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        calendarIdentifier: String?
    ) async throws -> AppleCalendarItemSummary {
        try await permissionManager.ensureAccess(for: .event)
        
        let store = permissionManager.store
        let event = EKEvent(eventStore: store)
        
        // Set basic properties
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        
        // Assign to calendar
        if let calendarIdentifier {
            let calendars = store.calendars(for: .event)
            if let targetCalendar = calendars.first(where: { $0.calendarIdentifier == calendarIdentifier }) {
                event.calendar = targetCalendar
            } else {
                event.calendar = store.defaultCalendarForNewEvents
            }
        } else {
            event.calendar = store.defaultCalendarForNewEvents
        }
        
        // Validate calendar is writable
        guard let calendar = event.calendar else {
            throw AppleDataAccessError.invalidCalendar
        }
        guard calendar.allowsContentModifications else {
            throw AppleDataAccessError.calendarNotWritable
        }
        
        // Save the event
        try store.save(event, span: .thisEvent)
        
        // Return summary
        return AppleCalendarItemSummary(
            identifier: event.eventIdentifier,
            calendarIdentifier: calendar.calendarIdentifier,
            calendarTitle: calendar.title,
            title: event.title ?? "(No Title)",
            startDateISO8601: isoFormatter.string(from: event.startDate),
            endDateISO8601: isoFormatter.string(from: event.endDate ?? event.startDate),
            isAllDay: event.isAllDay,
            location: event.location?.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: event.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            attendees: event.attendees?.compactMap { $0.name }
        )
    }
}
#endif
