import Foundation

/// Represents a user-saved preset for all settings in the app.
/// This struct captures the entire state of the SettingsView.
struct Prompt: Codable, Identifiable, Equatable {
    // MARK: - Properties
    var name: String
    
    // Model and Generation
    var openAIModel: String
    var reasoningEffort: String
    var reasoningSummary: String // Added
    var temperature: Double
    
    // Instructions
    var systemInstructions: String
    var developerInstructions: String
    
    // Tools
    var enableWebSearch: Bool
    var enableCodeInterpreter: Bool
    var enableImageGeneration: Bool
    var enableFileSearch: Bool
    var selectedVectorStoreIds: String? // Added
    // Computer Use (Preview) removed
    
    // MCP Tool
    var enableMCPTool: Bool
    var mcpServerLabel: String
    var mcpServerURL: String
    var mcpHeaders: String
    var mcpRequireApproval: String
    // Comma-separated list of MCP tools the model is allowed to call
    var mcpAllowedTools: String

    // Custom Tool
    var enableCustomTool: Bool
    var customToolName: String
    var customToolDescription: String
    // Advanced Custom Tool Configuration
    // JSON Schema string that defines the parameters for the custom function tool
    var customToolParametersJSON: String
    // How the app executes the custom function tool locally: "echo", "calculator", or "webhook"
    var customToolExecutionType: String
    // Optional webhook URL for executionType == "webhook"
    var customToolWebhookURL: String
    
    // Web Search Location
    var userLocationCity: String?
    var userLocationCountry: String?
    var userLocationRegion: String?
    var userLocationTimezone: String?
    
    // Advanced API
    var backgroundMode: Bool
    var maxOutputTokens: Int
    var maxToolCalls: Int
    var parallelToolCalls: Bool
    var serviceTier: String
    var topLogprobs: Int
    var topP: Double
    var truncationStrategy: String
    var userIdentifier: String
    
    // Text Formatting
    var textFormatType: String
    var jsonSchemaName: String
    var jsonSchemaDescription: String
    var jsonSchemaStrict: Bool
    var jsonSchemaContent: String
    
    // Advanced Includes
    var includeCodeInterpreterOutputs: Bool
    var includeComputerCallOutput: Bool
    var includeFileSearchResults: Bool
    var includeWebSearchResults: Bool
    var includeInputImageUrls: Bool
    var includeOutputLogprobs: Bool
    var includeReasoningContent: Bool
    
    // Streaming and Published Prompts
    var enableStreaming: Bool
    var enablePublishedPrompt: Bool
    var publishedPromptId: String
    var publishedPromptVersion: String
    
    // Misc
    var toolChoice: String
    var metadata: String?
    var searchContextSize: String?
    
    // Input Modalities (audio removed)
    
    /// A flag to indicate if this prompt is a saved preset.
    /// This is a runtime-only property and is not persisted.
    var isPreset: Bool = false
    
    // MARK: - Identifiable
    var id: UUID = UUID()
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        // Explicitly list all properties to be encoded/decoded
        case name, openAIModel, reasoningEffort, reasoningSummary, temperature, systemInstructions, developerInstructions
    case enableWebSearch, enableCodeInterpreter, enableImageGeneration, enableFileSearch, selectedVectorStoreIds
    // enableComputerUse removed
    case enableMCPTool, mcpServerLabel, mcpServerURL, mcpHeaders, mcpRequireApproval, mcpAllowedTools
    case enableCustomTool, customToolName, customToolDescription, customToolParametersJSON, customToolExecutionType, customToolWebhookURL
        case userLocationCity, userLocationCountry, userLocationRegion, userLocationTimezone
        case backgroundMode, maxOutputTokens, maxToolCalls, parallelToolCalls, serviceTier, topLogprobs, topP, truncationStrategy, userIdentifier
        case textFormatType, jsonSchemaName, jsonSchemaDescription, jsonSchemaStrict, jsonSchemaContent
        case includeCodeInterpreterOutputs, includeComputerCallOutput, includeFileSearchResults, includeWebSearchResults, includeInputImageUrls, includeOutputLogprobs, includeReasoningContent
        case enableStreaming, enablePublishedPrompt, publishedPromptId, publishedPromptVersion
        case toolChoice, metadata, searchContextSize
        case id // Make sure 'id' is included
        // 'isPreset' is intentionally omitted from Codable to prevent it from being persisted.
    }
    
    // MARK: - Default Prompt
    static func defaultPrompt() -> Prompt {
        return Prompt(
            name: "Default",
            openAIModel: "gpt-4o",
            reasoningEffort: "medium",
            reasoningSummary: "", // Added
            temperature: 1.0,
            systemInstructions: "You are a helpful assistant.",
            developerInstructions: "",
            enableWebSearch: true,
            enableCodeInterpreter: true,
            enableImageGeneration: true,
            enableFileSearch: false,
            selectedVectorStoreIds: nil, // Added
            enableMCPTool: false,
            mcpServerLabel: "paypal",
            mcpServerURL: "https://mcp.paypal.com/sse",
            mcpHeaders: "{\"Authorization\": \"Bearer s\"}",
            mcpRequireApproval: "always",
            mcpAllowedTools: "",
            enableCustomTool: false,
            customToolName: "custom_tool_placeholder",
            customToolDescription: "A placeholder for a custom tool.",
            customToolParametersJSON: "{\n  \"type\": \"object\",\n  \"properties\": {},\n  \"additionalProperties\": true\n}",
            customToolExecutionType: "echo",
            customToolWebhookURL: "",
            userLocationCity: nil,
            userLocationCountry: nil,
            userLocationRegion: nil,
            userLocationTimezone: nil,
            backgroundMode: false,
            maxOutputTokens: 0,
            maxToolCalls: 0,
            parallelToolCalls: true,
            serviceTier: "auto",
            topLogprobs: 0,
            topP: 1.0,
            truncationStrategy: "disabled",
            userIdentifier: "",
            textFormatType: "text",
            jsonSchemaName: "",
            jsonSchemaDescription: "",
            jsonSchemaStrict: false,
            jsonSchemaContent: "",
            includeCodeInterpreterOutputs: false,
            includeComputerCallOutput: false,
            includeFileSearchResults: false,
            includeWebSearchResults: false,
            includeInputImageUrls: false,
            includeOutputLogprobs: false,
            includeReasoningContent: false,
            enableStreaming: true,
            enablePublishedPrompt: false,
            publishedPromptId: "",
            publishedPromptVersion: "1",
            toolChoice: "auto",
            metadata: nil,
            searchContextSize: nil,
            isPreset: false // Default is not a preset
        )
    }
}
