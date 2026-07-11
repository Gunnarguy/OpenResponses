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

    /// Human-readable display name for the model
    var displayName: String {
        switch id {
        // Latest GPT models (2026)
        case "gpt-5.6":
            return "gpt-5.6"
        case "gpt-5.6-sol":
            return "gpt-5.6-sol"
        case "gpt-5.6-terra":
            return "gpt-5.6-terra"
        case "gpt-5.6-luna":
            return "gpt-5.6-luna"
        case "gpt-5.5":
            return "gpt-5.5"
        case "gpt-5.5-pro":
            return "gpt-5.5-pro"
        case "gpt-5.5-mini":
            return "gpt-5.5-mini"
        case "gpt-5.5-nano":
            return "gpt-5.5-nano"
        case "gpt-5.4":
            return "gpt-5.4"
        case "gpt-5.4-pro":
            return "gpt-5.4-pro"
        case "gpt-5.4-mini":
            return "gpt-5.4-mini"
        case "gpt-5.4-nano":
            return "gpt-5.4-nano"
        case "gpt-5.2":
            return "gpt-5.2"
        case "gpt-5.2-pro":
            return "gpt-5.2-pro"
        case "gpt-5.1":
            return "gpt-5.1"
        case "gpt-5-mini":
            return "gpt-5-mini"
        case "gpt-5-nano":
            return "gpt-5-nano"
        case "gpt-5":
            return "gpt-5"
        case "gpt-5-thinking":
            return "gpt-5-thinking"
        case "gpt-4.1":
            return "gpt-4.1"
        case "gpt-4.1-mini":
            return "gpt-4.1-mini"
        case "gpt-4.1-nano":
            return "gpt-4.1-nano"
        case "gpt-4.1-2025-04-14":
            return "gpt-4.1 (2025-04-14)"

        // Existing GPT models
        case "gpt-4o":
            return "gpt-4o"
        case "gpt-4o-mini":
            return "gpt-4o-mini"
        case "gpt-4o-2024-08-06":
            return "gpt-4o (2024-08-06)"
        case "gpt-4o-mini-2024-07-18":
            return "gpt-4o-mini (2024-07-18)"
        case "computer-use-preview":
            return "computer-use-preview"

        // Reasoning models (o-series)
        case "o3":
            return "o3"
        case "o3-mini":
            return "o3-mini"
        case let model where model.hasPrefix("o1"):
            return model // Keep original formatting with hyphens
        case let model where model.hasPrefix("o3"):
            return model // Keep original formatting with hyphens

        default:
            // For unknown models, return the ID as-is to preserve original formatting
            return id
        }
    }

    /// Whether this is a reasoning model (O-series or GPT-5)
    var isReasoningModel: Bool {
        return id.hasPrefix("o1") || id.hasPrefix("o3") || id.hasPrefix("gpt-5")
    }
}

/// Response from the OpenAI models API endpoint.
struct OpenAIModelsResponse: Codable {
    let object: String
    let data: [OpenAIModel]
}
