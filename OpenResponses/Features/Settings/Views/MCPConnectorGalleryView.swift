import SwiftUI

/// A user-friendly gallery view for connecting popular services via MCP connectors
struct MCPConnectorGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedConnector: MCPConnector?
    @State private var showingConnectorSetup = false
    @State private var showingRemoteServerSetup = false
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
                    RemoteServerSetupView(
                        viewModel: viewModel,
                        connector: connector
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
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredConnectors) { connector in
                ConnectorCard(connector: connector, viewModel: viewModel) {
                    selectedConnector = connector
                    // Show different setup flow based on connector type
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
    @State private var showingNotionToolSelector = false
    
    private var isValid: Bool {
        !oauthToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                        
                        if let setupURL = connector.setupURL {
                            Link(destination: URL(string: setupURL)!) {
                                HStack {
                                    Image(systemName: "arrow.up.forward.square")
                                    Text("Open OAuth Setup")
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
                        
                        SecureField("Paste your OAuth token here", text: $oauthToken)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        if !oauthToken.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Token entered")
                                    .font(.caption)
                                    .foregroundColor(.green)
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
                            if connector.id == "connector_notion" {
                                Button {
                                    showingNotionToolSelector = true
                                } label: {
                                    HStack {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.caption)
                                        Text("Choose Notion tools")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan.opacity(0.15))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.borderless)
                                Text("Fine-tune the Notion APIs the assistant can call to stay within your workspace limits.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
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
            .sheet(isPresented: $showingNotionToolSelector) {
                NotionToolSelectorView(selectedTools: $allowedToolsText)
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
