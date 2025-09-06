// FILE: OpenResponses/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showingSettings = false
    @State private var showingConversationList = false
    private let keychainService = KeychainService.shared

    init() {
        _viewModel = StateObject(wrappedValue: ChatViewModel())
    }

    var body: some View {
        NavigationView {
            ChatView()
                .navigationBarTitle(viewModel.activeConversation?.title ?? "Chat", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingConversationList = true }) {
                            Image(systemName: "sidebar.left")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .onAppear(perform: checkAPIKey)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingConversationList) {
            ConversationListView(isPresented: $showingConversationList)
        }
        .environmentObject(viewModel)
    }

    private func checkAPIKey() {
        if keychainService.load(forKey: "openAIKey") == nil {
            self.showingSettings = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
