import SwiftUI
import Combine
import CryptoKit

@MainActor
final class MCPDiscoveryViewModel: ObservableObject {
    enum State {
        case idle, loading, ready(MCPDiscoverySnapshot), failed(String)
    }
    @Published private(set) var state: State = .idle
    private var task: Task<Void, Never>?
    private var generation = UUID()

    func refresh(configuration: () throws -> MCPDiscoveryConfiguration) {
        reset()
        do {
            let configuration = try configuration()
            let generation = self.generation
            state = .loading
            task = Task { [weak self] in
                do {
                    let snapshot = try await MCPDiscoveryService.shared.discover(configuration, forceRefresh: true)
                    guard let self, !Task.isCancelled, self.generation == generation else { return }
                    self.state = .ready(snapshot)
                } catch {
                    guard let self, !Task.isCancelled, self.generation == generation else { return }
                    // Known local errors only; the discovery service strips remote diagnostic text.
                    self.state = .failed((error as? MCPDiscoveryError)?.localizedDescription ??
                                        (error as? OpenAIServiceError)?.localizedDescription ?? "Discovery could not finish. Please retry.")
                }
            }
        } catch { state = .failed(error.localizedDescription) }
    }

    func reset() {
        generation = UUID()
        task?.cancel()
        task = nil
        state = .idle
    }

    func cancelIfLoading() {
        if case .loading = state { reset() }
    }
}

/// Same discovery UI for saved connections and unsaved drafts. No credential writes.
struct MCPDiscoverySection: View {
    let prompt: Prompt
    var headersOverride: [String: String]? = nil
    var connectorTokenOverride: String? = nil
    var canTest = true
    @StateObject private var discovery = MCPDiscoveryViewModel()
    @AppStorage("exploreModeEnabled") private var exploreModeEnabled = false
    @AppStorage(AppFeatureFlags.aiDataSharingConsentVersionKey) private var consentVersion = 0
    @State private var showingConsent = false

    private var identity: String {
        // A fingerprint prevents stale results after edits without putting credentials into view IDs.
        let values: [String: Any] = ["label": prompt.mcpServerLabel, "url": prompt.mcpServerURL,
            "connector": prompt.mcpConnectorId ?? "", "isConnector": prompt.mcpIsConnector,
            "headers": headersOverride ?? MCPDiscoveryConfiguration.savedHeaders(for: prompt),
            "token": connectorTokenOverride ?? (prompt.mcpConnectorId.flatMap { KeychainService.shared.load(forKey: "mcp_connector_\($0)") } ?? ""),
            "allowed": prompt.mcpAllowedTools, "keepAuthInHeaders": prompt.mcpKeepAuthInHeaders,
            "apiAccount": KeychainService.shared.load(forKey: "openAIKey") ?? ""]
        let bytes = (try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])) ?? Data()
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }

    var body: some View {
        Section {
            switch discovery.state {
            case .loading:
                HStack {
                    ProgressView()
                    Text("Discovering tools…")
                    Spacer()
                    Button("Cancel") { discovery.reset() }
                }
            default:
                Button { discover() } label: {
                    Label(buttonTitle, systemImage: "arrow.clockwise")
                }
                .disabled(!canTest || exploreModeEnabled)
            }
            switch discovery.state {
            case .ready(let snapshot):
                Label(snapshot.tools.isEmpty ? "Connected · No tools available" : "Connected · \(snapshot.tools.count) tools", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Checked \(snapshot.checkedAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption).foregroundStyle(.secondary)
                if snapshot.filtered {
                    Text("Showing tools permitted by your allowed-tools list.").font(.caption).foregroundStyle(.secondary)
                }
                if snapshot.tools.isEmpty {
                    Text("The server returned an empty catalog. Check the account permissions and allowed-tools list.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    NavigationLink {
                        MCPToolCatalogView(snapshot: snapshot)
                    } label: {
                        Label("Browse Tools", systemImage: "list.bullet.rectangle")
                    }
                    ForEach(snapshot.tools.prefix(3)) { tool in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tool.name).font(.subheadline.monospaced())
                            if !tool.description.isEmpty {
                                Text(tool.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
            case .idle, .loading: EmptyView()
            }
        } header: {
            Label("Tool Discovery", systemImage: "network")
        } footer: {
            Text(exploreModeEnabled ? "Demo Mode is offline. Turn it off in Settings → General to discover tools." : "Fetches tool definitions through OpenAI without calling tools. Discovery uses your API account. Account sign-in is handled separately.")
        }
        .onChange(of: identity) { _, _ in discovery.reset() }
        .onDisappear { discovery.cancelIfLoading() }
        .onChange(of: exploreModeEnabled) { _, _ in discovery.reset() }
        .onChange(of: consentVersion) { _, version in
            if version < AppFeatureFlags.aiDataSharingConsentVersion { discovery.reset() }
        }
        .alert("Before You Send", isPresented: $showingConsent) {
            Button("Allow & Discover") {
                consentVersion = AppFeatureFlags.aiDataSharingConsentVersion
                discover()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("OpenAI will receive this server configuration and its authorization to retrieve tool definitions. The configured MCP provider will receive the discovery request. Your chat history is not included and tools will not be called.")
        }
    }

    private func discover() {
        guard !exploreModeEnabled else { return }
        let hasKey = !(KeychainService.shared.load(forKey: "openAIKey") ?? "").isEmpty
        if hasKey, consentVersion < AppFeatureFlags.aiDataSharingConsentVersion {
            showingConsent = true
            return
        }
        discovery.refresh {
            try MCPDiscoveryConfiguration(prompt: prompt, headersOverride: headersOverride,
                                          connectorTokenOverride: connectorTokenOverride)
        }
    }

    private var buttonTitle: String {
        switch discovery.state {
        case .ready: return "Refresh Tools"
        case .failed: return "Retry Discovery"
        default: return "Discover Tools"
        }
    }
}

private struct MCPToolCatalogView: View {
    let snapshot: MCPDiscoverySnapshot
    @State private var search = ""
    private var tools: [MCPDiscoveredTool] {
        guard !search.isEmpty else { return snapshot.tools }
        return snapshot.tools.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.description.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        List(tools) { tool in
            DisclosureGroup {
                if !tool.description.isEmpty { Text(tool.description).font(.subheadline).textSelection(.enabled) }
                Text("Input Schema").font(.caption.bold())
                Text(tool.schemaJSON).font(.caption.monospaced()).textSelection(.enabled)
                if let annotations = tool.annotationsJSON {
                    Text("Server Annotations").font(.caption.bold())
                    Text(annotations).font(.caption.monospaced()).textSelection(.enabled)
                }
            } label: { Text(tool.name).font(.subheadline.monospaced()) }
        }
        .navigationTitle(snapshot.label)
        .searchable(text: $search, prompt: "Find a tool")
        .overlay { if tools.isEmpty { ContentUnavailableView.search(text: search) } }
    }
}
