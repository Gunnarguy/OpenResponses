import SwiftUI

/// A comprehensive view for discovering, configuring, and managing MCP servers and tools
struct MCPToolDiscoveryView: View {
    @StateObject private var discoveryService = MCPDiscoveryService.shared
    @State private var searchText = ""
    @State private var selectedCategory: MCPServerCategory? = nil
    @State private var showOnlyOfficial = false
    @State private var showOnlyNoAuth = false
    @State private var selectedServer: MCPServerInfo? = nil
    @State private var showingServerDetail = false
    @State private var showingAuthSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filters
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search servers and tools...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(MCPServerCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        Toggle("Official only", isOn: $showOnlyOfficial)
                        Spacer()
                        Toggle("No auth required", isOn: $showOnlyNoAuth)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Server List
                List {
                    ForEach(filteredServers, id: \.name) { server in
                        ServerRowView(
                            server: server,
                            isEnabled: discoveryService.isServerEnabled(server.name)
                        ) {
                            selectedServer = server
                            showingServerDetail = true
                        } onToggle: { isEnabled in
                            if isEnabled {
                                discoveryService.enableServer(server)
                            } else {
                                discoveryService.disableServer(server.name)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("MCP Tools")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingServerDetail) {
                if let server = selectedServer {
                    ServerDetailView(server: server)
                }
            }
        }
    }
    
    private var filteredServers: [MCPServerInfo] {
        var servers = discoveryService.searchServers(query: searchText)
        
        if let category = selectedCategory {
            servers = servers.filter { $0.category == category }
        }
        
        if showOnlyOfficial {
            servers = servers.filter { $0.isOfficial }
        }
        
        if showOnlyNoAuth {
            servers = servers.filter { $0.requiredAuth == .none }
        }
        
        return servers.sorted { first, second in
            // Sort by: enabled status, official status, then name
            if discoveryService.isServerEnabled(first.name) != discoveryService.isServerEnabled(second.name) {
                return discoveryService.isServerEnabled(first.name)
            }
            if first.isOfficial != second.isOfficial {
                return first.isOfficial
            }
            return first.displayName < second.displayName
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
        }
    }
}

struct ServerRowView: View {
    let server: MCPServerInfo
    let isEnabled: Bool
    let onTap: () -> Void
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(server.displayName)
                        .font(.headline)
                    
                    if server.isOfficial {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    CategoryBadge(category: server.category)
                }
                
                Text(server.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(server.availableTools.count) tools", systemImage: "wrench.and.screwdriver")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    AuthBadge(authType: server.requiredAuth)
                }
            }
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: onToggle
            ))
            .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct CategoryBadge: View {
    let category: MCPServerCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(categoryColor.opacity(0.2))
            .foregroundColor(categoryColor)
            .cornerRadius(4)
    }
    
    private var categoryColor: Color {
        switch category {
        case .development: return .blue
        case .productivity: return .green
        case .communication: return .orange
        case .fileManagement: return .purple
        case .ecommerce: return .red
        case .dataAnalysis: return .indigo
        case .contentCreation: return .pink
        case .automation: return .cyan
        case .entertainment: return .yellow
        case .other: return .gray
        }
    }
}

struct AuthBadge: View {
    let authType: MCPAuthType
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: authIcon)
            Text(authType.displayName)
        }
        .font(.caption2)
        .foregroundColor(authType == .none ? .green : .orange)
    }
    
    private var authIcon: String {
        switch authType {
        case .none: return "lock.open"
        case .apiKey: return "key"
        case .bearerToken: return "key.fill"
        case .oauth: return "person.badge.key"
        case .custom: return "gearshape"
        }
    }
}

struct ServerDetailView: View {
    let server: MCPServerInfo
    @StateObject private var discoveryService = MCPDiscoveryService.shared
    @State private var selectedTools: Set<String> = []
    @State private var authConfiguration: [String: String] = [:]
    @State private var showingAuthHelp = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(server.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if server.isOfficial {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            
                            Spacer()
                            
                            CategoryBadge(category: server.category)
                        }
                        
                        Text(server.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            AuthBadge(authType: server.requiredAuth)
                            Spacer()
                            Text("Server: \(server.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Authentication Setup
                    if server.requiredAuth != .none {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Authentication")
                                    .font(.headline)
                                Spacer()
                                Button("Help") {
                                    showingAuthHelp = true
                                }
                                .font(.caption)
                            }
                            
                            AuthConfigurationView(
                                authType: server.requiredAuth,
                                configuration: $authConfiguration
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Tool Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Available Tools")
                                .font(.headline)
                            Spacer()
                            Text("\(selectedTools.count) of \(server.availableTools.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                            ForEach(server.availableTools, id: \.name) { tool in
                                ToolRowView(
                                    tool: tool,
                                    isSelected: selectedTools.contains(tool.name)
                                ) { isSelected in
                                    if isSelected {
                                        selectedTools.insert(tool.name)
                                    } else {
                                        selectedTools.remove(tool.name)
                                    }
                                }
                            }
                        }
                        
                        HStack {
                            Button("Select All") {
                                selectedTools = Set(server.availableTools.map { $0.name })
                            }
                            .disabled(selectedTools.count == server.availableTools.count)
                            
                            Spacer()
                            
                            Button("Select None") {
                                selectedTools.removeAll()
                            }
                            .disabled(selectedTools.isEmpty)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Setup Instructions
                    if let instructions = server.setupInstructions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Setup Instructions")
                                .font(.headline)
                            Text(instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Server Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveConfiguration()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(server.requiredAuth != .none && authConfiguration.isEmpty)
            )
        }
        .onAppear {
            loadCurrentConfiguration()
        }
        .sheet(isPresented: $showingAuthHelp) {
            AuthHelpView(server: server)
        }
    }
    
    private func loadCurrentConfiguration() {
        if let config = discoveryService.getConfiguration(for: server.name) {
            selectedTools = config.selectedTools
            authConfiguration = config.authConfiguration
        } else {
            selectedTools = Set(server.availableTools.map { $0.name })
        }
    }
    
    private func saveConfiguration() {
        let config = MCPServerConfiguration(
            serverId: server.name,
            isEnabled: true,
            authConfiguration: authConfiguration,
            selectedTools: selectedTools
        )
        discoveryService.updateConfiguration(config)
    }
}

struct ToolRowView: View {
    let tool: MCPToolInfo
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: onToggle
            ))
        }
        .padding(.vertical, 4)
    }
}

struct AuthConfigurationView: View {
    let authType: MCPAuthType
    @Binding var configuration: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch authType {
            case .none:
                EmptyView()
                
            case .apiKey:
                SecureField("API Key", text: Binding(
                    get: { configuration["api_key"] ?? "" },
                    set: { configuration["api_key"] = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case .bearerToken:
                SecureField("Bearer Token", text: Binding(
                    get: { configuration["bearer_token"] ?? "" },
                    set: { configuration["bearer_token"] = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case .oauth:
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Client ID", text: Binding(
                        get: { configuration["client_id"] ?? "" },
                        set: { configuration["client_id"] = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Client Secret", text: Binding(
                        get: { configuration["client_secret"] ?? "" },
                        set: { configuration["client_secret"] = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Redirect URI", text: Binding(
                        get: { configuration["redirect_uri"] ?? "" },
                        set: { configuration["redirect_uri"] = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
            case .custom:
                Text("Custom authentication configuration required")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct AuthHelpView: View {
    let server: MCPServerInfo
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Authentication Help")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Setting up authentication for \(server.displayName)")
                        .font(.headline)
                    
                    if let instructions = server.setupInstructions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Setup Instructions:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(instructions)
                                .font(.body)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Authentication Type:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(authHelp)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var authHelp: String {
        switch server.requiredAuth {
        case .none:
            return "No authentication required for this server."
        case .apiKey:
            return "You'll need an API key from the service provider. This is usually found in your account settings or developer dashboard."
        case .bearerToken:
            return "You'll need a bearer token, typically obtained through the service's authentication API or developer portal."
        case .oauth:
            return "OAuth authentication requires setting up an application with the service provider. You'll need to register your app and get client credentials."
        case .custom:
            return "This server uses a custom authentication method. Please refer to the server's documentation for specific setup instructions."
        }
    }
}

#Preview {
    MCPToolDiscoveryView()
}