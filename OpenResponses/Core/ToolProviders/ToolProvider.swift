import Foundation
import Security
import AuthenticationServices

// MARK: - Shared Types

public enum ToolKind: String, CaseIterable, Identifiable {
    case notion, gmail, gcal, gcontacts, apple
    public var id: String { rawValue }
}

public struct ProviderCapability: OptionSet {
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

public protocol ToolProvider {
    var kind: ToolKind { get }
    var capabilities: ProviderCapability { get }
    func connect(presentingAnchor: ASPresentationAnchor?) async throws
}

// MARK: - Provider-Specific Protocols

public protocol NotionReadable {
    func listDatabasesUnderPage(_ pageId: String) async throws -> [NotionDatabaseSummary]
}
public protocol GmailReadable {
    func listRecentThreads(max: Int) async throws -> [GmailThreadSummary]
}
public protocol CalendarReadable {
    func listEvents(startISO8601: String, endISO8601: String, max: Int) async throws -> [GCalEventSummary]
}
public protocol ContactsReadable {
    func searchContacts(query: String, max: Int) async throws -> [GContactSummary]
}

// MARK: - Token Store (Keychain)

enum TokenStore {
    static func save(_ data: Data, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func saveString(_ s: String, account: String) -> Bool {
        save(Data(s.utf8), account: account)
    }

    static func readString(account: String) -> String? {
        read(account: account).flatMap { String(data: $0, encoding: .utf8) }
    }
    
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - HTTP Client with Backoff

final class HttpClient {
    struct Metrics {
        var attempts = 0
        var durationMs: Int = 0
        var status: Int = 0
    }

    func send(_ req: URLRequest, retries: Int = 2) async throws -> (Data, URLResponse, Metrics) {
        var lastErr: Error?
        var metrics = Metrics()
        for attempt in 0...retries {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                metrics.attempts = attempt + 1
                metrics.durationMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                metrics.status = (resp as? HTTPURLResponse)?.statusCode ?? -1
                
                if let http = resp as? HTTPURLResponse, (http.statusCode == 429 || http.statusCode >= 500), attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 0.25 * 1_000_000_000)) // 250ms, 500ms
                    continue
                }
                return (data, resp, metrics)
            } catch {
                lastErr = error
                if attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 0.25 * 1_000_000_000))
                }
                continue
            }
        }
        throw lastErr ?? URLError(.cannotLoadFromNetwork)
    }
}
