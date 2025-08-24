//
//  OpenResponsesTests.swift
//  OpenResponsesTests
//
//  Created by GitHub Copilot on 8/24/25.
//

import XCTest
@testable import OpenResponses

final class OpenResponsesTests: XCTestCase {
    
    // Test KeychainService
    func testKeychainService() {
        let testKey = "testKey"
        let testValue = "testValue"
        
        // Clean up from previous test runs
        _ = KeychainService.shared.delete(forKey: testKey)
        
        // Test saving
        XCTAssertTrue(KeychainService.shared.save(value: testValue, forKey: testKey), "Should save value to keychain")
        
        // Test loading
        XCTAssertEqual(KeychainService.shared.load(forKey: testKey), testValue, "Should load correct value from keychain")
        
        // Test deleting
        XCTAssertTrue(KeychainService.shared.delete(forKey: testKey), "Should delete value from keychain")
        XCTAssertNil(KeychainService.shared.load(forKey: testKey), "Should return nil after deletion")
    }
    
    // Test ChatMessage model
    func testChatMessage() {
        // Create a chat message
        let message = ChatMessage(role: .user, content: "Hello", fileAttachments: nil)
        
        // Test properties
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertNil(message.fileAttachments)
        
        // Test display attributes
        XCTAssertTrue(message.isUser)
        XCTAssertFalse(message.isAssistant)
    }
    
    // Test PromptLibrary
    func testPromptLibrary() {
        let library = PromptLibrary()
        
        // Create a test prompt
        let prompt = Prompt.defaultPrompt()
        let promptName = "Test Prompt"
        let promptDesc = "This is a test prompt"
        
        var testPrompt = prompt
        testPrompt.name = promptName
        testPrompt.description = promptDesc
        
        // Add the prompt
        library.addPrompt(testPrompt)
        
        // Check that it was added
        XCTAssertFalse(library.prompts.isEmpty, "Library should not be empty after adding a prompt")
        XCTAssertEqual(library.prompts.first?.name, promptName, "Should retrieve the prompt with correct name")
        XCTAssertEqual(library.prompts.first?.description, promptDesc, "Should retrieve the prompt with correct description")
        
        // Test updating
        var updatedPrompt = library.prompts.first!
        updatedPrompt.description = "Updated description"
        library.updatePrompt(updatedPrompt)
        
        XCTAssertEqual(library.prompts.first?.description, "Updated description", "Should update the prompt description")
        
        // Test deleting
        if let promptToDelete = library.prompts.first {
            library.deletePrompt(promptToDelete)
            XCTAssertTrue(library.prompts.isEmpty, "Library should be empty after deleting the prompt")
        } else {
            XCTFail("Should have a prompt to delete")
        }
    }
}
