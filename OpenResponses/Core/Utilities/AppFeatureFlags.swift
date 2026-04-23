import Foundation

enum AppFeatureFlags {
    /// MCP is temporarily disabled in the shipping app while App Review focuses on the
    /// core OpenAI experience and explicit first-send privacy disclosures.
    static let isMCPAvailable = false

    /// Increment this when the consent copy changes and users should be asked again.
    static let aiDataSharingConsentVersion = 2
    static let aiDataSharingConsentVersionKey = "aiDataSharingConsentVersion"
}
