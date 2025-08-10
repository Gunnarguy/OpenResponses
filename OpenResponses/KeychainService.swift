import Foundation
import Security

/// A service for securely storing and retrieving data from the iOS Keychain.
class KeychainService {
    
    static let shared = KeychainService()
    private init() {}

    /// Saves a string value to the Keychain for a given key.
    /// - Parameters:
    ///   - value: The string value to save.
    ///   - key: The key to associate with the value.
    /// - Returns: `true` if saving was successful, `false` otherwise.
    @discardableResult
    func save(value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item for this key before saving a new one
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Loads a string value from the Keychain for a given key.
    /// - Parameter key: The key for the value to retrieve.
    /// - Returns: The string value if found, otherwise `nil`.
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
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
                print("Successfully migrated API key from UserDefaults to Keychain.")
            }
        }
    }
}
