import SwiftUI
import UIKit

/// Clean, tabbed Settings container aligned with OpenAI Responses Playground mental model.
/// Tabs: General, Model, Tools, MCP, Advanced
struct SettingsHomeView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @StateObject private var promptLibrary = PromptLibrary()

    @State private var apiKey: String = ""
    @State private var selectedTab: SettingsTab = .general

    // Sheets
    @State private var showingNotionQuickConnect = false
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false
    @State private var showingMCPGallery = false
    @State private var showingRemoteMCPSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Segmented tabs
                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                Group {
                    switch selectedTab {
                    case .general: GeneralTab(apiKey: $apiKey, showingPromptLibrary: $showingPromptLibrary)
                    case .model: ModelTab()
                    case .tools: ToolsTab(
                        showingNotionQuickConnect: $showingNotionQuickConnect,
                        showingFileManager: $showingFileManager
                    )
                    case .mcp: MCPTab(
                        showingConnectorGallery: $showingMCPGallery,
                        showingRemoteSetup: $showingRemoteMCPSheet
                    )
                    case .advanced: AdvancedTab()
                    }
                }
                .animation(.none, value: selectedTab)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                        Text("Settings").font(.headline)
                    }
                }
            }
        }
        .onAppear {
            apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
        }
        .onChange(of: apiKey) { _, newValue in
            KeychainService.shared.save(value: newValue, forKey: "openAIKey")
        }
        .sheet(isPresented: $showingNotionQuickConnect) {
            NotionConnectionView()
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingPromptLibrary) {
            PromptLibraryView(
                library: promptLibrary,
                createPromptFromCurrentSettings: { viewModel.activePrompt }
            )
        }
        .sheet(isPresented: $showingMCPGallery) {
            MCPConnectorGalleryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingRemoteMCPSheet) {
            RemoteMCPSetupSheet()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Tabs

private enum SettingsTab: CaseIterable {
    case general, model, tools, mcp, advanced

    var title: String {
        switch self {
        case .general:  return "General"
        case .model:    return "Model"
        case .tools:    return "Tools"
        case .mcp:      return "MCP"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var apiKey: String
    @Binding var showingPromptLibrary: Bool
    @State private var savingDefault = false
    @State private var resetConfirm = false

    var body: some View {
        Form {
            Section(header: Label("API", systemImage: "key.fill")) {
                HStack(spacing: 8) {
                    SecureField("OpenAI API Key (sk-...)", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    if !apiKey.isEmpty {
                        Button {
                            apiKey = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle("Store Responses on OpenAI", isOn: $viewModel.activePrompt.storeResponses)
                Text("Disable if you prefer responses to be ephemeral on OpenAI's side.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, -4)
            }

            Section(header: Label("Streaming", systemImage: "bolt.horizontal.circle")) {
                Toggle("Enable Streaming", isOn: $viewModel.activePrompt.enableStreaming)

                Toggle("Include Usage Events", isOn: $viewModel.activePrompt.streamIncludeUsage)
                    .disabled(!viewModel.activePrompt.enableStreaming)
                Text("Stream token counts as they're produced.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
                    .opacity(viewModel.activePrompt.enableStreaming ? 1 : 0.4)

                Toggle("Include Obfuscated Segments", isOn: $viewModel.activePrompt.streamIncludeObfuscation)
                    .disabled(!viewModel.activePrompt.enableStreaming)
                Text("Surface redaction markers rather than hiding sensitive spans.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
                    .opacity(viewModel.activePrompt.enableStreaming ? 1 : 0.4)
            }

            Section(header: Label("Published Prompt", systemImage: "doc.text.fill")) {
                Toggle("Use Published Prompt", isOn: $viewModel.activePrompt.enablePublishedPrompt)
                if viewModel.activePrompt.enablePublishedPrompt {
                    TextField("Published Prompt ID", text: $viewModel.activePrompt.publishedPromptId)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            }

            Section(header: Label("Request Identity", systemImage: "person.badge.key.fill")) {
                TextField("Safety Identifier (hashed user id)", text: $viewModel.activePrompt.safetyIdentifier)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                Text("Use a stable hash (e.g., SHA256 of a user id) to help detect abuse across sessions.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                TextField("Prompt Cache Key", text: $viewModel.activePrompt.promptCacheKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                Text("Reuse cached system/developer prompts for faster warm starts.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section(header: Label("Persistence", systemImage: "tray.and.arrow.down.fill")) {
                Button {
                    savingDefault = true
                    // Persist current prompt (already persists on change; this is an explicit affordance)
                    viewModel.saveActivePrompt()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { savingDefault = false }
                } label: {
                    Label(savingDefault ? "Saving..." : "Save as Default", systemImage: savingDefault ? "clock" : "square.and.arrow.down")
                }
                .disabled(savingDefault)

                Button(role: .destructive) {
                    resetConfirm = true
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                .alert("Reset Settings", isPresented: $resetConfirm) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        viewModel.resetToDefaultPrompt()
                    }
                } message: {
                    Text("This will restore all settings to factory defaults.")
                }
            }

            Section(header: Label("Presets", systemImage: "book.fill")) {
                Button {
                    showingPromptLibrary = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Prompt Library")
                                .fontWeight(.medium)
                            Text("Save and load prompt configurations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Model

private struct ModelTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Form {
            Section {
                ModelConfigurationView(
                    activePrompt: $viewModel.activePrompt,
                    openAIService: AppContainer.shared.openAIService,
                    onSave: { viewModel.saveActivePrompt() }
                )
            }
        }
    }
}

// MARK: - Tools

private struct ToolsTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    
    @Binding var showingNotionQuickConnect: Bool
    @Binding var showingFileManager: Bool
    @State private var hasNotionIntegrationToken: Bool = KeychainService.shared.load(forKey: "notionApiKey")?.isEmpty == false
    @AppStorage("hasShownComputerUseDisclosure") private var hasShownComputerUseDisclosure = false
    @State private var showComputerUseDisclosure = false

    private var isImageGenerationSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(
            .imageGeneration,
            for: viewModel.activePrompt.openAIModel,
            isStreaming: viewModel.activePrompt.enableStreaming
        )
    }

    var body: some View {
        Form {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("About Tools")
                            .fontWeight(.semibold)
                    }
                    Text("Enable AI capabilities like web search, code execution, and image generation. Connect external services like Notion for direct access to your data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // Direct Integrations
            Section(header: Label("Direct Integrations", systemImage: "link")) {
                Toggle("Enable Notion Integration", isOn: $viewModel.activePrompt.enableNotionIntegration)
                    .disabled(!hasNotionIntegrationToken)
                if !hasNotionIntegrationToken {
                    Text("Connect Notion to enable workspace tools.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button {
                    showingNotionQuickConnect = true
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundColor(.black)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect Notion")
                                .fontWeight(.medium)
                            Text("Access your databases and pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            #if canImport(EventKit)
            // Apple System Integrations
            Section(header: Label("Apple System Integrations", systemImage: "apple.logo")) {
                Toggle("Enable Apple Integrations", isOn: $viewModel.activePrompt.enableAppleIntegrations)
                if viewModel.activePrompt.enableAppleIntegrations {
                    AppleIntegrationsCard()
                } else {
                    Text("Allow the assistant to access Calendar, Reminders, and Contacts when needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            #endif
            
            // File & Vector Store Management
            Section(header: Label("File Management", systemImage: "doc.fill")) {
                Button {
                    showingFileManager = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manage Files & Vector Stores")
                                .fontWeight(.medium)
                            Text("Upload files, create vector stores, enable file search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }

                Toggle("Enable File Search", isOn: $viewModel.activePrompt.enableFileSearch)

                if viewModel.activePrompt.enableFileSearch {
                    TextField("Vector Store IDs (comma-separated)", text: $viewModel.activePrompt.selectedVectorStoreIds.bound)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Search through uploaded files in your vector stores")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DisclosureGroup("Advanced Options") {
                        HStack {
                            Text("Max Results").font(.caption)
                            Spacer()
                            Text(viewModel.activePrompt.fileSearchMaxResults.map { "\($0)" } ?? "Default (10)")
                                .font(.caption).foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.activePrompt.fileSearchMaxResults ?? 10) },
                                set: { viewModel.activePrompt.fileSearchMaxResults = Int($0) }
                            ),
                            in: 1...50, step: 1
                        )

                        Text("Ranker").font(.caption)
                        Picker("", selection: $viewModel.activePrompt.fileSearchRanker.bound) {
                            Text("Auto").tag(Optional<String>.none)
                            Text("Auto (Explicit)").tag(Optional("auto"))
                            Text("Default 2024-08-21").tag(Optional("default-2024-08-21"))
                        }
                        .pickerStyle(.segmented)

                        Toggle("Use Score Threshold", isOn: fileSearchThresholdBinding)
                        if viewModel.activePrompt.fileSearchScoreThreshold != nil {
                            Slider(
                                value: Binding(
                                    get: { viewModel.activePrompt.fileSearchScoreThreshold ?? 0.5 },
                                    set: { value in
                                        viewModel.activePrompt.fileSearchScoreThreshold = roundedScoreThreshold(value)
                                    }
                                ),
                                in: 0...1
                            )
                            let threshold = viewModel.activePrompt.fileSearchScoreThreshold ?? 0
                            Text("Ignore matches below \(String(format: "%.2f", threshold)) confidence.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider().padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Attribute Filters JSON")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextEditor(text: $viewModel.activePrompt.fileSearchFiltersJSON.bound)
                                .frame(minHeight: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2))
                                )

                            Text("Provide a comparison/compound filter payload (see Responses API docs). Leave blank to search all records.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Enable file search to let the assistant query uploaded documents.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // OpenAI Tools
            Section(header: Label("OpenAI Tools", systemImage: "wand.and.stars")) {
                Text("Native capabilities powered by OpenAI's API")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Computer Use
            Section(header: Label("Computer Use", systemImage: "display")) {
                let isSupported = ModelCompatibilityService.shared.isToolSupported(
                    .computer,
                    for: viewModel.activePrompt.openAIModel,
                    isStreaming: viewModel.activePrompt.enableStreaming
                )

                let computerUseBinding = Binding(
                    get: { viewModel.activePrompt.enableComputerUse },
                    set: { newValue in
                        guard newValue != viewModel.activePrompt.enableComputerUse else { return }
                        if newValue && !hasShownComputerUseDisclosure {
                            showComputerUseDisclosure = true
                        } else {
                            viewModel.activePrompt.enableComputerUse = newValue
                        }
                        if !newValue {
                            viewModel.activePrompt.enableComputerUse = false
                        }
                    }
                )

                Toggle("Enable Computer Use", isOn: computerUseBinding)
                    .disabled(!isSupported)
                    .alert("Enable Computer Use?", isPresented: $showComputerUseDisclosure) {
                        Button("Continue", role: .none) {
                            viewModel.activePrompt.enableComputerUse = true
                            hasShownComputerUseDisclosure = true
                            showComputerUseDisclosure = false
                        }
                        Button("Cancel", role: .cancel) {
                            viewModel.activePrompt.enableComputerUse = false
                            showComputerUseDisclosure = false
                        }
                    } message: {
                        Text("Computer Use connects to your approved bridge over the local network and can control apps when you approve each step. Keep the review sheet open and only allow actions you trust.")
                    }

                if !isSupported {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Not supported by current model. Switch to computer-use-preview to enable it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.activePrompt.enableComputerUse {
                    Toggle("Ultra-strict Mode", isOn: $viewModel.activePrompt.ultraStrictComputerUse)
                        .tint(.red)
                    Text("Disables app-side helpers like pre-navigation and click-by-text for maximum model control.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            webSearchSection

            // Code Interpreter
            Section(header: Label("Code Interpreter", systemImage: "terminal.fill")) {
                Toggle("Enable Python Sandbox", isOn: $viewModel.activePrompt.enableCodeInterpreter)

                if viewModel.activePrompt.enableCodeInterpreter {
                    // Force auto to avoid API 400s per service comments
                    HStack {
                        Text("Container Type").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("auto").font(.caption).foregroundColor(.green)
                    }

                    TextField("Preload File IDs (comma-separated)", text: $viewModel.activePrompt.codeInterpreterPreloadFileIds.bound)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Files to make available in the Python environment")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            // Image Generation
            Section(header: Label("Image Generation", systemImage: "photo.artframe")) {
                Toggle("Enable DALL-E", isOn: $viewModel.activePrompt.enableImageGeneration)
                    .disabled(!isImageGenerationSupported)
                if !isImageGenerationSupported {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Not supported by current model or streaming mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.activePrompt.enableImageGeneration {
                    TextField("Image Model", text: $viewModel.activePrompt.imageGenerationModel)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    Picker("Size", selection: $viewModel.activePrompt.imageGenerationSize) {
                        Text("Auto").tag("auto")
                        Text("1024×1024").tag("1024x1024")
                        Text("1024×1536").tag("1024x1536")
                        Text("1536×1024").tag("1536x1024")
                    }
                    .pickerStyle(.segmented)

                    Picker("Quality", selection: $viewModel.activePrompt.imageGenerationQuality) {
                        Text("Auto").tag("auto")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)

                    Picker("Output", selection: $viewModel.activePrompt.imageGenerationOutputFormat) {
                        Text("PNG").tag("png")
                        Text("WEBP").tag("webp")
                        Text("JPEG").tag("jpeg")
                    }
                    .pickerStyle(.segmented)

                    Picker("Background", selection: $viewModel.activePrompt.imageGenerationBackground) {
                        Text("Auto").tag("auto")
                        Text("Transparent").tag("transparent")
                        Text("Opaque").tag("opaque")
                    }
                    .pickerStyle(.segmented)

                    Text("Model, size, quality, and format map directly to the Responses API image_generation tool inputs.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Label("Custom Function Tool", systemImage: "hammer.fill")) {
                Toggle("Enable Custom Tool", isOn: $viewModel.activePrompt.enableCustomTool)

                if viewModel.activePrompt.enableCustomTool {
                    TextField("Function Name", text: $viewModel.activePrompt.customToolName)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    TextField("Short Description", text: $viewModel.activePrompt.customToolDescription)

                    Picker("Execution", selection: $viewModel.activePrompt.customToolExecutionType) {
                        Text("Echo").tag("echo")
                        Text("Calculator").tag("calculator")
                        Text("Webhook").tag("webhook")
                    }
                    .pickerStyle(.segmented)

                    if viewModel.activePrompt.customToolExecutionType == "webhook" {
                        TextField("Webhook URL", text: $viewModel.activePrompt.customToolWebhookURL)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Parameters JSON")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $viewModel.activePrompt.customToolParametersJSON)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )

                        Text("Matches the function tool schema sent to the model.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Expose a single function-style tool that the assistant can call.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear { refreshNotionTokenStatus() }
        .onChange(of: showingNotionQuickConnect) { _, isPresented in
            if !isPresented { refreshNotionTokenStatus() }
        }
    }

    private func refreshNotionTokenStatus() {
        // Keep the toggle in sync with whether a Notion token is currently stored
        let tokenAvailable = KeychainService.shared.load(forKey: "notionApiKey")?.isEmpty == false
        hasNotionIntegrationToken = tokenAvailable
        if !tokenAvailable && viewModel.activePrompt.enableNotionIntegration {
            viewModel.activePrompt.enableNotionIntegration = false
            viewModel.saveActivePrompt()
        }
    }

    private var fileSearchThresholdBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.fileSearchScoreThreshold != nil },
            set: { enabled in
                if enabled {
                    if viewModel.activePrompt.fileSearchScoreThreshold == nil {
                        viewModel.activePrompt.fileSearchScoreThreshold = 0.5
                    }
                } else {
                    viewModel.activePrompt.fileSearchScoreThreshold = nil
                }
            }
        )
    }

    private func roundedScoreThreshold(_ raw: Double) -> Double {
        let clamped = min(max(raw, 0), 1)
        return Double((clamped * 100).rounded() / 100)
    }

    private enum WebSearchModeSelection: Hashable {
        case defaultMode
        case custom
    }

    private var webSearchSection: some View {
        Section(header: Label("Web Search", systemImage: "magnifyingglass.circle.fill")) {
            Toggle("Enable Web Search", isOn: $viewModel.activePrompt.enableWebSearch)

            if viewModel.activePrompt.enableWebSearch {
                webSearchModePicker
                webSearchInstructionsEditor
                webSearchAdvancedControls
            } else {
                Text("Keep the toggle on to let the assistant gather fresh context from the web.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var webSearchModePicker: some View {
        Picker("Search Focus", selection: webSearchModeSelection) {
            Text("General Web").tag(WebSearchModeSelection.defaultMode)
            Text("Specialized").tag(WebSearchModeSelection.custom)
        }
        .pickerStyle(.segmented)

        if webSearchModeSelection.wrappedValue == .custom {
            TextField("Enter the code OpenAI provided (for example, news)", text: $viewModel.activePrompt.webSearchMode)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }

        Text("General Web uses OpenAI's standard web index. Choose Specialized only if OpenAI gave you a profile code (like \"news\") for a focused dataset.")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var webSearchInstructionsEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Search Instructions (optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.activePrompt.webSearchInstructions)
                    .frame(minHeight: 70)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))

                if viewModel.activePrompt.webSearchInstructions.isEmpty {
                    Text("Highlight sources, tone, or queries to prioritize.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 6)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    @ViewBuilder
    private var webSearchAdvancedControls: some View {
        // Mirrors web_search tuning options from API/ResponsesAPI.md
        DisclosureGroup("Advanced Tuning") {
            Toggle("Limit Pages", isOn: webSearchPagesBinding)
            if viewModel.activePrompt.webSearchMaxPages > 0 {
                Stepper(
                    "Max Pages: \(viewModel.activePrompt.webSearchMaxPages)",
                    value: Binding(
                        get: { max(viewModel.activePrompt.webSearchMaxPages, 1) },
                        set: { viewModel.activePrompt.webSearchMaxPages = max(min($0, 20), 1) }
                    ),
                    in: 1...20
                )
            }

            Toggle("Limit Crawl Depth", isOn: webSearchDepthBinding)
            if viewModel.activePrompt.webSearchCrawlDepth > 0 {
                Stepper(
                    "Crawl Depth: \(viewModel.activePrompt.webSearchCrawlDepth)",
                    value: Binding(
                        get: { max(viewModel.activePrompt.webSearchCrawlDepth, 1) },
                        set: { viewModel.activePrompt.webSearchCrawlDepth = max(min($0, 5), 1) }
                    ),
                    in: 1...5
                )
                Text("Higher depth follows additional links on each page.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider().padding(.vertical, 4)

            TextField("Allowed Domains (comma-separated)", text: $viewModel.activePrompt.webSearchAllowedDomains.bound)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            Text("Restrict search results to trusted domains when populated.")
                .font(.caption2)
                .foregroundColor(.secondary)

            TextField("Blocked Domains (comma-separated)", text: $viewModel.activePrompt.webSearchBlockedDomains.bound)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            Text("Exclude specific hosts from web search results.")
                .font(.caption2)
                .foregroundColor(.secondary)

            Divider().padding(.vertical, 4)

            Text("Approximate User Location")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                TextField("City", text: $viewModel.activePrompt.userLocationCity.bound)
                TextField("Region", text: $viewModel.activePrompt.userLocationRegion.bound)
                TextField("Country (ISO code)", text: $viewModel.activePrompt.userLocationCountry.bound)
                TextField("Timezone (e.g. America/Los_Angeles)", text: $viewModel.activePrompt.userLocationTimezone.bound)
            }
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
        }
    }

    private var webSearchModeSelection: Binding<WebSearchModeSelection> {
        Binding(
            get: {
                viewModel.activePrompt.webSearchMode == "default"
                ? .defaultMode
                : .custom
            },
            set: { selection in
                switch selection {
                case .defaultMode:
                    viewModel.activePrompt.webSearchMode = "default"
                case .custom:
                    if viewModel.activePrompt.webSearchMode == "default" {
                        viewModel.activePrompt.webSearchMode = ""
                    }
                }
            }
        )
    }

    private var webSearchPagesBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.webSearchMaxPages > 0 },
            set: { enabled in
                viewModel.activePrompt.webSearchMaxPages = enabled ? max(viewModel.activePrompt.webSearchMaxPages, 5) : 0
            }
        )
    }

    private var webSearchDepthBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.webSearchCrawlDepth > 0 },
            set: { enabled in
                viewModel.activePrompt.webSearchCrawlDepth = enabled ? max(viewModel.activePrompt.webSearchCrawlDepth, 1) : 0
            }
        )
    }
}

// MARK: - Advanced

private struct AdvancedTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingAbout = false

    private var modelCaps: ModelCompatibilityService.ModelCapabilities? {
        ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)
    }

    var body: some View {
        Form {
            toolChoiceSection
            truncationSection
            toolExecutionSection
            responseIncludesSection
            retrievalSection
            metadataSection
            userSection
            appInfoSection
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var appInfoSection: some View {
        Section(header: Label("Application", systemImage: "info.circle")) {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Label("About & Licenses", systemImage: "doc.text.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private var toolChoiceSection: some View {
        Section(header: Label("Tool Choice", systemImage: "switch.2")) {
            Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                Text("Auto").tag("auto")
                Text("Required").tag("required")
                Text("None").tag("none")
            }
            .pickerStyle(.segmented)
        }
    }

    private var truncationSection: some View {
        Section(header: Label("Truncation & Tier", systemImage: "scissors")) {
            Picker("Truncation", selection: $viewModel.activePrompt.truncationStrategy) {
                Text("Disabled").tag("disabled")
                Text("Auto").tag("auto")
            }
            .pickerStyle(.segmented)

            Picker("Service Tier", selection: $viewModel.activePrompt.serviceTier) {
                Text("Auto").tag("auto")
                Text("Default").tag("default")
            }
            .pickerStyle(.segmented)
        }
    }

    private var toolExecutionSection: some View {
        Section(header: Label("Tool Execution", systemImage: "hammer.circle")) {
            Toggle("Allow Parallel Tool Calls", isOn: $viewModel.activePrompt.parallelToolCalls)
            Toggle("Enable Background Mode", isOn: $viewModel.activePrompt.backgroundMode)

            Toggle("Limit Tool Calls", isOn: limitToolCallsBinding)
            if viewModel.activePrompt.maxToolCalls > 0 {
                Stepper(
                    "Max Tool Calls: \(viewModel.activePrompt.maxToolCalls)",
                    value: Binding(
                        get: { max(viewModel.activePrompt.maxToolCalls, 1) },
                        set: { viewModel.activePrompt.maxToolCalls = max(min($0, 32), 1) }
                    ),
                    in: 1...32
                )
            }
        }
    }

    private var responseIncludesSection: some View {
        Section(header: Label("Response Includes", systemImage: "tray.full")) {
            Toggle("Include Computer Use Output", isOn: $viewModel.activePrompt.includeComputerUseOutput)
            Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
            Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
            Toggle("Include Web Search Sources", isOn: $viewModel.activePrompt.includeWebSearchSources)
            Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
            Toggle("Include Code Interpreter Output", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
            Toggle("Include Computer Call Output", isOn: $viewModel.activePrompt.includeComputerCallOutput)

            HStack {
                Toggle("Include Output Logprobs", isOn: includeLogprobBinding)
                    .disabled(modelCaps?.supportsReasoningEffort == true)
                if modelCaps?.supportsReasoningEffort == true {
                    Image(systemName: "info.circle.fill").foregroundColor(.blue)
                }
            }

            if viewModel.activePrompt.includeOutputLogprobs {
                Stepper(
                    "Top Logprobs: \(viewModel.activePrompt.topLogprobs)",
                    value: $viewModel.activePrompt.topLogprobs,
                    in: 1...20
                )
                Text("Higher numbers expose more alternative tokens per position.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                    .disabled(!(modelCaps?.supportsReasoningEffort == true))
                if !(modelCaps?.supportsReasoningEffort == true) {
                    Image(systemName: "info.circle.fill").foregroundColor(.blue)
                }
            }
        }
    }

    private var retrievalSection: some View {
        Section(header: Label("Retrieval Context", systemImage: "text.magnifyingglass")) {
            TextField("Search Context Size (tokens)", text: $viewModel.activePrompt.searchContextSize.bound)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            Text("Overrides automatic chunk size when set. Leave blank for default behavior.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var metadataSection: some View {
        Section(header: Label("Metadata", systemImage: "square.and.pencil")) {
            TextEditor(text: $viewModel.activePrompt.metadata.bound)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            Text("Custom metadata as JSON object (stored in request).")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var userSection: some View {
        Section(header: Label("User", systemImage: "person.crop.circle")) {
            TextField("User Identifier (optional)", text: $viewModel.activePrompt.userIdentifier)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            Text("Legacy identifier still accepted by older models. Prefer Safety Identifier above when possible.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var limitToolCallsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.maxToolCalls > 0 },
            set: { newValue in
                if newValue {
                    if viewModel.activePrompt.maxToolCalls == 0 {
                        viewModel.activePrompt.maxToolCalls = 4
                    }
                } else {
                    viewModel.activePrompt.maxToolCalls = 0
                }
            }
        )
    }

    private var includeLogprobBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.includeOutputLogprobs },
            set: { newValue in
                viewModel.activePrompt.includeOutputLogprobs = newValue
                if newValue && viewModel.activePrompt.topLogprobs == 0 {
                    viewModel.activePrompt.topLogprobs = 5
                }
                if !newValue {
                    viewModel.activePrompt.topLogprobs = 0
                }
            }
        )
    }
}


// MARK: - MCP

private struct MCPTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var showingConnectorGallery: Bool
    @Binding var showingRemoteSetup: Bool

    @State private var isTesting = false
    @State private var diagStatus: String?
    @State private var showClearConfirm = false

    private var prompt: Prompt { viewModel.activePrompt }
    private var headerKey: String {
        normalizedHeaderKey(prompt.mcpAuthHeaderKey)
    }
    private var remoteConfigured: Bool {
        !prompt.mcpIsConnector &&
        !prompt.mcpServerLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !prompt.mcpServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var connectorConfigured: Bool {
        prompt.mcpIsConnector && (prompt.mcpConnectorId ?? "").isEmpty == false
    }
    private var hasConfiguration: Bool { remoteConfigured || connectorConfigured }
    private var mcpEnabled: Bool { prompt.enableMCPTool }

    var body: some View {
        Form {
            Section(header: Label("Status", systemImage: "power")) {
                Toggle(isOn: Binding(
                    get: { viewModel.activePrompt.enableMCPTool },
                    set: { newValue in
                        var updated = viewModel.activePrompt
                        updated.enableMCPTool = newValue
                        viewModel.replaceActivePrompt(with: updated)
                        viewModel.saveActivePrompt()
                    }
                )) {
                    Text("Enable MCP Tools")
                }
                .toggleStyle(.switch)

                Text(mcpEnabled ? "Tool calls will use the configured MCP connector." : "Keep the configuration, but skip MCP tool calls until you re-enable this switch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Label("Current Configuration", systemImage: "bolt.shield")) {
                if remoteConfigured {
                    remoteStatusCard
                } else if connectorConfigured {
                    connectorStatusCard
                } else {
                    Text("No MCP configuration is active. Use the actions below to connect a connector or remote server.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if remoteConfigured {
                Section(header: Label("Diagnostics", systemImage: "waveform.and.magnifyingglass")) {
                    if isTesting {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Testing…")
                        }
                    } else {
                        Button {
                            testMCPConnection()
                        } label: {
                            Label("Test MCP Connection", systemImage: "checkmark.seal")
                        }
                    }

                    if let diagStatus {
                        Text(diagStatus)
                            .font(.caption)
                            .foregroundColor(diagStatus.contains("OK") ? .green : .orange)
                    }
                }
            }

            Section(header: Label("Manage", systemImage: "slider.horizontal.3")) {
                Button {
                    showingConnectorGallery = true
                } label: {
                    Label("Browse Connector Gallery", systemImage: "square.grid.2x2.fill")
                }

                Button {
                    showingRemoteSetup = true
                } label: {
                    Label("Configure Remote Server", systemImage: "server.rack")
                }

                if hasConfiguration {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Remove MCP Configuration", systemImage: "trash")
                    }
                }
            }

            if let guidance = notionGuidance {
                Section {
                    Text(guidance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    .onAppear { diagStatus = nil }
    .onChange(of: prompt.mcpServerLabel) { _, _ in diagStatus = nil }
        .alert("Remove MCP Configuration?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                clearMCPConfiguration()
            }
        } message: {
            Text("This clears connector tokens, remote headers, and diagnostics.")
        }
    }

    private var remoteStatusCard: some View {
        let label = prompt.mcpServerLabel
        let url = prompt.mcpServerURL
        let defaults = UserDefaults.standard
        let probeOk = defaults.bool(forKey: "mcp_probe_ok_\(label)")
        let probeTimestamp = defaults.double(forKey: "mcp_probe_ok_at_\(label)")
        let toolCount = optionalInt(forKey: "mcp_probe_tool_count_\(label)")
        let storedHash = defaults.string(forKey: "mcp_probe_token_hash_\(label)")
        let currentHash = currentTokenHash(for: label, headerKey: headerKey, prompt: prompt)

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.headline)
                Text(url).font(.caption).foregroundColor(.secondary)
            }

            StatusRow(title: "Enabled", value: mcpEnabled ? "On" : "Off", systemImage: "power")
            StatusRow(title: "Mode", value: "Remote server", systemImage: "network")
            StatusRow(title: "Approval", value: approvalDescription(prompt.mcpRequireApproval), systemImage: "checkmark.shield")
            StatusRow(title: "Allowed Tools", value: allowedToolsDescription(prompt.mcpAllowedTools), systemImage: "hammer")
            StatusRow(title: "Token", value: remoteTokenStatus(label: label), systemImage: "key.fill")

            StatusRow(title: "Last Probe", value: probeSummary(ok: probeOk, timestamp: probeTimestamp), systemImage: "waveform")
            if let toolCount {
                StatusRow(title: "Tool Count", value: "\(toolCount)", systemImage: "list.bullet")
            }
            StatusRow(title: "Token Hash", value: hashStatusText(storedHash: storedHash, currentHash: currentHash), systemImage: "fingerprint")

            if let diagStatus {
                Divider()
                Text(diagStatus)
                    .font(.caption)
                    .foregroundColor(diagStatus.contains("OK") ? .green : .orange)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }

    private var connectorStatusCard: some View {
        guard let connectorId = prompt.mcpConnectorId,
              let connector = MCPConnector.connector(for: connectorId) else {
            return AnyView(Text("Configured connector is no longer available.")
                .font(.caption)
                .foregroundColor(.secondary))
        }

        let tokenKey = "mcp_connector_\(connectorId)"
        let tokenStored = KeychainService.shared.load(forKey: tokenKey)?.isEmpty == false

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connector.name).font(.headline)
                    Text(connector.description).font(.caption).foregroundColor(.secondary)
                }

                StatusRow(title: "Mode", value: "Connector", systemImage: "link")
                StatusRow(title: "Connector ID", value: connectorId, systemImage: "number")
                StatusRow(title: "Approval", value: approvalDescription(prompt.mcpRequireApproval), systemImage: "checkmark.shield")
                StatusRow(title: "Allowed Tools", value: allowedToolsDescription(prompt.mcpAllowedTools), systemImage: "hammer")
                StatusRow(title: "Token", value: tokenStored ? "Stored in Keychain" : "Missing", systemImage: "key.fill")
                StatusRow(title: "Enabled", value: mcpEnabled ? "On" : "Off", systemImage: "power")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        )
    }

    private var notionGuidance: String? {
        guard remoteConfigured else { return nil }
        let lowerURL = prompt.mcpServerURL.lowercased()
        let lowerLabel = prompt.mcpServerLabel.lowercased()
        let raw = rawTokenForGuidance(label: prompt.mcpServerLabel, prompt: prompt)
        let looksIntegration = raw.map(tokenLooksLikeNotionIntegration) ?? false

        if lowerURL.contains("mcp.notion.com") {
            if looksIntegration {
                return "Official Notion MCP detected. Your integration token will be sent as top-level authorization (no Authorization header)."
            }
            return "Official Notion MCP requires your Notion Integration token (ntn_/secret_) pasted into the remote setup."
        }

        if lowerURL.contains("notion") || lowerLabel.contains("notion") {
            if looksIntegration {
                return "Self-hosted Notion MCP is using an integration token. Replace it with the Bearer token printed by your server."
            }
            return "Self-hosted Notion MCP servers require the Bearer token emitted by your container logs."
        }

        return nil
    }

    private func testMCPConnection() {
        guard remoteConfigured else { return }
        isTesting = true
        diagStatus = nil
        let currentPrompt = viewModel.activePrompt
        Task {
            do {
                let result = try await AppContainer.shared.openAIService.probeMCPListTools(prompt: currentPrompt)
                await MainActor.run {
                    persistProbeSuccess(label: result.label, count: result.count, prompt: currentPrompt)
                    diagStatus = "MCP list_tools OK (\(result.label)): \(result.count) tools"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    diagStatus = friendlyProbeError(error)
                    isTesting = false
                }
            }
        }
    }

    private func clearMCPConfiguration() {
        var prompt = viewModel.activePrompt
        let oldLabel = prompt.mcpServerLabel
        let oldConnector = prompt.mcpConnectorId

        if let oldConnector {
            KeychainService.shared.delete(forKey: "mcp_connector_\(oldConnector)")
        }
        if !oldLabel.isEmpty {
            KeychainService.shared.delete(forKey: "mcp_manual_\(oldLabel)")
        }

        prompt.enableMCPTool = false
        prompt.mcpIsConnector = false
        prompt.mcpConnectorId = nil
        prompt.mcpServerLabel = ""
        prompt.mcpServerURL = ""
        prompt.mcpAllowedTools = ""
        prompt.mcpRequireApproval = "never"
        prompt.mcpHeaders = ""
        prompt.mcpAuthHeaderKey = "Authorization"
        prompt.mcpKeepAuthInHeaders = false

        viewModel.replaceActivePrompt(with: prompt)
        viewModel.saveActivePrompt()
        viewModel.lastMCPServerLabel = nil

        if !oldLabel.isEmpty {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "mcp_probe_ok_\(oldLabel)")
            defaults.removeObject(forKey: "mcp_probe_ok_at_\(oldLabel)")
            defaults.removeObject(forKey: "mcp_probe_token_hash_\(oldLabel)")
            defaults.removeObject(forKey: "mcp_probe_tool_count_\(oldLabel)")
        }

        diagStatus = nil
    }

    private func approvalDescription(_ raw: String) -> String {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "always": return "Always require approval"
        case "never": return "Never require approval"
        case "prompt", "ask", "review": return "Always require approval"
        case "auto", "": return "Never require approval"
        default: return normalized.capitalized
        }
    }

    private func allowedToolsDescription(_ raw: String) -> String {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.isEmpty { return "All tools" }
        if parts.count <= 3 { return parts.joined(separator: ", ") }
        return "\(parts.count) tools whitelisted"
    }

    private func remoteTokenStatus(label: String) -> String {
        if label.isEmpty { return "Missing" }
        if !prompt.secureMCPHeaders.isEmpty { return "Stored in Keychain" }
        if let stored = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), !stored.isEmpty {
            return "Stored in Keychain"
        }
        return "Missing"
    }

    private func probeSummary(ok: Bool, timestamp: Double) -> String {
        guard timestamp > 0 else { return ok ? "Recorded" : "Never" }
        let formatter = RelativeDateTimeFormatter()
        let date = Date(timeIntervalSince1970: timestamp)
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return ok ? "Pass · \(relative)" : "Fail · \(relative)"
    }

    private func hashStatusText(storedHash: String?, currentHash: String?) -> String {
        switch (storedHash, currentHash) {
        case let (stored?, current?):
            return stored == current ? "Matches last probe" : "Token changed since probe"
        case (nil, _):
            return "Run diagnostics to record"
        case (_, nil):
            return "Token missing"
        }
    }

    private func optionalInt(forKey key: String) -> Int? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.integer(forKey: key)
    }

    private func normalizedHeaderKey(_ raw: String) -> String {
        let base = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = base.isEmpty ? "Authorization" : base
        return key.split(separator: "-").map { part -> String in
            var lower = part.lowercased()
            if lower == "id" { lower = "ID" }
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }.joined(separator: "-")
    }

    private func currentTokenHash(for label: String, headerKey: String, prompt: Prompt) -> String? {
        let headers = prompt.secureMCPHeaders
        if let headerValue = headers[headerKey] ?? headers["Authorization"], !headerValue.isEmpty {
            return NotionAuthService.shared.tokenHash(fromAuthorizationValue: headerValue)
        }
        guard let stored = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), !stored.isEmpty else {
            return nil
        }
        if let data = stored.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let headerValue = obj[headerKey] ?? obj["Authorization"] {
            return NotionAuthService.shared.tokenHash(fromAuthorizationValue: headerValue)
        }
        return NotionAuthService.shared.tokenHash(fromAuthorizationValue: stored)
    }

    private func rawTokenForGuidance(label: String, prompt: Prompt) -> String? {
        let headers = prompt.secureMCPHeaders
        if let headerValue = headers[headerKey] ?? headers["Authorization"], !headerValue.isEmpty {
            return headerValue
        }
        guard let stored = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), !stored.isEmpty else {
            return nil
        }
        if let data = stored.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return obj[headerKey] ?? obj["Authorization"]
        }
        return stored
    }

    private func tokenLooksLikeNotionIntegration(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasPrefix("bearer ") {
            let core = String(lower.dropFirst(7))
            return core.hasPrefix("ntn_") || core.hasPrefix("secret_")
        }
        return lower.hasPrefix("ntn_") || lower.hasPrefix("secret_")
    }

    private func persistProbeSuccess(label: String, count: Int, prompt: Prompt) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "mcp_probe_ok_\(label)")
        defaults.set(Date().timeIntervalSince1970, forKey: "mcp_probe_ok_at_\(label)")
        if let hash = currentTokenHash(for: label, headerKey: headerKey, prompt: prompt) {
            defaults.set(hash, forKey: "mcp_probe_token_hash_\(label)")
        }
        defaults.set(count, forKey: "mcp_probe_tool_count_\(label)")
    }

    private func friendlyProbeError(_ error: Error) -> String {
        let message = error.localizedDescription
        let lower = message.lowercased()
        if lower.contains("401") || lower.contains("unauthorized") {
            return "Probe failed: Unauthorized (401). Check the token."
        }
        if lower.contains("timeout") || lower.contains("timed out") {
            return "Probe failed: Connection timed out. Verify the URL is reachable."
        }
        return "Probe failed: \(message)"
    }
}

private struct StatusRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
    }
}

#if canImport(EventKit)
import EventKit
import Contacts

// MARK: - Apple Integrations Card

private struct AppleIntegrationsCard: View {
    @State private var calendarAccess: EKAuthorizationStatus = .notDetermined
    @State private var remindersAccess: EKAuthorizationStatus = .notDetermined
    @State private var contactsAccess: CNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false
    @State private var lastError: String?
    @State private var showDetails = false
    @State private var calendarCount: Int?
    @State private var contactsCount: Int?
    @State private var reminderListCount: Int?
    @State private var pendingPermission: PermissionType?
    @State private var showPermissionPrompt = false
    
    private var isIOS17OrLater: Bool {
        if #available(iOS 17.0, *) {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple System Integration")
                        .font(.headline)
                    Text("On-device access to Calendar, Reminders & Contacts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showDetails.toggle()
                    }
                } label: {
                    Image(systemName: showDetails ? "chevron.up.circle.fill" : "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Calendar Section
            IntegrationRow(
                icon: "calendar",
                iconColor: .red,
                title: "Calendar",
                subtitle: "Access and manage events",
                status: calendarAccess,
                detailCount: calendarCount,
                detailLabel: "calendars",
                isRequesting: $isRequesting,
                showDetails: showDetails,
                onConnect: { presentPermission(.calendar) }
            )
            
            Divider()
            
            // Reminders Section
            IntegrationRow(
                icon: "checkmark.circle",
                iconColor: .orange,
                title: "Reminders",
                subtitle: "Create and manage tasks",
                status: remindersAccess,
                detailCount: reminderListCount,
                detailLabel: "lists",
                isRequesting: $isRequesting,
                showDetails: showDetails,
                onConnect: { presentPermission(.reminders) }
            )
            
            Divider()
            
            // Contacts Section
            ContactsIntegrationRow(
                contactsAccess: contactsAccess,
                contactsCount: contactsCount,
                isRequesting: $isRequesting,
                showDetails: showDetails,
                onConnect: { presentPermission(.contacts) }
            )
            
            // Error Display
            if let lastError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(lastError)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
            
            // Behind-the-scenes technical details
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("🔒 Technical Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    IntegrationDetailRow(
                        label: "iOS Version",
                        value: isIOS17OrLater ? "iOS 17+ (Full Access API)" : "iOS 16 (Legacy API)"
                    )
                    
                    IntegrationDetailRow(
                        label: "Privacy Model",
                        value: "On-device only • Zero cloud sync"
                    )
                    
                    IntegrationDetailRow(
                        label: "API Frameworks",
                        value: "EventKit • Contacts"
                    )
                    
                    IntegrationDetailRow(
                        label: "Integration Type",
                        value: "Native Apple System • MCP-compatible"
                    )
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
            
            // Usage guidance
            Text("💡 Grant access to use these Apple apps directly in your AI conversations. All data stays on your device.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .onAppear {
            refreshStatus()
            loadDetailCounts()
        }
        .alert(permissionTitle, isPresented: $showPermissionPrompt, presenting: pendingPermission) { permission in
            Button(pendingButtonLabel(for: permission), role: .none) {
                requestPermission(permission)
            }
            Button("Cancel", role: .cancel) {
                pendingPermission = nil
            }
        } message: { permission in
            Text(permissionMessage(for: permission))
        }
    }
    
    private func refreshStatus() {
        calendarAccess = EKEventStore.authorizationStatus(for: .event)
        remindersAccess = EKEventStore.authorizationStatus(for: .reminder)
        contactsAccess = CNContactStore.authorizationStatus(for: .contacts)
    }

    private func presentPermission(_ type: PermissionType) {
        pendingPermission = type
        showPermissionPrompt = true
    }

    private func requestPermission(_ type: PermissionType) {
        switch type {
        case .calendar:
            if calendarAccess == .denied || calendarAccess == .restricted {
                openSettings()
            } else {
                requestCalendarAccess()
            }
        case .reminders:
            if remindersAccess == .denied || remindersAccess == .restricted {
                openSettings()
            } else {
                requestRemindersAccess()
            }
        case .contacts:
            if contactsAccess == .denied || contactsAccess == .restricted {
                openSettings()
            } else {
                requestContactsAccess()
            }
        }
        showPermissionPrompt = false
        pendingPermission = nil
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var permissionTitle: String {
        guard let pendingPermission else { return "Permission Required" }
        switch pendingPermission {
        case .calendar:
            return "Calendar Access"
        case .reminders:
            return "Reminders Access"
        case .contacts:
            return "Contacts Access"
        }
    }

    private func pendingButtonLabel(for permission: PermissionType) -> String {
        switch permission {
        case .calendar:
            return (calendarAccess == .denied || calendarAccess == .restricted) ? "Open Settings" : "Continue"
        case .reminders:
            return (remindersAccess == .denied || remindersAccess == .restricted) ? "Open Settings" : "Continue"
        case .contacts:
            return (contactsAccess == .denied || contactsAccess == .restricted) ? "Open Settings" : "Continue"
        }
    }

    private func permissionMessage(for permission: PermissionType) -> String {
        switch permission {
        case .calendar:
            return "OpenResponses uses your Calendar only when you approve an action in chat. Events stay on device and the app never syncs in the background."
        case .reminders:
            return "Granting access lets the assistant add or update Reminders that you explicitly request. We do not read or send data elsewhere."
        case .contacts:
            return "Contacts access helps the assistant look up people when you ask. Data remains local; deny access any time from Settings."
        }
    }
    
    private func loadDetailCounts() {
        // Load calendar count
        if calendarAccess == .fullAccess {
            Task {
                let store = EKEventStore()
                let calendars = store.calendars(for: .event)
                await MainActor.run {
                    calendarCount = calendars.count
                }
            }
        }
        
        // Load reminder lists count
        if remindersAccess == .fullAccess {
            Task {
                let store = EKEventStore()
                let lists = store.calendars(for: .reminder)
                await MainActor.run {
                    reminderListCount = lists.count
                }
            }
        }
        
        // Load contacts count
        if contactsAccess == .authorized {
            Task {
                do {
                    let contacts = try await AppContainer.shared.appleProvider.getAllContacts(limit: 10000)
                    await MainActor.run {
                        contactsCount = contacts.count
                    }
                } catch {
                    // Silently fail - count is optional
                }
            }
        }
    }
    
    private func requestCalendarAccess() {
        isRequesting = true
        lastError = nil
        
        Task {
            do {
                AppLogger.log("📅 [Settings] Requesting Calendar access...", category: .ui, level: .info)
                try await AppContainer.shared.appleProvider.connect(presentingAnchor: nil)
                await MainActor.run {
                    refreshStatus()
                    loadDetailCounts()
                    isRequesting = false
                    AppLogger.log("✅ [Settings] Calendar access granted", category: .ui, level: .info)
                }
            } catch {
                await MainActor.run {
                    lastError = "Calendar access failed: \(error.localizedDescription)"
                    refreshStatus()
                    isRequesting = false
                    AppLogger.log("❌ [Settings] Calendar access failed: \(error)", category: .ui, level: .error)
                }
            }
        }
    }
    
    private func requestRemindersAccess() {
        isRequesting = true
        lastError = nil
        
        Task {
            do {
                AppLogger.log("✅ [Settings] Requesting Reminders access...", category: .ui, level: .info)
                try await AppContainer.shared.appleProvider.connect(presentingAnchor: nil)
                await MainActor.run {
                    refreshStatus()
                    loadDetailCounts()
                    isRequesting = false
                    AppLogger.log("✅ [Settings] Reminders access granted", category: .ui, level: .info)
                }
            } catch {
                await MainActor.run {
                    lastError = "Reminders access failed: \(error.localizedDescription)"
                    refreshStatus()
                    isRequesting = false
                    AppLogger.log("❌ [Settings] Reminders access failed: \(error)", category: .ui, level: .error)
                }
            }
        }
    }
    
    private func requestContactsAccess() {
        isRequesting = true
        lastError = nil
        
        Task {
            do {
                AppLogger.log("📇 [Settings] Requesting Contacts access...", category: .ui, level: .info)
                try await AppContainer.shared.appleProvider.connect(presentingAnchor: nil)
                await MainActor.run {
                    refreshStatus()
                    loadDetailCounts()
                    isRequesting = false
                    AppLogger.log("✅ [Settings] Contacts access granted", category: .ui, level: .info)
                }
            } catch {
                await MainActor.run {
                    lastError = "Contacts access failed: \(error.localizedDescription)"
                    refreshStatus()
                    isRequesting = false
                    AppLogger.log("❌ [Settings] Contacts access failed: \(error)", category: .ui, level: .error)
                }
            }
        }
    }
}

private enum PermissionType {
    case calendar
    case reminders
    case contacts
}

// MARK: - Helper Views

private struct IntegrationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let status: EKAuthorizationStatus
    let detailCount: Int?
    let detailLabel: String
    @Binding var isRequesting: Bool
    let showDetails: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(for: status))
                        .frame(width: 6, height: 6)
                    
                    Text(statusText(for: status))
                        .font(.caption)
                        .foregroundColor(statusColor(for: status))
                }
                
                if showDetails, let count = detailCount {
                    Text("\(count) \(detailLabel) accessible")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            if status == .notDetermined || status == .denied {
                Button(action: onConnect) {
                    Text(status == .notDetermined ? "Connect" : "Fix in Settings")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(isRequesting)
            } else {
                if #available(iOS 17.0, *) {
                    if status == .fullAccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                } else {
                    if status == .fullAccess || status == .authorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    private func statusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not connected"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied - check Settings"
        case .authorized, .fullAccess:
            return "Connected"
        case .writeOnly:
            return "Write-only"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func statusColor(for status: EKAuthorizationStatus) -> Color {
        switch status {
        case .notDetermined:
            return .secondary
        case .restricted, .denied:
            return .red
        case .authorized, .fullAccess:
            return .green
        case .writeOnly:
            return .orange
        @unknown default:
            return .secondary
        }
    }
}

private struct ContactsIntegrationRow: View {
    let contactsAccess: CNAuthorizationStatus
    let contactsCount: Int?
    @Binding var isRequesting: Bool
    let showDetails: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Contacts")
                    .fontWeight(.semibold)
                
                Text("Search and manage contacts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(contactsStatusColor(for: contactsAccess))
                        .frame(width: 6, height: 6)
                    
                    Text(contactsStatusText(for: contactsAccess))
                        .font(.caption)
                        .foregroundColor(contactsStatusColor(for: contactsAccess))
                }
                
                if showDetails, let count = contactsCount {
                    Text("\(count) contacts accessible")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            if contactsAccess == .notDetermined || contactsAccess == .denied {
                Button(action: onConnect) {
                    Text(contactsAccess == .notDetermined ? "Connect" : "Fix in Settings")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(isRequesting)
            } else if contactsAccess == .authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
    }
    
    private func contactsStatusText(for status: CNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not connected"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied - check Settings"
        case .authorized:
            return "Connected"
        default:
            if #available(iOS 18.0, *), status == .limited {
                return "Limited access"
            }
            return "Unknown"
        }
    }
    
    private func contactsStatusColor(for status: CNAuthorizationStatus) -> Color {
        switch status {
        case .notDetermined:
            return .secondary
        case .restricted, .denied:
            return .red
        case .authorized:
            return .green
        default:
            if #available(iOS 18.0, *), status == .limited {
                return .orange
            }
            return .secondary
        }
    }
}

private struct IntegrationDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
    }
}
#endif


#Preview {
    SettingsHomeView()
        .environmentObject(ChatViewModel())
}
