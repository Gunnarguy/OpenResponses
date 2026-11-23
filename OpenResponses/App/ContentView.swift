// FILE: OpenResponses/ContentView.swift
import StoreKit
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif
    @ObservedObject private var reviewPrompt = ReviewPromptService.shared
    @ObservedObject private var proStore = ProStore.shared
    @State private var showingSettings = false
    @State private var showingConversationList = false
    @State private var showingShareSheet = false
    @State private var showingOnboarding = false
    @State private var showingExploreWelcome = false
    private let keychainService = KeychainService.shared

    var body: some View {
        rootContent
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
            if phase == .active { viewModel.takeSharedInbox(); showPendingPaywall() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedInboxDidChange)) { _ in
            viewModel.takeSharedInbox()
            showPendingPaywall()
        }
        // OpenResponses Pro (3.1): StoreKit listens for transactions from launch.
        .task { proStore.start() }
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
        .platformFullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingExploreWelcome) {
            ExploreModeWelcomeSheet(openSettings: {
                showingSettings = true
            })
            .environmentObject(viewModel)
            .macSheetFrame(width: 520, height: 560)
        }
        // Sheets get ChatViewModel explicitly: the Mac Catalyst build does not carry the window's environment object
        // into a sheet, and Settings stopped the app with "No ObservableObject of type ChatViewModel found" (2026-11-22).
        #if os(macOS)
        // The Mac's Settings is its own window (Settings scene), not a sheet.
        .onChange(of: showingSettings) { _, show in
            guard show else { return }
            showingSettings = false
            openSettings()
        }
        #else
        .sheet(isPresented: $showingSettings) {
            Group {
                SettingsHomeView()
                    .environmentObject(viewModel)
            }
            .macSheetFrame(width: 560, height: 620)
        }
        #endif
        .sheet(isPresented: $showingConversationList) {
            ConversationListView(isPresented: $showingConversationList)
                .environmentObject(viewModel)
                .macSheetFrame(width: 520, height: 620)
        }
        .sheet(isPresented: $showingShareSheet) { ShareSheet(items: [viewModel.exportConversationText()]) }
        // Settings presents its own paywall while it is open; this one covers the chat screen and shortcuts.
        .sheet(item: Binding(get: { showingSettings ? nil : proStore.paywall }, set: { proStore.paywall = $0 })) { feature in
            ProPaywallView(store: proStore, feature: feature)
                .environmentObject(viewModel)
                .macSheetFrame(width: 480, height: 600)
        }
    }

    /// The window's content: a sidebar of conversations beside the chat on the Mac, as OpenIntelligence's Mac app
    /// is laid out; a navigation stack with the conversations in a sheet on iPhone and iPad.
    @ViewBuilder private var rootContent: some View {
        #if os(macOS)
        NavigationSplitView {
            MacConversationSidebar()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            ChatView()
                // Mac controls: the chat's icon buttons and menus without the gray bezel AppKit gives a custom-labeled
                // button, and no focus rings. Applied to the chat only, so the window toolbar keeps its own look.
                .buttonStyle(.borderless)
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .focusEffectDisabled()
                .navigationSplitViewColumnWidth(min: 480, ideal: 820)
                .navigationTitle(viewModel.activeConversation?.title ?? "New Chat")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if viewModel.lastResponseId != nil {
                            Button { viewModel.compactCurrentConversation() } label: {
                                Label("Compact Context", systemImage: "archivebox")
                            }
                            .help("Compact the conversation's context on OpenAI")
                        }
                        Button { showingShareSheet = true } label: {
                            Label("Share Conversation", systemImage: "square.and.arrow.up")
                        }
                        .help("Share or copy the conversation")
                        .disabled(viewModel.messages.isEmpty)
                        SettingsLink {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .help("Settings (⌘,)")
                    }
                }
        }
        // Min and max both: with only a minimum, the frame let the split view pick its own ideal height (1,478
        // points, the sidebar list's), and the chat's input ended up below the window (2026-11-22).
        .frame(minWidth: 760, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
        #else
        NavigationStack {
            ChatView()
                .navigationTitle(viewModel.activeConversation?.title ?? "Chat")
                .inlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .leadingBar) {
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

                    ToolbarItem(placement: .trailingBar) {
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
        #endif
    }

    /// A locked shortcut (New Chat) asks for the paywall through the App Group; show it once the app is in front.
    private func showPendingPaywall() {
        if let feature = ProAccess.takePendingPaywall(), !proStore.isPro { proStore.showPaywall(feature) }
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

#if os(macOS)
/// The Mac's share panel, as a Mac app offers sharing: the system Share menu, plus Copy for text or Save for a file.
struct ShareSheet: View {
    let items: [Any]
    @Environment(\.dismiss) private var dismiss

    private var text: String { items.compactMap { $0 as? String }.joined(separator: "\n\n") }
    private var file: URL? { items.compactMap { $0 as? URL }.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(file == nil ? "Share Conversation" : "Share File").font(.headline)
            Text(file?.lastPathComponent ?? "Send the conversation's text to another app, or copy it.")
                .foregroundStyle(.secondary)
            HStack {
                if let file {
                    ShareLink(item: file) { Label("Share…", systemImage: "square.and.arrow.up") }
                    Button { save(file) } label: { Label("Save…", systemImage: "square.and.arrow.down") }
                } else {
                    ShareLink(item: text) { Label("Share…", systemImage: "square.and.arrow.up") }
                    Button {
                        UIPasteboard.general.string = text
                        dismiss()
                    } label: { Label("Copy", systemImage: "doc.on.doc") }
                }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func save(_ file: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.lastPathComponent
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.copyItem(at: file, to: destination)
        dismiss()
    }
}
#else
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
#endif
