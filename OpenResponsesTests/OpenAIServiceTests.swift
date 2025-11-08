//
//  OpenAIServiceTests.swift
//  OpenResponsesTests
//
//  Created for App Store release - comprehensive API service tests
//

import XCTest
@testable import OpenResponses

final class OpenAIServiceTests: XCTestCase {
    var service: OpenAIService!
    
    override func setUp() {
        super.setUp()
        service = OpenAIService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Request Building Tests
    
    func testBuildRequestObjectBasic() throws {
        // Given: A basic prompt with minimal configuration
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "gpt-4o"
        prompt.enableStreaming = true
        
        let messages = [
            ChatMessage(role: .user, content: "Hello", fileAttachments: nil)
        ]
        
        // When: Building a request object
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Request object should have basic structure
        XCTAssertNotNil(requestObject["model"], "Should include model")
        XCTAssertEqual(requestObject["model"] as? String, "gpt-4o")
        XCTAssertNotNil(requestObject["stream"], "Should include stream flag")
        XCTAssertEqual(requestObject["stream"] as? Bool, true)
        XCTAssertNotNil(requestObject["input"], "Should include input array")
        
        // Verify input array structure
        let input = requestObject["input"] as? [[String: Any]]
        XCTAssertNotNil(input)
        XCTAssertEqual(input?.count, 1, "Should have one message")
        
        let firstMessage = input?.first
        XCTAssertEqual(firstMessage?["role"] as? String, "user")
        XCTAssertEqual(firstMessage?["content"] as? String, "Hello")
    }
    
    func testBuildRequestObjectWithSystemInstructions() throws {
        // Given: A prompt with system instructions
        var prompt = Prompt.defaultPrompt()
        prompt.systemInstructions = "You are a helpful assistant."
        prompt.developerInstructions = "Be concise."
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include instructions
        let input = requestObject["input"] as? [[String: Any]]
        XCTAssertNotNil(input)
        
        // First message should be system instructions
        let systemMsg = input?.first
        XCTAssertEqual(systemMsg?["type"] as? String, "message")
        XCTAssertEqual(systemMsg?["role"] as? String, "system")
    }
    
    func testBuildRequestObjectWithTemperature() throws {
        // Given: A prompt with custom temperature
        var prompt = Prompt.defaultPrompt()
        prompt.temperature = 0.7
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include temperature
        XCTAssertEqual(requestObject["temperature"] as? Double, 0.7)
    }
    
    func testBuildRequestObjectWithMaxTokens() throws {
        // Given: A prompt with max output tokens
        var prompt = Prompt.defaultPrompt()
        prompt.maxOutputTokens = 2000
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include max_completion_tokens
        XCTAssertEqual(requestObject["max_completion_tokens"] as? Int, 2000)
    }
    
    func testBuildRequestObjectWithReasoningEffort() throws {
        // Given: A reasoning model with effort set
        var prompt = Prompt.defaultPrompt()
        prompt.openAIModel = "o1"
        prompt.reasoningEffort = "high"
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include reasoning_effort
        XCTAssertEqual(requestObject["reasoning_effort"] as? String, "high")
    }
    
    func testBuildRequestObjectWithToolsEnabled() throws {
        // Given: A prompt with code interpreter enabled
        var prompt = Prompt.defaultPrompt()
        prompt.enableCodeInterpreter = true
        
        let messages = [
            ChatMessage(role: .user, content: "Calculate something", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include tools array
        let tools = requestObject["tools"] as? [[String: Any]]
        XCTAssertNotNil(tools)
        XCTAssertTrue(tools?.contains(where: { $0["type"] as? String == "code_interpreter" }) ?? false,
                     "Should include code_interpreter tool")
    }
    
    func testBuildRequestObjectWithFileSearch() throws {
        // Given: A prompt with file search enabled and vector stores
        var prompt = Prompt.defaultPrompt()
        prompt.enableFileSearch = true
        prompt.vectorStoreIDs = ["vs_123", "vs_456"]
        
        let messages = [
            ChatMessage(role: .user, content: "Search my docs", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include file_search tool and vector stores
        let tools = requestObject["tools"] as? [[String: Any]]
        XCTAssertNotNil(tools)
        
        let fileSearchTool = tools?.first(where: { $0["type"] as? String == "file_search" })
        XCTAssertNotNil(fileSearchTool)
        
        let vectorStores = fileSearchTool?["file_search"] as? [String: Any]
        let vectorStoreIds = vectorStores?["vector_store_ids"] as? [String]
        XCTAssertEqual(vectorStoreIds, ["vs_123", "vs_456"])
    }
    
    func testBuildRequestObjectWithWebSearch() throws {
        // Given: A prompt with web search enabled
        var prompt = Prompt.defaultPrompt()
        prompt.enableWebSearch = true
        prompt.webSearchMode = "grounded"
        
        let messages = [
            ChatMessage(role: .user, content: "Latest news", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include web_search tool
        let tools = requestObject["tools"] as? [[String: Any]]
        XCTAssertNotNil(tools)
        XCTAssertTrue(tools?.contains(where: { $0["type"] as? String == "web_search" }) ?? false)
    }
    
    func testBuildRequestObjectWithMetadata() throws {
        // Given: A prompt with custom metadata
        var prompt = Prompt.defaultPrompt()
        prompt.metadata = "{\"user_id\": \"test123\", \"session\": \"abc\"}"
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include metadata
        let metadata = requestObject["metadata"] as? [String: Any]
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?["user_id"] as? String, "test123")
        XCTAssertEqual(metadata?["session"] as? String, "abc")
    }
    
    func testBuildRequestObjectWithModerationEnabled() throws {
        // Given: A prompt with moderation enabled
        var prompt = Prompt.defaultPrompt()
        prompt.enableModeration = true
        prompt.moderationModel = "omni-moderation-latest"
        prompt.moderationCategories = ["sexual", "violence"]
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include moderation config
        let moderation = requestObject["moderation"] as? [String: Any]
        XCTAssertNotNil(moderation)
        XCTAssertEqual(moderation?["model"] as? String, "omni-moderation-latest")
        
        let categories = moderation?["categories"] as? [String]
        XCTAssertEqual(categories?.sorted(), ["sexual", "violence"])
    }
    
    // MARK: - Conversation Context Tests
    
    func testBuildRequestObjectWithPreviousResponseID() throws {
        // Given: A prompt with conversation context
        let prompt = Prompt.defaultPrompt()
        let messages = [
            ChatMessage(role: .user, content: "Follow-up question", fileAttachments: nil)
        ]
        
        // When: Building request with previous response ID
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: "resp_abc123",
            responseID: nil
        )
        
        // Then: Should include previous_response_id
        XCTAssertEqual(requestObject["previous_response_id"] as? String, "resp_abc123")
    }
    
    func testBuildRequestObjectWithConversationID() throws {
        // Given: A prompt with conversation ID
        let prompt = Prompt.defaultPrompt()
        let messages = [
            ChatMessage(role: .user, content: "Message in conversation", fileAttachments: nil)
        ]
        
        // When: Building request with conversation ID
        let requestObject = try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: "conv_xyz789",
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should include conversation_id
        XCTAssertEqual(requestObject["conversation_id"] as? String, "conv_xyz789")
    }
    
    // MARK: - Edge Cases
    
    func testBuildRequestObjectWithEmptyMessages() throws {
        // Given: No user messages
        let prompt = Prompt.defaultPrompt()
        let messages: [ChatMessage] = []
        
        // When/Then: Should handle gracefully
        XCTAssertNoThrow(try service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        ))
    }
    
    func testBuildRequestObjectWithInvalidMetadata() {
        // Given: Invalid JSON metadata
        var prompt = Prompt.defaultPrompt()
        prompt.metadata = "{invalid json}"
        
        let messages = [
            ChatMessage(role: .user, content: "Test", fileAttachments: nil)
        ]
        
        // When: Building request
        let requestObject = try? service.buildRequestObject(
            for: prompt,
            messages: messages,
            conversationID: nil,
            previousResponseID: nil,
            responseID: nil
        )
        
        // Then: Should still build request (ignoring invalid metadata)
        XCTAssertNotNil(requestObject)
    }
}
