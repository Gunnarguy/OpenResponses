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
    let id: String               // The response ID (used for continuity in follow-ups)
    let object: String?          // Response object type
    let created: Int?            // Unix timestamp
    let model: String?           // Model used
    let output: [OutputItem]     // List of output items returned by the model (messages, tool outputs, etc.)
    let usage: UsageInfo?        // Token usage information
    let status: String?          // Response status
}

struct OutputItem: Decodable {
    let id: String
    let type: String              // Type of output (e.g., "message", "reasoning", "tool_call", "image", etc.)
    let summary: [SummaryItem]?   // Chain-of-thought summary items (if reasoning summary was requested)
    let content: [ContentItem]?   // Content items (text segments, images, etc.) for this output
    
    // Fields for function/tool calls
    let name: String?
    let arguments: String? // JSON string
    let callId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, summary, content, name, arguments
        case callId = "call_id"
    }
}

struct SummaryItem: Decodable {
    let type: String              // Summary type (e.g., "summary_text")
    let text: String
}

struct ContentItem: Codable {
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
struct ImageURLContent: Codable {
    let url: String
}

/// Nested object for image file content in API response.
struct ImageFileContent: Codable {
    let file_id: String
}

/// Token usage information from the API response
struct UsageInfo: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
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

// MARK: - Streaming API Models

/// Represents different types of streaming events from the OpenAI Responses API.
/// Documentation based on: https://platform.openai.com/docs/api-reference/streaming
struct StreamingEvent: Decodable, CustomStringConvertible {
    /// Type of the streaming event.
    /// Common types include:
    /// - "response.created" - Initial event when response is created
    /// - "response.queued" - Response is queued for processing
    /// - "response.in_progress" - Response generation has started
    /// - "response.completed" - Final event with complete response
    /// - "response.output_item.added" - New output item (message, reasoning, etc.) added
    /// - "response.output_item.done" - Output item is complete
    /// - "response.content_part.added" - Content part added to an output item
    /// - "response.content_part.done" - Content part is complete
    /// - "response.output_text.delta" - Text token added to content
    /// - "response.output_text.done" - Text content is complete
    let type: String
    
    /// Sequence number to maintain ordering of events
    let sequenceNumber: Int
    
    /// Full response object, present in some events like "response.created"
    let response: StreamingResponse?
    
    /// Index in the output array where the item belongs
    let outputIndex: Int?
    
    /// ID of the item this event relates to
    let itemId: String?
    
    /// Index in the content array where the content belongs
    let contentIndex: Int?
    
    /// Text delta for output_text.delta events
    let delta: String?
    
    /// Item object for output_item events
    let item: StreamingItem?
    
    /// Part object for content_part events
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
    
    /// Provides a readable description of the event
    var description: String {
        var desc = "StreamingEvent(type: \"\(type)\", seq: \(sequenceNumber)"
        
        if let response = response {
            desc += ", response: \(response.id)"
        }
        
        if let outputIndex = outputIndex {
            desc += ", outputIndex: \(outputIndex)"
        }
        
        if let itemId = itemId {
            desc += ", itemId: \"\(itemId)\""
        }
        
        if let contentIndex = contentIndex {
            desc += ", contentIndex: \(contentIndex)"
        }
        
        if let delta = delta {
            let safeText = delta.count > 20 ? "\(delta.prefix(20))..." : delta
            desc += ", delta: \"\(safeText)\""
        }
        
        return desc + ")"
    }
}

/// Streaming response object with metadata
struct StreamingResponse: Decodable, CustomStringConvertible {
    /// Unique identifier for this response
    let id: String
    
    /// Status of the response: "queued", "in_progress", "completed", "error"
    let status: String?
    
    /// Array of output items (messages, reasoning, etc.)
    let output: [StreamingOutputItem]?
    
    /// Token usage statistics (only in final response.completed event)
    let usage: StreamingUsage?
    
    /// Provides a readable description of the response
    var description: String {
        var desc = "StreamingResponse(id: \"\(id)\""
        
        if let status = status {
            desc += ", status: \"\(status)\""
        }
        
        if let output = output, !output.isEmpty {
            desc += ", output: [\(output.count) items]"
        }
        
        if let usage = usage {
            desc += ", usage: \(usage)"
        }
        
        return desc + ")"
    }
}

/// Streaming output item (message, reasoning, etc.)
struct StreamingOutputItem: Decodable, CustomStringConvertible {
    /// Unique identifier for this output item
    let id: String
    
    /// Type of output: "message", "reasoning", "tool_call", etc.
    let type: String
    
    /// Status of the item: "in_progress", "completed", etc.
    let status: String?
    
    /// Array of content items (text, images, etc.)
    let content: [StreamingContentItem]?
    
    /// Role for message items: "user", "assistant", etc.
    let role: String?
    
    /// Provides a readable description of the output item
    var description: String {
        "StreamingOutputItem(id: \"\(id)\", type: \"\(type)\")"
    }
}

/// Content item within an output item
struct StreamingContentItem: Decodable, CustomStringConvertible {
    /// Type of content: "text", "image_url", etc.
    let type: String
    
    /// Text content if present
    let text: String?
    
    /// Provides a readable description of the content item
    var description: String {
        var desc = "StreamingContentItem(type: \"\(type)\""
        
        if let text = text {
            let safeText = text.count > 20 ? "\(text.prefix(20))..." : text
            desc += ", text: \"\(safeText)\""
        }
        
        return desc + ")"
    }
}

/// Streaming item object
struct StreamingItem: Decodable, CustomStringConvertible {
    /// Unique identifier for this item
    let id: String
    
    /// Type of item: "message", "reasoning", "tool_call", etc.
    let type: String
    
    /// Status of the item: "in_progress", "completed", etc.
    let status: String?
    
    /// Array of content items (text, images, etc.)
    let content: [StreamingContentItem]?
    
    /// Role for message items: "user", "assistant", etc.
    let role: String?
    
    // Fields for function/tool calls
    /// Name of the tool or function (for tool_call items)
    let name: String?
    
    /// JSON string of arguments (for tool_call items)
    let arguments: String?
    
    /// ID of the call (for tool_call items)
    let callId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, status, content, role, name, arguments
        case callId = "call_id"
    }
    
    /// Provides a readable description of the item
    var description: String {
        "StreamingItem(id: \"\(id)\", type: \"\(type)\")"
    }
}

/// Content part object
struct StreamingPart: Decodable, CustomStringConvertible {
    /// Type of part: "output_text", etc.
    let type: String
    
    /// Text content if present
    let text: String?
    
    /// Provides a readable description of the part
    var description: String {
        var desc = "StreamingPart(type: \"\(type)\""
        
        if let text = text {
            let safeText = text.count > 20 ? "\(text.prefix(20))..." : text
            desc += ", text: \"\(safeText)\""
        }
        
        return desc + ")"
    }
}

/// Token usage information
struct StreamingUsage: Decodable, CustomStringConvertible {
    /// Number of tokens in the input/prompt
    let inputTokens: Int
    
    /// Number of tokens in the output/completion
    let outputTokens: Int
    
    /// Total number of tokens used (input + output)
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
    
    /// Provides a readable description of the usage
    var description: String {
        "StreamingUsage(in: \(inputTokens), out: \(outputTokens), total: \(totalTokens))"
    }
}
