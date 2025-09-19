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

// MARK: - Code Interpreter Artifact Models

/// Represents a code interpreter artifact (file output from code execution)
struct CodeInterpreterArtifact: Codable, Identifiable {
    let id: String
    let fileId: String
    let filename: String
    let containerId: String
    let mimeType: String?
    let content: ArtifactContent
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, fileId = "file_id", filename, containerId = "container_id", mimeType = "mime_type", content, createdAt = "created_at"
    }
    
    /// Initialize with current date
    init(id: String = UUID().uuidString, fileId: String, filename: String, containerId: String, mimeType: String?, content: ArtifactContent) {
        self.id = id
        self.fileId = fileId  
        self.filename = filename
        self.containerId = containerId
        self.mimeType = mimeType
        self.content = content
        self.createdAt = Date()
    }
    
    /// Determines artifact type based on filename extension and MIME type
    var artifactType: ArtifactType {
        let ext = (filename as NSString).pathExtension.lowercased()
        
        // Image types
        if ["jpg", "jpeg", "png", "gif"].contains(ext) {
            return .image
        }
        
        // Text/code types  
        if ["txt", "log", "py", "js", "html", "css", "json", "csv", "md", "c", "cpp", "java", "rb", "php", "sh", "ts"].contains(ext) {
            return .text
        }
        
        // Data types
        if ["csv", "json", "xml", "pkl"].contains(ext) {
            return .data
        }
        
        // Document types
        if ["pdf", "doc", "docx", "pptx", "xlsx"].contains(ext) {
            return .document
        }
        
        // Archive types
        if ["zip", "tar"].contains(ext) {
            return .archive
        }
        
        return .binary
    }
    
    /// User-friendly display name
    var displayName: String {
        switch artifactType {
        case .image: return "Image"
        case .text: return "Text File"
        case .data: return "Data File" 
        case .document: return "Document"
        case .archive: return "Archive"
        case .binary: return "Binary File"
        }
    }
    
    /// Icon name for UI display
    var iconName: String {
        switch artifactType {
        case .image: return "photo"
        case .text: return "doc.text"
        case .data: return "tablecells"
        case .document: return "doc"
        case .archive: return "archivebox"
        case .binary: return "questionmark.circle"
        }
    }
}

/// Types of code interpreter artifacts
enum ArtifactType: String, CaseIterable, Codable {
    case image = "image"
    case text = "text"
    case data = "data"
    case document = "document" 
    case archive = "archive"
    case binary = "binary"
}

/// Content of a code interpreter artifact
enum ArtifactContent: Codable {
    case image(UIImage)
    case text(String)
    case data(Data)
    case error(String)
    
    enum CodingKeys: String, CodingKey {
        case type, content
    }
    
    init(from decoder: Decoder) throws {
        // This will be set by the parsing logic in ChatViewModel
        // For now, default to error state
        self = .error("Content not loaded")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .image(_):
            try container.encode("image", forKey: .type)
        case .text(let string):
            try container.encode("text", forKey: .type)
            try container.encode(string, forKey: .content)
        case .data(_):
            try container.encode("data", forKey: .type)
        case .error(let message):
            try container.encode("error", forKey: .type)
            try container.encode(message, forKey: .content)
        }
    }
    
    /// Get text content if available
    var textContent: String? {
        switch self {
        case .text(let content): return content
        case .error(let message): return message
        default: return nil
        }
    }
    
    /// Get image content if available
    var imageContent: UIImage? {
        switch self {
        case .image(let image): return image
        default: return nil
        }
    }
    
    /// Get binary data if available
    var dataContent: Data? {
        switch self {
        case .data(let data): return data
        default: return nil
        }
    }
}
