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
    #if !os(macOS)
    @State private var storageBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif
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
                    #if os(macOS)
                    // A Mac app keeps running in the background, so there is no task to ask the system for.
                    Task { await chatViewModel.flushConversationStorage() }
                    #else
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
                    #endif
                }
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 800)
        .commands {
            OpenResponsesCommands(chatViewModel: chatViewModel)
            SidebarCommands()
            ToolbarCommands()
        }
        #else
        .commands { OpenResponsesCommands(chatViewModel: chatViewModel) }
        #endif

        #if os(macOS)
        // Settings… and ⌘, open this window, as in every Mac app (OpenIntelligence does the same).
        Settings {
            SettingsHomeView()
                .environmentObject(chatViewModel)
        }
        .windowResizability(.contentMinSize)
        #endif
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
        #if !os(macOS)
        // iPad shows this as a keyboard shortcut; the Mac's Settings scene provides Settings… and ⌘, itself.
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowFullSettings"), object: nil)
            }
            .keyboardShortcut(",")
        }
        #endif
    }
}
