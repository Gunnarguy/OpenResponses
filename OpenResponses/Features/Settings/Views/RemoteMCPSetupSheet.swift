import SwiftUI

struct RemoteMCPSetupSheet: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var serverURL: String = ""
    @State private var authHeaderKey: String = "Authorization"
    @State private var token: String = ""
    @State private var allowedToolsCSV: String = ""
    @State private var approvalMode: String = "never"

    @State private var errorMessage: String?

    @State private var isTesting: Bool = false
    @State private var diagStatus: String? = nil

    private var isValid: Bool {
        let lbl = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let tkn = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lbl.isEmpty, !url.isEmpty, !tkn.isEmpty else { return false }
        guard url.lowercased().hasPrefix("https://") else { return false }
        // Notion hosted MCP requires OAuth; this app does not support that flow for remote MCP config.
        if url.lowercased().contains("mcp.notion.com") { return false }
        return true
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Label("Remote Server", systemImage: "server.rack")) {
                    TextField("Label (e.g., Notion HTTP MCP)", text: $label)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("Server URL (https://…)", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section(header: Label("Authorization", systemImage: "key.fill"),
                        footer: Text("Notion's hosted MCP (mcp.notion.com) is OAuth-based and isn't supported here. For Notion, use Direct Notion Integration. For self-hosted MCP servers, paste the server-issued Bearer token.").font(.caption))
                {
                    TextField("Header Key (default: Authorization)", text: $authHeaderKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    SecureField("Token", text: $token)
                }

                Section(header: Label("Policy", systemImage: "checkmark.seal")) {
                    TextField("Allowed Tools (CSV, optional)", text: $allowedToolsCSV)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    Picker("Approval", selection: $approvalMode) {
                        Text("Never").tag("never")
                        Text("Always").tag("always")
                        Text("Auto").tag("auto")
                    }
                    .pickerStyle(.segmented)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).font(.caption).foregroundColor(.red)
                    }
                }

                Section(header: Label("Diagnostics", systemImage: "checkmark.seal")) {
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

                                let lbl = label.trimmingCharacters(in: .whitespacesAndNewlines)
                                let urlStr = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                let headerKey = authHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Authorization" : authHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                let normalizedAuth = NotionAuthService.shared.normalizeAuthorizationValue(token)
                                let isNotionOfficial = urlStr.lowercased().contains("mcp.notion.com")
                                if isNotionOfficial {
                                    diagStatus = "Notion hosted MCP (mcp.notion.com) requires OAuth and isn't supported here. Use Direct Notion Integration instead."
                                    isTesting = false
                                    return
                                }

                                // Persist minimal auth for probe (matches OpenAIService.resolveMCPAuthorization expectations)
                                // Headers JSON
                                let headers = [headerKey: normalizedAuth]
                                if let data = try? JSONSerialization.data(withJSONObject: headers, options: [.sortedKeys]),
                                   let str = String(data: data, encoding: .utf8)
                                {
                                    _ = KeychainService.shared.save(value: str, forKey: "mcp_manual_\(lbl)")
                                }

                                var probePrompt = viewModel.activePrompt
                                probePrompt.enableMCPTool = true
                                probePrompt.mcpIsConnector = false
                                probePrompt.mcpServerLabel = lbl
                                probePrompt.mcpServerURL = urlStr
                                probePrompt.mcpAllowedTools = allowedToolsCSV.trimmingCharacters(in: .whitespacesAndNewlines)
                                probePrompt.mcpRequireApproval = approvalMode
                                probePrompt.mcpAuthHeaderKey = headerKey

                                do {
                                    let (foundLabel, count) = try await AppContainer.shared.openAIService.probeMCPListTools(prompt: probePrompt)
                                    let d = UserDefaults.standard
                                    d.set(true, forKey: "mcp_probe_ok_\(foundLabel)")
                                    d.set(Date().timeIntervalSince1970, forKey: "mcp_probe_ok_at_\(foundLabel)")
                                    if let stored = KeychainService.shared.load(forKey: "mcp_manual_\(foundLabel)"),
                                       let data = stored.data(using: .utf8),
                                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                                    {
                                        let ah = obj[headerKey] ?? obj["Authorization"] ?? ""
                                        let hash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: ah)
                                        d.set(hash, forKey: "mcp_probe_token_hash_\(foundLabel)")
                                    } else {
                                        // If top-level storage (raw token), hash directly
                                        let hash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: normalizedAuth)
                                        d.set(hash, forKey: "mcp_probe_token_hash_\(foundLabel)")
                                    }
                                    d.set(count, forKey: "mcp_probe_tool_count_\(foundLabel)")
                                    diagStatus = "MCP list_tools OK (\(foundLabel)): \(count) tools"
                                } catch {
                                    let lower = error.localizedDescription.lowercased()
                                    if lower.contains("401") || lower.contains("unauthorized") {
                                        diagStatus = "Probe failed: Unauthorized (401). Check the token."
                                    } else if lower.contains("timed out") || lower.contains("timeout") {
                                        diagStatus = "Probe failed: Connection timed out. Verify the URL is reachable."
                                    } else {
                                        diagStatus = "Probe failed: \(error.localizedDescription)"
                                    }
                                }

                                isTesting = false
                            }
                        } label: {
                            Label("Test MCP Connection", systemImage: "checkmark.seal")
                        }
                        .disabled(!isValid)
                    }

                    if let status = diagStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("OK") ? .green : .orange)
                    }
                }
            }
            .navigationTitle("Add Custom MCP Remote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                // Pre-fill with any existing remote config for quick edits
                let prompt = viewModel.activePrompt
                if !prompt.mcpIsConnector && prompt.enableMCPTool {
                    if label.isEmpty { label = prompt.mcpServerLabel }
                    if serverURL.isEmpty { serverURL = prompt.mcpServerURL }
                    if approvalMode.isEmpty { approvalMode = prompt.mcpRequireApproval.isEmpty ? "never" : prompt.mcpRequireApproval }
                    if authHeaderKey.isEmpty { authHeaderKey = prompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : prompt.mcpAuthHeaderKey }
                    if allowedToolsCSV.isEmpty { allowedToolsCSV = prompt.mcpAllowedTools }
                }
            }
        }
    }

    private func save() {
        let lbl = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let headerKey = authHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Authorization" : authHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let tkn = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = allowedToolsCSV.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lbl.isEmpty, !url.isEmpty, !tkn.isEmpty else {
            errorMessage = "Please provide a label, URL, and token."
            return
        }
        guard url.lowercased().hasPrefix("https://") else {
            errorMessage = "Server URL must start with https://"
            return
        }

        if url.lowercased().contains("mcp.notion.com") {
            errorMessage = "Notion hosted MCP (mcp.notion.com) requires OAuth and isn't supported here. Use Direct Notion Integration instead."
            return
        }

        // Normalize token value for headers
        let normalizedAuth = NotionAuthService.shared.normalizeAuthorizationValue(tkn)

        // Update active prompt configuration
        var prompt = viewModel.activePrompt
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = false
        prompt.mcpServerLabel = lbl
        prompt.mcpServerURL = url
        prompt.mcpAllowedTools = allowed
        prompt.mcpRequireApproval = approvalMode
        prompt.mcpAuthHeaderKey = headerKey

        var headers = prompt.secureMCPHeaders
        headers[headerKey] = normalizedAuth
        prompt.secureMCPHeaders = headers

        viewModel.replaceActivePrompt(with: prompt)
        viewModel.saveActivePrompt()

        // Persist token copies for parity with disconnectRemote()
        _ = KeychainService.shared.save(value: normalizedAuth, forKey: "mcp_manual_\(lbl)")
        _ = KeychainService.shared.save(value: normalizedAuth, forKey: "mcp_auth_\(lbl)")

        dismiss()
    }
}

#Preview {
    RemoteMCPSetupSheet()
        .environmentObject(ChatViewModel())
}
