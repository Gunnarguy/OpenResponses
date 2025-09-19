//
//  OpenResponsesApp.swift
//  OpenResponses
//
//  Created by Gunnar Hostetler on 6/27/25.
//

import SwiftUI

@main
struct OpenResponsesApp: App {
    @StateObject private var chatViewModel = AppContainer.shared.makeChatViewModel()

    init() {
        // Migrate API key from UserDefaults to Keychain on first launch
        KeychainService.shared.migrateApiKeyFromUserDefaults()
        
        // Migrate any existing MCP auth from old format to secure keychain
        migrateMCPAuthToKeychain()
    }
    
    /// Migrates any existing MCP authentication from insecure storage to keychain
    private func migrateMCPAuthToKeychain() {
        // This ensures existing users get secure storage without losing their tokens
        let defaults = UserDefaults.standard
        
        // Check if migration marker exists
        if defaults.bool(forKey: "mcp_auth_migrated_to_keychain") {
            return // Already migrated
        }
        
        // Migrate any existing discovery service configurations
        Task { @MainActor in
            MCPDiscoveryService.shared.configurations.forEach { config in
                if !config.authConfiguration.isEmpty {
                    // Re-save configuration to trigger keychain migration
                    MCPDiscoveryService.shared.updateConfiguration(config)
                }
            }
        }
        
        // Set migration marker
        defaults.set(true, forKey: "mcp_auth_migrated_to_keychain")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatViewModel)
        }
    }
}
