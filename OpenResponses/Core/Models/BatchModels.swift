import Foundation

/// Represents an OpenAI Batch Job.
struct BatchJob: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let endpoint: String
    let inputFileId: String
    let outputFileId: String?
    let errorFileId: String?
    let status: String // "validating", "failed", "in_progress", "completed", "cancelling", "cancelled"
    let createdAt: Int
    let completedAt: Int?
    let failedAt: Int?
    let requestCounts: BatchRequestCounts?
    
    enum CodingKeys: String, CodingKey {
        case id, object, endpoint, status
        case inputFileId = "input_file_id"
        case outputFileId = "output_file_id"
        case errorFileId = "error_file_id"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case failedAt = "failed_at"
        case requestCounts = "request_counts"
    }
}

/// Represents the request counts in a batch job.
struct BatchRequestCounts: Codable, Hashable {
    let total: Int
    let completed: Int
    let failed: Int
}

/// Model representing a single line in a JSONL batch input file.
struct BatchInputLine: Codable {
    let customId: String
    let method: String // "POST"
    let url: String // "/v1/chat/completions" or "/v1/responses"
    let body: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case method, url, body
        case customId = "custom_id"
    }
}
