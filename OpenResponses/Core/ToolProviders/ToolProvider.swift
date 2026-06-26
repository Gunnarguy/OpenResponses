import Foundation
import Security
import AuthenticationServices

// MARK: - Shared Types



public protocol ToolProvider: Sendable {
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

/// Lightweight keychain wrapper matching KeychainService's service name for cross-compatibility.
enum TokenStore: Sendable {
    /// Must match KeychainService.keychainServiceName for tokens to be shared between the two APIs.
    
    nonisolated static func save(_ data: Data, account: String) -> Bool {
        let serviceName = "OpenResponses"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    nonisolated static func read(account: String) -> Data? {
        let serviceName = "OpenResponses"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    nonisolated static func saveString(_ s: String, account: String) -> Bool {
        save(Data(s.utf8), account: account)
    }

    nonisolated static func readString(account: String) -> String? {
        read(account: account).flatMap { String(data: $0, encoding: .utf8) }
    }

    nonisolated static func delete(account: String) -> Bool {
        let serviceName = "OpenResponses"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - HTTP Client with Backoff

final class HttpClient: Sendable {
    struct Metrics {
        var attempts = 0
        var durationMs: Int = 0
        var status: Int = 0
    }

    nonisolated init() {}

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
