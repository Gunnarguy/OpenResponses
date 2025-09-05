import Foundation

/// Response model for delete response operation
struct DeleteResponseResult: Codable {
    let id: String
    let object: String
    let deleted: Bool
}

/// Response model for input items list
struct InputItemsResponse: Codable {
    let object: String
    let data: [InputItem]
    let hasMore: Bool
    let firstId: String?
    let lastId: String?
    
    enum CodingKeys: String, CodingKey {
        case object, data
        case hasMore = "has_more"
        case firstId = "first_id"
        case lastId = "last_id"
    }
}

/// Represents an input item for a response
struct InputItem: Codable {
    let id: String
    let object: String
    let type: String
    let role: String?
    let content: [ContentItem]?
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case id, object, type, role, content
        case createdAt = "created_at"
    }
}
