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
                .appTextSize()
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
        .commands { OpenResponsesCommands(chatViewModel: chatViewModel) }
    }
}

/// Menu-bar commands on the Mac, which iPad shows as keyboard shortcuts (3.1).
struct OpenResponsesCommands: Commands {
    @ObservedObject var chatViewModel: ChatViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Chat") { chatViewModel.createNewConversation() }
                .keyboardShortcut("n")
                .disabled(chatViewModel.isStreaming)
        }
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowFullSettings"), object: nil)
            }
            .keyboardShortcut(",")
        }
    }
}
