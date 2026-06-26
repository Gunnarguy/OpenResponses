import Foundation
import AuthenticationServices

extension NotionProvider {
    @MainActor
    public func connect(presentingAnchor _: ASPresentationAnchor?) async throws {
        guard TokenStore.readString(account: tokenAccount) != nil else {
            throw NSError(domain: "NotionProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "No Notion token found in Keychain. Please add one in Settings."])
        }
    }
}