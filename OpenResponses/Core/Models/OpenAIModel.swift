import Foundation

/// Represents an OpenAI model from the models API endpoint.
struct OpenAIModel: Codable, Identifiable {
    let id: String
    let object: String
    let created: Int
    let ownedBy: String

    enum CodingKeys: String, CodingKey {
        case id, object, created
        case ownedBy = "owned_by"
    }

    /// Display name for the model: the API ID as returned, including dated snapshots.
    var displayName: String { id }

    /// Whether the model accepts reasoning effort.
    var isReasoningModel: Bool {
        ModelCompatibilityService.shared.getCapabilities(for: id)?.supportsReasoningEffort == true
    }
}

/// Response from the OpenAI models API endpoint.
struct OpenAIModelsResponse: Codable {
    let object: String
    let data: [OpenAIModel]
}
