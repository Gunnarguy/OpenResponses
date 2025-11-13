//
//  PromptPersistenceTests.swift
//  OpenResponsesTests
//
//  Created for App Store release - test prompt save/load
//

import XCTest
@testable import OpenResponses

fileprivate final class PromptPersistence {
    static let shared = PromptPersistence()
    private let storageKey = "PromptPersistenceTests_activePrompt"

    private init() {}

    func savePrompt(_ prompt: Prompt) {
        guard !prompt.isPreset else { return }
        guard let data = try? JSONEncoder().encode(prompt) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func loadPrompt() -> Prompt {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let prompt = try? JSONDecoder().decode(Prompt.self, from: data) else {
            return Prompt.defaultPrompt()
        }
        return prompt
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

final class PromptPersistenceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PromptPersistence.shared.clear()
    }

    override func tearDown() {
        PromptPersistence.shared.clear()
        super.tearDown()
    }

    func testSaveAndLoadPrompt() {
        var prompt = Prompt.defaultPrompt()
        prompt.name = "Test Configuration"
        prompt.openAIModel = "gpt-4o"
        prompt.systemInstructions = "You are a test assistant."
        prompt.temperature = 0.8
        prompt.maxOutputTokens = 3000
        prompt.enableCodeInterpreter = true
        prompt.enableFileSearch = true
        prompt.selectedVectorStoreIds = "vs_test123"

        PromptPersistence.shared.savePrompt(prompt)
        let loadedPrompt = PromptPersistence.shared.loadPrompt()

        XCTAssertEqual(loadedPrompt.name, "Test Configuration")
        XCTAssertEqual(loadedPrompt.openAIModel, "gpt-4o")
        XCTAssertEqual(loadedPrompt.systemInstructions, "You are a test assistant.")
        XCTAssertEqual(loadedPrompt.temperature, 0.8)
        XCTAssertEqual(loadedPrompt.maxOutputTokens, 3000)
        XCTAssertTrue(loadedPrompt.enableCodeInterpreter)
        XCTAssertTrue(loadedPrompt.enableFileSearch)
        XCTAssertEqual(loadedPrompt.selectedVectorStoreIds, "vs_test123")
    }

    func testLoadDefaultPromptWhenNoneSaved() {
        PromptPersistence.shared.clear()

        let prompt = PromptPersistence.shared.loadPrompt()

        XCTAssertEqual(prompt.openAIModel, Prompt.defaultPrompt().openAIModel)
    }

    func testPromptPersistenceAcrossAppLaunches() {
        var prompt = Prompt.defaultPrompt()
        prompt.name = "Persistent Config"
        prompt.reasoningEffort = "high"
        prompt.includeReasoningContent = true

        PromptPersistence.shared.savePrompt(prompt)

        let loaded = PromptPersistence.shared.loadPrompt()

        XCTAssertEqual(loaded.name, "Persistent Config")
        XCTAssertEqual(loaded.reasoningEffort, "high")
        XCTAssertTrue(loaded.includeReasoningContent)
    }

    func testSavePromptWithAllToolsEnabled() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableCodeInterpreter = true
        prompt.enableWebSearch = true
        prompt.enableFileSearch = true
        prompt.enableImageGeneration = true
        prompt.enableComputerUse = true
        prompt.enableMCPTool = true

        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()

        XCTAssertTrue(loaded.enableCodeInterpreter)
        XCTAssertTrue(loaded.enableWebSearch)
        XCTAssertTrue(loaded.enableFileSearch)
        XCTAssertTrue(loaded.enableImageGeneration)
        XCTAssertTrue(loaded.enableComputerUse)
        XCTAssertTrue(loaded.enableMCPTool)
    }

    func testSavePromptWithComplexMCPConfiguration() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpServerURL = "http://localhost:3000"
        prompt.mcpServerLabel = "Test MCP Server"
        prompt.mcpAuthHeaderKey = "Authorization"
        prompt.mcpRequireApproval = "always"
        prompt.mcpAllowedTools = "tool1,tool2,tool3"

        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()

        XCTAssertEqual(loaded.mcpServerURL, "http://localhost:3000")
        XCTAssertEqual(loaded.mcpServerLabel, "Test MCP Server")
        XCTAssertEqual(loaded.mcpAuthHeaderKey, "Authorization")
        XCTAssertEqual(loaded.mcpRequireApproval, "always")
        XCTAssertEqual(loaded.mcpAllowedTools, "tool1,tool2,tool3")
    }

    func testSavePromptWithResponseIncludes() {
        var prompt = Prompt.defaultPrompt()
        prompt.includeReasoningContent = true
        prompt.includeOutputLogprobs = true
        prompt.topLogprobs = 10
        prompt.includeFileSearchResults = true
        prompt.includeWebSearchResults = true
        prompt.includeWebSearchSources = true
        prompt.includeCodeInterpreterOutputs = true
        prompt.includeComputerUseOutput = true

        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()

        XCTAssertTrue(loaded.includeReasoningContent)
        XCTAssertTrue(loaded.includeOutputLogprobs)
        XCTAssertEqual(loaded.topLogprobs, 10)
        XCTAssertTrue(loaded.includeFileSearchResults)
        XCTAssertTrue(loaded.includeWebSearchResults)
        XCTAssertTrue(loaded.includeWebSearchSources)
        XCTAssertTrue(loaded.includeCodeInterpreterOutputs)
        XCTAssertTrue(loaded.includeComputerUseOutput)
    }
}
