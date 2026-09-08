import SwiftUI

/// Account sign-in is the normal path. API keys remain an explicit custom-server option.
struct RemoteMCPSetupSheet: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flow = MCPConnectFlow()
    @State private var name = ""
    @State private var serverURL = ""
    @State private var authentication = Authentication.account
    @State private var header = "Authorization"
    @State private var token = ""
    @State private var error: String?
    @AppStorage("exploreModeEnabled") private var demo = false
    private enum Authentication: String, CaseIterable {
        case account = "Account sign-in", publicServer = "Public server", apiKey = "API key (advanced)"
    }
    private var address: String { serverURL.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (try? MCPOAuthSecurity.publicHTTPS(address)) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("https://provider.example/mcp", text: $serverURL)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Picker("Connection", selection: $authentication) {
                        ForEach(Authentication.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                } header: { Text("Custom server") } footer: {
                    Text("Use the remote MCP address provided by the service. Account sign-in discovers its authorization service and opens the provider’s login.")
                }
                if authentication == .apiKey {
                    Section {
                        TextField("Header name", text: $header).textInputAutocapitalization(.never).autocorrectionDisabled()
                        SecureField("API key", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled()
                    } header: { Text("Advanced authentication") } footer: {
                        Text("Only for servers that explicitly support API keys. For hosted Notion and other OAuth services, choose Account sign-in.")
                    }
                }
                Section {
                    if flow.connected != nil {
                        Label("Connected and enabled for this chat", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Button("Done") { dismiss() }
                    } else if flow.busy {
                        ProgressView(flow.progress)
                        Button("Cancel Sign-in") { flow.cancel() }
                    } else {
                        Button(demo ? "Leave Demo & Connect" : "Connect") { connect() }
                            .disabled(!valid || (authentication == .apiKey && token.isEmpty))
                    }
                    if let error = flow.error ?? error { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
                } footer: {
                    Text("The connection is saved securely on this device. OpenAI receives its authorization when you use it in chat or discover tools. Tool calls ask for your approval by default.")
                }
            }
            .navigationTitle("Add Custom Server").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onDisappear { flow.cancel() }
        }
    }
    private func connect() {
        if demo { demo = false; viewModel.exploreModeEnabled = false }
        error = nil
        if authentication == .apiKey {
            do {
                // Hosted Notion never accepts integration tokens on its MCP endpoint.
                if MCPDiscoveryConfiguration.isNotionHosted(address) { throw MCPAuthorizationError.unsupportedSignIn }
                let connection = try MCPConnectionStore.shared.addAPIKey(name: name, serverURL: address,
                    header: header.trimmingCharacters(in: .whitespacesAndNewlines), token: token)
                try viewModel.setMCPConnection(connection.id, enabled: true)
                token = ""; dismiss()
            } catch { self.error = error.localizedDescription }
        } else {
            flow.connect(provider: MCPProvider(id: "custom", name: name.trimmingCharacters(in: .whitespacesAndNewlines), summary: "",
                category: .development, serverURL: address, signIn: authentication == .publicServer ? .publicAccess : .automatic)) {
                try viewModel.setMCPConnection($0.id, enabled: true)
            }
        }
    }
}
