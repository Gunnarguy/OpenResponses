import Foundation
import XCTest
@testable import OpenResponses

@MainActor
final class ChatViewModelLifecycleTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        _ = KeychainService.shared.save(value: "test-key", forKey: "openAIKey")
    }

    override func tearDown() {
        for directory in temporaryDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        temporaryDirectories.removeAll()
        _ = KeychainService.shared.delete(forKey: "openAIKey")
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        super.tearDown()
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

        XCTAssertTrue(await waitUntil {
            api.chatRequests.count == 1 && !viewModel.isStreaming
        })

        XCTAssertEqual(api.createConversationCalls.count, 1)
        XCTAssertEqual(api.chatRequests.first?.conversationId, "conv_remote_1")
        XCTAssertNil(api.chatRequests.first?.previousResponseId)
        XCTAssertEqual(viewModel.activeConversation?.remoteId, "conv_remote_1")
        XCTAssertEqual(viewModel.activeConversation?.syncState, .synced)
    }

    func testDeleteConversationRemovesRemoteConversationBeforeLocalCleanup() async {
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

        XCTAssertTrue(await waitUntil {
            api.deletedConversationIds == ["conv_remote_delete"] &&
            viewModel.conversations.allSatisfy { $0.id != conversation.id }
        })
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

        XCTAssertTrue(await waitUntil {
            !viewModel.isStreaming &&
            viewModel.messages.contains { $0.text == "Background work finished." }
        })

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
        XCTAssertTrue(viewModel.messages.last?.text?.contains("open a website") == true)
        XCTAssertTrue(viewModel.activePrompt.enableComputerUse)
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

        XCTAssertTrue(await waitUntil {
            viewModel.messages.contains { $0.text == "Background response in progress..." } ||
            !api.getResponseCalls.isEmpty
        })

        viewModel.cancelStreaming()

        XCTAssertTrue(await waitUntil {
            api.cancelResponseCalls == ["resp_background_cancel"] &&
            !viewModel.isStreaming &&
            viewModel.messages.contains { $0.text?.contains("cancelled by user") == true }
        })
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

        XCTAssertTrue(await waitUntil {
            api.sendFunctionOutputCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "The result is 4." }
        })

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

        XCTAssertTrue(await waitUntil {
            api.sendFunctionOutputCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "The result is 4." }
        })

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

        XCTAssertTrue(await waitUntil {
            api.sendFunctionOutputsCalls.count == 1 &&
            api.streamFunctionOutputsCalls.isEmpty &&
            viewModel.messages.contains { $0.text == "Batch results ready." }
        })

        XCTAssertEqual(api.sendFunctionOutputsCalls.first?.outputs.count, 2)
        XCTAssertNil(api.sendFunctionOutputsCalls.first?.previousResponseId)
        XCTAssertEqual(api.sendFunctionOutputsCalls.first?.conversationId, "conv_remote_batch")
    }

    private func makeViewModel(
        api: MockOpenAIService,
        backgroundPollIntervalNanoseconds: UInt64 = 10_000_000
    ) -> ChatViewModel {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        temporaryDirectories.append(directory)

        return ChatViewModel(
            api: api,
            storageService: ConversationStorageService(storageURL: directory),
            startBackgroundWork: false,
            backgroundPollIntervalNanoseconds: backgroundPollIntervalNanoseconds
        )
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

    private func waitUntil(
        timeout: TimeInterval = 1.0,
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

    func sendChatRequest(
        userMessage: String,
        prompt: Prompt,
        attachments: [[String : Any]]?,
        fileData: [Data]?,
        fileNames: [String]?,
        fileIds: [String]?,
        imageAttachments: [InputImage]?,
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
        previousResponseId: String?,
        conversationId: String?
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        AsyncThrowingStream { continuation in
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
        AsyncThrowingStream { continuation in
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
        AsyncThrowingStream { continuation in
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
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func probeMCPListTools(prompt: Prompt) async throws -> (label: String, count: Int) {
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

    func listModels() async throws -> [OpenAIModel] {
        []
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
}
