import Foundation

/// Service for managing model compatibility with tools and parameters
class ModelCompatibilityService {
    static let shared = ModelCompatibilityService()
    private init() {}
    
    // MARK: - Compatibility Types
    
    /// Represents a tool's compatibility and usage status
    public struct ToolCompatibility {
        public let name: String
        public let isSupported: Bool
        public let isEnabled: Bool
        public let isUsed: Bool
        public let supportedModels: [String]
        public let restrictions: [String]
        public let description: String
        
        public init(name: String, isSupported: Bool, isEnabled: Bool, isUsed: Bool, supportedModels: [String], restrictions: [String], description: String) {
            self.name = name
            self.isSupported = isSupported
            self.isEnabled = isEnabled
            self.isUsed = isUsed
            self.supportedModels = supportedModels
            self.restrictions = restrictions
            self.description = description
        }
    }
    
    /// Represents parameter compatibility for a model
    public struct ParameterCompatibility {
        public let name: String
        public let isSupported: Bool
        public let supportedModels: [String]
        public let defaultValue: Any?
        public let restrictions: [String]
        
        public init(name: String, isSupported: Bool, supportedModels: [String], defaultValue: Any?, restrictions: [String]) {
            self.name = name
            self.isSupported = isSupported
            self.supportedModels = supportedModels
            self.defaultValue = defaultValue
            self.restrictions = restrictions
        }
    }
    
    // MARK: - Tool Overrides
    
    /// Overrides for specific tools, allowing fine-grained control over their availability.
    public struct ToolOverrides: Codable {
        public var webSearch: ToolOverride?
        public var codeInterpreter: ToolOverride?
        public var imageGeneration: ToolOverride?
        public var fileSearch: ToolOverride?
        public var computer: ToolOverride?
    }
    
    /// Defines the override setting for a tool (either `enabled` or `disabled`).
    public enum ToolOverride: String, Codable {
        case enabled
        case disabled
    }
    
    /// Defines the coding keys for tool overrides, mapping to the API's expected keys.
    private enum ToolCodingKeys: String, CodingKey {
        case webSearch = "web_search"
        case codeInterpreter = "code_interpreter"
        case imageGeneration = "image_generation"
        case fileSearch = "file_search"
        case computer = "computer"
    }
    
    /// Model capability information
    public struct ModelCapabilities: Codable {
        public let streaming: Bool
        public let tools: [APICapabilities.ToolType]
        public let parameters: [String]
        public let toolOverrides: ToolOverrides?
        public let category: ModelCategory
        public let supportsReasoningEffort: Bool
        public let supportsTemperature: Bool
        
        public init(streaming: Bool, tools: [APICapabilities.ToolType], parameters: [String], toolOverrides: ToolOverrides? = nil, category: ModelCategory = .standard, supportsReasoningEffort: Bool = false, supportsTemperature: Bool = true) {
            self.streaming = streaming
            self.tools = tools
            self.parameters = parameters
            self.toolOverrides = toolOverrides
            self.category = category
            self.supportsReasoningEffort = supportsReasoningEffort
            self.supportsTemperature = supportsTemperature
        }
        
        /// For backward compatibility
        public var supportsStreaming: Bool { streaming }
    }
    
    /// Model category enumeration
    public enum ModelCategory: String, Codable {
        case reasoning // o-series models
        case standard // gpt-4, gpt-3.5
        case latest // gpt-5, gpt-4.1
        case preview // experimental models
    }
    
    /// A dictionary mapping model identifiers to their specific API capabilities.
    private var modelCapabilities: [String: ModelCapabilities] = [
        "gpt-4o": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .imageGeneration, .fileSearch, .function, .computer],
            parameters: ["temperature", "top_p", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .enabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .latest,
            supportsReasoningEffort: false,
            supportsTemperature: true
        ),
        "gpt-4-turbo": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .imageGeneration, .fileSearch, .function, .computer],
            parameters: ["temperature", "top_p", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .enabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .standard,
            supportsReasoningEffort: false,
            supportsTemperature: true
        ),
        "gpt-4-vision": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .imageGeneration, .fileSearch, .function, .computer],
            parameters: ["temperature", "top_p", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .enabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .standard,
            supportsReasoningEffort: false,
            supportsTemperature: true
        ),
        "gpt-4": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .imageGeneration, .fileSearch, .function, .computer],
            parameters: ["temperature", "top_p", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .enabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .standard,
            supportsReasoningEffort: false,
            supportsTemperature: true
        ),
        "gpt-3.5-turbo": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .fileSearch, .function],
            parameters: ["temperature", "top_p", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            category: .standard,
            supportsReasoningEffort: false,
            supportsTemperature: true
        ),
        "o1-preview": ModelCapabilities(
            streaming: false,
            tools: [.codeInterpreter, .fileSearch],
            parameters: ["reasoning_effort", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            category: .reasoning,
            supportsReasoningEffort: true,
            supportsTemperature: false
        ),
        "o1-mini": ModelCapabilities(
            streaming: false,
            tools: [.codeInterpreter, .fileSearch],
            parameters: ["reasoning_effort", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            category: .reasoning,
            supportsReasoningEffort: true,
            supportsTemperature: false
        ),
        "o3": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .fileSearch, .function, .computer],
            parameters: ["reasoning_effort", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .disabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .reasoning,
            supportsReasoningEffort: true,
            supportsTemperature: false
        ),
        "o3-mini": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .fileSearch, .function],
            parameters: ["reasoning_effort", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            category: .reasoning,
            supportsReasoningEffort: true,
            supportsTemperature: false
        ),
        "gpt-5-turbo": ModelCapabilities(
            streaming: true,
            tools: [.webSearch, .codeInterpreter, .imageGeneration, .fileSearch, .function, .computer],
            parameters: ["temperature", "top_p", "reasoning_effort", "parallel_tool_calls", "max_output_tokens", "truncation", "service_tier", "top_logprobs", "user_identifier", "max_tool_calls", "metadata", "tool_choice"],
            toolOverrides: ToolOverrides(
                webSearch: .enabled,
                codeInterpreter: .enabled,
                imageGeneration: .enabled,
                fileSearch: .enabled,
                computer: .enabled
            ),
            category: .latest,
            supportsReasoningEffort: true,
            supportsTemperature: true
        )
    ]
    
    // MARK: - Public API
    
    /// Returns the capabilities for a given model.
    /// - Parameter modelId: The model identifier.
    /// - Returns: The model capabilities, or nil if the model is not supported.
    public func getCapabilities(for modelId: String) -> ModelCapabilities? {
        return modelCapabilities[modelId]
    }
    
    /// Checks if a tool is supported by a given model.
    /// - Parameters:
    ///   - toolType: The tool type to check.
    ///   - modelId: The model identifier.
    ///   - isStreaming: Whether streaming is enabled (affects some tools).
    /// - Returns: True if the tool is supported, false otherwise.
    public func isToolSupported(_ toolType: APICapabilities.ToolType, for modelId: String, isStreaming: Bool = false) -> Bool {
        guard let capabilities = modelCapabilities[modelId] else {
            return false
        }
        
        // Check if the tool is in the supported tools list
        guard capabilities.tools.contains(toolType) else {
            return false
        }
        
        // Special case: Image generation is not supported during streaming
        if toolType == .imageGeneration && isStreaming {
            return false
        }
        
        // Check for specific tool overrides for the given model
        if let toolOverrides = capabilities.toolOverrides {
            switch toolType {
            case .webSearch:
                if toolOverrides.webSearch == .disabled { return false }
            case .codeInterpreter:
                if toolOverrides.codeInterpreter == .disabled { return false }
            case .imageGeneration:
                if toolOverrides.imageGeneration == .disabled { return false }
            case .fileSearch:
                if toolOverrides.fileSearch == .disabled { return false }
            case .computer:
                if toolOverrides.computer == .disabled { return false }
            case .function:
                break // No override for function tool
            }
        }
        
        // Default to supported if no specific override is found
        return true
    }
    
    /// Checks if a parameter is supported by a given model.
    /// - Parameters:
    ///   - parameter: The parameter name.
    ///   - modelId: The model identifier.
    /// - Returns: True if the parameter is supported, false otherwise.
    public func isParameterSupported(_ parameter: String, for modelId: String) -> Bool {
        guard let capabilities = modelCapabilities[modelId] else {
            return false
        }
        return capabilities.parameters.contains(parameter)
    }
    
    /// Updates the model capabilities with the provided dictionary, merging with existing capabilities.
    /// - Parameter capabilities: A dictionary of model capabilities to update.
    public func updateCapabilities(_ capabilities: [String: ModelCapabilities]) {
        for (modelId, newCapabilities) in capabilities {
            if let existingCapabilities = modelCapabilities[modelId] {
                // Merge with existing capabilities
                var updatedTools = existingCapabilities.tools
                updatedTools.append(contentsOf: newCapabilities.tools)
                var updatedParameters = existingCapabilities.parameters
                updatedParameters.append(contentsOf: newCapabilities.parameters)
                
                let mergedOverrides = mergeToolOverrides(existingCapabilities.toolOverrides, newCapabilities.toolOverrides)

                let updatedCapabilities = ModelCapabilities(
                    streaming: existingCapabilities.streaming || newCapabilities.streaming,
                    tools: updatedTools,
                    parameters: updatedParameters,
                    toolOverrides: mergedOverrides
                )
                
                modelCapabilities[modelId] = updatedCapabilities
            } else {
                // Add new capabilities
                modelCapabilities[modelId] = newCapabilities
            }
        }
    }
    
    /// Merges two sets of tool overrides, giving precedence to the first set.
    /// - Parameters:
    ///   - existing: The existing tool overrides.
    ///   - new: The new tool overrides to merge.
    /// - Returns: The merged tool overrides.
    private func mergeToolOverrides(_ existing: ToolOverrides?, _ new: ToolOverrides?) -> ToolOverrides? {
        guard let existing = existing else { return new }
        guard let new = new else { return existing }
        
        return ToolOverrides(
            webSearch: existing.webSearch ?? new.webSearch,
            codeInterpreter: existing.codeInterpreter ?? new.codeInterpreter,
            imageGeneration: existing.imageGeneration ?? new.imageGeneration,
            fileSearch: existing.fileSearch ?? new.fileSearch,
            computer: existing.computer ?? new.computer
        )
    }
    
    // MARK: - Additional Compatibility Methods
    
    /// Gets tool compatibility information for a specific model and prompt configuration
    /// - Parameters:
    ///   - modelId: The model identifier
    ///   - prompt: The current prompt configuration
    ///   - isStreaming: Whether streaming is enabled
    /// - Returns: Array of tool compatibility information
    public func getCompatibleTools(for modelId: String, prompt: Prompt, isStreaming: Bool) -> [ToolCompatibility] {
        guard modelCapabilities[modelId] != nil else { return [] }
        
        let allTools: [(APICapabilities.ToolType, String, String, Bool)] = [
            (.webSearch, "Web Search", "Search the internet for current information", prompt.enableWebSearch),
            (.codeInterpreter, "Code Interpreter", "Run Python code and analyze data", prompt.enableCodeInterpreter),
            (.imageGeneration, "Image Generation", "Generate images using AI", prompt.enableImageGeneration),
            (.fileSearch, "File Search", "Search through uploaded documents", prompt.enableFileSearch),
            (.computer, "Computer Use", "Interact with the computer", prompt.enableComputerUse),
            (.function, "Custom Functions", "Call custom functions", prompt.enableCustomTool)
        ]
        
        return allTools.map { toolType, name, description, isEnabled in
            let isSupported = isToolSupported(toolType, for: modelId, isStreaming: isStreaming)
            let supportedModels = modelCapabilities.compactMap { key, value in
                value.tools.contains(toolType) ? key : nil
            }
            
            var restrictions: [String] = []
            if toolType == .imageGeneration && isStreaming {
                restrictions.append("Not available during streaming")
            }
            
            return ToolCompatibility(
                name: name,
                isSupported: isSupported,
                isEnabled: isEnabled,
                isUsed: isSupported && isEnabled,
                supportedModels: supportedModels,
                restrictions: restrictions,
                description: description
            )
        }
    }
    
    /// Gets parameter compatibility information for a specific model
    /// - Parameter modelId: The model identifier
    /// - Returns: Array of parameter compatibility information
    public func getParameterCompatibility(for modelId: String) -> [ParameterCompatibility] {
        guard let capabilities = modelCapabilities[modelId] else { return [] }
        
        let allParameters: [(String, Any?, String)] = [
            ("temperature", 1.0, "Controls randomness in responses"),
            ("top_p", 1.0, "Controls diversity via nucleus sampling"),
            ("reasoning_effort", "medium", "Controls reasoning depth for O-series models"),
            ("max_output_tokens", 4096, "Maximum number of tokens in response"),
            ("parallel_tool_calls", true, "Allow multiple tool calls simultaneously"),
            ("service_tier", "auto", "API service tier selection"),
            ("top_logprobs", 0, "Number of top token probabilities to return"),
            ("truncation", "auto", "Strategy for handling context length limits"),
            ("tool_choice", "auto", "Controls which tools the model can use"),
            ("metadata", nil, "Custom metadata for requests")
        ]
        
        return allParameters.map { name, defaultValue, description in
            let isSupported = isParameterSupported(name, for: modelId)
            let supportedModels = modelCapabilities.compactMap { key, value in
                value.parameters.contains(name) ? key : nil
            }
            
            var restrictions: [String] = []
            if name == "temperature" && capabilities.category == .reasoning {
                restrictions.append("Not available for reasoning models")
            }
            if name == "reasoning_effort" && capabilities.category != .reasoning {
                restrictions.append("Only available for reasoning models")
            }
            
            return ParameterCompatibility(
                name: name,
                isSupported: isSupported,
                supportedModels: supportedModels,
                defaultValue: defaultValue,
                restrictions: restrictions
            )
        }
    }
}
