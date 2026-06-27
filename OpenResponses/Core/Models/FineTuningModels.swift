import Foundation

/// Represents an OpenAI Fine-Tuning Job.
struct FineTuningJob: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let model: String
    let createdAt: Int
    let fineTunedModel: String?
    let status: String // "validating_files", "queued", "running", "succeeded", "failed", "cancelled"
    let trainingFile: String
    let validationFile: String?
    let trainedTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, object, model, status
        case createdAt = "created_at"
        case fineTunedModel = "fine_tuned_model"
        case trainingFile = "training_file"
        case validationFile = "validation_file"
        case trainedTokens = "trained_tokens"
    }
}

/// Helper structures for fine-tuning dataset formatting.
struct FineTuningConversation: Codable {
    let messages: [FineTuningMessage]
}

struct FineTuningMessage: Codable {
    let role: String // "system", "user", "assistant"
    let content: String
}
