// FILE: OpenResponses/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showingSettings = false
    @State private var showingConversationList = false
    @State private var showingShareSheet = false
    @State private var showingOnboarding = false
    private let keychainService = KeychainService.shared

    init() {
        _viewModel = StateObject(wrappedValue: AppContainer.shared.makeChatViewModel())
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
                    
                    ToolbarItem(placement: .principal) {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(viewModel.messages.isEmpty)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .onAppear(perform: checkOnboardingAndAPIKey)
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            checkAPIKey()
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingConversationList) {
            ConversationListView(isPresented: $showingConversationList)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [viewModel.exportConversationText()])
        }
        .environmentObject(viewModel)
    }

    private func checkOnboardingAndAPIKey() {
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if !hasCompletedOnboarding {
            // Show onboarding first
            showingOnboarding = true
        } else if keychainService.load(forKey: "openAIKey") == nil {
            // If onboarding is done but no API key, show settings
            showingSettings = true
        }
        // Ensure MCP is bootstrapped ubiquitously once a configuration exists
        MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
    }
    
    private func checkAPIKey() {
        if keychainService.load(forKey: "openAIKey") == nil {
            self.showingSettings = true
        }
        // Re-apply MCP bootstrap after onboarding or API key updates
        MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer.shared.makeChatViewModel())
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
