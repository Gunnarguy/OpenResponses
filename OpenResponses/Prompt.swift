import Foundation

/// Represents a user-saved preset for all settings in the app.
/// This struct captures the entire state of the SettingsView.
struct Prompt: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var description: String
    
    // Basic Settings
    var openAIModel: String
    var reasoningEffort: String
    var temperature: Double
    var systemInstructions: String
    var developerInstructions: String
    
    // Published Prompt Settings
    var enablePublishedPrompt: Bool
    var publishedPromptId: String
    var publishedPromptVersion: String
    
    // Tool Toggles
    var enableWebSearch: Bool
    var enableCodeInterpreter: Bool
    var enableImageGeneration: Bool
    var enableFileSearch: Bool
    var enableCalculator: Bool
    var enableMCPTool: Bool
    var enableCustomTool: Bool
    
    // Response Settings
    var enableStreaming: Bool
    var maxOutputTokens: Int
    var presencePenalty: Double
    var frequencyPenalty: Double
    
    // Tool Configuration
    var toolChoice: String // "auto", "none", or specific tool name
    var metadata: String? // JSON string for metadata
    
    // Advanced API Settings
    var backgroundMode: Bool
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
    
    // Advanced Reasoning
    var reasoningSummary: String
    
    // MCP Tool
    var mcpServerLabel: String
    var mcpServerURL: String
    var mcpHeaders: String
    var mcpRequireApproval: String
    
    // Custom Tool
    var customToolName: String
    var customToolDescription: String
    
    // Include Parameters
    var includeCodeInterpreterOutputs: Bool
    var includeComputerCallOutput: Bool
    var includeFileSearchResults: Bool
    var includeInputImageUrls: Bool
    var includeOutputLogprobs: Bool
    var includeReasoningContent: Bool
    
    // File Search
    var selectedVectorStoreIds: String?
    
    // Web Search
    var searchContextSize: String?
    var userLocationCity: String?
    var userLocationCountry: String?
    var userLocationRegion: String?
    var userLocationTimezone: String?

    // Note: Detailed tool configurations like web search are not stored here
    // as they are less likely to change per-prompt and would bloat the model.
    // They will continue to be read from UserDefaults directly.
    
    static func defaultPrompt() -> Prompt {
        return Prompt(
            name: "Default",
            description: "The default settings for the application.",
            openAIModel: "gpt-4o",
            reasoningEffort: "medium",
            temperature: 1.0,
            systemInstructions: "You are a helpful assistant.",
            developerInstructions: "",
            enablePublishedPrompt: false,
            publishedPromptId: "",
            publishedPromptVersion: "1",
            enableWebSearch: true,
            enableCodeInterpreter: true,
            enableImageGeneration: true,
            enableFileSearch: false,
            enableCalculator: true,
            enableMCPTool: false,
            enableCustomTool: false,
            enableStreaming: true,
            maxOutputTokens: 0,
            presencePenalty: 0.0,
            frequencyPenalty: 0.0,
            toolChoice: "auto",
            metadata: nil,
            backgroundMode: false,
            maxToolCalls: 0,
            parallelToolCalls: true,
            serviceTier: "auto",
            topLogprobs: 0,
            topP: 1.0,
            truncationStrategy: "auto",
            userIdentifier: "",
            textFormatType: "auto",
            jsonSchemaName: "",
            jsonSchemaDescription: "",
            jsonSchemaStrict: false,
            jsonSchemaContent: "",
            reasoningSummary: "",
            mcpServerLabel: "",
            mcpServerURL: "",
            mcpHeaders: "",
            mcpRequireApproval: "never",
            customToolName: "",
            customToolDescription: "",
            includeCodeInterpreterOutputs: true,
            includeComputerCallOutput: false,
            includeFileSearchResults: true,
            includeInputImageUrls: true,
            includeOutputLogprobs: false,
            includeReasoningContent: false,
            selectedVectorStoreIds: nil,
            searchContextSize: "medium",
            userLocationCity: nil,
            userLocationCountry: nil,
            userLocationRegion: nil,
            userLocationTimezone: nil
        )
    }
}
