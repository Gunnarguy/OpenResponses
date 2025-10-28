import Foundation
import CoreFoundation

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
        case mcp = "mcp"
    }

    // MARK: - Tools

    /// Represents the collection of tools the model can use to extend its capabilities.
    ///
    /// Tools allow the model to perform actions like searching the web, running code,
    /// or accessing external services.
    public enum Tool: Codable, Hashable {
        
        /// Allows the model to access up-to-date information from the internet.
        case webSearch
        /// Allows deep-research models to access preview web search capability required by API.
        /// Encodes as type "web_search_preview".
        case webSearchPreview
        
        /// Allows the model to search the contents of uploaded files within specified vector stores.
        /// - Parameters:
        ///   - vectorStoreIds: Array of vector store IDs to search
        ///   - maxNumResults: Optional limit on number of results (1-50)
        ///   - rankingOptions: Optional ranking configuration
        ///   - filters: Optional attribute filtering
        case fileSearch(
            vectorStoreIds: [String],
            maxNumResults: Int?,
            rankingOptions: RankingOptions?,
            filters: AttributeFilter?
        )
        
        /// Allows the model to write and run Python code in a sandboxed environment.
        case codeInterpreter(containerType: String, fileIds: [String]?)
        
        /// Allows the model to generate images using a text prompt.
        case imageGeneration(model: String, size: String, quality: String, outputFormat: String)
        
        /// Allows the model to call custom functions defined by the application.
        case function(function: Function)

        /// Allows the model to interact with the user's computer.
        case computer(environment: String?, displayWidth: Int?, displayHeight: Int?)

        /// Allows the model to connect to Model Context Protocol (MCP) servers.
        /// Supports either a remote server_url or a connector_id with authorization.
        case mcp(
            serverLabel: String,
            serverURL: String?,
            connectorId: String?,
            authorization: String?,
            headers: [String: String]?,
            requireApproval: String?,
            allowedTools: [String]?,
            serverDescription: String? = nil
        )

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
            case maxNumResults = "max_num_results"
            case rankingOptions = "ranking_options"
            case filters
            case fileIds = "file_ids"
            case environment
            case displayWidth = "display_width"
            case displayHeight = "display_height"
            case serverLabel = "server_label"
            case serverURL = "server_url"
            case connectorId = "connector_id"
            case authorization
            case headers
            case requireApproval = "require_approval"
            case allowedTools = "allowed_tools"
            case serverDescription = "server_description"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typeString = try container.decode(String.self, forKey: .type)
            
            switch typeString {
            case "web_search":
                self = .webSearch
            case "web_search_preview":
                self = .webSearchPreview
            case "file_search":
                let vectorStoreIds = try container.decodeIfPresent([String].self, forKey: .vectorStoreIds) ?? []
                let maxNumResults = try container.decodeIfPresent(Int.self, forKey: .maxNumResults)
                let rankingOptions = try container.decodeIfPresent(RankingOptions.self, forKey: .rankingOptions)
                let filters = try container.decodeIfPresent(AttributeFilter.self, forKey: .filters)
                self = .fileSearch(
                    vectorStoreIds: vectorStoreIds,
                    maxNumResults: maxNumResults,
                    rankingOptions: rankingOptions,
                    filters: filters
                )
            case "code_interpreter":
                let containerInfo = try container.decodeIfPresent([String: String].self, forKey: .container)
                let containerType = containerInfo?["type"] ?? "auto"
                let fileIds = try container.decodeIfPresent([String].self, forKey: .fileIds)
                self = .codeInterpreter(containerType: containerType, fileIds: fileIds)
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
            case "mcp":
                let serverLabel = try container.decode(String.self, forKey: .serverLabel)
                // Either server_url or connector_id may be present
                let serverURL = try container.decodeIfPresent(String.self, forKey: .serverURL)
                let connectorId = try container.decodeIfPresent(String.self, forKey: .connectorId)
                let authorization = try container.decodeIfPresent(String.self, forKey: .authorization)
                let headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
                let requireApproval = try container.decodeIfPresent(String.self, forKey: .requireApproval)
                let allowedTools = try container.decodeIfPresent([String].self, forKey: .allowedTools)
                let serverDescription = try container.decodeIfPresent(String.self, forKey: .serverDescription)
                self = .mcp(
                    serverLabel: serverLabel,
                    serverURL: serverURL,
                    connectorId: connectorId,
                    authorization: authorization,
                    headers: headers,
                    requireApproval: requireApproval,
                    allowedTools: allowedTools,
                    serverDescription: serverDescription
                )
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
            case .webSearchPreview:
                try container.encode("web_search_preview", forKey: .type)
            case .fileSearch(let vectorStoreIds, let maxNumResults, let rankingOptions, let filters):
                try container.encode("file_search", forKey: .type)
                if !vectorStoreIds.isEmpty {
                    try container.encode(vectorStoreIds, forKey: .vectorStoreIds)
                }
                if let maxNumResults = maxNumResults {
                    try container.encode(maxNumResults, forKey: .maxNumResults)
                }
                if let rankingOptions = rankingOptions {
                    try container.encode(rankingOptions, forKey: .rankingOptions)
                }
                if let filters = filters {
                    try container.encode(filters, forKey: .filters)
                }
            case .codeInterpreter(let containerType, let fileIds):
                try container.encode("code_interpreter", forKey: .type)
                try container.encode(["type": containerType], forKey: .container)
                if let fileIds = fileIds, !fileIds.isEmpty {
                    try container.encode(fileIds, forKey: .fileIds)
                }
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
            case .mcp(let serverLabel, let serverURL, let connectorId, let authorization, let headers, let requireApproval, let allowedTools, let serverDescription):
                try container.encode("mcp", forKey: .type)
                try container.encode(serverLabel, forKey: .serverLabel)
                if let serverURL = serverURL {
                    try container.encode(serverURL, forKey: .serverURL)
                }
                if let connectorId = connectorId {
                    try container.encode(connectorId, forKey: .connectorId)
                }
                if let authorization = authorization {
                    try container.encode(authorization, forKey: .authorization)
                }
                if let headers = headers {
                    try container.encode(headers, forKey: .headers)
                }
                if let requireApproval = requireApproval {
                    try container.encode(requireApproval, forKey: .requireApproval)
                }
                if let allowedTools = allowedTools {
                    try container.encode(allowedTools, forKey: .allowedTools)
                }
                if let serverDescription = serverDescription {
                    try container.encode(serverDescription, forKey: .serverDescription)
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

/// A type-erased wrapper to allow encoding/decoding of JSON values, including `null`.
public struct AnyCodable: Codable, Hashable {
    public let value: Any?

    public init(_ value: Any?) {
        self.value = value
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let hashable as AnyHashable:
            hasher.combine(hashable)
        case nil:
            hasher.combine("nil")
        default:
            hasher.combine(String(describing: value))
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil):
            return true
        case let (lhsHashable as AnyHashable, rhsHashable as AnyHashable):
            return lhsHashable == rhsHashable
        default:
            return false
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let intVal = try? container.decode(Int.self) {
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
            value = dictVal.reduce(into: [String: Any?]()) { result, element in
                result[element.key] = element.value.value
            }
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case nil:
            try container.encodeNil()
        case let val as Int:
            try container.encode(val)
        case let val as String:
            try container.encode(val)
        case let val as Bool:
            try container.encode(val)
        case let val as Double:
            try container.encode(val)
        case let val as [AnyCodable]:
            try container.encode(val)
        case let val as [Any?]:
            try container.encode(val.map { AnyCodable($0) })
        case let val as [Any]:
            try container.encode(val.map { AnyCodable($0) })
        case let val as [String: AnyCodable]:
            try container.encode(val)
        case let val as [String: Any?]:
            let converted = val.reduce(into: [String: AnyCodable]()) { result, element in
                result[element.key] = AnyCodable(element.value)
            }
            try container.encode(converted)
        case let val as [String: Any]:
            let converted = val.mapValues { AnyCodable($0) }
            try container.encode(converted)
        default:
            throw EncodingError.invalidValue(
                value as Any,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }

    /// Returns a JSON string representation of the wrapped value when possible.
    /// Falls back to a descriptive string as a last resort to avoid hiding diagnostics.
    public func jsonString(prettyPrinted: Bool = false) -> String? {
        guard let unwrapped = value else { return "null" }

        if let string = unwrapped as? String {
            return string
        }

        if let boolValue = unwrapped as? Bool {
            return boolValue ? "true" : "false"
        }

        if let number = unwrapped as? NSNumber {
            // NSNumber can represent both numeric values and booleans. The boolean case is handled above.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }

        let wrapped = AnyCodable.makeJSONRepresentable(from: unwrapped)

        if JSONSerialization.isValidJSONObject(wrapped) {
            let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
            if let data = try? JSONSerialization.data(withJSONObject: wrapped, options: options),
               let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        }

        return String(describing: unwrapped)
    }

    /// Converts a value into something `JSONSerialization` accepts, preserving nulls.
    private static func makeJSONRepresentable(from value: Any) -> Any {
        switch value {
        case let codable as AnyCodable:
            return makeJSONRepresentable(from: codable.value as Any)
        case let array as [AnyCodable]:
            return array.map { makeJSONRepresentable(from: $0.value as Any) }
        case let array as [Any?]:
            return array.map { element -> Any in
                guard let element else { return NSNull() }
                return makeJSONRepresentable(from: element)
            }
        case let array as [Any]:
            return array.map { makeJSONRepresentable(from: $0) }
        case let dict as [String: AnyCodable]:
            return dict.reduce(into: [String: Any]()) { result, element in
                result[element.key] = makeJSONRepresentable(from: element.value.value as Any)
            }
        case let dict as [String: Any?]:
            return dict.reduce(into: [String: Any]()) { result, element in
                if let value = element.value {
                    result[element.key] = makeJSONRepresentable(from: value)
                } else {
                    result[element.key] = NSNull()
                }
            }
        case let dict as [String: Any]:
            return dict.reduce(into: [String: Any]()) { result, element in
                result[element.key] = makeJSONRepresentable(from: element.value)
            }
        case is NSNull:
            return value
        default:
            return value
        }
    }
}

// MARK: - Decoding helpers

extension KeyedDecodingContainer {
    /// Attempts to decode either a plain string or a JSON payload represented as a dictionary/array.
    /// Returns the payload serialized as a compact JSON string when necessary.
    func decodeStringOrJSONStringIfPresent(forKey key: Key) throws -> String? {
        guard contains(key) else { return nil }

        if try decodeNil(forKey: key) {
            return nil
        }

        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let anyValue = try? decode(AnyCodable.self, forKey: key) {
            return anyValue.jsonString(prettyPrinted: false)
        }

        return nil
    }
}

// MARK: - Attribute Filtering

/// Attribute filtering for file search
public enum AttributeFilter: Codable, Hashable {
    case comparison(property: String, operator: ComparisonOperator, value: AttributeValue)
    case compound(operator: CompoundOperator, filters: [AttributeFilter])
    
    public enum ComparisonOperator: String, Codable {
        case eq, ne, gt, gte, lt, lte
    }
    
    public enum CompoundOperator: String, Codable {
        case and, or
    }
    
    public enum AttributeValue: Codable, Hashable {
        case string(String)
        case int(Int)
        case double(Double)
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .string(let val): hasher.combine(val)
            case .int(let val): hasher.combine(val)
            case .double(let val): hasher.combine(val)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                self = .int(intVal)
            } else if let doubleVal = try? container.decode(Double.self) {
                self = .double(doubleVal)
            } else if let stringVal = try? container.decode(String.self) {
                self = .string(stringVal)
            } else {
                throw DecodingError.typeMismatch(AttributeValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported attribute value type"))
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let val): try container.encode(val)
            case .int(let val): try container.encode(val)
            case .double(let val): try container.encode(val)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type, property, value, filters
        case `operator` = "operator"
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .comparison(let property, let op, let value):
            hasher.combine("comparison")
            hasher.combine(property)
            hasher.combine(op)
            hasher.combine(value)
        case .compound(let op, let filters):
            hasher.combine("compound")
            hasher.combine(op)
            hasher.combine(filters)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "and", "or":
            let op = CompoundOperator(rawValue: type)!
            let filters = try container.decode([AttributeFilter].self, forKey: .filters)
            self = .compound(operator: op, filters: filters)
        default:
            // Comparison operators
            let property = try container.decode(String.self, forKey: .property)
            let op = ComparisonOperator(rawValue: type)!
            let value = try container.decode(AttributeValue.self, forKey: .value)
            self = .comparison(property: property, operator: op, value: value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .comparison(let property, let op, let value):
            try container.encode(op.rawValue, forKey: .type)
            try container.encode(property, forKey: .property)
            try container.encode(value, forKey: .value)
        case .compound(let op, let filters):
            try container.encode(op.rawValue, forKey: .type)
            try container.encode(filters, forKey: .filters)
        }
    }
}

// MARK: - Ranking Options

/// Ranking options for file search results
public struct RankingOptions: Codable, Hashable {
    let ranker: String // "auto" or "default-2024-08-21"
    let scoreThreshold: Double // 0.0 to 1.0
    
    enum CodingKeys: String, CodingKey {
        case ranker
        case scoreThreshold = "score_threshold"
    }
    
    public static let auto = RankingOptions(ranker: "auto", scoreThreshold: 0.0)
    
    public init(ranker: String, scoreThreshold: Double) {
        self.ranker = ranker
        self.scoreThreshold = min(max(scoreThreshold, 0.0), 1.0)
    }
}
