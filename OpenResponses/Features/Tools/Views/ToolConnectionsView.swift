import SwiftUI
import AuthenticationServices
import Combine

struct ToolConnectionsView: View {
    @StateObject private var viewModel = ToolConnectionsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatViewModel: ChatViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client-Only Connections"), footer: Text("Direct connections to services that run entirely on your device. No server required.")) {
                    // Notion
                    HStack {
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundColor(.black)
                        Text("Notion")
                        Spacer()
                        if viewModel.isNotionConnected {
                            Button("Disconnect") { viewModel.toggleNotionConnection() }
                                .buttonStyle(.bordered)
                                .tint(.red)
                        }
                    }
                    if !viewModel.isNotionConnected {
                        SecureField("Paste Notion Integration Token", text: $viewModel.notionToken)
                        Button("Connect") { viewModel.toggleNotionConnection() }
                            .disabled(!viewModel.isNotionTokenValid)
#if DEBUG
                        Button("Load Notion Token from test.env (dev)") {
                            viewModel.loadNotionTokenFromDevFile()
                        }
                        .font(.caption)
#endif
                    }

                    Button("Validate Token (users/me)") {
                        viewModel.validateNotionToken()
                    }
                    .font(.caption)
                    Button("Quick Smoke Test") {
                        viewModel.quickSmokeTest()
                    }
                    .font(.caption)

                    // Minimal client-only test harness (No server)
                    TextField("Page URL or Page ID", text: $viewModel.notionPageInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Button("Resolve Database ID from Page URL/ID") {
                        viewModel.resolveNotionDatabaseId()
                    }
                    .disabled(!(viewModel.isNotionConnected && !viewModel.notionPageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                    TextField("Database ID (UUID)", text: $viewModel.notionDatabaseId)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("Data Source ID (optional)", text: $viewModel.notionDataSourceId)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("Title Equals (optional, e.g., OpenAssistant)", text: $viewModel.notionTitleEquals)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("Title Property (default: Project Name)", text: $viewModel.notionTitleProperty)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Button("List Pages in Database") {
                        viewModel.listNotionPages()
                    }
                    .disabled(!(viewModel.isNotionConnected && !viewModel.notionDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                    // Google Services
                    ForEach(viewModel.googleProviders) { provider in
                        HStack {
                            Image(systemName: provider.icon)
                                .foregroundColor(provider.color)
                            Text(provider.kind.rawValue.capitalized)
                            Spacer()
                            Button(provider.isConnected ? "Disconnect" : "Connect") {
                                if provider.isConnected {
                                    viewModel.disconnectGoogleProvider(provider.kind)
                                } else {
                                    viewModel.connectGoogleProvider(provider.kind)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(provider.isConnected ? .red : .accentColor)
                        }
                    }
                }

                Section(header: Text("OpenAI Connectors"), footer: Text("Secure connections to services like Dropbox, managed by OpenAI.")) {
                    Button(action: { viewModel.showingConnectorGallery = true }) {
                        Label("Browse Connector Gallery", systemImage: "square.grid.2x2.fill")
                    }
                }
                
                Section(header: Text("Advanced")) {
                    Button(action: { viewModel.showingCustomMCPSheet = true }) {
                        Label("Connect to Custom Backend Server (MCP)", systemImage: "server.rack")
                    }
                }

                if let status = viewModel.statusMessage {
                    Section {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(viewModel.hasError ? .red : .secondary)
                    }
                }
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.checkInitialConnectionStatus()
            }
            .sheet(isPresented: $viewModel.showingConnectorGallery) {
                MCPConnectorGalleryView(viewModel: chatViewModel)
            }
            .sheet(isPresented: $viewModel.showingCustomMCPSheet) {
                MCPConnectorGalleryView(viewModel: chatViewModel)
            }
        }
    }
}

@MainActor
class ToolConnectionsViewModel: ObservableObject {
    @Published var notionToken: String = ""
    @Published var isNotionConnected: Bool = false
    @Published var statusMessage: String?
    @Published var hasError: Bool = false
    @Published var showingConnectorGallery = false
    @Published var showingCustomMCPSheet = false

    // Notion quick test inputs
    @Published var notionPageInput: String = ""
    @Published var notionDatabaseId: String = ""
    @Published var notionDataSourceId: String = ""
    @Published var notionTitleEquals: String = ""
    @Published var notionTitleProperty: String = "Project Name"
    
    struct GoogleProviderState: Identifiable {
        var id: ToolKind { kind }
        let kind: ToolKind
        var isConnected: Bool
        var icon: String
        var color: Color
    }
    
    @Published var googleProviders: [GoogleProviderState] = [
        .init(kind: .gmail, isConnected: false, icon: "envelope.fill", color: .red),
        .init(kind: .gcal, isConnected: false, icon: "calendar", color: .blue),
        .init(kind: .gcontacts, isConnected: false, icon: "person.2.fill", color: .green)
    ]

    var isNotionTokenValid: Bool {
        !notionToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func checkInitialConnectionStatus() {
        // Notion
        if let token = TokenStore.readString(account: ToolHub.shared.notion.tokenAccount), !token.isEmpty {
            isNotionConnected = true
            notionToken = "********************" // Placeholder for security
        } else {
            isNotionConnected = false
        }
        
        // Google Services
        for i in 0..<googleProviders.count {
            let key = "oauth.\(googleProviders[i].kind.rawValue).tokens"
            googleProviders[i].isConnected = TokenStore.read(account: key) != nil
        }
    }

    func toggleNotionConnection() {
        if isNotionConnected {
            // Disconnect
            if TokenStore.delete(account: ToolHub.shared.notion.tokenAccount) {
                isNotionConnected = false
                notionToken = ""
                setStatus("Notion disconnected.", isError: false)
            } else {
                setStatus("Failed to disconnect Notion.", isError: true)
            }
        } else {
            // Connect
            guard isNotionTokenValid else {
                setStatus("Please enter a valid Notion token.", isError: true)
                return
            }
            if TokenStore.saveString(notionToken, account: ToolHub.shared.notion.tokenAccount) {
                isNotionConnected = true
                setStatus("Notion connected successfully.", isError: false)
            } else {
                setStatus("Failed to save Notion token to Keychain.", isError: true)
            }
        }
    }
    
    #if DEBUG
    func loadNotionTokenFromDevFile() {
        let candidates: [String] = [
            "/Users/gunnarhostetler/Documents/GitHub/OpenResponses/test.env",
            NSHomeDirectory() + "/Documents/GitHub/OpenResponses/test.env"
        ]
        var token: String?
        for p in candidates {
            if FileManager.default.fileExists(atPath: p),
               let content = try? String(contentsOfFile: p, encoding: .utf8) {
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { token = trimmed; break }
            }
        }
        if token == nil, let url = Bundle.main.url(forResource: "test", withExtension: "env"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { token = trimmed }
        }
        guard let t = token else {
            setStatus("Dev token file not found.", isError: true)
            return
        }
        notionToken = t
        if TokenStore.saveString(t, account: ToolHub.shared.notion.tokenAccount) {
            isNotionConnected = true
            setStatus("Loaded Notion token from test.env (dev).", isError: false)
        } else {
            setStatus("Failed to save dev token to Keychain.", isError: true)
        }
    }
    #endif

    func validateNotionToken() {
        Task {
            let entered = self.notionToken.trimmingCharacters(in: .whitespacesAndNewlines)
            let token: String
            if self.isNotionConnected,
               let saved = TokenStore.readString(account: ToolHub.shared.notion.tokenAccount),
               !saved.isEmpty {
                token = saved
            } else if !entered.isEmpty {
                token = entered
            } else {
                setStatus("Enter or connect a token first.", isError: true)
                return
            }

            let res = await NotionAuthService.shared.preflight(authorizationValue: token)
            if res.ok {
                let user = res.userName ?? "bot"
                let uid = res.userId ?? "-"
                setStatus("Token OK: \(user) [\(uid)]", isError: false)
            } else {
                let snippet = res.message.prefix(300)
                setStatus("Token check failed (\(res.status)): \(snippet)", isError: true)
            }
        }
    }
    
    func quickSmokeTest() {
        Task {
            guard self.isNotionConnected else {
                setStatus("Connect Notion first.", isError: true)
                return
            }
            do {
                var db = self.notionDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines)
                if db.isEmpty {
                    let input = self.notionPageInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !input.isEmpty, let pid = normalizedPageId(from: input) else {
                        setStatus("Provide a Page URL/ID or a Database ID.", isError: true)
                        return
                    }
                    if let parentDb = try await ToolHub.shared.notion.parentDatabaseId(ofPageId: pid) {
                        db = parentDb
                        self.notionDatabaseId = parentDb
                    } else {
                        setStatus("Page is not inside a database.", isError: true)
                        return
                    }
                }
                
                let dsOverride = self.notionDataSourceId.trimmingCharacters(in: .whitespacesAndNewlines)
                let dsParam: String? = dsOverride.isEmpty ? nil : dsOverride
                let filter = self.notionTitleEquals.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let pages: [NotionPageSummary]
                if !filter.isEmpty {
                    let prop = self.notionTitleProperty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Project Name"
                        : self.notionTitleProperty.trimmingCharacters(in: .whitespacesAndNewlines)
                    pages = try await ToolHub.shared.notion.findPages(inDatabase: db, dataSourceId: dsParam, titleProperty: prop, equals: filter, pageSize: 10)
                } else {
                    pages = try await ToolHub.shared.notion.listPages(inDatabase: db, dataSourceId: dsParam, pageSize: 10)
                }
                
                let titles = pages.prefix(10).map { $0.title.isEmpty ? "(untitled)" : $0.title }
                let dsNote = dsParam == nil ? "" : " [DS override used]"
                setStatus("Quick test OK: \(pages.count) page(s). " + titles.joined(separator: ", ") + dsNote, isError: false)
            } catch {
                setStatus(mapNotionError(error), isError: true)
            }
        }
    }
    
    func connectGoogleProvider(_ kind: ToolKind) {
        Task {
            do {
                let provider = provider(for: kind)
                try await provider.connect(presentingAnchor: nil)
                if let index = googleProviders.firstIndex(where: { $0.kind == kind }) {
                    googleProviders[index].isConnected = true
                }
                setStatus("\(kind.rawValue.capitalized) connected successfully.", isError: false)
            } catch {
                setStatus("Failed to connect \(kind.rawValue.capitalized): \(error.localizedDescription)", isError: true)
            }
        }
    }

    func disconnectGoogleProvider(_ kind: ToolKind) {
        let key = "oauth.\(kind.rawValue).tokens"
        if TokenStore.delete(account: key) {
            if let index = googleProviders.firstIndex(where: { $0.kind == kind }) {
                googleProviders[index].isConnected = false
            }
            setStatus("\(kind.rawValue.capitalized) disconnected.", isError: false)
        } else {
            setStatus("Failed to disconnect \(kind.rawValue.capitalized).", isError: true)
        }
    }
    
    // Resolve Database ID from a Page URL or Page ID
    func resolveNotionDatabaseId() {
        let input = notionPageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isNotionConnected, !input.isEmpty else {
            setStatus("Enter a Page URL/ID and connect Notion first.", isError: true)
            return
        }
        guard let pid = normalizedPageId(from: input) else {
            setStatus("Could not parse a Notion page ID from input.", isError: true)
            return
        }
        Task {
            setStatus("Resolving database from page…", isError: false)
            do {
                if let db = try await ToolHub.shared.notion.parentDatabaseId(ofPageId: pid) {
                    notionDatabaseId = db
                    setStatus("Database ID resolved.", isError: false)
                } else {
                    setStatus("Page is not inside a database.", isError: true)
                }
            } catch {
                let msg = mapNotionError(error)
                setStatus(msg, isError: true)
            }
        }
    }

    // Extract a 32-hex page ID and return dashed UUID form
    private func normalizedPageId(from input: String) -> String? {
        let lower = input.lowercased()
        let allowed = "0123456789abcdef"
        let hex = lower.filter { allowed.contains($0) }
        guard hex.count >= 32 else { return nil }
        let tail = String(hex.suffix(32))
        let p1 = tail.prefix(8)
        let p2 = tail.dropFirst(8).prefix(4)
        let p3 = tail.dropFirst(12).prefix(4)
        let p4 = tail.dropFirst(16).prefix(4)
        let p5 = tail.dropFirst(20)
        return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
    }

    func listNotionPages() {
        let db = notionDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isNotionConnected, !db.isEmpty else {
            setStatus("Enter a Database ID and connect Notion first.", isError: true)
            return
        }
        Task {
            setStatus("Querying Notion…", isError: false)
            do {
                let notion = ToolHub.shared.notion
                let pages: [NotionPageSummary]
                let filter = notionTitleEquals.trimmingCharacters(in: .whitespacesAndNewlines)
                let dsOverride = notionDataSourceId.trimmingCharacters(in: .whitespacesAndNewlines)
                let dsParam: String? = dsOverride.isEmpty ? nil : dsOverride

                if !filter.isEmpty {
                    let prop = self.notionTitleProperty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Project Name"
                        : self.notionTitleProperty.trimmingCharacters(in: .whitespacesAndNewlines)
                    pages = try await notion.findPages(inDatabase: db, dataSourceId: dsParam, titleProperty: prop, equals: filter, pageSize: 10)
                } else {
                    pages = try await notion.listPages(inDatabase: db, dataSourceId: dsParam, pageSize: 50)
                }
                let titles = pages.prefix(10).map { $0.title.isEmpty ? "(untitled)" : $0.title }
                let more = pages.count > 10 ? " (+\(pages.count - 10) more)" : ""
                let dsNote = dsParam == nil ? "" : " [DS override used]"
                setStatus("Found \(pages.count) page(s): " + titles.joined(separator: ", ") + more + dsNote, isError: false)
            } catch {
                let msg = mapNotionError(error)
                setStatus(msg, isError: true)
            }
        }
    }

    private func mapNotionError(_ error: Error) -> String {
        let lower = error.localizedDescription.lowercased()
        if lower.contains("401") || lower.contains("unauthorized") {
            return "Notion error: 401 Unauthorized. Check your integration token and that it’s pasted correctly."
        }
        if lower.contains("403") || lower.contains("forbidden") || lower.contains("permission") {
            return "Notion error: 403 Forbidden. Share the database with your integration."
        }
        if lower.contains("404") || lower.contains("not found") {
            return "Notion error: 404 Not Found. Verify the database_id and that your integration has access."
        }
        if lower.contains("429") || lower.contains("rate limit") {
            return "Notion error: 429 Rate limited. Please retry after a short delay."
        }
        return "Notion error: \(error.localizedDescription)"
    }

    private func provider(for kind: ToolKind) -> ToolProvider {
        switch kind {
        case .gmail: return ToolHub.shared.gmail
        case .gcal: return ToolHub.shared.gcal
        case .gcontacts: return ToolHub.shared.gcts
        case .notion: return ToolHub.shared.notion
        case .apple: return AppContainer.shared.appleProvider
        }
    }

    private func setStatus(_ message: String, isError: Bool) {
        self.statusMessage = message
        self.hasError = isError
    }
}

struct ToolConnectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ToolConnectionsView()
    }
}
