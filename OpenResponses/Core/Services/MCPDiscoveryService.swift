import CryptoKit
import Foundation

nonisolated struct MCPDiscoveredTool: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let description: String
    let schemaJSON: String
    let annotationsJSON: String?
}

nonisolated struct MCPDiscoverySnapshot: Equatable, Sendable {
    let label: String
    let tools: [MCPDiscoveredTool]
    let checkedAt: Date
    let filtered: Bool
}

/// Deliberately does not retain arbitrary server error text, URLs or credentials.
nonisolated enum MCPDiscoveryError: LocalizedError, Equatable {
    case invalidConfiguration(String), missingCredentials, authentication, permissionDenied
    case rateLimited, unavailable, timedOut, malformedCatalog, noCatalog, unexpectedToolCall
    case apiAuthentication, apiRejected

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason): return reason
        case .missingCredentials: return "This connection needs account sign-in. Open Settings → MCP → Connections."
        case .authentication: return "The MCP server rejected its credentials (401). Sign in again from Connections."
        case .permissionDenied: return "The MCP server denied access (403). Check the account's permissions and token scopes."
        case .rateLimited: return "Discovery was rate limited (429). Wait briefly before refreshing."
        case .unavailable: return "The MCP server or OpenAI is temporarily unavailable. Check your connection and retry."
        case .timedOut: return "Discovery timed out. Check that the MCP URL is reachable from OpenAI, then retry."
        case .malformedCatalog: return "The server returned an invalid or oversized tool catalog. Check the MCP server configuration."
        case .noCatalog: return "The request ended without a complete tool catalog. Verify the MCP endpoint and retry."
        case .unexpectedToolCall: return "Discovery unexpectedly requested a tool call. The check was stopped without approving it."
        case .apiAuthentication: return "OpenAI rejected the API key (401). Update it in Settings."
        case .apiRejected: return "OpenAI rejected the discovery request. Check the server configuration and API account access."
        }
    }

    static func server(_ value: Any?) -> MCPDiscoveryError {
        // Inspect only for classification; never display remote text that may echo a secret.
        let text = String(describing: value ?? "").lowercased()
        if text.contains("401") || text.contains("unauthorized") { return .authentication }
        if text.contains("403") || text.contains("forbidden") { return .permissionDenied }
        if text.contains("429") || text.contains("rate_limit") { return .rateLimited }
        if text.contains("timeout") || text.contains("timed out") { return .timedOut }
        if text.contains("502") || text.contains("503") || text.contains("504") { return .unavailable }
        return .noCatalog
    }
}

struct MCPDiscoveryConfiguration {
    let tool: [String: Any]
    var label: String { tool["server_label"] as? String ?? "MCP" }

    /// Reads credentials without Prompt's legacy migration getter. Drafts never touch Keychain.
    static func savedHeaders(for prompt: Prompt) -> [String: String] {
        for key in ["mcp_manual_\(prompt.id.uuidString)", "mcp_manual_\(prompt.mcpServerLabel)"] {
            guard let value = KeychainService.shared.load(forKey: key), !value.isEmpty else { continue }
            if let headers = try? JSONSerialization.jsonObject(with: Data(value.utf8)) as? [String: String] { return headers }
            return [prompt.mcpAuthHeaderKey.isEmpty ? "Authorization" : prompt.mcpAuthHeaderKey: value]
        }
        if let headers = try? JSONSerialization.jsonObject(with: Data(prompt.mcpHeaders.utf8)) as? [String: String] { return headers }
        return prompt.mcpHeaders.isEmpty ? [:] : ["Authorization": prompt.mcpHeaders]
    }

    static func validURL(_ text: String) -> Bool {
        guard let url = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.fragment == nil else { return false }
        return true
    }

    static func isNotionHosted(_ text: String) -> Bool {
        URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines))?.host?.lowercased() == "mcp.notion.com"
    }

    static func authorization(headers: [String: String], keepInHeaders: Bool) throws -> (String?, [String: String]?) {
        var sanitized: [String: String] = [:]
        var authorization: String?
        let headerCharacters = CharacterSet(charactersIn: "!#$%&'*+-.^_`|~0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let name = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.unicodeScalars.allSatisfy(headerCharacters.contains),
                  !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
                throw MCPDiscoveryError.invalidConfiguration("Use a valid HTTP header name and a single-line token.")
            }
            // Transport/session headers belong to OpenAI's MCP client and the remote server.
            if ["mcp-session-id", "mcp-protocol-version", "host", "content-length", "connection", "accept", "content-type"].contains(name) { continue }
            guard !value.isEmpty else { continue }
            guard sanitized[name] == nil, !(name == "authorization" && authorization != nil) else {
                throw MCPDiscoveryError.invalidConfiguration("Remove duplicate authorization or custom headers.")
            }
            if name == "authorization" {
                let raw = value.lowercased().hasPrefix("bearer ") ? String(value.dropFirst(7)).trimmingCharacters(in: .whitespaces) : value
                if keepInHeaders { sanitized[name] = "Bearer " + raw } else { authorization = raw }
            } else {
                sanitized[name] = value // API-key headers must not receive an invented Bearer prefix.
            }
        }
        return (authorization, sanitized.isEmpty ? nil : sanitized)
    }

    init(prompt: Prompt, headersOverride: [String: String]? = nil, connectorTokenOverride: String? = nil) throws {
        var tool: [String: Any] = ["type": "mcp", "require_approval": "always"]
        let label = prompt.mcpServerLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty, label.count <= 64, label.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw MCPDiscoveryError.invalidConfiguration("Enter a server label of 1–64 characters.")
        }
        tool["server_label"] = label
        if prompt.mcpIsConnector {
            guard let id = prompt.mcpConnectorId, MCPConnector.connector(for: id) != nil else {
                throw MCPDiscoveryError.invalidConfiguration("Choose a supported connector.")
            }
            let token = (connectorTokenOverride ?? KeychainService.shared.load(forKey: "mcp_connector_\(id)") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { throw MCPDiscoveryError.missingCredentials }
            let auth = try Self.authorization(headers: ["Authorization": token], keepInHeaders: false)
            tool["connector_id"] = id
            tool["authorization"] = auth.0
        } else {
            let url = prompt.mcpServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
            guard Self.validURL(url) else { throw MCPDiscoveryError.invalidConfiguration("Enter a valid HTTPS MCP URL without embedded credentials or a fragment.") }
            let headers = headersOverride ?? Self.savedHeaders(for: prompt)
            let auth = try Self.authorization(headers: headers, keepInHeaders: prompt.mcpKeepAuthInHeaders)
            if Self.isNotionHosted(url) {
                let token = auth.0 ?? headers.first(where: { $0.key.lowercased() == "authorization" })?.value ?? ""
                let raw = token.lowercased().replacingOccurrences(of: "bearer ", with: "")
                guard !raw.isEmpty, !raw.hasPrefix("ntn_"), !raw.hasPrefix("secret_") else {
                    throw MCPDiscoveryError.invalidConfiguration("Notion hosted MCP needs an OAuth access token, not a Notion integration token.")
                }
            }
            tool["server_url"] = url
            tool["authorization"] = auth.0
            tool["headers"] = auth.1
        }
        let allowed = Array(Set(prompt.mcpAllowedTools.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted()
        if !allowed.isEmpty { tool["allowed_tools"] = allowed }
        self.tool = tool
    }

    var body: [String: Any] {
        // Independent of chat history, instructions, tools, background mode and experimental options.
        ["model": "gpt-5.6-luna", "input": "Discover the configured MCP tools. Do not call tools.",
         "tools": [tool], "tool_choice": "none", "store": false, "stream": true, "max_output_tokens": 32]
    }

    func cacheKey(apiKey: String) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return SHA256.hash(data: data + Data(apiKey.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Accept only complete catalogs, never an in-progress empty placeholder.
struct MCPDiscoveryParser {
    let label: String
    let filtered: Bool

    func consume(_ event: [String: Any]) throws -> MCPDiscoverySnapshot? {
        let type = event["type"] as? String ?? ""
        if type == "error" || type == "response.failed" || type == "response.mcp_list_tools.failed" {
            throw MCPDiscoveryError.server(event["error"] ?? (event["response"] as? [String: Any])?["error"])
        }
        if let item = event["item"] as? [String: Any], ["mcp_call", "mcp_approval_request"].contains(item["type"] as? String ?? "") {
            throw MCPDiscoveryError.unexpectedToolCall
        }
        if ["response.output_item.done", "response.output_item.completed"].contains(type), let item = event["item"] as? [String: Any] {
            return try catalog(item)
        }
        if ["response.completed", "response.done", "response.incomplete"].contains(type) {
            for item in (event["response"] as? [String: Any])?["output"] as? [[String: Any]] ?? [] {
                if let result = try catalog(item) { return result }
            }
            throw MCPDiscoveryError.noCatalog
        }
        return nil
    }

    private func catalog(_ item: [String: Any]) throws -> MCPDiscoverySnapshot? {
        guard item["type"] as? String == "mcp_list_tools", item["server_label"] as? String == label else { return nil }
        if let error = item["error"], !(error is NSNull) { throw MCPDiscoveryError.server(error) }
        if item["status"] as? String == "failed" { throw MCPDiscoveryError.noCatalog }
        guard let rawTools = item["tools"] as? [[String: Any]], rawTools.count <= 2_000 else { throw MCPDiscoveryError.malformedCatalog }
        var names = Set<String>()
        let tools = try rawTools.map { raw -> MCPDiscoveredTool in
            guard let name = raw["name"] as? String, !name.isEmpty, name.count <= 256,
                  names.insert(name).inserted, let schema = raw["input_schema"] as? [String: Any],
                  JSONSerialization.isValidJSONObject(schema) else { throw MCPDiscoveryError.malformedCatalog }
            return MCPDiscoveredTool(name: name, description: raw["description"] as? String ?? "",
                                     schemaJSON: ResponsesAPIClient.pretty(schema),
                                     annotationsJSON: (raw["annotations"] as? [String: Any]).map(ResponsesAPIClient.pretty))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return MCPDiscoverySnapshot(label: label, tools: tools, checkedAt: Date(), filtered: filtered)
    }
}

/// Coalesces identical checks. A cancelling screen releases only its own waiter.
/// Last-waiter cancellation and the wall-clock deadline both cancel the HTTP task.
@MainActor
final class MCPDiscoveryService {
    static let shared = MCPDiscoveryService()
    typealias Transport = @MainActor (URLRequest) -> MCPDiscoveryStream
    private struct Flight {
        let id: UUID
        let task: Task<Void, Never>
        var waiters: [UUID: CheckedContinuation<MCPDiscoverySnapshot, Error>]
    }
    private var flights: [String: Flight] = [:]
    private var cache: [String: MCPDiscoverySnapshot] = [:]
    private let transport: Transport
    private let timeout: TimeInterval
    private let cacheLifetime: TimeInterval
    private let keyProvider: () -> String?

    init(timeout: TimeInterval = 35, cacheLifetime: TimeInterval = 300,
         keyProvider: @escaping () -> String? = { KeychainService.shared.load(forKey: "openAIKey") },
         transport: @escaping Transport = MCPDiscoveryStream.open) {
        self.timeout = timeout
        self.cacheLifetime = cacheLifetime
        self.keyProvider = keyProvider
        self.transport = transport
    }

    func discover(_ configuration: MCPDiscoveryConfiguration, forceRefresh: Bool = false) async throws -> MCPDiscoverySnapshot {
        try Task.checkCancellation()
        guard let apiKey = keyProvider(), !apiKey.isEmpty else { throw OpenAIServiceError.missingAPIKey }
        let key = try configuration.cacheKey(apiKey: apiKey)
        if !forceRefresh, let existing = cache[key], Date().timeIntervalSince(existing.checkedAt) < cacheLifetime { return existing }
        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled { continuation.resume(throwing: CancellationError()); return }
                if flights[key] != nil { flights[key]?.waiters[waiterID] = continuation; return }
                cache.removeValue(forKey: key) // A failed refresh must not leave a green cached result.
                let flightID = UUID()
                let task = Task { [weak self] in
                    guard let self else { return }
                    let result: Result<MCPDiscoverySnapshot, Error>
                    do { result = .success(try await self.perform(configuration, apiKey: apiKey)) }
                    catch { result = .failure(error) }
                    self.finish(key: key, id: flightID, result: result)
                }
                flights[key] = Flight(id: flightID, task: task, waiters: [waiterID: continuation])
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel(key: key, waiterID: waiterID) }
        }
    }

    func invalidate() {
        cache.removeAll()
        let pending = flights.values
        flights.removeAll()
        for flight in pending {
            flight.task.cancel()
            for waiter in flight.waiters.values { waiter.resume(throwing: CancellationError()) }
        }
    }

    private func cancel(key: String, waiterID: UUID) {
        guard let waiter = flights[key]?.waiters.removeValue(forKey: waiterID) else { return }
        waiter.resume(throwing: CancellationError())
        if flights[key]?.waiters.isEmpty == true { flights.removeValue(forKey: key)?.task.cancel() }
    }

    private func finish(key: String, id: UUID, result: Result<MCPDiscoverySnapshot, Error>) {
        guard let flight = flights[key], flight.id == id else { return }
        flights.removeValue(forKey: key)
        if case .success(let snapshot) = result {
            cache = cache.filter { Date().timeIntervalSince($0.value.checkedAt) < cacheLifetime }
            if cache.count >= 16, let oldest = cache.min(by: { $0.value.checkedAt < $1.value.checkedAt })?.key { cache.removeValue(forKey: oldest) }
            cache[key] = snapshot
        }
        for waiter in flight.waiters.values { waiter.resume(with: result) }
    }

    private func perform(_ configuration: MCPDiscoveryConfiguration, apiKey: String) async throws -> MCPDiscoverySnapshot {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: configuration.body)
        let parser = MCPDiscoveryParser(label: configuration.label, filtered: configuration.tool["allowed_tools"] != nil)
        let transport = self.transport
        let timeout = self.timeout
        return try await withThrowingTaskGroup(of: MCPDiscoverySnapshot.self) { group in
            group.addTask { @MainActor in
                for attempt in 0..<2 {
                    try Task.checkCancellation()
                    let connection = transport(request)
                    do {
                        defer { connection.cancel() }
                        for try await event in connection.events {
                            try Task.checkCancellation()
                            if let snapshot = try parser.consume(event) { return snapshot }
                        }
                        try Task.checkCancellation()
                        throw MCPDiscoveryError.noCatalog
                    } catch {
                        if Task.isCancelled { throw CancellationError() }
                        let classified: Error
                        if let urlError = error as? URLError {
                            classified = urlError.code == .timedOut ? MCPDiscoveryError.timedOut : MCPDiscoveryError.unavailable
                        } else { classified = error }
                        guard attempt == 0, classified as? MCPDiscoveryError == .unavailable else { throw classified }
                        try await Task.sleep(nanoseconds: 600_000_000)
                    }
                }
                throw MCPDiscoveryError.unavailable
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw MCPDiscoveryError.timedOut
            }
            defer { group.cancelAll() }
            guard let snapshot = try await group.next() else { throw MCPDiscoveryError.noCatalog }
            return snapshot
        }
    }
}
