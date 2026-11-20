import SwiftUI
import Combine

/// Settings → Connectors. One account library, shared across prompts; a prompt stores only the IDs it uses.
/// The page opens on the popular services, grouped by kind, and below them the whole public MCP Registry,
/// loaded page by page as the list scrolls. Typing searches both at once. Adding a server by its address
/// is the last row, for anything that is in neither.
struct MCPConnectionsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject private var store = MCPConnectionStore.shared
    @State private var query = ""
    @State private var selectedProvider: MCPProvider?
    @State private var showingCustom = false
    @State private var showingNotionToken = false
    @State private var hasNotionToken = false
    @State private var confirmingTokenRemoval = false
    @State private var registry: [MCPProvider] = []
    @State private var registryQuery: String?
    @State private var cursor: String?
    @State private var reachedEnd = false
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var error: String?
    @AppStorage("exploreModeEnabled") private var demo = false

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var popular: [MCPProvider] {
        // OpenAI's own connectors (no server address) need a sign-in the app can't offer yet, so they stay out.
        MCPProvider.featured.filter { !$0.serverURL.isEmpty }.filter {
            trimmedQuery.isEmpty || ($0.name + " " + $0.summary + " " + $0.category.rawValue).localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    /// Registry servers that are not already in the popular list.
    private var registryResults: [MCPProvider] {
        let featuredURLs = Set(MCPProvider.featured.map(\.serverURL))
        return registry.filter { !featuredURLs.contains($0.serverURL) }
    }

    var body: some View {
        List {
            if let error = store.storageError ?? error {
                Section { Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.orange) }
            }

            if !store.connections.isEmpty || hasNotionToken {
                Section {
                    ForEach(store.connections) { connection in
                        connectionRow(connection)
                    }
                    if hasNotionToken { notionTokenRow }
                    if !missingIDs.isEmpty {
                        Button("Remove unavailable connections from this chat") {
                            let missing = Set(missingIDs)
                            viewModel.activePrompt.currentOptions.mcpConnectionIDs?.removeAll { missing.contains($0) }
                            viewModel.saveActivePrompt()
                        }
                    }
                } header: { Text("Connected") } footer: {
                    Text("Accounts stay connected when switched off. The assistant asks before it uses a tool, unless you change that in a connection.")
                }
            }

            if trimmedQuery.isEmpty {
                ForEach(MCPProvider.Category.allCases, id: \.self) { category in
                    let items = popular.filter { $0.category == category }
                    if !items.isEmpty {
                        Section(category.rawValue) {
                            ForEach(items) { providerButton($0) }
                        }
                    }
                }
            } else {
                Section("Popular") {
                    ForEach(popular) { providerButton($0) }
                    if popular.isEmpty { Text("None of the popular services match.").foregroundStyle(.secondary) }
                }
            }

            Section {
                if demo {
                    Button {
                        demo = false; viewModel.exploreModeEnabled = false
                        loadRegistry(reset: true)
                    } label: { Label("Leave Demo Mode to browse the registry", systemImage: "globe") }
                }
                ForEach(registryResults) { providerButton($0) }
                if searching {
                    ProgressView().frame(maxWidth: .infinity)
                } else if !demo && !reachedEnd && registryQuery != nil {
                    // Scrolling to this row loads the next page.
                    ProgressView().frame(maxWidth: .infinity).onAppear { loadRegistry() }
                }
                if !searching && !demo && reachedEnd && registryResults.isEmpty {
                    Text(trimmedQuery.isEmpty ? "The registry has no servers to show." : "No servers in the registry match “\(trimmedQuery)”.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(trimmedQuery.isEmpty ? "Everything in the MCP Registry" : "MCP Registry")
            } footer: {
                Text("The public MCP Registry lists remote servers from many publishers. Anyone can list a server, so check the publisher and address before you connect. Servers that only run on a computer are left out.")
            }

            Section {
                Button { showingCustom = true } label: { Label("Add a Server by Address", systemImage: "plus") }
            } footer: {
                Text("For a server that isn't listed: paste its https address, and add a key if it needs one.")
            }
        }
        .searchable(text: $query, prompt: "Search connectors")
        .navigationTitle("Connectors")
        .sheet(item: $selectedProvider) { provider in
            NavigationStack { MCPProviderDetailView(provider: provider, viewModel: viewModel) }
        }
        .sheet(isPresented: $showingCustom) { RemoteMCPSetupSheet().environmentObject(viewModel) }
        .sheet(isPresented: $showingNotionToken, onDismiss: refreshNotionToken) { NotionConnectionView() }
        .confirmationDialog("Remove the Notion integration token?", isPresented: $confirmingTokenRemoval, titleVisibility: .visible) {
            Button("Remove Token", role: .destructive) {
                _ = KeychainService.shared.delete(forKey: "notionApiKey")
                refreshNotionToken()
            }
        } message: {
            Text("Your Notion account stays connected. The token is deleted from this device's Keychain.")
        }
        .task(id: viewModel.activePrompt.id) { migrateLegacy() }
        .task { refreshNotionToken(); if registry.isEmpty { loadRegistry(reset: true) } }
        .onChange(of: query) { _, _ in
            // Wait for a pause in typing, then search the registry with what was typed.
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(450))
                guard !Task.isCancelled else { return }
                loadRegistry(reset: true)
            }
        }
        .onChange(of: demo) { _, enabled in if enabled { searchTask?.cancel(); searching = false } }
        .onDisappear { searchTask?.cancel(); searching = false }
    }

    private func providerButton(_ provider: MCPProvider) -> some View {
        Button { selectedProvider = provider } label: { MCPProviderRow(provider: provider) }
            .buttonStyle(.plain)
    }

    private func connectionRow(_ connection: MCPConnection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                MCPConnectionDetailView(id: connection.id, viewModel: viewModel)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: connection.needsSignIn ? "person.crop.circle.badge.exclamationmark" : "link.circle.fill")
                        .font(.title2).foregroundStyle(connection.needsSignIn ? .orange : .blue)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(connection.name).font(.headline)
                        Text(connection.needsSignIn ? "Sign in again" : connection.authentication == .oauth ? "Account connected" : "Server saved")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Toggle("Use in this chat", isOn: Binding(
                get: { viewModel.activePrompt.enableMCPTool && (viewModel.activePrompt.currentOptions.mcpConnectionIDs ?? []).contains(connection.id) },
                set: { enabled in setActive(connection.id, enabled: enabled) }
            )).font(.subheadline).disabled(connection.needsSignIn)
        }.padding(.vertical, 4)
    }

    /// A Notion integration token saved by an older version. It keeps working; new Notion connections use
    /// the Notion row in the list, which signs in to the account.
    private var notionTokenRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showingNotionToken = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "key.fill").font(.title2).foregroundStyle(.gray).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Notion (integration token)").font(.headline).foregroundStyle(.primary)
                        Text(notionAccountConnected
                             ? "Saved by an earlier version. Your Notion account above does the same job, so with both on the assistant gets two sets of Notion tools."
                             : "Saved by an earlier version. Notion in the list below signs in to your account instead.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.buttonStyle(.plain)
            if notionAccountConnected {
                Button("Remove Token", role: .destructive) { confirmingTokenRemoval = true }
                    .font(.subheadline)
            }
            Toggle("Use in this chat", isOn: $viewModel.activePrompt.enableNotionIntegration)
                .font(.subheadline)
                .onChange(of: viewModel.activePrompt.enableNotionIntegration) { _, _ in viewModel.saveActivePrompt() }
        }.padding(.vertical, 4)
    }

    /// A signed-in Notion account (Notion's hosted MCP server) replaces the old integration token.
    private var notionAccountConnected: Bool {
        store.connections.contains { MCPDiscoveryConfiguration.isNotionHosted($0.serverURL) && !$0.needsSignIn }
    }

    private func refreshNotionToken() {
        hasNotionToken = !(KeychainService.shared.load(forKey: "notionApiKey") ?? "").isEmpty
    }

    private var missingIDs: [UUID] {
        (viewModel.activePrompt.currentOptions.mcpConnectionIDs ?? []).filter { id in !store.connections.contains { $0.id == id } }
    }
    private func migrateLegacy() {
        guard viewModel.activePrompt.currentOptions.mcpConnectionIDs == nil else { return }
        do {
            if let id = try store.importLegacy(prompt: viewModel.activePrompt) {
                viewModel.activePrompt.currentOptions.mcpConnectionIDs = [id]
                viewModel.activePrompt.mcpHeaders = ""
                viewModel.saveActivePrompt()
            }
        } catch { self.error = error.localizedDescription }
    }
    private func setActive(_ id: UUID, enabled: Bool) {
        do { try viewModel.setMCPConnection(id, enabled: enabled) }
        catch { self.error = error.localizedDescription }
    }

    /// Loads the next registry page for the current search (or for no search, which lists every server).
    private func loadRegistry(reset: Bool = false) {
        guard !demo else { return }
        let text = trimmedQuery
        if reset {
            registry = []; cursor = nil; reachedEnd = false; registryQuery = text; error = nil
        } else {
            guard !searching, !reachedEnd, registryQuery == text else { return }
        }
        let next = cursor
        searching = true
        Task {
            do {
                let page = try await MCPRegistryService.search(text, cursor: next)
                guard registryQuery == text else { return }
                let existing = Set(registry.map(\.id))
                registry.append(contentsOf: page.providers.filter { !existing.contains($0.id) })
                cursor = page.nextCursor
                reachedEnd = page.nextCursor == nil || page.nextCursor == next
            } catch {
                if registryQuery == text { self.error = "The registry could not be reached. Your connections still work." }
            }
            if registryQuery == text { searching = false }
        }
    }
}

private struct MCPProviderRow: View {
    let provider: MCPProvider
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: provider.icon).font(.title3).foregroundStyle(.blue)
                .frame(width: 34, height: 34).background(.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name).font(.headline)
                Text(provider.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text(provider.signInLabel).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }.padding(.vertical, 4).contentShape(Rectangle())
    }
}

@MainActor
final class MCPConnectFlow: ObservableObject {
    @Published private(set) var busy = false
    @Published private(set) var progress = ""
    @Published var error: String?
    @Published private(set) var connected: MCPConnection?
    private let web = MCPWebAuthentication()
    private var attempt = UUID()
    private var task: Task<Void, Never>?

    func connect(provider: MCPProvider, reconnecting: UUID? = nil, completion: @escaping (MCPConnection) throws -> Void) {
        guard !busy else { return }
        error = nil; busy = true
        let currentAttempt = UUID(); attempt = currentAttempt
        task = Task {
            do {
                let connection: MCPConnection
                if provider.signIn == .publicAccess {
                    connection = try MCPConnectionStore.shared.addPublic(providerID: provider.id, name: provider.name, serverURL: provider.serverURL)
                } else {
                    connection = try await MCPConnectionStore.shared.connect(providerID: provider.id, name: provider.name,
                        serverURL: provider.serverURL, reconnecting: reconnecting, authenticate: { try await self.web.signIn(url: $0) }, progress: { if self.attempt == currentAttempt { self.progress = $0 } })
                }
                try Task.checkCancellation()
                guard attempt == currentAttempt else { return }
                connected = connection
                try completion(connection)
            } catch {
                if attempt == currentAttempt && !Task.isCancelled && error as? MCPAuthorizationError != .cancelled {
                    self.error = (error as? MCPAuthorizationError)?.localizedDescription ?? "Connection could not finish. Please try again."
                }
            }
            if attempt == currentAttempt { busy = false }
        }
    }
    func cancel() { attempt = UUID(); task?.cancel(); web.cancel(); task = nil; busy = false }
}

struct MCPProviderDetailView: View {
    let provider: MCPProvider
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flow = MCPConnectFlow()
    @AppStorage("exploreModeEnabled") private var demo = false
    @State private var showingKey = false
    @State private var token = ""
    @State private var keyError: String?

    private func connectWithKey() {
        if demo { demo = false; viewModel.exploreModeEnabled = false }
        keyError = nil
        do {
            // The store sends it as "Authorization: Bearer …", with or without the word Bearer typed.
            let connection = try MCPConnectionStore.shared.addAPIKey(name: provider.name, serverURL: provider.serverURL,
                                                                     header: "Authorization", token: token)
            try viewModel.setMCPConnection(connection.id, enabled: true)
            token = ""
            dismiss()
        } catch { keyError = error.localizedDescription }
    }

    var body: some View {
        Form {
            Section {
                Label(provider.name, systemImage: provider.icon).font(.title2.bold())
                Text(provider.summary).foregroundStyle(.secondary)
                if !provider.serverURL.isEmpty { LabeledContent("Server", value: provider.host).font(.caption) }
                if let publisher = provider.registryName {
                    LabeledContent("Registry publisher", value: publisher).font(.caption).textSelection(.enabled)
                }
            }
            Section {
                if let connection = flow.connected {
                    Label("Connected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("\(connection.name) is ready to use in this chat. You can manage its tools and permissions from Your connections.")
                    Button("Done") { dismiss() }
                } else if provider.signIn == .providerSetup && provider.serverURL.isEmpty {
                    Label("Not available here yet", systemImage: "building.2.crop.circle")
                    Text("OpenAI runs this connector, and it needs a sign-in that OpenResponses can't offer yet.")
                        .font(.callout).foregroundStyle(.secondary)
                } else if provider.signIn == .providerSetup && !flow.busy {
                    // Some providers only let apps they've approved use account sign-in. Trying costs nothing:
                    // if it's refused, a key or token from the provider's settings works instead.
                    Button {
                        if demo { demo = false; viewModel.exploreModeEnabled = false }
                        flow.connect(provider: MCPProvider(id: provider.id, name: provider.name, summary: provider.summary,
                            category: provider.category, serverURL: provider.serverURL, signIn: .automatic)) {
                            try viewModel.setMCPConnection($0.id, enabled: true)
                        }
                    } label: {
                        Label("Try Signing In to \(provider.name)", systemImage: "person.crop.circle.badge.checkmark")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.buttonStyle(.borderedProminent).padding(.vertical, 4)
                    Text("\(provider.name) may only allow sign-in from apps it has approved. If sign-in is refused, connect with a key or token from your \(provider.name) settings below.")
                        .font(.callout).foregroundStyle(.secondary)
                    DisclosureGroup("Connect with a key or token", isExpanded: $showingKey) {
                        SecureField("Key or token", text: $token)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button("Connect with This Key") { connectWithKey() }
                            .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Text("Sent as the Authorization header. Stored in this iPhone's Keychain.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else if flow.busy {
                    ProgressView(flow.progress)
                    Button("Cancel Sign-in", role: .cancel) { flow.cancel() }
                } else {
                    Button {
                        if demo { demo = false; viewModel.exploreModeEnabled = false }
                        flow.connect(provider: provider) { try viewModel.setMCPConnection($0.id, enabled: true) }
                    } label: {
                        Label(demo ? "Leave Demo & Connect" : "Connect \(provider.name)", systemImage: "person.crop.circle.badge.checkmark")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.buttonStyle(.borderedProminent).padding(.vertical, 4)
                    Text(provider.signIn == .publicAccess ? "This public server does not need account sign-in." :
                        "A secure browser window opens the provider’s login. Choose your account and approve the access you want to grant.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if let error = flow.error ?? keyError {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                }
            } header: { Text("Connect your account") }
            Section {
                Text("Connections are saved in this device’s Keychain. When you use an app in chat, OpenAI receives the connection authorization and sends requests to that provider. Review requested tool calls before approving them.")
                    .font(.callout).foregroundStyle(.secondary)
                if let address = provider.documentationURL, let url = try? MCPOAuthSecurity.publicHTTPS(address) {
                    Link("Provider connection instructions", destination: url)
                }
                if !provider.serverURL.isEmpty {
                    DisclosureGroup("Server address") { Text(provider.serverURL).font(.caption.monospaced()).textSelection(.enabled) }
                }
            }
        }
        .navigationTitle(provider.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        .onDisappear { flow.cancel() }
    }
}

struct MCPConnectionDetailView: View {
    let id: UUID
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject private var store = MCPConnectionStore.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flow = MCPConnectFlow()
    @State private var snapshot: MCPDiscoverySnapshot?
    @State private var error: String?
    @State private var loading = false
    @State private var task: Task<Void, Never>?
    @State private var showingConsent = false
    @State private var showingDisconnect = false
    @State private var showingRename = false
    @State private var accountName = ""
    @AppStorage("exploreModeEnabled") private var demo = false
    @AppStorage(AppFeatureFlags.aiDataSharingConsentVersionKey) private var consentVersion = 0
    private var connection: MCPConnection? { store.connections.first { $0.id == id } }

    var body: some View {
        Form {
            if let connection {
                Section {
                    LabeledContent("Account", value: connection.name)
                    Button("Rename Account") { accountName = connection.name; showingRename = true }
                    LabeledContent("Status", value: connection.needsSignIn ? "Sign-in required" : connection.authentication == .oauth ? "Connected" : "Saved")
                    Toggle("Use in this chat", isOn: Binding(
                        get: { viewModel.activePrompt.enableMCPTool && (viewModel.activePrompt.currentOptions.mcpConnectionIDs ?? []).contains(id) },
                        set: { value in perform { try viewModel.setMCPConnection(id, enabled: value) } }
                    )).disabled(connection.needsSignIn)
                    if connection.authentication == .oauth || MCPProvider.featured.contains(where: { $0.serverURL == connection.serverURL && $0.signIn == .oauth }) {
                        if flow.busy { ProgressView(flow.progress); Button("Cancel Sign-in") { flow.cancel() } }
                        else {
                            Button(demo ? "Leave Demo & Sign In Again" : "Sign In Again") {
                                demo = false; viewModel.exploreModeEnabled = false
                                let provider = MCPProvider(id: connection.providerID, name: connection.name, summary: "", category: .productivity, serverURL: connection.serverURL)
                                flow.connect(provider: provider, reconnecting: id) { _ in snapshot = nil }
                            }
                        }
                    }
                    if let error = flow.error ?? error { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
                }
                Section {
                    Toggle("Ask before running tools", isOn: Binding(
                        get: { connection.requireApproval != "never" },
                        set: { value in perform { try store.updatePolicy(id: id, approval: value ? "always" : "never", allowedTools: connection.allowedTools) } }
                    ))
                    if connection.requireApproval == "never" {
                        Text("Tools can read or change provider data without a confirmation. Only enable this for tools you trust.").font(.caption).foregroundStyle(.secondary)
                    }
                    if !connection.allowedTools.isEmpty {
                        LabeledContent("Allowed tools", value: "\(connection.allowedTools.count) selected")
                        Button("Allow All Available Tools") { perform { try store.updatePolicy(id: id, approval: connection.requireApproval, allowedTools: []) }; snapshot = nil }
                    }
                } header: { Text("Permissions") } footer: { Text("These permissions apply everywhere this account is used.") }
                Section {
                    if loading { ProgressView("Fetching tool definitions…"); Button("Cancel") { task?.cancel(); loading = false } }
                    else {
                        Button(snapshot == nil ? "Discover Tools" : "Refresh Tools") {
                            if (KeychainService.shared.load(forKey: "openAIKey") ?? "").isEmpty {
                                error = OpenAIServiceError.missingAPIKey.localizedDescription
                            } else if consentVersion < AppFeatureFlags.aiDataSharingConsentVersion { showingConsent = true }
                            else { discover() }
                        }.disabled(demo || connection.needsSignIn)
                    }
                    if let snapshot {
                        Label("\(snapshot.tools.count) tools available", systemImage: "checkmark.circle").foregroundStyle(.green)
                        NavigationLink("Browse Tools & Choose Access") { MCPConnectionToolsView(id: id, snapshot: snapshot) }
                        Text("Checked \(snapshot.checkedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                    } else if let date = connection.lastCheckedAt, let count = connection.toolCount {
                        Text("Last checked \(date.formatted(date: .abbreviated, time: .shortened)) · \(count) tools").font(.caption).foregroundStyle(.secondary)
                    }
                } header: { Text("Tools") } footer: {
                    Text(demo ? "Demo Mode is offline. Leave Demo Mode in General to discover tools." : "Retrieves definitions through OpenAI using your API account. This does not run tools or send your chat history.")
                }
                Section {
                    if !connection.serverURL.isEmpty { Text(connection.serverURL).font(.caption.monospaced()).textSelection(.enabled) }
                    Button("Disconnect", role: .destructive) { showingDisconnect = true }
                } footer: { Text("Disconnect removes this account from this device. To revoke the provider’s grant as well, use the connected-app settings in your provider account.") }
            } else { ContentUnavailableView("Connection removed", systemImage: "link.badge.plus") }
        }
        .navigationTitle(connection?.name ?? "Connection").navigationBarTitleDisplayMode(.inline)
        .onDisappear { task?.cancel(); flow.cancel(); loading = false }
        .onChange(of: demo) { _, enabled in if enabled { task?.cancel(); flow.cancel(); loading = false } }
        .alert("Before You Send", isPresented: $showingConsent) {
            Button("Allow & Discover") { consentVersion = AppFeatureFlags.aiDataSharingConsentVersion; discover() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("OpenAI will receive this server configuration and authorization to retrieve tool definitions from the provider. Your chat history is not included and tools will not run.") }
        .confirmationDialog("Disconnect this account?", isPresented: $showingDisconnect, titleVisibility: .visible) {
            Button("Disconnect", role: .destructive) {
                perform {
                    try store.disconnect(id: id)
                    viewModel.activePrompt.currentOptions.mcpConnectionIDs?.removeAll { $0 == id }
                    viewModel.saveActivePrompt(); dismiss()
                }
            }
        }
        .alert("Account Name", isPresented: $showingRename) {
            TextField("Name or workspace", text: $accountName)
            Button("Save") { perform { try store.rename(id: id, name: accountName) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Give this account a name you can recognize when connecting more than one workspace.") }
    }
    private func perform(_ action: () throws -> Void) { do { try action(); error = nil } catch { self.error = error.localizedDescription } }
    private func discover() {
        guard !demo else { return }
        task?.cancel(); loading = true; error = nil
        task = Task {
            do {
                try await store.prepare(id: id)
                let result = try await MCPDiscoveryService.shared.discover(store.configuration(id: id, includeAllTools: true), forceRefresh: true)
                try Task.checkCancellation()
                try store.recordDiscovery(id: id, snapshot: result)
                snapshot = result
            } catch {
                guard !Task.isCancelled else { return }
                self.error = (error as? MCPAuthorizationError)?.localizedDescription ?? (error as? MCPDiscoveryError)?.localizedDescription ?? (error as? OpenAIServiceError)?.localizedDescription ?? "Tool discovery could not finish. Please retry."
            }
            loading = false
        }
    }
}

private struct MCPConnectionToolsView: View {
    let id: UUID
    let snapshot: MCPDiscoverySnapshot
    @ObservedObject private var store = MCPConnectionStore.shared
    @State private var search = ""
    @State private var error: String?
    private var connection: MCPConnection? { store.connections.first { $0.id == id } }
    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.orange) }
            Text("All tools are allowed unless you select a specific set. Selecting tools limits what this account can expose to chat.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(snapshot.tools.filter { search.isEmpty || ($0.name + " " + $0.description).localizedCaseInsensitiveContains(search) }) { tool in
                DisclosureGroup {
                    Text(tool.description).font(.callout).textSelection(.enabled)
                    Text(tool.schemaJSON).font(.caption.monospaced()).textSelection(.enabled)
                    if let annotations = tool.annotationsJSON { Text(annotations).font(.caption.monospaced()).textSelection(.enabled) }
                } label: {
                    Toggle(tool.name, isOn: Binding(
                        get: { connection?.allowedTools.isEmpty == true || connection?.allowedTools.contains(tool.name) == true },
                        set: { value in select(tool.name, enabled: value) }
                    )).font(.subheadline.monospaced())
                }
            }
        }.navigationTitle("Tools").searchable(text: $search, prompt: "Find a tool")
    }
    private func select(_ name: String, enabled: Bool) {
        guard let connection else { return }
        var selected = connection.allowedTools.isEmpty ? snapshot.tools.map(\.name) : connection.allowedTools
        selected.removeAll { $0 == name }; if enabled { selected.append(name) }
        guard !selected.isEmpty else { error = "Keep at least one tool selected, or switch off Use in this chat to disable this connection."; return }
        do { try store.updatePolicy(id: id, approval: connection.requireApproval, allowedTools: selected); error = nil }
        catch { self.error = error.localizedDescription }
    }
}

extension ChatViewModel {
    func setMCPConnection(_ id: UUID, enabled: Bool) throws {
        var ids = activePrompt.currentOptions.mcpConnectionIDs
        if ids == nil { ids = try MCPConnectionStore.shared.importLegacy(prompt: activePrompt).map { [$0] } ?? [] }
        ids?.removeAll { $0 == id }
        if enabled { ids?.append(id) }
        activePrompt.currentOptions.mcpConnectionIDs = ids
        activePrompt.mcpHeaders = ""
        activePrompt.enableMCPTool = !(ids ?? []).isEmpty
        saveActivePrompt()
    }
}
