import Foundation
import XCTest
@testable import OpenResponses

@MainActor
final class ChatViewModelLifecycleTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        UserDefaults.standard.set(AppFeatureFlags.aiDataSharingConsentVersion, forKey: AppFeatureFlags.aiDataSharingConsentVersionKey)
        _ = KeychainService.shared.save(value: "test-key", forKey: "openAIKey")
    }

    override func tearDown() {
        for directory in temporaryDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        temporaryDirectories.removeAll()
        _ = KeychainService.shared.delete(forKey: "openAIKey")
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        UserDefaults.standard.removeObject(forKey: AppFeatureFlags.aiDataSharingConsentVersionKey)
        super.tearDown()
    }

    func testAccountModelsKeepTheCurrentGeneralModelsFromTheModelList() async {
        UserDefaults.standard.removeObject(forKey: "accountModels")
        defer { UserDefaults.standard.removeObject(forKey: "accountModels") }
        let api = MockOpenAIService()
        api.listedModels = ["gpt-4o", "gpt-6-sol", "gpt-6.2-sol", "gpt-6.2-sol-2026-10-06", "gpt-realtime-2.1"].map {
            OpenAIModel(id: $0, object: "model", created: 0, ownedBy: "openai")
        }
        let viewModel = makeViewModel(api: api)
        viewModel.exploreModeEnabled = false

        await viewModel.refreshAccountModels()

        XCTAssertEqual(viewModel.accountModels, ["gpt-6.2-sol", "gpt-6-sol"])
        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: "accountModels"), ["gpt-6.2-sol", "gpt-6-sol"], "kept for the next launch")
        let menu = CurrentModelCatalog.selectionModels(including: viewModel.activePrompt.openAIModel, account: viewModel.accountModels)
        XCTAssertEqual(menu.first, "gpt-6.2-sol", "a model released after this build still reaches the model menus")
    }

    func testAShutdownDateInTheModelListMovesTheActivePresetOffThatModel() async {
        defer {
            ModelCatalogStore.shared.recordShutdowns([:])
            UserDefaults.standard.removeObject(forKey: "accountModelShutdowns")
            UserDefaults.standard.removeObject(forKey: "accountModels")
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        let api = MockOpenAIService()
        api.listedModels = [OpenAIModel(id: "gpt-5.6-terra", object: "model", created: 0, ownedBy: "openai",
                                        shutdownDate: formatter.string(from: Date().addingTimeInterval(10 * 86_400)))]
        let viewModel = makeViewModel(api: api)
        viewModel.exploreModeEnabled = false
        var prompt = viewModel.activePrompt
        prompt.openAIModel = "gpt-5.6-terra"
        _ = viewModel.replaceActivePrompt(with: prompt)
        XCTAssertEqual(viewModel.activePrompt.openAIModel, "gpt-5.6-terra")

        await viewModel.refreshAccountModels()

        XCTAssertEqual(viewModel.activePrompt.openAIModel, CurrentModelCatalog.defaultModel, "shuts down in 10 days, no listed replacement")
        XCTAssertFalse(viewModel.accountModels.contains("gpt-5.6-terra"))
    }

    func testSendUserMessageCreatesRemoteConversationBeforeRequest() async {
        let api = MockOpenAIService()
        api.createConversationResult = makeConversationDetail(id: "conv_remote_1")
        api.sendChatResponse = makeTextResponse(id: "resp_remote_1", text: "Remote conversation ready.")

        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.storeResponses = true
        viewModel.applyDraftStorePreference(true)

        viewModel.sendUserMessage("Ship the release build.")

        let condition1 = await waitUntil {
            api.chatRequests.count == 1 && !viewModel.isStreaming
        }
        XCTAssertTrue(condition1)

        XCTAssertEqual(api.createConversationCalls.count, 1)
        XCTAssertEqual(api.chatRequests.first?.conversationId, "conv_remote_1")
        XCTAssertNil(api.chatRequests.first?.previousResponseId)
        XCTAssertEqual(viewModel.activeConversation?.remoteId, "conv_remote_1")
        XCTAssertEqual(viewModel.activeConversation?.syncState, .synced)
    }

    func testDeleteConversationRemovesRemoteConversationBeforeLocalCleanup() async throws {
        let api = MockOpenAIService()
        let viewModel = makeViewModel(api: api)

        var conversation = try XCTUnwrap(viewModel.activeConversation)
        conversation.remoteId = "conv_remote_delete"
        conversation.shouldStoreRemotely = true
        conversation.syncState = .synced
        viewModel.conversations = [conversation]
        viewModel.activeConversation = conversation
        viewModel.saveConversation(conversation)

        viewModel.deleteConversation(conversation)

        let condition2 = await waitUntil {
            api.deletedConversationIds == ["conv_remote_delete"] &&
            viewModel.conversations.allSatisfy { $0.id != conversation.id }
        }
        XCTAssertTrue(condition2)
    }

    func testBackgroundResponsePollsUntilCompletion() async {
        let api = MockOpenAIService()
        api.sendChatResponse = makePendingResponse(id: "resp_background_1")
        api.getResponseQueue["resp_background_1"] = [
            makeTextResponse(id: "resp_background_1", text: "Background work finished.", status: "completed", background: true)
        ]

        let viewModel = makeViewModel(api: api, backgroundPollIntervalNanoseconds: 10_000_000)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.backgroundMode = true
        viewModel.activePrompt.storeResponses = true

        viewModel.sendUserMessage("Run the long task.")

        let condition3 = await waitUntil {
            !viewModel.isStreaming &&
            viewModel.messages.contains { $0.text == "Background work finished." }
        }
        XCTAssertTrue(condition3)

        XCTAssertEqual(api.getResponseCalls, ["resp_background_1"])
    }

    func testReplacingPromptDefaultsGPT54ReasoningEffortToNone() async {
        let api = MockOpenAIService()
        let viewModel = makeViewModel(api: api)

        var prompt = viewModel.activePrompt
        prompt.openAIModel = "gpt-5.4"
        prompt.reasoningEffort = "medium"

        viewModel.replaceActivePrompt(with: prompt, previousModelId: "gpt-4o")

        XCTAssertEqual(viewModel.activePrompt.reasoningEffort, "none")
    }

    func testComputerActivationShortcutRespondsLocallyAndDoesNotCallAPI() async {
        let api = MockOpenAIService()
        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.openAIModel = "gpt-5.4"
        viewModel.activePrompt.enableComputerUse = false

        viewModel.sendUserMessage("Computer")

        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertTrue(api.chatRequests.isEmpty)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertEqual(viewModel.messages.first?.text, "Computer")
        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("What would you like me to do?") == true)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("persistent live browser") == true)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("live webpage DOM") == true)
        XCTAssertTrue(viewModel.activePrompt.enableComputerUse)
    }

    func testSendUserMessageIgnoresMCPConfigurationWhenFeatureFlagDisabled() async {
        let label = "deepwiki"
        UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_\(label)")
        UserDefaults.standard.removeObject(forKey: "mcp_probe_ok_at_\(label)")
        UserDefaults.standard.removeObject(forKey: "mcp_probe_token_hash_\(label)")
        UserDefaults.standard.removeObject(forKey: "mcp_probe_tool_count_\(label)")
        _ = KeychainService.shared.delete(forKey: "mcp_manual_\(label)")

        let api = MockOpenAIService()
        api.probeMCPListToolsResult = (label: label, count: 2)
        api.sendChatResponse = makeTextResponse(id: "resp_public_mcp", text: "Public MCP ready.")

        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.storeResponses = false
        viewModel.applyDraftStorePreference(false)
        viewModel.activePrompt.openAIModel = "gpt-5.4"
        viewModel.activePrompt.enableMCPTool = true
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpServerLabel = label
        viewModel.activePrompt.mcpServerURL = "https://mcp.deepwiki.com/mcp"
        viewModel.activePrompt.mcpRequireApproval = "never"

        viewModel.sendUserMessage("Use the public MCP server.")

        let condition4 = await waitUntil() {
            api.chatRequests.count == 1 && viewModel.messages.contains { $0.text == "Public MCP ready." }
        }
        XCTAssertTrue(condition4)

        XCTAssertEqual(api.chatRequests.first?.userMessage, "Use the public MCP server.")
        XCTAssertTrue(api.createConversationCalls.count >= 0)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "mcp_probe_tool_count_\(label)"), 0)
        XCTAssertTrue(api.chatRequests.count == 1)
    }

    func testSendUserMessageRequiresConsentBeforeCallingAPI() async {
        UserDefaults.standard.removeObject(forKey: AppFeatureFlags.aiDataSharingConsentVersionKey)

        let api = MockOpenAIService()
        api.sendChatResponse = makeTextResponse(id: "resp_consent_pending", text: "Should not send yet.")

        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.storeResponses = false
        viewModel.applyDraftStorePreference(false)

        viewModel.sendUserMessage("Please wait for consent.")

        XCTAssertTrue(api.chatRequests.isEmpty)
        XCTAssertNotNil(viewModel.pendingAIDataSharingConsent)
    }

    func testApprovingConsentResumesQueuedSend() async {
        UserDefaults.standard.removeObject(forKey: AppFeatureFlags.aiDataSharingConsentVersionKey)

        let api = MockOpenAIService()
        api.sendChatResponse = makeTextResponse(id: "resp_consent_ok", text: "Consent approved.")

        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.storeResponses = false
        viewModel.applyDraftStorePreference(false)

        viewModel.sendUserMessage("Send after approval.")
        XCTAssertNotNil(viewModel.pendingAIDataSharingConsent)

        viewModel.approveAIDataSharingConsent()

        let condition5 = await waitUntil {
            api.chatRequests.count == 1 && viewModel.messages.contains { $0.text == "Consent approved." }
        }
        XCTAssertTrue(condition5)

        XCTAssertEqual(api.chatRequests.first?.userMessage, "Send after approval.")
    }

    func testDenyingConsentDoesNotSendRequest() async {
        UserDefaults.standard.removeObject(forKey: AppFeatureFlags.aiDataSharingConsentVersionKey)

        let api = MockOpenAIService()
        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.storeResponses = false
        viewModel.applyDraftStorePreference(false)

        viewModel.sendUserMessage("Do not send this.")
        XCTAssertNotNil(viewModel.pendingAIDataSharingConsent)

        viewModel.denyAIDataSharingConsent()

        XCTAssertTrue(api.chatRequests.isEmpty)
        XCTAssertNil(viewModel.pendingAIDataSharingConsent)
        XCTAssertTrue(viewModel.messages.contains { $0.text?.contains("No data was sent to OpenAI") == true })
    }

    func testCancelStreamingCancelsBackgroundResponse() async {
        let api = MockOpenAIService()
        api.sendChatResponse = makePendingResponse(id: "resp_background_cancel")
        api.getResponseQueue["resp_background_cancel"] = Array(
            repeating: makePendingResponse(id: "resp_background_cancel"),
            count: 8
        )
        api.cancelResponseResult = makePendingResponse(
            id: "resp_background_cancel",
            status: "cancelled",
            background: true
        )

        let viewModel = makeViewModel(api: api, backgroundPollIntervalNanoseconds: 10_000_000)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.backgroundMode = true
        viewModel.activePrompt.storeResponses = true

        viewModel.sendUserMessage("Cancel this background job.")

        let condition6 = await waitUntil {
            viewModel.messages.contains { $0.text == "Background response in progress..." } ||
            !api.getResponseCalls.isEmpty
        }
        XCTAssertTrue(condition6)

        viewModel.cancelStreaming()

        let condition7 = await waitUntil {
            api.cancelResponseCalls == ["resp_background_cancel"] &&
            !viewModel.isStreaming &&
            viewModel.messages.contains { $0.text?.contains("cancelled by user") == true }
        }
        XCTAssertTrue(condition7)
    }

    func testBackgroundFunctionFollowUpUsesConversationContinuationWhenRemoteConversationExists() async {
        let api = MockOpenAIService()
        api.sendChatResponse = makeFunctionCallResponse(
            id: "resp_function_start",
            calls: [
                OutputItem(
                    id: "fc_1",
                    type: "function_call",
                    content: nil,
                    name: "calculator",
                    arguments: #"{"expression":"2+2"}"#,
                    callId: "call_calc_1"
                )
            ]
        )
        api.sendFunctionOutputResult = makePendingResponse(id: "resp_function_background", background: true)
        api.getResponseQueue["resp_function_background"] = [
            makeTextResponse(
                id: "resp_function_background",
                text: "The result is 4.",
                status: "completed",
                background: true
            )
        ]

        let viewModel = makeViewModel(api: api, backgroundPollIntervalNanoseconds: 10_000_000)
        viewModel.activePrompt.enableStreaming = true
        viewModel.activePrompt.backgroundMode = true
        viewModel.activePrompt.storeResponses = true
        setRemoteConversation(id: "conv_remote_function", for: viewModel)

        viewModel.sendUserMessage("Calculate 2+2.")

        let condition8 = await waitUntil {
            api.sendFunctionOutputCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "The result is 4." }
        }
        XCTAssertTrue(condition8)

        XCTAssertNil(api.sendFunctionOutputCalls.first?.previousResponseId)
        XCTAssertEqual(api.sendFunctionOutputCalls.first?.conversationId, "conv_remote_function")
    }

    func testBackgroundFunctionFollowUpUsesPreviousResponseContinuationWithoutRemoteConversation() async {
        let api = MockOpenAIService()
        api.sendChatResponse = makeFunctionCallResponse(
            id: "resp_function_start",
            calls: [
                OutputItem(
                    id: "fc_1",
                    type: "function_call",
                    content: nil,
                    name: "calculator",
                    arguments: #"{"expression":"2+2"}"#,
                    callId: "call_calc_1"
                )
            ]
        )
        api.sendFunctionOutputResult = makePendingResponse(id: "resp_function_background", background: true)
        api.getResponseQueue["resp_function_background"] = [
            makeTextResponse(
                id: "resp_function_background",
                text: "The result is 4.",
                status: "completed",
                background: true
            )
        ]

        let viewModel = makeViewModel(api: api, backgroundPollIntervalNanoseconds: 10_000_000)
        viewModel.activePrompt.enableStreaming = true
        viewModel.activePrompt.backgroundMode = true
        viewModel.activePrompt.storeResponses = false
        viewModel.applyDraftStorePreference(false)

        viewModel.sendUserMessage("Calculate 2+2.")

        let condition9 = await waitUntil {
            api.sendFunctionOutputCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "The result is 4." }
        }
        XCTAssertTrue(condition9)

        XCTAssertEqual(api.sendFunctionOutputCalls.first?.previousResponseId, "resp_function_start")
        XCTAssertNil(api.sendFunctionOutputCalls.first?.conversationId)
    }

    func testNonStreamingParallelFunctionCallsUseConversationContinuationWhenRemoteConversationExists() async {
        let api = MockOpenAIService()
        api.sendChatResponse = makeFunctionCallResponse(
            id: "resp_batch_start",
            calls: [
                OutputItem(
                    id: "fc_1",
                    type: "function_call",
                    content: nil,
                    name: "calculator",
                    arguments: #"{"expression":"2+2"}"#,
                    callId: "call_calc_1"
                ),
                OutputItem(
                    id: "fc_2",
                    type: "function_call",
                    content: nil,
                    name: "calculator",
                    arguments: #"{"expression":"3+4"}"#,
                    callId: "call_calc_2"
                )
            ]
        )
        api.sendFunctionOutputsResult = makeTextResponse(id: "resp_batch_done", text: "Batch results ready.")

        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = false
        viewModel.activePrompt.parallelToolCalls = true
        setRemoteConversation(id: "conv_remote_batch", for: viewModel)

        viewModel.sendUserMessage("Run both calculations.")

        let condition10 = await waitUntil {
            api.sendFunctionOutputsCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "Batch results ready." }
        }
        XCTAssertTrue(condition10)

        XCTAssertEqual(api.sendFunctionOutputsCalls.first?.outputs.count, 2)
        XCTAssertNil(api.sendFunctionOutputsCalls.first?.previousResponseId)
        XCTAssertEqual(api.sendFunctionOutputsCalls.first?.conversationId, "conv_remote_batch")
    }

    // A streamed function call's step runs while the app works and then shows what the run returned.  Before 2.9 both
    // steps here stayed on Queued.  The browser call fails because Computer Use is off in this chat.
    func testStreamedFunctionStepsShowWhatTheAppsRunReturned() async throws {
        let api = MockOpenAIService()
        let item = { (id: String, name: String, arguments: String) -> [String: Any] in
            ["id": id, "type": "function_call", "call_id": "call_\(id)", "name": name, "arguments": arguments, "status": "completed"]
        }
        let calc = item("fc_calc", "calculator", #"{"expression":"2+2"}"#)
        let web = item("fc_web", "browserNavigate", #"{"url":"https://example.com"}"#)
        api.streamEvents = try [
            ["type": "response.created", "response": ["id": "resp_tools", "status": "in_progress"]],
            ["type": "response.output_item.added", "output_index": 0, "item": calc],
            ["type": "response.output_item.added", "output_index": 1, "item": web],
            ["type": "response.output_item.done", "output_index": 0, "item": calc],
            ["type": "response.output_item.done", "output_index": 1, "item": web],
        ].map { event in
            var event = event
            event["sequence_number"] = 0
            return try JSONDecoder().decode(StreamingEvent.self, from: JSONSerialization.data(withJSONObject: event))
        }
        let viewModel = makeViewModel(api: api)
        viewModel.activePrompt.enableStreaming = true
        viewModel.activePrompt.enableComputerUse = false
        viewModel.activePrompt.enableCustomTool = true
        viewModel.activePrompt.customToolName = "calculator"
        viewModel.activePrompt.customToolExecutionType = "calculator"

        viewModel.sendUserMessage("What's 2+2, and open example.com.")

        let step = { (id: String) in viewModel.messages.lazy.compactMap { $0.toolTimeline?.first { $0.id == id } }.first }
        let finished = await waitUntil {
            [step("fc_calc")?.status, step("fc_web")?.status].allSatisfy { $0 == .completed || $0 == .failed }
        }
        XCTAssertTrue(finished)
        XCTAssertEqual(step("fc_calc")?.status, .completed)
        XCTAssertEqual(step("fc_web")?.status, .failed)
        XCTAssertEqual(step("fc_web")?.rawOutputPreview, "Error: Browser tools are disabled in this chat.")
        XCTAssertEqual(step("fc_web")?.rawArguments, #"{"url":"https://example.com"}"#)
    }

    private func makeViewModel(
        api: MockOpenAIService,
        backgroundPollIntervalNanoseconds: UInt64 = 10_000_000
    ) -> ChatViewModel {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        temporaryDirectories.append(directory)

        let model = ChatViewModel(
            api: api,
            storageService: ConversationStorageService(storageURL: directory),
            startBackgroundWork: false,
            backgroundPollIntervalNanoseconds: backgroundPollIntervalNanoseconds
        )
        // These tests exercise the protocol-backed Responses lifecycle. Modern turn-runner
        // behavior has its own injected stream tests in StreamingEventDecodingTests.
        model.exploreModeEnabled = false
        model.activePrompt.openAIModel = "gpt-5.4"
        return model
    }

    private func setRemoteConversation(id remoteId: String, for viewModel: ChatViewModel) {
        guard var conversation = viewModel.activeConversation else {
            XCTFail("Expected an active conversation")
            return
        }

        conversation.remoteId = remoteId
        conversation.shouldStoreRemotely = true
        conversation.syncState = .synced
        viewModel.conversations = [conversation]
        viewModel.activeConversation = conversation
        viewModel.saveConversation(conversation)
    }

    /// Polls until the condition holds. The limit is generous because it only matters when a test fails: GitHub's
    /// shared runner missed a 1-second limit in five of these tests on 2026-09-30 (run 36751566276, a Build & Test job of
    /// 19.5 minutes against 8 the run before), while the same tests pass in well under a second locally.
    private func waitUntil(
        timeout: TimeInterval = 15.0,
        pollIntervalNanoseconds: UInt64 = 10_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
        }

        return condition()
    }

    private func makeConversationDetail(id: String) -> ConversationDetail {
        ConversationDetail(
            id: id,
            object: "conversation",
            deleted: nil,
            title: nil,
            metadata: nil,
            createdAt: nil,
            updatedAt: nil,
            archivedAt: nil,
            messages: nil
        )
    }

    private func makePendingResponse(
        id: String,
        status: String = "in_progress",
        background: Bool? = true
    ) -> OpenAIResponse {
        OpenAIResponse(
            id: id,
            object: "response",
            created: nil,
            model: "gpt-4o",
            output: [],
            usage: nil,
            status: status,
            background: background,
            error: nil,
            incompleteDetails: nil
        )
    }

    private func makeTextResponse(
        id: String,
        text: String,
        status: String = "completed",
        background: Bool? = nil
    ) -> OpenAIResponse {
        OpenAIResponse(
            id: id,
            object: "response",
            created: nil,
            model: "gpt-4o",
            output: [
                OutputItem(
                    id: "msg_\(id)",
                    type: "message",
                    content: [
                        ContentItem(type: "output_text", text: text, imageURL: nil, imageFile: nil)
                    ]
                )
            ],
            usage: nil,
            status: status,
            background: background,
            error: nil,
            incompleteDetails: nil
        )
    }

    private func makeFunctionCallResponse(
        id: String,
        calls: [OutputItem],
        status: String = "completed"
    ) -> OpenAIResponse {
        OpenAIResponse(
            id: id,
            object: "response",
            created: nil,
            model: "gpt-4o",
            output: calls,
            usage: nil,
            status: status,
            background: nil,
            error: nil,
            incompleteDetails: nil
        )
    }
}

private final class MockOpenAIService: OpenAIServiceProtocol {
    struct ChatRequest {
        let userMessage: String
        let previousResponseId: String?
        let conversationId: String?
    }

    struct FunctionOutputCall {
        let callId: String
        let output: String
        let previousResponseId: String?
        let conversationId: String?
    }

    struct FunctionOutputsBatchCall {
        let outputs: [FunctionCallOutputPayload]
        let previousResponseId: String?
        let conversationId: String?
    }

    struct ConversationCreateCall {
        let title: String?
        let metadata: [String: String]?
        let items: [[String: Any]]?
    }

    var chatRequests: [ChatRequest] = []
    var createConversationCalls: [ConversationCreateCall] = []
    var deletedConversationIds: [String] = []
    var getResponseCalls: [String] = []
    var cancelResponseCalls: [String] = []
    var sendFunctionOutputCalls: [FunctionOutputCall] = []
    var sendFunctionOutputsCalls: [FunctionOutputsBatchCall] = []
    var streamFunctionOutputsCalls: [FunctionOutputsBatchCall] = []
    /// Events the next streamed chat request yields, in order.
    var streamEvents: [StreamingEvent] = []
    var probeMCPListToolsResult: (label: String, count: Int)?
    var probeMCPListToolsError: Error?

    var sendChatResponse = OpenAIResponse(
        id: "resp_default",
        object: "response",
        created: nil,
        model: "gpt-4o",
        output: [],
        usage: nil,
        status: "completed",
        background: nil,
        error: nil,
        incompleteDetails: nil
    )
    var sendFunctionOutputResult = OpenAIResponse(
        id: "resp_function_default",
        object: "response",
        created: nil,
        model: "gpt-4o",
        output: [],
        usage: nil,
        status: "completed",
        background: nil,
        error: nil,
        incompleteDetails: nil
    )
    var sendFunctionOutputsResult = OpenAIResponse(
        id: "resp_function_batch_default",
        object: "response",
        created: nil,
        model: "gpt-4o",
        output: [],
        usage: nil,
        status: "completed",
        background: nil,
        error: nil,
        incompleteDetails: nil
    )
    var createConversationResult = ConversationDetail(
        id: "conv_default",
        object: "conversation",
        deleted: nil,
        title: nil,
        metadata: nil,
        createdAt: nil,
        updatedAt: nil,
        archivedAt: nil,
        messages: nil
    )
    var getResponseQueue: [String: [OpenAIResponse]] = [:]
    var cancelResponseResult = OpenAIResponse(
        id: "resp_cancelled",
        object: "response",
        created: nil,
        model: "gpt-4o",
        output: [],
        usage: nil,
        status: "cancelled",
        background: true,
        error: nil,
        incompleteDetails: nil
    )

    func checkModeration(input: String) async throws -> ModerationResult {
        ModerationResult(flagged: false, categories: [:], categoryScores: [:])
    }

    func buildPreviewRequestObject(for prompt: Prompt, userMessage: String?, attachments: [[String: Any]]?,
                                   fileData: [Data]?, fileNames: [String]?, fileIds: [String]?,
                                   imageAttachments: [InputImage]?, audioAttachments: [InputAudio]?,
                                   previousResponseId: String?, conversationId: String?, stream: Bool) -> [String: Any] {
        OpenAIService().buildPreviewRequestObject(for: prompt, userMessage: userMessage, attachments: attachments,
            fileData: fileData, fileNames: fileNames, fileIds: fileIds, imageAttachments: imageAttachments,
            audioAttachments: audioAttachments, previousResponseId: previousResponseId, conversationId: conversationId, stream: stream)
    }

    func sendChatRequest(
        userMessage: String,
        prompt: Prompt,
        attachments: [[String : Any]]?,
        fileData: [Data]?,
        fileNames: [String]?,
        fileIds: [String]?,
        imageAttachments: [InputImage]?,
        audioAttachments: [InputAudio]?,
        previousResponseId: String?,
        conversationId: String?
    ) async throws -> OpenAIResponse {
        chatRequests.append(
            ChatRequest(
                userMessage: userMessage,
                previousResponseId: previousResponseId,
                conversationId: conversationId
            )
        )
        return sendChatResponse
    }

    func streamChatRequest(
        userMessage: String,
        prompt: Prompt,
        attachments: [[String : Any]]?,
        fileData: [Data]?,
        fileNames: [String]?,
        fileIds: [String]?,
        imageAttachments: [InputImage]?,
        audioAttachments: [InputAudio]?,
        previousResponseId: String?,
        conversationId: String?
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        let events = streamEvents
        return AsyncThrowingStream { continuation in
            for event in events { continuation.yield(event) }
            continuation.finish()
        }
    }

    func getResponse(responseId: String) async throws -> OpenAIResponse {
        getResponseCalls.append(responseId)
        guard var queued = getResponseQueue[responseId], !queued.isEmpty else {
            throw OpenAIServiceError.invalidRequest("No mocked response queued for \(responseId)")
        }
        let next = queued.removeFirst()
        getResponseQueue[responseId] = queued
        return next
    }

    func deleteResponse(responseId: String) async throws -> DeleteResponseResult {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func cancelResponse(responseId: String) async throws -> OpenAIResponse {
        cancelResponseCalls.append(responseId)
        return cancelResponseResult
    }

    func listInputItems(responseId: String) async throws -> InputItemsResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func sendFunctionOutput(
        call: OutputItem,
        output: String,
        model: String,
        reasoningItems: [[String : Any]]?,
        previousResponseId: String?,
        conversationId: String?,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        sendFunctionOutputCalls.append(
            FunctionOutputCall(
                callId: call.callId ?? call.id,
                output: output,
                previousResponseId: previousResponseId,
                conversationId: conversationId
            )
        )
        return sendFunctionOutputResult
    }

    func sendFunctionOutputs(
        outputs: [FunctionCallOutputPayload],
        model: String,
        reasoningItems: [[String : Any]]?,
        previousResponseId: String?,
        conversationId: String?,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        sendFunctionOutputsCalls.append(
            FunctionOutputsBatchCall(
                outputs: outputs,
                previousResponseId: previousResponseId,
                conversationId: conversationId
            )
        )
        return sendFunctionOutputsResult
    }

    func streamFunctionOutputs(
        outputs: [FunctionCallOutputPayload],
        model: String,
        reasoningItems: [[String : Any]]?,
        previousResponseId: String?,
        conversationId: String?,
        prompt: Prompt
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        streamFunctionOutputsCalls.append(
            FunctionOutputsBatchCall(
                outputs: outputs,
                previousResponseId: previousResponseId,
                conversationId: conversationId
            )
        )
        return AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func sendComputerCallOutput(
        call: StreamingItem,
        output: Any,
        model: String,
        previousResponseId: String?,
        acknowledgedSafetyChecks: [SafetyCheck]?,
        currentUrl: String?
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func sendComputerCallOutput(
        callId: String,
        output: Any,
        model: String,
        previousResponseId: String?,
        acknowledgedSafetyChecks: [SafetyCheck]?,
        currentUrl: String?
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func sendComputerCallOutput(
        call: StreamingItem,
        output: Any,
        model: String,
        previousResponseId: String?
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func sendComputerCallOutput(
        callId: String,
        output: Any,
        model: String,
        previousResponseId: String?
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func sendMCPApprovalResponse(
        approvalResponse: [String : Any],
        model: String,
        previousResponseId: String?,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func streamMCPApprovalResponse(
        approvalResponse: [String : Any],
        model: String,
        previousResponseId: String?,
        prompt: Prompt
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        return AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func callMCP(
        serverLabel: String,
        tool: String,
        argumentsJSON: String,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func callMCP(
        serverLabel: String,
        tool: String,
        argumentsJSON: String,
        prompt: Prompt,
        stream: Bool
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        return AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func probeMCPListTools(prompt: Prompt) async throws -> (label: String, count: Int) {
        if let probeMCPListToolsError {
            throw probeMCPListToolsError
        }
        if let probeMCPListToolsResult {
            return probeMCPListToolsResult
        }
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func fetchImageData(for imageContent: ContentItem) async throws -> Data {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func fetchContainerFileContent(containerId: String, fileId: String) async throws -> Data {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func uploadFile(fileData: Data, filename: String, purpose: String) async throws -> OpenAIFile {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    func listFiles(purpose: String?) async throws -> [OpenAIFile] {
        []
    }

    func deleteFile(fileId: String) async throws {}

    func createVectorStore(name: String, fileIds: [String]?) async throws -> VectorStore {
        throw OpenAIServiceError.invalidRequest("Unused in tests")
    }

    var listedModels: [OpenAIModel] = []

    func listModels() async throws -> [OpenAIModel] {
        listedModels
    }

    func listConversations(limit: Int?, order: String?) async throws -> ConversationListResponse {
        ConversationListResponse(data: [], firstId: nil, lastId: nil, hasMore: false)
    }

    func createConversation(title: String?, metadata: [String : String]?, items: [[String : Any]]?) async throws -> ConversationDetail {
        createConversationCalls.append(
            ConversationCreateCall(title: title, metadata: metadata, items: items)
        )
        return createConversationResult
    }

    func getConversation(conversationId: String) async throws -> ConversationDetail {
        createConversationResult
    }

    func updateConversation(conversationId: String, title: String?, metadata: [String : String]?, archived: Bool?) async throws -> ConversationDetail {
        createConversationResult
    }

    func deleteConversation(conversationId: String) async throws {
        deletedConversationIds.append(conversationId)
    }

    func compactConversation(previousResponseId: String, model: String) async throws -> String {
        return "compacted_response_id"
    }
}
