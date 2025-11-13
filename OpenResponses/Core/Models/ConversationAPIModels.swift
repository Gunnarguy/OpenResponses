import Foundation

/// Response payload for listing conversations via `/v1/conversations`.
struct ConversationListResponse: Decodable {
    let data: [ConversationSummary]
    let firstId: String?
    let lastId: String?
    let hasMore: Bool

    private enum CodingKeys: String, CodingKey {
        case data
        case firstId = "first_id"
        case lastId = "last_id"
        case hasMore = "has_more"
    }
}

/// Minimal representation of a conversation returned by the Conversations API.
struct ConversationSummary: Decodable {
    let id: String
    let title: String?
    let metadata: [String: String]?
    let createdAt: Date?
    let updatedAt: Date?
    let archivedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
}

/// Detailed conversation payload with message history.
struct ConversationDetail: Decodable {
    let id: String
    let title: String?
    let metadata: [String: String]?
    let createdAt: Date?
    let updatedAt: Date?
    let archivedAt: Date?
    let messages: [ConversationMessage]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
        case messages
    }
}

/// Represents a single message inside a conversation as returned by the Conversations API.
struct ConversationMessage: Decodable {
    let id: String
    let role: String?
    let content: [ConversationContentPart]?
    let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
    }
}

/// Content part for a conversation message. We currently only care about text parts for reconstruction.
struct ConversationContentPart: Decodable {
    let type: String
    let text: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

/// Request body for creating or updating a conversation.
struct ConversationUpdatePayload: Encodable {
    var title: String?
    var metadata: [String: String]?
    var archived: Bool?
    var store: Bool?

    init(title: String? = nil, metadata: [String: String]? = nil, archived: Bool? = nil, store: Bool? = nil) {
        self.title = title
        self.metadata = metadata
        self.archived = archived
        self.store = store
    }
}
