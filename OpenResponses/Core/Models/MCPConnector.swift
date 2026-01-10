import Foundation

/// Represents an OpenAI-maintained MCP connector for popular services
struct MCPConnector: Identifiable, Codable, Hashable {
    let id: String // connector_id
    let name: String
    let description: String
    let icon: String // SF Symbol name
    let color: String // Hex color
    let oauthScopes: [String]
    let oauthInstructions: String
    let setupURL: String?
    let category: ConnectorCategory
    let popularTools: [String]
    let requiresRemoteServer: Bool // True if this requires self-hosted MCP server deployment

    enum ConnectorCategory: String, Codable, CaseIterable {
        case storage = "Storage"
        case email = "Email"
        case calendar = "Calendar"
        case collaboration = "Collaboration"
        case productivity = "Productivity"
        case development = "Development"
    }

    /// Built-in library of available connectors
    static let library: [MCPConnector] = [
        // Storage
        MCPConnector(
            id: "connector_dropbox",
            name: "Dropbox",
            description: "Search, fetch, and manage files in your Dropbox",
            icon: "cloud.fill",
            color: "#0061FF",
            oauthScopes: ["files.metadata.read", "files.content.read", "account_info.read"],
            oauthInstructions: "Visit Dropbox's App Console to create an OAuth app and obtain an access token.",
            setupURL: "https://www.dropbox.com/developers/apps",
            category: .storage,
            popularTools: ["search_files", "fetch_file", "list_recent_files"],
            requiresRemoteServer: false
        ),

        MCPConnector(
            id: "connector_googledrive",
            name: "Google Drive",
            description: "Search and access files in Google Drive",
            icon: "square.3.layers.3d",
            color: "#4285F4",
            oauthScopes: ["https://www.googleapis.com/auth/drive.readonly"],
            oauthInstructions: "Use Google OAuth Playground or create a Google Cloud project. Required scope: drive.readonly",
            setupURL: "https://developers.google.com/oauthplayground/",
            category: .storage,
            popularTools: ["search", "recent_documents", "fetch"],
            requiresRemoteServer: false
        ),

        MCPConnector(
            id: "connector_sharepoint",
            name: "SharePoint",
            description: "Access SharePoint sites and documents",
            icon: "building.2.fill",
            color: "#036C70",
            oauthScopes: ["Sites.Read.All", "Files.Read.All"],
            oauthInstructions: "Register an Azure AD app and grant Microsoft Graph permissions.",
            setupURL: "https://portal.azure.com/",
            category: .storage,
            popularTools: ["search", "list_recent_documents", "fetch"],
            requiresRemoteServer: false
        ),

        // Email
        MCPConnector(
            id: "connector_gmail",
            name: "Gmail",
            description: "Search, read, and manage your Gmail messages",
            icon: "envelope.fill",
            color: "#EA4335",
            oauthScopes: ["https://www.googleapis.com/auth/gmail.modify"],
            oauthInstructions: "Use Google OAuth Playground. Required scope: gmail.modify",
            setupURL: "https://developers.google.com/oauthplayground/",
            category: .email,
            popularTools: ["search_emails", "read_email", "get_recent_emails"],
            requiresRemoteServer: false
        ),

        MCPConnector(
            id: "connector_outlookemail",
            name: "Outlook Email",
            description: "Access and search your Outlook emails",
            icon: "envelope.badge.fill",
            color: "#0078D4",
            oauthScopes: ["Mail.Read"],
            oauthInstructions: "Register an Azure AD app with Mail.Read permission.",
            setupURL: "https://portal.azure.com/",
            category: .email,
            popularTools: ["list_messages", "search_messages", "fetch_message"],
            requiresRemoteServer: false
        ),

        // Calendar
        MCPConnector(
            id: "connector_googlecalendar",
            name: "Google Calendar",
            description: "View and search your Google Calendar events",
            icon: "calendar",
            color: "#4285F4",
            oauthScopes: ["https://www.googleapis.com/auth/calendar.events"],
            oauthInstructions: "Use Google OAuth Playground. Required scope: calendar.events",
            setupURL: "https://developers.google.com/oauthplayground/",
            category: .calendar,
            popularTools: ["search_events", "read_event"],
            requiresRemoteServer: false
        ),

        MCPConnector(
            id: "connector_outlookcalendar",
            name: "Outlook Calendar",
            description: "Access your Outlook calendar events",
            icon: "calendar.badge.clock",
            color: "#0078D4",
            oauthScopes: ["Calendars.Read"],
            oauthInstructions: "Register an Azure AD app with Calendars.Read permission.",
            setupURL: "https://portal.azure.com/",
            category: .calendar,
            popularTools: ["search_events", "list_events", "fetch_event"],
            requiresRemoteServer: false
        ),

        // Collaboration
        MCPConnector(
            id: "connector_microsoftteams",
            name: "Microsoft Teams",
            description: "Search Teams chats and channel messages",
            icon: "person.3.fill",
            color: "#6264A7",
            oauthScopes: ["Chat.Read", "ChannelMessage.Read.All"],
            oauthInstructions: "Register an Azure AD app with Teams permissions.",
            setupURL: "https://portal.azure.com/",
            category: .collaboration,
            popularTools: ["search", "fetch", "get_chat_members"],
            requiresRemoteServer: false
        ),

        // Productivity
        // REMOVED: Notion MCP connector (broken - use Direct Notion Integration instead)
        // The connector_notion entry has been removed because mcp.notion.com requires OAuth tokens
        // not integration tokens. Use Settings → MCP → Direct Notion Integration for working access.
    ]

    /// Get connector by ID
    static func connector(for id: String) -> MCPConnector? {
        library.first { $0.id == id }
    }

    /// Get connectors by category
    static func connectors(in category: ConnectorCategory) -> [MCPConnector] {
        library.filter { $0.category == category }
    }

    /// Search connectors by name or description
    static func search(_ query: String) -> [MCPConnector] {
        let lowercased = query.lowercased()
        return library.filter {
            $0.name.lowercased().contains(lowercased) ||
                $0.description.lowercased().contains(lowercased)
        }
    }
}

/// Represents a custom remote MCP server configuration
struct RemoteMCPServer: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var serverURL: String
    var serverDescription: String?
    var requireApproval: MCPApprovalSetting
    var allowedTools: [String]?

    /// User-friendly display name (can contain spaces/special chars)
    /// Falls back to label if not set
    var displayLabel: String?

    /// The label to show in UI - uses displayLabel if set, otherwise label
    var uiLabel: String {
        displayLabel ?? label
    }

    init(id: UUID = UUID(), label: String, serverURL: String, serverDescription: String? = nil, requireApproval: MCPApprovalSetting = .always, allowedTools: [String]? = nil, displayLabel: String? = nil) {
        self.id = id
        self.label = label
        self.serverURL = serverURL
        self.serverDescription = serverDescription
        self.requireApproval = requireApproval
        self.allowedTools = allowedTools
        self.displayLabel = displayLabel
    }

    /// Official Notion MCP server template (hosted by Notion)
    static let notionOfficial = RemoteMCPServer(
        label: "notion-mcp-official",
        serverURL: "https://mcp.notion.com/mcp",
        serverDescription: "Notion hosted MCP server (OAuth-based). This app does not currently support connecting to mcp.notion.com via OAuth, so this template is informational only.",
        requireApproval: .never,
        allowedTools: nil, // Empty = all tools available
        displayLabel: "Notion MCP (Official)"
    )

    /// Self-hosted Notion MCP template (user's custom Docker + ngrok setup)
    static let notionCustom = RemoteMCPServer(
        label: "notion-mcp-custom",
        serverURL: "https://your-ngrok-url.ngrok-free.app/mcp",
        serverDescription: "Self-hosted Notion MCP server. Runs on Docker with ngrok tunnel. Requires Bearer token from container logs.",
        requireApproval: .never,
        allowedTools: nil, // Empty = all tools available
        displayLabel: "Notion MCP (Self-Hosted)"
    )

    /// GCP-hosted Notion MCP template (your Cloud Run deployment)
    static let notionGCloud = RemoteMCPServer(
        label: "notion-gcloud",
        serverURL: "https://your-cloud-run-service.a.run.app/mcp",
        serverDescription: "Self-hosted Notion MCP server (Cloud Run).",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Notion MCP (GCP)"
    )

    // MARK: - Official Third-Party MCP Servers

    /// GitHub MCP Server (official, hosted by GitHub)
    static let github = RemoteMCPServer(
        label: "github",
        serverURL: "https://api.githubcopilot.com/mcp/",
        serverDescription: "Official GitHub MCP server. Access repositories, issues, PRs, and code search. Requires GitHub OAuth token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "GitHub"
    )

    /// Stripe MCP Server (official, hosted by Stripe)
    static let stripe = RemoteMCPServer(
        label: "stripe",
        serverURL: "https://mcp.stripe.com",
        serverDescription: "Official Stripe MCP server. Create payment links, manage customers, and access billing data. Requires Stripe OAuth token.",
        requireApproval: .always,
        allowedTools: nil,
        displayLabel: "Stripe"
    )

    /// DeepWiki MCP Server (official)
    static let deepwiki = RemoteMCPServer(
        label: "deepwiki",
        serverURL: "https://mcp.deepwiki.com/mcp",
        serverDescription: "DeepWiki MCP server. Ask questions about GitHub repositories and read wiki structures. No auth required.",
        requireApproval: .never,
        allowedTools: ["ask_question", "read_wiki_structure"],
        displayLabel: "DeepWiki"
    )

    /// Cloudflare MCP Server (official)
    static let cloudflare = RemoteMCPServer(
        label: "cloudflare",
        serverURL: "https://mcp.cloudflare.com/sse",
        serverDescription: "Official Cloudflare MCP server. Manage Workers, KV, R2, and D1. Requires Cloudflare API token.",
        requireApproval: .always,
        allowedTools: nil,
        displayLabel: "Cloudflare"
    )

    /// Sentry MCP Server (official)
    static let sentry = RemoteMCPServer(
        label: "sentry",
        serverURL: "https://mcp.sentry.dev/sse",
        serverDescription: "Official Sentry MCP server. Search issues, view stack traces, and analyze errors. Requires Sentry auth token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Sentry"
    )

    /// Linear MCP Server (official)
    static let linear = RemoteMCPServer(
        label: "linear",
        serverURL: "https://mcp.linear.app/sse",
        serverDescription: "Official Linear MCP server. Manage issues, projects, and cycles. Requires Linear OAuth token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Linear"
    )

    /// Figma MCP Server (community)
    static let figma = RemoteMCPServer(
        label: "figma",
        serverURL: "https://your-figma-mcp-server.com/sse",
        serverDescription: "Figma MCP server. Access designs, components, and export assets. Requires Figma personal access token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Figma"
    )

    /// Slack MCP Server (community)
    static let slack = RemoteMCPServer(
        label: "slack",
        serverURL: "https://your-slack-mcp-server.com/sse",
        serverDescription: "Slack MCP server. Send messages, search channels, and access workspace data. Requires Slack OAuth token.",
        requireApproval: .always,
        allowedTools: nil,
        displayLabel: "Slack"
    )

    /// Asana MCP Server (community)
    static let asana = RemoteMCPServer(
        label: "asana",
        serverURL: "https://your-asana-mcp-server.com/sse",
        serverDescription: "Asana MCP server. Manage tasks, projects, and workspaces. Requires Asana personal access token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Asana"
    )

    /// Jira MCP Server (community)
    static let jira = RemoteMCPServer(
        label: "jira",
        serverURL: "https://your-jira-mcp-server.com/sse",
        serverDescription: "Jira MCP server. Search issues, manage sprints, and track projects. Requires Atlassian API token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Jira"
    )

    /// Airtable MCP Server (community)
    static let airtable = RemoteMCPServer(
        label: "airtable",
        serverURL: "https://your-airtable-mcp-server.com/sse",
        serverDescription: "Airtable MCP server. Query bases, create records, and manage tables. Requires Airtable personal access token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Airtable"
    )

    /// Todoist MCP Server (community)
    static let todoist = RemoteMCPServer(
        label: "todoist",
        serverURL: "https://your-todoist-mcp-server.com/sse",
        serverDescription: "Todoist MCP server. Manage tasks, projects, and labels. Requires Todoist API token.",
        requireApproval: .never,
        allowedTools: nil,
        displayLabel: "Todoist"
    )

    /// Popular MCP server templates for quick setup
    static let templates: [RemoteMCPServer] = [
        // Official third-party servers (verified URLs)
        .github,
        .stripe,
        .deepwiki,
        .cloudflare,
        .sentry,
        .linear,
        // Self-hosted templates (require user URL)
        .figma,
        .slack,
        .asana,
        .jira,
        .airtable,
        .todoist,
    ]

    /// Categorized templates for UI display
    static let officialServers: [RemoteMCPServer] = [
        .github,
        .stripe,
        .deepwiki,
        .cloudflare,
        .sentry,
        .linear,
    ]

    static let communityServers: [RemoteMCPServer] = [
        .figma,
        .slack,
        .asana,
        .jira,
        .airtable,
        .todoist,
    ]
}

/// MCP approval settings
enum MCPApprovalSetting: Codable, Hashable {
    case always
    case never
    case specificTools([String])

    var displayName: String {
        switch self {
        case .always: return "Always require approval"
        case .never: return "Never require approval"
        case let .specificTools(tools): return "Require approval for \(tools.count) tools"
        }
    }
}

/// Combined MCP configuration that can be either a connector or remote server
enum MCPConfiguration: Identifiable, Codable, Hashable {
    case connector(MCPConnectorConfig)
    case remoteServer(RemoteMCPServer)

    var id: String {
        switch self {
        case let .connector(config): return "connector_\(config.connectorId)"
        case let .remoteServer(server): return "server_\(server.id.uuidString)"
        }
    }

    var displayName: String {
        switch self {
        case let .connector(config): return MCPConnector.connector(for: config.connectorId)?.name ?? config.connectorId
        case let .remoteServer(server): return server.label
        }
    }

    var requiresOAuth: Bool {
        switch self {
        case .connector: return true
        case let .remoteServer(server): return !server.serverURL.isEmpty
        }
    }
}

/// Active connector configuration with OAuth token
struct MCPConnectorConfig: Identifiable, Codable, Hashable {
    let id: UUID
    let connectorId: String
    var requireApproval: MCPApprovalSetting
    var allowedTools: [String]?
    var isEnabled: Bool

    init(id: UUID = UUID(), connectorId: String, requireApproval: MCPApprovalSetting = .always, allowedTools: [String]? = nil, isEnabled: Bool = true) {
        self.id = id
        self.connectorId = connectorId
        self.requireApproval = requireApproval
        self.allowedTools = allowedTools
        self.isEnabled = isEnabled
    }

    var connector: MCPConnector? {
        MCPConnector.connector(for: connectorId)
    }
}
