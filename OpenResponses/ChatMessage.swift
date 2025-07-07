import Foundation
import SwiftUI

/// Represents a single message in the chat (user, assistant, or system/error).
struct ChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
        case system  // Used for errors or system notices
    }
    let id: UUID
    let role: Role
    var text: String?
    var images: [UIImage]?  // Any images associated with the message (for assistant outputs)

    init(id: UUID = UUID(), role: Role, text: String?, images: [UIImage]? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.images = images
    }
}

/// Codable models for decoding OpenAI /v1/responses API JSON.
struct OpenAIResponse: Decodable {
    let id: String?               // The response ID (used for continuity in follow-ups)
    let output: [OutputItem]      // List of output items returned by the model (messages, tool outputs, etc.)
    // We omit other fields like 'status' for brevity, assuming each call completes with final output.
}

struct OutputItem: Decodable {
    let id: String
    let type: String              // Type of output (e.g., "message", "reasoning", "tool_call", "image", etc.)
    let summary: [SummaryItem]?   // Chain-of-thought summary items (if reasoning summary was requested)
    let content: [ContentItem]?   // Content items (text segments, images, etc.) for this output
    
    enum CodingKeys: String, CodingKey {
        case id, type, summary, content
    }
}

struct SummaryItem: Decodable {
    let type: String              // Summary type (e.g., "summary_text")
    let text: String
}

struct ContentItem: Decodable {
    let type: String              // Content type (e.g., "text", "image_file", "image_url")
    let text: String?             // Text content (present if type is text or similar)
    let imageURL: ImageURLContent?    // Image URL content (if type is "image_url")
    let imageFile: ImageFileContent?  // Image file content (if type is "image_file")
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
        case imageFile = "image_file"
    }
}

/// Nested object for image URL content in API response.
struct ImageURLContent: Decodable {
    let url: String
}

/// Nested object for image file content in API response.
struct ImageFileContent: Decodable {
    let file_id: String
}

// MARK: - File Management Models

/// Represents a file uploaded to OpenAI
struct OpenAIFile: Decodable, Identifiable {
    let id: String
    let object: String // "file"
    let bytes: Int
    let createdAt: Int
    let filename: String
    let purpose: String
    
    enum CodingKeys: String, CodingKey {
        case id, object, bytes, filename, purpose
        case createdAt = "created_at"
    }
}

/// Response when listing files
struct FileListResponse: Decodable {
    let object: String // "list"
    let data: [OpenAIFile]
}

// MARK: - Vector Store Models

/// Represents a vector store
struct VectorStore: Decodable, Identifiable {
    let id: String
    let object: String // "vector_store"
    let createdAt: Int
    let name: String?
    let usageBytes: Int
    let fileCounts: FileCounts
    let status: String
    let expiresAfter: ExpiresAfter?
    let expiresAt: Int?
    let lastActiveAt: Int?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, name, status, metadata
        case createdAt = "created_at"
        case usageBytes = "usage_bytes"
        case fileCounts = "file_counts"
        case expiresAfter = "expires_after"
        case expiresAt = "expires_at"
        case lastActiveAt = "last_active_at"
    }
}

/// File counts in a vector store
struct FileCounts: Decodable {
    let inProgress: Int
    let completed: Int
    let failed: Int
    let cancelled: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case total, completed, failed, cancelled
        case inProgress = "in_progress"
    }
}

/// Expiration settings for vector store
struct ExpiresAfter: Decodable {
    let anchor: String
    let days: Int
}

/// Response when listing vector stores
struct VectorStoreListResponse: Decodable {
    let object: String // "list"
    let data: [VectorStore]
}

/// Vector store file relationship
struct VectorStoreFile: Decodable, Identifiable {
    let id: String
    let object: String // "vector_store.file"
    let usageBytes: Int
    let createdAt: Int
    let vectorStoreId: String
    let status: String
    let lastError: VectorStoreFileError?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status
        case usageBytes = "usage_bytes"
        case createdAt = "created_at"
        case vectorStoreId = "vector_store_id"
        case lastError = "last_error"
    }
}

/// Error information for vector store files
struct VectorStoreFileError: Decodable {
    let code: String
    let message: String
}

/// Response when listing vector store files
struct VectorStoreFileListResponse: Decodable {
    let object: String // "list"
    let data: [VectorStoreFile]
}

// MARK: - New Streaming API Models

/// Represents different types of streaming events from the new OpenAI Responses API
struct StreamingEvent: Decodable {
    let type: String
    let sequenceNumber: Int
    let response: StreamingResponse?
    let outputIndex: Int?
    let itemId: String?
    let contentIndex: Int?
    let delta: String?
    let item: StreamingItem?
    let part: StreamingPart?
    
    enum CodingKeys: String, CodingKey {
        case type
        case sequenceNumber = "sequence_number"
        case response
        case outputIndex = "output_index"
        case itemId = "item_id"
        case contentIndex = "content_index"
        case delta
        case item
        case part
    }
}

/// Streaming response object
struct StreamingResponse: Decodable {
    let id: String
    let status: String?
    let output: [StreamingOutputItem]?
    let usage: StreamingUsage?
}

/// Streaming output item
struct StreamingOutputItem: Decodable {
    let id: String
    let type: String
    let status: String?
    let content: [StreamingContentItem]?
    let role: String?
}

/// Streaming content item
struct StreamingContentItem: Decodable {
    let type: String
    let text: String?
}

/// Streaming item
struct StreamingItem: Decodable {
    let id: String
    let type: String
    let status: String?
    let content: [StreamingContentItem]?
    let role: String?
}

/// Streaming part
struct StreamingPart: Decodable {
    let type: String
    let text: String?
}

/// Usage information
struct StreamingUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
}
