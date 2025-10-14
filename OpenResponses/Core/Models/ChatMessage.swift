import Foundation
import SwiftUI

/// Represents a single message in the chat (user, assistant, or system/error).
struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system  // Used for errors or system notices
    }
    let id: UUID
    let role: Role
    var text: String?
    var images: [UIImage]?  // Any images associated with the message (for assistant outputs)
    var webURLs: [URL]?     // URLs to render as embedded web content
    var webContentURL: [URL]? // Detected URLs in the message content
    var toolsUsed: [String]? // Track which tools were actually used in this message
    /// Live and final token usage for this message (assistant messages only)
    var tokenUsage: TokenUsage?
    /// Code interpreter artifacts (files, logs, data outputs)
    var artifacts: [CodeInterpreterArtifact]?
    /// MCP approval requests pending user decision
    var mcpApprovalRequests: [MCPApprovalRequest]?

    enum CodingKeys: String, CodingKey {
        case id, role, text, images, webURLs, webContentURL, toolsUsed, tokenUsage, artifacts, mcpApprovalRequests
    }

    init(id: UUID = UUID(), role: Role, text: String?, images: [UIImage]? = nil, webURLs: [URL]? = nil, webContentURL: [URL]? = nil, toolsUsed: [String]? = nil, tokenUsage: TokenUsage? = nil, artifacts: [CodeInterpreterArtifact]? = nil, mcpApprovalRequests: [MCPApprovalRequest]? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.images = images
        self.webURLs = webURLs
        self.webContentURL = webContentURL
        self.toolsUsed = toolsUsed
        self.tokenUsage = tokenUsage
        self.artifacts = artifacts
        self.mcpApprovalRequests = mcpApprovalRequests
    }

    // MARK: - Codable Conformance
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(Role.self, forKey: .role)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        
        if let imageData = try container.decodeIfPresent([Data].self, forKey: .images) {
            images = imageData.compactMap { UIImage(data: $0) }
        } else {
            images = nil
        }
        
        if let urlStrings = try container.decodeIfPresent([String].self, forKey: .webURLs) {
            webURLs = urlStrings.compactMap { URL(string: $0) }
        } else {
            webURLs = nil
        }
        
        if let webContentURLStrings = try container.decodeIfPresent([String].self, forKey: .webContentURL) {
            webContentURL = webContentURLStrings.compactMap { URL(string: $0) }
        } else {
            webContentURL = nil
        }
        
        toolsUsed = try container.decodeIfPresent([String].self, forKey: .toolsUsed)
        tokenUsage = try container.decodeIfPresent(TokenUsage.self, forKey: .tokenUsage)
        artifacts = try container.decodeIfPresent([CodeInterpreterArtifact].self, forKey: .artifacts)
        mcpApprovalRequests = try container.decodeIfPresent([MCPApprovalRequest].self, forKey: .mcpApprovalRequests)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(text, forKey: .text)
        
        if let images = images {
            let imageData = images.compactMap { $0.pngData() }
            try container.encode(imageData, forKey: .images)
        }
        
        if let webURLs = webURLs {
            let urlStrings = webURLs.map { $0.absoluteString }
            try container.encode(urlStrings, forKey: .webURLs)
        }
        
        if let webContentURL = webContentURL {
            let webContentURLStrings = webContentURL.map { $0.absoluteString }
            try container.encode(webContentURLStrings, forKey: .webContentURL)
        }
        
        try container.encodeIfPresent(toolsUsed, forKey: .toolsUsed)
        try container.encodeIfPresent(tokenUsage, forKey: .tokenUsage)
        try container.encodeIfPresent(artifacts, forKey: .artifacts)
        try container.encodeIfPresent(mcpApprovalRequests, forKey: .mcpApprovalRequests)
    }
}

/// Captures live estimates and final token usage for a message
struct TokenUsage: Codable {
    /// During streaming: estimated output tokens based on received text
    var estimatedOutput: Int?
    /// Final prompt/input tokens reported by API
    var input: Int?
    /// Final completion/output tokens reported by API
    var output: Int?
    /// Final total tokens reported by API
    var total: Int?
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
    
    // Field for computer_call items - direct action object
    let action: [String: AnyCodable]?
    
    /// Safety checks that need to be acknowledged before proceeding
    let pendingSafetyChecks: [SafetyCheck]?
    
    enum CodingKeys: String, CodingKey {
        case id, type, summary, content, name, arguments, action
        case callId = "call_id"
        case pendingSafetyChecks = "pending_safety_checks"
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

/// Chunking strategy for vector store files
struct ChunkingStrategy: Codable {
    let type: String // "auto" or "static"
    let `static`: StaticChunkingStrategy?
    
    struct StaticChunkingStrategy: Codable {
        let maxChunkSizeTokens: Int // 100-4096
        let chunkOverlapTokens: Int // 0 to maxChunkSizeTokens/2
        
        enum CodingKeys: String, CodingKey {
            case maxChunkSizeTokens = "max_chunk_size_tokens"
            case chunkOverlapTokens = "chunk_overlap_tokens"
        }
    }
    
    static var auto: ChunkingStrategy {
        ChunkingStrategy(type: "auto", static: nil)
    }
    
    static func staticStrategy(maxTokens: Int, overlapTokens: Int) -> ChunkingStrategy {
        ChunkingStrategy(
            type: "static",
            static: StaticChunkingStrategy(
                maxChunkSizeTokens: maxTokens,
                chunkOverlapTokens: overlapTokens
            )
        )
    }
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
    let chunkingStrategy: ChunkingStrategy?
    let attributes: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status, attributes
        case usageBytes = "usage_bytes"
        case createdAt = "created_at"
        case vectorStoreId = "vector_store_id"
        case lastError = "last_error"
        case chunkingStrategy = "chunking_strategy"
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
    /// - "response.mcp_list_tools.added" - MCP server tools list added
    /// - "response.mcp_call.added" - MCP tool call initiated
    /// - "response.mcp_call.done" - MCP tool call completed
    /// - "response.mcp_approval_request.added" - MCP tool call requires approval
    let type: String
    
    /// Sequence number to maintain ordering of events
    let sequenceNumber: Int
    
    /// Full response object, present in some events like "response.created"
    let response: StreamingResponse?
    
    /// Error information for standalone "type":"error" events
    let errorInfo: StreamingError?
    
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
    
    /// Partial image data for image generation events (base64 encoded)
    let partialImageB64: String?
    
    /// Index of the partial image for image generation events
    let partialImageIndex: Int?

    /// Some image generation payload variants include the base64 image under a generic key.
    /// We capture common alternates to improve compatibility across event shapes.
    let imageB64: String? // maps "image"
    let dataB64: String?  // maps "data"
    
    /// Screenshot data for computer use events (base64 encoded)
    let screenshotB64: String?
    
    /// Computer action data for computer use events
    let computerAction: String?

    // Annotation metadata for output_text.annotation.added (e.g., embedded file references)
    let fileId: String?
    let filename: String?
    let containerId: String?
    let annotationIndex: Int?
    
    /// Full annotation payload when provided as a nested object
    /// Some streaming payloads include annotation details under an `annotation` object rather than top-level fields.
    /// We decode it to improve robustness across event variants.
    let annotation: StreamingAnnotation?
    
    // MCP-specific fields
    /// Server label for MCP events
    let serverLabel: String?
    
    /// Tools array for mcp_list_tools events
    let tools: [[String: AnyCodable]]?
    
    /// Tool name for mcp_call and mcp_approval_request events
    let name: String?
    
    /// Arguments for mcp_call and mcp_approval_request events (JSON string)
    let arguments: String?
    
    /// Output from mcp_call events (JSON string)
    let output: String?
    
    /// Error from failed mcp_call events
    let error: String?
    
    /// Approval request ID for mcp_approval_request events
    let approvalRequestId: String?
    
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
        case partialImageB64 = "partial_image_b64"
        case partialImageIndex = "partial_image_index"
        case imageB64 = "image"
        case dataB64 = "data"
        case screenshotB64 = "screenshot_b64"
        case computerAction = "computer_action"
        case fileId = "file_id"
        case filename
        case containerId = "container_id"
        case annotationIndex = "annotation_index"
        case annotation
        case serverLabel = "server_label"
        case tools
        case name
        case arguments
        case output
        case error
        case approvalRequestId = "approval_request_id"
    }
    
    /// Custom decoder to handle polymorphic error field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode standard fields
        type = try container.decode(String.self, forKey: .type)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        response = try container.decodeIfPresent(StreamingResponse.self, forKey: .response)
        outputIndex = try container.decodeIfPresent(Int.self, forKey: .outputIndex)
        itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        contentIndex = try container.decodeIfPresent(Int.self, forKey: .contentIndex)
        delta = try container.decodeIfPresent(String.self, forKey: .delta)
        item = try container.decodeIfPresent(StreamingItem.self, forKey: .item)
        part = try container.decodeIfPresent(StreamingPart.self, forKey: .part)
        partialImageB64 = try container.decodeIfPresent(String.self, forKey: .partialImageB64)
        partialImageIndex = try container.decodeIfPresent(Int.self, forKey: .partialImageIndex)
        imageB64 = try container.decodeIfPresent(String.self, forKey: .imageB64)
        dataB64 = try container.decodeIfPresent(String.self, forKey: .dataB64)
        screenshotB64 = try container.decodeIfPresent(String.self, forKey: .screenshotB64)
        computerAction = try container.decodeIfPresent(String.self, forKey: .computerAction)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        containerId = try container.decodeIfPresent(String.self, forKey: .containerId)
        annotationIndex = try container.decodeIfPresent(Int.self, forKey: .annotationIndex)
        annotation = try container.decodeIfPresent(StreamingAnnotation.self, forKey: .annotation)
        serverLabel = try container.decodeIfPresent(String.self, forKey: .serverLabel)
        tools = try container.decodeIfPresent([[String: AnyCodable]].self, forKey: .tools)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        arguments = try container.decodeIfPresent(String.self, forKey: .arguments)
        output = try container.decodeIfPresent(String.self, forKey: .output)
        approvalRequestId = try container.decodeIfPresent(String.self, forKey: .approvalRequestId)
        
        // Handle polymorphic error field
        // Try to decode as StreamingError object first (for standalone error events)
        if let errorObj = try? container.decodeIfPresent(StreamingError.self, forKey: .error) {
            errorInfo = errorObj
            error = nil
        } else {
            // Fall back to string (for MCP errors)
            errorInfo = nil
            error = try container.decodeIfPresent(String.self, forKey: .error)
        }
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
        
        if let serverLabel = serverLabel {
            desc += ", serverLabel: \"\(serverLabel)\""
        }
        
        if let name = name {
            desc += ", name: \"\(name)\""
        }
        
        return desc + ")"
    }
}

/// Represents a nested annotation object attached to an output_text part
/// This includes file citation metadata for items produced inside tool containers (e.g., code interpreter).
struct StreamingAnnotation: Decodable {
    let type: String?
    let startIndex: Int?
    let endIndex: Int?
    let fileId: String?
    let filename: String?
    let containerId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case startIndex = "start_index"
        case endIndex = "end_index"
        case fileId = "file_id"
        case filename
        case containerId = "container_id"
    }
}

/// Streaming response object with metadata
struct StreamingResponse: Decodable, CustomStringConvertible {
    /// Unique identifier for this response
    let id: String
    
    /// Status of the response: "queued", "in_progress", "completed", "failed"
    let status: String?
    
    /// Array of output items (messages, reasoning, etc.)
    let output: [StreamingOutputItem]?
    
    /// Token usage statistics (only in final response.completed event)
    let usage: StreamingUsage?
    
    /// Error information when status is "failed"
    let error: StreamingError?
    
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

/// Error information in streaming responses
struct StreamingError: Decodable {
    /// Error code
    let code: String?
    
    /// Error message
    let message: String
}

/// MCP tool call error information
struct MCPToolError: Decodable {
    /// Error type (e.g., "http_error", "timeout", etc.)
    let type: String
    
    /// HTTP status code or error code
    let code: Int?
    
    /// Error message
    let message: String
}

/// Streaming output item (message, reasoning, tool_call, mcp_list_tools, mcp_call, mcp_approval_request, etc.)
struct StreamingOutputItem: Decodable, CustomStringConvertible {
    /// Unique identifier for this output item
    let id: String
    
    /// Type of output: "message", "reasoning", "tool_call", "mcp_list_tools", "mcp_call", "mcp_approval_request", etc.
    let type: String
    
    /// Status of the item: "in_progress", "completed", etc.
    let status: String?
    
    /// Array of content items (text, images, etc.)
    let content: [StreamingContentItem]?
    
    /// Role for message items: "user", "assistant", etc.
    let role: String?
    
    // MCP-specific fields
    /// Server label for MCP items
    let serverLabel: String?
    
    /// Tools array for mcp_list_tools items
    let tools: [[String: AnyCodable]]?
    
    /// Tool name for mcp_call and mcp_approval_request items
    let name: String?
    
    /// Arguments for mcp_call and mcp_approval_request items (JSON string)
    let arguments: String?
    
    /// Output from mcp_call items (JSON string)
    let output: String?
    
    /// Error from failed mcp_call items (structured error object)
    let error: MCPToolError?
    
    /// Approval request ID for linking approval responses
    let approvalRequestId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, status, content, role
        case serverLabel = "server_label"
        case tools
        case name
        case arguments
        case output
        case error
        case approvalRequestId = "approval_request_id"
    }
    
    /// Provides a readable description of the output item
    var description: String {
        var desc = "StreamingOutputItem(id: \"\(id)\", type: \"\(type)\""
        if let serverLabel = serverLabel {
            desc += ", serverLabel: \"\(serverLabel)\""
        }
        if let name = name {
            desc += ", name: \"\(name)\""
        }
        return desc + ")"
    }
}

/// Content item within an output item
struct StreamingContentItem: Decodable, CustomStringConvertible {
    /// Type of content: "text", "image_url", etc.
    let type: String
    
    /// Text content if present
    let text: String?
    
    /// Image URL for screenshot or media content if present
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL = "image_url"
    }

    /// Provides a readable description of the content item
    var description: String {
        var desc = "StreamingContentItem(type: \"\(type)\""
        
        if let text = text {
            let safeText = text.count > 20 ? "\(text.prefix(20))..." : text
            desc += ", text: \"\(safeText)\""
        }
        if let imageURL = imageURL {
            desc += ", image_url: \"\(imageURL)\""
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
    
    // Fields for computer_call items
    /// Action object for computer use calls (contains type, x, y, etc.)
    let action: [String: AnyCodable]?
    
    /// Safety checks that need to be acknowledged before proceeding
    let pendingSafetyChecks: [SafetyCheck]?
    
    // Fields for MCP approval request items
    /// Server label for MCP approval requests
    let serverLabel: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, status, content, role, name, arguments, action
        case callId = "call_id"
        case pendingSafetyChecks = "pending_safety_checks"
        case serverLabel = "server_label"
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

/// Represents a safety check that needs to be acknowledged
struct SafetyCheck: Decodable, CustomStringConvertible {
    /// Unique identifier for this safety check
    let id: String
    
    /// Type of safety check: "malicious_instructions", "irrelevant_domain", "sensitive_domain"
    let code: String
    
    /// Human-readable message describing the safety concern
    let message: String
    
    /// Provides a readable description of the safety check
    var description: String {
        "SafetyCheck(id: \"\(id)\", code: \"\(code)\", message: \"\(message)\")"
    }
}

/// Represents an MCP approval request waiting for user decision
struct MCPApprovalRequest: Identifiable, Codable {
    let id: String                    // approval_request_id
    let toolName: String              // name of the tool being called
    let serverLabel: String           // server label (e.g., "Dropbox", "notion")
    let arguments: String             // JSON string of arguments
    var status: ApprovalStatus        // pending, approved, rejected
    var reason: String?               // Optional reason for decision
    
    enum ApprovalStatus: String, Codable {
        case pending
        case approved
        case rejected
    }
}
