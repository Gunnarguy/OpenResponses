// FILE: OpenResponses/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showingSettings = false
    @State private var showingConversationList = false
    @State private var showingShareSheet = false
    @State private var showingOnboarding = false
    @State private var showingExploreWelcome = false
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
.onReceive(NotificationCenter.default.publisher(for: .openAIKeyDidChange)) { _ in
    checkAPIKey()
}
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
        .sheet(isPresented: $showingExploreWelcome) {
            ExploreModeWelcomeSheet(openSettings: {
                showingSettings = true
            })
        }
        .sheet(isPresented: $showingSettings) {
            SettingsHomeView()
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
        } else if isMissingOpenAIKey, !viewModel.exploreModeEnabled { 
            // If onboarding is done but no API key, offer Explore Demo or Settings
            showingExploreWelcome = true
        }
        // Ensure MCP is bootstrapped ubiquitously once a configuration exists
        MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
    }

    private func checkAPIKey() {
        if isMissingOpenAIKey, !viewModel.exploreModeEnabled { 
            self.showingExploreWelcome = true
        }
        // Re-apply MCP bootstrap after onboarding or API key updates
        MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
    }

    private var isMissingOpenAIKey: Bool {
        let key = keychainService.load(forKey: "openAIKey")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return key?.isEmpty != false
    }
}

#Preview {
    ContentView()
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
