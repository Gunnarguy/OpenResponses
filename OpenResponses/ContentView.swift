// FILE: OpenResponses/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showingSettings = false
    private let keychainService = KeychainService.shared

    init() {
        // Note: Per your file list, the newer ChatViewModel initializer does not require the API service to be passed.
        _viewModel = StateObject(wrappedValue: ChatViewModel())
    }

    var body: some View {
        ChatView() // ChatView now uses @EnvironmentObject, so no need to pass the viewModel here.
            .onAppear(perform: checkAPIKey)
            .sheet(isPresented: $showingSettings) {
                // This sheet presents our compliant SettingsView if no key is found.
                SettingsView()
                    .environmentObject(viewModel) // Ensure the environment object is passed to the sheet.
            }
    }

    private func checkAPIKey() {
        if keychainService.load(forKey: "openAIKey") == nil {
            // If no key is found on the very first appearance,
            // present the settings sheet to the user.
            self.showingSettings = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
