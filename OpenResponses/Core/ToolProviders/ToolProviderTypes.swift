import Foundation

// MARK: - Shared Types

nonisolated public enum ToolKind: String, CaseIterable, Identifiable, Sendable {
    case notion, gmail, gcal, gcontacts, apple
    public var id: String { rawValue }
}

nonisolated public struct ProviderCapability: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let listDatabases       = ProviderCapability(rawValue: 1 << 0)  // Notion
    public static let listEmails          = ProviderCapability(rawValue: 1 << 1)  // Gmail
    public static let listEvents          = ProviderCapability(rawValue: 1 << 2)  // GCal
    public static let listContacts        = ProviderCapability(rawValue: 1 << 3)  // GContacts
    public static let listCalendarEvents  = ProviderCapability(rawValue: 1 << 4)  // Apple Calendar
    public static let createCalendarEvent = ProviderCapability(rawValue: 1 << 5)  // Apple Calendar
    public static let listReminders       = ProviderCapability(rawValue: 1 << 6)  // Apple Reminders
    public static let createReminder      = ProviderCapability(rawValue: 1 << 7)  // Apple Reminders
    public static let searchContacts      = ProviderCapability(rawValue: 1 << 8)  // Apple Contacts
    public static let getContact          = ProviderCapability(rawValue: 1 << 9)  // Apple Contacts
    public static let createContact       = ProviderCapability(rawValue: 1 << 10) // Apple Contacts
}
