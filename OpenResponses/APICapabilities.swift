import Foundation

// MARK: - APICapabilities

/// A definitive guide to the OpenAI API features available to the OpenResponses application.
///
/// This file serves as a single, machine-readable source of truth, translating the concepts
/// from the project's documentation into a structured, type-safe Swift format. Each
/// capability is documented with details on its purpose, usage, and parameters.
public enum APICapabilities {

    // MARK: - Tools

    /// Represents the collection of tools the model can use to extend its capabilities.
    ///
    /// Tools allow the model to perform actions like searching the web, running code,
    /// or accessing external services.
    public enum Tool: Codable, Hashable {
        
        /// Allows the model to access up-to-date information from the internet.
        case webSearch(allowedDomains: [String]? = nil)
        
        /// Allows the model to search the contents of uploaded files within specified vector stores.
        case fileSearch(vectorStoreIDs: [String])
        
        /// Allows the model to write and run Python code in a sandboxed environment.
        case codeInterpreter
        
        /// Allows the model to generate images using a text prompt.
        case imageGeneration
        
        /// Allows the model to call custom functions defined by the application.
        case function(name: String, description: String, parameters: JSONSchema)
        
        /// Allows the model to connect to external services via the Model Context Protocol (MCP).
        case mcp(serverURL: URL, description: String, requiresApproval: Bool)

        // MARK: - Codable Implementation
        
        private enum CodingKeys: String, CodingKey {
            case type
            case function
            case webSearch = "web_search"
            case fileSearch = "file_search"
            case mcp
        }
        
        private enum ToolType: String, Codable {
            case webSearch = "web_search"
            case fileSearch = "file_search"
            case codeInterpreter = "code_interpreter"
            case imageGeneration = "image_generation"
            case function
            case mcp
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ToolType.self, forKey: .type)
            
            switch type {
            case .webSearch:
                // Web search might have an associated object for filters
                self = .webSearch() // Simplified for now
            case .fileSearch:
                let fileSearchContainer = try container.nestedContainer(keyedBy: FileSearchKeys.self, forKey: .fileSearch)
                let vectorStoreIDs = try fileSearchContainer.decode([String].self, forKey: .vectorStoreIDs)
                self = .fileSearch(vectorStoreIDs: vectorStoreIDs)
            case .codeInterpreter:
                self = .codeInterpreter
            case .imageGeneration:
                self = .imageGeneration
            case .function:
                let funcContainer = try container.nestedContainer(keyedBy: FunctionKeys.self, forKey: .function)
                let name = try funcContainer.decode(String.self, forKey: .name)
                let description = try funcContainer.decode(String.self, forKey: .description)
                let parameters = try funcContainer.decode(JSONSchema.self, forKey: .parameters)
                self = .function(name: name, description: description, parameters: parameters)
            case .mcp:
                // MCP would have its own container and keys
                self = .mcp(serverURL: URL(string:"https://example.com")!, description: "", requiresApproval: false) // Simplified
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .webSearch:
                try container.encode(ToolType.webSearch, forKey: .type)
            case .fileSearch(let vectorStoreIDs):
                try container.encode(ToolType.fileSearch, forKey: .type)
                var fileSearchContainer = container.nestedContainer(keyedBy: FileSearchKeys.self, forKey: .fileSearch)
                try fileSearchContainer.encode(vectorStoreIDs, forKey: .vectorStoreIDs)
            case .codeInterpreter:
                try container.encode(ToolType.codeInterpreter, forKey: .type)
            case .imageGeneration:
                try container.encode(ToolType.imageGeneration, forKey: .type)
            case .function(let name, let description, let parameters):
                try container.encode(ToolType.function, forKey: .type)
                var funcContainer = container.nestedContainer(keyedBy: FunctionKeys.self, forKey: .function)
                try funcContainer.encode(name, forKey: .name)
                try funcContainer.encode(description, forKey: .description)
                try funcContainer.encode(parameters, forKey: .parameters)
            case .mcp:
                try container.encode(ToolType.mcp, forKey: .type)
            }
        }
        
        private enum FunctionKeys: String, CodingKey {
            case name, description, parameters
        }
        
        private enum FileSearchKeys: String, CodingKey {
            case vectorStoreIDs = "vector_store_ids"
        }
    }

    // MARK: - Image & Vision

    /// Defines the capabilities related to image generation and analysis (vision).
    public struct ImageCapability {
        
        /// The model used for the operation (e.g., "gpt-image-1", "gpt-4o").
        public let model: String
        
        /// Describes the two primary modes of operation for images.
        public enum Mode {
            
            /// Creating a new image from a text prompt.
            case generate(prompt: String, revisedPrompt: String?, streamPartials: Int?)
            
            /// Analyzing an existing image.
            case analyze(image: ImageInput, detail: DetailLevel)
        }
        
        /// The mode of operation for this capability.
        public let mode: Mode
        
        /// Represents the input for image analysis.
        public enum ImageInput {
            case url(URL)
            case base64(Data)
            case fileID(String)
        }
        
        /// Controls the level of detail for image analysis, balancing cost, speed, and accuracy.
        public enum DetailLevel: String, Codable {
            case low, high, auto
        }
    }

    // MARK: - File Management

    /// Defines the workflow for uploading, managing, and using files.
    public struct FileManagement {
        
        /// The purpose for which a file is uploaded.
        public enum Purpose: String, Codable {
            /// For files that will be used as direct input to a model (e.g., an image for analysis).
            case input
            /// For files that will be part of a knowledge base for the `file_search` tool.
            case fileSearch = "file_search"
        }
        
        /// Represents a file uploaded to OpenAI.
        public struct File: Codable, Hashable {
            public let id: String
            public let purpose: Purpose
            public let filename: String
        }
        
        /// A container for files that have been indexed for efficient search.
        public struct VectorStore: Codable, Hashable {
            public let id: String
            public let name: String
            public let fileIDs: [String]
        }
    }

    // MARK: - Advanced Features

    /// A collection of advanced API features for building sophisticated applications.
    public enum AdvancedFeature {
        
        /// Receiving model outputs as they are generated for real-time applications.
        case streaming
        
        /// Ensuring model responses conform to a specific JSON schema.
        case structuredOutput(schema: JSONSchema)
        
        /// Reducing latency and cost by caching the results of frequently used prompt prefixes.
        case promptCaching
        
        /// Leveraging models designed for complex problem-solving and planning.
        case reasoning(effort: ReasoningEffort)
        
        public enum ReasoningEffort: String, Codable {
            case low, medium, high
        }
    }

    // MARK: - Prompting

    /// A guide to strategies for writing effective prompts.
    public struct Prompting {
        
        /// The role of the message author, which influences the model's response.
        public enum Role: String, Codable {
            case instructions, developer, user, assistant
        }
        
        /// A structured message in a conversation.
        public struct Message: Codable, Hashable {
            public let role: Role
            public let content: String
        }
        
        /// The technique of providing examples to teach the model a new task.
        public struct FewShotExample: Codable, Hashable {
            public let input: String
            public let output: String
        }
    }
    
    // MARK: - Helper Types
    
    /// A placeholder for a JSON schema definition.
    /// In a real implementation, this would be a more robust struct that is Codable.
    /// For now, we use a dictionary, which is inherently Codable.
    public struct JSONSchema: Codable, Hashable {
        public let value: [String: AnyCodable]

        public init(_ value: [String: Any]) {
            self.value = value.mapValues { AnyCodable($0) }
        }
    }
}

/// A type-erased wrapper to allow encoding/decoding of `[String: Any]`.
public struct AnyCodable: Codable, Hashable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public func hash(into hasher: inout Hasher) {
        if let val = value as? AnyHashable {
            hasher.combine(val)
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // This is a simplified equality check. A robust implementation would be more complex.
        return (lhs.value as? AnyHashable) == (rhs.value as? AnyHashable)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let val = value as? Int {
            try container.encode(val)
        } else if let val = value as? String {
            try container.encode(val)
        } else if let val = value as? Bool {
            try container.encode(val)
        } else if let val = value as? Double {
            try container.encode(val)
        } else if let val = value as? [Any] {
            try container.encode(val.map { AnyCodable($0) })
        } else if let val = value as? [String: Any] {
            try container.encode(val.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
