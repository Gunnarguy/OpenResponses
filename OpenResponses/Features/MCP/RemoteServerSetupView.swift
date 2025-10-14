import SwiftUI

/// View for configuring a remote MCP server with custom URL and authorization
struct RemoteServerSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ChatViewModel
    let connector: MCPConnector
    
    // Server configuration
    @State private var serverLabel: String = ""
    @State private var serverURL: String = ""
    @State private var authorizationToken: String = ""
    @State private var allowedTools: String = ""
    @State private var requireApproval: String = "never"
    
    // UI state
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var isSaving = false
    @State private var showingClearAlert = false
    
    let approvalOptions = ["never", "prompt", "always"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Deployment instructions
                    deploymentInstructionsSection
                    
                    Divider()
                    
                    // Configuration form
                    configurationFormSection
                    
                    Divider()
                    
                    // Advanced options
                    advancedOptionsSection
                    
                    Divider()
                    
                    // Validation feedback
                    validationFeedbackSection
                }
                .padding()
            }
            .navigationTitle("Remote Server Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadExistingConfiguration()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Clear Configuration", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearConfiguration()
                }
            } message: {
                Text("This will remove all saved configuration for \(connector.name). You'll need to set it up again if you want to reconnect.")
            }
            .alert("Configuration Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: connector.icon)
                .font(.system(size: 40))
                .foregroundColor(Color(hex: connector.color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(connector.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Remote MCP Server")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Deployment Instructions
    
    private var deploymentInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Deployment Required", systemImage: "server.rack")
                .font(.headline)
            
            Text(connector.oauthInstructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let setupURL = connector.setupURL {
                Link(destination: URL(string: setupURL)!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("View Deployment Guide")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    // MARK: - Configuration Form
    
    private var configurationFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Server Configuration")
                .font(.headline)
            
            // Server Label
            VStack(alignment: .leading, spacing: 8) {
                Text("Server Label")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("e.g., NotionLocal or My_Server", text: $serverLabel)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                Text("A friendly name to identify this server (spaces will be converted to underscores)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Server URL
            VStack(alignment: .leading, spacing: 8) {
                Text("Server URL (HTTPS Required)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("https://your-server.com/sse", text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                Text("The HTTPS endpoint for your deployed MCP server")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Authorization Token
            VStack(alignment: .leading, spacing: 8) {
                Text("Authorization Token")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                SecureField("Your token (stored securely in Keychain)", text: $authorizationToken)
                    .textFieldStyle(.roundedBorder)
                Text("The authorization token your server expects (e.g., Notion integration token)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Advanced Options
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Options")
                .font(.headline)
            
            // Allowed Tools
            VStack(alignment: .leading, spacing: 8) {
                Text("Allowed Tools (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("tool1, tool2, tool3", text: $allowedTools)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                Text("Comma-separated list of tool names to enable. Leave blank to allow all tools.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Require Approval
            VStack(alignment: .leading, spacing: 8) {
                Text("Require Approval")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Approval Mode", selection: $requireApproval) {
                    ForEach(approvalOptions, id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Text("Controls when the AI must ask permission before using tools")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Validation Feedback
    
    private var validationFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let trimmedLabel = serverLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let trimmedToken = authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let validProtocol = trimmedURL.hasPrefix("https://") || 
                               trimmedURL.hasPrefix("http://localhost") || 
                               trimmedURL.hasPrefix("http://127.0.0.1") || 
                               trimmedURL.contains("://192.168.") ||
                               trimmedURL.contains("://10.") ||
                               trimmedURL.contains("://172.")
            
            let labelValid = !trimmedLabel.isEmpty
            let urlValid = !trimmedURL.isEmpty && validProtocol
            let tokenValid = !trimmedToken.isEmpty
            
            if !labelValid || !urlValid || !tokenValid {
                Text("⚠️ Save disabled. Required:")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                if !labelValid {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Server Label cannot be empty")
                    }
                    .font(.caption)
                }
                
                if !urlValid {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        if trimmedURL.isEmpty {
                            Text("Server URL cannot be empty")
                        } else if !validProtocol {
                            Text("URL must start with https:// or http://localhost")
                        }
                    }
                    .font(.caption)
                }
                
                if !tokenValid {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Authorization Token cannot be empty")
                    }
                    .font(.caption)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All fields valid - ready to save!")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    // MARK: - Load Existing Configuration
    
    private func loadExistingConfiguration() {
        // Check if there's an existing configuration in the active prompt
        if !viewModel.activePrompt.mcpServerURL.isEmpty {
            serverLabel = viewModel.activePrompt.mcpServerLabel
            serverURL = viewModel.activePrompt.mcpServerURL
            allowedTools = viewModel.activePrompt.mcpAllowedTools
            requireApproval = viewModel.activePrompt.mcpRequireApproval
            
            // Try to load the token from keychain using connector name
            let keychainKey = "mcp_auth_\(connector.name)"
            if let token = KeychainService.shared.load(forKey: keychainKey) {
                authorizationToken = token
                AppLogger.log("📋 Loaded existing configuration for '\(connector.name)'", category: .general, level: .info)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        let trimmedLabel = serverLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedToken = authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Allow HTTPS or HTTP for localhost/local network
        let validProtocol = trimmedURL.hasPrefix("https://") || 
                           trimmedURL.hasPrefix("http://localhost") || 
                           trimmedURL.hasPrefix("http://127.0.0.1") || 
                           trimmedURL.contains("://192.168.") ||
                           trimmedURL.contains("://10.") ||
                           trimmedURL.contains("://172.")
        
        let labelValid = !trimmedLabel.isEmpty
        let urlValid = !trimmedURL.isEmpty && validProtocol
        let tokenValid = !trimmedToken.isEmpty
        
        print("🔍 Validation Debug:")
        print("  Label: '\(trimmedLabel)' - Valid: \(labelValid)")
        print("  URL: '\(trimmedURL)' - Valid: \(urlValid)")
        print("  Token: '\(trimmedToken.prefix(20))...' - Valid: \(tokenValid)")
        print("  Overall Valid: \(labelValid && urlValid && tokenValid)")
        
        return labelValid && urlValid && tokenValid
    }
    
    // MARK: - Save Configuration
    
    private func saveConfiguration() {
        guard isValid else {
            validationErrorMessage = "Please fill in all required fields with valid values."
            showingValidationError = true
            return
        }
        
        isSaving = true
        
        // Trim whitespace
        let trimmedLabel = serverLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTools = allowedTools.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save authorization token to Keychain using connector name (not user's label)
        // This ensures disconnect can find it with "mcp_auth_\(connector.name)"
        let keychainKey = "mcp_auth_\(connector.name)"
        KeychainService.shared.save(value: trimmedToken, forKey: keychainKey)
        
        AppLogger.log("💾 Saved auth token for remote server '\(connector.name)' at keychain key: \(keychainKey)", category: .general, level: .info)
        
        // Update the active prompt with remote server configuration
        // Note: activePrompt is a non-optional @Published property
        viewModel.activePrompt.enableMCPTool = true // Enable MCP tool
        viewModel.activePrompt.mcpServerLabel = trimmedLabel
        viewModel.activePrompt.mcpServerURL = trimmedURL
        viewModel.activePrompt.mcpAllowedTools = trimmedTools
        viewModel.activePrompt.mcpRequireApproval = requireApproval
        viewModel.activePrompt.mcpIsConnector = false // Important: This is a remote server, not a connector
        
        // Clear connector-specific fields
        viewModel.activePrompt.mcpConnectorId = ""
        
        // Save the prompt
        viewModel.saveActivePrompt()
        
        print("✅ Remote MCP server configured:")
        print("   Label: \(trimmedLabel)")
        print("   URL: \(trimmedURL)")
        print("   Tools: \(trimmedTools.isEmpty ? "all" : trimmedTools)")
        print("   Approval: \(requireApproval)")
        
        // Success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
    
    // MARK: - Clear Configuration
    
    private func clearConfiguration() {
        // Remove token from keychain
        let keychainKey = "mcp_auth_\(connector.name)"
        KeychainService.shared.delete(forKey: keychainKey)
        
        AppLogger.log("🗑️ Cleared remote server configuration for '\(connector.name)'", category: .general, level: .info)
        
        // Clear the form fields
        serverLabel = ""
        serverURL = ""
        authorizationToken = ""
        allowedTools = ""
        requireApproval = "never"
        
        // Clear MCP settings from active prompt
        viewModel.activePrompt.enableMCPTool = false
        viewModel.activePrompt.mcpServerLabel = ""
        viewModel.activePrompt.mcpServerURL = ""
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpConnectorId = ""
        
        // Save the cleared state
        viewModel.saveActivePrompt()
        
        // Dismiss after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

