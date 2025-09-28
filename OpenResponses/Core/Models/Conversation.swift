import Foundation

/// Represents a single, ongoing conversation, including its messages and state.
struct Conversation: Identifiable, Codable {
    /// A unique identifier for the conversation.
    var id: UUID

    /// The title of the conversation, often derived from the first user message.
    var title: String

    /// The array of messages that make up the conversation.
    var messages: [ChatMessage]

    /// The ID of the last response from the OpenAI API. This is crucial for maintaining conversational context
    /// with the stateful Responses API. It links subsequent requests to the previous turn.
    var lastResponseId: String?

    /// The timestamp when the conversation was last modified. This is used for sorting conversations.
    var lastModified: Date

    /// A static factory method to create a new, empty conversation.
    /// - Returns: A `Conversation` instance with a new UUID, a default title, an empty message array,
    ///   and the current timestamp.
    static func new() -> Conversation {
        Conversation(
            id: UUID(),
            title: "New Chat",
            messages: [],
            lastResponseId: nil,
            lastModified: Date()
        )
    }
}
