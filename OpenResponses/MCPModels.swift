import Foundation

// MARK: - MCP Discovery Models

/// Represents a discovered MCP server with its available tools
public struct MCPServerInfo: Codable, Identifiable, Hashable {
    // Use a stable identity derived from the server's unique name to ensure
    // consistent identity across view updates and sheet(item:) presentations.
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let description: String
    public let serverURL: String
    /// Optional: when this server is available as an OpenAI connector,
    /// specify the connector_id (e.g., "connector_googledrive").
    public let connectorId: String?
    public let category: MCPServerCategory
    public let isOfficial: Bool
    public let requiredAuth: MCPAuthType
    public let supportedCapabilities: [MCPCapability]
    public let availableTools: [MCPToolInfo]
    public let setupInstructions: String?
    
    public init(
        name: String,
        displayName: String,
        description: String,
        serverURL: String,
        connectorId: String? = nil,
        category: MCPServerCategory,
        isOfficial: Bool = false,
        requiredAuth: MCPAuthType = .none,
        supportedCapabilities: [MCPCapability] = [],
        availableTools: [MCPToolInfo] = [],
        setupInstructions: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.serverURL = serverURL
        self.connectorId = connectorId
        self.category = category
        self.isOfficial = isOfficial
        self.requiredAuth = requiredAuth
        self.supportedCapabilities = supportedCapabilities
        self.availableTools = availableTools
        self.setupInstructions = setupInstructions
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, displayName, description, serverURL, connectorId, category, isOfficial, requiredAuth, supportedCapabilities, availableTools, setupInstructions
    }
}

/// Categories for organizing MCP servers
public enum MCPServerCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case development = "development"
    case dataAnalysis = "data_analysis"
    case contentCreation = "content_creation"
    case communication = "communication"
    case fileManagement = "file_management"
    case automation = "automation"
    case ecommerce = "ecommerce"
    case entertainment = "entertainment"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .development: return "Development"
        case .dataAnalysis: return "Data Analysis"
        case .contentCreation: return "Content Creation"
        case .communication: return "Communication"
        case .fileManagement: return "File Management"
        case .automation: return "Automation"
        case .ecommerce: return "E-commerce"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        }
    }
    
    public var icon: String {
        switch self {
        case .productivity: return "productivity"
        case .development: return "hammer"
        case .dataAnalysis: return "chart.bar"
        case .contentCreation: return "paintbrush"
        case .communication: return "message"
        case .fileManagement: return "folder"
        case .automation: return "gear"
        case .ecommerce: return "cart"
        case .entertainment: return "tv"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Authentication types required for MCP servers
public enum MCPAuthType: String, Codable, CaseIterable {
    case none = "none"
    case apiKey = "api_key"
    case oauth = "oauth"
    case bearerToken = "bearer_token"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .none: return "No Authentication"
        case .apiKey: return "API Key"
        case .oauth: return "OAuth"
        case .bearerToken: return "Bearer Token"
        case .custom: return "Custom Auth"
        }
    }
    
    public var description: String {
        switch self {
        case .none: return "No authentication required"
        case .apiKey: return "Requires an API key"
        case .oauth: return "Requires OAuth authentication"
        case .bearerToken: return "Requires a bearer token"
        case .custom: return "Requires custom authentication"
        }
    }
}

/// Capabilities that an MCP server can support
public enum MCPCapability: String, Codable, CaseIterable {
    case toolExecution = "tool_execution"
    case resourceAccess = "resource_access"
    case fileOperations = "file_operations"
    case realTimeData = "real_time_data"
    case notifications = "notifications"
    case streaming = "streaming"
    case batchOperations = "batch_operations"
    
    public var displayName: String {
        switch self {
        case .toolExecution: return "Tool Execution"
        case .resourceAccess: return "Resource Access"
        case .fileOperations: return "File Operations"
        case .realTimeData: return "Real-time Data"
        case .notifications: return "Notifications"
        case .streaming: return "Streaming"
        case .batchOperations: return "Batch Operations"
        }
    }
}

/// Information about a specific tool available on an MCP server
public struct MCPToolInfo: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let displayName: String
    public let description: String
    public let category: String
    public let requiredPermissions: [String]
    public let inputSchema: [String: Any]?
    public let outputSchema: [String: Any]?
    public let examples: [MCPToolExample]
    
    public init(
        name: String,
        displayName: String,
        description: String,
        category: String,
        requiredPermissions: [String] = [],
        inputSchema: [String: Any]? = nil,
        outputSchema: [String: Any]? = nil,
        examples: [MCPToolExample] = []
    ) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.category = category
        self.requiredPermissions = requiredPermissions
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.examples = examples
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, displayName, description, category, requiredPermissions, examples
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        requiredPermissions = try container.decodeIfPresent([String].self, forKey: .requiredPermissions) ?? []
        examples = try container.decodeIfPresent([MCPToolExample].self, forKey: .examples) ?? []
        inputSchema = nil // Simplified for now
        outputSchema = nil // Simplified for now
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(requiredPermissions, forKey: .requiredPermissions)
        try container.encode(examples, forKey: .examples)
    }
}

// MARK: - MCPToolInfo Hashable & Equatable Conformance
extension MCPToolInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(displayName)
        hasher.combine(description)
        hasher.combine(category)
        hasher.combine(requiredPermissions)
        hasher.combine(examples)
        // Skip inputSchema and outputSchema since [String: Any] can't be hashed reliably
    }
}

extension MCPToolInfo: Equatable {
    public static func == (lhs: MCPToolInfo, rhs: MCPToolInfo) -> Bool {
        return lhs.name == rhs.name &&
               lhs.displayName == rhs.displayName &&
               lhs.description == rhs.description &&
               lhs.category == rhs.category &&
               lhs.requiredPermissions == rhs.requiredPermissions &&
               lhs.examples == rhs.examples
        // Skip inputSchema and outputSchema comparison since [String: Any] can't be compared reliably
    }
}

/// Example usage for an MCP tool
public struct MCPToolExample: Codable, Hashable {
    public let title: String
    public let description: String
    public let input: String
    public let expectedOutput: String
    
    public init(title: String, description: String, input: String, expectedOutput: String) {
        self.title = title
        self.description = description
        self.input = input
        self.expectedOutput = expectedOutput
    }
}

/// Configuration for connecting to a specific MCP server
public struct MCPServerConfiguration: Codable, Identifiable {
    public let id = UUID()
    public let serverId: String // References MCPServerInfo.name
    public var isEnabled: Bool
    public var authConfiguration: [String: String] // Auth headers/tokens
    public var selectedTools: Set<String> // Tool names to enable
    public var approvalSettings: MCPApprovalSettings
    
    public init(
        serverId: String,
        isEnabled: Bool = false,
        authConfiguration: [String: String] = [:],
        selectedTools: Set<String> = [],
        approvalSettings: MCPApprovalSettings = MCPApprovalSettings()
    ) {
        self.serverId = serverId
        self.isEnabled = isEnabled
        self.authConfiguration = authConfiguration
        self.selectedTools = selectedTools
        self.approvalSettings = approvalSettings
    }
    
    private enum CodingKeys: String, CodingKey {
        case serverId, isEnabled, authConfiguration, selectedTools, approvalSettings
    }
}

/// Settings for tool approval behavior
public struct MCPApprovalSettings: Codable {
    public var requireApprovalForAll: Bool
    public var approveAutomatically: Set<String> // Tool names that don't need approval
    public var alwaysAsk: Set<String> // Tool names that always need approval
    public var defaultAction: MCPApprovalAction
    
    public init(
        requireApprovalForAll: Bool = true,
        approveAutomatically: Set<String> = [],
        alwaysAsk: Set<String> = [],
        defaultAction: MCPApprovalAction = .prompt
    ) {
        self.requireApprovalForAll = requireApprovalForAll
        self.approveAutomatically = approveAutomatically
        self.alwaysAsk = alwaysAsk
        self.defaultAction = defaultAction
    }
}

/// Actions for tool approval
public enum MCPApprovalAction: String, Codable, CaseIterable {
    case allow = "allow"
    case deny = "deny"
    case prompt = "prompt"
    
    public var displayName: String {
        switch self {
        case .allow: return "Always Allow"
        case .deny: return "Always Deny"
        case .prompt: return "Ask Each Time"
        }
    }
}