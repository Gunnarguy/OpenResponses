import Foundation
import Combine
import Security

struct APIWorkbenchDraft: Codable, Equatable {
    var version = 1
    var requestText: String
    var template: String
    var endpoint: String
    var transport: String
    var resourceID: String
}

/// Requests may contain MCP authorization. Keep drafts in the device-only Keychain,
/// update existing items atomically, and retain the previous item on save failure.
@MainActor
final class APIWorkbenchDraftStore: ObservableObject {
    @Published private(set) var status = "Current request is saved securely on this device."
    private(set) var restored: APIWorkbenchDraft?
    private var pending: APIWorkbenchDraft?
    private var saved: APIWorkbenchDraft?
    private var saveTask: Task<Void, Never>?
    private var recoveryRequired = false
    private let write: @MainActor (Data) throws -> Void

    init(read: @MainActor () throws -> Data? = APIWorkbenchDraftStore.readKeychain,
         write: @escaping @MainActor (Data) throws -> Void = APIWorkbenchDraftStore.writeKeychain) {
        self.write = write
        do {
            if let data = try read() {
                let draft = try JSONDecoder().decode(APIWorkbenchDraft.self, from: data)
                guard draft.version == 1 else { throw DraftError.unreadable }
                restored = draft
                saved = draft
            }
        } catch {
            recoveryRequired = true
            status = "Saved draft could not be opened. It has been preserved. Reopen Workbench after unlocking your device; export any new edits before leaving."
        }
    }

    func schedule(_ draft: APIWorkbenchDraft) {
        pending = draft
        saveTask?.cancel()
        guard !recoveryRequired, draft != saved else { return }
        status = "Saving draft…"
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)) }
            catch { return }
            self?.flush()
        }
    }

    func flush() {
        saveTask?.cancel()
        saveTask = nil
        guard !recoveryRequired, let pending, pending != saved else { return }
        do {
            try write(JSONEncoder().encode(pending))
            saved = pending
            status = "Draft saved securely on this device."
        } catch {
            status = "Draft could not be saved. Your previous saved draft is preserved. Export this request before leaving."
        }
    }

    private enum DraftError: Error { case unreadable, keychain(OSStatus) }
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "OpenResponses",
         kSecAttrAccount as String: "apiWorkbenchDraft.v1"]
    }

    private static func readKeychain() throws -> Data? {
        var query = query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = value as? Data else { throw DraftError.keychain(status) }
        return data
    }

    private static func writeKeychain(_ data: Data) throws {
        let attributes: [String: Any] = [kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let added = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
            guard added == errSecSuccess else { throw DraftError.keychain(added) }
        } else if status != errSecSuccess { throw DraftError.keychain(status) }
    }
}
