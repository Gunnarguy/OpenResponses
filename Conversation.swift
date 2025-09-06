import Foundation

/// Represents a single conversation session.
struct Conversation: Identifiable, Codable, Hashable {
    /// A unique identifier for the conversation.
    var id: UUID = UUID()
    
    /// The topic or title of the conversation.
    var topic: String?
    
    /// The date of the last message in the conversation.
    var lastMessageDate: Date
    
    /// A preview of the last message text.
    var lastMessagePreview: String?
}
