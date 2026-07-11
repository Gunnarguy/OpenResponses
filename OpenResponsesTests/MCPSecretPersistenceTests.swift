import XCTest
@testable import OpenResponses

final class MCPSecretPersistenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Ensure clean slate for test keys
        let testPromptId = "00000000-0000-0000-0000-000000000000"
        KeychainService.shared.delete(forKey: "mcp_manual_\(testPromptId)")
        KeychainService.shared.delete(forKey: "mcp_manual_test-label")
        KeychainService.shared.delete(forKey: "mcp_auth_test-label")
    }
    
    func testUUIDKeyedSavingAndLoading() {
        let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        var prompt = Prompt.defaultPrompt()
        prompt.id = uuid
        prompt.mcpServerLabel = "test-label"
        
        // Write headers via secureMCPHeaders property
        let headers = ["Authorization": "Bearer test-token"]
        prompt.secureMCPHeaders = headers
        
        // Load headers back
        let loaded = prompt.secureMCPHeaders
        XCTAssertEqual(loaded["Authorization"], "Bearer test-token")
        
        // Assert it is stored under prompt's UUID in Keychain
        let key = "mcp_manual_\(uuid.uuidString)"
        let storedData = KeychainService.shared.load(forKey: key)
        XCTAssertNotNil(storedData)
    }
    
    func testMigrationFromLegacyLabelKey() {
        let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        var prompt = Prompt.defaultPrompt()
        prompt.id = uuid
        prompt.mcpServerLabel = "test-label"
        
        // Write to legacy label key manually in Keychain
        let legacyKey = "mcp_manual_test-label"
        let headersDict = ["X-My-Header": "header-value"]
        let dictData = try! JSONSerialization.data(withJSONObject: headersDict)
        let dictString = String(data: dictData, encoding: .utf8)!
        KeychainService.shared.save(value: dictString, forKey: legacyKey)
        
        // Accessing secureMCPHeaders should trigger self-healing migration
        let loaded = prompt.secureMCPHeaders
        XCTAssertEqual(loaded["X-My-Header"], "header-value")
        
        // Legacy keys should be deleted
        XCTAssertNil(KeychainService.shared.load(forKey: legacyKey))
        
        // New UUID-based key should contain the migrated headers
        let newKey = "mcp_manual_\(uuid.uuidString)"
        XCTAssertNotNil(KeychainService.shared.load(forKey: newKey))
    }
}
