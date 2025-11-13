//
//  OpenResponsesTests.swift
//  OpenResponsesTests
//
//  Created by GitHub Copilot on 8/24/25.
//

import XCTest
@testable import OpenResponses

final class OpenResponsesTests: XCTestCase {

    private let promptDefaultsSuite = "OpenResponsesPromptLibraryTests"
    private var promptDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "savedPrompts")
        promptDefaults = UserDefaults(suiteName: promptDefaultsSuite)!
        promptDefaults.removePersistentDomain(forName: promptDefaultsSuite)
    }

    override func tearDown() {
        promptDefaults?.removePersistentDomain(forName: promptDefaultsSuite)
        promptDefaults = nil
        UserDefaults.standard.removeObject(forKey: "savedPrompts")
        super.tearDown()
    }
    
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
    @MainActor
    func testChatMessage() {
        // Create a chat message
        let message = ChatMessage(role: .user, text: "Hello")

        // Test core properties
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.text, "Hello")
        XCTAssertNil(message.images)
        XCTAssertNil(message.webURLs)
    }
    
        // Test PromptLibrary
    @MainActor
    func testPromptLibrary() async {
        let library = PromptLibrary(userDefaults: promptDefaults, userDefaultsKey: "test_savedPrompts")
        
        // Create a test prompt
        let prompt = Prompt.defaultPrompt()
        let promptName = "Test Prompt"
        let promptInstructions = "This is a test prompt"
        
        var testPrompt = prompt
        testPrompt.name = promptName
        testPrompt.systemInstructions = promptInstructions
        
        // Add the prompt
        library.addPrompt(testPrompt)
        
        // Check that it was added
        XCTAssertFalse(library.prompts.isEmpty, "Library should not be empty after adding a prompt")
        XCTAssertEqual(library.prompts.first?.name, promptName, "Should retrieve the prompt with correct name")
        XCTAssertEqual(library.prompts.first?.systemInstructions, promptInstructions, "Should retrieve the prompt with correct instructions")
        
        // Test updating
        var updatedPrompt = library.prompts.first!
        updatedPrompt.systemInstructions = "Updated instructions"
        library.updatePrompt(updatedPrompt)

        XCTAssertEqual(library.prompts.first?.systemInstructions, "Updated instructions", "Should update the prompt instructions")
        
        // Test deleting
        if !library.prompts.isEmpty {
            library.deletePrompt(at: IndexSet(integer: 0))
            XCTAssertTrue(library.prompts.isEmpty, "Library should be empty after deleting the prompt")
        } else {
            XCTFail("Should have a prompt to delete")
        }
        
        // Ensure library stays alive until end of test
        withExtendedLifetime(library) { }
    }
}
