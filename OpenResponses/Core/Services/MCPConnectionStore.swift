import Foundation
import Combine
import Security

struct MCPConnection: Identifiable, Codable, Equatable {
    enum Authentication: String, Codable { case oauth, apiKey, publicServer }
    var id: UUID
    var providerID: String
    var name: String
    var serverURL: String
    var connectorID: String?
    var authentication: Authentication
    var requireApproval = "always"
    var allowedTools: [String] = []
    var needsSignIn = false
    var toolCount: Int?
    var lastCheckedAt: Date?
    var serverLabel: String { "mcp_" + id.uuidString.replacingOccurrences(of: "-", with: "").lowercased() }
}

/// Connection metadata and credentials are committed together as one device-only Keychain item.
/// The published model deliberately contains no access tokens, refresh tokens, or client secrets.
@MainActor
final class MCPConnectionStore: ObservableObject {
    static let shared = MCPConnectionStore()
    @Published private(set) var connections: [MCPConnection] = []
    @Published private(set) var storageError: String?
    private struct Record: Codable, Equatable {
        var connection: MCPConnection
        var oauth: MCPOAuthCredential?
        var headers: [String: String]?
    }
    private struct Archive: Codable { var version = 1; var records: [Record] }
    private var records: [Record] = []
    private var refreshes: [UUID: Task<Void, Error>] = [:]
    private var registrations: [String: MCPOAuthClient] = [:]
    private let write: @MainActor (Data) throws -> Void
    private let oauthClient: MCPAuthorizationClient

    init(read: @MainActor () throws -> Data? = MCPConnectionVault.read,
         write: @escaping @MainActor (Data) throws -> Void = MCPConnectionVault.write,
         oauthClient: MCPAuthorizationClient? = nil) {
        self.write = write
        self.oauthClient = oauthClient ?? MCPAuthorizationClient()
        do {
            if let data = try read() {
                let archive = try JSONDecoder().decode(Archive.self, from: data)
                guard archive.version == 1, Set(archive.records.map { $0.connection.id }).count == archive.records.count else { throw MCPAuthorizationError.secureStorage }
                records = archive.records
                connections = records.map(\.connection)
            }
        } catch { storageError = "Saved connections could not be opened. They have been preserved. Unlock your device and reopen the app." }
    }

    private func commit(_ updated: [Record]) throws {
        guard storageError == nil else { throw MCPAuthorizationError.secureStorage }
        do { try write(JSONEncoder().encode(Archive(records: updated))) }
        catch { throw MCPAuthorizationError.secureStorage }
        records = updated
        connections = updated.map(\.connection)
    }

    func connect(providerID: String, name: String, serverURL: String, reconnecting id: UUID? = nil,
                 authenticate: (URL) async throws -> URL, progress: (String) -> Void) async throws -> MCPConnection {
        guard storageError == nil else { throw MCPAuthorizationError.secureStorage }
        let previous = id.flatMap { id in records.first { $0.connection.id == id } }
        if id != nil && previous == nil { throw MCPAuthorizationError.cancelled }
        progress("Finding \(name)’s sign-in service…")
        let metadata = try await oauthClient.discover(serverURL: serverURL)
        try Task.checkCancellation()
        let cacheKey = metadata.issuer + "|" + metadata.authMethod
        let client: MCPOAuthClient
        if let old = previous?.oauth, old.metadata == metadata { client = old.client }
        else if let cached = registrations[cacheKey] { client = cached }
        else {
            progress("Preparing secure sign-in…")
            client = try await oauthClient.register(metadata: metadata)
            registrations[cacheKey] = client
        }
        let state = try MCPOAuthSecurity.random()
        let verifier = try MCPOAuthSecurity.random()
        let url = try oauthClient.authorizationURL(metadata: metadata, client: client, state: state, verifier: verifier)
        try Task.checkCancellation()
        progress("Continue in \(name)’s sign-in window…")
        let callback = try await authenticate(url)
        let code = try MCPOAuthSecurity.callbackCode(callback, state: state, issuer: metadata.issuer)
        progress("Finishing connection…")
        let credential = try await oauthClient.exchange(code: code, verifier: verifier, metadata: metadata, client: client)
        try Task.checkCancellation()
        // Preserve policy/name edits, but never resurrect a removed or reauthorized account.
        let current = previous.flatMap { old in records.first { $0.connection.id == old.connection.id && $0.oauth == old.oauth } }
        if previous != nil && current == nil { throw MCPAuthorizationError.cancelled }
        var connection = current?.connection ?? MCPConnection(id: UUID(), providerID: providerID, name: name,
            serverURL: serverURL, authentication: .oauth)
        connection.authentication = .oauth
        connection.needsSignIn = false
        connection.lastCheckedAt = nil
        connection.toolCount = nil
        var updated = records.filter { $0.connection.id != connection.id }
        updated.append(Record(connection: connection, oauth: credential))
        try commit(updated)
        return connection
    }

    func addPublic(providerID: String, name: String, serverURL: String) throws -> MCPConnection {
        _ = try MCPOAuthSecurity.publicHTTPS(serverURL)
        let connection = MCPConnection(id: UUID(), providerID: providerID, name: name, serverURL: serverURL, authentication: .publicServer)
        try commit(records + [Record(connection: connection)])
        return connection
    }

    func addAPIKey(name: String, serverURL: String, header: String, token: String) throws -> MCPConnection {
        _ = try MCPOAuthSecurity.publicHTTPS(serverURL)
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MCPDiscoveryError.missingCredentials }
        let headers = [header: token]
        _ = try MCPDiscoveryConfiguration.authorization(headers: headers, keepInHeaders: false)
        let connection = MCPConnection(id: UUID(), providerID: "custom", name: name, serverURL: serverURL, authentication: .apiKey)
        try commit(records + [Record(connection: connection, headers: headers)])
        return connection
    }

    func updatePolicy(id: UUID, approval: String, allowedTools: [String]) throws {
        guard let index = records.firstIndex(where: { $0.connection.id == id }) else { return }
        var updated = records
        updated[index].connection.requireApproval = approval == "never" ? "never" : "always"
        updated[index].connection.allowedTools = Array(Set(allowedTools.filter { !$0.isEmpty })).sorted()
        try commit(updated)
    }

    func rename(id: UUID, name: String) throws {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 80, !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw MCPDiscoveryError.invalidConfiguration("Use an account name of 1–80 characters.")
        }
        guard let index = records.firstIndex(where: { $0.connection.id == id }) else { return }
        var updated = records; updated[index].connection.name = value
        try commit(updated)
    }

    func recordDiscovery(id: UUID, snapshot: MCPDiscoverySnapshot) throws {
        guard let index = records.firstIndex(where: { $0.connection.id == id }) else { return }
        var updated = records
        updated[index].connection.lastCheckedAt = snapshot.checkedAt
        updated[index].connection.toolCount = snapshot.tools.count
        try commit(updated)
    }

    func disconnect(id: UUID) throws {
        try commit(records.filter { $0.connection.id != id })
        refreshes.removeValue(forKey: id)?.cancel()
    }

    /// Keeps older configurations usable while moving the current prompt to the account library.
    func importLegacy(prompt: Prompt) throws -> UUID? {
        guard prompt.currentOptions.mcpConnectionIDs == nil else { return nil }
        let hasRemote = !prompt.mcpServerURL.isEmpty && !prompt.mcpIsConnector
        guard hasRemote || prompt.mcpConnectorId?.isEmpty == false else { return nil }
        let providerID = "legacy_" + prompt.id.uuidString
        if let existing = connections.first(where: { $0.providerID == providerID }) { return existing.id }
        let headers: [String: String]
        if prompt.mcpIsConnector, let connector = prompt.mcpConnectorId {
            guard let token = KeychainService.shared.load(forKey: "mcp_connector_\(connector)"), !token.isEmpty else { return nil }
            headers = ["Authorization": token]
        } else { headers = MCPDiscoveryConfiguration.savedHeaders(for: prompt) }
        let name = prompt.mcpIsConnector ? MCPConnector.connector(for: prompt.mcpConnectorId ?? "")?.name ?? prompt.mcpServerLabel : prompt.mcpServerLabel
        var connection = MCPConnection(id: UUID(), providerID: providerID, name: name.isEmpty ? "Saved server" : name,
            serverURL: prompt.mcpServerURL, connectorID: prompt.mcpIsConnector ? prompt.mcpConnectorId : nil,
            authentication: headers.isEmpty ? .publicServer : .apiKey)
        connection.requireApproval = prompt.mcpRequireApproval == "never" ? "never" : "always"
        connection.allowedTools = prompt.mcpAllowedTools.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        try commit(records + [Record(connection: connection, headers: headers.isEmpty ? nil : headers)])
        return connection.id
    }

    func prepare(id: UUID) async throws {
        if let task = refreshes[id] { try await task.value; try Task.checkCancellation(); return }
        guard let record = records.first(where: { $0.connection.id == id }) else { throw MCPAuthorizationError.expired }
        guard !record.connection.needsSignIn else { throw MCPAuthorizationError.expired }
        guard let credential = record.oauth, credential.needsRefresh() else { return }
        let task = Task { @MainActor in
            do {
                let refreshed = try await oauthClient.refresh(credential)
                try Task.checkCancellation()
                guard let index = records.firstIndex(where: { $0.connection.id == id && $0.oauth == credential }) else { throw MCPAuthorizationError.cancelled }
                var updated = records
                updated[index].oauth = refreshed
                try commit(updated)
            } catch {
                if error as? MCPAuthorizationError == .expired, let index = records.firstIndex(where: { $0.connection.id == id && $0.oauth == credential }) {
                    var updated = records
                    updated[index].connection.needsSignIn = true
                    try commit(updated)
                }
                throw error
            }
        }
        refreshes[id] = task
        defer { refreshes[id] = nil }
        try await task.value
        try Task.checkCancellation()
    }

    func prepare(prompt: Prompt) async throws {
        guard prompt.enableMCPTool else { return }
        for id in prompt.currentOptions.mcpConnectionIDs ?? [] { try await prepare(id: id) }
    }

    func displayName(for label: String) -> String {
        connections.first { $0.serverLabel == label }?.name ?? label
    }

    /// Native chat opts in at its transport boundary. Raw Workbench requests remain literal.
    /// Match both the opaque account label and endpoint before attaching fresh credentials.
    func refreshCredentials(in body: [String: Any]) async throws -> [String: Any] {
        guard var tools = body["tools"] as? [[String: Any]] else { return body }
        for index in tools.indices {
            guard tools[index]["type"] as? String == "mcp", let label = tools[index]["server_label"] as? String,
                  label.range(of: "^mcp_[a-f0-9]{32}$", options: .regularExpression) != nil else { continue }
            guard let connection = connections.first(where: { $0.serverLabel == label }) else { throw MCPAuthorizationError.expired }
            guard tools[index]["server_url"] as? String == (connection.connectorID == nil ? connection.serverURL : nil),
                  tools[index]["connector_id"] as? String == connection.connectorID else { throw MCPAuthorizationError.unsafeURL }
            try await prepare(id: connection.id)
            let current = try configuration(id: connection.id).tool
            for key in ["authorization", "headers"] { tools[index][key] = current[key] }
        }
        var result = body; result["tools"] = tools
        return result
    }

    func configuration(id: UUID, includeAllTools: Bool = false) throws -> MCPDiscoveryConfiguration {
        guard let record = records.first(where: { $0.connection.id == id }), !record.connection.needsSignIn else { throw MCPAuthorizationError.expired }
        if record.oauth?.expiresAt.map({ $0 <= Date() }) == true { throw MCPAuthorizationError.expired }
        var prompt = Prompt.defaultPrompt()
        prompt.mcpServerLabel = record.connection.serverLabel
        prompt.mcpServerURL = record.connection.serverURL
        prompt.mcpIsConnector = record.connection.connectorID != nil
        prompt.mcpConnectorId = record.connection.connectorID
        prompt.mcpAllowedTools = includeAllTools ? "" : record.connection.allowedTools.joined(separator: ",")
        let headers = record.oauth.map { ["Authorization": "Bearer " + $0.accessToken] } ?? record.headers ?? [:]
        return try MCPDiscoveryConfiguration(prompt: prompt, headersOverride: headers, connectorTokenOverride: headers["Authorization"])
    }

    func tools(prompt: Prompt) throws -> [APICapabilities.Tool] {
        guard prompt.enableMCPTool else { return [] }
        return try (prompt.currentOptions.mcpConnectionIDs ?? []).map { id in
            let config = try configuration(id: id).tool
            guard let connection = connections.first(where: { $0.id == id }) else { throw MCPAuthorizationError.expired }
            return .mcp(serverLabel: connection.serverLabel, serverURL: config["server_url"] as? String,
                connectorId: config["connector_id"] as? String, authorization: config["authorization"] as? String,
                headers: config["headers"] as? [String: String], requireApproval: connection.requireApproval,
                allowedTools: connection.allowedTools.isEmpty ? nil : connection.allowedTools,
                serverDescription: connection.name)
        }
    }
}

@MainActor
private enum MCPConnectionVault {
    static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "OpenResponses", kSecAttrAccount as String: "mcpConnections.v1"]
    }
    static func read() throws -> Data? {
        var query = query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = value as? Data else { throw MCPAuthorizationError.secureStorage }
        return data
    }
    static func write(_ data: Data) throws {
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            guard SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil) == errSecSuccess else { throw MCPAuthorizationError.secureStorage }
        } else if status != errSecSuccess { throw MCPAuthorizationError.secureStorage }
    }
}
