//
//  OpenResponsesApp.swift
//  OpenResponses
//
//  Created by Gunnar Hostetler on 6/27/25.
//

import SwiftUI

@main
struct OpenResponsesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var storageBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    @StateObject private var chatViewModel = AppContainer.shared.makeChatViewModel()

    init() {
        // Migrate API key from UserDefaults to Keychain on first launch
        KeychainService.shared.migrateApiKeyFromUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatViewModel)
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    if storageBackgroundTask == .invalid {
                        storageBackgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Save conversations") {
                            if storageBackgroundTask != .invalid {
                                UIApplication.shared.endBackgroundTask(storageBackgroundTask)
                                storageBackgroundTask = .invalid
                            }
                        }
                    }
                    Task {
                        await chatViewModel.flushConversationStorage()
                        if storageBackgroundTask != .invalid {
                            UIApplication.shared.endBackgroundTask(storageBackgroundTask)
                            storageBackgroundTask = .invalid
                        }
                    }
                }
        }
    }
}
