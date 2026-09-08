import Foundation

/// Lossless JSON transport for API utilities and forward-compatible playground requests.
/// Credentials stay in Keychain. Request and response content is never logged here.
final class ResponsesAPIClient {
    private let managesMCPConnections: Bool
    init(managesMCPConnections: Bool = false) { self.managesMCPConnections = managesMCPConnections }

    struct APIError: LocalizedError {
        let status: Int
        let code: String?
        let message: String
        let requestID: String?
        let retryAfter: String?

        var errorDescription: String? {
            var text = "HTTP \(status): \(message)"
            if let code { text += " [\(code)]" }
            if let retryAfter { text += " Retry after: \(retryAfter)." }
            if let requestID { text += " Request: \(requestID)" }
            return text
        }
    }

    func request(path: String, method: String = "POST", body: [String: Any]? = nil) throws -> URLRequest {
        if let body { try ResponseConfigurationValidation.validate(body: body) }
        guard path.hasPrefix("/"), !path.contains(".."), !path.contains("#"),
              let url = URL(string: "https://api.openai.com/v1" + path), url.host == "api.openai.com" else {
            throw OpenAIServiceError.invalidRequest("Invalid OpenAI endpoint.")
        }
        guard let key = KeychainService.shared.load(forKey: "openAIKey"), !key.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 300
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        return request
    }

    static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw OpenAIServiceError.invalidResponseData }
        guard (200..<300).contains(http.statusCode) else {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let error = json?["error"] as? [String: Any]
            throw APIError(status: http.statusCode, code: error?["code"] as? String,
                           message: error?["message"] as? String ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode),
                           requestID: http.value(forHTTPHeaderField: "x-request-id"), retryAfter: http.value(forHTTPHeaderField: "Retry-After"))
        }
    }

    func json(path: String, method: String = "POST", body: [String: Any]? = nil) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request(path: path, method: method, body: body))
        try Self.validate(response, data: data)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIServiceError.invalidResponseData
        }
        return object
    }

    /// A cancellation-linked raw stream used by native chat orchestration.
    func responseEvents(body: [String: Any]) -> AsyncThrowingStream<[String: Any], Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let body = self.managesMCPConnections ? try await MCPConnectionStore.shared.refreshCredentials(in: body) : body
                    var request = try self.request(path: "/responses", body: body)
                    if body["multi_agent"] != nil { request.setValue("responses_multi_agent=v1", forHTTPHeaderField: "OpenAI-Beta") }
                    if body["stream"] as? Bool == true {
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                            var data = Data()
                            for try await byte in bytes { data.append(byte); if data.count >= 64_000 { break } }
                            try Self.validate(response, data: data)
                        }
                        for try await line in bytes.lines {
                            try Task.checkCancellation()
                            guard line.hasPrefix("data:") else { continue }
                            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            if payload == "[DONE]" { break }
                            guard let event = try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any] else {
                                throw OpenAIServiceError.invalidResponseData
                            }
                            continuation.yield(event)
                        }
                    } else {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        try Self.validate(response, data: data)
                        guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw OpenAIServiceError.invalidResponseData }
                        continuation.yield(["type": "response.created", "response": ["id": result["id"] ?? ""]])
                        continuation.yield(["type": "response." + (result["status"] as? String ?? "completed"), "response": result])
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    @MainActor
    func multiAgentConnection() throws -> ResponseSocketRunner.Connection {
        var request = try request(path: "/responses", method: "GET")
        request.url = URL(string: "wss://api.openai.com/v1/responses")!
        request.setValue("responses_multi_agent=v1", forHTTPHeaderField: "OpenAI-Beta")
        let socket = URLSession.shared.webSocketTask(with: request)
        socket.maximumMessageSize = 32 * 1024 * 1024 // Image output can exceed URLSession's default frame limit.
        socket.resume()
        let events = AsyncThrowingStream<[String: Any], Error> { continuation in
            let reader = Task {
                do {
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        let data: Data
                        switch message {
                        case .data(let value): data = value
                        case .string(let value): data = Data(value.utf8)
                        @unknown default: continue
                        }
                        guard let event = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw OpenAIServiceError.invalidResponseData }
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in reader.cancel(); socket.cancel(with: .goingAway, reason: nil) }
        }
        return .init(events: events, send: { value in
            let value = self.managesMCPConnections ? try await MCPConnectionStore.shared.refreshCredentials(in: value) : value
            let data = try JSONSerialization.data(withJSONObject: value)
            try await socket.send(.string(String(decoding: data, as: UTF8.self)))
        }, close: { socket.cancel(with: .normalClosure, reason: nil) })
    }

    static func tokenCountBody(from request: [String: Any]) -> [String: Any] {
        // Only the fields accepted by Responses input_tokens; generation/transport options are excluded.
        let keys: Set<String> = ["model", "input", "instructions", "tools", "tool_choice", "parallel_tool_calls", "text", "reasoning", "previous_response_id", "conversation", "truncation"]
        var body = request.filter { keys.contains($0.key) }
        if let tools = body["tools"] as? [[String: Any]] {
            body["tools"] = tools.map { tool in
                var tool = tool
                if tool["type"] as? String == "image_generation" { tool.removeValue(forKey: "partial_images") }
                return tool
            }
        }
        return body
    }

    func countTokens(request: [String: Any]) async throws -> Int {
        let result = try await json(path: "/responses/input_tokens", body: Self.tokenCountBody(from: request))
        guard let count = result["input_tokens"] as? Int else { throw OpenAIServiceError.invalidResponseData }
        return count
    }

    /// Fetches every item, preserving ordering and opaque fields such as phase, reasoning and tool caller metadata.
    func allItems(path: String) async throws -> [[String: Any]] {
        var items: [[String: Any]] = []
        var after: String?
        var seenCursors = Set<String>()
        repeat {
            var query = "?limit=100&order=asc"
            if let after { query += "&after=" + (after.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? after) }
            let page = try await json(path: path + query, method: "GET")
            guard let data = page["data"] as? [[String: Any]] else { throw OpenAIServiceError.invalidResponseData }
            items.append(contentsOf: data)
            if page["has_more"] as? Bool != true { return items }
            guard let cursor = page["last_id"] as? String, seenCursors.insert(cursor).inserted else {
                throw OpenAIServiceError.invalidRequest("The API returned an invalid pagination cursor.")
            }
            after = cursor
        } while true
    }

    static func pretty(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
