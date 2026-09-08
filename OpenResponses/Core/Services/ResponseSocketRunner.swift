import Foundation

/// A single native multi-agent response, with tool outputs injected while agents are waiting.
/// Socket events and completed tools enter one queue so execution, acknowledgments and checkpoints stay ordered.
@MainActor
final class ResponseSocketRunner {
    typealias JSON = [String: Any]
    struct Connection {
        let events: AsyncThrowingStream<JSON, Error>
        let send: (JSON) async throws -> Void
        let close: () -> Void
    }
    private enum Signal {
        case event(JSON)
        case result(JSON, String)
        case failure(Error)
        case closed
    }

    func run(body: JSON, connection: Connection, maxCalls: Int,
             concurrentNames: Set<String>, initialHistory: [JSON]?,
             execute: @escaping ResponseTurnRunner.Execute,
             onCheckpoint: (ResponseTurnRunner.Result) -> Void,
             onEvent: (JSON) -> Void, onToolResult: (JSON, String) -> Void) async throws -> ResponseTurnRunner.Result {
        try ResponseConfigurationValidation.validate(body: body)
        let (signals, continuation) = AsyncStream<Signal>.makeStream()
        let reader = Task {
            do {
                for try await event in connection.events { continuation.yield(.event(event)) }
                continuation.yield(.closed)
            } catch { continuation.yield(.failure(error)) }
        }
        var jobs: [String: Task<Void, Never>] = [:]
        defer {
            reader.cancel(); jobs.values.forEach { $0.cancel() }
            connection.close(); continuation.finish()
        }
        var payload = body
        for key in ["stream", "stream_options", "background"] { payload.removeValue(forKey: key) }
        payload["type"] = "response.create"
        var history = initialHistory ?? ResponseTurnRunner.inputItems(body["input"])
        var seenItems = Set<String>()
        var signatures: [String: String] = [:]
        var queue: [JSON] = []
        var ready: [JSON] = []
        var injecting: [JSON] = []
        var responseID: String?
        var terminal: JSON?
        var runningReadIDs = Set<String>()
        var runningWriteID: String?
        let limit = max(1, min(maxCalls, 256))

        func checkpoint() {
            onCheckpoint(.init(response: terminal ?? [:], replayInput: history, rounds: 1))
        }
        func record(_ item: JSON) {
            if let id = item["id"] as? String {
                if !seenItems.insert(id).inserted {
                    if let index = history.lastIndex(where: { $0["id"] as? String == id }) { history[index] = item }
                    return
                }
            }
            history.append(item)
        }
        func register(_ call: JSON) throws {
            guard ["function_call", "custom_tool_call"].contains(call["type"] as? String ?? "") else { return }
            guard let id = call["call_id"] as? String, !id.isEmpty else { throw OpenAIServiceError.invalidRequest("A tool call is missing its API call_id.") }
            let signature = ResponseTurnRunner.signature(call)
            if let previous = signatures[id] {
                guard previous == signature else { throw OpenAIServiceError.invalidRequest("The API reused a call_id for different arguments.") }
                return
            }
            guard signatures.count < limit else { throw OpenAIServiceError.invalidRequest("Stopped at the multi-agent client-tool limit (\(limit)). Completed work is retained.") }
            signatures[id] = signature
            queue.append(call)
        }
        func startTools() {
            var waiting: [JSON] = []
            for call in queue {
                let id = call["call_id"] as! String
                let readOnly = concurrentNames.contains(call["name"] as? String ?? "")
                guard readOnly ? runningReadIDs.count < 4 : runningWriteID == nil else { waiting.append(call); continue }
                if readOnly { runningReadIDs.insert(id) } else { runningWriteID = id }
                jobs[id] = Task {
                    do {
                        try Task.checkCancellation()
                        let output = try await execute(call)
                        continuation.yield(.result(call, output))
                    } catch { continuation.yield(.failure(error)) }
                }
            }
            queue = waiting
        }
        checkpoint()
        try await connection.send(payload)
        for await signal in signals {
            try Task.checkCancellation()
            switch signal {
            case .event(let event):
                let type = event["type"] as? String ?? ""
                if type == "response.created" { responseID = (event["response"] as? JSON)?["id"] as? String }
                if type == "response.output_item.done", let item = event["item"] as? JSON {
                    record(item); checkpoint(); try register(item)
                }
                if type == "response.inject.created" {
                    guard !injecting.isEmpty else { throw OpenAIServiceError.invalidRequest("Unexpected tool injection acknowledgment.") }
                    if let acknowledged = event["input"] as? [JSON] {
                        guard Set(acknowledged.compactMap { $0["call_id"] as? String }) == Set(injecting.compactMap { $0["call_id"] as? String }) else {
                            throw OpenAIServiceError.invalidRequest("Tool injection acknowledgment did not match the submitted call IDs.")
                        }
                    }
                    injecting = []
                }
                if ["error", "response.inject.failed"].contains(type) {
                    let detail = event["error"] as? JSON ?? event
                    throw OpenAIServiceError.invalidRequest(detail["message"] as? String ?? "The tool injection failed. Completed tool work is retained; it was not retried.")
                }
                if ["response.completed", "response.incomplete", "response.failed"].contains(type) {
                    guard let response = event["response"] as? JSON else { throw OpenAIServiceError.invalidResponseData }
                    terminal = response
                    for item in response["output"] as? [JSON] ?? [] { record(item); try register(item) }
                    checkpoint()
                }
                onEvent(event)
            case .result(let call, let output):
                let id = call["call_id"] as! String
                jobs.removeValue(forKey: id); runningReadIDs.remove(id)
                if runningWriteID == id { runningWriteID = nil }
                let item: JSON = ["type": call["type"] as? String == "custom_tool_call" ? "custom_tool_call_output" : "function_call_output", "call_id": id, "output": output]
                history.append(item); ready.append(item); checkpoint()
                onToolResult(call, output)
            case .failure(let error): throw error
            case .closed: throw OpenAIServiceError.invalidRequest("The socket closed before the response and tool acknowledgments finished.")
            }
            if terminal == nil { startTools() }
            if injecting.isEmpty, !ready.isEmpty, terminal == nil {
                guard let responseID else { throw OpenAIServiceError.invalidRequest("The socket did not provide a response ID before a tool call.") }
                injecting = ready; ready = []
                try await connection.send(["type": "response.inject", "response_id": responseID, "input": injecting])
            }
            if let terminal, injecting.isEmpty {
                guard terminal["status"] as? String == "completed" else {
                    let detail = terminal["error"] as? JSON ?? terminal["incomplete_details"] as? JSON ?? [:]
                    throw OpenAIServiceError.invalidRequest(detail["message"] as? String ?? detail["reason"] as? String ?? "The multi-agent response did not complete.")
                }
                guard jobs.isEmpty, queue.isEmpty, ready.isEmpty else { throw OpenAIServiceError.invalidRequest("The response ended before all client-tool results were accepted. Completed work is retained.") }
                return .init(response: terminal, replayInput: history, rounds: 1)
            }
        }
        try Task.checkCancellation()
        throw OpenAIServiceError.invalidRequest("The multi-agent event stream ended unexpectedly.")
    }
}
