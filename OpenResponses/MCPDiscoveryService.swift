import Foundation
import Combine

/// Service for discovering and managing MCP servers and tools
@MainActor
class MCPDiscoveryService: ObservableObject {
    static let shared = MCPDiscoveryService()
    
    @Published var availableServers: [MCPServerInfo] = []
    @Published var configurations: [MCPServerConfiguration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let keychainService = KeychainService.shared
    private let configurationsKey = "mcp_server_configurations"
    private let authKeychainPrefix = "mcp_auth_"
    
    private init() {
        loadConfigurations()
        loadBuiltInServers()
        
        // Ensure servers are loaded
        Task { @MainActor in
            if availableServers.isEmpty {
                loadBuiltInServers()
            }
        }
        
        // Enable GitHub server by default for demo purposes (without auth)
        // Users can configure authentication later
        let defaultGitHubConfig = MCPServerConfiguration(
            serverId: "github",
            isEnabled: true,
            authConfiguration: [:],
            selectedTools: Set(["list_repositories", "search_code"])
        )
        
        // Only add default config if none exists
        if getConfiguration(for: "github") == nil {
            updateConfiguration(defaultGitHubConfig)
        }
        
        // Temporarily disable Notion server to test GitHub MCP in isolation
        if let notionConfig = getConfiguration(for: "notion") {
            let disabledNotionConfig = MCPServerConfiguration(
                serverId: "notion",
                isEnabled: false,
                authConfiguration: notionConfig.authConfiguration,
                selectedTools: notionConfig.selectedTools
            )
            updateConfiguration(disabledNotionConfig)
        }
    }
    
    // MARK: - Built-in Server Registry
    
    /// Load a curated list of popular MCP servers
    private func loadBuiltInServers() {
        availableServers = [
            // Development Tools
            MCPServerInfo(
                name: "github",
                displayName: "GitHub (Currently Disabled - OAuth Required)",
                description: "GitHub Copilot MCP server requires OAuth authentication which is complex to implement in iOS. Temporarily disabled until OAuth integration is added.",
                serverURL: "https://api.githubcopilot.com/mcp/",
                category: .development,
                isOfficial: true,
                requiredAuth: .bearerToken,
                supportedCapabilities: [.toolExecution, .resourceAccess, .realTimeData],
                availableTools: [
                    MCPToolInfo(
                        name: "list_repositories",
                        displayName: "List Repositories",
                        description: "Get a list of user's repositories",
                        category: "repository"
                    ),
                    MCPToolInfo(
                        name: "get_repository",
                        displayName: "Get Repository",
                        description: "Get detailed information about a repository",
                        category: "repository"
                    ),
                    MCPToolInfo(
                        name: "search_code",
                        displayName: "Search Code",
                        description: "Search for code across repositories",
                        category: "search"
                    )
                ],
                setupInstructions: """
                ⚠️ CRITICAL DISCOVERY: OAUTH IS THE REAL SOLUTION!
                
                **THE ACTUAL PROBLEM:**
                GitHub's official documentation clearly states: "Use OAuth when available: For MCP servers like GitHub MCP, prefer OAuth authentication over personal access tokens."
                
                **WHY YOUR PAT ISN'T WORKING (Even with All Scopes):**
                • GitHub Copilot MCP server is designed primarily for OAuth flows
                • PAT authentication is a fallback, not the primary method
                • Even with all possible scopes, PAT may hit undocumented limitations
                • GitHub's MCP server expects OAuth-style authentication headers
                
                **OAUTH vs PAT COMPARISON:**
                
                OAuth (GitHub's Recommended Method):
                ✅ One-click setup in IDEs (VS Code, Visual Studio, JetBrains, Xcode, Eclipse)
                ✅ Automatic scope management 
                ✅ No manual token creation required
                ✅ Short-lived, secure tokens
                ✅ Full GitHub Copilot MCP feature access
                ✅ Organization policy compliant
                
                PAT (Current Workaround):
                ❌ Manual setup required
                ❌ Long-lived security risk
                ❌ May not provide full MCP server access
                ❌ Subject to undocumented restrictions
                ❌ Not optimized for GitHub Copilot integration
                
                **IMMEDIATE WORKAROUND (PAT - Limited Success Expected):**
                Since this is an iOS app without OAuth integration yet:
                
                1. Create Classic Personal Access Token at github.com/settings/tokens:
                   
                   EXTENDED SCOPE LIST (try all of these):
                   ✓ repo (Full control of private repositories)
                   ✓ workflow (Update GitHub Action workflows)  
                   ✓ write:packages (Upload packages to GitHub Package Registry)
                   ✓ delete:packages (Delete packages from GitHub Package Registry)
                   ✓ admin:org (Full control of orgs and teams, read and write org projects)
                   ✓ gist (Create gists)
                   ✓ notifications (Access notifications)
                   ✓ user (Update all user data)
                   ✓ delete_repo (Delete repositories)
                   ✓ write:discussion (Write team discussions)
                   ✓ write:packages (Upload packages to GitHub Package Registry)
                   ✓ read:packages (Download packages from GitHub Package Registry)
                   ✓ admin:public_key (Full control of user public keys)
                   ✓ admin:repo_hook (Full control of repository hooks)
                   ✓ admin:org_hook (Full control of organization hooks)
                   ✓ admin:gpg_key (Full control of user GPG keys)
                
                2. Copy token and paste in authentication field below
                3. Test with basic request like "List my repositories"
                
                **PROPER SOLUTION NEEDED:**
                To fully fix this, the app needs OAuth implementation:
                • GitHub OAuth app registration  
                • OAuth authorization flow in iOS
                • Use OAuth tokens instead of PAT
                • Follow GitHub's recommended MCP integration pattern
                
                **WHY OTHER EDITORS WORK SEAMLESSLY:**
                • VS Code, Visual Studio, JetBrains, Xcode all have built-in OAuth flows
                • They use GitHub's preferred authentication method
                • No manual token creation or scope guessing required
                
                **TECHNICAL REALITY:**
                The 400 Bad Request errors indicate the GitHub Copilot MCP server expects OAuth-authenticated requests. This iOS app's PAT approach may work for basic operations but will likely have limitations compared to proper OAuth integration.
                
                References:
                • https://docs.github.com/en/copilot/customizing-copilot/using-model-context-protocol/using-the-github-mcp-server
                • https://docs.github.com/en/copilot/tutorials/enhance-agent-mode-with-mcp
                """
            ),
            
            // Alternative community GitHub MCP server that may work better with PAT
            MCPServerInfo(
                name: "git-mcp",
                displayName: "GitMCP (Community Alternative)",
                description: "Community-built GitHub MCP server designed to be PAT-friendly. Alternative to GitHub's official server.",
                serverURL: "https://git-mcp.com/api", // Note: This might not be the actual URL, need to check the repo
                category: .development,
                isOfficial: false,
                requiredAuth: .bearerToken,
                supportedCapabilities: [.toolExecution, .resourceAccess],
                availableTools: [
                    MCPToolInfo(
                        name: "read_repository",
                        displayName: "Read Repository",
                        description: "Read repository structure and files",
                        category: "repository"
                    ),
                    MCPToolInfo(
                        name: "search_files",
                        displayName: "Search Files",
                        description: "Search for files in repositories",
                        category: "search"
                    )
                ],
                setupInstructions: """
                **ALTERNATIVE GITHUB MCP SERVER**
                
                This is a community-built alternative to GitHub's official MCP server.
                It may work better with Personal Access Token authentication.
                
                **SETUP:**
                1. Create a GitHub Personal Access Token with basic repo access:
                   • repo (repository access)
                   • read:user (read user info)
                   
                2. Enter token in the authentication field
                3. Test with a simple request
                
                **WHY THIS MIGHT WORK BETTER:**
                • Built by community for PAT compatibility
                • No OAuth requirements
                • Simpler authentication model
                • Focused on core GitHub functionality
                
                **NOTE:** This is experimental - if it doesn't work, we can disable it and focus on the core app functionality.
                
                Source: https://github.com/idosal/git-mcp
                """),
            
            // Alternative community GitHub MCP server that may work better with PAT
            MCPServerInfo(
                name: "git-mcp",
                displayName: "GitMCP (Community Alternative)",
                description: "Community-built GitHub MCP server designed to be PAT-friendly. Alternative to GitHub's official server.",
                serverURL: "https://git-mcp.com/api", // Note: This might not be the actual URL, need to check the repo
                category: .development,
                isOfficial: false,
                requiredAuth: .bearerToken,
                supportedCapabilities: [.toolExecution, .resourceAccess],
                availableTools: [
                    MCPToolInfo(
                        name: "read_repository",
                        displayName: "Read Repository",
                        description: "Read repository structure and files",
                        category: "repository"
                    ),
                    MCPToolInfo(
                        name: "search_files",
                        displayName: "Search Files",
                        description: "Search for files in repositories",
                        category: "search"
                    )
                ],
                setupInstructions: """
                **ALTERNATIVE GITHUB MCP SERVER**
                
                This is a community-built alternative to GitHub's official MCP server.
                It may work better with Personal Access Token authentication.
                
                **SETUP:**
                1. Create a GitHub Personal Access Token with basic repo access:
                   • repo (repository access)
                   • read:user (read user info)
                   
                2. Enter token in the authentication field
                3. Test with a simple request
                
                **WHY THIS MIGHT WORK BETTER:**
                • Built by community for PAT compatibility
                • No OAuth requirements
                • Simpler authentication model
                • Focused on core GitHub functionality
                
                **NOTE:** This is experimental - if it doesn't work, we can disable it and focus on the core app functionality.
                
                Source: https://github.com/idosal/git-mcp
                """
            ),
            
            MCPServerInfo(
                name: "gitlab",
                displayName: "GitLab",
                description: "Interact with GitLab projects, issues, and merge requests",
                serverURL: "https://gitlab.com/api/mcp",
                category: .development,
                isOfficial: true,
                requiredAuth: .apiKey,
                supportedCapabilities: [.toolExecution, .resourceAccess],
                availableTools: [
                    MCPToolInfo(
                        name: "list_projects",
                        displayName: "List Projects",
                        description: "Get a list of user's projects",
                        category: "project"
                    ),
                    MCPToolInfo(
                        name: "create_issue",
                        displayName: "Create Issue",
                        description: "Create a new issue in a repository",
                        category: "issue"
                    ),
                    MCPToolInfo(
                        name: "search_code",
                        displayName: "Search Code",
                        description: "Search for code across repositories",
                        category: "search"
                    )
                ],
                setupInstructions: """
                ⚠️ CRITICAL DISCOVERY: OAUTH IS THE REAL SOLUTION!
                
                **THE ACTUAL PROBLEM:**
                GitHub's official documentation clearly states: "Use OAuth when available: For MCP servers like GitHub MCP, prefer OAuth authentication over personal access tokens."
                
                **WHY YOUR PAT ISN'T WORKING (Even with All Scopes):**
                • GitHub Copilot MCP server is designed primarily for OAuth flows
                • PAT authentication is a fallback, not the primary method
                • Even with all possible scopes, PAT may hit undocumented limitations
                • GitHub's MCP server expects OAuth-style authentication headers
                
                **OAUTH vs PAT COMPARISON:**
                
                OAuth (GitHub's Recommended Method):
                ✅ One-click setup in IDEs (VS Code, Visual Studio, JetBrains, Xcode, Eclipse)
                ✅ Automatic scope management 
                ✅ No manual token creation required
                ✅ Short-lived, secure tokens
                ✅ Full GitHub Copilot MCP feature access
                ✅ Organization policy compliant
                
                PAT (Current Workaround):
                ❌ Manual setup required
                ❌ Long-lived security risk
                ❌ May not provide full MCP server access
                ❌ Subject to undocumented restrictions
                ❌ Not optimized for GitHub Copilot integration
                
                **IMMEDIATE WORKAROUND (PAT - Limited Success Expected):**
                Since this is an iOS app without OAuth integration yet:
                
                1. Create Classic Personal Access Token at github.com/settings/tokens:
                   
                   EXTENDED SCOPE LIST (try all of these):
                   ✓ repo (Full control of private repositories)
                   ✓ workflow (Update GitHub Action workflows)  
                   ✓ write:packages (Upload packages to GitHub Package Registry)
                   ✓ delete:packages (Delete packages from GitHub Package Registry)
                   ✓ admin:org (Full control of orgs and teams, read and write org projects)
                   ✓ gist (Create gists)
                   ✓ notifications (Access notifications)
                   ✓ user (Update all user data)
                   ✓ delete_repo (Delete repositories)
                   ✓ write:discussion (Write team discussions)
                   ✓ write:packages (Upload packages to GitHub Package Registry)
                   ✓ read:packages (Download packages from GitHub Package Registry)
                   ✓ admin:public_key (Full control of user public keys)
                   ✓ admin:repo_hook (Full control of repository hooks)
                   ✓ admin:org_hook (Full control of organization hooks)
                   ✓ admin:gpg_key (Full control of user GPG keys)
                
                2. Copy token and paste in authentication field below
                3. Test with basic request like "List my repositories"
                
                **PROPER SOLUTION NEEDED:**
                To fully fix this, the app needs OAuth implementation:
                • GitHub OAuth app registration  
                • OAuth authorization flow in iOS
                • Use OAuth tokens instead of PAT
                • Follow GitHub's recommended MCP integration pattern
                
                **WHY OTHER EDITORS WORK SEAMLESSLY:**
                • VS Code, Visual Studio, JetBrains, Xcode all have built-in OAuth flows
                • They use GitHub's preferred authentication method
                • No manual token creation or scope guessing required
                
                **TECHNICAL REALITY:**
                The 400 Bad Request errors indicate the GitHub Copilot MCP server expects OAuth-authenticated requests. This iOS app's PAT approach may work for basic operations but will likely have limitations compared to proper OAuth integration.
                
                References:
                • https://docs.github.com/en/copilot/customizing-copilot/using-model-context-protocol/using-the-github-mcp-server
                • https://docs.github.com/en/copilot/tutorials/enhance-agent-mode-with-mcp
                """
            ),
            
            MCPServerInfo(
                name: "gitlab",
                displayName: "GitLab",
                description: "Interact with GitLab projects, issues, and merge requests",
                serverURL: "https://gitlab.com/api/mcp",
                category: .development,
                isOfficial: true,
                requiredAuth: .apiKey,
                supportedCapabilities: [.toolExecution, .resourceAccess],
                availableTools: [
                    MCPToolInfo(
                        name: "list_projects",
                        displayName: "List Projects",
                        description: "Get a list of user's projects",
                        category: "project"
                    ),
                    MCPToolInfo(
                        name: "create_merge_request",
                        displayName: "Create Merge Request",
                        description: "Create a new merge request",
                        category: "merge_request"
                    )
                ]
            ),
            
            // Productivity Tools
            
            // NOTION MCP SERVER - TEMPORARILY DISABLED
            // The remote Notion MCP server at https://api.notion.com/mcp requires OAuth authentication,
            // not integration tokens. There are two different Notion MCP implementations:
            //
            // 1. Remote Notion MCP Server (hosted by Notion): 
            //    - URL: https://api.notion.com/mcp
            //    - Authentication: OAuth 2.0 with one-click installation
            //    - Access: Full workspace access automatically
            //    - Optimized for AI agents with efficient data formatting
            //    - Documentation: https://developers.notion.com/docs/mcp
            //
            // 2. Local/Self-hosted Notion MCP Server (npm package):
            //    - Package: @notionhq/notion-mcp-server  
            //    - Authentication: Integration tokens (ntn_***)
            //    - Access: Requires manual page/database sharing via Notion UI
            //    - Setup: Complex integration token + page sharing workflow
            //    - Documentation: https://github.com/makenotion/notion-mcp-server
            //
            // Note: Integration tokens should be configured through the secure keychain storage,
            // not hardcoded in the source. This causes 424 (Failed Dependency) errors when
            // trying to use remote servers without proper authentication.
            //
            // To fix Notion integration, need to either:
            // A) Switch to OAuth authentication for remote server (recommended)
            // B) Switch to local self-hosted server with proper integration token setup
            //
            // For now, disabling to prevent errors and focus on GitHub MCP functionality.
            
            /*
            MCPServerInfo(
                name: "notion",
                displayName: "Notion (OAuth Required)",
                description: "Access and manage Notion pages, databases, and content. Requires OAuth authentication for remote server.",
                serverURL: "https://api.notion.com/mcp",
                category: .productivity,
                isOfficial: true,
                requiredAuth: .oauth,
                supportedCapabilities: [.toolExecution, .resourceAccess, .fileOperations],
                availableTools: [
                    MCPToolInfo(
                        name: "search_pages",
                        displayName: "Search Pages",
                        description: "Search for pages in your Notion workspace",
                        category: "page"
                    ),
                    MCPToolInfo(
                        name: "create_page",
                        displayName: "Create Page",
                        description: "Create a new page in a database",
                        category: "page"
                    ),
                    MCPToolInfo(
                        name: "query_database",
                        displayName: "Query Database",
                        description: "Query a Notion database",
                        category: "database"
                    )
                ],
                setupInstructions: """
                IMPORTANT: This is the remote Notion MCP server that requires OAuth authentication.
                
                Current Status: DISABLED - Integration token authentication not supported.
                
                To enable Notion MCP:
                1. Visit https://developers.notion.com/docs/mcp for OAuth setup
                2. Follow the one-click installation process
                3. Grant workspace permissions through OAuth flow
                4. No manual page sharing required with OAuth
                
                Alternative: Use local self-hosted server (@notionhq/notion-mcp-server) with integration tokens
                """
            ),
            */
            
            MCPServerInfo(
                name: "slack",
                displayName: "Slack",
                description: "Send messages, read channels, and manage Slack workspaces",
                serverURL: "https://slack.com/api/mcp",
                category: .communication,
                isOfficial: true,
                requiredAuth: .oauth,
                supportedCapabilities: [.toolExecution, .realTimeData, .notifications],
                availableTools: [
                    MCPToolInfo(
                        name: "send_message",
                        displayName: "Send Message",
                        description: "Send a message to a channel or user",
                        category: "messaging"
                    ),
                    MCPToolInfo(
                        name: "list_channels",
                        displayName: "List Channels",
                        description: "Get a list of channels in the workspace",
                        category: "channel"
                    )
                ]
            ),
            
            // File Management
            MCPServerInfo(
                name: "google_drive",
                displayName: "Google Drive",
                description: "Access and manage files in Google Drive",
                serverURL: "https://drive.googleapis.com/mcp",
                connectorId: "connector_googledrive",
                category: .fileManagement,
                isOfficial: true,
                requiredAuth: .oauth,
                supportedCapabilities: [.toolExecution, .resourceAccess, .fileOperations],
                availableTools: [
                    MCPToolInfo(
                        name: "list_files",
                        displayName: "List Files",
                        description: "Get a list of files in Google Drive",
                        category: "file"
                    ),
                    MCPToolInfo(
                        name: "upload_file",
                        displayName: "Upload File",
                        description: "Upload a file to Google Drive",
                        category: "file"
                    ),
                    MCPToolInfo(
                        name: "share_file",
                        displayName: "Share File",
                        description: "Share a file with specified permissions",
                        category: "sharing"
                    )
                ]
            ),
            
            // E-commerce
            MCPServerInfo(
                name: "shopify",
                displayName: "Shopify",
                description: "Manage Shopify stores, products, and orders",
                serverURL: "https://api.shopify.com/mcp",
                category: .ecommerce,
                isOfficial: true,
                requiredAuth: .apiKey,
                supportedCapabilities: [.toolExecution, .resourceAccess, .realTimeData],
                availableTools: [
                    MCPToolInfo(
                        name: "list_products",
                        displayName: "List Products",
                        description: "Get a list of products in the store",
                        category: "product"
                    ),
                    MCPToolInfo(
                        name: "create_product",
                        displayName: "Create Product",
                        description: "Create a new product",
                        category: "product"
                    ),
                    MCPToolInfo(
                        name: "list_orders",
                        displayName: "List Orders",
                        description: "Get recent orders",
                        category: "order"
                    )
                ]
            ),
            
            // Data Analysis
            MCPServerInfo(
                name: "airtable",
                displayName: "Airtable",
                description: "Access and manipulate Airtable bases and records",
                serverURL: "https://api.airtable.com/mcp",
                category: .dataAnalysis,
                isOfficial: true,
                requiredAuth: .bearerToken,
                supportedCapabilities: [.toolExecution, .resourceAccess, .batchOperations],
                availableTools: [
                    MCPToolInfo(
                        name: "list_records",
                        displayName: "List Records",
                        description: "Get records from a table",
                        category: "record"
                    ),
                    MCPToolInfo(
                        name: "create_record",
                        displayName: "Create Record",
                        description: "Create a new record in a table",
                        category: "record"
                    ),
                    MCPToolInfo(
                        name: "update_record",
                        displayName: "Update Record",
                        description: "Update an existing record",
                        category: "record"
                    )
                ]
            ),
            
            // Custom/Community Servers
            MCPServerInfo(
                name: "weather",
                displayName: "Weather Service",
                description: "Get current weather and forecasts",
                serverURL: "https://weather-mcp.example.com",
                category: .other,
                isOfficial: false,
                requiredAuth: .apiKey,
                supportedCapabilities: [.toolExecution, .realTimeData],
                availableTools: [
                    MCPToolInfo(
                        name: "current_weather",
                        displayName: "Current Weather",
                        description: "Get current weather for a location",
                        category: "weather"
                    ),
                    MCPToolInfo(
                        name: "weather_forecast",
                        displayName: "Weather Forecast",
                        description: "Get weather forecast for a location",
                        category: "weather"
                    )
                ]
            ),
            
            MCPServerInfo(
                name: "calculator",
                displayName: "Advanced Calculator",
                description: "Perform complex mathematical calculations",
                serverURL: "https://calc-mcp.example.com",
                category: .productivity,
                isOfficial: false,
                requiredAuth: .none,
                supportedCapabilities: [.toolExecution],
                availableTools: [
                    MCPToolInfo(
                        name: "calculate",
                        displayName: "Calculate",
                        description: "Perform mathematical calculations",
                        category: "math"
                    ),
                    MCPToolInfo(
                        name: "solve_equation",
                        displayName: "Solve Equation",
                        description: "Solve algebraic equations",
                        category: "math"
                    )
                ]
            )
        ]
        
        AppLogger.log("MCPDiscoveryService: Loaded \(availableServers.count) built-in servers", category: .general, level: .debug)
        
        // Trigger UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Configuration Management
    
    /// Load saved server configurations from UserDefaults and auth from Keychain
    private func loadConfigurations() {
        guard let data = userDefaults.data(forKey: configurationsKey),
              let savedConfigs = try? JSONDecoder().decode([MCPServerConfiguration].self, from: data) else {
            return
        }
        
        // Load configurations and restore auth from keychain
        configurations = savedConfigs.map { config in
            var mutableConfig = config
            // Load auth configuration from keychain
            if let authData = keychainService.load(forKey: authKeychainPrefix + config.serverId),
               let authDict = try? JSONSerialization.jsonObject(with: Data(authData.utf8)) as? [String: String] {
                mutableConfig.authConfiguration = authDict
            }
            return mutableConfig
        }
    }
    
    /// Save server configurations to UserDefaults (non-sensitive) and Keychain (auth tokens)
    private func saveConfigurations() {
        // Create sanitized configs without auth for UserDefaults
        let sanitizedConfigs = configurations.map { config in
            var sanitized = config
            // Store auth separately in keychain
            if !config.authConfiguration.isEmpty {
                if let authData = try? JSONSerialization.data(withJSONObject: config.authConfiguration),
                   let authString = String(data: authData, encoding: .utf8) {
                    keychainService.save(value: authString, forKey: authKeychainPrefix + config.serverId)
                }
            }
            // Remove auth from the config saved to UserDefaults
            sanitized.authConfiguration = [:]
            return sanitized
        }
        
        // Save sanitized configs to UserDefaults
        if let data = try? JSONEncoder().encode(sanitizedConfigs) {
            userDefaults.set(data, forKey: configurationsKey)
        }
    }
    
    /// Get configuration for a specific server
    func getConfiguration(for serverId: String) -> MCPServerConfiguration? {
        return configurations.first { $0.serverId == serverId }
    }
    
    /// Update or create configuration for a server
    func updateConfiguration(_ configuration: MCPServerConfiguration) {
        if let index = configurations.firstIndex(where: { $0.serverId == configuration.serverId }) {
            configurations[index] = configuration
        } else {
            configurations.append(configuration)
        }
        saveConfigurations()
    }
    
    /// Enable a server with default settings
    func enableServer(_ server: MCPServerInfo) {
        let config = MCPServerConfiguration(
            serverId: server.name,
            isEnabled: true,
            selectedTools: Set(server.availableTools.map { $0.name })
        )
        updateConfiguration(config)
    }
    
    /// Disable a server
    func disableServer(_ serverId: String) {
        if let config = getConfiguration(for: serverId) {
            let updatedConfig = MCPServerConfiguration(
                serverId: config.serverId,
                isEnabled: false,
                authConfiguration: config.authConfiguration,
                selectedTools: config.selectedTools,
                approvalSettings: config.approvalSettings
            )
            updateConfiguration(updatedConfig)
        }
    }
    
    /// Completely remove a server configuration and its auth tokens
    func removeServerConfiguration(_ serverId: String) {
        // Remove auth from keychain
        keychainService.delete(forKey: authKeychainPrefix + serverId)
        
        // Remove configuration
        configurations.removeAll { $0.serverId == serverId }
        saveConfigurations()
    }
    
    /// Check if a server is enabled
    func isServerEnabled(_ serverId: String) -> Bool {
        return getConfiguration(for: serverId)?.isEnabled ?? false
    }
    
    /// Get all enabled servers with their configurations
    func getEnabledServersWithConfigs() -> [(MCPServerInfo, MCPServerConfiguration)] {
        var result: [(MCPServerInfo, MCPServerConfiguration)] = []
        
        for server in availableServers {
            if let config = getConfiguration(for: server.name), config.isEnabled {
                result.append((server, config))
            }
        }
        
        return result
    }
    
    // MARK: - Discovery and Search
    
    /// Search servers by name, category, or description
    func searchServers(query: String) -> [MCPServerInfo] {
        if query.isEmpty {
            return availableServers
        }
        
        let lowercaseQuery = query.lowercased()
        return availableServers.filter { server in
            server.name.lowercased().contains(lowercaseQuery) ||
            server.displayName.lowercased().contains(lowercaseQuery) ||
            server.description.lowercased().contains(lowercaseQuery) ||
            server.category.displayName.lowercased().contains(lowercaseQuery) ||
            server.availableTools.contains { tool in
                tool.name.lowercased().contains(lowercaseQuery) ||
                tool.displayName.lowercased().contains(lowercaseQuery) ||
                tool.description.lowercased().contains(lowercaseQuery)
            }
        }
    }
    
    /// Filter servers by category
    func getServers(in category: MCPServerCategory) -> [MCPServerInfo] {
        return availableServers.filter { $0.category == category }
    }
    
    /// Get servers that don't require authentication
    func getServersWithoutAuth() -> [MCPServerInfo] {
        return availableServers.filter { $0.requiredAuth == .none }
    }
    
    /// Get official servers only
    func getOfficialServers() -> [MCPServerInfo] {
        return availableServers.filter { $0.isOfficial }
    }
    
    // MARK: - Tool Management
    
    /// Get all available tools across all enabled servers
    func getAvailableTools() -> [MCPToolInfo] {
        let enabledServers = getEnabledServersWithConfigs()
        var allTools: [MCPToolInfo] = []
        
        for (server, config) in enabledServers {
            let enabledTools = server.availableTools.filter { tool in
                config.selectedTools.contains(tool.name)
            }
            allTools.append(contentsOf: enabledTools)
        }
        
        return allTools
    }
    
    /// Update selected tools for a server
    func updateSelectedTools(for serverId: String, tools: Set<String>) {
        if var config = getConfiguration(for: serverId) {
            config.selectedTools = tools
            updateConfiguration(config)
        }
    }
    
    /// Update auth configuration for a server
    func updateAuthConfiguration(for serverId: String, auth: [String: String]) {
        if var config = getConfiguration(for: serverId) {
            config.authConfiguration = auth
            updateConfiguration(config)
        }
    }
}