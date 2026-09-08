import SwiftUI
import Combine

/// One account library, shared across prompts. A prompt stores only the IDs it uses.
struct MCPConnectionsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject private var store = MCPConnectionStore.shared
    @State private var query = ""
    @State private var category: MCPProvider.Category?
    @State private var selectedProvider: MCPProvider?
    @State private var showingCustom = false
    @State private var registry: [MCPProvider] = []
    @State private var registryQuery = ""
    @State private var cursor: String?
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var error: String?
    @AppStorage("exploreModeEnabled") private var demo = false

    private var providers: [MCPProvider] {
        MCPProvider.featured.filter {
            (category == nil || $0.category == category) && (query.isEmpty ||
                ($0.name + " " + $0.summary).localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bring your apps into chat").font(.title3.bold())
                    Text("Connect an account, then choose which apps this chat can use.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }.padding(.vertical, 4)
                if demo {
                    Label("Demo Mode · browsing the catalog is offline", systemImage: "sparkles")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let error = store.storageError ?? error {
                    Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.orange)
                }
            }

            Section {
                if store.connections.isEmpty {
                    Label("No connected accounts yet", systemImage: "person.crop.circle.badge.plus")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.connections) { connection in
                    VStack(alignment: .leading, spacing: 10) {
                        NavigationLink {
                            MCPConnectionDetailView(id: connection.id, viewModel: viewModel)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: connection.needsSignIn ? "person.crop.circle.badge.exclamationmark" : "link.circle.fill")
                                    .font(.title2).foregroundStyle(connection.needsSignIn ? .orange : .blue)
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
                if !missingIDs.isEmpty {
                    Button("Remove unavailable connections from this chat") {
                        let missing = Set(missingIDs)
                        viewModel.activePrompt.currentOptions.mcpConnectionIDs?.removeAll { missing.contains($0) }
                        viewModel.saveActivePrompt()
                    }
                }
            } header: { Text("Your connections") } footer: {
                if !store.connections.isEmpty { Text("Accounts stay connected when switched off. Tool calls ask for approval by default.") }
            }

            Section {
                TextField("Search apps and services", text: $query)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("mcp.catalog.search")
                Picker("Category", selection: $category) {
                    Text("All apps").tag(nil as MCPProvider.Category?)
                    ForEach(MCPProvider.Category.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                }
                ForEach(providers) { provider in
                    Button { selectedProvider = provider } label: { MCPProviderRow(provider: provider) }
                        .buttonStyle(.plain)
                }
                if providers.isEmpty { Text("No featured apps match this search.").foregroundStyle(.secondary) }
            } header: { Text("Explore apps · \(MCPProvider.featured.count)") } footer: {
                Text("Account sign-in opens the provider’s login. Some providers must approve OpenResponses before sign-in becomes available.")
            }

            Section {
                Button {
                    if demo { demo = false; viewModel.exploreModeEnabled = false }
                    searchRegistry()
                } label: {
                    Label(demo ? "Leave Demo & Search the Registry" : "Search the MCP Registry", systemImage: "globe")
                }.disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || searching)
                if searching { ProgressView("Searching remote servers…") }
                ForEach(registry) { provider in
                    Button { selectedProvider = provider } label: { MCPProviderRow(provider: provider) }
                        .buttonStyle(.plain)
                }
                if !registryQuery.isEmpty && !searching && registry.isEmpty {
                    Text("No supported remote servers found for “\(registryQuery)”.").foregroundStyle(.secondary)
                }
                if cursor != nil && !searching {
                    Button("Load more servers") { searchRegistry(nextPage: true) }
                }
            } header: { Text("Find more connections") } footer: {
                Text("Searches the public MCP Registry for remote HTTPS servers. Listings are supplied by publishers; check the publisher and server address before connecting. Local packages cannot run on iPhone.")
            }

            Section {
                Button { showingCustom = true } label: { Label("Add a Custom Server", systemImage: "plus") }
            }
        }
        .navigationTitle("Connections")
        .sheet(item: $selectedProvider) { provider in
            NavigationStack { MCPProviderDetailView(provider: provider, viewModel: viewModel) }
        }
        .sheet(isPresented: $showingCustom) { RemoteMCPSetupSheet().environmentObject(viewModel) }
        .task(id: viewModel.activePrompt.id) { migrateLegacy() }
        .onChange(of: query) { _, _ in
            searchTask?.cancel(); searchTask = nil; searching = false
            registry = []; cursor = nil; registryQuery = ""
        }
        .onChange(of: demo) { _, enabled in if enabled { searchTask?.cancel(); searching = false } }
        .onDisappear { searchTask?.cancel(); searching = false }
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
    private func searchRegistry(nextPage: Bool = false) {
        searchTask?.cancel()
        let text = nextPage ? registryQuery : query.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = nextPage ? cursor : nil
        if !nextPage { registry = []; cursor = nil }
        registryQuery = text; searching = true; error = nil
        searchTask = Task {
            do {
                let page = try await MCPRegistryService.search(text, cursor: next)
                try Task.checkCancellation()
                let existing = Set(registry.map(\.id))
                registry.append(contentsOf: page.providers.filter { !existing.contains($0.id) })
                cursor = page.nextCursor == next ? nil : page.nextCursor
            } catch {
                guard !Task.isCancelled else { return }
                self.error = "The registry could not be reached. Your saved connections are still available."
            }
            searching = false
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
                Text(provider.signInLabel).font(.caption2).foregroundStyle(provider.signIn == .providerSetup ? .orange : .secondary)
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
                } else if provider.signIn == .providerSetup {
                    Label("Provider setup required", systemImage: "building.2.crop.circle")
                    Text("This provider requires OpenResponses to be registered or approved before account sign-in can be offered. A login button becomes available once that provider setup is complete.")
                    Text("This is setup for the app developer or workspace administrator. You do not need to find and paste an OAuth access token.")
                        .font(.callout).foregroundStyle(.secondary)
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
                if let error = flow.error {
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
