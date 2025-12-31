import AuthenticationServices
import Contacts
import EventKit
import Foundation

#if canImport(EventKit)

// MARK: - Apple Data Summaries

/// Structured summary of a calendar event for tool output.
public struct AppleCalendarEventDetail: Codable {
    let identifier: String
    let calendarIdentifier: String
    let calendarTitle: String
    let title: String
    let startDateISO8601: String
    let endDateISO8601: String
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let attendees: [String]?
}

/// Structured summary of a reminder for tool output.
public struct AppleReminderDetail: Codable {
    let identifier: String
    let calendarIdentifier: String
    let calendarTitle: String
    let title: String
    let dueDateISO8601: String?
    let hasDueTime: Bool
    let completed: Bool
    let completionDateISO8601: String?
    let priority: Int
    let notes: String?
}

// MARK: - Apple Tool Provider

/// Provides MCP-compatible tools for accessing Apple Calendar and Reminders on-device.
/// Requires user consent through EventKit permissions.
public final class AppleProvider: ToolProvider {

    public var kind: ToolKind { .apple }

    public var capabilities: ProviderCapability {
        [.listCalendarEvents, .createCalendarEvent, .listReminders, .createReminder, .searchContacts, .getContact, .createContact]
    }

    private let permissionManager: EventKitPermissionManager
    private let calendarRepo: AppleCalendarRepository
    private let reminderRepo: AppleReminderRepository
    private let contactsPermissionManager: ContactsPermissionManager
    private let contactsRepo: ContactsRepository

    /// Initializes the provider with dependency injection support.
    public init(
        permissionManager: EventKitPermissionManager = .shared,
        calendarRepo: AppleCalendarRepository = AppleCalendarRepository(),
        reminderRepo: AppleReminderRepository = AppleReminderRepository(),
        contactsPermissionManager: ContactsPermissionManager = .shared,
        contactsRepo: ContactsRepository = ContactsRepository()
    ) {
        self.permissionManager = permissionManager
        self.calendarRepo = calendarRepo
        self.reminderRepo = reminderRepo
        self.contactsPermissionManager = contactsPermissionManager
        self.contactsRepo = contactsRepo
    }

    /// Connects by requesting EventKit permissions for both calendars and reminders.
    public func connect(presentingAnchor: ASPresentationAnchor?) async throws {
        // Request calendar access
        try await permissionManager.ensureAccess(for: .event)
        // Request reminders access
        try await permissionManager.ensureAccess(for: .reminder)
        // Request contacts access
        try await contactsPermissionManager.ensureAccess()
    }

    /// Checks if the user has granted calendar permissions.
    public func hasCalendarAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    /// Checks if the user has granted reminders permissions.
    public func hasRemindersAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    /// Checks if the user has granted contacts permissions.
    public func hasContactsAccess() -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return status == .authorized
    }

    /// Revokes permissions by clearing internal state. Note: actual system permissions
    /// must be revoked by the user through Settings > Privacy.
    public func disconnect() {
        // EventKit and Contacts permissions are system-level and cannot be programmatically revoked.
        // This method exists for protocol consistency but is effectively a no-op.
        // Users must go to Settings > Privacy > Calendars/Reminders/Contacts to revoke.
    }
}

// MARK: - Calendar Operations

extension AppleProvider: AppleCalendarReadable {

    /// Fetches calendar events within the specified date range.
    /// - Parameters:
    ///   - startISO8601: ISO8601 start date (e.g., "2025-11-05T00:00:00Z")
    ///   - endISO8601: ISO8601 end date
    ///   - calendarIdentifiers: Optional filter for specific calendars
    /// - Returns: Array of calendar event summaries
    public func listEvents(
        startISO8601: String,
        endISO8601: String,
        calendarIdentifiers: [String]?
    ) async throws -> [AppleCalendarEventDetail] {
        let summaries = try await calendarRepo.fetchEvents(
            startISO8601: startISO8601,
            endISO8601: endISO8601,
            calendarIdentifiers: calendarIdentifiers
        )

        return summaries.map { summary in
            AppleCalendarEventDetail(
                identifier: summary.identifier,
                calendarIdentifier: summary.calendarIdentifier,
                calendarTitle: summary.calendarTitle,
                title: summary.title,
                startDateISO8601: summary.startDateISO8601,
                endDateISO8601: summary.endDateISO8601,
                isAllDay: summary.isAllDay,
                location: summary.location,
                notes: summary.notes,
                attendees: summary.attendees
            )
        }
    }

    /// Creates a new calendar event.
    /// - Parameters:
    ///   - title: Event title
    ///   - startISO8601: ISO8601 start date/time
    ///   - endISO8601: ISO8601 end date/time
    ///   - location: Optional event location
    ///   - notes: Optional event notes
    ///   - calendarIdentifier: Optional specific calendar (defaults to system default)
    /// - Returns: The created event summary
    public func createEvent(
        title: String,
        startISO8601: String,
        endISO8601: String,
        location: String?,
        notes: String?,
        calendarIdentifier: String?
    ) async throws -> AppleCalendarEventDetail {
        // Parse ISO8601 dates
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startDate = formatter.date(from: startISO8601) else {
            throw NSError(domain: "AppleProvider", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid start date format: \(startISO8601)"
            ])
        }

        guard let endDate = formatter.date(from: endISO8601) else {
            throw NSError(domain: "AppleProvider", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid end date format: \(endISO8601)"
            ])
        }

        let summary = try await calendarRepo.createEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            notes: notes,
            calendarIdentifier: calendarIdentifier
        )

        return AppleCalendarEventDetail(
            identifier: summary.identifier,
            calendarIdentifier: summary.calendarIdentifier,
            calendarTitle: summary.calendarTitle,
            title: summary.title,
            startDateISO8601: summary.startDateISO8601,
            endDateISO8601: summary.endDateISO8601,
            isAllDay: summary.isAllDay,
            location: summary.location,
            notes: summary.notes,
            attendees: summary.attendees
        )
    }
}

// MARK: - Reminders Operations

extension AppleProvider: AppleReminderReadable {

    /// Fetches reminders within the specified date range.
    /// - Parameters:
    ///   - startISO8601: Optional ISO8601 start date for due date filtering
    ///   - endISO8601: Optional ISO8601 end date for due date filtering
    ///   - completed: Filter by completion status (nil = all)
    ///   - listIdentifiers: Optional filter for specific reminder lists
    /// - Returns: Array of reminder summaries
    public func listReminders(
        startISO8601: String?,
        endISO8601: String?,
        completed: Bool?,
        listIdentifiers: [String]?
    ) async throws -> [AppleReminderDetail] {
        let summaries = try await reminderRepo.fetchReminders(
            startISO8601: startISO8601,
            endISO8601: endISO8601,
            completed: completed,
            listIdentifiers: listIdentifiers
        )

        return summaries.map { summary in
            AppleReminderDetail(
                identifier: summary.identifier,
                calendarIdentifier: summary.calendarIdentifier,
                calendarTitle: summary.calendarTitle,
                title: summary.title,
                dueDateISO8601: summary.dueDateISO8601,
                hasDueTime: summary.hasDueTime,
                completed: summary.completed,
                completionDateISO8601: summary.completionDateISO8601,
                priority: summary.priority,
                notes: summary.notes
            )
        }
    }

    /// Creates a new reminder in the specified list.
    /// - Parameters:
    ///   - title: Reminder title
    ///   - notes: Optional notes
    ///   - dueDateISO8601: Optional ISO8601 due date
    ///   - listIdentifier: Optional list identifier (defaults to system default)
    /// - Returns: The created reminder summary
    public func createReminder(
        title: String,
        notes: String?,
        dueDateISO8601: String?,
        listIdentifier: String?
    ) async throws -> AppleReminderDetail {
        // Parse ISO8601 date if provided
        let dueDate: Date?
        if let dueDateISO8601 {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dueDate = formatter.date(from: dueDateISO8601)
        } else {
            dueDate = nil
        }

        let summary = try await reminderRepo.createReminder(
            title: title,
            notes: notes,
            dueDate: dueDate,
            listIdentifier: listIdentifier
        )

        return AppleReminderDetail(
            identifier: summary.identifier,
            calendarIdentifier: summary.calendarIdentifier,
            calendarTitle: summary.calendarTitle,
            title: summary.title,
            dueDateISO8601: summary.dueDateISO8601,
            hasDueTime: summary.hasDueTime,
            completed: summary.completed,
            completionDateISO8601: summary.completionDateISO8601,
            priority: summary.priority,
            notes: summary.notes
        )
    }
}

// MARK: - Provider-Specific Protocols

public protocol AppleCalendarReadable {
    func listEvents(
        startISO8601: String,
        endISO8601: String,
        calendarIdentifiers: [String]?
    ) async throws -> [AppleCalendarEventDetail]

    func createEvent(
        title: String,
        startISO8601: String,
        endISO8601: String,
        location: String?,
        notes: String?,
        calendarIdentifier: String?
    ) async throws -> AppleCalendarEventDetail
}

public protocol AppleReminderReadable {
    func listReminders(
        startISO8601: String?,
        endISO8601: String?,
        completed: Bool?,
        listIdentifiers: [String]?
    ) async throws -> [AppleReminderDetail]

    func createReminder(
        title: String,
        notes: String?,
        dueDateISO8601: String?,
        listIdentifier: String?
    ) async throws -> AppleReminderDetail
}

// MARK: - Contacts Operations

extension AppleProvider: AppleContactsReadable {

    /// Searches contacts by name, email, or phone
    /// - Parameters:
    ///   - query: Search term to match against contact names
    ///   - limit: Maximum number of results (default: 50)
    /// - Returns: Array of contact summaries
    public func searchContacts(
        query: String,
        limit: Int = 50
    ) async throws -> [AppleContactSummary] {
        return try await contactsRepo.searchContacts(query: query, limit: limit)
    }

    /// Gets all contacts (for "list all" queries)
    /// - Parameter limit: Maximum number of results (default: 100)
    /// - Returns: Array of contact summaries
    public func getAllContacts(
        limit: Int = 100
    ) async throws -> [AppleContactSummary] {
        return try await contactsRepo.getAllContacts(limit: limit)
    }

    /// Gets detailed information about a specific contact
    /// - Parameter identifier: The contact's unique identifier
    /// - Returns: Detailed contact information
    public func getContact(
        identifier: String
    ) async throws -> AppleContactDetail {
        return try await contactsRepo.getContact(identifier: identifier)
    }

    /// Creates a new contact
    /// - Parameters:
    ///   - givenName: First name
    ///   - familyName: Last name
    ///   - organizationName: Company/organization
    ///   - phoneNumber: Phone number
    ///   - phoneLabel: Label for phone (e.g., "mobile", "work")
    ///   - emailAddress: Email address
    ///   - emailLabel: Label for email (e.g., "home", "work")
    ///   - note: Additional notes
    /// - Returns: The newly created contact's details
    public func createContact(
        givenName: String?,
        familyName: String?,
        organizationName: String?,
        phoneNumber: String?,
        phoneLabel: String?,
        emailAddress: String?,
        emailLabel: String?,
        note: String?
    ) async throws -> AppleContactDetail {
        return try await contactsRepo.createContact(
            givenName: givenName,
            familyName: familyName,
            organizationName: organizationName,
            phoneNumber: phoneNumber,
            phoneLabel: phoneLabel,
            emailAddress: emailAddress,
            emailLabel: emailLabel,
            note: note
        )
    }
}

public protocol AppleContactsReadable {
    func searchContacts(query: String, limit: Int) async throws -> [AppleContactSummary]
    func getAllContacts(limit: Int) async throws -> [AppleContactSummary]
    func getContact(identifier: String) async throws -> AppleContactDetail
    func createContact(
        givenName: String?,
        familyName: String?,
        organizationName: String?,
        phoneNumber: String?,
        phoneLabel: String?,
        emailAddress: String?,
        emailLabel: String?,
        note: String?
    ) async throws -> AppleContactDetail
}

#endif
