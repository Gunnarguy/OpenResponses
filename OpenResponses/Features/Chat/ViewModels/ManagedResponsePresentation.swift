import SwiftUI

/// Keeps root answers separate from subagent work while retaining inspectable native activity cards.
@MainActor
final class ManagedResponsePresentation {
    private var agents: [Int: String] = [:]
    private var responseID: String?
    private var textItemID: String?
    private var hasTextDeltas = false
    private var imageIndexes: [String: Int] = [:]
    private var usageTotals: [String: Int] = [:]
    private var cachedTokens = 0
    private var cacheWriteTokens = 0

    static func rootOutput(_ response: [String: Any]) -> [[String: Any]] {
        (response["output"] as? [[String: Any]] ?? []).filter {
            !["message", "reasoning"].contains($0["type"] as? String ?? "") || ResponseTurnRunner.agentName($0) == "/root"
        }
    }

    func receive(_ raw: [String: Any], viewModel: ChatViewModel, messageId: UUID) {
        var event = raw
        let type = event["type"] as? String ?? ""
        if type == "response.created" {
            agents = [:]; textItemID = nil; hasTextDeltas = false
            responseID = (event["response"] as? [String: Any])?["id"] as? String
        }
        if let item = event["item"] as? [String: Any] {
            var attributedItem = item
            if attributedItem["agent"] == nil { attributedItem["agent"] = event["agent"] }
            event["item"] = attributedItem
            if let index = event["output_index"] as? Int { agents[index] = ResponseTurnRunner.agentName(attributedItem) }
            record(attributedItem, completed: type.hasSuffix(".done"), viewModel: viewModel, messageId: messageId)
        }
        let agent = (event["agent"] as? [String: Any])?["agent_name"] as? String
            ?? (event["item"] as? [String: Any]).map(ResponseTurnRunner.agentName)
            ?? agents[event["output_index"] as? Int ?? -1] ?? "/root"
        if agent != "/root" { return }

        if type == "response.image_generation_call.partial_image" {
            if let b64 = event["partial_image_b64"] as? String, let id = event["item_id"] as? String {
                renderImage(b64, id: id, viewModel: viewModel, messageId: messageId)
            }
            return
        }
        if type == "response.output_text.delta" {
            let id = event["item_id"] as? String ?? "root-text"
            if id != textItemID {
                appendSeparator(viewModel, messageId: messageId)
                textItemID = id
            }
            hasTextDeltas = true
        }
        if ["response.failed", "response.incomplete", "error"].contains(type) { return } // runner reports terminal errors once
        if type == "response.completed", var response = event["response"] as? [String: Any] {
            for item in response["output"] as? [[String: Any]] ?? [] {
                record(item, completed: true, viewModel: viewModel, messageId: messageId)
            }
            response["output"] = Self.rootOutput(response)
            if !hasTextDeltas {
                let text = Self.rootOutput(response).filter { $0["type"] as? String == "message" }.flatMap {
                    $0["content"] as? [[String: Any]] ?? []
                }.compactMap { $0["text"] as? String }.joined(separator: "\n\n")
                if !text.isEmpty, let index = viewModel.messages.firstIndex(where: { $0.id == messageId }) {
                    appendSeparator(viewModel, messageId: messageId)
                    viewModel.messages[index].text = (viewModel.messages[index].text ?? "") + text
                }
            }
            if let usage = response["usage"] as? [String: Any] {
                for key in ["input_tokens", "output_tokens", "total_tokens"] { usageTotals[key, default: 0] += usage[key] as? Int ?? 0 }
                let details = usage["input_tokens_details"] as? [String: Any] ?? [:]
                cachedTokens += details["cached_tokens"] as? Int ?? 0
                cacheWriteTokens += details["cache_write_tokens"] as? Int ?? 0
                var combined: [String: Any] = usageTotals
                combined["input_tokens_details"] = ["cached_tokens": cachedTokens, "cache_write_tokens": cacheWriteTokens]
                response["usage"] = combined
            }
            event["response"] = response
        }
        event["sequence_number"] = event["sequence_number"] ?? 0
        if let data = try? JSONSerialization.data(withJSONObject: event), let chunk = try? JSONDecoder().decode(StreamingEvent.self, from: data) {
            viewModel.handleStreamChunk(chunk, for: messageId)
        }
        if type == "response.completed", let response = raw["response"] as? [String: Any],
           (response["output"] as? [[String: Any]] ?? []).contains(where: { ["function_call", "custom_tool_call"].contains($0["type"] as? String ?? "") }) {
            viewModel.streamingStatus = .runningTool("Waiting for tool results")
        }
    }

    private func appendSeparator(_ viewModel: ChatViewModel, messageId: UUID) {
        viewModel.flushDeltaBufferIfNeeded(for: messageId)
        if let index = viewModel.messages.firstIndex(where: { $0.id == messageId }),
           let text = viewModel.messages[index].text, !text.isEmpty, !text.hasSuffix("\n\n") {
            viewModel.messages[index].text = text + "\n\n"
        }
    }

    private func renderImage(_ b64: String, id: String, viewModel: ChatViewModel, messageId: UUID) {
        guard let data = Data(base64Encoded: b64), let image = UIImage(data: data),
              let index = viewModel.messages.firstIndex(where: { $0.id == messageId }) else { return }
        var images = viewModel.messages[index].images ?? []
        if let slot = imageIndexes[id], images.indices.contains(slot) { images[slot] = image }
        else { imageIndexes[id] = images.count; images.append(image) }
        viewModel.messages[index].images = images
    }

    private func record(_ item: [String: Any], completed: Bool, viewModel: ChatViewModel, messageId: UUID) {
        let type = item["type"] as? String ?? ""
        let agent = ResponseTurnRunner.agentName(item)
        guard let id = item["id"] as? String else { return }
        if type == "image_generation_call", completed, agent == "/root", let b64 = item["result"] as? String {
            renderImage(b64, id: id, viewModel: viewModel, messageId: messageId)
        }
        let modernTypes = ["custom_tool_call", "agent_message", "function_call", "program", "program_output", "shell_call", "shell_call_output", "tool_search_call", "multi_agent_call", "compaction", "image_generation_call"]
        guard modernTypes.contains(type) || (type == "message" && agent != "/root") else { return }
        guard let index = viewModel.messages.firstIndex(where: { $0.id == messageId }) else { return }
        var timeline = viewModel.messages[index].toolTimeline ?? []
        let existing = timeline.firstIndex(where: { $0.id == id })
        // Function-item completion means arguments are ready, not that client execution has finished.
        let done = completed && !["function_call", "custom_tool_call"].contains(type)
        let name = item["name"] as? String ?? type.replacingOccurrences(of: "_", with: " ").capitalized
        let suffix = (item["async"] as? Bool == true ? " · async" : "")
            + ((item["caller"] as? [String: Any]).map { $0["type"] as? String != "direct" } == true ? " · program" : "")
            + (agent != "/root" ? " · \(agent)" : "")
        var entry = existing.map { timeline[$0] } ?? ToolExecutionTimeline(id: id, responseId: responseID, toolType: type, toolName: name + suffix)
        let clientFinished = ["function_call", "custom_tool_call"].contains(type) && entry.completedAt != nil
        if !clientFinished, entry.status != .completed { entry.status = done ? .completed : .running }
        if item["status"] as? String == "failed" { entry.status = .failed }
        var detail = item
        detail.removeValue(forKey: "encrypted_content")
        detail.removeValue(forKey: "fingerprint")
        if type == "agent_message" { detail.removeValue(forKey: "content") }
        if type == "image_generation_call" { detail.removeValue(forKey: "result") }
        entry.rawArguments = item["arguments"] as? String ?? item["input"] as? String ?? item["code"] as? String
        if !clientFinished { entry.rawOutputPreview = String(ResponsesAPIClient.pretty(detail).prefix(24_000)) }
        if done { entry.completedAt = Date() }
        if let existing { timeline[existing] = entry } else { timeline.append(entry) }
        viewModel.messages[index].toolTimeline = timeline
    }

    func toolResult(_ call: [String: Any], output: String, viewModel: ChatViewModel, messageId: UUID) {
        guard let id = call["id"] as? String,
              let index = viewModel.messages.firstIndex(where: { $0.id == messageId }),
              let slot = viewModel.messages[index].toolTimeline?.firstIndex(where: { $0.id == id }) else { return }
        viewModel.messages[index].toolTimeline?[slot].status = output.hasPrefix("Error:") ? .failed : .completed
        viewModel.messages[index].toolTimeline?[slot].rawOutputPreview = String(output.prefix(24_000))
        viewModel.messages[index].toolTimeline?[slot].completedAt = Date()
    }

    static func finishActivity(_ viewModel: ChatViewModel, messageId: UUID, status: ToolExecutionTimeline.Status) {
        guard let index = viewModel.messages.firstIndex(where: { $0.id == messageId }),
              var timeline = viewModel.messages[index].toolTimeline else { return }
        for slot in timeline.indices where [.running, .queued].contains(timeline[slot].status) {
            timeline[slot].status = status
            timeline[slot].completedAt = Date()
        }
        viewModel.messages[index].toolTimeline = timeline
    }
}
