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
    var webSearchMode: String
    var webSearchInstructions: String
    var webSearchMaxPages: Int
    var webSearchCrawlDepth: Int
    var enableCodeInterpreter: Bool
    var codeInterpreterContainerType: String
    var codeInterpreterPreloadFileIds: String?
    var enableImageGeneration: Bool
    var enableFileSearch: Bool
    var selectedVectorStoreIds: String?
    
    // File Search Advanced Options
    var fileSearchMaxResults: Int? // 1-50
    var fileSearchRanker: String? // "auto" or "default-2024-08-21"
    var fileSearchScoreThreshold: Double? // 0.0-1.0
    
    var enableMCPTool: Bool
    var enableCustomTool: Bool
    var enableComputerUse: Bool
    var enableNotionIntegration: Bool = true
    var enableAppleIntegrations: Bool = true

    // MARK: - MCP Tool Parameters
    var mcpServerLabel: String
    var mcpServerURL: String
    var mcpHeaders: String // Will be migrated to keychain storage
    var mcpRequireApproval: String
    var mcpAllowedTools: String
    var mcpAuthHeaderKey: String // e.g., "Authorization", "X-Auth-Token"
    var mcpKeepAuthInHeaders: Bool // If true and using Authorization, also send as header in addition to top-level
    
    // MARK: - MCP Connector Support
    var mcpConnectorId: String? // e.g., "connector_dropbox", "connector_gmail"
    var mcpIsConnector: Bool // True if using a connector, false if using a remote server
    
    // MARK: - Secure MCP Auth Helper
    /// Gets the MCP headers, preferring secure keychain storage over the mcpHeaders string
    var secureMCPHeaders: [String: String] {
        get {
            // First try to load from keychain using server label as key
            if !mcpServerLabel.isEmpty,
               let authData = KeychainService.shared.load(forKey: "mcp_manual_\(mcpServerLabel)"),
               let authDict = try? JSONSerialization.jsonObject(with: Data(authData.utf8)) as? [String: String] {
                return authDict
            }
            
            // Fall back to parsing mcpHeaders string (legacy)
            if let data = mcpHeaders.data(using: .utf8),
               let parsedHeaders = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                return parsedHeaders
            }
            
            return [:]
        }
        set {
            // Save to keychain if we have a server label
            if !mcpServerLabel.isEmpty {
                if let authData = try? JSONSerialization.data(withJSONObject: newValue),
                   let authString = String(data: authData, encoding: .utf8) {
                    KeychainService.shared.save(value: authString, forKey: "mcp_manual_\(mcpServerLabel)")
                    // Clear the old string format for security
                    mcpHeaders = ""
                }
            }
        }
    }

    // MARK: - Custom Tool Parameters
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
    var includeComputerUseOutput: Bool = false
    
    // Behavior Controls
    /// When true, the app will not apply any helper heuristics around computer-use actions
    /// (no pre-navigation URL derivation, no intent-aware search submission, no click-by-text overrides).
    /// The agent will execute exactly the model's actions. Useful for purists and debugging.
    var ultraStrictComputerUse: Bool = false
    
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
    case enableWebSearch, webSearchMode, webSearchInstructions, webSearchMaxPages, webSearchCrawlDepth
    case enableCodeInterpreter, codeInterpreterContainerType, codeInterpreterPreloadFileIds, enableImageGeneration, enableFileSearch, selectedVectorStoreIds
    case fileSearchMaxResults, fileSearchRanker, fileSearchScoreThreshold
    case enableComputerUse
    case enableNotionIntegration, enableAppleIntegrations
    case enableMCPTool, mcpServerLabel, mcpServerURL, mcpHeaders, mcpRequireApproval, mcpAllowedTools, mcpAuthHeaderKey, mcpKeepAuthInHeaders
    case mcpConnectorId, mcpIsConnector
    case enableCustomTool, customToolName, customToolDescription, customToolParametersJSON, customToolExecutionType, customToolWebhookURL
        case userLocationCity, userLocationCountry, userLocationRegion, userLocationTimezone
        case backgroundMode, maxOutputTokens, maxToolCalls, parallelToolCalls, serviceTier, topLogprobs, topP, truncationStrategy, userIdentifier
        case textFormatType, jsonSchemaName, jsonSchemaDescription, jsonSchemaStrict, jsonSchemaContent
    case includeCodeInterpreterOutputs, includeComputerCallOutput, includeFileSearchResults, includeWebSearchResults, includeInputImageUrls, includeOutputLogprobs, includeReasoningContent, includeComputerUseOutput
    case ultraStrictComputerUse
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
            webSearchMode: "default",
            webSearchInstructions: "",
            webSearchMaxPages: 0,
            webSearchCrawlDepth: 0,
            enableCodeInterpreter: true,
            codeInterpreterContainerType: "auto",
            codeInterpreterPreloadFileIds: "",
            enableImageGeneration: true,
            enableFileSearch: false,
            selectedVectorStoreIds: "",
            fileSearchMaxResults: nil,
            fileSearchRanker: nil,
            fileSearchScoreThreshold: nil,
            enableMCPTool: true,
            enableCustomTool: false,
            enableComputerUse: false,
            enableNotionIntegration: true,
            enableAppleIntegrations: true,
            mcpServerLabel: "",
            mcpServerURL: "",
            mcpHeaders: "",
            mcpRequireApproval: "prompt",
            mcpAllowedTools: "",
            mcpAuthHeaderKey: "Authorization",
            mcpKeepAuthInHeaders: false,
            mcpConnectorId: nil,
            mcpIsConnector: false,
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
            truncationStrategy: "auto", // Changed from "disabled" - enables automatic context management
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
            includeComputerUseOutput: false,
            ultraStrictComputerUse: false,
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
