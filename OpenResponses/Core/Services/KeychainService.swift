import Foundation
import Security

/// A service for securely storing and retrieving data from the iOS Keychain.
class KeychainService {

    static let shared = KeychainService()
    private init() {}

    /// A stable Keychain service name so items can be found across app + test runs.
    ///
    /// Notes:
    /// - For `kSecClassGenericPassword`, Apple expects `kSecAttrService` to be present.
    /// - Using a constant avoids surprises where `Bundle.main.bundleIdentifier` differs
    ///   between app/UITest runners.
    private let keychainServiceName = "OpenResponses"

    /// XCTest / CI environments (especially when using `build-for-testing` with relaxed signing)
    /// can make Keychain access flaky or unavailable. We provide a test-only, in-memory fallback
    /// so unit tests remain deterministic.
    private let isRunningUnitTests: Bool = {
        // Environment var is the usual signal, but not all runners propagate it.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        // When XCTest is loaded, XCTestCase is present.
        return NSClassFromString("XCTestCase") != nil
    }()

    private let inMemoryStoreLock = NSLock()
    private var inMemoryStore: [String: String] = [:]

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
        ]
    }

    private func logKeychainFailure(_ operation: String, status: OSStatus, key: String) {
        let message = (SecCopyErrorMessageString(status, nil) as String?) ?? "OSStatus(\(status))"
        AppLogger.log("[KeychainService] \(operation) failed for key=\(key). status=\(status) \(message)", category: .general, level: .debug)
    }

    /// Saves a string value to the Keychain for a given key.
    /// - Parameters:
    ///   - value: The string value to save.
    ///   - key: The key to associate with the value.
    /// - Returns: `true` if saving was successful, `false` otherwise.
    @discardableResult
    func save(value: String, forKey key: String) -> Bool {
        if isRunningUnitTests {
            inMemoryStoreLock.lock()
            defer { inMemoryStoreLock.unlock() }
            inMemoryStore[key] = value
            return true
        }

        guard let data = value.data(using: .utf8) else { return false }
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        // Keep the stored key local to this device and available after the first unlock.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        // Delete any existing item for this key before saving a new one
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logKeychainFailure("save", status: status, key: key)
        }
        return status == errSecSuccess
    }

    /// Loads a string value from the Keychain for a given key.
    /// - Parameter key: The key for the value to retrieve.
    /// - Returns: The string value if found, otherwise `nil`.
    func load(forKey key: String) -> String? {
        if isRunningUnitTests {
            inMemoryStoreLock.lock()
            defer { inMemoryStoreLock.unlock() }
            return inMemoryStore[key]
        }

        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status != errSecSuccess, status != errSecItemNotFound {
            logKeychainFailure("load", status: status, key: key)
        }

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    /// Deletes a value from the Keychain for a given key.
    /// - Parameter key: The key for the value to delete.
    /// - Returns: `true` if deletion was successful, `false` otherwise.
    @discardableResult
    func delete(forKey key: String) -> Bool {
        if isRunningUnitTests {
            inMemoryStoreLock.lock()
            defer { inMemoryStoreLock.unlock() }
            inMemoryStore.removeValue(forKey: key)
            return true
        }

        let query = baseQuery(forKey: key)

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logKeychainFailure("delete", status: status, key: key)
        }

        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Migrates the API key from UserDefaults to Keychain if it exists.
    /// This should be called once at app startup.
    func migrateApiKeyFromUserDefaults() {
        let userDefaultsKey = "openAIKey"
        let keychainKey = "openAIKey"

        // Check if a key already exists in Keychain
        if load(forKey: keychainKey) != nil {
            // Key already in Keychain, no migration needed.
            // We can optionally remove the old UserDefaults key.
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }

        // Check if a key exists in UserDefaults
        if let apiKeyFromUserDefaults = UserDefaults.standard.string(forKey: userDefaultsKey) {
            // Save it to Keychain
            if save(value: apiKeyFromUserDefaults, forKey: keychainKey) {
                // If successful, remove it from UserDefaults
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                AppLogger.log("Successfully migrated API key from UserDefaults to Keychain.", category: .general, level: .info)
            }
        }
    }
}
