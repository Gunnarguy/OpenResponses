import Foundation

enum AppFeatureFlags {
    /// MCP uses the same first-send consent, Keychain credentials, and explicit tool approvals as chat.
    static let isMCPAvailable = true

    /// Increment this when the consent copy changes and users should be asked again.
    static let aiDataSharingConsentVersion = 2
    static let aiDataSharingConsentVersionKey = "aiDataSharingConsentVersion"
}
