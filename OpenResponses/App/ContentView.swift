// FILE: OpenResponses/ContentView.swift
import StoreKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var reviewPrompt = ReviewPromptService.shared
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
        // A chat turn just stopped streaming: count the answer, which may make this the moment to ask for a rating.
        .onChange(of: viewModel.isStreaming) { wasStreaming, isStreaming in
            guard wasStreaming, !isStreaming else { return }
            reviewPrompt.noteTurnEnded(lastMessage: viewModel.messages.last, exploreDemo: viewModel.exploreModeEnabled)
        }
        .onChange(of: reviewPrompt.wantsPrompt) { _, wants in
            if wants { askForRatingWhenInFront() }
        }
        // A request held because the app was not in front, or because the next answer had started, is made on return.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, reviewPrompt.wantsPrompt { askForRatingWhenInFront() }
            // Text and files from the share sheet or the New Chat shortcut open as a new chat (3.1).
            if phase == .active { viewModel.takeSharedInbox() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedInboxDidChange)) { _ in
            viewModel.takeSharedInbox()
        }
        // The model menus list the account's newer models too, with settings from OpenAI's docs pages; one GET /models
        // per launch keeps them current.
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

    /// Hands the rating request to StoreKit two seconds after the answer landed, and only while the app is in front
    /// with no answer streaming and onboarding closed. Held otherwise, and "asked" is recorded only when the request
    /// was made, so a version's one ask is never spent where no sheet can show. Apple decides whether the sheet shows.
    private func askForRatingWhenInFront() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard reviewPrompt.wantsPrompt, scenePhase == .active, !viewModel.isStreaming, !showingOnboarding else {
                return
            }
            requestReview()
            AppLogger.log("Rating request handed to StoreKit", category: .ui, level: .info)
            reviewPrompt.didAsk()
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
