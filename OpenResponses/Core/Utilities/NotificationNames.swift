import Foundation

extension Notification.Name {
    /// Posted when the OpenAI API key is added/updated/removed.
    static let openAIKeyDidChange = Notification.Name("openAIKeyDidChange")
}
