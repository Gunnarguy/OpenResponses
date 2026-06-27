import Foundation

/// Implementation of AssistantsServiceProtocol that communicates with OpenAI Assistants API (v2).
class AssistantsService: AssistantsServiceProtocol {
    static let shared = AssistantsService()
    
    private let baseURL = "https://api.openai.com/v1"
    
    private init() {}
    
    private var apiKey: String? {
        KeychainService.shared.load(forKey: "openAIKey")
    }
    
    private func createHeaders() throws -> [String: String] {
        guard let key = apiKey, !key.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        return [
            "Authorization": "Bearer \(key)",
            "Content-Type": "application/json",
            "OpenAI-Beta": "assistants=v2"
        ]
    }
    
    func listAssistants() async throws -> [Assistant] {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/assistants")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        let listResponse = try JSONDecoder().decode(AssistantListResponse<Assistant>.self, from: data)
        return listResponse.data
    }
    
    func createAssistant(
        name: String?,
        model: String,
        instructions: String?,
        tools: [AssistantTool]?
    ) async throws -> Assistant {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/assistants")!
        
        var requestBody: [String: Any] = [
            "model": model
        ]
        if let name = name { requestBody["name"] = name }
        if let instructions = instructions { requestBody["instructions"] = instructions }
        if let tools = tools {
            let encoder = JSONEncoder()
            let toolsData = try encoder.encode(tools)
            let toolsJSON = try JSONSerialization.jsonObject(with: toolsData, options: [])
            requestBody["tools"] = toolsJSON
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(Assistant.self, from: data)
    }
    
    func createThread() async throws -> AssistantThread {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/threads")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(AssistantThread.self, from: data)
    }
    
    func createMessage(
        threadId: String,
        role: String,
        content: String
    ) async throws -> AssistantMessage {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/threads/\(threadId)/messages")!
        
        let requestBody: [String: Any] = [
            "role": role,
            "content": content
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(AssistantMessage.self, from: data)
    }
    
    func createRun(
        threadId: String,
        assistantId: String
    ) -> AsyncThrowingStream<AssistantsStreamEvent, Error> {
        do {
            let headers = try createHeaders()
            let url = URL(string: "\(baseURL)/threads/\(threadId)/runs")!
            
            let requestBody: [String: Any] = [
                "assistant_id": assistantId,
                "stream": true
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = bodyData
            for (key, val) in headers {
                request.setValue(val, forHTTPHeaderField: key)
            }
            
            return streamEvents(from: request)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
    }
    
    func submitToolOutputs(
        threadId: String,
        runId: String,
        outputs: [[String: Any]]
    ) -> AsyncThrowingStream<AssistantsStreamEvent, Error> {
        do {
            let headers = try createHeaders()
            let url = URL(string: "\(baseURL)/threads/\(threadId)/runs/\(runId)/submit_tool_outputs")!
            
            let requestBody: [String: Any] = [
                "tool_outputs": outputs,
                "stream": true
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = bodyData
            for (key, val) in headers {
                request.setValue(val, forHTTPHeaderField: key)
            }
            
            return streamEvents(from: request)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
    }
    
    private func streamEvents(from request: URLRequest) -> AsyncThrowingStream<AssistantsStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenAIServiceError.invalidResponseData
                    }
                    
                    if httpResponse.statusCode != 200 {
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
                    }
                    
                    var currentEventName: String? = nil
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("event: ") {
                            currentEventName = String(line.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if line.hasPrefix("data: ") {
                            let dataString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                            if dataString == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            guard let data = dataString.data(using: .utf8) else { continue }
                            guard let eventName = currentEventName else { continue }
                            
                            do {
                                let decoder = JSONDecoder()
                                switch eventName {
                                case "thread.created":
                                    let obj = try decoder.decode(AssistantThread.self, from: data)
                                    continuation.yield(.threadCreated(obj))
                                case "thread.run.created":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunCreated(obj))
                                case "thread.run.queued":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunQueued(obj))
                                case "thread.run.in_progress":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunInProgress(obj))
                                case "thread.run.requires_action":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunRequiresAction(obj))
                                case "thread.run.completed":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunCompleted(obj))
                                case "thread.run.failed":
                                    let obj = try decoder.decode(AssistantRun.self, from: data)
                                    continuation.yield(.threadRunFailed(obj))
                                case "thread.message.created":
                                    let obj = try decoder.decode(AssistantMessage.self, from: data)
                                    continuation.yield(.threadMessageCreated(obj))
                                case "thread.message.delta":
                                    let obj = try decoder.decode(AssistantMessageDelta.self, from: data)
                                    continuation.yield(.threadMessageDelta(obj))
                                case "thread.message.completed":
                                    let obj = try decoder.decode(AssistantMessage.self, from: data)
                                    continuation.yield(.threadMessageCompleted(obj))
                                case "error":
                                    let obj = try decoder.decode(AssistantRunError.self, from: data)
                                    continuation.yield(.error(obj))
                                default:
                                    continuation.yield(.unknown(event: eventName, data: dataString))
                                }
                            } catch {
                                // Fallback for any decoding mismatch so stream doesn't break
                                continuation.yield(.unknown(event: eventName, data: dataString))
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
