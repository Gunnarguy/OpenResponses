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

        prompt.openAIModel = "gpt-5-thinking"
        XCTAssertEqual(buildRequest(prompt: prompt)["model"] as? String, "gpt-5")

        prompt.openAIModel = "gpt-5-thinking-mini"
        XCTAssertEqual(buildRequest(prompt: prompt)["model"] as? String, "gpt-5-mini")

        prompt.openAIModel = "gpt-5-thinking-nano"
        XCTAssertEqual(buildRequest(prompt: prompt)["model"] as? String, "gpt-5-nano")
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
        prompt.openAIModel = "o3-mini"
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

    func testLegacyComputerUsePreviewModelUsesPreviewShape() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "computer-use-preview"
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
              let computerTool = tools.first(where: { $0["type"] as? String == "computer_use_preview" })
        else {
            return XCTFail("Expected legacy preview computer tool payload")
        }

        XCTAssertNotNil(computerTool["display_width"] as? Int)
        XCTAssertNotNil(computerTool["display_height"] as? Int)
        XCTAssertNotNil(computerTool["environment"] as? String)
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

    func testLegacyPreviewComputerCallOutputRetainsCurrentURL() throws {
        let request = try buildComputerCallOutputRequest(model: "computer-use-preview")

        guard let input = request["input"] as? [[String: Any]],
              let computerOutput = input.first,
              let output = computerOutput["output"] as? [String: Any] else {
            return XCTFail("Expected preview computer_call_output request payload")
        }

        XCTAssertEqual(computerOutput["current_url"] as? String, "https://example.com/path")
        XCTAssertNil(output["detail"])
        XCTAssertEqual(request["truncation"] as? String, "auto")

        guard let tools = request["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools payload")
        }
        XCTAssertEqual(tools.first?["type"] as? String, "computer_use_preview")
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

        XCTAssertTrue(tools.contains { $0["type"] as? String == "web_search" || $0["type"] as? String == "web_search_preview" })
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
        XCTAssertEqual(tool?["model"] as? String, "gpt-image-2")
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
