import Foundation
import AVFoundation
import UIKit
import XCTest
@testable import OpenResponses

final class RealtimeAudioPipelineTests: XCTestCase {
    func testMicrophoneConversionDoesNotRepeatInputToFillOutputCapacity() throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let encoder = try XCTUnwrap(RealtimePCMEncoder(inputFormat: format))
        var frames = 0
        for _ in 0..<20 {
            let input = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1_024))
            input.frameLength = 1_024
            for index in 0..<1_024 { input.floatChannelData![0][index] = 0.15 * sin(Float(index) * 0.13) }
            let data = try encoder.encode(input)
            frames += data.count / 2
            XCTAssertGreaterThan(RealtimePCMEncoder.level(data), 0)
        }
        // 20 * 1,024 samples at 48 kHz is 10,240 samples at 24 kHz, allowing converter filter delay.
        XCTAssertEqual(frames, 10_240, accuracy: 32)
    }

    func testPCMLevelReturnsToZeroForSilenceAndEmptyInput() {
        XCTAssertEqual(RealtimePCMEncoder.level(Data()), 0)
        XCTAssertEqual(RealtimePCMEncoder.level(Data(repeating: 0, count: 4_800)), 0)
        XCTAssertGreaterThan(RealtimePCMEncoder.level(Data(repeating: 0x3F, count: 4_800)), 0)
    }

    func testPlaybackCompletionReopensMicrophoneForTwoConsecutiveTurns() {
        var state = RealtimePlaybackState()
        for turn in 0..<2 {
            let now = Double(turn * 10)
            let first = state.enqueue(frames: 2_400, level: 0.5, itemID: "item_\(turn)", contentIndex: 0, now: now, latency: 0)
            let last = state.enqueue(frames: 2_400, level: 0.7, itemID: "item_\(turn)", contentIndex: 0, now: now, latency: 0)
            XCTAssertTrue(state.suppressesMicrophone(now: now))
            state.complete(first, now: now + 0.1)
            XCTAssertTrue(state.suppressesMicrophone(now: now + 0.1))
            state.complete(last, now: now + 0.2)
            XCTAssertTrue(state.suppressesMicrophone(now: now + 0.3), "Brief echo tail is intentional")
            XCTAssertFalse(state.suppressesMicrophone(now: now + 0.5))
            XCTAssertEqual(state.level(now: now + 0.5), 0)
        }
    }

    func testLostPlaybackCallbackCannotPermanentlySuppressMicrophone() {
        var state = RealtimePlaybackState()
        _ = state.enqueue(frames: 24_000, level: 0.8, itemID: "item", contentIndex: 0, now: 10, latency: 0.1)
        XCTAssertFalse(state.recoverExpiredPlayback(now: 11.2))
        XCTAssertTrue(state.recoverExpiredPlayback(now: 11.9))
        XCTAssertFalse(state.suppressesMicrophone(now: 11.9))
        XCTAssertEqual(state.level(now: 11.9), 0)
    }

    func testOldCompletionAfterBargeInCannotDrainTheNextTurn() {
        var state = RealtimePlaybackState()
        let old = state.enqueue(frames: 24_000, level: 0.5, itemID: "old", contentIndex: 0, now: 0, latency: 0)
        state.reset()
        let new = state.enqueue(frames: 24_000, level: 0.7, itemID: "new", contentIndex: 0, now: 1, latency: 0)
        state.complete(old, now: 1.1)
        XCTAssertEqual(state.buffers.count, 1)
        XCTAssertEqual(state.buffers.first?.id, new.id)
        XCTAssertTrue(state.suppressesMicrophone(now: 1.1))
    }

    func testInterruptionTruncatesOnlyPlayedAudioAndWaveformTracksPlayback() {
        var state = RealtimePlaybackState()
        let first = state.enqueue(frames: 12_000, level: 0.3, itemID: "assistant", contentIndex: 0, now: 2, latency: 0.1)
        _ = state.enqueue(frames: 12_000, level: 0.8, itemID: "assistant", contentIndex: 0, now: 2, latency: 0.1)
        XCTAssertEqual(state.level(now: 2.2), 0.3)
        state.complete(first, now: 2.6)
        XCTAssertEqual(state.level(now: 2.8), 0.8)
        let event = state.truncation(now: 2.85)
        XCTAssertEqual(event?["item_id"] as? String, "assistant")
        XCTAssertEqual(event?["audio_end_ms"] as? Int ?? -1, 750, accuracy: 1)
        state.reset()
        XCTAssertNil(state.truncation(now: 3))
        XCTAssertEqual(state.level(now: 3), 0)
    }

    func testHeldPlaybackMovesTheQueueLaterWithoutDroppingIt() {
        var state = RealtimePlaybackState()
        let first = state.enqueue(frames: 12_000, level: 0.4, itemID: "assistant", contentIndex: 0, now: 5, latency: 0)
        _ = state.enqueue(frames: 12_000, level: 0.6, itemID: "assistant", contentIndex: 0, now: 5, latency: 0)
        state.delay(by: 0.6)
        XCTAssertEqual(state.buffers.count, 2)
        XCTAssertEqual(state.buffers[0].startsAt, 5.6, accuracy: 0.0001)
        XCTAssertEqual(state.buffers[1].endsAt, 6.6, accuracy: 0.0001)
        XCTAssertFalse(state.recoverExpiredPlayback(now: 7.2))
        state.complete(first, now: 6.1)
        XCTAssertEqual(state.buffers.count, 1, "a delayed buffer still completes by its original identity")
    }

    func testLiveGateIgnoresQuietShortOrUnopposedSpeech() {
        var gate = LiveInterruptionGate()
        XCTAssertEqual(gate.microphone(level: 0.2, at: 0, assistantAudible: true), .none)
        XCTAssertEqual(gate.microphone(level: 0.6, at: 0.1, assistantAudible: true), .none)
        XCTAssertEqual(gate.microphone(level: 0.1, at: 0.2, assistantAudible: true), .none, "a pause resets the onset")
        XCTAssertEqual(gate.microphone(level: 0.6, at: 0.3, assistantAudible: true), .none)
        XCTAssertEqual(gate.microphone(level: 0.6, at: 0.4, assistantAudible: true), .none)
        XCTAssertEqual(gate.microphone(level: 0.9, at: 1, assistantAudible: false), .none, "nothing to interrupt")
        XCTAssertFalse(gate.isHolding)
    }

    func testLiveGateResumesWhenLiveKeepsTalkingThroughABackchannel() {
        var gate = LiveInterruptionGate()
        XCTAssertEqual(gate.microphone(level: 0.6, at: 10, assistantAudible: true), .none)
        XCTAssertEqual(gate.microphone(level: 0.6, at: 10.2, assistantAudible: true), .pause)
        XCTAssertTrue(gate.isHolding)
        XCTAssertEqual(gate.microphone(level: 0.6, at: 10.3, assistantAudible: true), .none, "one decision per hold")
        gate.outputAudio(duration: 0.2)
        gate.outputAudio(duration: 0.2)
        XCTAssertEqual(gate.tick(at: 10.5), .none)
        XCTAssertEqual(gate.tick(at: 10.8), .resume)
        XCTAssertFalse(gate.isHolding)
    }

    func testLiveGateDiscardsQueuedAudioWhenLiveYields() {
        var gate = LiveInterruptionGate()
        _ = gate.microphone(level: 0.7, at: 20, assistantAudible: true)
        XCTAssertEqual(gate.microphone(level: 0.7, at: 20.2, assistantAudible: true), .pause)
        gate.outputAudio(duration: 0.1) // a straggler sent before Live stopped
        XCTAssertEqual(gate.tick(at: 20.8), .discard)
        gate.outputAudio(duration: 1)
        XCTAssertEqual(gate.tick(at: 22), .none, "audio after a decision starts no new hold")
    }

    func testLiveGateOnlyRunsWhereTheMicrophoneCannotHearTheAssistant() {
        XCTAssertTrue(RealtimeService.isPrivateOutput([.headphones]))
        XCTAssertTrue(RealtimeService.isPrivateOutput([.bluetoothA2DP]))
        XCTAssertTrue(RealtimeService.isPrivateOutput([.bluetoothHFP]))
        XCTAssertFalse(RealtimeService.isPrivateOutput([.builtInSpeaker]))
        XCTAssertFalse(RealtimeService.isPrivateOutput([.builtInReceiver]))
        XCTAssertFalse(RealtimeService.isPrivateOutput([.headphones, .builtInSpeaker]))
        XCTAssertFalse(RealtimeService.isPrivateOutput([]))
    }

    func testVADAutomaticallyCreatesTheNextResponseAndHonorsBargeIn() {
        for bargeIn in [false, true] {
            let config = RealtimeService.sessionConfiguration(voice: "alloy", instructions: "Brief", textOnly: false, bargeIn: bargeIn)
            let input = (config["audio"] as? [String: Any])?["input"] as? [String: Any]
            let vad = input?["turn_detection"] as? [String: Any]
            XCTAssertEqual(vad?["type"] as? String, "server_vad")
            XCTAssertEqual(vad?["create_response"] as? Bool, true)
            XCTAssertEqual(vad?["interrupt_response"] as? Bool, bargeIn)
        }
    }
}

@MainActor
final class StreamingEventDecodingTests: XCTestCase {
    func testResponseCompletedDecodesPromptCacheUsage() throws {
        let json = """
        {
          "type": "response.completed",
          "sequence_number": 2,
          "response": {
            "id": "resp_cache",
            "status": "completed",
            "output": [],
            "usage": {
              "input_tokens": 2006,
              "output_tokens": 300,
              "total_tokens": 2306,
              "input_tokens_details": {
                "cached_tokens": 1920,
                "cache_write_tokens": 0
              }
            }
          }
        }
        """

        let event = try JSONDecoder().decode(StreamingEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.response?.usage?.inputTokenDetails?.cachedTokens, 1920)
        XCTAssertEqual(event.response?.usage?.inputTokenDetails?.cacheWriteTokens, 0)
    }

    func testStreamingEventDecodesComputerCallActionsArray() throws {
        let json = """
        {
          "type": "response.output_item.done",
          "sequence_number": 3,
          "item": {
            "id": "cu_123",
            "type": "computer_call",
            "call_id": "call_123",
            "actions": [
              {
                "type": "click",
                "x": 120,
                "y": 320,
                "button": "left"
              },
              {
                "type": "type",
                "text": "penguin"
              }
            ]
          }
        }
        """

        let event = try JSONDecoder().decode(StreamingEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.type, "response.output_item.done")
        XCTAssertEqual(event.item?.type, "computer_call")
        XCTAssertEqual(event.item?.callId, "call_123")
        XCTAssertEqual(event.item?.actions?.count, 2)
        XCTAssertEqual(event.item?.actions?.first?["type"]?.value as? String, "click")
        XCTAssertEqual(event.item?.actions?.first?["x"]?.value as? Int, 120)
        XCTAssertEqual(event.item?.actions?[1]["type"]?.value as? String, "type")
        XCTAssertEqual(event.item?.actions?[1]["text"]?.value as? String, "penguin")
    }

    func testStreamingResponseCompletedDecodesComputerCallActionsAndSafetyChecks() throws {
        let json = """
        {
          "type": "response.completed",
          "sequence_number": 8,
          "response": {
            "id": "resp_computer",
            "status": "completed",
            "output": [
              {
                "id": "cu_done",
                "type": "computer_call",
                "call_id": "call_done",
                "actions": [
                  {
                    "type": "wait",
                    "seconds": 1
                  },
                  {
                    "type": "screenshot"
                  }
                ],
                "pending_safety_checks": [
                  {
                    "id": "safe_1",
                    "code": "sensitive_domain",
                    "message": "This action touches a potentially sensitive surface."
                  }
                ]
              }
            ]
          }
        }
        """

        let event = try JSONDecoder().decode(StreamingEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.type, "response.completed")
        XCTAssertEqual(event.response?.output?.count, 1)
        XCTAssertEqual(event.response?.output?.first?.type, "computer_call")
        XCTAssertEqual(event.response?.output?.first?.callId, "call_done")
        XCTAssertEqual(event.response?.output?.first?.actions?.count, 2)
        XCTAssertEqual(event.response?.output?.first?.actions?.first?["type"]?.value as? String, "wait")
        XCTAssertEqual(event.response?.output?.first?.pendingSafetyChecks?.first?.code, "sensitive_domain")
    }

    func testStreamingEventDecodesMCPListToolsWithNulls() throws {
        let json = """
        {
          "type": "response.completed",
          "sequence_number": 10,
          "response": {
            "id": "resp_123",
            "object": "response",
            "created_at": 1761670071,
            "status": "completed",
            "background": false,
            "error": null,
            "incomplete_details": null,
            "instructions": "You are a helpful assistant.",
            "max_output_tokens": null,
            "max_tool_calls": null,
            "model": "gpt-5-test",
            "output": [
              {
                "id": "mcpl_123",
                "type": "mcp_list_tools",
                "server_label": "Gmail",
                "tools": [
                  {
                    "name": "fetch_messages",
                    "description": "Read Gmail messages",
                    "metadata": null,
                    "annotations": {
                      "read_only": true
                    },
                    "input_schema": {
                      "type": "object",
                      "properties": {
                        "message_ids": {
                          "type": "array",
                          "description": null,
                          "items": {
                            "type": "string"
                          }
                        }
                      },
                      "required": ["message_ids"]
                    }
                  }
                ]
              }
            ]
          }
        }
        """

        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

        XCTAssertEqual(event.type, "response.completed")
        XCTAssertEqual(event.sequenceNumber, 10)

        guard let outputItem = event.response?.output?.first else {
            XCTFail("Expected output item")
            return
        }

        XCTAssertEqual(outputItem.serverLabel, "Gmail")
        XCTAssertEqual(outputItem.tools?.count, 1)

        guard let tool = outputItem.tools?.first else {
            XCTFail("Expected tool payload")
            return
        }

        XCTAssertEqual(tool["name"]?.value as? String, "fetch_messages")
        XCTAssertEqual(tool["metadata"]?.jsonString(), "null")

        guard let schemaJSON = tool["input_schema"]?.jsonString(),
              let schemaData = schemaJSON.data(using: .utf8),
              let schema = try JSONSerialization.jsonObject(with: schemaData) as? [String: Any] else {
            XCTFail("Expected input_schema JSON")
            return
        }

        XCTAssertEqual(schema["type"] as? String, "object")

        guard let required = schema["required"] as? [String] else {
            XCTFail("Expected required array")
            return
        }
        XCTAssertEqual(required, ["message_ids"])

        guard let properties = schema["properties"] as? [String: Any],
              let messageIds = properties["message_ids"] as? [String: Any] else {
            XCTFail("Expected properties.message_ids dictionary")
            return
        }

        XCTAssertEqual(messageIds["type"] as? String, "array")
        XCTAssertTrue(messageIds["description"] is NSNull)

        guard let items = messageIds["items"] as? [String: Any] else {
            XCTFail("Expected items dictionary")
            return
        }
        XCTAssertEqual(items["type"] as? String, "string")
    }

    func testStreamingEventDecodesMCPListToolsFromEmbeddedItem() throws {
        let json = """
        {
          "type": "response.mcp_list_tools.added",
          "sequence_number": 2,
          "server_label": "Gmail",
          "item": {
            "id": "mcpl_embedded",
            "type": "mcp_list_tools",
            "server_label": "Gmail",
            "tools": [
              {
                "name": "search_emails",
                "description": "Search mail by query.",
                "input_schema": {
                  "type": "object",
                  "properties": {
                    "query": { "type": "string" }
                  }
                }
              }
            ]
          }
        }
        """

        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

        XCTAssertEqual(event.type, "response.mcp_list_tools.added")
        XCTAssertNil(event.tools)

        guard let item = event.item else {
            XCTFail("Expected embedded streaming item")
            return
        }

        XCTAssertEqual(item.serverLabel, "Gmail")
        XCTAssertEqual(item.tools?.count, 1)
        XCTAssertEqual(item.tools?.first?["name"]?.value as? String, "search_emails")
    }

    func testStreamingEventDecodesApprovalRequestArgumentsObject() throws {
        let json = """
        {
          "type": "response.mcp_approval_request.added",
          "sequence_number": 4,
          "name": "list_messages",
          "server_label": "Gmail",
          "arguments": {
            "query": "from:boss@example.com",
            "max_results": 5
          },
          "approval_request_id": "mcpr_123",
          "item": {
            "id": "mcpr_123",
            "type": "mcp_approval_request",
            "server_label": "Gmail",
            "name": "list_messages",
            "arguments": {
              "query": "from:boss@example.com",
              "max_results": 5
            }
          }
        }
        """

        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

        XCTAssertEqual(event.type, "response.mcp_approval_request.added")
        XCTAssertEqual(event.sequenceNumber, 4)
        XCTAssertEqual(event.serverLabel, "Gmail")
        XCTAssertEqual(event.name, "list_messages")
        XCTAssertEqual(event.approvalRequestId, "mcpr_123")

        guard let topArguments = event.arguments,
              let topArgsData = topArguments.data(using: .utf8),
              let topArgs = try JSONSerialization.jsonObject(with: topArgsData) as? [String: Any] else {
            XCTFail("Expected top-level arguments JSON")
            return
        }

        XCTAssertEqual(topArgs["query"] as? String, "from:boss@example.com")
        XCTAssertEqual(topArgs["max_results"] as? Int, 5)

        guard let item = event.item else {
            XCTFail("Expected embedded item")
            return
        }
        XCTAssertEqual(item.serverLabel, "Gmail")
        XCTAssertEqual(item.name, "list_messages")

        guard let itemArguments = item.arguments,
              let itemArgsData = itemArguments.data(using: .utf8),
              let itemArgs = try JSONSerialization.jsonObject(with: itemArgsData) as? [String: Any] else {
            XCTFail("Expected item arguments JSON")
            return
        }

        XCTAssertEqual(itemArgs["query"] as? String, "from:boss@example.com")
        XCTAssertEqual(itemArgs["max_results"] as? Int, 5)
    }

    @MainActor
    func testApprovalSummaryBuildsFromCompletionOutput() throws {
        let json = """
        {
          "type": "response.completed",
          "sequence_number": 7,
          "response": {
            "id": "resp_approval",
            "object": "response",
            "created_at": 1761675071,
            "status": "completed",
            "background": false,
            "error": null,
            "output": [
              {
                "id": "mcpr_approve_1",
                "type": "mcp_approval_request",
                "server_label": "Gmail",
                "name": "list_messages",
                "arguments": {
                  "query": "from:boss@example.com",
                  "max_results": 5
                },
                "approval_request_id": "mcpr_approve_1"
              }
            ]
          }
        }
        """

        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

        XCTAssertEqual(event.type, "response.completed")
        XCTAssertEqual(event.sequenceNumber, 7)

        let prompt = Prompt.defaultPrompt()
        let requests = MCPApprovalUtils.extractApprovalRequests(from: event.response?.output, prompt: prompt).requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.toolName, "list_messages")
        XCTAssertEqual(requests.first?.serverLabel, "Gmail")

        let summary = MCPApprovalUtils.buildTextFromApprovalRequests(requests)
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary?.contains("Approval required") == true)
        XCTAssertTrue(summary?.contains("list_messages") == true)
        XCTAssertTrue(summary?.contains("Gmail") == true)
        XCTAssertTrue(summary?.contains("query") == true)
    }

    @MainActor
    func testApprovalResponsePayloadOmitsReasonWhenApproving() {
      let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "mcpr_approve",
            approve: true,
            reason: "Looks good"
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "mcpr_approve")
        XCTAssertEqual(payload["approve"] as? Bool, true)
        XCTAssertNil(payload["reason"])
    }

    @MainActor
    func testApprovalResponsePayloadIncludesReasonWhenRejecting() {
      let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "mcpr_reject",
            approve: false,
            reason: "Insufficient scope"
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approve"] as? Bool, false)
        XCTAssertEqual(payload["reason"] as? String, "Insufficient scope")
    }
}


@MainActor
final class APIWorkbenchEventTests: XCTestCase {
    func testWorkbenchPreservesUnknownEventsAndAsyncToolCallMetadata() {
        let session = APIWorkbenchSession()
        session.receive(["type": "response.created", "response": ["id": "resp_new"]])
        XCTAssertTrue(session.isRunning)
        session.receive(["type": "response.future_tool.completed", "new_field": "retained"])
        XCTAssertTrue(session.transcript.contains("retained"))
        session.receive(["type": "response.completed", "response": ["id": "resp_new", "status": "completed", "output": [["type": "function_call", "name": "lookup", "call_id": "call_async", "async": true, "caller": ["type": "programmatic", "program_id": "prog_1"]]]]])
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.pendingCalls.first?["async"] as? Bool, true)
        XCTAssertEqual((session.pendingCalls.first?["caller"] as? [String: Any])?["program_id"] as? String, "prog_1")
    }

    func testIncompleteWorkbenchResponseIsTerminalAndKeepsReason() {
        let session = APIWorkbenchSession()
        session.receive(["type": "response.created", "response": ["id": "resp_short"]])
        session.receive(["type": "response.incomplete", "response": ["id": "resp_short", "status": "incomplete", "incomplete_details": ["reason": "max_output_tokens"]]])
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.status, "incomplete")
        XCTAssertTrue(session.transcript.contains("max_output_tokens"))
    }
}

@MainActor
final class ResponseTurnRunnerTests: XCTestCase {
    typealias JSON = [String: Any]

    private func call(_ id: String, name: String = "fetchAppleReminders") -> JSON {
        ["id": "fc_" + id, "type": "function_call", "call_id": id, "name": name, "arguments": "{}", "async": true]
    }

    private func events(_ output: [JSON], id: String = "resp_one", status: String = "completed") -> [JSON] {
        [["type": "response.created", "response": ["id": id]]]
        + output.map { ["type": "response.output_item.done", "item": $0] }
        + [["type": "response." + status, "response": ["id": id, "status": status, "output": output]]]
    }

    private func stream(_ events: [JSON]) -> AsyncThrowingStream<JSON, Error> {
        AsyncThrowingStream { continuation in
            for event in events { continuation.yield(event) }
            continuation.finish()
        }
    }

    func testTextAndAsyncCallsWaitForTerminalAndSubmitEveryOutputOnce() async throws {
        let calls = [call("call_a"), call("call_b")]
        let message: JSON = ["id": "msg_progress", "type": "message", "role": "assistant", "phase": "commentary", "content": [["type": "output_text", "text": "Working"]]]
        var requests: [JSON] = []
        var executions: [String] = []
        var terminalSeen = false
        let result = try await ResponseTurnRunner().run(body: ["model": "gpt-6-astra", "input": "Read two lists", "store": false], stream: { body in
            requests.append(body)
            if requests.count == 1 { return self.stream(self.events([message] + calls)) }
            XCTAssertTrue(terminalSeen)
            let input = body["input"] as? [JSON] ?? []
            let outputs = input.filter { $0["type"] as? String == "function_call_output" }
            XCTAssertEqual(Set(outputs.compactMap { $0["call_id"] as? String }), ["call_a", "call_b"])
            XCTAssertEqual(outputs.count, 2)
            XCTAssertEqual(input.first { $0["id"] as? String == "msg_progress" }?["phase"] as? String, "commentary")
            return self.stream(self.events([], id: "resp_two"))
        }, execute: { call in
            let id = call["call_id"] as! String
            executions.append(id)
            await Task.yield()
            return "actual " + id
        }, onEvent: { event in
            if event["type"] as? String == "response.completed" { terminalSeen = true }
        }, onToolResult: { _, _ in })
        XCTAssertEqual(result.rounds, 2)
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(executions.sorted(), ["call_a", "call_b"])
    }

    func testProgramAndAgentOpaqueStateSurvivesReplay() async throws {
        var nested = call("call_program")
        nested["caller"] = ["type": "program", "caller_id": "program_call"]
        nested["agent"] = ["agent_name": "/root/research"]
        let program: JSON = ["type": "program", "id": "prog_1", "call_id": "program_call", "code": "await tools.fetchAppleReminders({})", "fingerprint": "opaque"]
        var requests = 0
        _ = try await ResponseTurnRunner().run(body: ["input": "Investigate", "store": false, "multi_agent": ["enabled": true]], stream: { body in
            requests += 1
            if requests == 1 { return self.stream(self.events([program, nested])) }
            let input = body["input"] as? [JSON] ?? []
            XCTAssertEqual(input.first { $0["type"] as? String == "program" }?["fingerprint"] as? String, "opaque")
            let replayCall = input.first { $0["type"] as? String == "function_call" }
            XCTAssertEqual((replayCall?["caller"] as? JSON)?["caller_id"] as? String, "program_call")
            XCTAssertEqual((replayCall?["agent"] as? JSON)?["agent_name"] as? String, "/root/research")
            XCTAssertNotNil(body["multi_agent"])
            return self.stream(self.events([], id: "resp_final"))
        }, execute: { _ in "[]" }, onEvent: { _ in }, onToolResult: { _, _ in })
    }

    func testIncompleteResponseDoesNotExecuteMutationOrContinue() async {
        var count = 0
        do {
            _ = try await ResponseTurnRunner().run(body: ["input": "Create a reminder"], stream: { _ in
                count += 1
                return self.stream(self.events([self.call("write", name: "createAppleReminder")], status: "incomplete"))
            }, execute: { _ in XCTFail("An incomplete response must not execute a deferred write"); return "bad" }, onEvent: { _ in }, onToolResult: { _, _ in })
            XCTFail("Expected an incomplete-response error")
        } catch { XCTAssertEqual(count, 1) }
    }

    func testMutationWaitsForTerminalAndDuplicateCallIsNotExecutedAgain() async throws {
        var terminal = false
        var rounds = 0
        var executions = 0
        _ = try await ResponseTurnRunner().run(body: ["input": "Create once", "store": true], stream: { body in
            rounds += 1
            if rounds > 1 { XCTAssertNotNil(body["previous_response_id"]) }
            return self.stream(self.events(rounds < 3 ? [self.call("write", name: "createAppleReminder")] : [], id: "resp_\(rounds)"))
        }, execute: { _ in
            XCTAssertTrue(terminal)
            executions += 1
            return "Created"
        }, onEvent: { event in
            if event["type"] as? String == "response.created" { terminal = false }
            if event["type"] as? String == "response.completed" { terminal = true }
        }, onToolResult: { _, _ in })
        XCTAssertEqual(executions, 1)
        XCTAssertEqual(rounds, 3)
    }

    func testMissingCallIDAndTruncatedStreamsFailWithoutToolExecution() async {
        for output in [stream([["type": "response.created", "response": ["id": "resp_short"]]]), stream(events([["id": "fc_bad", "type": "function_call", "name": "fetchAppleReminders"]]))] {
            do {
                _ = try await ResponseTurnRunner().run(body: [:], stream: { _ in output }, execute: { _ in XCTFail("Invalid stream must not execute"); return "" }, onEvent: { _ in }, onToolResult: { _, _ in })
                XCTFail("Expected validation error")
            } catch { XCTAssertTrue(error is OpenAIServiceError) }
        }
    }

    func testSubagentMessagesAreExcludedFromAnswerButCallsRemain() {
        let response: JSON = ["output": [
            ["type": "message", "id": "root", "agent": ["agent_name": "/root"]],
            ["type": "message", "id": "child", "agent": ["agent_name": "/root/research"]],
            ["type": "function_call", "id": "fc", "agent": ["agent_name": "/root/research"]]
        ]]
        XCTAssertEqual(ManagedResponsePresentation.rootOutput(response).compactMap { $0["id"] as? String }, ["root", "fc"])
    }

    func testOldModernSettingsDecodeWithNewFeaturesOff() throws {
        let options = try JSONDecoder().decode(ModernResponseOptions.self, from: Data(#"{"hostedShell":true,"reasoningContext":"all_turns"}"#.utf8))
        XCTAssertTrue(options.hostedShell)
        XCTAssertEqual(options.reasoningContext, "all_turns")
        XCTAssertFalse(options.asyncTools)
        XCTAssertFalse(options.multiAgent)
        XCTAssertFalse(options.programmaticTools)
        XCTAssertEqual(options.maxToolRounds, 12)
    }
}

@MainActor
final class NativeResponseLifecycleTests: XCTestCase {
    typealias JSON = [String: Any]

    func testNativeToolCardWaitsForExecutionAndPreservesFailureThroughFinalResponse() {
        let vm = ChatViewModel()
        let message = ChatMessage(role: .assistant, text: "")
        vm.messages = [message]
        vm.managedResponseMessageId = message.id
        let presentation = ManagedResponsePresentation()
        let call: JSON = ["id": "fc_display", "type": "function_call", "call_id": "call_display", "name": "fetchAppleReminders", "arguments": "{}"]
        presentation.receive(["type": "response.output_item.done", "item": call], viewModel: vm, messageId: message.id)
        XCTAssertEqual(vm.messages.first?.toolTimeline?.first?.status, .running)
        presentation.toolResult(call, output: "Error: access denied", viewModel: vm, messageId: message.id)
        presentation.receive(["type": "response.completed", "response": ["id": "resp_display", "status": "completed", "output": [call]]], viewModel: vm, messageId: message.id)
        XCTAssertEqual(vm.messages.first?.toolTimeline?.first?.status, .failed)
        XCTAssertEqual(vm.messages.first?.toolTimeline?.first?.rawOutputPreview, "Error: access denied")
    }

    func testCancellationCancelsReadJobAndPreventsContinuation() async {
        let started = expectation(description: "Read tool started")
        let cancelled = expectation(description: "Read tool cancelled")
        var requests = 0
        let runner = Task {
            try await ResponseTurnRunner().run(body: [:], stream: { _ in
                requests += 1
                return AsyncThrowingStream { continuation in
                    continuation.yield(["type": "response.output_item.done", "item": ["id": "fc_slow", "type": "function_call", "call_id": "slow", "name": "fetchAppleReminders", "arguments": "{}"]])
                }
            }, execute: { _ in
                started.fulfill()
                do { try await Task.sleep(nanoseconds: 60_000_000_000); return "never" }
                catch { cancelled.fulfill(); throw error }
            }, onEvent: { _ in }, onToolResult: { _, _ in XCTFail("Cancelled tool must not submit output") })
        }
        await fulfillment(of: [started], timeout: 3)
        runner.cancel()
        do { _ = try await runner.value; XCTFail("Expected cancellation") } catch { XCTAssertTrue(error is CancellationError) }
        await fulfillment(of: [cancelled], timeout: 3)
        XCTAssertEqual(requests, 1)
    }

    func testCustomTextToolReturnsCustomOutputWithOriginalCallID() async throws {
        var requests = 0
        _ = try await ResponseTurnRunner().run(body: ["store": false], stream: { body in
            requests += 1
            var output: [JSON] = []
            if requests == 1 {
                output = [["id": "ct_1", "type": "custom_tool_call", "name": "echo_text", "call_id": "custom_123", "input": "plain text"]]
            } else {
                let item = (body["input"] as? [JSON])?.last
                XCTAssertEqual(item?["type"] as? String, "custom_tool_call_output")
                XCTAssertEqual(item?["call_id"] as? String, "custom_123")
                XCTAssertEqual(item?["output"] as? String, "plain text")
            }
            return AsyncThrowingStream { continuation in
                continuation.yield(["type": "response.completed", "response": ["id": "resp_\(requests)", "status": "completed", "output": output]])
                continuation.finish()
            }
        }, execute: { $0["input"] as? String ?? "" }, onEvent: { _ in }, onToolResult: { _, _ in })
        XCTAssertEqual(requests, 2)
    }

    func testWorkbenchExposesWaitingToolsBeforeResponseCompletes() {
        let session = APIWorkbenchSession()
        session.receive(["type": "response.created", "response": ["id": "resp_live"]])
        let event: JSON = ["type": "response.output_item.done", "item": ["type": "function_call", "id": "fc_child", "call_id": "call_child", "name": "lookup", "agent": ["agent_name": "/root/child"]]]
        session.receive(event)
        session.receive(event)
        XCTAssertTrue(session.isRunning)
        XCTAssertEqual(session.pendingCalls.count, 1)
        XCTAssertEqual(session.pendingCalls.first?["call_id"] as? String, "call_child")
    }

    func testNativePresentationSeparatesAgentTextAndAccumulatesUsage() {
        let viewModel = ChatViewModel()
        let id = UUID()
        viewModel.messages = [ChatMessage(id: id, role: .assistant, text: "")]
        viewModel.streamingMessageId = id
        viewModel.managedResponseMessageId = id
        viewModel.isStreaming = true
        let presentation = ManagedResponsePresentation()
        presentation.receive(["type": "response.created", "response": ["id": "resp_first"]], viewModel: viewModel, messageId: id)
        presentation.receive(["type": "response.output_item.added", "output_index": 0, "item": ["id": "child", "type": "message", "agent": ["agent_name": "/root/child"]]], viewModel: viewModel, messageId: id)
        presentation.receive(["type": "response.output_text.delta", "output_index": 0, "item_id": "child", "delta": "CHILD-ONLY"], viewModel: viewModel, messageId: id)
        for round in 1...2 {
            presentation.receive(["type": "response.completed", "response": ["id": "resp_\(round)", "status": "completed", "usage": ["input_tokens": 10, "output_tokens": 5, "total_tokens": 15], "output": [["id": "root_\(round)", "type": "message", "role": "assistant", "content": [["type": "output_text", "text": "Root \(round)"]]]]]], viewModel: viewModel, messageId: id)
        }
        XCTAssertEqual(viewModel.messages.first?.text, "Root 1\n\nRoot 2")
        XCTAssertEqual(viewModel.messages.first?.tokenUsage?.total, 30)
        XCTAssertFalse(viewModel.messages.first?.text?.contains("CHILD-ONLY") ?? true)
        XCTAssertTrue(viewModel.isStreaming, "Only the runner may finish the complete tool turn")
    }
}
@MainActor
final class ResponseSocketRunnerTests: XCTestCase {
    typealias JSON = [String: Any]

    func testInjectsRealResultsBeforeCompletionAndWaitsForAcknowledgment() async throws {
        let (events, feed) = AsyncThrowingStream<JSON, Error>.makeStream()
        let call: JSON = ["type": "function_call", "id": "fc_probe", "call_id": "call_probe", "name": "read_probe", "arguments": "{}", "agent": ["agent_name": "/root/probe"], "caller": ["type": "direct"]]
        var executions = 0
        var injections = 0
        var closed = false
        var terminalSeen = false
        var ackSeen = false
        let socket = ResponseSocketRunner.Connection(events: events, send: { event in
            switch event["type"] as? String {
            case "response.create":
                XCTAssertNil(event["stream"])
                feed.yield(["type": "response.created", "response": ["id": "resp_probe"]])
                feed.yield(["type": "response.output_item.done", "item": call])
                feed.yield(["type": "response.output_item.done", "item": call])
            case "response.inject":
                injections += 1
                XCTAssertEqual(event["response_id"] as? String, "resp_probe")
                let outputs = try XCTUnwrap(event["input"] as? [JSON])
                XCTAssertEqual(outputs.first?["call_id"] as? String, "call_probe")
                XCTAssertEqual(outputs.first?["output"] as? String, "actual local result")
                feed.yield(["type": "response.completed", "response": ["id": "resp_probe", "status": "completed", "output": [call]]])
                feed.yield(["type": "response.inject.created", "input": outputs])
            default: XCTFail("Unexpected socket message")
            }
        }, close: { closed = true; feed.finish() })
        let result = try await ResponseTurnRunner().run(body: ["input": "read", "store": false, "stream": true], stream: { _ in XCTFail("Must use socket"); return AsyncThrowingStream { $0.finish() } }, socket: socket, execute: { _ in
            XCTAssertFalse(terminalSeen)
            executions += 1
            return "actual local result"
        }, onEvent: { event in
            if event["type"] as? String == "response.completed" { terminalSeen = true }
            if event["type"] as? String == "response.inject.created" { ackSeen = true }
        }, onToolResult: { _, _ in })
        XCTAssertEqual(executions, 1); XCTAssertEqual(injections, 1)
        XCTAssertTrue(terminalSeen); XCTAssertTrue(ackSeen); XCTAssertTrue(closed)
        XCTAssertEqual(result.replayInput.filter { $0["type"] as? String == "function_call_output" }.count, 1)
        XCTAssertEqual(ResponseTurnRunner.agentName(try XCTUnwrap(result.replayInput.first { $0["type"] as? String == "function_call" })), "/root/probe")
    }

    func testFailedInjectionRetainsExecutedWriteWithoutRetry() async throws {
        let (events, feed) = AsyncThrowingStream<JSON, Error>.makeStream()
        let call: JSON = ["type": "custom_tool_call", "id": "ct_write", "call_id": "call_write", "name": "write", "input": "fixture"]
        var executions = 0
        var checkpoint: [JSON] = []
        let socket = ResponseSocketRunner.Connection(events: events, send: { event in
            if event["type"] as? String == "response.create" {
                feed.yield(["type": "response.created", "response": ["id": "resp_write"]])
                feed.yield(["type": "response.output_item.done", "item": call])
            } else {
                XCTAssertEqual((event["input"] as? [JSON])?.first?["type"] as? String, "custom_tool_call_output")
                feed.yield(["type": "response.inject.failed", "error": ["message": "fixture rejection"]])
            }
        }, close: { feed.finish() })
        do {
            _ = try await ResponseSocketRunner().run(body: [:], connection: socket, maxCalls: 2, concurrentNames: [], initialHistory: nil, execute: { _ in executions += 1; return "write completed" }, onCheckpoint: { checkpoint = $0.replayInput }, onEvent: { _ in }, onToolResult: { _, _ in })
            XCTFail("Injection rejection must fail the run")
        } catch { XCTAssertTrue(error.localizedDescription.contains("fixture rejection")) }
        XCTAssertEqual(executions, 1)
        XCTAssertEqual(checkpoint.last?["output"] as? String, "write completed")
        XCTAssertEqual(ResponseTurnRunner.recoveryInput(checkpoint).count, checkpoint.count)
    }

    func testSocketCancellationClosesConnectionAndCancelsReadTask() async throws {
        let (events, feed) = AsyncThrowingStream<JSON, Error>.makeStream()
        let started = expectation(description: "read started")
        let cancelled = expectation(description: "read cancelled")
        var closed = false
        let socket = ResponseSocketRunner.Connection(events: events, send: { _ in
            feed.yield(["type": "response.created", "response": ["id": "resp_cancel"]])
            feed.yield(["type": "response.output_item.done", "item": ["id": "fc_cancel", "type": "function_call", "name": "read", "call_id": "call_cancel", "arguments": "{}"]])
        }, close: { closed = true; feed.finish() })
        let task = Task {
            try await ResponseSocketRunner().run(body: [:], connection: socket, maxCalls: 2, concurrentNames: ["read"], initialHistory: nil, execute: { _ in
                started.fulfill()
                do { try await Task.sleep(nanoseconds: 30_000_000_000); return "unexpected" }
                catch { cancelled.fulfill(); throw error }
            }, onCheckpoint: { _ in }, onEvent: { _ in }, onToolResult: { _, _ in })
        }
        await fulfillment(of: [started], timeout: 2)
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancellation must throw") } catch { XCTAssertTrue(error is CancellationError) }
        await fulfillment(of: [cancelled], timeout: 2)
        XCTAssertTrue(closed)
    }

    func testInterruptedReplayMarksOnlyUnansweredCallsUnknown() {
        let history: [JSON] = [
            ["type": "program", "id": "program_1", "fingerprint": "opaque"],
            ["type": "function_call", "call_id": "known", "name": "write", "arguments": "{}"],
            ["type": "function_call_output", "call_id": "known", "output": "saved"],
            ["type": "custom_tool_call", "call_id": "unknown", "name": "write", "input": "fixture"]
        ]
        let recovered = ResponseTurnRunner.recoveryInput(history)
        XCTAssertEqual(recovered.count, 5)
        XCTAssertEqual(recovered.first?["fingerprint"] as? String, "opaque")
        XCTAssertEqual(recovered.last?["type"] as? String, "custom_tool_call_output")
        XCTAssertEqual(recovered.last?["call_id"] as? String, "unknown")
        XCTAssertTrue((recovered.last?["output"] as? String ?? "").contains("result is unknown"))
        XCTAssertEqual(ResponseTurnRunner.recoveryInput(recovered).count, 5)
    }

    func testConflictingDuplicateCallIDDoesNotExecuteWrite() async throws {
        var executions = 0
        do {
            _ = try await ResponseTurnRunner().run(body: [:], stream: { _ in AsyncThrowingStream { feed in
                for args in ["first", "changed"] { feed.yield(["type": "response.output_item.done", "item": ["type": "custom_tool_call", "name": "write", "call_id": "duplicate", "input": args]]) }
                feed.finish()
            } }, execute: { _ in executions += 1; return "" }, onEvent: { _ in }, onToolResult: { _, _ in })
            XCTFail("Conflicting call IDs must fail")
        } catch { XCTAssertTrue(error.localizedDescription.contains("call_id")) }
        XCTAssertEqual(executions, 0)
    }
}

@MainActor
final class MCPDiscoveryTests: XCTestCase {
    private func config(url: String = "https://example.com/mcp", token: String = "fixture", allowed: String = "") throws -> MCPDiscoveryConfiguration {
        var prompt = Prompt.defaultPrompt()
        prompt.mcpServerLabel = "fixture"
        prompt.mcpServerURL = url
        prompt.mcpIsConnector = false
        prompt.mcpAllowedTools = allowed
        prompt.systemInstructions = "Private instructions must not be sent."
        prompt.enableComputerUse = true
        prompt.backgroundMode = true
        return try MCPDiscoveryConfiguration(prompt: prompt, headersOverride: token.isEmpty ? [:] : ["Authorization": token])
    }

    private func catalog(tools: [[String: Any]] = [["name": "search", "input_schema": ["type": "object"]]]) -> [String: Any] {
        ["type": "response.output_item.done", "item": ["type": "mcp_list_tools", "server_label": "fixture", "tools": tools, "error": NSNull()]]
    }

    func testMCPDiscoveryLifecycleDoesNotInventAnEmptyCatalog() throws {
        let viewModel = ChatViewModel()
        let message = ChatMessage(role: .assistant, text: "")
        viewModel.messages = [message]
        viewModel.streamingMessageId = message.id
        viewModel.activePrompt.mcpServerLabel = "fixture"
        for type in ["response.mcp_list_tools.in_progress", "response.mcp_list_tools.completed"] {
            let data = try JSONSerialization.data(withJSONObject: ["type": type, "item_id": "mcpl_fixture", "output_index": 0, "sequence_number": 1])
            let chunk = try JSONDecoder().decode(StreamingEvent.self, from: data)
            viewModel.handleStreamChunk(chunk, for: message.id)
        }
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertTrue(viewModel.mcpToolRegistry.isEmpty)

        let completed: [String: Any] = ["type": "response.output_item.done", "output_index": 0, "sequence_number": 2,
            "item": ["id": "mcpl_fixture", "type": "mcp_list_tools", "server_label": "fixture", "tools": [["name": "search", "input_schema": ["type": "object"]]]]]
        let chunk = try JSONDecoder().decode(StreamingEvent.self, from: JSONSerialization.data(withJSONObject: completed))
        viewModel.handleStreamChunk(chunk, for: message.id)
        XCTAssertEqual(viewModel.mcpToolRegistry["fixture"]?.count, 1)
        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func testDiscoveryIsIsolatedAndCannotExecuteTools() throws {
        let configuration = try config()
        let body = configuration.body
        XCTAssertEqual(body["tool_choice"] as? String, "none")
        XCTAssertEqual(body["store"] as? Bool, false)
        XCTAssertEqual(configuration.tool["require_approval"] as? String, "always")
        XCTAssertEqual((body["tools"] as? [[String: Any]])?.count, 1)
        for key in ["instructions", "previous_response_id", "conversation", "background", "multi_agent", "async"] { XCTAssertNil(body[key]) }
        XCTAssertFalse(ResponsesAPIClient.pretty(body).contains("Private instructions"))
    }

    func testDraftCredentialsDoNotOverwriteSavedHeaders() throws {
        var prompt = Prompt.defaultPrompt()
        prompt.mcpIsConnector = false
        prompt.mcpServerLabel = "draft-fixture"
        prompt.mcpServerURL = "https://example.com/mcp"
        let key = "mcp_manual_\(prompt.id.uuidString)"
        defer { KeychainService.shared.delete(forKey: key) }
        prompt.secureMCPHeaders = ["Authorization": "saved-fixture"]
        let before = KeychainService.shared.load(forKey: key)
        let draft = try MCPDiscoveryConfiguration(prompt: prompt, headersOverride: ["Authorization": "draft-fixture"])
        XCTAssertEqual(draft.tool["authorization"] as? String, "draft-fixture")
        XCTAssertEqual(KeychainService.shared.load(forKey: key), before)
        let anonymous = try MCPDiscoveryConfiguration(prompt: prompt, headersOverride: [:])
        XCTAssertNil(anonymous.tool["authorization"])
        XCTAssertEqual(KeychainService.shared.load(forKey: key), before)
    }

    func testAuthorizationPreservesAPIKeysAndRemovesClientInventedSessions() throws {
        let result = try MCPDiscoveryConfiguration.authorization(headers: ["Authorization": "Bearer fixture", "X-API-Key": "raw-fixture", "Mcp-Session-Id": "invented"], keepInHeaders: false)
        XCTAssertEqual(result.0, "fixture")
        XCTAssertEqual(result.1, ["x-api-key": "raw-fixture"])
        XCTAssertThrowsError(try MCPDiscoveryConfiguration.authorization(headers: ["Bad Header": "value"], keepInHeaders: false))
        XCTAssertThrowsError(try MCPDiscoveryConfiguration.authorization(headers: ["Authorization": "value\r\nInjected: token"], keepInHeaders: false))
        XCTAssertThrowsError(try MCPDiscoveryConfiguration.authorization(headers: ["Authorization": "one", "authorization": "two"], keepInHeaders: false))
    }

    func testURLValidationUsesExactHostAndRejectsEmbeddedCredentials() {
        XCTAssertTrue(MCPDiscoveryConfiguration.validURL("https://example.com/mcp"))
        for value in ["http://example.com/mcp", "https://", "https://user:pass@example.com/mcp", "https://example.com/mcp#fragment"] {
            XCTAssertFalse(MCPDiscoveryConfiguration.validURL(value))
        }
        XCTAssertTrue(MCPDiscoveryConfiguration.isNotionHosted("https://mcp.notion.com/mcp"))
        XCTAssertFalse(MCPDiscoveryConfiguration.isNotionHosted("https://example.com/mcp.notion.com"))
        XCTAssertFalse(MCPDiscoveryConfiguration.isNotionHosted("https://mcp.notion.com.example.com"))
    }

    func testCacheIdentityIncludesEndpointTokenAllowlistAndOpenAIAccount() throws {
        let base = try config().cacheKey(apiKey: "account-one")
        XCTAssertEqual(base, try config().cacheKey(apiKey: "account-one"))
        XCTAssertNotEqual(base, try config(url: "https://other.example/mcp").cacheKey(apiKey: "account-one"))
        XCTAssertNotEqual(base, try config(token: "other-fixture").cacheKey(apiKey: "account-one"))
        XCTAssertNotEqual(base, try config(allowed: "search").cacheKey(apiKey: "account-one"))
        XCTAssertNotEqual(base, try config().cacheKey(apiKey: "account-two"))
        XCTAssertEqual(try config(allowed: "b, a,a").cacheKey(apiKey: "account-one"), try config(allowed: "a,b").cacheKey(apiKey: "account-one"))
    }

    func testParserWaitsForCompleteCatalogAndPreservesEmptySuccess() throws {
        let parser = MCPDiscoveryParser(label: "fixture", filtered: false)
        for event: [String: Any] in [["type": "response.mcp_list_tools.in_progress"], ["type": "response.mcp_list_tools.completed"], ["type": "response.output_item.added", "item": ["type": "mcp_list_tools", "server_label": "fixture", "tools": []]]] {
            XCTAssertNil(try parser.consume(event))
        }
        XCTAssertEqual(try parser.consume(catalog())?.tools.first?.name, "search")
        XCTAssertEqual(try parser.consume(catalog(tools: []))?.tools.count, 0)
    }

    func testParserHandlesTerminalFallbackAndRejectsIncompleteOrForeignCatalogs() throws {
        let parser = MCPDiscoveryParser(label: "fixture", filtered: true)
        let item = try XCTUnwrap(catalog()["item"])
        let snapshot = try parser.consume(["type": "response.completed", "response": ["output": [item]]])
        XCTAssertEqual(snapshot?.tools.count, 1)
        XCTAssertEqual(snapshot?.filtered, true)
        XCTAssertThrowsError(try parser.consume(["type": "response.completed", "response": ["output": []]]))
        XCTAssertThrowsError(try parser.consume(catalog(tools: [["name": "broken"]])) )
        XCTAssertThrowsError(try parser.consume(catalog(tools: [["name": "a", "input_schema": [:]], ["name": "a", "input_schema": [:]]])))
        XCTAssertNil(try MCPDiscoveryParser(label: "different", filtered: false).consume(catalog()))
    }

    func testRemoteErrorsAreClassifiedWithoutEchoingSecretsAndCallsAreRejected() throws {
        let parser = MCPDiscoveryParser(label: "fixture", filtered: false)
        XCTAssertThrowsError(try parser.consume(["type": "response.failed", "response": ["error": ["message": "401 unauthorized secret-fixture-token"]]])) { error in
            XCTAssertEqual(error as? MCPDiscoveryError, .authentication)
            XCTAssertFalse(error.localizedDescription.contains("secret-fixture-token"))
        }
        for type in ["mcp_call", "mcp_approval_request"] {
            XCTAssertThrowsError(try parser.consume(["type": "response.output_item.added", "item": ["type": type]])) { error in
                XCTAssertEqual(error as? MCPDiscoveryError, .unexpectedToolCall)
            }
        }
        XCTAssertThrowsError(try parser.consume(["type": "response.output_item.done", "item": ["type": "mcp_list_tools", "server_label": "fixture", "tools": [], "error": "403 denied"]])) { error in
            XCTAssertEqual(error as? MCPDiscoveryError, .permissionDenied)
        }
    }

    func testSSEFramingSupportsCommentsCRLFMultilineAndDone() throws {
        var decoder = MCPDiscoverySSEDecoder()
        var events: [[String: Any]] = []
        let bytes = ": keepalive\r\nevent: response.output_item.done\r\ndata: {\"type\":\r\ndata: \"fixture\"}\r\n\r\ndata: [DONE]\n\n".utf8
        for byte in bytes { if let event = try decoder.append(byte) { events.append(event) } }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?["type"] as? String, "fixture")
        XCTAssertTrue(decoder.isDone)
        var malformed = MCPDiscoverySSEDecoder()
        XCTAssertThrowsError(try Array("data: not-json\n\n".utf8).forEach { _ = try malformed.append($0) })
    }

    func testSSERejectsAnOversizedUnterminatedLine() throws {
        var decoder = MCPDiscoverySSEDecoder()
        for _ in 0..<MCPDiscoverySSEDecoder.maximumEventBytes { _ = try decoder.append(65) }
        XCTAssertThrowsError(try decoder.append(65))
    }

    private final class Harness {
        var requests: [URLRequest] = []
        var continuations: [AsyncThrowingStream<[String: Any], Error>.Continuation] = []
        var closed = Set<Int>()
        func open(_ request: URLRequest) -> MCPDiscoveryStream {
            let id = requests.count
            requests.append(request)
            let stream = AsyncThrowingStream<[String: Any], Error> { self.continuations.append($0) }
            return MCPDiscoveryStream(events: stream, cancel: { self.closed.insert(id) })
        }
    }

    private func waitFor(_ condition: () -> Bool) async throws {
        for _ in 0..<300 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTFail("Asynchronous discovery did not reach the expected state")
        throw MCPDiscoveryError.timedOut
    }

    func testSilentTransportActuallyTimesOutAndCloses() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(timeout: 0.04, keyProvider: { "fixture" }, transport: harness.open)
        let start = Date()
        do { _ = try await service.discover(config()); XCTFail("Expected timeout") }
        catch { XCTAssertEqual(error as? MCPDiscoveryError, .timedOut) }
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
        XCTAssertEqual(harness.closed, [0])
    }

    func testSharedDiscoveryCancellationDoesNotCancelOtherWaiterAndCachesSuccess() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(keyProvider: { "fixture" }, transport: harness.open)
        let configuration = try config()
        let first = Task { try await service.discover(configuration) }
        let second = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 1 }
        // Let both actor calls register before cancelling either consumer.
        try await Task.sleep(nanoseconds: 20_000_000)
        first.cancel()
        do { _ = try await first.value; XCTFail("Expected cancellation") } catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertTrue(harness.closed.isEmpty)
        harness.continuations[0].yield(catalog())
        let snapshot = try await second.value
        XCTAssertEqual(snapshot.tools.count, 1)
        XCTAssertEqual(harness.closed, [0])
        let cached = try await service.discover(configuration)
        XCTAssertEqual(cached, snapshot)
        XCTAssertEqual(harness.requests.count, 1)
    }

    func testLastWaiterCancellationClosesAndDoesNotCacheLateResults() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(keyProvider: { "fixture" }, transport: harness.open)
        let configuration = try config()
        let first = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 1 }
        first.cancel()
        _ = await first.result
        try await waitFor { harness.closed.contains(0) }
        harness.continuations[0].yield(catalog())
        let second = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 2 }
        harness.continuations[1].yield(catalog(tools: []))
        let snapshot = try await second.value
        XCTAssertTrue(snapshot.tools.isEmpty)
    }

    func testFailedRefreshInvalidatesOldSuccessAndDoesNotRetryAuthentication() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(keyProvider: { "fixture" }, transport: harness.open)
        let configuration = try config()
        let initial = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 1 }
        harness.continuations[0].yield(catalog())
        _ = try await initial.value
        let refresh = Task { try await service.discover(configuration, forceRefresh: true) }
        try await waitFor { harness.requests.count == 2 }
        harness.continuations[1].finish(throwing: MCPDiscoveryError.authentication)
        do { _ = try await refresh.value; XCTFail("Expected auth failure") }
        catch { XCTAssertEqual(error as? MCPDiscoveryError, .authentication) }
        let next = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 3 }
        harness.continuations[2].yield(catalog())
        _ = try await next.value
    }

    func testTransientUnavailableRetriesOnceAndClosesBothAttempts() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(keyProvider: { "fixture" }, transport: harness.open)
        let configuration = try config()
        let discovery = Task { try await service.discover(configuration) }
        try await waitFor { harness.requests.count == 1 }
        harness.continuations[0].finish(throwing: MCPDiscoveryError.unavailable)
        try await waitFor { harness.requests.count == 2 }
        harness.continuations[1].yield(catalog())
        _ = try await discovery.value
        XCTAssertEqual(harness.closed, [0, 1])
    }

    func testMissingAPIKeyNeverStartsTransport() async throws {
        let harness = Harness()
        let service = MCPDiscoveryService(keyProvider: { nil }, transport: harness.open)
        do { _ = try await service.discover(config()); XCTFail("Expected missing key") } catch { XCTAssertTrue(error is OpenAIServiceError) }
        XCTAssertTrue(harness.requests.isEmpty)
    }
}

@MainActor
final class ToolRowsTextAndFilesTests: XCTestCase {
    private func streaming() -> (ChatViewModel, ChatMessage) {
        let viewModel = ChatViewModel()
        let message = ChatMessage(role: .assistant, text: "")
        viewModel.messages = [message]
        viewModel.streamingMessageId = message.id
        return (viewModel, message)
    }

    private func feed(_ viewModel: ChatViewModel, _ events: [[String: Any]], to message: ChatMessage) throws {
        for var event in events {
            event["sequence_number"] = event["sequence_number"] ?? 0
            let chunk = try JSONDecoder().decode(StreamingEvent.self, from: JSONSerialization.data(withJSONObject: event))
            viewModel.handleStreamChunk(chunk, for: message.id)
        }
    }

    private func row(_ viewModel: ChatViewModel, _ id: String) -> ToolExecutionTimeline? {
        viewModel.messages.first?.toolTimeline?.first { $0.id == id }
    }

    // The API ends an item with response.output_item.done.  Before 2.9 only response.output_item.completed, which the
    // API never sends, closed a row, so every hosted tool showed Queued after it had finished.
    func testHostedToolRowsRunThenFinishOnOutputItemDone() throws {
        let (viewModel, message) = streaming()
        try feed(viewModel, [
            ["type": "response.output_item.added", "output_index": 0, "item": ["id": "ci_1", "type": "code_interpreter_call", "status": "in_progress"]],
            ["type": "response.output_item.added", "output_index": 1, "item": ["id": "ws_1", "type": "web_search_call", "status": "in_progress"]],
        ], to: message)
        XCTAssertEqual(row(viewModel, "ci_1")?.status, .queued)
        try feed(viewModel, [["type": "response.code_interpreter_call.interpreting", "item_id": "ci_1", "output_index": 0]], to: message)
        XCTAssertEqual(row(viewModel, "ci_1")?.status, .running)
        try feed(viewModel, [
            ["type": "response.output_item.done", "output_index": 0, "item": ["id": "ci_1", "type": "code_interpreter_call", "status": "completed"]],
            ["type": "response.output_item.done", "output_index": 1, "item": ["id": "ws_1", "type": "web_search_call", "status": "failed"]],
        ], to: message)
        XCTAssertEqual(row(viewModel, "ci_1")?.status, .completed)
        XCTAssertNotNil(row(viewModel, "ci_1")?.completedAt)
        XCTAssertEqual(row(viewModel, "ws_1")?.status, .failed)

        // A replayed event doesn't reopen a finished row.
        try feed(viewModel, [["type": "response.output_item.done", "output_index": 0, "item": ["id": "ci_1", "type": "code_interpreter_call", "status": "incomplete"]]], to: message)
        XCTAssertEqual(row(viewModel, "ci_1")?.status, .completed)
    }

    // A step's output is a failure when it starts with "Error".  The browser's failures read "Error processing …",
    // and a page that only mentions errors isn't one.
    func testAFunctionFailsWhenItsOutputStartsWithError() {
        XCTAssertTrue(ChatViewModel.functionOutputFailed("Error processing browserNavigate: Timed out waiting for navigation."))
        XCTAssertTrue(ChatViewModel.functionOutputFailed("Error: Browser tools are disabled in this chat."))
        XCTAssertTrue(ChatViewModel.functionOutputFailed("  error searching contacts"))
        XCTAssertFalse(ChatViewModel.functionOutputFailed(#"{"title":"2016 World Series","text":"Cleveland made 3 errors in Game 7"}"#))
    }

    // MCP's in_progress event names no tool, so its row stayed Queued until the end.  A tool execution error carries
    // content instead of a message, and the item didn't decode, so the row never showed Failed.
    func testMCPStepsRunThenFailOnAToolError() throws {
        let (viewModel, message) = streaming()
        let item: [String: Any] = ["id": "mcp_1", "type": "mcp_call", "name": "fetch", "server_label": "docs", "arguments": "{}"]
        try feed(viewModel, [["type": "response.output_item.added", "output_index": 0, "item": item]], to: message)
        XCTAssertEqual(row(viewModel, "mcp_1")?.status, .queued)
        try feed(viewModel, [["type": "response.mcp_call.in_progress", "item_id": "mcp_1", "output_index": 0]], to: message)
        XCTAssertEqual(row(viewModel, "mcp_1")?.status, .running)

        var failed = item
        failed["status"] = "failed"
        failed["error"] = ["type": "mcp_tool_execution_error", "content": [["type": "text", "text": "No page with that name."]]]
        let decoded = try JSONDecoder().decode(StreamingItem.self, from: JSONSerialization.data(withJSONObject: failed))
        XCTAssertEqual(decoded.error?.message, "No page with that name.")
        try feed(viewModel, [["type": "response.output_item.done", "output_index": 0, "item": failed]], to: message)
        XCTAssertEqual(row(viewModel, "mcp_1")?.status, .failed)
    }

    // A Code Interpreter step reads "Code Interpreter", not "code_interpreter_call", and opens to the Python it ran.
    func testCodeInterpreterStepShowsItsNameAndCode() throws {
        let (viewModel, message) = streaming()
        let code = "import matplotlib.pyplot as plt\nplt.pie([1450, 520, 180, 340, 95, 45])"
        try feed(viewModel, [
            ["type": "response.output_item.added", "output_index": 0, "item": ["id": "ci_1", "type": "code_interpreter_call", "status": "in_progress", "container_id": "cntr_1"]],
            ["type": "response.output_item.done", "output_index": 0, "item": ["id": "ci_1", "type": "code_interpreter_call", "status": "completed", "container_id": "cntr_1", "code": code]],
        ], to: message)
        XCTAssertEqual(row(viewModel, "ci_1")?.displayName, "Code Interpreter")
        XCTAssertEqual(row(viewModel, "ci_1")?.rawArguments, code)
        XCTAssertEqual(ToolExecutionTimeline(toolType: "function_call", toolName: "browserNavigate").displayName, "browserNavigate")
    }

    // The note the app shows when a tool fails is a placeholder until the model writes.  After two failures the text
    // still held only the first note, which no longer matched both joined, so it stayed above the answer.
    func testFailureNotesClearWhenTheAnswerStarts() throws {
        let (viewModel, message) = streaming()
        viewModel.recordFunctionOutputSummary("browserNavigate failed: Timed out waiting for navigation.", for: message.id)
        viewModel.recordFunctionOutputSummary("browserType failed: Timed out waiting for typing.", for: message.id)
        XCTAssertEqual(viewModel.messages.first?.text, "browserNavigate failed: Timed out waiting for navigation.")
        try feed(viewModel, [["type": "response.output_text.delta", "item_id": "msg_b", "output_index": 3, "content_index": 0, "delta": "The Chicago Cubs won in 2016."]], to: message)
        viewModel.flushDeltaBufferIfNeeded(for: message.id)
        XCTAssertEqual(viewModel.messages.first?.text, "The Chicago Cubs won in 2016.")
    }

    // Text after a tool call comes in a new output item.  Before 2.9 it ran straight on: "retrying.The Chicago Cubs".
    func testTextFromANewOutputItemStartsANewParagraph() throws {
        let (viewModel, message) = streaming()
        try feed(viewModel, [
            ["type": "response.output_text.delta", "item_id": "msg_a", "output_index": 0, "content_index": 0, "delta": "The page didn't load, so I'm retrying."],
            ["type": "response.output_text.delta", "item_id": "msg_b", "output_index": 2, "content_index": 0, "delta": "The Chicago Cubs won"],
            ["type": "response.output_text.delta", "item_id": "msg_b", "output_index": 2, "content_index": 0, "delta": " in 2016."],
        ], to: message)
        viewModel.flushDeltaBufferIfNeeded(for: message.id)
        XCTAssertEqual(viewModel.messages.first?.text, "The page didn't load, so I'm retrying.\n\nThe Chicago Cubs won in 2016.")
        XCTAssertEqual(ChatViewModel.paragraphBreak(after: ""), "")
        XCTAssertEqual(ChatViewModel.paragraphBreak(after: "Done.\n"), "\n")
        XCTAssertEqual(ChatViewModel.paragraphBreak(after: "Done.\n\n"), "")
    }

    // appendArtifact also puts a chart's picture in `images`, and the bubble drew both: every chart twice.  A reopened
    // conversation listed the chart again as "Content not loaded", and a saved text file lost its words.
    func testAChartShowsOnceAndSavedFilesKeepTheirText() throws {
        let viewModel = ChatViewModel()
        let message = ChatMessage(role: .assistant, text: "Here's the chart.")
        viewModel.messages = [message]
        let chart = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        viewModel.appendArtifact(CodeInterpreterArtifact(fileId: "cfile_chart", filename: "chart.png", containerId: "cntr_1", mimeType: "image/png", content: .image(chart)), to: message.id)
        viewModel.appendArtifact(CodeInterpreterArtifact(fileId: "cfile_csv", filename: "totals.csv", containerId: "cntr_1", mimeType: "text/csv", content: .text("name,total\nSam,19.20")), to: message.id)
        // The same file again from a sandbox link, once under its bare id: still one entry, under its real name.
        viewModel.appendArtifact(CodeInterpreterArtifact(fileId: "cfile_chart", filename: "cfile_chart.png", containerId: "cntr_1", mimeType: "image/png", content: .image(chart)), to: message.id)
        viewModel.appendArtifact(CodeInterpreterArtifact(fileId: "cfile_csv", filename: "totals.csv", containerId: "cntr_1", mimeType: "text/csv", content: .text("name,total\nSam,19.20")), to: message.id)
        let live = try XCTUnwrap(viewModel.messages.first)
        XCTAssertEqual(live.artifacts?.map(\.filename), ["chart.png", "totals.csv"])
        XCTAssertEqual(live.images?.count, 1)
        XCTAssertEqual(live.listedArtifacts.map(\.filename), ["totals.csv"])

        let reopened = try JSONDecoder().decode(ChatMessage.self, from: JSONEncoder().encode(live))
        XCTAssertEqual(reopened.images?.count, 1)
        XCTAssertEqual(reopened.listedArtifacts.map(\.filename), ["totals.csv"])
        XCTAssertEqual(reopened.listedArtifacts.first?.content.textContent, "name,total\nSam,19.20")

        // A chart that failed to load stays listed, so its error shows, even beside a picture that did load.
        var both = reopened
        both.artifacts?.append(CodeInterpreterArtifact(fileId: "cfile_x", filename: "second.png", containerId: "cntr_1", mimeType: "image/png", content: .error("Failed to load: timed out")))
        XCTAssertEqual(both.listedArtifacts.map(\.filename), ["totals.csv", "second.png"])
    }

    // A browser screenshot replaces the message's pictures, so a chart left out of the list because it was shown
    // above has to come back to the list once it isn't.
    func testAChartComesBackToTheListWhenAScreenshotReplacesIt() throws {
        let viewModel = ChatViewModel()
        let message = ChatMessage(role: .assistant, text: "")
        viewModel.messages = [message]
        let picture = { (color: UIColor) in
            UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
        }
        viewModel.appendArtifact(CodeInterpreterArtifact(fileId: "cfile_chart", filename: "chart.png", containerId: "cntr_1", mimeType: "image/png", content: .image(picture(.systemBlue))), to: message.id)
        XCTAssertTrue(try XCTUnwrap(viewModel.messages.first).listedArtifacts.isEmpty)
        viewModel.messages[0].images = [picture(.white)]
        XCTAssertEqual(viewModel.messages[0].listedArtifacts.map(\.filename), ["chart.png"])
    }

    // The newer-model path names an image step "Image Generation Call", with the agent after it for a subagent.
    func testManagedImageStepsUseTheToolsName() {
        let row = { (name: String) in ToolExecutionTimeline(toolType: "image_generation_call", toolName: name).displayName }
        XCTAssertEqual(row("image_generation_call"), "Image Generation")
        XCTAssertEqual(row("Image Generation Call"), "Image Generation")
        XCTAssertEqual(row("Image Generation Call · /researcher"), "Image Generation · /researcher")
        XCTAssertEqual(ToolExecutionTimeline(toolType: "web_search_call", toolName: "web_search_call").displayName, "Web Search")
    }

    // An MCP error sent as a bare string is read as its message instead of failing the whole item.
    func testAnMCPErrorSentAsTextStillDecodes() throws {
        let item: [String: Any] = ["id": "mcp_2", "type": "mcp_call", "name": "fetch", "server_label": "docs", "status": "failed", "error": "Server timed out"]
        let decoded = try JSONDecoder().decode(StreamingItem.self, from: JSONSerialization.data(withJSONObject: item))
        XCTAssertEqual(decoded.error?.message, "Server timed out")
    }

    // Reasoning summaries are Markdown.  The view drew "**Calculating tip distribution**" with its asterisks.
    func testReasoningSummariesShowTheirMarkdown() throws {
        let rendered = InlineMarkdown.attributed("**Calculating tip distribution**\n\nSam pays $19.20.")
        XCTAssertEqual(String(rendered.characters), "Calculating tip distribution\n\nSam pays $19.20.")
        let bold = try XCTUnwrap(rendered.runs.first?.inlinePresentationIntent)
        XCTAssertTrue(bold.contains(.stronglyEmphasized))
        XCTAssertEqual(String(InlineMarkdown.attributed("2 * 3 = 6").characters), "2 * 3 = 6")
    }

    // Code Interpreter keeps a plot it displayed as a file named by its own id, and code that also saved the figure
    // got the same chart shown twice.  One chart, from the saved file, whichever arrives first; two different charts stay.
    func testAChartCitedAsPlotAndSavedFileShowsOnce() throws {
        let pie = { (size: CGSize, slices: [CGFloat]) in
            UIGraphicsImageRenderer(size: size, format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }()).image { context in
                UIColor.white.setFill(); context.fill(CGRect(origin: .zero, size: size))
                let center = CGPoint(x: size.width / 2, y: size.height / 2), radius = size.height * 0.4
                var start: CGFloat = 0
                for (slice, color) in zip(slices, [UIColor.systemBlue, .systemGreen, .systemOrange, .systemRed]) {
                    let path = UIBezierPath()
                    path.move(to: center)
                    path.addArc(withCenter: center, radius: radius, startAngle: start, endAngle: start + slice * 2 * .pi, clockwise: true)
                    color.setFill(); path.fill()
                    start += slice * 2 * .pi
                }
            }
        }
        let shares: [CGFloat] = [0.55, 0.2, 0.13, 0.12]
        let plot = CodeInterpreterArtifact(fileId: "cfile_plot", filename: "cfile_plot.png", containerId: "cntr_1", mimeType: "image/png", content: .image(pie(CGSize(width: 90, height: 60), shares)))
        let saved = CodeInterpreterArtifact(fileId: "cfile_saved", filename: "monthly_spending_pie.png", containerId: "cntr_1", mimeType: "image/png", content: .image(pie(CGSize(width: 270, height: 180), shares)))
        XCTAssertTrue(ChatViewModel.isTwin(plot, of: saved))

        for order in [[plot, saved], [saved, plot]] {
            let viewModel = ChatViewModel()
            let message = ChatMessage(role: .assistant, text: "")
            viewModel.messages = [message]
            for artifact in order { viewModel.appendArtifact(artifact, to: message.id) }
            let shown = try XCTUnwrap(viewModel.messages.first)
            XCTAssertEqual(shown.artifacts?.map(\.filename), ["monthly_spending_pie.png"])
            XCTAssertEqual(shown.images?.count, 1)
            XCTAssertEqual(shown.images?.first?.size.width, 270)
            XCTAssertTrue(shown.listedArtifacts.isEmpty)
        }

        let other = CodeInterpreterArtifact(fileId: "cfile_other", filename: "cfile_other.png", containerId: "cntr_1", mimeType: "image/png", content: .image(pie(CGSize(width: 90, height: 60), [0.25, 0.25, 0.25, 0.25])))
        XCTAssertFalse(ChatViewModel.isTwin(other, of: saved))
    }
}
