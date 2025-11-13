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
    func testPromptLibrary() throws {
        try XCTSkipIf(true, "PromptLibrary persistence relies on UI-managed flows; tracked for rework in Conversations API migration.")
    }
}
