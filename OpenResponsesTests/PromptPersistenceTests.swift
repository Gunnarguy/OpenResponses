//
//  PromptPersistenceTests.swift
//  OpenResponsesTests
//
//  Created for App Store release - test prompt save/load
//

import XCTest
@testable import OpenResponses

final class PromptPersistenceTests: XCTestCase {
    
    func testSaveAndLoadPrompt() {
        // Given: A custom prompt configuration
        var prompt = Prompt.defaultPrompt()
        prompt.name = "Test Configuration"
        prompt.openAIModel = "gpt-4o"
        prompt.systemInstructions = "You are a test assistant."
        prompt.temperature = 0.8
        prompt.maxOutputTokens = 3000
        prompt.enableCodeInterpreter = true
        prompt.enableFileSearch = true
        prompt.vectorStoreIDs = ["vs_test123"]
        
        // When: Saving the prompt
        PromptPersistence.shared.savePrompt(prompt)
        
        // Then: Should be able to load it back
        let loadedPrompt = PromptPersistence.shared.loadPrompt()
        
        XCTAssertNotNil(loadedPrompt)
        XCTAssertEqual(loadedPrompt?.name, "Test Configuration")
        XCTAssertEqual(loadedPrompt?.openAIModel, "gpt-4o")
        XCTAssertEqual(loadedPrompt?.systemInstructions, "You are a test assistant.")
        XCTAssertEqual(loadedPrompt?.temperature, 0.8)
        XCTAssertEqual(loadedPrompt?.maxOutputTokens, 3000)
        XCTAssertEqual(loadedPrompt?.enableCodeInterpreter, true)
        XCTAssertEqual(loadedPrompt?.enableFileSearch, true)
        XCTAssertEqual(loadedPrompt?.vectorStoreIDs, ["vs_test123"])
    }
    
    func testLoadDefaultPromptWhenNoneSaved() {
        // Given: No saved prompt (clear UserDefaults)
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        
        // When: Loading prompt
        let prompt = PromptPersistence.shared.loadPrompt()
        
        // Then: Should return default prompt
        XCTAssertNotNil(prompt)
        XCTAssertEqual(prompt?.openAIModel, Prompt.defaultPrompt().openAIModel)
    }
    
    func testPromptPersistenceAcrossAppLaunches() {
        // Given: A saved prompt
        var prompt = Prompt.defaultPrompt()
        prompt.name = "Persistent Config"
        prompt.reasoningEffort = "high"
        prompt.includeReasoningContent = true
        
        PromptPersistence.shared.savePrompt(prompt)
        
        // When: Creating a new persistence instance (simulating app relaunch)
        let newPersistence = PromptPersistence.shared
        let loaded = newPersistence.loadPrompt()
        
        // Then: Should load the same configuration
        XCTAssertEqual(loaded?.name, "Persistent Config")
        XCTAssertEqual(loaded?.reasoningEffort, "high")
        XCTAssertEqual(loaded?.includeReasoningContent, true)
    }
    
    func testSavePromptWithAllToolsEnabled() {
        // Given: A prompt with all tools enabled
        var prompt = Prompt.defaultPrompt()
        prompt.enableCodeInterpreter = true
        prompt.enableWebSearch = true
        prompt.enableFileSearch = true
        prompt.enableImageGeneration = true
        prompt.enableComputerUse = true
        prompt.enableMCPTool = true
        
        // When: Saving and loading
        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()
        
        // Then: All tools should be enabled
        XCTAssertEqual(loaded?.enableCodeInterpreter, true)
        XCTAssertEqual(loaded?.enableWebSearch, true)
        XCTAssertEqual(loaded?.enableFileSearch, true)
        XCTAssertEqual(loaded?.enableImageGeneration, true)
        XCTAssertEqual(loaded?.enableComputerUse, true)
        XCTAssertEqual(loaded?.enableMCPTool, true)
    }
    
    func testSavePromptWithComplexMCPConfiguration() {
        // Given: A prompt with MCP configuration
        var prompt = Prompt.defaultPrompt()
        prompt.enableMCPTool = true
        prompt.mcpServerURL = "http://localhost:3000"
        prompt.mcpServerLabel = "Test MCP Server"
        prompt.mcpAuthHeaderKey = "Authorization"
        prompt.mcpRequireApproval = "always"
        prompt.mcpAllowedTools = "tool1,tool2,tool3"
        
        // When: Saving and loading
        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()
        
        // Then: MCP config should be preserved
        XCTAssertEqual(loaded?.mcpServerURL, "http://localhost:3000")
        XCTAssertEqual(loaded?.mcpServerLabel, "Test MCP Server")
        XCTAssertEqual(loaded?.mcpAuthHeaderKey, "Authorization")
        XCTAssertEqual(loaded?.mcpRequireApproval, "always")
        XCTAssertEqual(loaded?.mcpAllowedTools, "tool1,tool2,tool3")
    }
    
    func testSavePromptWithResponseIncludes() {
        // Given: A prompt with custom response includes
        var prompt = Prompt.defaultPrompt()
        prompt.includeReasoningContent = true
        prompt.includeOutputLogprobs = true
        prompt.topLogprobs = 10
        prompt.includeFileSearchResults = true
        prompt.includeWebSearchResults = true
        prompt.includeWebSearchSources = true
        prompt.includeCodeInterpreterOutputs = true
        prompt.includeComputerUseOutput = true
        
        // When: Saving and loading
        PromptPersistence.shared.savePrompt(prompt)
        let loaded = PromptPersistence.shared.loadPrompt()
        
        // Then: All includes should be preserved
        XCTAssertEqual(loaded?.includeReasoningContent, true)
        XCTAssertEqual(loaded?.includeOutputLogprobs, true)
        XCTAssertEqual(loaded?.topLogprobs, 10)
        XCTAssertEqual(loaded?.includeFileSearchResults, true)
        XCTAssertEqual(loaded?.includeWebSearchResults, true)
        XCTAssertEqual(loaded?.includeWebSearchSources, true)
        XCTAssertEqual(loaded?.includeCodeInterpreterOutputs, true)
        XCTAssertEqual(loaded?.includeComputerUseOutput, true)
    }
}
