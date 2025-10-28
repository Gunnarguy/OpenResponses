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
    @State private var defaultsApplied = false

    // Auth header configuration
    @State private var authHeaderKey: String = "Authorization"
    @State private var keepAuthInHeaders: Bool = true
    @State private var isTesting: Bool = false
    @State private var probeStatus: String? = nil
    
    // UI state
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var isSaving = false
    @State private var showingClearAlert = false
    
    let approvalOptions = ["never", "prompt", "always"]
    private let defaultNotionVersion = "2022-06-28"
    
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

                    // Presets (one-tap fill)
                    presetsSection

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
                applyRemoteDefaultsIfNeeded()
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
                        Task { await saveConfigurationAsync() }
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
    
    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Presets", systemImage: "sparkles")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    presetButton(RemoteMCPServer.notionOfficial, color: .blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text("Tap a preset to pre-fill fields. Authorization is not stored until you Save.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

    private func presetButton(_ preset: RemoteMCPServer, color: Color) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.square")
                Text(preset.uiLabel)
            }
            .foregroundColor(color)
        }
        .accessibilityLabel("Use preset \(preset.uiLabel)")
    }

    private func applyPreset(_ preset: RemoteMCPServer) {
        serverLabel = preset.label
        serverURL = preset.serverURL
        requireApproval = {
            switch preset.requireApproval {
            case .never: return "never"
            case .always: return "always"
            case .specificTools: return "always" // default to always if specific set in template
            }
        }()
        // Leave allowed tools empty (ubiquitous)
        allowedTools = ""
        // Reset auth header config to sensible defaults
        authHeaderKey = "Authorization"
        keepAuthInHeaders = false
        // Keep any typed token visible but do not store until Save
        defaultsApplied = true
        AppLogger.log("⚙️ Applied preset: \(preset.uiLabel) → \(preset.serverURL)", category: .general, level: .info)
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
                    .disabled(true)
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
                    .disabled(true)
                Text("Official Notion MCP endpoint (locked)")
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
                Text("Paste your Notion Internal Integration secret (starts with ntn_ or secret_). Do not type 'Bearer'. Stored securely in Keychain.")
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
                    .disabled(true)
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
                .disabled(true)
                Text("Controls when the AI must ask permission before using tools")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider().padding(.vertical, 4)

            // Auth Header Key
            VStack(alignment: .leading, spacing: 8) {
                Text("Auth Header Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Authorization", text: $authHeaderKey)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disabled(true)
                Text("Name of the HTTP header your server expects for auth (e.g., Authorization, X-Auth-Token).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Keep Authorization in headers (applies when key is Authorization)
            Toggle(isOn: $keepAuthInHeaders) {
                Text("Also keep token in headers when using Authorization")
            }
            .disabled(true)
            Text("OpenAI API forbids sending both top‑level authorization and an Authorization header. When Auth Header Key = Authorization, the app sends top‑level only and ignores this toggle. Use a custom header key (e.g., X-Auth-Token) if your server requires header‑only auth.")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Test MCP connection
            Button {
                Task { await testConnection() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isTesting ? "hourglass" : "bolt.horizontal")
                    Text(isTesting ? "Testing…" : "Test MCP Connection")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid || isSaving || isTesting)
            .padding(.top, 4)

            // Inline probe result
            if let probeStatus = probeStatus {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(probeStatus)
                }
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

                // Identity line if preflight succeeded previously
                let identity = loadPreflightIdentity(for: trimmedLabel)
                let display = (identity.name?.isEmpty == false ? identity.name : identity.id) ?? ""
                if !display.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Connected to Notion as \(display)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
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
        let prompt = viewModel.activePrompt
        guard !prompt.mcpServerLabel.isEmpty || !prompt.mcpServerURL.isEmpty else {
            return
        }

        serverLabel = prompt.mcpServerLabel
        serverURL = prompt.mcpServerURL
        allowedTools = prompt.mcpAllowedTools
        requireApproval = prompt.mcpRequireApproval
        // Load auth header prefs
        authHeaderKey = prompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : prompt.mcpAuthHeaderKey
        keepAuthInHeaders = prompt.mcpKeepAuthInHeaders

        let manualKey = "mcp_manual_\(prompt.mcpServerLabel)"
        if let stored = KeychainService.shared.load(forKey: manualKey), !stored.isEmpty {
            if let headers = decodeHeaderPayload(stored), !headers.isEmpty {
                authorizationToken = strippedAuthorizationValue(headers["Authorization"] ?? headers["authorization"] ?? stored)
                defaultsApplied = true
                AppLogger.log("📋 Loaded remote MCP configuration for '\(prompt.mcpServerLabel)'", category: .general, level: .info)
                return
            } else {
                authorizationToken = strippedAuthorizationValue(stored)
                defaultsApplied = true
                AppLogger.log("📋 Loaded legacy remote MCP token for '\(prompt.mcpServerLabel)'", category: .general, level: .info)
                return
            }
        }

        // Legacy key migration (mcp_auth_<connector.name>)
        let legacyKey = "mcp_auth_\(connector.name)"
        if let legacyToken = KeychainService.shared.load(forKey: legacyKey), !legacyToken.isEmpty {
            authorizationToken = strippedAuthorizationValue(legacyToken)

            let headers = buildHeaderDictionary(
                from: legacyToken,
                serverLabel: prompt.mcpServerLabel,
                serverURL: prompt.mcpServerURL
            )
            if let encoded = encodeHeaderPayload(headers) {
                KeychainService.shared.save(value: encoded, forKey: manualKey)
            } else {
                KeychainService.shared.save(value: normalizedAuthorizationValue(from: legacyToken), forKey: manualKey)
            }

            KeychainService.shared.delete(forKey: legacyKey)
            defaultsApplied = true
            AppLogger.log("♻️ Migrated legacy remote MCP token from \(legacyKey) to \(manualKey)", category: .general, level: .info)
        }
    }

    private func applyRemoteDefaultsIfNeeded() {
        guard !defaultsApplied else { return }

        switch connector.id {
        case "connector_notion":
            // Prefer user's GCP preset by default when no saved config exists
            if serverLabel.isEmpty {
                serverLabel = RemoteMCPServer.notionOfficial.label
            }
            if serverURL.isEmpty {
                serverURL = RemoteMCPServer.notionOfficial.serverURL
            }
            requireApproval = "never" // ubiquitous by default
            // Auth header defaults
            if authHeaderKey.isEmpty { authHeaderKey = "Authorization" }
            keepAuthInHeaders = false
            defaultsApplied = true
            AppLogger.log("ℹ️ Applied default Notion MCP (Official) settings", category: .general, level: .info)
        default:
            break
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

        // Early token format check to prevent saving obviously invalid values
        if !isLikelyNotionToken(trimmedToken) {
            validationErrorMessage = "Token format looks invalid. Notion integration tokens start with 'secret_' or 'ntn_'. Open Notion → Settings & members → Connections → New integration to create one, copy the Integration Secret, and paste it here (without 'Bearer')."
            showingValidationError = true
            isSaving = false
            return
        }
        
        // Remove legacy key if present to avoid confusion between old and new storage keys
        let legacyKey = "mcp_auth_\(connector.name)"
        if KeychainService.shared.load(forKey: legacyKey) != nil {
            KeychainService.shared.delete(forKey: legacyKey)
            AppLogger.log("♻️ Removed legacy keychain key: \(legacyKey)", category: .general, level: .info)
        }
        
        // If the label changed, clean up the previous keychain entry to prevent orphaned secrets
        let previousLabel = viewModel.activePrompt.mcpServerLabel
        if !previousLabel.isEmpty, previousLabel != trimmedLabel {
            let previousManualKey = "mcp_manual_\(previousLabel)"
            KeychainService.shared.delete(forKey: previousManualKey)
            AppLogger.log("🧹 Removed stale MCP keychain entry: \(previousManualKey)", category: .general, level: .debug)
        }
        
        let headerDictionary = buildHeaderDictionary(
            from: trimmedToken,
            serverLabel: trimmedLabel,
            serverURL: trimmedURL
        )
        AppLogger.log("🔐 Prepared MCP header payload for \(trimmedLabel) with keys: \(headerDictionary.keys.joined(separator: ", "))", category: .general, level: .info)
        
        // Update the active prompt with remote server configuration
        // Note: activePrompt is a non-optional @Published property
        viewModel.activePrompt.enableMCPTool = true // Enable MCP tool
        viewModel.activePrompt.mcpServerLabel = trimmedLabel
        viewModel.activePrompt.mcpServerURL = trimmedURL
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpIsConnector = false // Important: This is a remote server, not a connector
        // Auth header preferences
        viewModel.activePrompt.mcpAuthHeaderKey = "Authorization"
        viewModel.activePrompt.mcpKeepAuthInHeaders = false
        
        // Clear connector-specific fields
        viewModel.activePrompt.mcpConnectorId = ""
        viewModel.activePrompt.secureMCPHeaders = headerDictionary // Persist via keychain helper

        // Reflect sanitized values back into the UI for immediate feedback
        allowedTools = ""
        authorizationToken = strippedAuthorizationValue(headerDictionary["Authorization"] ?? trimmedToken)
        defaultsApplied = true
        
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
    
    // MARK: - Save Configuration (Async with Notion preflight)

    @MainActor private func saveConfigurationAsync() async {
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

        // Format sanity: token must look like a Notion Integration Secret
        if !isLikelyNotionToken(trimmedToken) {
            validationErrorMessage = "Token format looks invalid. Notion integration tokens start with 'secret_' or 'ntn_'. Open Notion → Settings & members → Connections → New integration to create one, copy the Integration Secret, and paste it here (without 'Bearer')."
            showingValidationError = true
            isSaving = false
            return
        }

        // Notion preflight: block saving if /v1/users/me is not 200
        if shouldAppendNotionVersion(label: trimmedLabel, url: trimmedURL) {
            let preflight = await preflightNotionToken(trimmedToken)
            if !preflight.ok {
                // Surface a clear message and abort the save
                validationErrorMessage = "Notion token unauthorized (HTTP \(preflight.status)). Re-copy your Integration Secret in Notion and paste it here.\nDetails: \(preflight.message.prefix(180))"
                showingValidationError = true
                isSaving = false
                return
            } else {
                AppLogger.log("✅ Notion token preflight (save) succeeded (200) for \(trimmedLabel)", category: .general, level: .info)
                // Mark preflight OK and record freshness timestamp for chat gating
                UserDefaults.standard.set(true, forKey: "mcp_preflight_ok_\(trimmedLabel)")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "mcp_preflight_ok_at_\(trimmedLabel)")
                // Store token hash and Notion identity for stronger gating
                let authValueForHash = normalizedAuthorizationValue(from: trimmedToken)
                let authHash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: authValueForHash)
                UserDefaults.standard.set(authHash, forKey: "mcp_preflight_token_hash_\(trimmedLabel)")
                let identity = await NotionAuthService.shared.preflight(authorizationValue: trimmedToken)
                if identity.ok {
                    let userDict: [String: String] = [
                        "id": identity.userId ?? "",
                        "name": identity.userName ?? ""
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: userDict, options: [.sortedKeys]),
                       let str = String(data: data, encoding: .utf8) {
                        UserDefaults.standard.set(str, forKey: "mcp_preflight_user_\(trimmedLabel)")
                    }
                }
            }
        }

        // Remove legacy key if present to avoid confusion between old and new storage keys
        let legacyKey = "mcp_auth_\(connector.name)"
        if KeychainService.shared.load(forKey: legacyKey) != nil {
            KeychainService.shared.delete(forKey: legacyKey)
            AppLogger.log("♻️ Removed legacy keychain key: \(legacyKey)", category: .general, level: .info)
        }

        // If the label changed, clean up the previous keychain entry to prevent orphaned secrets
        let previousLabel = viewModel.activePrompt.mcpServerLabel
        if !previousLabel.isEmpty, previousLabel != trimmedLabel {
            let previousManualKey = "mcp_manual_\(previousLabel)"
            KeychainService.shared.delete(forKey: previousManualKey)
            // Also clear any preflight flags for the previous label to prevent stale validation
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_ok_\(previousLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_ok_at_\(previousLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_token_hash_\(previousLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_user_\(previousLabel)")
            // And clear any probe flags to avoid stale list_tools status carrying over
            UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_\(previousLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_at_\(previousLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_probe_token_hash_\(previousLabel)")
            AppLogger.log("🧹 Removed stale MCP keychain entry: \(previousManualKey)", category: .general, level: .debug)
        }

        // Build header dictionary (Authorization + Notion-Version if needed)
        let headerDictionary = buildHeaderDictionary(
            from: trimmedToken,
            serverLabel: trimmedLabel,
            serverURL: trimmedURL
        )
        AppLogger.log("🔐 Prepared MCP header payload (save) for \(trimmedLabel) with keys: \(headerDictionary.keys.joined(separator: ", "))", category: .general, level: .info)

        // Update the active prompt with remote server configuration
        viewModel.activePrompt.enableMCPTool = true // Enable MCP tool
        viewModel.activePrompt.mcpServerLabel = trimmedLabel
        viewModel.activePrompt.mcpServerURL = trimmedURL
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpIsConnector = false // This is a remote server, not a connector
        // Auth header preferences (enforce top‑level only for Authorization)
        viewModel.activePrompt.mcpAuthHeaderKey = "Authorization"
        viewModel.activePrompt.mcpKeepAuthInHeaders = false
        // Clear connector-specific fields
        viewModel.activePrompt.mcpConnectorId = ""
        viewModel.activePrompt.secureMCPHeaders = headerDictionary // Persist via keychain helper

        // Reflect sanitized values back into the UI for immediate feedback
        allowedTools = ""
        authorizationToken = strippedAuthorizationValue(headerDictionary["Authorization"] ?? trimmedToken)
        defaultsApplied = true

        // Save the prompt
        viewModel.saveActivePrompt()

        print("✅ Remote MCP server configured (after preflight):")
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

    // MARK: - Test Connection

    @MainActor private func testConnection() async {
        guard isValid else {
            validationErrorMessage = "Please fill in all required fields with valid values before testing."
            showingValidationError = true
            return
        }

        // Early token format check to prevent avoidable 401s
        if !isLikelyNotionToken(authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines)) {
            validationErrorMessage = "Token format looks invalid. Notion integration tokens start with 'secret_' or 'ntn_'. Open Notion → Settings & members → Connections → New integration to create one, copy the Integration Secret, and paste it here (without 'Bearer')."
            showingValidationError = true
            return
        }

        isTesting = true

        // Prepare trimmed values (mirror saveConfiguration, but do not dismiss)
        let trimmedLabel = serverLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clean legacy keys (do not block test)
        let legacyKey = "mcp_auth_\(connector.name)"
        if KeychainService.shared.load(forKey: legacyKey) != nil {
            KeychainService.shared.delete(forKey: legacyKey)
            AppLogger.log("♻️ Removed legacy keychain key before test: \(legacyKey)", category: .general, level: .info)
        }

        // Remove stale key if label changed
        let previousLabel = viewModel.activePrompt.mcpServerLabel
        if !previousLabel.isEmpty, previousLabel != trimmedLabel {
            let previousManualKey = "mcp_manual_\(previousLabel)"
            KeychainService.shared.delete(forKey: previousManualKey)
            AppLogger.log("🧹 Removed stale MCP keychain entry before test: \(previousManualKey)", category: .general, level: .debug)
        }

        // Build header dictionary (Authorization + Notion-Version if needed)
        let headerDictionary = buildHeaderDictionary(
            from: trimmedToken,
            serverLabel: trimmedLabel,
            serverURL: trimmedURL
        )
        AppLogger.log("🧪 Prepared MCP header payload (test) for \(trimmedLabel) with keys: \(headerDictionary.keys.joined(separator: ", "))", category: .general, level: .info)

        // Optional Notion token preflight to catch 401s early
        if shouldAppendNotionVersion(label: trimmedLabel, url: trimmedURL) {
            let preflight = await preflightNotionToken(trimmedToken)
            if !preflight.ok {
                AppLogger.log("🧪 Notion token preflight failed: HTTP \(preflight.status) — \(preflight.message)", category: .general, level: .warning)
                // Surface a clear, user-friendly alert and abort the test
                DispatchQueue.main.async {
                    let formatHint = self.isLikelyNotionToken(trimmedToken) ? "" : "Token format looks invalid. Notion integration tokens start with 'secret_' or 'ntn_'. "
                    self.validationErrorMessage = "\(formatHint)Notion token unauthorized (HTTP \(preflight.status)). Re-copy your Integration Secret in Notion and paste it here. Details: \(preflight.message.prefix(180))"
                    self.showingValidationError = true
                    self.isTesting = false
                }
                return
            } else {
                AppLogger.log("🧪 Notion token preflight succeeded (200)", category: .general, level: .info)
                // Mark preflight OK and record freshness timestamp for chat gating
                UserDefaults.standard.set(true, forKey: "mcp_preflight_ok_\(trimmedLabel)")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "mcp_preflight_ok_at_\(trimmedLabel)")
                // Store token hash and Notion identity for stronger gating
                let authValueForHash = normalizedAuthorizationValue(from: trimmedToken)
                let authHash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: authValueForHash)
                UserDefaults.standard.set(authHash, forKey: "mcp_preflight_token_hash_\(trimmedLabel)")
                let identity = await NotionAuthService.shared.preflight(authorizationValue: trimmedToken)
                if identity.ok {
                    let userDict: [String: String] = [
                        "id": identity.userId ?? "",
                        "name": identity.userName ?? ""
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: userDict, options: [.sortedKeys]),
                       let str = String(data: data, encoding: .utf8) {
                        UserDefaults.standard.set(str, forKey: "mcp_preflight_user_\(trimmedLabel)")
                    }
                }
            }
        }

        // Apply to active prompt (no dismiss)
        viewModel.activePrompt.enableMCPTool = true
        viewModel.activePrompt.mcpServerLabel = trimmedLabel
        viewModel.activePrompt.mcpServerURL = trimmedURL
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpAuthHeaderKey = "Authorization"
        viewModel.activePrompt.mcpKeepAuthInHeaders = false
        viewModel.activePrompt.mcpConnectorId = ""
        viewModel.activePrompt.secureMCPHeaders = headerDictionary // Persist to keychain

        // Reflect sanitized values back into UI immediately
        allowedTools = ""
        authorizationToken = strippedAuthorizationValue(headerDictionary["Authorization"] ?? trimmedToken)

        // Persist prompt changes
        viewModel.saveActivePrompt()

        // Perform direct MCP health probe (list_tools) via service without mutating chat state
        do {
            let result = try await viewModel.api.probeMCPListTools(prompt: viewModel.activePrompt)
            AppLogger.log("🧪 MCP health probe succeeded for \(result.label): \(result.count) tools", category: .mcp, level: .info)
            DispatchQueue.main.async {
                // Persist probe-ok flags so chat gate recognizes a validated tools list for this token hash
                let d = UserDefaults.standard
                d.set(true, forKey: "mcp_probe_ok_\(trimmedLabel)")
                d.set(Date().timeIntervalSince1970, forKey: "mcp_probe_ok_at_\(trimmedLabel)")
                let authValueForHash = self.normalizedAuthorizationValue(from: trimmedToken)
                let authHash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: authValueForHash)
                d.set(authHash, forKey: "mcp_probe_token_hash_\(trimmedLabel)")
                // UI feedback
                self.probeStatus = "MCP tools: \(result.count) available"
                self.isTesting = false
            }
        } catch {
            let message: String
            if let svcErr = error as? OpenAIServiceError {
                switch svcErr {
                case .requestFailed(let code, let msg):
                    message = "MCP list_tools failed (HTTP \(code)). \(msg)"
                    if code == 401 {
                        // Revoke preflight on unauthorized to prevent chat retries with bad token
                        let d = UserDefaults.standard
                        d.set(false, forKey: "mcp_preflight_ok_\(trimmedLabel)")
                        d.removeObject(forKey: "mcp_preflight_ok_at_\(trimmedLabel)")
                        d.removeObject(forKey: "mcp_preflight_token_hash_\(trimmedLabel)")
                        d.removeObject(forKey: "mcp_preflight_user_\(trimmedLabel)")
                    }
                default:
                    message = svcErr.userFriendlyDescription
                }
            } else {
                message = error.localizedDescription
            }
            AppLogger.log("🧪 MCP health probe failed: \(message)", category: .mcp, level: .warning)
            DispatchQueue.main.async {
                self.probeStatus = "Probe failed: \(message.prefix(160))"
                self.isTesting = false
                self.validationErrorMessage = message
                self.showingValidationError = true
            }
        }
    }

    // MARK: - Clear Configuration
    
    private func clearConfiguration() {
        // Remove token(s) from Keychain - delete both legacy and manual keys to be safe
        let legacyKey = "mcp_auth_\(connector.name)"
        _ = KeychainService.shared.delete(forKey: legacyKey)

        // Also attempt to delete the new manual key if a server label exists on the active prompt
        let manualLabel = viewModel.activePrompt.mcpServerLabel
        if !manualLabel.isEmpty {
            let manualKey = "mcp_manual_\(manualLabel)"
            _ = KeychainService.shared.delete(forKey: manualKey)
            // Clear preflight flags for this label
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_ok_\(manualLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_ok_at_\(manualLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_token_hash_\(manualLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_preflight_user_\(manualLabel)")
            // Clear probe flags for this label
            UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_\(manualLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_at_\(manualLabel)")
            UserDefaults.standard.removeObject(forKey: "mcp_probe_token_hash_\(manualLabel)")
        }

        AppLogger.log("🗑️ Cleared remote server configuration for '\(connector.name)' (removed keychain entries)", category: .general, level: .info)
        
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

    // MARK: - Header Helpers

    private func normalizedAuthorizationValue(from input: String) -> String {
        // Remove whitespace, quotes, and invisible Unicode characters that can break auth
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        let cleaned = removeInvisibleCharacters(from: trimmed)
        guard !cleaned.isEmpty else { return "" }

        let lower = cleaned.lowercased()
        if lower.hasPrefix("bearer ") || lower.hasPrefix("basic ") || lower.hasPrefix("token ") {
            return cleaned
        }

        if cleaned.contains(" ") {
            return cleaned
        }

        return "Bearer \(cleaned)"
    }

    private func strippedAuthorizationValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        let cleaned = removeInvisibleCharacters(from: trimmed)
        let lower = cleaned.lowercased()
        if lower.hasPrefix("bearer ") {
            return String(cleaned.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    private func buildHeaderDictionary(from token: String, serverLabel: String, serverURL: String) -> [String: String] {
        var headers: [String: String] = [:]

        let authorizationValue = normalizedAuthorizationValue(from: token)
        if !authorizationValue.isEmpty {
            headers["Authorization"] = authorizationValue
        }

        if shouldAppendNotionVersion(label: serverLabel, url: serverURL) {
            headers["Notion-Version"] = defaultNotionVersion
        }

        return headers
    }

    private func shouldAppendNotionVersion(label: String, url: String) -> Bool {
        if connector.id == "connector_notion" { return true }

        let normalizedLabel = label.lowercased()
        let normalizedURL = url.lowercased()
        if normalizedLabel.contains("notion") { return true }
        if normalizedURL.contains("notion") { return true }
        return false
    }

    private func encodeHeaderPayload(_ headers: [String: String]) -> String? {
        guard !headers.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: headers, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func decodeHeaderPayload(_ payload: String) -> [String: String]? {
        guard let data = payload.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return parsed
    }

    /// Strips control characters and zero-width/invisible Unicode that can accidentally be copied with tokens
    private func removeInvisibleCharacters(from input: String) -> String {
        // Common invisibles: ZERO WIDTH SPACE/NO-JOINER/JOINER, BOM, NBSP
        let forbidden = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{FEFF}\u{00A0}")
        let scalars = input.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0) && !forbidden.contains($0)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    // Identity helper
    private func loadPreflightIdentity(for label: String) -> (name: String?, id: String?) {
        if let json = UserDefaults.standard.string(forKey: "mcp_preflight_user_\(label)"),
           let data = json.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return (dict["name"], dict["id"])
        }
        return (nil, nil)
    }

    // Token heuristics
    private func isLikelyNotionToken(_ token: String) -> Bool {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return false }
        let lower = t.lowercased()
        return lower.hasPrefix("secret_") || lower.hasPrefix("ntn_")
    }

    // MARK: - Preflight (Notion token validator)

    /// Quickly validates the provided Notion Integration secret by calling /v1/users/me.
    /// Returns ok=false with HTTP status and message when unauthorized or failing.
    private func preflightNotionToken(_ token: String) async -> (ok: Bool, status: Int, message: String) {
        guard let url = URL(string: "https://api.notion.com/v1/users/me") else {
            return (false, -1, "Invalid Notion URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue(normalizedAuthorizationValue(from: token), forHTTPHeaderField: "Authorization")
        req.setValue(defaultNotionVersion, forHTTPHeaderField: "Notion-Version")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if status == 200 {
                return (true, status, "OK")
            } else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return (false, status, body)
            }
        } catch {
            return (false, -1, error.localizedDescription)
        }
    }
}
