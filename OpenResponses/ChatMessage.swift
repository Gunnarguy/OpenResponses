import Foundation
import SwiftUI

/// Represents a single message in the chat (user, assistant, or system/error).
struct ChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
        case system  // Used for errors or system notices
    }
    let id = UUID()
    let role: Role
    let text: String?
    var images: [UIImage]?  // Any images associated with the message (for assistant outputs)
}

/// Codable models for decoding OpenAI /v1/responses API JSON.
struct OpenAIResponse: Decodable {
    let id: String                // The response ID (used for continuity in follow-ups)
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
