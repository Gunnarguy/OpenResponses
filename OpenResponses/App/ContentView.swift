// FILE: OpenResponses/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingSettings = false
    @State private var showingConversationList = false
    @State private var showingShareSheet = false
    @State private var showingOnboarding = false
    @State private var showingExploreWelcome = false
    private let keychainService = KeychainService.shared

    var body: some View {
        NavigationStack {
            ChatView()
                .navigationTitle(viewModel.activeConversation?.title ?? "Chat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingConversationList = true }) {
                            Image(systemName: "sidebar.left")
                        }
                        .accessibilityLabel("Conversations")
                        .accessibilityIdentifier("conversationsButton")
                    }

                    ToolbarItem(placement: .principal) {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share conversation")
                        .disabled(viewModel.messages.isEmpty)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            if viewModel.lastResponseId != nil {
                                Button(action: { viewModel.compactCurrentConversation() }) {
                                    Image(systemName: "archivebox")
                                }
                                .accessibilityLabel("Compact Context")
                            }
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                            .accessibilityLabel("Settings")
                            .accessibilityIdentifier(AccessibilityUtils.Identifier.settingsButton)
                        }
                    }
                }
        }
        .onAppear(perform: checkOnboardingAndAPIKey)
        // The model menus list the account's newer models too; one GET /models per launch keeps them current.
        .task { await viewModel.refreshAccountModels() }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            checkAPIKey()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAIKeyDidChange)) { _ in
            checkAPIKey()
            Task { await viewModel.refreshAccountModels() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowFullSettings"))) { _ in
            showingSettings = true
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
        if AppFeatureFlags.isMCPAvailable {
            MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
        }
    }

    private func checkAPIKey() {
        if isMissingOpenAIKey, !viewModel.exploreModeEnabled {
            self.showingExploreWelcome = true
        }
        if AppFeatureFlags.isMCPAvailable {
            MCPConfigurationService.shared.bootstrap(chatViewModel: viewModel)
        }
    }

    private var isMissingOpenAIKey: Bool {
        let key = keychainService.load(forKey: "openAIKey")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return key?.isEmpty != false
    }
}

#Preview {
    ContentView().environmentObject(AppContainer.shared.makeChatViewModel())
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
