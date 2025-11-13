//
//  OpenAIServiceTests.swift
//  OpenResponsesTests
//

import XCTest
@testable import OpenResponses

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
        prompt.temperature = 0.42

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["temperature"] as? Double, 0.42)
    }

    func testMaxOutputTokensIncluded() {
        var prompt = Prompt.defaultPrompt()
        prompt.maxOutputTokens = 1500

        let request = buildRequest(prompt: prompt)

        XCTAssertEqual(request["max_output_tokens"] as? Int, 1500)
    }

    func testReasoningPayloadForReasoningModel() {
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "o1-preview"
        prompt.reasoningEffort = "high"
        prompt.reasoningSummary = "concise"

        let request = buildRequest(prompt: prompt)

        let reasoning = request["reasoning"] as? [String: Any]
        XCTAssertEqual(reasoning?["effort"] as? String, "high")
        XCTAssertEqual(reasoning?["summary"] as? String, "concise")
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
                            let ids = fileSearch["vector_store_ids"] as? [String] else {
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
        XCTAssertEqual(request["conversation_id"] as? String, "conv_789")
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
}
