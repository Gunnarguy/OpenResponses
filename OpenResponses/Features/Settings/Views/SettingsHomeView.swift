import SwiftUI

/// Clean, tabbed Settings container aligned with OpenAI Responses Playground mental model.
/// Tabs: General, Model, Tools, Advanced
struct SettingsHomeView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @StateObject private var promptLibrary = PromptLibrary()

    @State private var apiKey: String = ""
    @State private var selectedTab: SettingsTab = .general

    // Sheets
    @State private var showingNotionQuickConnect = false
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false

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
                    case .general: GeneralTab(apiKey: $apiKey)
                    case .model: ModelTab()
                    case .tools: ToolsTab(
                        showingNotionQuickConnect: $showingNotionQuickConnect,
                        showingFileManager: $showingFileManager,
                        showingPromptLibrary: $showingPromptLibrary
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
    }
}

// MARK: - Tabs

private enum SettingsTab: CaseIterable {
    case general, model, tools, advanced

    var title: String {
        switch self {
        case .general:  return "General"
        case .model:    return "Model"
        case .tools:    return "Tools"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var apiKey: String
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
                Toggle("Enable Streaming", isOn: $viewModel.activePrompt.enableStreaming)
            }

            Section(header: Label("Published Prompt", systemImage: "doc.text.fill")) {
                Toggle("Use Published Prompt", isOn: $viewModel.activePrompt.enablePublishedPrompt)
                if viewModel.activePrompt.enablePublishedPrompt {
                    TextField("Published Prompt ID", text: $viewModel.activePrompt.publishedPromptId)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
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
    @Binding var showingPromptLibrary: Bool

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
            }
            
            // Prompt Library
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

                Toggle("Enable Computer Use", isOn: $viewModel.activePrompt.enableComputerUse)
                    .disabled(!isSupported)

                if !isSupported {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Not supported by current model. Use gpt-5 or computer-use-preview.")
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

            // Web Search
            Section(header: Label("Web Search", systemImage: "magnifyingglass.circle.fill")) {
                Toggle("Enable Web Search", isOn: $viewModel.activePrompt.enableWebSearch)
                
                if viewModel.activePrompt.enableWebSearch {
                    TextField("Mode (e.g., default)", text: $viewModel.activePrompt.webSearchMode)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Search Instructions (optional)").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $viewModel.activePrompt.webSearchInstructions)
                            .frame(minHeight: 60)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                    }

                    Stepper("Max Pages: \(viewModel.activePrompt.webSearchMaxPages)", value: $viewModel.activePrompt.webSearchMaxPages, in: 1...20)
                    Stepper("Crawl Depth: \(viewModel.activePrompt.webSearchCrawlDepth)", value: $viewModel.activePrompt.webSearchCrawlDepth, in: 0...5)
                }
            }

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
                }
            }

            // File Search
            Section(header: Label("File Search", systemImage: "doc.text.magnifyingglass")) {
                Toggle("Enable Vector Store Search", isOn: $viewModel.activePrompt.enableFileSearch)
                
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
                    }
                }
            }
        }
    }
}

// MARK: - Advanced

private struct AdvancedTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    private var modelCaps: ModelCompatibilityService.ModelCapabilities? {
        ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)
    }

    var body: some View {
        Form {
            Section(header: Label("Tool Choice", systemImage: "switch.2")) {
                Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("Required").tag("required")
                    Text("None").tag("none")
                }
                .pickerStyle(.segmented)
            }

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

            Section(header: Label("Response Includes", systemImage: "tray.full")) {
                Toggle("Include Computer Use Output", isOn: $viewModel.activePrompt.includeComputerUseOutput)
                Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)

                HStack {
                    Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                        .disabled(modelCaps?.supportsReasoningEffort == true)
                    if modelCaps?.supportsReasoningEffort == true {
                        Image(systemName: "info.circle.fill").foregroundColor(.blue)
                    }
                }

                HStack {
                    Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                        .disabled(!(modelCaps?.supportsReasoningEffort == true))
                    if !(modelCaps?.supportsReasoningEffort == true) {
                        Image(systemName: "info.circle.fill").foregroundColor(.blue)
                    }
                }
            }

            Section(header: Label("Metadata", systemImage: "square.and.pencil")) {
                TextEditor(text: $viewModel.activePrompt.metadata.bound)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                Text("Custom metadata as JSON object (stored in request).")
                    .font(.caption).foregroundColor(.secondary)
            }

            Section(header: Label("User", systemImage: "person.crop.circle")) {
                TextField("User Identifier (optional)", text: $viewModel.activePrompt.userIdentifier)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
        }
    }
}


#Preview {
    SettingsHomeView()
        .environmentObject(ChatViewModel())
}
