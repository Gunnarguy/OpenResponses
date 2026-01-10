import SwiftUI

/// A user-friendly gallery view for connecting popular services via MCP connectors
struct MCPConnectorGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedConnector: MCPConnector?
    @State private var selectedRemoteServer: RemoteMCPServer?
    @State private var showingConnectorSetup = false
    @State private var showingRemoteServerSetup = false
    @State private var showingRemoteServerTemplateSetup = false
    @State private var searchText = ""
    @State private var selectedCategory: MCPConnector.ConnectorCategory?

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    private var filteredConnectors: [MCPConnector] {
        var connectors = MCPConnector.library

        // Filter by category
        if let category = selectedCategory {
            connectors = connectors.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            connectors = MCPConnector.search(searchText)
        }

        return connectors
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    searchBar
                    categoryFilters
                    connectorGrid
                    footerNote
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingConnectorSetup) {
                if let connector = selectedConnector {
                    ConnectorSetupView(
                        connector: connector,
                        viewModel: viewModel,
                        onComplete: {
                            showingConnectorSetup = false
                            dismiss()
                        }
                    )
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showingRemoteServerSetup) {
                if let connector = selectedConnector {
                    RemoteServerSetupSheet(
                        connector: connector,
                        viewModel: viewModel
                    )
                } else {
                    EmptyView()
                }
            }
.sheet(isPresented: $showingRemoteServerTemplateSetup) {
    if let server = selectedRemoteServer {
        RemoteServerTemplateSetupSheet(
            template: server,
            viewModel: viewModel,
            onComplete: {
                showingRemoteServerTemplateSetup = false
                dismiss()
            }
        )
    } else {
        EmptyView()
    }
}
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connect Your Apps")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Give AI access to your favorite services. All connections are secure and you control what data is shared.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Note about Direct Notion Integration
            Text("For Notion: Use 'Direct Notion Integration' in Settings → MCP tab (recommended path)")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search connectors...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(MCPConnector.ConnectorCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var connectorGrid: some View {
        VStack(alignment: .leading, spacing: 24) {
            // OpenAI Hosted Connectors
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenAI Hosted Connectors")
                    .font(.headline)
                    .padding(.horizontal)

                Text("Official integrations managed by OpenAI. Connect with OAuth.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    ForEach(filteredConnectors) { connector in
                        ConnectorCard(connector: connector, viewModel: viewModel) { 
                            selectedConnector = connector
                            if connector.requiresRemoteServer {
                                showingRemoteServerSetup = true
                            } else {
                                showingConnectorSetup = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // Official Third-Party MCP Servers
            VStack(alignment: .leading, spacing: 12) {
                Text("Official MCP Servers")
                    .font(.headline)
                    .padding(.horizontal)

                Text("Verified servers hosted by service providers. Requires OAuth or API token.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    ForEach(RemoteMCPServer.officialServers, id: \.id) { server in
                        RemoteServerCard(server: server, viewModel: viewModel) {
                            selectedRemoteServer = server
                            showingRemoteServerTemplateSetup = true
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // Community/Self-Hosted Servers
            VStack(alignment: .leading, spacing: 12) {
                Text("Community & Self-Hosted")
                    .font(.headline)
                    .padding(.horizontal)

                Text("Templates for popular services. Requires your own MCP server deployment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    ForEach(RemoteMCPServer.communityServers, id: \.id) { server in
                        RemoteServerCard(server: server, viewModel: viewModel) {
                            selectedRemoteServer = server
                            showingRemoteServerTemplateSetup = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var footerNote: some View {
        Text("🔒 All connections use OAuth and are securely stored in your device's Keychain. OpenResponses never stores your credentials.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

/// Individual connector card in the gallery
private struct ConnectorCard: View {
    let connector: MCPConnector
    let viewModel: ChatViewModel
    let action: () -> Void

    // Check if this connector is currently configured
    private var isConnected: Bool {
        if connector.requiresRemoteServer {
            let prompt = viewModel.activePrompt
            guard prompt.enableMCPTool, !prompt.mcpIsConnector, !prompt.mcpServerURL.isEmpty else {
                return false
            }
            if connector.id == "connector_notion" {
                return prompt.mcpServerURL.lowercased().contains("notion")
            }
            return true
        } else {
            // For connectors, check the connector-specific keychain key
            let keychainKey = "mcp_connector_\(connector.id)"
            return KeychainService.shared.load(forKey: keychainKey) != nil
        }
    }

    @State private var showingDisconnectAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(Color(hex: connector.color).opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: connector.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: connector.color))

                // Connected indicator
                if isConnected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 20, y: 20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(connector.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if connector.requiresRemoteServer {
                        Image(systemName: "server.rack")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Connection status badge
                    if isConnected {
                        Text("Connected")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }

                Text(connector.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                // Connect/Setup button
                Button(action: action) {
                    HStack {
                        Image(systemName: connector.requiresRemoteServer ? "server.rack" : "link")
                            .font(.caption)
                        Text(isConnected ? (connector.requiresRemoteServer ? "Reconfigure" : "Update") : (connector.requiresRemoteServer ? "Setup" : "Connect"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                // Disconnect button (only show if connected)
                if isConnected {
                    Button(action: { showingDisconnectAlert = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isConnected ? Color.green.opacity(0.3) : (connector.requiresRemoteServer ? Color.orange.opacity(0.5) : Color(.systemGray5)), lineWidth: isConnected ? 2 : (connector.requiresRemoteServer ? 2 : 1))
        )
        .alert("Disconnect \(connector.name)?", isPresented: $showingDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                disconnectConnector()
            }
        } message: {
            Text("This will remove your saved credentials and configuration for \(connector.name).")
        }
    }

    private func disconnectConnector() {
        if connector.requiresRemoteServer {
            // Clear active prompt configuration if it matches this connector
            if !viewModel.activePrompt.mcpIsConnector,
               !viewModel.activePrompt.mcpServerLabel.isEmpty {
                let manualKey = "mcp_manual_\(viewModel.activePrompt.mcpServerLabel)"
                KeychainService.shared.delete(forKey: manualKey)
                let legacyKey = "mcp_auth_\(connector.name)"
                KeychainService.shared.delete(forKey: legacyKey)
                viewModel.activePrompt.enableMCPTool = false
                viewModel.activePrompt.mcpServerLabel = ""
                viewModel.activePrompt.mcpServerURL = ""
                viewModel.activePrompt.mcpAllowedTools = ""
                viewModel.activePrompt.mcpRequireApproval = "never"
                viewModel.saveActivePrompt()
            }
            AppLogger.log("🔌 Disconnected remote MCP configuration for \(connector.name)", category: .general, level: .info)
        } else {
            // Remove connector OAuth token
            let keychainKey = "mcp_connector_\(connector.id)"
            KeychainService.shared.delete(forKey: keychainKey)
            AppLogger.log("🔌 Disconnected connector: \(connector.name)", category: .general, level: .info)
        }
    }
}

/// Category filter pill
private struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

/// Connector setup flow with OAuth instructions
struct ConnectorSetupView: View {
    let connector: MCPConnector
    @ObservedObject var viewModel: ChatViewModel
    let onComplete: () -> Void

    @State private var oauthToken = ""
    @State private var requireApproval = true
    @State private var allowedToolsText = ""
    @State private var showingSuccess = false

    private var isValid: Bool {
        let trimmed = oauthToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Reject authorization codes (they start with "4/0")
        if trimmed.hasPrefix("4/0") {
            return false
        }

        return true
    }

    private var allowedToolList: [String] {
        allowedToolsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: connector.color).opacity(0.15))
                                .frame(width: 64, height: 64)

                            Image(systemName: connector.icon)
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: connector.color))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(connector.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(connector.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Step-by-step instructions
                    VStack(alignment: .leading, spacing: 16) {
                        StepHeader(number: 1, title: "Get OAuth Token", isCompleted: !oauthToken.isEmpty)

                        Text(connector.oauthInstructions)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Link to OAuth Playground for easy testing
                        Link(destination: URL(string: "https://developers.google.com/oauthplayground/")!) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Google OAuth 2.0 Playground")
                                        .fontWeight(.medium)
                                    Text("Get a test access token quickly")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                        }

                        if let setupURL = connector.setupURL {
                            Link(destination: URL(string: setupURL)!) {
                                HStack {
                                    Image(systemName: "arrow.up.forward.square")
                                    Text("Production OAuth Setup")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                        }

                        // Required scopes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Required Scopes:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            ForEach(connector.oauthScopes, id: \.self) { scope in
                                Text("• \(scope)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.bottom)

                    Divider()

                    // Token input
                    VStack(alignment: .leading, spacing: 16) {
                        StepHeader(number: 2, title: "Enter Access Token", isCompleted: isValid)

                        // Critical warning about token type
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("IMPORTANT: You need an ACCESS TOKEN, not an authorization code")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }

                            Text("• Access tokens start with 'ya29.' for Google services")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("• Authorization codes (starting with '4/0') will NOT work")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("• Use Google OAuth Playground to get a test access token")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)

                        SecureField("Paste your OAuth ACCESS TOKEN here (ya29...)", text: $oauthToken)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        if !oauthToken.isEmpty {
                            let tokenPrefix = String(oauthToken.prefix(4))
                            if tokenPrefix == "4/0A" || tokenPrefix == "4/0_" {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("This looks like an authorization CODE")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.red)
                                        Text("You need to exchange it for an access token first")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                            } else if oauthToken.hasPrefix("ya29.") {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Valid Google access token format")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Token entered")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(.bottom)

                    Divider()

                    // Settings
                    VStack(alignment: .leading, spacing: 16) {
                        StepHeader(number: 3, title: "Configure Settings", isCompleted: true)

                        Toggle(isOn: $requireApproval) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Require Approval")
                                    .font(.subheadline)
                                Text("Review each action before it's executed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Allowed Tools (Optional)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            TextField("tool_one, tool_two", text: $allowedToolsText)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            if !allowedToolList.isEmpty {
                                Text("\(allowedToolList.count) tools selected")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("Leave blank to allow every tool exposed by the connector.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Popular Tools")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            ForEach(connector.popularTools, id: \.self) { tool in
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(tool)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Connect \(connector.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Connect") {
                        saveConnector()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadExistingConfiguration()
            }
            .alert("Connected!", isPresented: $showingSuccess) {
                Button("Done") {
                    onComplete()
                }
            } message: {
                Text("\(connector.name) is now connected and ready to use!")
            }
        }
    }

    private func saveConnector() {
        // Confirm the connector exists and does not require remote hosting
        guard let catalogConnector = MCPConnector.connector(for: connector.id) else {
            AppLogger.log("⚠️ Attempted to configure unknown connector id: \(connector.id)", category: .general, level: .error)
            onComplete()
            return
        }

        guard catalogConnector.requiresRemoteServer == false else {
            AppLogger.log("⚠️ Attempted to configure '\(connector.name)' via connector flow, but it requires remote server setup", category: .general, level: .warning)
            onComplete()
            return
        }

        // Save OAuth token to keychain
        let keychainKey = "mcp_connector_\(connector.id)"
        KeychainService.shared.save(value: oauthToken, forKey: keychainKey)

        // Update prompt model to use connector (not remote server)
        viewModel.activePrompt.enableMCPTool = true
        viewModel.activePrompt.mcpIsConnector = true
        viewModel.activePrompt.mcpConnectorId = connector.id
        viewModel.activePrompt.mcpServerLabel = connector.name

        // Set approval mode (convert bool to string for Prompt model)
        viewModel.activePrompt.mcpRequireApproval = requireApproval ? "always" : "never"

        // Set allowed tools if specified
        if !allowedToolList.isEmpty {
            let sanitizedAllowedTools = allowedToolList.joined(separator: ", ")
            viewModel.activePrompt.mcpAllowedTools = sanitizedAllowedTools
            allowedToolsText = sanitizedAllowedTools
        } else {
            viewModel.activePrompt.mcpAllowedTools = ""
            allowedToolsText = ""
        }

        // Clear any remote server config to avoid confusion
        viewModel.activePrompt.mcpServerURL = ""
        viewModel.saveActivePrompt()

        // Show success
        showingSuccess = true

        AppLogger.log("✅ Connected to \(connector.name) connector (id: \(connector.id))", category: .openAI, level: .info)
    }

    private func loadExistingConfiguration() {
        guard viewModel.activePrompt.mcpIsConnector,
              viewModel.activePrompt.mcpConnectorId == connector.id else {
            return
        }
        let keychainKey = "mcp_connector_\(connector.id)"
        if let existingToken = KeychainService.shared.load(forKey: keychainKey) {
            oauthToken = existingToken
        }
        requireApproval = viewModel.activePrompt.mcpRequireApproval != "never"
        allowedToolsText = viewModel.activePrompt.mcpAllowedTools.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct RemoteServerSetupSheet: View {
    let connector: MCPConnector
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var url: String = ""
    @State private var token: String = ""
    @State private var requireApproval: Bool = true
    @State private var allowedToolsText: String = ""
    @State private var isTesting: Bool = false
    @State private var diagStatus: String?

    private var allowedToolList: [String] {
        allowedToolsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var tokenLooksLikeIntegration: Bool {
        let t = token.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return t.hasPrefix("ntn_") || t.hasPrefix("secret_") || t.hasPrefix("bearer ntn_") || t.hasPrefix("bearer secret_")
    }
    private var isNotionOfficialURL: Bool {
        url.lowercased().contains("mcp.notion.com")
    }

    private var isValid: Bool {
        let base = !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if connector.id == "connector_notion" {
            // For official Notion MCP allow integration tokens; for self-hosted require server-issued token
            if isNotionOfficialURL {
                return base
            } else {
                return base && !tokenLooksLikeIntegration
            }
        }
        return base
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server")) {
                    TextField("Label", text: $label)
                    TextField("Server URL (https://...)", text: $url)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Authorization")) {
                    SecureField("Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    // Guidance for Notion MCP
                    if connector.id == "connector_notion" {
                        if isNotionOfficialURL {
                            if tokenLooksLikeIntegration {
                                Text("Detected a Notion integration token — correct for the official Notion MCP.")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else if !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("For the official Notion MCP, use your Notion Integration token (ntn_/secret_). The app will send it as top‑level authorization.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Official Notion MCP (mcp.notion.com): paste your Notion Integration token (ntn_/secret_).")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            if tokenLooksLikeIntegration {
                                Text("This looks like a Notion integration token. For self‑hosted servers, use the server‑issued Bearer token from your container logs instead.")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            } else {
                                Text("Self‑hosted Notion MCP: use the server‑issued Bearer token printed by your container.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Toggle("Require Approval", isOn: $requireApproval)
                }

                Section(header: Text("Allowed Tools (optional)")) {
                    TextField("tool_one, tool_two", text: $allowedToolsText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !allowedToolList.isEmpty {
                        Text("\(allowedToolList.count) tools selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Leave blank to allow all tools reported by the server")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if connector.id == "connector_notion" {
                    Section(footer: Text(isNotionOfficialURL
                                         ? "Official Notion MCP (mcp.notion.com): paste your Notion Integration token (ntn_/secret_) and the app will send it as top‑level authorization."
                                         : "Self‑hosted Notion MCP: use the server‑issued Bearer token printed in your container logs (do not paste the integration token here).")) {
                        EmptyView()
                    }
                }

                Section(header: Text("Diagnostics")) {
                    if isTesting {
                        HStack {
                            ProgressView()
                            Text("Testing…")
                        }
                    } else {
                        Button {
                            Task {
                                isTesting = true
                                diagStatus = nil

                                // Persist auth for probe
                                let headerKey = viewModel.activePrompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : viewModel.activePrompt.mcpAuthHeaderKey
                                let normalizedAuth = NotionAuthService.shared.normalizeAuthorizationValue(token)
                                if isNotionOfficialURL {
                                    // Official Notion MCP: save raw token for top-level auth (no Authorization header)
                                    KeychainService.shared.save(value: normalizedAuth, forKey: "mcp_manual_\(label)")
                                } else {
                                    // Self-hosted: store as Authorization header JSON
                                    let headers = [headerKey: normalizedAuth]
                                    if let data = try? JSONSerialization.data(withJSONObject: headers, options: [.sortedKeys]),
                                       let str = String(data: data, encoding: .utf8) {
                                        KeychainService.shared.save(value: str, forKey: "mcp_manual_\(label)")
                                    }
                                }

                                // Build derived prompt for probe (without mutating current prompt)
                                var probePrompt = viewModel.activePrompt
                                probePrompt.enableMCPTool = true
                                probePrompt.mcpIsConnector = false
                                probePrompt.mcpServerLabel = label
                                probePrompt.mcpServerURL = url
                                probePrompt.mcpAllowedTools = allowedToolList.joined(separator: ", ")
                                probePrompt.mcpRequireApproval = requireApproval ? "always" : "never"

                                do {
                                    let (lbl, count) = try await AppContainer.shared.openAIService.probeMCPListTools(prompt: probePrompt)
                                    diagStatus = "MCP list_tools OK (\(lbl)): \(count) tools"
                                } catch {
                                    diagStatus = "Probe failed: \(error.localizedDescription)"
                                }

                                isTesting = false
                            }
                        } label: {
                            Label("Test MCP Connection", systemImage: "checkmark.seal")
                        }
                        .disabled(!isValid)
                    }

                    if let diagStatus = diagStatus {
                        Text(diagStatus)
                            .font(.caption)
                            .foregroundColor(diagStatus.contains("OK") ? .green : .orange)
                    }
                }
            }
            .navigationTitle("Setup \(connector.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { preload() }
        }
    }

    private func preload() {
        // Prefill sensible defaults
        if label.isEmpty { label = connector.name }
        // Quick Notion defaults
        if connector.id == "connector_notion", url.isEmpty {
            url = "https://mcp.notion.com/mcp"
        }
        // If a remote is already configured, preload it
        let p = viewModel.activePrompt
        if p.enableMCPTool && !p.mcpIsConnector && !p.mcpServerLabel.isEmpty {
            label = p.mcpServerLabel
            url = p.mcpServerURL
            allowedToolsText = p.mcpAllowedTools
            requireApproval = p.mcpRequireApproval != "never"
            if let existing = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), token.isEmpty {
                // If the stored value is a JSON header dict, extract Authorization; otherwise treat as raw token.
                if let data = existing.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    let headerKey = viewModel.activePrompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : viewModel.activePrompt.mcpAuthHeaderKey
                    let headerVal = obj[headerKey] ?? obj["Authorization"] ?? ""
                    token = NotionAuthService.shared.stripBearer(headerVal)
                } else {
                    token = existing
                }
            }
        }
    }

    private func save() {
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = allowedToolList.joined(separator: ", ")
        let headerKey = viewModel.activePrompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : viewModel.activePrompt.mcpAuthHeaderKey
        let normalizedAuth = NotionAuthService.shared.normalizeAuthorizationValue(cleanToken)
        let isNotionOfficial = cleanURL.lowercased().contains("mcp.notion.com")

        // Update active prompt to a remote MCP configuration
        viewModel.activePrompt.enableMCPTool = true
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpConnectorId = nil
        viewModel.activePrompt.mcpServerLabel = cleanLabel
        viewModel.activePrompt.mcpServerURL = cleanURL
        viewModel.activePrompt.mcpAllowedTools = allowed
        viewModel.activePrompt.mcpRequireApproval = requireApproval ? "always" : "never"

        var headers = viewModel.activePrompt.secureMCPHeaders

        if isNotionOfficial {
            // Official Notion MCP: use TOP-LEVEL raw token only, no Authorization header
            headers.removeValue(forKey: headerKey)
            headers.removeValue(forKey: "Authorization")
            viewModel.activePrompt.secureMCPHeaders = headers

            // Persist raw token for top-level auth (strip any Bearer)
            let rawTopLevel = NotionAuthService.shared.stripBearer(normalizedAuth)
            KeychainService.shared.save(value: rawTopLevel, forKey: "mcp_manual_\(cleanLabel)")
            AppLogger.log("🔐 Saved top-level token for official Notion MCP (no Authorization header).", category: .mcp, level: .info)
        } else {
            // Self-hosted: store Authorization header JSON and keep in headers
            let headersDict = [headerKey: normalizedAuth]
            if let data = try? JSONSerialization.data(withJSONObject: headersDict, options: [.sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                KeychainService.shared.save(value: str, forKey: "mcp_manual_\(cleanLabel)")
            } else {
                KeychainService.shared.save(value: "{\"\(headerKey)\":\"\(normalizedAuth)\"}", forKey: "mcp_manual_\(cleanLabel)")
            }
            headers[headerKey] = normalizedAuth
            viewModel.activePrompt.secureMCPHeaders = headers
            AppLogger.log("🔐 Saved Authorization header for self-hosted MCP.", category: .mcp, level: .info)
        }

        viewModel.saveActivePrompt()
        AppLogger.log("✅ Configured remote MCP server '\(cleanLabel)' (official=\(isNotionOfficial))", category: .mcp, level: .info)
        dismiss()
    }
}

/// Step header for setup flow
private struct StepHeader: View {
    let number: Int
    let title: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.blue)
                    .frame(width: 28, height: 28)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Remote Server Card

/// Card for displaying a remote MCP server template
private struct RemoteServerCard: View {
    let server: RemoteMCPServer
    let viewModel: ChatViewModel
    let action: () -> Void

    private var isConfigured: Bool {
        let prompt = viewModel.activePrompt
        guard prompt.enableMCPTool, !prompt.mcpIsConnector else { return false }
        return prompt.mcpServerLabel == server.label
    }

    private var iconName: String {
        switch server.label {
        case "github": return "chevron.left.forwardslash.chevron.right"
        case "stripe": return "creditcard.fill"
        case "deepwiki": return "book.fill"
        case "cloudflare": return "cloud.fill"
        case "sentry": return "ant.fill"
        case "linear": return "squares.leading.rectangle"
        case "figma": return "paintpalette.fill"
        case "slack": return "number.square.fill"
        case "asana": return "list.bullet.circle.fill"
        case "jira": return "ticket.fill"
        case "airtable": return "tablecells.fill"
        case "todoist": return "checkmark.circle.fill"
        default: return "server.rack"
        }
    }

    private var iconColor: Color {
        switch server.label {
        case "github": return .black
        case "stripe": return Color(hex: "#635BFF")
        case "deepwiki": return Color(hex: "#4A90D9")
        case "cloudflare": return Color(hex: "#F38020")
        case "sentry": return Color(hex: "#362D59")
        case "linear": return Color(hex: "#5E6AD2")
        case "figma": return Color(hex: "#F24E1E")
        case "slack": return Color(hex: "#4A154B")
        case "asana": return Color(hex: "#F06A6A")
        case "jira": return Color(hex: "#0052CC")
        case "airtable": return Color(hex: "#18BFFF")
        case "todoist": return Color(hex: "#E44332")
        default: return .blue
        }
    }

    private var isOfficialServer: Bool {
        RemoteMCPServer.officialServers.contains(where: { $0.label == server.label })
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(server.displayLabel ?? server.label)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isOfficialServer {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Text(server.serverDescription ?? "MCP Server")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Configured")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text(isOfficialServer ? "Connect" : "Set Up")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isConfigured ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Remote Server Template Setup Sheet

/// Setup sheet for configuring a remote MCP server from a template
private struct RemoteServerTemplateSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: RemoteMCPServer
    @ObservedObject var viewModel: ChatViewModel
    let onComplete: () -> Void

    @State private var serverURL: String = ""
    @State private var authToken: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isOfficialServer: Bool {
        RemoteMCPServer.officialServers.contains(where: { $0.label == template.label })
    }

    private var isURLValid: Bool {
        guard let url = URL(string: serverURL) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.displayLabel ?? template.label)
                            .font(.title2)
                            .fontWeight(.bold)

                        if isOfficialServer {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                Text("Official Server")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Text(template.serverDescription ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Server URL")) {
                    TextField("https://...", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    if !isOfficialServer {
                        Text("Enter your self-hosted MCP server URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Authentication")) {
                    SecureField("OAuth Token or API Key", text: $authToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text(authInstructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section {
                    Button {
                        saveConfiguration()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            Text(isSaving ? "Saving..." : "Connect")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isURLValid || authToken.isEmpty || isSaving)
                }
            }
            .navigationTitle("Set Up \(template.displayLabel ?? template.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Pre-fill URL for official servers
                if isOfficialServer {
                    serverURL = template.serverURL
                }
            }
        }
    }

    private var authInstructions: String {
        switch template.label {
        case "github":
            return "Generate a GitHub personal access token or use GitHub OAuth."
        case "stripe":
            return "Use a Stripe OAuth access token from your Stripe dashboard."
        case "deepwiki":
            return "DeepWiki doesn't require authentication. Leave empty or use 'none'."
        case "cloudflare":
            return "Use a Cloudflare API token with appropriate permissions."
        case "sentry":
            return "Generate a Sentry auth token from your account settings."
        case "linear":
            return "Use a Linear OAuth token or personal API key."
        default:
            return "Enter the authentication token required by this MCP server."
        }
    }

    private func saveConfiguration() {
        isSaving = true
        errorMessage = nil

        // Build the authorization header
        var headers: [String: String] = [:]
        if !authToken.isEmpty, authToken.lowercased() != "none" {
            let token = authToken.hasPrefix("Bearer ") ? authToken : "Bearer \(authToken)"
            headers["Authorization"] = token
        }

        // Save to keychain
        let keychainKey = "mcp_manual_\(template.label)"
        if let headersData = try? JSONEncoder().encode(headers),
           let headersString = String(data: headersData, encoding: .utf8)
        {
            _ = KeychainService.shared.save(value: headersString, forKey: keychainKey)
        }

        // Update prompt configuration
        var prompt = viewModel.activePrompt
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = false
        prompt.mcpConnectorId = nil
        prompt.mcpServerLabel = template.label
        prompt.mcpServerURL = serverURL
        prompt.mcpRequireApproval = template.requireApproval == .never ? "never" : "always"
        prompt.mcpAllowedTools = template.allowedTools?.joined(separator: ", ") ?? ""
        prompt.mcpAuthHeaderKey = "Authorization"
        prompt.mcpKeepAuthInHeaders = false

        viewModel.replaceActivePrompt(with: prompt)
        viewModel.saveActivePrompt()
        viewModel.lastMCPServerLabel = template.label

        isSaving = false
        onComplete()
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MCPConnectorGalleryView(viewModel: ChatViewModel())
}
