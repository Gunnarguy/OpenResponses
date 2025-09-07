import Foundation

/// Service for managing model compatibility with tools and parameters
class ModelCompatibilityService {
    
    /// Represents a tool's compatibility and usage status
    struct ToolCompatibility {
        let name: String
        let isSupported: Bool
        let isEnabled: Bool
        let isUsed: Bool
        let supportedModels: [String]
        let restrictions: [String]
        let description: String
    }
    
    /// Represents parameter compatibility for a model
    struct ParameterCompatibility {
        let name: String
        let isSupported: Bool
        let supportedModels: [String]
        let defaultValue: Any?
        let restrictions: [String]
    }
    
    /// Model capability information
    struct ModelCapabilities {
        let modelId: String
        let supportedTools: [String]
        let supportedParameters: [String]
        let maxTokens: Int?
        let supportsStreaming: Bool
        let supportsReasoningEffort: Bool
        let supportsTemperature: Bool
        let category: ModelCategory
    }
    
    enum ModelCategory {
        case reasoning // o-series models
        case standard // gpt-4, gpt-3.5
        case latest // gpt-5, gpt-4.1
        case preview // experimental models
    }
    
    static let shared = ModelCompatibilityService()
    private init() {}
    
    // MARK: - Model Capabilities Database
    
    private let modelCapabilities: [String: ModelCapabilities] = [
        // O-series (Reasoning) models
        "o1-preview": ModelCapabilities(
            modelId: "o1-preview",
            supportedTools: ["code_interpreter", "file_search"],
            supportedParameters: ["reasoning_effort", "max_output_tokens", "truncation", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 32768,
            supportsStreaming: false,
            supportsReasoningEffort: true,
            supportsTemperature: false,
            category: .reasoning
        ),
        "o1-mini": ModelCapabilities(
            modelId: "o1-mini",
            supportedTools: ["code_interpreter", "file_search"],
            supportedParameters: ["reasoning_effort", "max_output_tokens", "truncation", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 65536,
            supportsStreaming: false,
            supportsReasoningEffort: true,
            supportsTemperature: false,
            category: .reasoning
        ),
        "o3": ModelCapabilities(
            modelId: "o3",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview"],
            supportedParameters: ["reasoning_effort", "max_output_tokens", "truncation", "parallel_tool_calls", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 200000,
            supportsStreaming: true,
            supportsReasoningEffort: true,
            supportsTemperature: false,
            category: .reasoning
        ),
        "o3-mini": ModelCapabilities(
            modelId: "o3-mini",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview"],
            supportedParameters: ["reasoning_effort", "max_output_tokens", "truncation", "parallel_tool_calls", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 200000,
            supportsStreaming: true,
            supportsReasoningEffort: true,
            supportsTemperature: false,
            category: .reasoning
        ),
        
        // GPT-4 series models
        "gpt-4o": ModelCapabilities(
            modelId: "gpt-4o",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview", "image_generation", "computer_use_preview"],
            supportedParameters: ["temperature", "top_p", "max_output_tokens", "parallel_tool_calls", "truncation", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 16384,
            supportsStreaming: true,
            supportsReasoningEffort: false,
            supportsTemperature: true,
            category: .standard
        ),
        "gpt-4o-mini": ModelCapabilities(
            modelId: "gpt-4o-mini",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview", "image_generation"],
            supportedParameters: ["temperature", "top_p", "max_output_tokens", "parallel_tool_calls", "truncation", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 16384,
            supportsStreaming: true,
            supportsReasoningEffort: false,
            supportsTemperature: true,
            category: .standard
        ),
        "gpt-4-turbo": ModelCapabilities(
            modelId: "gpt-4-turbo",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview", "image_generation"],
            supportedParameters: ["temperature", "top_p", "max_output_tokens", "parallel_tool_calls", "truncation", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 4096,
            supportsStreaming: true,
            supportsReasoningEffort: false,
            supportsTemperature: true,
            category: .standard
        ),
        
        // GPT-5/4.1 series
        "gpt-5": ModelCapabilities(
            modelId: "gpt-5",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview", "image_generation", "computer_use_preview"],
            supportedParameters: ["temperature", "top_p", "max_output_tokens", "parallel_tool_calls", "truncation", "reasoning_effort", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 32768,
            supportsStreaming: true,
            supportsReasoningEffort: true,
            supportsTemperature: true,
            category: .latest
        ),
        "gpt-4.1-2025-04-14": ModelCapabilities(
            modelId: "gpt-4.1-2025-04-14",
            supportedTools: ["code_interpreter", "file_search", "web_search_preview", "image_generation", "computer_use_preview"],
            supportedParameters: ["temperature", "top_p", "max_output_tokens", "parallel_tool_calls", "truncation", "reasoning_effort", "max_tool_calls", "service_tier", "top_logprobs", "response_format"],
            maxTokens: 32768,
            supportsStreaming: true,
            supportsReasoningEffort: true,
            supportsTemperature: true,
            category: .latest
        )
    ]
    
    // MARK: - Public API
    
    /// Get capabilities for a specific model
    func getCapabilities(for modelId: String) -> ModelCapabilities? {
        return modelCapabilities[modelId]
    }
    
    /// Check if a tool is supported by a model
    func isToolSupported(_ tool: String, for modelId: String, isStreaming: Bool = false) -> Bool {
        guard let capabilities = modelCapabilities[modelId] else {
            // Fallback logic for unknown models
            return fallbackToolSupport(tool, for: modelId, isStreaming: isStreaming)
        }
        
        let isSupported = capabilities.supportedTools.contains(tool)
        
        // Special cases
        if tool == "image_generation" && isStreaming {
            return false // Image generation not supported in streaming mode
        }
        
        return isSupported
    }
    
    /// Check if a parameter is supported by a model
    func isParameterSupported(_ parameter: String, for modelId: String) -> Bool {
        guard let capabilities = modelCapabilities[modelId] else {
            return fallbackParameterSupport(parameter, for: modelId)
        }
        
        return capabilities.supportedParameters.contains(parameter)
    }
    
    /// Get filtered tools based on model compatibility and user settings
    func getCompatibleTools(for modelId: String, prompt: Prompt, isStreaming: Bool = false) -> [ToolCompatibility] {
        var tools: [ToolCompatibility] = []
        
        // Web Search
        tools.append(ToolCompatibility(
            name: "web_search_preview",
            isSupported: isToolSupported("web_search_preview", for: modelId, isStreaming: isStreaming),
            isEnabled: prompt.enableWebSearch,
            isUsed: prompt.enableWebSearch && isToolSupported("web_search_preview", for: modelId, isStreaming: isStreaming),
            supportedModels: getModelsSupporting("web_search_preview"),
            restrictions: [],
            description: "Search the web for current information"
        ))
        
        // Code Interpreter
        tools.append(ToolCompatibility(
            name: "code_interpreter",
            isSupported: isToolSupported("code_interpreter", for: modelId, isStreaming: isStreaming),
            isEnabled: prompt.enableCodeInterpreter,
            isUsed: prompt.enableCodeInterpreter && isToolSupported("code_interpreter", for: modelId, isStreaming: isStreaming),
            supportedModels: getModelsSupporting("code_interpreter"),
            restrictions: [],
            description: "Execute Python code in a secure environment"
        ))
        
        // Image Generation
        let imageGenRestrictions = isStreaming ? ["Disabled in streaming mode"] : []
        tools.append(ToolCompatibility(
            name: "image_generation",
            isSupported: isToolSupported("image_generation", for: modelId, isStreaming: isStreaming),
            isEnabled: prompt.enableImageGeneration,
            isUsed: prompt.enableImageGeneration && isToolSupported("image_generation", for: modelId, isStreaming: isStreaming),
            supportedModels: getModelsSupporting("image_generation"),
            restrictions: imageGenRestrictions,
            description: "Generate images from text descriptions"
        ))
        
        // File Search
        tools.append(ToolCompatibility(
            name: "file_search",
            isSupported: isToolSupported("file_search", for: modelId, isStreaming: isStreaming),
            isEnabled: prompt.enableFileSearch,
            isUsed: prompt.enableFileSearch && isToolSupported("file_search", for: modelId, isStreaming: isStreaming),
            supportedModels: getModelsSupporting("file_search"),
            restrictions: [],
            description: "Search through uploaded documents and files"
        ))
        
        // Calculator
        tools.append(ToolCompatibility(
            name: "calculator",
            isSupported: true, // Calculator is a basic function, supported by all models
            isEnabled: prompt.enableCalculator,
            isUsed: prompt.enableCalculator,
            supportedModels: Array(modelCapabilities.keys),
            restrictions: [],
            description: "Perform mathematical calculations"
        ))
        
        // Computer Use (Preview)
        tools.append(ToolCompatibility(
            name: "computer_use_preview",
            isSupported: isToolSupported("computer_use_preview", for: modelId, isStreaming: isStreaming),
            isEnabled: false, // Not exposed in current UI, but check compatibility
            isUsed: false,
            supportedModels: getModelsSupporting("computer_use_preview"),
            restrictions: ["Preview feature"],
            description: "Control a virtual computer environment"
        ))
        
        return tools
    }
    
    /// Get parameter compatibility information
    func getParameterCompatibility(for modelId: String) -> [ParameterCompatibility] {
        guard let capabilities = modelCapabilities[modelId] else {
            return []
        }
        
        var parameters: [ParameterCompatibility] = []
        
        // Temperature
        parameters.append(ParameterCompatibility(
            name: "temperature",
            isSupported: capabilities.supportsTemperature,
            supportedModels: getModelsSupporting("temperature"),
            defaultValue: 1.0,
            restrictions: capabilities.supportsTemperature ? [] : ["Not supported by reasoning models"]
        ))
        
        // Reasoning Effort
        parameters.append(ParameterCompatibility(
            name: "reasoning_effort",
            isSupported: capabilities.supportsReasoningEffort,
            supportedModels: getModelsSupporting("reasoning_effort"),
            defaultValue: "medium",
            restrictions: []
        ))
        
        // Max Output Tokens
        parameters.append(ParameterCompatibility(
            name: "max_output_tokens",
            isSupported: capabilities.supportedParameters.contains("max_output_tokens"),
            supportedModels: getModelsSupporting("max_output_tokens"),
            defaultValue: capabilities.maxTokens,
            restrictions: capabilities.maxTokens != nil ? ["Max: \(capabilities.maxTokens!)"] : []
        ))
        
        return parameters
    }
    
    // MARK: - Private Helpers
    
    private func fallbackToolSupport(_ tool: String, for modelId: String, isStreaming: Bool) -> Bool {
        // Fallback logic for models not in our database
        switch tool {
        case "code_interpreter":
            return modelId.starts(with: "gpt-4") || modelId.starts(with: "o") || modelId.starts(with: "gpt-5")
        case "image_generation":
            return !isStreaming && modelId.starts(with: "gpt-4")
        case "web_search_preview", "file_search":
            return true
        default:
            return false
        }
    }
    
    private func fallbackParameterSupport(_ parameter: String, for modelId: String) -> Bool {
        switch parameter {
        case "temperature", "top_p":
            return !modelId.starts(with: "o1") // o1 models don't support temperature
        case "reasoning_effort":
            return modelId.starts(with: "o") || modelId.starts(with: "gpt-5") || modelId.contains("gpt-4.1")
        case "max_tool_calls", "service_tier", "top_logprobs":
            return true // Generally supported by most models
        case "background_mode":
            return false // This is typically not supported by most models
        default:
            return true
        }
    }
    
    private func getModelsSupporting(_ feature: String) -> [String] {
        switch feature {
        case "web_search_preview":
            return modelCapabilities.compactMap { key, value in
                value.supportedTools.contains("web_search_preview") ? key : nil
            }
        case "code_interpreter":
            return modelCapabilities.compactMap { key, value in
                value.supportedTools.contains("code_interpreter") ? key : nil
            }
        case "image_generation":
            return modelCapabilities.compactMap { key, value in
                value.supportedTools.contains("image_generation") ? key : nil
            }
        case "file_search":
            return modelCapabilities.compactMap { key, value in
                value.supportedTools.contains("file_search") ? key : nil
            }
        case "computer_use_preview":
            return modelCapabilities.compactMap { key, value in
                value.supportedTools.contains("computer_use_preview") ? key : nil
            }
        case "temperature":
            return modelCapabilities.compactMap { key, value in
                value.supportsTemperature ? key : nil
            }
        case "reasoning_effort":
            return modelCapabilities.compactMap { key, value in
                value.supportsReasoningEffort ? key : nil
            }
        case "max_output_tokens":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("max_output_tokens") ? key : nil
            }
        case "max_tool_calls":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("max_tool_calls") ? key : nil
            }
        case "service_tier":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("service_tier") ? key : nil
            }
        case "top_logprobs":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("top_logprobs") ? key : nil
            }
        case "top_p":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("top_p") ? key : nil
            }
        case "truncation":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("truncation") ? key : nil
            }
        case "parallel_tool_calls":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("parallel_tool_calls") ? key : nil
            }
        case "response_format":
            return modelCapabilities.compactMap { key, value in
                value.supportedParameters.contains("response_format") ? key : nil
            }
        case "background_mode":
            return [] // Not supported by any current models
        default:
            return []
        }
    }
}
