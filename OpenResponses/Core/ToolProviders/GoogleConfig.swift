import Foundation

enum GoogleConfig {
    // IMPORTANT: Replace this with your actual Google Cloud iOS Client ID.
    static let clientID = "<GOOGLE_IOS_CLIENT_ID>"
    
    // IMPORTANT: Ensure this custom URL scheme is configured in your Xcode project's Info.plist.
    static let redirectScheme = "com.openresponses:/oauth2redirect"
}
