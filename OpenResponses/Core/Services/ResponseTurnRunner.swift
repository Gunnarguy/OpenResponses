import Foundation

/// Coordinates client tools around actual response boundaries. No timers, partial batches, or automatic retries.
@MainActor
final class ResponseTurnRunner {
    typealias JSON = [String: Any]
    typealias Stream = (JSON) -> AsyncThrowingStream<JSON, Error>
    typealias Execute = (JSON) async throws -> String

    struct Result {
        let response: JSON
        let replayInput: [JSON]
        let rounds: Int
    }

    // Only read operations can overlap generation or be invoked from a hosted program.
    // Mutations continue through the existing direct execution/approval path, one at a time.
    nonisolated static let concurrentFunctions: Set<String> = [
        "searchNotion", "getNotionDatabase", "getNotionDataSource",
        "fetchAppleCalendarEvents", "fetchAppleReminders", "searchAppleContacts", "getAppleContact"
    ]

    static func agentName(_ item: JSON) -> String {
        (item["agent"] as? JSON)?["agent_name"] as? String ?? "/root"
    }

    static func inputItems(_ input: Any?) -> [JSON] {
        if let text = input as? String { return [["role": "user", "content": text]] }
        return input as? [JSON] ?? []
    }

    static func signature(_ call: JSON) -> String {
        "\(call["type"] ?? ""):\(call["name"] ?? ""):\(call["arguments"] ?? call["input"] ?? "")"
    }

    /// An interrupted tool may already have changed external state. Never manufacture success or retry it.
    static func recoveryInput(_ history: [JSON]) -> [JSON] {
        let answered = Set(history.filter { ["function_call_output", "custom_tool_call_output"].contains($0["type"] as? String ?? "") }.compactMap { $0["call_id"] as? String })
        var result = history
        var seen = answered
        for call in history where ["function_call", "custom_tool_call"].contains(call["type"] as? String ?? "") {
            guard let id = call["call_id"] as? String, seen.insert(id).inserted else { continue }
            result.append(["type": call["type"] as? String == "custom_tool_call" ? "custom_tool_call_output" : "function_call_output", "call_id": id,
                           "output": "Error: Execution was interrupted and the result is unknown. Do not assume success. Check external state before retrying any operation that could change data."])
        }
        return result
    }

    /// Preserves all opaque program, reasoning, phase, and agent fields for stateless continuation.
    static func continuation(_ body: JSON, response: JSON, history: [JSON], outputs: [JSON]) -> JSON {
        var next = body
        if body["conversation"] != nil {
            next.removeValue(forKey: "previous_response_id")
            next["input"] = outputs
        } else if body["store"] as? Bool != false {
            next["previous_response_id"] = response["id"]
            next["input"] = outputs
        } else {
            next.removeValue(forKey: "previous_response_id")
            next["input"] = history + outputs
        }
        return next
    }

    func run(body: JSON, maxRounds: Int = 12, concurrentNames: Set<String> = concurrentFunctions, initialHistory: [JSON]? = nil,
             stream: Stream, socket: ResponseSocketRunner.Connection? = nil, execute: @escaping Execute, onCheckpoint: (Result) -> Void = { _ in },
             onEvent: (JSON) -> Void, onToolResult: (JSON, String) -> Void) async throws -> Result {
        if let socket {
            return try await ResponseSocketRunner().run(body: body, connection: socket, maxCalls: maxRounds,
                concurrentNames: concurrentNames, initialHistory: initialHistory, execute: execute,
                onCheckpoint: onCheckpoint, onEvent: onEvent, onToolResult: onToolResult)
        }
        var request = body
        var history = initialHistory ?? Self.inputItems(body["input"])
        var completed: [String: (signature: String, output: String)] = [:]
        var jobs: [String: Task<String, Error>] = [:]
        defer { jobs.values.forEach { $0.cancel() } }
        onCheckpoint(Result(response: [:], replayInput: history, rounds: 0))

        for round in 0..<max(1, min(maxRounds, 32)) {
            try Task.checkCancellation()
            var calls: [JSON] = []
            var callIDs = Set<String>()
            var signatures: [String: String] = [:]
            var roundItems: [JSON] = []
            var terminal: JSON?

            func register(_ item: JSON) throws {
                guard ["function_call", "custom_tool_call"].contains(item["type"] as? String ?? "") else { return }
                guard let id = item["call_id"] as? String, !id.isEmpty else {
                    throw OpenAIServiceError.invalidRequest("A function call is missing its API call_id.")
                }
                let signature = Self.signature(item)
                if let previous = signatures[id], previous != signature {
                    throw OpenAIServiceError.invalidRequest("The API reused a call_id for different arguments.")
                }
                signatures[id] = signature
                if let cached = completed[id], cached.signature != signature {
                    throw OpenAIServiceError.invalidRequest("The API reused a call_id for different arguments.")
                }
                guard callIDs.insert(id).inserted else { return }
                guard calls.count < 64 else { throw OpenAIServiceError.invalidRequest("The response exceeded the client limit of 64 tool calls.") }
                calls.append(item)
                if completed[id] == nil, jobs.count < 4,
                   concurrentNames.contains(item["name"] as? String ?? "") {
                    jobs[id] = Task { try Task.checkCancellation(); return try await execute(item) }
                }
            }

            for try await event in stream(request) {
                try Task.checkCancellation()
                let type = event["type"] as? String ?? ""
                if type == "error" {
                    let error = event["error"] as? JSON ?? event
                    throw OpenAIServiceError.invalidRequest(error["message"] as? String ?? "The API stream failed.")
                }
                if type == "response.output_item.done", let item = event["item"] as? JSON {
                    if !roundItems.contains(where: { $0["id"] as? String != nil && $0["id"] as? String == item["id"] as? String }) { roundItems.append(item) }
                    onCheckpoint(Result(response: [:], replayInput: history + roundItems, rounds: round + 1))
                    try register(item)
                }
                if ["response.completed", "response.incomplete", "response.failed"].contains(type) {
                    guard let response = event["response"] as? JSON else { throw OpenAIServiceError.invalidResponseData }
                    terminal = response
                    if type == "response.completed" {
                        for item in response["output"] as? [JSON] ?? [] { try register(item) }
                    }
                }
                onEvent(event)
            }
            try Task.checkCancellation()
            guard let response = terminal else { throw OpenAIServiceError.invalidRequest("The stream ended before a terminal response.") }
            let output = response["output"] as? [JSON] ?? []
            history += output
            onCheckpoint(Result(response: response, replayInput: history, rounds: round + 1))
            guard response["status"] as? String == "completed" else {
                let detail = response["error"] as? JSON ?? response["incomplete_details"] as? JSON ?? [:]
                throw OpenAIServiceError.invalidRequest(detail["message"] as? String ?? detail["reason"] as? String ?? "The response did not complete.")
            }
            if calls.isEmpty { return Result(response: response, replayInput: history, rounds: round + 1) }

            var outputs: [JSON] = []
            for call in calls {
                try Task.checkCancellation()
                let id = call["call_id"] as! String // validated at registration
                let signature = Self.signature(call)
                let result: String
                if let cached = completed[id] { result = cached.output }
                else if let job = jobs[id] { result = try await job.value; jobs.removeValue(forKey: id) }
                else { result = try await execute(call) }
                try Task.checkCancellation()
                completed[id] = (signature, result)
                outputs.append(["type": call["type"] as? String == "custom_tool_call" ? "custom_tool_call_output" : "function_call_output", "call_id": id, "output": result])
                onCheckpoint(Result(response: response, replayInput: history + outputs, rounds: round + 1))
                onToolResult(call, result)
            }
            request = Self.continuation(request, response: response, history: history, outputs: outputs)
            history += outputs
            onCheckpoint(Result(response: response, replayInput: history, rounds: round + 1))
        }
        throw OpenAIServiceError.invalidRequest("Stopped after the tool-round limit. Completed work is retained; review the result before continuing.")
    }
}
