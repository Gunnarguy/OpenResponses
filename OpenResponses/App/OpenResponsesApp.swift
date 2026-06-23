//
//  OpenResponsesApp.swift
//  OpenResponses
//
//  Created by Gunnar Hostetler on 6/27/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics

@main
struct OpenResponsesApp: App {
    @StateObject private var chatViewModel = AppContainer.shared.makeChatViewModel()

    init() {
        // Initialize Firebase Telemetry
        FirebaseApp.configure()
        
        // Migrate API key from UserDefaults to Keychain on first launch
        KeychainService.shared.migrateApiKeyFromUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatViewModel)
        }
    }
}
