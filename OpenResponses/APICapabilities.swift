import Foundation

// MARK: - APICapabilities

/// A definitive guide to the OpenAI API features available to the OpenResponses application.
///
/// This file serves as a single, machine-readable source of truth, translating the concepts
/// from the project's documentation into a structured, type-safe Swift format. Each
/// capability is documented with details on its purpose, usage, and parameters.
public enum APICapabilities {

    public enum ToolType: String, Codable, CaseIterable {
        case webSearch = "web_search"
        case codeInterpreter = "code_interpreter"
        case imageGeneration = "image_generation"
        case fileSearch = "file_search"
        case function = "function"
        case computer = "computer"
    }

    // MARK: - Tools

    /// Represents the collection of tools the model can use to extend its capabilities.
    ///
    /// Tools allow the model to perform actions like searching the web, running code,
    /// or accessing external services.
    public enum Tool: Codable, Hashable {
        
        /// Allows the model to access up-to-date information from the internet.
        case webSearch
        
        /// Allows the model to search the contents of uploaded files within specified vector stores.
        case fileSearch(vectorStoreIds: [String])
        
        /// Allows the model to write and run Python code in a sandboxed environment.
        case codeInterpreter(containerType: String)
        
        /// Allows the model to generate images using a text prompt.
        case imageGeneration(model: String, size: String, quality: String, outputFormat: String)
        
        /// Allows the model to call custom functions defined by the application.
        case function(function: Function)

        /// Allows the model to interact with the user's computer.
        case computer(environment: String?, displayWidth: Int?, displayHeight: Int?)

        // MARK: - Codable Implementation
        
        private enum CodingKeys: String, CodingKey {
            case type
            case function
            case container
            case model
            case size
            case quality
            case outputFormat = "output_format"
            case vectorStoreIds = "vector_store_ids"
            case environment
            case displayWidth = "display_width"
            case displayHeight = "display_height"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typeString = try container.decode(String.self, forKey: .type)
            
            switch typeString {
            case "web_search":
                self = .webSearch
            case "file_search":
                let vectorStoreIds = try container.decodeIfPresent([String].self, forKey: .vectorStoreIds) ?? []
                self = .fileSearch(vectorStoreIds: vectorStoreIds)
            case "code_interpreter":
                let containerInfo = try container.decodeIfPresent([String: String].self, forKey: .container)
                let containerType = containerInfo?["type"] ?? "auto"
                self = .codeInterpreter(containerType: containerType)
            case "image_generation":
                let model = try container.decodeIfPresent(String.self, forKey: .model) ?? "gpt-image-1"
                let size = try container.decodeIfPresent(String.self, forKey: .size) ?? "auto"
                let quality = try container.decodeIfPresent(String.self, forKey: .quality) ?? "high"
                let outputFormat = try container.decodeIfPresent(String.self, forKey: .outputFormat) ?? "png"
                self = .imageGeneration(model: model, size: size, quality: quality, outputFormat: outputFormat)
            case "function":
                let function = try container.decode(Function.self, forKey: .function)
                self = .function(function: function)
            case "computer_use_preview", "computer":
                let environment = try container.decodeIfPresent(String.self, forKey: .environment)
                let displayWidth = try container.decodeIfPresent(Int.self, forKey: .displayWidth)
                let displayHeight = try container.decodeIfPresent(Int.self, forKey: .displayHeight)
                self = .computer(environment: environment, displayWidth: displayWidth, displayHeight: displayHeight)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown tool type: \(typeString)")
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .webSearch:
                try container.encode("web_search", forKey: .type)
            case .fileSearch(let vectorStoreIds):
                try container.encode("file_search", forKey: .type)
                if !vectorStoreIds.isEmpty {
                    try container.encode(vectorStoreIds, forKey: .vectorStoreIds)
                }
            case .codeInterpreter(let containerType):
                try container.encode("code_interpreter", forKey: .type)
                try container.encode(["type": containerType], forKey: .container)
            case .imageGeneration(let model, let size, let quality, let outputFormat):
                try container.encode("image_generation", forKey: .type)
                try container.encode(model, forKey: .model)
                try container.encode(size, forKey: .size)
                try container.encode(quality, forKey: .quality)
                try container.encode(outputFormat, forKey: .outputFormat)
            case .function(let function):
                try container.encode("function", forKey: .type)
                try container.encode(function, forKey: .function)
            case .computer(let environment, let displayWidth, let displayHeight):
                try container.encode("computer_use_preview", forKey: .type)
                if let environment = environment {
                    try container.encode(environment, forKey: .environment)
                }
                if let displayWidth = displayWidth {
                    try container.encode(displayWidth, forKey: .displayWidth)
                }
                if let displayHeight = displayHeight {
                    try container.encode(displayHeight, forKey: .displayHeight)
                }
            }
        }
    }

    // MARK: - Tool Configurations

    public struct Function: Codable, Hashable {
        public let name: String
        public let description: String
        public let parameters: JSONSchema
        public let strict: Bool?
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
