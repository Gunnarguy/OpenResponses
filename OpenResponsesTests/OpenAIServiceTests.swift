//
//  OpenAIServiceTests.swift
//  OpenResponsesTests
//

@testable import OpenResponses
import XCTest

final class OpenAIServiceTests: XCTestCase {
    private var service: OpenAIService!

    override func setUp() {
        super.setUp()
        service = OpenAIService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    private func buildRequest(
        prompt: Prompt,
        message: String = "Hello",
        stream: Bool = false,
        previousResponseID: String? = nil,
        conversationID: String? = nil
    ) -> [String: Any] {
        service.testing_buildRequestObject(
            for: prompt,
            userMessage: message,
            previousResponseId: previousResponseID,
            conversationId: conversationID,
            stream: stream
        )
    }

    private func buildFunctionOutputsRequest(
        prompt: Prompt = .defaultPrompt(),
        model: String = "gpt-4o",
        previousResponseID: String? = nil,
        conversationID: String? = nil
    ) throws -> [String: Any] {
        try service.testing_buildFunctionOutputsRequestObject(
            outputs: [
                FunctionCallOutputPayload(
                    callId: "call_123",
                    output: #"{"status":"ok"}"#,
                    functionName: "fetchAppleReminders",
                    callItem: nil
                )
            ],
            model: model,
            previousResponseId: previousResponseID,
            conversationId: conversationID,
            prompt: prompt
        )
    }

    private func buildComputerCallOutputRequest(
        model: String,
        currentURL: String? = "https://example.com/path"
    ) throws -> [String: Any] {
        try service.testing_buildComputerCallOutputRequestObject(
            callId: "call_123",
            output: [
                "type": "computer_screenshot",
                "image_url": "data:image/png;base64,abcd",
            ],
            model: model,
            previousResponseId: "resp_123",
            acknowledgedSafetyChecks: nil,
            currentUrl: currentURL
        )
    }

    func testRequestIncludesModelAndStreamFlag() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-4o"

        let request = buildRequest(prompt: prompt, message: "Hi", stream: true)

        XCTAssertEqual(request["model"] as? String, "gpt-4o")
        XCTAssertEqual(request["stream"] as? Bool, true)

        let input = request["input"] as? [[String: Any]]
        XCTAssertEqual(input?.count, 1)
        let userMessage = input?.first
        XCTAssertEqual(userMessage?["role"] as? String, "user")

        if let content = userMessage?["content"] as? [[String: Any]] {
            XCTAssertEqual(content.first?["type"] as? String, "input_text")
            XCTAssertEqual(content.first?["text"] as? String, "Hi")
        } else {
            XCTFail("User content should use structured array")
        }
    }

    func testRequestAddsStableAutomaticPromptCacheKey() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"

        let first = buildRequest(prompt: prompt)
        let second = buildRequest(prompt: prompt)

        let expected = "openresponses:prompt:\(prompt.id.uuidString.lowercased())"
        XCTAssertEqual(first["prompt_cache_key"] as? String, expected)
        XCTAssertEqual(second["prompt_cache_key"] as? String, expected)
    }

    func testExplicitPromptCacheKeyOverridesAutomaticKey() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.promptCacheKey = "tenant:acme:assistant-v2"

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(
            request["prompt_cache_key"] as? String,
            "tenant:acme:assistant-v2"
        )
    }

    @MainActor
    func testLegacyNumericPromptCacheTTLNormalizesToCurrentValue() throws {
        let data = Data(#"{"mode":"implicit","ttl":30}"#.utf8)
        let options = try JSONDecoder().decode(PromptCacheOptions.self, from: data)

        XCTAssertEqual(options.mode, "implicit")
        XCTAssertEqual(options.ttl, "30m")
    }

    func testModelAliasNormalizationForAPI() {
        var prompt = Prompt.defaultPrompt()

        prompt.openAIModel = "gpt-5.5-thinking"
        XCTAssertEqual(buildRequest(prompt: prompt)["model"] as? String, "gpt-5.5")

        prompt.openAIModel = "gpt-5.4-thinking-mini"
        XCTAssertEqual(buildRequest(prompt: prompt)["model"] as? String, "gpt-5.4-mini")
    }

    func testModelAliasNormalizationAlsoDrivesCapabilityChecks() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4-thinking"
        prompt.reasoningEffort = "none"
        prompt.temperature = 0.42
        prompt.enableComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the computer", stream: true)

        XCTAssertEqual(request["model"] as? String, "gpt-5.4")
        XCTAssertEqual(request["temperature"] as? Double, 0.42)

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools for normalized alias")
        }
        XCTAssertTrue(tools.contains { $0["type"] as? String == "computer" })
    }

    func testDatedSnapshotModelUsesBaseFamilyCapabilitiesWithoutChangingModelId() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4-mini-2026-05-28"
        prompt.enableComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the computer", stream: true)

        XCTAssertEqual(request["model"] as? String, "gpt-5.4-mini-2026-05-28")
        let tools = (request["tools"] as? [[String: Any]]) ?? []
        XCTAssertTrue(tools.contains { $0["type"] as? String == "computer" })
    }

    func testProAliasNormalizesButKeepsComputerDisabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4-thinking-pro"
        prompt.enableComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the computer", stream: true)

        XCTAssertEqual(request["model"] as? String, "gpt-5.4-pro")
        let tools = (request["tools"] as? [[String: Any]]) ?? []
        XCTAssertFalse(tools.contains { $0["type"] as? String == "computer" })
    }

    func testDeveloperInstructionsAppearBeforeUserMessage() {
        var prompt = Prompt.defaultPrompt()
        prompt.developerInstructions = "Be concise."

        let request = buildRequest(prompt: prompt, message: "Summarize this")

        guard let input = request["input"] as? [[String: Any]] else {
            return XCTFail("Input array missing")
        }

        XCTAssertEqual(input.first?["role"] as? String, "developer")
        XCTAssertEqual(input.first?["content"] as? String, "Be concise.")
        XCTAssertEqual(input.last?["role"] as? String, "user")
    }

    func testTemperatureIncludedWhenSupported() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-4o"
        prompt.temperature = 0.42

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["temperature"] as? Double, 0.42)
    }

    func testGPT54OmitsSamplingParametersWhenReasoningIsEnabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.reasoningEffort = "medium"
        prompt.temperature = 0.42
        prompt.topP = 0.25

        let request = buildRequest(prompt: prompt)

        XCTAssertNil(request["temperature"])
        XCTAssertNil(request["top_p"])
    }

    func testGPT54IncludesSamplingParametersWhenReasoningIsNone() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.reasoningEffort = "none"
        prompt.temperature = 0.42
        prompt.topP = 0.25

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["temperature"] as? Double, 0.42)
        XCTAssertEqual(request["top_p"] as? Double, 0.25)
    }

    func testGPT55OmitsSamplingParametersWhenReasoningIsEnabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.5"
        prompt.reasoningEffort = "high"
        prompt.temperature = 0.42
        prompt.topP = 0.25

        let request = buildRequest(prompt: prompt)

        XCTAssertNil(request["temperature"])
        XCTAssertNil(request["top_p"])
    }

    func testGPT55IncludesSamplingParametersWhenReasoningIsNone() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.5"
        prompt.reasoningEffort = "none"
        prompt.temperature = 0.42
        prompt.topP = 0.25

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["temperature"] as? Double, 0.42)
        XCTAssertEqual(request["top_p"] as? Double, 0.25)
    }

    func testMaxOutputTokensIncluded() {
        var prompt = Prompt.defaultPrompt()
        prompt.maxOutputTokens = 1500

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["max_output_tokens"] as? Int, 1500)
    }

    func testReasoningPayloadForReasoningModel() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4-mini"
        prompt.reasoningEffort = "high"
        prompt.reasoningSummary = "concise"

        let request = buildRequest(prompt: prompt)

        let reasoning = request["reasoning"] as? [String: Any]
        XCTAssertEqual(reasoning?["effort"] as? String, "high")
        XCTAssertEqual(reasoning?["summary"] as? String, "concise")
    }

    func testAppleInstructionsExplainLocalTimeAndReminderCompletionDefault() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableAppleIntegrations = true

        let request = buildRequest(prompt: prompt)
        let instructions = request["instructions"] as? String

        XCTAssertTrue(instructions?.contains("device's local time zone") == true)
        XCTAssertTrue(instructions?.contains("omit the `completed` filter") == true)
    }

    func testToolsIncludeCodeInterpreterWhenEnabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableCodeInterpreter = true
        prompt.enableImageGeneration = false
        prompt.enableWebSearch = false
        prompt.enableFileSearch = false

        let request = buildRequest(prompt: prompt, message: "Calculate area")

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }

        XCTAssertTrue(tools.contains { $0["type"] as? String == "code_interpreter" })
    }

    func testCodeInterpreterPreloadFileIdsAreNestedUnderContainer() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-4o"
        prompt.enableCodeInterpreter = true
        prompt.codeInterpreterPreloadFileIds = "file_a, file_b"
        prompt.enableImageGeneration = false
        prompt.enableWebSearch = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Analyze files")

        guard let tools = request["tools"] as? [[String: Any]],
              let codeInterpreter = tools.first(where: { $0["type"] as? String == "code_interpreter" }),
              let container = codeInterpreter["container"] as? [String: Any]
        else {
            return XCTFail("Expected code_interpreter tool with nested container")
        }

        XCTAssertEqual(container["type"] as? String, "auto")
        XCTAssertEqual(container["file_ids"] as? [String], ["file_a", "file_b"])
        XCTAssertNil(codeInterpreter["file_ids"])
    }

    func testGPT54ComputerToolUsesGAShape() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.enableComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the computer", stream: true)

        guard let tools = request["tools"] as? [[String: Any]],
              let computerTool = tools.first(where: { $0["type"] as? String == "computer" })
        else {
            return XCTFail("Expected GA computer tool payload")
        }

        XCTAssertNil(computerTool["display_width"])
        XCTAssertNil(computerTool["display_height"])
        XCTAssertNil(computerTool["environment"])
    }

    func testComputerUseAlsoAddsLiveBrowserFunctionTools() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.enableComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the browser", stream: true)

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }

        let functionNames = Set(
            tools
                .filter { $0["type"] as? String == "function" }
                .compactMap { $0["name"] as? String }
        )

        XCTAssertTrue(functionNames.contains("browserNavigate"))
        XCTAssertTrue(functionNames.contains("browserRead"))
        XCTAssertTrue(functionNames.contains("browserSearch"))
        XCTAssertTrue(functionNames.contains("browserClick"))
        XCTAssertTrue(functionNames.contains("browserType"))
        XCTAssertTrue(functionNames.contains("browserScroll"))

        let instructions = request["instructions"] as? String
        XCTAssertTrue(instructions?.contains("Prefer the live browser function tools") == true)
    }

    func testUltraStrictComputerUseSkipsLiveBrowserFunctionTools() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-5.4"
        prompt.enableComputerUse = true
        prompt.ultraStrictComputerUse = true
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false

        let request = buildRequest(prompt: prompt, message: "Use the browser", stream: true)

        let tools = (request["tools"] as? [[String: Any]]) ?? []
        let functionNames = Set(
            tools
                .filter { $0["type"] as? String == "function" }
                .compactMap { $0["name"] as? String }
        )

        XCTAssertFalse(functionNames.contains("browserNavigate"))
        XCTAssertFalse(functionNames.contains("browserRead"))
        XCTAssertTrue(tools.contains { $0["type"] as? String == "computer" })
    }


    func testGPT54ComputerCallOutputOmitsCurrentURLAndUsesOriginalDetail() throws {
        let request = try buildComputerCallOutputRequest(model: "gpt-5.4")

        guard let input = request["input"] as? [[String: Any]],
              let computerOutput = input.first,
              let output = computerOutput["output"] as? [String: Any] else {
            return XCTFail("Expected computer_call_output request payload")
        }

        XCTAssertEqual(computerOutput["type"] as? String, "computer_call_output")
        XCTAssertEqual(computerOutput["call_id"] as? String, "call_123")
        XCTAssertNil(computerOutput["current_url"])
        XCTAssertEqual(output["type"] as? String, "computer_screenshot")
        XCTAssertEqual(output["detail"] as? String, "original")
        XCTAssertNil(request["truncation"])

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }
        XCTAssertEqual(tools.first?["type"] as? String, "computer")
    }

    func testComputerCallOutputNormalizesModelAlias() throws {
        let request = try buildComputerCallOutputRequest(model: "gpt-5.4-thinking")

        XCTAssertEqual(request["model"] as? String, "gpt-5.4")

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }
        XCTAssertEqual(tools.first?["type"] as? String, "computer")
    }


    func testMCPConnectorToolNotIncludedWhenAuthorizationMissing() {
        // Regression test: OpenAI requires `authorization` whenever `connector_id` is specified.
        // If missing, the whole request fails with HTTP 400.
        let connectorId = "connector_dropbox"
        let authKey = "mcp_connector_\(connectorId)"
        _ = KeychainService.shared.delete(forKey: authKey)

        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = true
        prompt.mcpConnectorId = connectorId
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableWebSearch = false
        prompt.enableCodeInterpreter = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false

        let request = buildRequest(prompt: prompt, message: "Use MCP tools")

        // If the connector tool is skipped and there are no other enabled tools, the request may omit
        // the `tools` field entirely. Treat missing tools as an empty list.
        let tools = (request["tools"] as? [[String: Any]]) ?? []

        let hasDropboxConnector = tools.contains { tool in
            tool["type"] as? String == "mcp" && (tool["connector_id"] as? String == connectorId)
        }
        XCTAssertFalse(hasDropboxConnector)
    }

    func testMCPConnectorToolIncludedWithAuthorization() {
        let connectorId = "connector_dropbox"
        let authKey = "mcp_connector_\(connectorId)"
        XCTAssertTrue(KeychainService.shared.save(value: "test-oauth-token", forKey: authKey))

        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = true
        prompt.mcpConnectorId = connectorId
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableWebSearch = false
        prompt.enableCodeInterpreter = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false

        let request = buildRequest(prompt: prompt, message: "Use MCP tools")

        let tools = (request["tools"] as? [[String: Any]]) ?? []
        XCTAssertTrue(tools.contains { tool in
            tool["type"] as? String == "mcp" && (tool["connector_id"] as? String == connectorId)
        })
    }

    func testRemoteMCPToolIncludedForPublicServer() {
        let label = "deepwiki"
        _ = KeychainService.shared.delete(forKey: "mcp_manual_\(label)")

        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = false
        prompt.mcpServerLabel = label
        prompt.mcpServerURL = "https://mcp.deepwiki.com/mcp"
        prompt.mcpRequireApproval = "never"
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableWebSearch = false
        prompt.enableCodeInterpreter = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false

        let request = buildRequest(prompt: prompt, message: "Use MCP tools")

        let tools = (request["tools"] as? [[String: Any]]) ?? []
        XCTAssertTrue(tools.contains { tool in
            tool["type"] as? String == "mcp" && (tool["server_url"] as? String) == "https://mcp.deepwiki.com/mcp"
        })
    }

    func testRemoteMCPToolIncludedWithAuthorization() {
        let label = "github"
        _ = KeychainService.shared.delete(forKey: "mcp_manual_\(label)")

        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpIsConnector = false
        prompt.mcpServerLabel = label
        prompt.mcpServerURL = "https://api.githubcopilot.com/mcp/"
        prompt.mcpRequireApproval = "always"
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableWebSearch = false
        prompt.enableCodeInterpreter = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false
        prompt.secureMCPHeaders = ["Authorization": "Bearer github-oauth-token"]

        let request = buildRequest(prompt: prompt, message: "Use MCP tools")

        let tools = (request["tools"] as? [[String: Any]]) ?? []
        XCTAssertTrue(tools.contains { tool in
            tool["type"] as? String == "mcp" && (tool["server_url"] as? String) == "https://api.githubcopilot.com/mcp/"
        })
    }

    func testFileSearchToolCarriesVectorStoreIds() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableFileSearch = true
        prompt.selectedVectorStoreIds = "vs_123, vs_456"
        prompt.enableCodeInterpreter = false
        prompt.enableWebSearch = false
        prompt.enableImageGeneration = false

        let request = buildRequest(prompt: prompt, message: "Search my docs")

        guard let tools = request["tools"] as? [[String: Any]],
              let fileSearch = tools.first(where: { $0["type"] as? String == "file_search" }),
              let ids = fileSearch["vector_store_ids"] as? [String]
        else {
            return XCTFail("Expected file_search tool with vector store IDs")
        }

        XCTAssertEqual(ids, ["vs_123", "vs_456"])
    }

    func testWebSearchToolIncludedWhenEnabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableWebSearch = true
        prompt.webSearchMode = "grounded"
        prompt.enableCodeInterpreter = false
        prompt.enableImageGeneration = false
        prompt.enableFileSearch = false

        let request = buildRequest(prompt: prompt, message: "Latest news")

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }

        XCTAssertTrue(tools.contains { $0["type"] as? String == "web_search" })
        XCTAssertFalse(tools.contains { $0["profile"] != nil }, "The live API rejects the legacy profile parameter")
    }

    func testMetadataParsedIntoDictionary() {
        var prompt = Prompt.defaultPrompt()
        prompt.metadata = "{\"user_id\":\"test123\",\"session\":\"abc\"}"

        let request = buildRequest(prompt: prompt)

        let metadata = request["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["user_id"] as? String, "test123")
        XCTAssertEqual(metadata?["session"] as? String, "abc")
    }

    func testInvalidMetadataSilentlyIgnored() {
        var prompt = Prompt.defaultPrompt()
        prompt.metadata = "not json"

        let request = buildRequest(prompt: prompt)

        XCTAssertNil(request["metadata"])
    }

    func testPreviousResponseIdPropagates() {
        let request = buildRequest(prompt: Prompt.defaultPrompt(), previousResponseID: "resp_123")
        XCTAssertEqual(request["previous_response_id"] as? String, "resp_123")
    }

    func testConversationIdPropagates() {
        let request = buildRequest(prompt: Prompt.defaultPrompt(), conversationID: "conv_789")
        XCTAssertEqual(request["conversation"] as? String, "conv_789")
        XCTAssertNil(request["conversation_id"])
    }

    func testPreviousResponseIdWinsOverConversationId() {
        let request = buildRequest(
            prompt: Prompt.defaultPrompt(),
            previousResponseID: "resp_123",
            conversationID: "conv_789"
        )

        XCTAssertEqual(request["previous_response_id"] as? String, "resp_123")
        XCTAssertNil(request["conversation"])
    }

    func testFunctionOutputsRequestOmitsConversationWhenPreviousResponseIdIsPresent() throws {
        let request = try buildFunctionOutputsRequest(
            previousResponseID: "resp_123",
            conversationID: "conv_789"
        )

        XCTAssertEqual(request["previous_response_id"] as? String, "resp_123")
        XCTAssertNil(request["conversation"])
    }

    func testFunctionOutputsRequestIncludesConversationWhenPreviousResponseIdIsMissing() throws {
        let request = try buildFunctionOutputsRequest(
            previousResponseID: nil,
            conversationID: "conv_789"
        )

        XCTAssertEqual(request["conversation"] as? String, "conv_789")
        XCTAssertNil(request["previous_response_id"])
    }

    func testFunctionOutputsRequestNormalizesModelAlias() throws {
        let request = try buildFunctionOutputsRequest(model: "gpt-5.4-thinking")

        XCTAssertEqual(request["model"] as? String, "gpt-5.4")
    }

    func testCustomInputOverridesDefaultMessages() {
        let prompt = Prompt.defaultPrompt()
        let custom: [[String: Any]] = [["role": "user", "content": "preset"]]

        let request = service.testing_buildRequestObject(
            for: prompt,
            userMessage: nil,
            customInput: custom
        )

        let input = request["input"] as? [[String: Any]]
        XCTAssertEqual(input?.first?["content"] as? String, "preset")
        XCTAssertEqual(input?.first?["role"] as? String, "user")
    }
    func testAstraSupportsToolsAndNormalizesLegacyEffortWithoutSampling() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-6-astra"
        prompt.reasoningEffort = "none"
        prompt.reasoningSummary = "auto"
        prompt.temperature = 0.7
        let request = buildRequest(prompt: prompt)
        XCTAssertEqual((request["reasoning"] as? [String: Any])?["effort"] as? String, "low")
        XCTAssertEqual((request["reasoning"] as? [String: Any])?["summary"] as? String, "auto")
        XCTAssertNil(request["temperature"])
        XCTAssertNil(request["top_p"])
        XCTAssertTrue(((request["tools"] as? [[String: Any]]) ?? []).contains { $0["type"] as? String == "web_search" })
        XCTAssertFalse(CurrentModelCatalog.reasoningEfforts(for: "gpt-6-astra").contains("none"))
        XCTAssertFalse(CurrentModelCatalog.reasoningEfforts(for: "gpt-5.6-sol").contains("minimal"))
    }

    func testModernControlsApplyToInitialAndToolContinuationRequests() throws {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-6-astra"
        prompt.currentOptions.automaticCompaction = true
        prompt.currentOptions.compactThreshold = 120_000
        prompt.currentOptions.reasoningContext = "all_turns"
        prompt.currentOptions.reasoningMode = "pro"
        for request in [buildRequest(prompt: prompt), try buildFunctionOutputsRequest(prompt: prompt, model: "gpt-6-astra", previousResponseID: "resp_test")] {
            let management = request["context_management"] as? [[String: Any]]
            XCTAssertEqual(management?.first?["compact_threshold"] as? Int, 120_000)
            XCTAssertEqual((request["reasoning"] as? [String: Any])?["context"] as? String, "all_turns")
            XCTAssertEqual((request["reasoning"] as? [String: Any])?["mode"] as? String, "pro")
        }
        prompt.openAIModel = "gpt-4o"
        XCTAssertNil(buildRequest(prompt: prompt)["context_management"])
    }

    func testToolSearchDefersFunctionsAndHostedShellCanStandAlone() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableWebSearch = false
        prompt.enableCodeInterpreter = false
        prompt.enableFileSearch = false
        prompt.enableImageGeneration = false
        prompt.enableMCPTool = false
        prompt.currentOptions.hostedShell = true
        var tools = buildRequest(prompt: prompt)["tools"] as? [[String: Any]]
        XCTAssertEqual(tools?.count, 1)
        XCTAssertEqual(tools?.first?["type"] as? String, "shell")
        XCTAssertEqual((tools?.first?["environment"] as? [String: Any])?["type"] as? String, "container_auto")
        prompt.enableCustomTool = true
        prompt.currentOptions.toolSearch = true
        tools = buildRequest(prompt: prompt)["tools"] as? [[String: Any]]
        XCTAssertTrue(tools?.contains { $0["type"] as? String == "tool_search" } == true)
        XCTAssertEqual(tools?.first { $0["type"] as? String == "function" }?["defer_loading"] as? Bool, true)
    }

    @MainActor
    func testCompactedWindowPreservesOpaqueItemsAndOnlyPrependsOnce() throws {
        var prompt = Prompt.defaultPrompt()
        prompt.compactedInputJSON = #"[{"type":"compaction","id":"cmp_123","encrypted_content":"opaque"},{"type":"message","role":"assistant","phase":"final_answer","content":[{"type":"output_text","text":"Retained"}]}]"#
        let first = buildRequest(prompt: prompt)
        let input = try XCTUnwrap(first["input"] as? [[String: Any]])
        XCTAssertEqual(input.first?["encrypted_content"] as? String, "opaque")
        XCTAssertEqual(input[1]["phase"] as? String, "final_answer")
        let continued = buildRequest(prompt: prompt, previousResponseID: "resp_after_compaction")
        XCTAssertFalse((continued["input"] as? [[String: Any]] ?? []).contains { $0["type"] as? String == "compaction" })
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(prompt)) as? [String: Any]
        XCTAssertNil(encoded?["compactedInputJSON"], "Conversation context must never leak into a saved preset")
    }

    func testImageTwoTransparencyAndPartialPreviews() {
        var prompt = Prompt.defaultPrompt()
        prompt.imageGenerationBackground = "transparent"
        prompt.imageGenerationOutputFormat = "jpeg"
        prompt.currentOptions.partialImages = 9
        prompt.currentOptions.imageAction = "edit"
        let tool = (buildRequest(prompt: prompt, stream: true)["tools"] as? [[String: Any]])?.first { $0["type"] as? String == "image_generation" }
        XCTAssertEqual(tool?["model"] as? String, CurrentModelCatalog.imageModel)
        XCTAssertEqual(tool?["output_format"] as? String, "png")
        XCTAssertEqual(tool?["partial_images"] as? Int, 3)
        XCTAssertEqual(tool?["action"] as? String, "edit")
        let nonStreamingTool = (buildRequest(prompt: prompt)["tools"] as? [[String: Any]])?.first { $0["type"] as? String == "image_generation" }
        XCTAssertNil(nonStreamingTool?["partial_images"])
        let count = ResponsesAPIClient.tokenCountBody(from: buildRequest(prompt: prompt, stream: true))
        XCTAssertNil((count["tools"] as? [[String: Any]])?.first { $0["type"] as? String == "image_generation" }?["partial_images"])
    }

    @MainActor
    func testModernOptionsAreBackwardCompatibleAndOptIn() throws {
        let prompt = Prompt.defaultPrompt()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(prompt)) as? [String: Any])
        json.removeValue(forKey: "modernOptions")
        let restored = try JSONDecoder().decode(Prompt.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(restored.currentOptions.toolSearch)
        XCTAssertFalse(restored.currentOptions.automaticCompaction)
        XCTAssertNil(buildRequest(prompt: restored)["prompt_cache_options"], "Do not enable cache writes for short requests")
    }

    func testModelSnapshotCapabilitiesDoNotLeakToUnknownFamilies() {
        XCTAssertTrue(CurrentModelCatalog.isModern("gpt-6-astra-2026-09-03"))
        XCTAssertFalse(CurrentModelCatalog.isModern("gpt-6-astra-audio"))
        XCTAssertTrue(CurrentModelCatalog.isRetired("computer-use-preview"))
        XCTAssertFalse(CurrentModelCatalog.recommended.contains("computer-use-preview"))
    }

    func testGPT6SolAndLunaAreCurrentModelsWithTheFullReasoningRange() {
        for model in ["gpt-6-sol", "gpt-6-luna"] {
            XCTAssertTrue(CurrentModelCatalog.isModern(model), model)
            XCTAssertTrue(CurrentModelCatalog.recommended.contains(model), model)
            XCTAssertEqual(CurrentModelCatalog.reasoningEfforts(for: model), ["none", "low", "medium", "high", "xhigh", "max"])
            let capabilities = ModelCompatibilityService.shared.getCapabilities(for: model)
            XCTAssertNotNil(capabilities, "\(model) must appear in the model picker")
            XCTAssertTrue(ModelCompatibilityService.shared.isToolSupported(.computer, for: model))
            XCTAssertEqual(ModelCompatibilityService.shared.defaultReasoningEffort(for: model), "medium")

            var prompt = Prompt.defaultPrompt()
            prompt.openAIModel = model
            prompt.reasoningEffort = "none"
            prompt.temperature = 0.7
            let request = buildRequest(prompt: prompt)
            XCTAssertEqual(request["model"] as? String, model)
            XCTAssertEqual((request["reasoning"] as? [String: Any])?["effort"] as? String, "none")
            XCTAssertNil(request["temperature"])
            XCTAssertTrue(((request["tools"] as? [[String: Any]]) ?? []).contains { $0["type"] as? String == "web_search" })
        }
        XCTAssertEqual(CurrentModelCatalog.defaultModel, "gpt-6-sol")
        XCTAssertEqual(Prompt.defaultPrompt().openAIModel, "gpt-6-sol")
        XCTAssertFalse(CurrentModelCatalog.supportsAsyncTools("gpt-6-sol"))
        XCTAssertTrue(CurrentModelCatalog.supportsAsyncTools("gpt-6-astra-2026-09-03"))
    }

    func testLaterGeneralReleasesAreRecognizedButSpecializedModelsAreNot() {
        for model in ["gpt-6.1-sol", "gpt-7", "gpt-7-luna-2027-03-01", "GPT-6-SOL", "gpt-5.6", "gpt-5.6-terra-2026-06-01"] {
            XCTAssertTrue(CurrentModelCatalog.isModern(model), model)
        }
        for model in ["gpt-5.6-cyber", "gpt-realtime-2.1", "gpt-image-2.5-flare", "gpt-6-sol-transcribe", "gpt-live-1",
                      "gpt-5.5", "gpt-oss-120b", "gpt-6-astra-audio", "gpt-4o", "o3", "gpt-6-sol-mini-preview", "gpt-daybreak-red-latest"] {
            XCTAssertFalse(CurrentModelCatalog.isModern(model), model)
        }
        XCTAssertEqual(CurrentModelCatalog.reasoningEfforts(for: "gpt-6.1-sol").first, "none")
        XCTAssertEqual(CurrentModelCatalog.reasoningEfforts(for: "gpt-7-astra").first, "low")
        XCTAssertGreaterThan(CurrentModelCatalog.priority("gpt-7-sol"), CurrentModelCatalog.priority("gpt-6-sol"))
        XCTAssertGreaterThan(CurrentModelCatalog.priority("gpt-6-sol"), CurrentModelCatalog.priority("gpt-5.6-sol"))
        XCTAssertEqual(CurrentModelCatalog.family("gpt-6-luna-2026-09-22"), "gpt-6-luna")
        XCTAssertEqual(CurrentModelCatalog.description(for: "gpt-6.1-sol"), "Current generation model")
        for retiring in ["gpt-5", "gpt-5-mini", "gpt-5-nano", "o3"] {
            XCTAssertFalse(CurrentModelCatalog.legacy.contains(retiring), retiring)
        }
    }

    func testImageQualityFollowsTheChosenImageModel() {
        XCTAssertTrue(CurrentModelCatalog.supportsExtendedImageQuality("gpt-image-2.5-sunburst-2026-09-08"))
        XCTAssertFalse(CurrentModelCatalog.supportsExtendedImageQuality("gpt-image-2"))
        XCTAssertEqual(CurrentModelCatalog.normalizedImageQuality("max", model: "gpt-image-2"), "high")
        XCTAssertEqual(CurrentModelCatalog.normalizedImageQuality("max", model: "gpt-image-2.5-flare"), "max")
        XCTAssertEqual(CurrentModelCatalog.normalizedImageQuality("hd", model: "gpt-image-2.5-flare"), "auto")

        var prompt = Prompt.defaultPrompt()
        prompt.enableImageGeneration = true
        prompt.imageGenerationQuality = "max"
        func imageTool() -> [String: Any]? {
            (buildRequest(prompt: prompt)["tools"] as? [[String: Any]])?.first { $0["type"] as? String == "image_generation" }
        }
        prompt.imageGenerationModel = "gpt-image-2.5-sunburst"
        XCTAssertEqual(imageTool()?["quality"] as? String, "max")
        prompt.imageGenerationModel = "gpt-image-2"
        XCTAssertEqual(imageTool()?["quality"] as? String, "high", "gpt-image-2 rejects max; send the nearest accepted value")
    }

    func testRetiringRealtimeModelsMoveToTheCurrentDefault() {
        XCTAssertEqual(CurrentModelCatalog.supportedRealtimeModel("gpt-realtime"), "gpt-realtime-2.1")
        XCTAssertEqual(CurrentModelCatalog.supportedRealtimeModel("gpt-realtime-mini"), "gpt-realtime-2.1")
        XCTAssertEqual(CurrentModelCatalog.supportedRealtimeModel("gpt-realtime-2.1-mini"), "gpt-realtime-2.1-mini")
    }

    func testLiveSessionsStartWithSessionStartAndMapOntoVoiceEvents() {
        XCTAssertTrue(RealtimeService.isLiveModel("gpt-live-1"))
        XCTAssertFalse(RealtimeService.isLiveModel("gpt-realtime-2.1"))
        XCTAssertTrue(CurrentModelCatalog.realtimeModels.contains("gpt-live-1"))
        XCTAssertEqual(CurrentModelCatalog.supportedRealtimeModel("gpt-live-1"), "gpt-live-1")
        let start = RealtimeService.liveStartEvent(model: "gpt-live-1", voice: "not-a-voice", instructions: "Be brief")
        XCTAssertEqual(start["type"] as? String, "session.start")
        let session = start["session"] as? [String: Any]
        XCTAssertEqual(session?["model"] as? String, "gpt-live-1")
        XCTAssertEqual(session?["instructions"] as? String, "Be brief")
        let audio = session?["audio"] as? [String: Any]
        XCTAssertEqual((audio?["format"] as? [String: Any])?["rate"] as? Int, 24000)
        XCTAssertEqual((audio?["output"] as? [String: Any])?["voice"] as? String, "marin")
        XCTAssertNil(session?["type"], "Live sessions have no Realtime session type")
        XCTAssertEqual(RealtimeService.normalizedLiveEvent(["type": "session.started"])["type"] as? String, "session.updated")
        XCTAssertEqual(RealtimeService.normalizedLiveEvent(["type": "session.output_audio.delta", "delta": "AAA="])["type"] as? String, "response.output_audio.delta")
        XCTAssertEqual(RealtimeService.normalizedLiveEvent(["type": "session.output_transcript.delta"])["type"] as? String, "live.output_transcript.delta")
        XCTAssertEqual(RealtimeService.normalizedLiveEvent(["type": "error"])["type"] as? String, "error")
    }

    func testCurrentResponsesOptionsReachTheRequest() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableMCPTool = false
        prompt.enableWebSearch = true
        prompt.enableCodeInterpreter = true
        prompt.enableImageGeneration = true
        prompt.imageGenerationOutputFormat = "webp"
        prompt.enableFileSearch = true
        prompt.selectedVectorStoreIds = "vs_one"
        prompt.fileSearchRanker = "default_2024_08_21"
        prompt.fileSearchScoreThreshold = 0.4
        prompt.currentOptions.moderationModel = "omni-moderation-latest"
        prompt.currentOptions.moderationOutputMode = "block"
        prompt.currentOptions.webSearchExternalAccess = false
        prompt.currentOptions.codeInterpreterMemoryLimit = "4g"
        prompt.currentOptions.imageInputFidelity = "high"
        prompt.currentOptions.imageOutputCompression = 80
        prompt.currentOptions.hybridEmbeddingWeight = 0.7
        prompt.currentOptions.hybridTextWeight = 0.3
        prompt.webSearchAllowedDomains = "example.com"
        prompt.webSearchBlockedDomains = "blocked.example"
        let request = buildRequest(prompt: prompt)
        let moderation = request["moderation"] as? [String: Any]
        XCTAssertEqual(moderation?["model"] as? String, "omni-moderation-latest")
        XCTAssertEqual(((moderation?["policy"] as? [String: Any])?["input"] as? [String: Any])?["mode"] as? String, "score")
        XCTAssertEqual(((moderation?["policy"] as? [String: Any])?["output"] as? [String: Any])?["mode"] as? String, "block")
        let tools = request["tools"] as? [[String: Any]] ?? []
        func tool(_ type: String) -> [String: Any]? { tools.first { $0["type"] as? String == type } }
        XCTAssertEqual(tool("web_search")?["external_web_access"] as? Bool, false)
        let filters = tool("web_search")?["filters"] as? [String: Any]
        XCTAssertEqual(filters?["allowed_domains"] as? [String], ["example.com"])
        XCTAssertNil(filters?["blocked_domains"], "web_search filters accept allowed_domains only")
        XCTAssertEqual((tool("code_interpreter")?["container"] as? [String: Any])?["memory_limit"] as? String, "4g")
        XCTAssertEqual(tool("image_generation")?["input_fidelity"] as? String, "high")
        XCTAssertEqual(tool("image_generation")?["output_compression"] as? Int, 80)
        let ranking = tool("file_search")?["ranking_options"] as? [String: Any]
        XCTAssertEqual(ranking?["ranker"] as? String, "default-2024-11-15")
        XCTAssertEqual((ranking?["hybrid_search"] as? [String: Any])?["embedding_weight"] as? Double, 0.7)
        XCTAssertFalse(tools.contains { ($0["type"] as? String)?.hasSuffix("_preview") == true })

        let defaults = buildRequest(prompt: Prompt.defaultPrompt())
        XCTAssertNil(defaults["moderation"])
        XCTAssertNil(((defaults["tools"] as? [[String: Any]]) ?? []).first { $0["type"] as? String == "web_search" }?["external_web_access"])
    }

    func testWorkbenchCoversCurrentEndpointsAndExcludesDeprecatedAPIs() throws {
        let paths = try APIWorkbenchView.Endpoint.allCases.map { try $0.path(id: "id_1") }
        for expected in ["/responses", "/responses/input_tokens", "/responses/compact", "/responses/id_1", "/conversations/id_1/items",
                         "/models", "/moderations", "/embeddings", "/vector_stores/id_1/search", "/containers", "/batches/id_1/cancel",
                         "/realtime/client_secrets", "/audio/voice_consents"] {
            XCTAssertTrue(paths.contains(expected), expected)
        }
        for retired in ["/assistants", "/threads", "/prompts", "/evals", "/fine_tuning", "/images/variations", "/videos", "/chat/completions"] {
            XCTAssertFalse(paths.contains { $0.hasPrefix(retired) }, retired)
        }
        XCTAssertEqual(APIWorkbenchView.Endpoint.deleteFile.method, "DELETE")
        XCTAssertEqual(try APIWorkbenchView.Endpoint.retrieveModel.path(id: "gpt-5.6-sol"), "/models/gpt-5.6-sol")
        XCTAssertThrowsError(try APIWorkbenchView.Endpoint.retrieveFile.path(id: "../x"))
        XCTAssertEqual(APIWorkbenchView.Endpoint(rawValue: "Create response"), .responses, "Saved drafts keep their endpoint")
    }

    func testReviewFindingsGPT4oMiniFineTunesBlockedDomainsAndVoiceNotes() throws {
        XCTAssertNotNil(ModelCompatibilityService.shared.getCapabilities(for: "gpt-4o-mini"))
        XCTAssertNotNil(ModelCompatibilityService.shared.getCapabilities(for: "gpt-4o-mini-2024-07-18"))
        XCTAssertFalse(CurrentModelCatalog.isRetired("ft:gpt-4.1-mini-2025-04-14:org::abc123"), "Fine-tuned inference continues until its base model retires")
        XCTAssertNil(ModelCompatibilityService.shared.getCapabilities(for: "gpt-5.2-codex"), "Only dated snapshots inherit a family")

        var prompt = Prompt.defaultPrompt()
        prompt.systemInstructions = "Answer as a travel agent."
        prompt.enableWebSearch = true
        prompt.webSearchBlockedDomains = "reddit.com, example.org"
        let instructions = buildRequest(prompt: prompt)["instructions"] as? String ?? ""
        XCTAssertTrue(instructions.hasPrefix("Answer as a travel agent."))
        XCTAssertTrue(instructions.contains("avoid citing: reddit.com, example.org"))

        let request = OpenAIService.transcriptionRequest(audio: Data([1, 2, 3]), fileName: "voice-note.wav", apiKey: "test")
        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/audio/transcriptions")
        XCTAssertTrue(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
        let body = String(decoding: try XCTUnwrap(request.httpBody), as: UTF8.self)
        XCTAssertTrue(body.contains("name=\"model\"\r\n\r\ngpt-transcribe"))
        XCTAssertTrue(body.contains("filename=\"voice-note.wav\""))
    }

    func testTokenCountExcludesGenerationAndTransportFields() {
        let body = ResponsesAPIClient.tokenCountBody(from: ["model": "gpt-6-astra", "input": "Hi", "stream": true, "background": true, "store": false, "max_output_tokens": 50, "tools": [["type": "web_search"]]])
        XCTAssertEqual(Set(body.keys), ["model", "input", "tools"])
    }

    func testRealtimeUsesCurrentNestedAudioSchemaAndValidVoice() {
        let session = RealtimeService.sessionConfiguration(voice: "fable", instructions: "Be brief", textOnly: false)
        XCTAssertNil(session["input_audio_transcription"])
        XCTAssertEqual(session["output_modalities"] as? [String], ["audio"])
        let audio = session["audio"] as? [String: Any]
        let input = audio?["input"] as? [String: Any]
        XCTAssertEqual((input?["transcription"] as? [String: Any])?["model"] as? String, "gpt-live-transcribe")
        XCTAssertEqual((audio?["output"] as? [String: Any])?["voice"] as? String, "marin")
    }

    @MainActor
    func testNativeOrchestrationGatesIncompatibleParametersAndToolRoutes() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-6-astra"
        prompt.enableCustomTool = true
        prompt.customToolName = "read_echo"
        prompt.customToolExecutionType = "echo"
        prompt.currentOptions.customToolFormat = "text"
        prompt.currentOptions.multiAgent = true
        prompt.currentOptions.asyncTools = true
        prompt.currentOptions.maxSubagents = 99
        prompt.reasoningSummary = "detailed"
        prompt.maxToolCalls = 8
        let request = buildRequest(prompt: prompt, stream: true)
        XCTAssertNil((request["reasoning"] as? [String: Any])?["summary"])
        XCTAssertNil(request["max_tool_calls"])
        XCTAssertEqual(request["parallel_tool_calls"] as? Bool, false)
        XCTAssertEqual((request["multi_agent"] as? [String: Any])?["max_concurrent_subagents"] as? Int, 8)
        let custom = (request["tools"] as? [[String: Any]])?.first { $0["name"] as? String == "read_echo" }
        XCTAssertEqual(custom?["type"] as? String, "custom")
        XCTAssertEqual(custom?["async"] as? Bool, true)
        XCTAssertNil(custom?["parameters"])
        prompt.currentOptions.programmaticTools = true
        let programmatic = buildRequest(prompt: prompt)
        let programTool = (programmatic["tools"] as? [[String: Any]])?.first { $0["name"] as? String == "read_echo" }
        XCTAssertNil(programTool?["async"])
        XCTAssertEqual(programTool?["allowed_callers"] as? [String], ["direct", "programmatic"])
        prompt.customToolExecutionType = "webhook"
        let webhook = (buildRequest(prompt: prompt)["tools"] as? [[String: Any]])?.first { $0["name"] as? String == "read_echo" }
        XCTAssertNil(webhook?["async"])
        XCTAssertNil(webhook?["allowed_callers"])
        prompt.enableComputerUse = true
        let computerRequest = buildRequest(prompt: prompt)
        XCTAssertNil(computerRequest["multi_agent"])
        XCTAssertFalse((computerRequest["tools"] as? [[String: Any]] ?? []).contains { $0["type"] as? String == "programmatic_tool_calling" })
    }

}
