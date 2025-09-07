import Foundation
import UIKit

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

/// Represents an input image for sending to the model
struct InputImage: Codable {
    let type: String = "input_image"
    let detail: String          // "high", "low", or "auto"
    let imageUrl: String?       // Base64 data URL or actual URL
    let fileId: String?         // ID of previously uploaded image file
    
    enum CodingKeys: String, CodingKey {
        case type, detail
        case imageUrl = "image_url"
        case fileId = "file_id"
    }
    
    /// Create an InputImage from a UIImage with base64 encoding
    init(image: UIImage, detail: String = "auto") {
        self.detail = detail
        
        // Convert UIImage to base64 data URL
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64String = imageData.base64EncodedString()
            self.imageUrl = "data:image/jpeg;base64,\(base64String)"
        } else {
            self.imageUrl = nil
        }
        self.fileId = nil
    }
    
    /// Create an InputImage from a file ID
    init(fileId: String, detail: String = "auto") {
        self.detail = detail
        self.imageUrl = nil
        self.fileId = fileId
    }
}
