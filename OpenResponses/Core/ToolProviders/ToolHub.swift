import Foundation
import AuthenticationServices

public final class ToolHub {
    public static let shared = ToolHub()
    private init() {}

    public let notion = NotionProvider()
    public let gmail  = GmailProvider()
    public let gcal   = GCalProvider()
    public let gcts   = GContactsProvider()

    public var allProviders: [ToolProvider] {
        [notion, gmail, gcal, gcts]
    }

    public func connectAll(anchor: ASPresentationAnchor?) async -> [Error] {
        var errors: [Error] = []
        for provider in allProviders {
            do {
                try await provider.connect(presentingAnchor: anchor)
            } catch {
                errors.append(error)
            }
        }
        return errors
    }
}
