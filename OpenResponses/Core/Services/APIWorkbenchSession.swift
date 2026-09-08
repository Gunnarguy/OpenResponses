import Foundation
import Combine

/// A developer workbench retains raw events, including new item types the chat renderer doesn't yet know.
@MainActor
final class APIWorkbenchSession: ObservableObject {
    @Published var transcript = ""
    @Published var status = "Ready"
    @Published var isRunning = false
    @Published var responseID: String?
    @Published var pendingCalls: [[String: Any]] = []
    @Published var result: [String: Any] = [:]
    @Published private(set) var canInjectToolResults = false
    @Published private(set) var injectionPending = false
    private(set) var lastRequestBody: [String: Any] = [:]
    private var injectedCallIDs = Set<String>()
    private var injectingCallIDs = Set<String>()
    private var terminalReceived = false
    var hasOpenSocket: Bool { socket != nil }
    private var operation: Task<Void, Never>?
    private var socket: URLSessionWebSocketTask?
    private var socketTask: Task<Void, Never>?
    private var socketBeta = false
    private var steeredResponseID: String?
    private var runID = UUID()
    private let client = ResponsesAPIClient()

    enum Transport: String, CaseIterable { case http = "HTTP", sse = "SSE", webSocket = "WebSocket" }

    func run(body: [String: Any], path: String = "/responses", method: String = "POST", transport: Transport = .http) {
        guard !isRunning else { return }
        do { try ResponseConfigurationValidation.validate(body: body) }
        catch { status = error.localizedDescription; return }
        operation?.cancel()
        let generation = UUID()
        runID = generation
        isRunning = true
        status = "Connecting"
        transcript = ""
        pendingCalls = []
        responseID = nil
        result = [:]
        lastRequestBody = body
        canInjectToolResults = transport == .webSocket && body["multi_agent"] != nil
        injectionPending = false
        injectedCallIDs = []
        injectingCallIDs = []
        terminalReceived = false
        steeredResponseID = nil
        operation = Task {
            do {
                if method == "GET", path.contains("/items?") || path.contains("/input_items?") {
                    let items = try await client.allItems(path: String(path.split(separator: "?")[0]))
                    guard runID == generation else { return }
                    result = ["data": items, "has_more": false]
                    transcript = ResponsesAPIClient.pretty(result)
                    status = "Retrieved \(items.count) items across all pages"
                    isRunning = false
                    return
                }
                var payload = body
                let beta = payload["multi_agent"] != nil
                if transport == .webSocket, path == "/responses" {
                    payload.removeValue(forKey: "stream")
                    payload.removeValue(forKey: "stream_options")
                    payload.removeValue(forKey: "background")
                    payload["type"] = "response.create"
                    if socket == nil || socketBeta != beta {
                        disconnectSocket()
                        var request = try client.request(path: "/responses", method: "GET")
                        request.url = URL(string: "wss://api.openai.com/v1/responses")!
                        if beta { request.setValue("responses_multi_agent=v1", forHTTPHeaderField: "OpenAI-Beta") }
                        let connection = URLSession.shared.webSocketTask(with: request)
                        connection.maximumMessageSize = 32 * 1024 * 1024
                        socket = connection
                        socketBeta = beta
                        connection.resume()
                        socketTask = Task { [weak self] in
                            do {
                                while !Task.isCancelled {
                                    let message = try await connection.receive()
                                    let data: Data
                                    switch message {
                                    case .string(let text): data = Data(text.utf8)
                                    case .data(let bytes): data = bytes
                                    @unknown default: continue
                                    }
                                    guard let self, self.socket === connection else { return }
                                    if let event = try JSONSerialization.jsonObject(with: data) as? [String: Any] { self.receive(event) }
                                }
                            } catch {
                                guard let self, self.socket === connection, !Task.isCancelled else { return }
                                self.status = "Connection closed: \(error.localizedDescription)"
                                self.isRunning = false
                                self.disconnectSocket()
                            }
                        }
                    }
                    try await sendSocket(payload)
                    status = "Streaming"
                    return
                }
                disconnectSocket()
                if path == "/responses" { payload["stream"] = transport == .sse }
                var request = try client.request(path: path, method: method, body: method == "GET" || method == "DELETE" ? nil : payload)
                if beta { request.setValue("responses_multi_agent=v1", forHTTPHeaderField: "OpenAI-Beta") }
                if transport == .sse, path == "/responses" {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        var data = Data()
                        for try await byte in bytes { data.append(byte); if data.count >= 64_000 { break } }
                        try ResponsesAPIClient.validate(response, data: data)
                    }
                    for try await line in bytes.lines {
                        try Task.checkCancellation()
                        guard self.runID == generation else { return }
                        guard line.hasPrefix("data:") else { continue }
                        let text = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if text == "[DONE]" { break }
                        if let event = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] { receive(event) }
                    }
                    if isRunning { throw OpenAIServiceError.invalidRequest("The stream ended before a terminal response event.") }
                } else {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    try ResponsesAPIClient.validate(response, data: data)
                    guard runID == generation else { return }
                    result = (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
                    transcript = ResponsesAPIClient.pretty(result)
                    responseID = result["id"] as? String
                    pendingCalls = Self.toolCalls(in: result)
                    status = result["status"] as? String ?? "Completed"
                    isRunning = false
                }
            } catch {
                guard runID == generation else { return }
                status = Task.isCancelled ? "Stopped" : error.localizedDescription
                isRunning = false
            }
        }
    }

    func receive(_ event: [String: Any]) {
        let type = event["type"] as? String ?? "unknown"
        let response = event["response"] as? [String: Any]
        if type == "response.created" { responseID = response?["id"] as? String; isRunning = true; terminalReceived = false }
        if type == "response.output_item.done", let item = event["item"] as? [String: Any],
           !Self.toolCalls(in: ["output": [item]]).isEmpty {
            let id = item["call_id"] as? String ?? item["id"] as? String ?? ""
            if !injectedCallIDs.contains(id), !pendingCalls.contains(where: { ($0["call_id"] as? String ?? $0["id"] as? String) == id }) {
                pendingCalls.append(item)
            }
        }
        if let delta = event["delta"] as? String, type == "response.output_text.delta" { append(delta) }
        else { append("\n\(ResponsesAPIClient.pretty(event))\n") }
        if ["response.inject.created", "response.inject.failed"].contains(type) {
            if type == "response.inject.created" {
                injectedCallIDs.formUnion(injectingCallIDs)
                pendingCalls.removeAll { injectingCallIDs.contains($0["call_id"] as? String ?? "") }
                status = terminalReceived ? "Completed; tool results accepted" : "Tool results accepted; streaming"
            } else { status = "Tool injection failed; see event details and retry through a continuation if the response ended" }
            injectionPending = false
            injectingCallIDs = []
            if terminalReceived { isRunning = false }
            return
        }
        if type == "response.steer.accepted" { status = "Steering accepted; waiting for continuation"; return }
        if type == "response.steer.failed" {
            // The original response may already have ended while the steering request was in flight.
            if let steeredResponseID, result["id"] as? String == steeredResponseID { isRunning = false }
            steeredResponseID = nil
            status = "Steering failed; see event details"
            return
        }
        if ["response.completed", "response.incomplete", "response.failed"].contains(type) {
            terminalReceived = true
            result = response ?? [:]
            pendingCalls = Self.toolCalls(in: result).filter { !injectedCallIDs.contains($0["call_id"] as? String ?? "") }
            if result["id"] as? String == steeredResponseID, pendingCalls.isEmpty, type != "response.failed" {
                status = "Waiting for steering continuation"
            } else {
                status = result["status"] as? String ?? type
                isRunning = injectionPending
                steeredResponseID = nil
            }
        } else if type == "error" { status = "API error; see event details"; isRunning = false }
    }

    static func toolCalls(in response: [String: Any]) -> [[String: Any]] {
        (response["output"] as? [[String: Any]] ?? []).filter {
            ["function_call", "custom_tool_call", "apply_patch_call", "mcp_approval_request"].contains($0["type"] as? String ?? "")
        }
    }

    func injectToolResults(_ outputs: [[String: Any]]) {
        guard canInjectToolResults, isRunning, !terminalReceived, !injectionPending, let responseID, !outputs.isEmpty else { return }
        let ids = Set(outputs.compactMap { $0["call_id"] as? String })
        let pendingIDs = Set(pendingCalls.compactMap { $0["call_id"] as? String })
        guard ids.count == outputs.count, ids.isSubset(of: pendingIDs) else { status = "Match each output to a pending API call_id."; return }
        injectingCallIDs = ids
        injectionPending = true
        Task {
            do { try await sendSocket(["type": "response.inject", "response_id": responseID, "input": outputs]) }
            catch {
                injectionPending = false; injectingCallIDs = []
                if terminalReceived { isRunning = false }
                status = error.localizedDescription
            }
        }
    }

    func steer(_ text: String) {
        guard isRunning, let responseID, socket != nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        steeredResponseID = responseID
        Task {
            do { try await sendSocket(["type": "response.steer", "previous_response_id": responseID, "input": text]) }
            catch {
                if result["id"] as? String == responseID { isRunning = false }
                steeredResponseID = nil
                status = error.localizedDescription
            }
        }
    }

    private func sendSocket(_ object: [String: Any]) async throws {
        guard let socket else { throw OpenAIServiceError.invalidRequest("Connect a WebSocket first.") }
        let data = try JSONSerialization.data(withJSONObject: object)
        try await socket.send(.string(String(decoding: data, as: UTF8.self)))
    }

    private func append(_ text: String) {
        transcript += text
        if transcript.count > 250_000 {
            transcript = "[Earlier events omitted from this preview. Final response remains available below.]\n" + transcript.suffix(200_000)
        }
    }

    private func disconnectSocket() {
        socketTask?.cancel(); socketTask = nil
        socket?.cancel(with: .normalClosure, reason: nil); socket = nil
    }

    func stop() {
        runID = UUID()
        operation?.cancel(); operation = nil
        disconnectSocket()
        canInjectToolResults = false
        injectionPending = false
        isRunning = false
        status = "Connection stopped"
    }
}
