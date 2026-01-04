import SwiftUI
import UIKit

/// Consolidated Settings container aligned with OpenAI Responses API.
/// Tabs: General, Model, Tools, Advanced
struct SettingsHomeView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @StateObject private var promptLibrary = PromptLibrary()

    @State private var apiKey: String = ""
    @State private var apiKeySaveState: ApiKeySaveState = .idle
    @State private var apiKeyLastSavedNormalized: String = ""
    @State private var apiKeyPendingSave: DispatchWorkItem?
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
                    case .general:
                        GeneralTab(
                            apiKey: $apiKey,
                            apiKeySaveState: $apiKeySaveState,
                            isApiKeyDirty: normalizeApiKey(apiKey) != apiKeyLastSavedNormalized,
                            saveApiKeyNow: { commitApiKey(apiKey) },
                            showingPromptLibrary: $showingPromptLibrary
                        )
                    case .model: ModelTab()
                    case .tools: ToolsTab(
                        showingNotionQuickConnect: $showingNotionQuickConnect,
                        showingFileManager: $showingFileManager
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
            let loaded = KeychainService.shared.load(forKey: "openAIKey") ?? ""
            apiKey = loaded
            apiKeyLastSavedNormalized = normalizeApiKey(loaded)
            apiKeySaveState = .idle
        }
        .onChange(of: apiKey) { _, newValue in
            scheduleApiKeyCommit(newValue)
        }
        .onDisappear {
            commitApiKey(apiKey)
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

    private func normalizeApiKey(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func scheduleApiKeyCommit(_ raw: String) {
        let normalized = normalizeApiKey(raw)
        guard normalized != apiKeyLastSavedNormalized else { return }

        apiKeyPendingSave?.cancel()
        let work = DispatchWorkItem { [raw] in
            commitApiKey(raw)
        }
        apiKeyPendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func commitApiKey(_ raw: String) {
        apiKeyPendingSave?.cancel()
        apiKeyPendingSave = nil

        let normalized = normalizeApiKey(raw)
        guard normalized != apiKeyLastSavedNormalized else { return }

        apiKeySaveState = .saving

        DispatchQueue.global(qos: .userInitiated).async {
            let success: Bool
            if normalized.isEmpty {
                success = KeychainService.shared.delete(forKey: "openAIKey")
            } else {
                success = KeychainService.shared.save(value: normalized, forKey: "openAIKey")
            }

            DispatchQueue.main.async {
                self.apiKeyLastSavedNormalized = normalized
                self.apiKeySaveState = success ? .saved : .failed
                NotificationCenter.default.post(name: .openAIKeyDidChange, object: nil)
            }
        }
    }
}

private enum ApiKeySaveState: Equatable {
    case idle, saving, saved, failed
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

// MARK: - General Tab (Consolidated)

private struct GeneralTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var apiKey: String
    @Binding var apiKeySaveState: ApiKeySaveState
    let isApiKeyDirty: Bool
    let saveApiKeyNow: () -> Void
    @Binding var showingPromptLibrary: Bool
    @State private var resetConfirm = false
    @State private var showAdvancedIdentity = false

    var body: some View {
        Form {
            // MARK: API Key

            Section { 
                HStack(spacing: 8) {
                    SecureField("sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
.submitLabel(.done)
    .onSubmit { saveApiKeyNow() }
    .accessibilityConfiguration(
        hint: AccessibilityUtils.Hint.apiKeyField,
        identifier: AccessibilityUtils.Identifier.apiKeyField
    )

                    if !apiKey.isEmpty {
                        Button { apiKey = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }

                    saveStatusBadge
                }
            } header: {
                Label("OpenAI API Key", systemImage: "key.fill")
            } footer: {
                Text("Required for API access. Stored securely in Keychain.")
            }

            // MARK: Explore Demo (conditional)
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.exploreModeEnabled { 
                Section {
                    Toggle("Demo Mode", isOn: Binding(
                        get: { viewModel.exploreModeEnabled },
                        set: { viewModel.setExploreModeEnabled($0) }
                    ))

                    if viewModel.exploreModeEnabled {
                        Button { viewModel.startExploreDemoConversation() } label: {
                            Label("Start Demo", systemImage: "sparkles")
                        }
                        Button(role: .destructive) { viewModel.exitExploreDemo() } label: {
                            Label("Exit Demo", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Label("Explore Mode", systemImage: "play.circle")
                } footer: {
                    Text("Try the app with simulated responses—no API key needed.")
                }
            }

            // MARK: Streaming

            Section {
                Toggle("Stream Responses", isOn: $viewModel.activePrompt.enableStreaming)
            } header: {
                Label("Streaming", systemImage: "bolt.horizontal")
            } footer: {
                Text("See responses as they're generated.")
            }

            // MARK: API Behavior

            Section {
                Toggle("Store on OpenAI", isOn: $viewModel.activePrompt.storeResponses)

                DisclosureGroup("Identity & Caching", isExpanded: $showAdvancedIdentity) {
                    TextField("Safety Identifier", text: $viewModel.activePrompt.safetyIdentifier)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Hashed user ID for abuse detection.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    TextField("Prompt Cache Key", text: $viewModel.activePrompt.promptCacheKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Reuse cached prompts for faster responses.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("API Behavior", systemImage: "server.rack")
            }

            // MARK: Presets

            Section {
                Button { showingPromptLibrary = true } label: {
                    HStack {
                        Label("Prompt Library", systemImage: "book.fill")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                }

                Button(role: .destructive) { resetConfirm = true } label: {
                    Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                }
                .alert("Reset Settings?", isPresented: $resetConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) { viewModel.resetToDefaultPrompt() }
                } message: {
                    Text("Restore all settings to defaults.")
                }
            } header: {
                Label("Presets", systemImage: "bookmark.fill")
            }
        }
    }

    @ViewBuilder
    private var saveStatusBadge: some View {
        switch apiKeySaveState {
        case .idle:
            if isApiKeyDirty {
                Button { saveApiKeyNow() } label: {
                    Image(systemName: "checkmark.circle").foregroundColor(.blue)
                }
            } else {
                EmptyView()
            }
        case .saving:
            ProgressView().controlSize(.small)
        case .saved:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
        }
    }
}

// MARK: - Model Tab

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

// MARK: - Tools Tab (Consolidated with Inline Selection)

private struct ToolsTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var showingNotionQuickConnect: Bool
    @Binding var showingFileManager: Bool
    @State private var hasNotionIntegrationToken: Bool = KeychainService.shared.load(forKey: "notionApiKey")?.isEmpty == false
    @AppStorage("hasShownComputerUseDisclosure") private var hasShownComputerUseDisclosure = false
    @State private var showComputerUseDisclosure = false
    @State private var showWebSearchAdvanced = false
    @State private var showWebSearchLocation = false
    @State private var showImageGenAdvanced = false

    // Vector Store State
    @State private var availableVectorStores: [VectorStore] = []
    @State private var isLoadingVectorStores = false
    @State private var vectorStoreSearchText = ""
    @State private var showVectorStoreBrowser = false
    @State private var vectorStoreDisplayCount = 5

    // Files State
    @State private var availableFiles: [OpenAIFile] = []
    @State private var isLoadingFiles = false
    @State private var fileSearchText = ""
    @State private var showFileBrowser = false
    @State private var fileDisplayCount = 5

    private let api = OpenAIService()

    private var isComputerUseSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(
            .computer,
            for: viewModel.activePrompt.openAIModel,
            isStreaming: viewModel.activePrompt.enableStreaming
        )
    }

    private var isImageGenerationSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(
            .imageGeneration,
            for: viewModel.activePrompt.openAIModel,
            isStreaming: viewModel.activePrompt.enableStreaming
        )
    }

    private var selectedVectorStoreIds: Set<String> {
        guard let ids = viewModel.activePrompt.selectedVectorStoreIds, !ids.isEmpty else { return [] }
        return Set(ids.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    private var selectedFileIds: Set<String> {
        guard let ids = viewModel.activePrompt.codeInterpreterPreloadFileIds, !ids.isEmpty else { return [] }
        return Set(ids.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    // Filtered & unselected items for browsing
    private var filteredVectorStores: [VectorStore] {
        let unselected = availableVectorStores.filter { !selectedVectorStoreIds.contains($0.id) }
        if vectorStoreSearchText.isEmpty { return unselected }
        return unselected.filter { ($0.name ?? "").localizedCaseInsensitiveContains(vectorStoreSearchText) }
    }

    private var filteredFiles: [OpenAIFile] {
        let unselected = availableFiles.filter { !selectedFileIds.contains($0.id) }
        if fileSearchText.isEmpty { return unselected }
        return unselected.filter { $0.filename.localizedCaseInsensitiveContains(fileSearchText) }
    }

    // Selected items for display
    private var selectedVectorStores: [VectorStore] {
        availableVectorStores.filter { selectedVectorStoreIds.contains($0.id) }
    }

    private var selectedFiles: [OpenAIFile] {
        availableFiles.filter { selectedFileIds.contains($0.id) }
    }

    var body: some View {
        Form {
            // MARK: Web Search

            Section {
                Toggle("Web Search", isOn: $viewModel.activePrompt.enableWebSearch)
                    .tint(.blue)

                if viewModel.activePrompt.enableWebSearch {
                    DisclosureGroup("Options", isExpanded: $showWebSearchAdvanced) {
                        webSearchOptions
                    }
.font(.subheadline)
                }
            } header: {
                Label("Web Search", systemImage: "globe")
            }

            // MARK: File Search with Smart Vector Store Selection

            Section {
                Toggle("File Search", isOn: $viewModel.activePrompt.enableFileSearch)
                    .tint(.purple)

                if viewModel.activePrompt.enableFileSearch {
                    vectorStoreSelectionView
                }

                // Advanced file management link - always visible
                Button {
                    showingFileManager = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundColor(.purple)
                        Text("Manage Files & Vector Stores")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Label("File Search", systemImage: "doc.text.magnifyingglass")
            } footer: {
                if viewModel.activePrompt.enableFileSearch, !availableVectorStores.isEmpty {
                    Text("Select up to 2 vector stores. \(selectedVectorStoreIds.count)/2 selected.")
                }
            }

            // MARK: Code Interpreter with Smart File Selection

            Section {
                Toggle("Code Interpreter", isOn: $viewModel.activePrompt.enableCodeInterpreter)
                    .tint(.orange)

                if viewModel.activePrompt.enableCodeInterpreter {
                    fileSelectionView
                }
            } header: {
                Label("Code Interpreter", systemImage: "terminal")
            } footer: {
                if viewModel.activePrompt.enableCodeInterpreter, !availableFiles.isEmpty {
                    Text("Pre-load files into the Python sandbox. \(selectedFileIds.count) selected.")
                }
            }

            // MARK: Image Generation

            Section {
                Toggle("Image Generation", isOn: $viewModel.activePrompt.enableImageGeneration)
                    .tint(.pink)
                    .disabled(!isImageGenerationSupported)

                if viewModel.activePrompt.enableImageGeneration {
                    DisclosureGroup("Options", isExpanded: $showImageGenAdvanced) {
                        imageGenerationOptions
                    }
.font(.subheadline)
                }
            } header: {
                Label("Image Generation", systemImage: "photo.artframe")
            }

            // MARK: Computer Use

            Section {
                computerUseToggle
            } header: {
                Label("Computer Use", systemImage: "desktopcomputer")
            }

            // MARK: External Integrations

            Section {
                Toggle("Notion", isOn: $viewModel.activePrompt.enableNotionIntegration)
                    .disabled(!hasNotionIntegrationToken)

                if !hasNotionIntegrationToken {
                    Button { showingNotionQuickConnect = true } label: {
                        Label("Connect Notion", systemImage: "square.grid.2x2.fill")
                    }
                }

                #if canImport(EventKit)
                    Toggle("Apple Calendar/Reminders/Contacts", isOn: $viewModel.activePrompt.enableAppleIntegrations)

                    if viewModel.activePrompt.enableAppleIntegrations {
                        AppleIntegrationsCard()
                    }
                #endif
            } header: {
                Label("Integrations", systemImage: "link")
            }
        }
        .onAppear {
            refreshNotionTokenStatus()
            loadVectorStores()
            loadFiles()
        }
        .onChange(of: showingNotionQuickConnect) { _, isPresented in
            if !isPresented { refreshNotionTokenStatus() }
        }
        .onChange(of: viewModel.activePrompt.enableFileSearch) { _, enabled in
            if enabled, availableVectorStores.isEmpty { loadVectorStores() }
        }
        .onChange(of: viewModel.activePrompt.enableCodeInterpreter) { _, enabled in
            if enabled, availableFiles.isEmpty { loadFiles() }
        }
    }

    // MARK: - Vector Store Selection View

    @ViewBuilder
    private var vectorStoreSelectionView: some View {
        if isLoadingVectorStores {
            HStack {
                ProgressView()
                Text("Loading vector stores...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if availableVectorStores.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No vector stores found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button {
                    showingFileManager = true
                } label: {
                    Label("Create Vector Store", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
            }
        } else { 
            // Selected stores shown as removable chips
            if !selectedVectorStores.isEmpty {
                ForEach(selectedVectorStores) { store in
                    selectedVectorStoreChip(store)
                }
            }

            // Add more button / browser
            if selectedVectorStoreIds.count < 2 {
                DisclosureGroup(
                    isExpanded: $showVectorStoreBrowser,
                    content: {
                        // Search field
                        if availableVectorStores.count > 3 {
                            TextField("Search vector stores...", text: $vectorStoreSearchText)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                        }

                        // Show paginated unselected stores
                        let storesToShow = Array(filteredVectorStores.prefix(vectorStoreDisplayCount))
                        if storesToShow.isEmpty, !vectorStoreSearchText.isEmpty {
                            Text("No matching vector stores")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(storesToShow) { store in
                                vectorStoreBrowserRow(store)
                            }
                        }

                        // Load more button
                        if filteredVectorStores.count > vectorStoreDisplayCount {
                            Button {
                                vectorStoreDisplayCount += 5
                            } label: {
                                HStack {
                                    Text("Load \(min(5, filteredVectorStores.count - vectorStoreDisplayCount)) more")
                                    Text("(\(filteredVectorStores.count - vectorStoreDisplayCount) remaining)")
                                        .foregroundColor(.secondary)
                                }
.font(.caption)
                            }
                        }
                    },
                    label: {
                            Label(
                                selectedVectorStoreIds.isEmpty ? "Select Vector Store" : "Add Another Store",
                                systemImage: "plus.circle"
                            )
.font(.subheadline)
    .foregroundColor(.purple)
                        }
                )
            } else {
                Text("Maximum 2 vector stores reached")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - File Selection View

    @ViewBuilder
    private var fileSelectionView: some View {
        if isLoadingFiles {
            HStack { 
                ProgressView()
                Text("Loading files...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if availableFiles.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No files uploaded yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button {
                    showingFileManager = true
                } label: {
                    Label("Upload Files", systemImage: "arrow.up.circle.fill")
                        .font(.caption)
                }
            }
        } else {
            // Selected files shown as removable chips
            if !selectedFiles.isEmpty {
                ForEach(selectedFiles) { file in
                    selectedFileChip(file)
                }
            }

            // Add more button / browser
            DisclosureGroup(
                isExpanded: $showFileBrowser,
                content: {
                    // Search field
                    if availableFiles.count > 3 {
                        TextField("Search files...", text: $fileSearchText)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }

                    // Show paginated unselected files
                    let filesToShow = Array(filteredFiles.prefix(fileDisplayCount))
                    if filesToShow.isEmpty, !fileSearchText.isEmpty {
                        Text("No matching files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filesToShow) { file in
                            fileBrowserRow(file)
                        }
                    }

                    // Load more button
                    if filteredFiles.count > fileDisplayCount {
                        Button {
                            fileDisplayCount += 5
                        } label: {
                            HStack { 
                                Text("Load \(min(5, filteredFiles.count - fileDisplayCount)) more")
                                Text("(\(filteredFiles.count - fileDisplayCount) remaining)")
                                    .foregroundColor(.secondary)
                            }
.font(.caption)
                        }
                    }
                },
                label: {
                        Label(
                            selectedFileIds.isEmpty ? "Select Files (Optional)" : "Add More Files",
                            systemImage: "plus.circle"
                        )
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    }
            )
        }
    }

    // MARK: - Selected Item Chips

    @ViewBuilder
    private func selectedVectorStoreChip(_ store: VectorStore) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 1) {
                Text(store.name ?? "Unnamed Store")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text("\(store.fileCounts.total) files")
                    Text("•")
                    Text(formatBytes(store.usageBytes))
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                removeVectorStore(store.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
.buttonStyle(.plain)
        }
        .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
    }

    @ViewBuilder
    private func selectedFileChip(_ file: OpenAIFile) -> some View {
        HStack(spacing: 8) {
            fileIcon(for: file.filename)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.filename)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(formatBytes(file.bytes))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                removeFile(file.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
.buttonStyle(.plain)
        }
.padding(.vertical, 6)
    .padding(.horizontal, 10)
    .background(Color.orange.opacity(0.1))
    .cornerRadius(8)
    }

    // MARK: - Browser Rows (for adding items)

    @ViewBuilder
    private func vectorStoreBrowserRow(_ store: VectorStore) -> some View {
        Button {
            addVectorStore(store.id)
            if selectedVectorStoreIds.count >= 2 {
                showVectorStoreBrowser = false
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.name ?? "Unnamed Store")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text("\(store.fileCounts.total) files")
                        Text("•")
                        Text(formatBytes(store.usageBytes))
                        Text("•")
                        Text(store.status.replacingOccurrences(of: "_", with: " "))
                    }
.font(.caption2)
    .foregroundColor(.secondary)
                }

                Spacer()
            }
.padding(.vertical, 4)
    .contentShape(Rectangle())
        }
.buttonStyle(.plain)
    }

    @ViewBuilder
    private func fileBrowserRow(_ file: OpenAIFile) -> some View {
        Button {
            addFile(file.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.orange)

                fileIcon(for: file.filename)
                    .foregroundColor(.orange.opacity(0.7))
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(formatBytes(file.bytes))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Web Search Options

    @ViewBuilder
    private var webSearchOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Search Context Size

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Context Size")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(searchContextDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Picker("Context Size", selection: $viewModel.activePrompt.searchContextSize.bound) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
.pickerStyle(.segmented)

Text("Higher = better quality, slower response, may cost more tokens.")
    .font(.caption2)
    .foregroundColor(.secondary)
            }

            Divider()

            // MARK: Domain Filtering

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe.badge.chevron.backward")
                        .foregroundColor(.blue)
                    Text("Domain Filtering")
                        .font(.subheadline.weight(.medium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Allowed Domains")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    TextField("e.g., nytimes.com, bbc.com", text: $viewModel.activePrompt.webSearchAllowedDomains.bound)
                        .textInputAutocapitalization(.never)
.autocorrectionDisabled()
    .font(.callout)
    .padding(8)
    .background(Color(.systemGray6))
    .cornerRadius(8)

                    Text("Up to 20 domains. Separate with commas. Omit http/https.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blocked Domains")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    TextField("e.g., reddit.com, twitter.com", text: $viewModel.activePrompt.webSearchBlockedDomains.bound)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Domain pills preview
                if !allowedDomainsList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(allowedDomainsList.prefix(5), id: \.self) { domain in
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Text(domain)
                                        .font(.caption2)
                                }
.padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.green.opacity(0.1))
    .cornerRadius(12)
                            }
                            if allowedDomainsList.count > 5 {
                                Text("+\(allowedDomainsList.count - 5) more")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            // MARK: User Location

            DisclosureGroup(isExpanded: $showWebSearchLocation) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Country (ISO)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("US", text: $viewModel.activePrompt.userLocationCountry.bound)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .frame(width: 60)
                                .font(.callout)
                                .padding(6)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("City")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("San Francisco", text: $viewModel.activePrompt.userLocationCity.bound)
                                .textInputAutocapitalization(.words)
                                .font(.callout)
                                .padding(6)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Region/State")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("California", text: $viewModel.activePrompt.userLocationRegion.bound)
                                .textInputAutocapitalization(.words)
                                .font(.callout)
                                .padding(6)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timezone")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("America/Los_Angeles", text: $viewModel.activePrompt.userLocationTimezone.bound)
.textInputAutocapitalization(.never)
.autocorrectionDisabled()
    .font(.callout)
    .padding(6)
    .background(Color(.systemGray6))
    .cornerRadius(6)
                        }
                    }

                    Button {
                        autofillLocation()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
.font(.caption)
                    }
.buttonStyle(.bordered)
    .tint(.blue)

Text("Location helps refine local search results (restaurants, events, etc.)")
    .font(.caption2)
    .foregroundColor(.secondary)
                }
.padding(.top, 8)
            } label: {
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundColor(.orange)
                    Text("User Location")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if hasLocationSet {
                        Text(locationSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // MARK: Search Instructions

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.purple)
                    Text("Search Instructions")
                        .font(.subheadline.weight(.medium))
                }

                TextEditor(text: $viewModel.activePrompt.webSearchInstructions)
                    .frame(height: 60)
                    .font(.callout)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

                Text("Optional guidance for how the model should search (e.g., \"Focus on recent news from the last 24 hours\").")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // MARK: API Info

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("API Notes")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("• Context size not supported on o3, o4-mini, deep research models")
                    Text("• Domain filtering: up to 20 allowed domains")
                    Text("• Location not supported on deep research models")
                }
.font(.caption2)
    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }

    // MARK: Web Search Helpers

    private var searchContextDisplayName: String {
        switch viewModel.activePrompt.searchContextSize ?? "medium" {
        case "low": return "Fast, less context"
        case "high": return "Comprehensive, slower"
        default: return "Balanced (default)"
        }
    }

    private var allowedDomainsList: [String] {
        (viewModel.activePrompt.webSearchAllowedDomains ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var hasLocationSet: Bool {
        let city = viewModel.activePrompt.userLocationCity ?? ""
        let country = viewModel.activePrompt.userLocationCountry ?? ""
        return !city.isEmpty || !country.isEmpty
    }

    private var locationSummary: String {
        let city = viewModel.activePrompt.userLocationCity ?? ""
        let country = viewModel.activePrompt.userLocationCountry ?? ""
        if !city.isEmpty && !country.isEmpty {
            return "\(city), \(country)"
        } else if !city.isEmpty {
            return city
        } else if !country.isEmpty {
            return country
        }
        return "Not set"
    }

    private func autofillLocation() {
        // Auto-fill with device timezone
        let tz = TimeZone.current.identifier
        viewModel.activePrompt.userLocationTimezone = tz

        // Try to infer country from locale
        if let regionCode = Locale.current.region?.identifier {
            viewModel.activePrompt.userLocationCountry = regionCode
        }
    }

    // MARK: Image Generation Options

    @ViewBuilder
    private var imageGenerationOptions: some View {
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
    }

    // MARK: Computer Use Toggle

    @ViewBuilder
    private var computerUseToggle: some View {
        let computerUseBinding = Binding(
            get: { viewModel.activePrompt.enableComputerUse },
            set: { newValue in
                if newValue, !hasShownComputerUseDisclosure {
                    showComputerUseDisclosure = true
                } else {
                    viewModel.activePrompt.enableComputerUse = newValue
                }
            }
        )

        Toggle("Computer Use", isOn: computerUseBinding)
            .tint(.indigo)
            .disabled(!isComputerUseSupported)
            .alert("Enable Computer Use?", isPresented: $showComputerUseDisclosure) {
                Button("Continue") {
                    viewModel.activePrompt.enableComputerUse = true
                    hasShownComputerUseDisclosure = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Computer Use can control apps when you approve each action. Only allow actions you trust.")
            }

        if !isComputerUseSupported {
            Text("Requires computer-use-preview model.")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else if viewModel.activePrompt.enableComputerUse {
            Toggle("Strict Mode", isOn: $viewModel.activePrompt.ultraStrictComputerUse)
                .tint(.red)
            Text("Disables helper behaviors for pure model control.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Methods

    private func refreshNotionTokenStatus() {
        let tokenAvailable = KeychainService.shared.load(forKey: "notionApiKey")?.isEmpty == false
        hasNotionIntegrationToken = tokenAvailable
        if !tokenAvailable, viewModel.activePrompt.enableNotionIntegration {
            viewModel.activePrompt.enableNotionIntegration = false
            viewModel.saveActivePrompt()
        }
    }

    private func loadVectorStores() {
        guard !isLoadingVectorStores else { return }
        isLoadingVectorStores = true
        Task {
            do {
                let stores = try await api.listVectorStores()
                await MainActor.run {
                    availableVectorStores = stores
                    isLoadingVectorStores = false
                }
            } catch {
                await MainActor.run { isLoadingVectorStores = false }
            }
        }
    }

    private func loadFiles() {
        guard !isLoadingFiles else { return }
        isLoadingFiles = true
        Task {
            do {
                let files = try await api.listFiles(purpose: nil)
                await MainActor.run {
                    availableFiles = files
                    isLoadingFiles = false
                }
            } catch {
                await MainActor.run { isLoadingFiles = false }
            }
        }
    }

    private func addVectorStore(_ id: String) {
        var ids = Array(selectedVectorStoreIds)
        guard !ids.contains(id), ids.count < 2 else { return }
        ids.append(id)
        viewModel.activePrompt.selectedVectorStoreIds = ids.joined(separator: ",")
        viewModel.saveActivePrompt()
    }

    private func removeVectorStore(_ id: String) {
        var ids = Array(selectedVectorStoreIds)
        ids.removeAll { $0 == id }
        viewModel.activePrompt.selectedVectorStoreIds = ids.isEmpty ? nil : ids.joined(separator: ",")
        viewModel.saveActivePrompt()
    }

    private func addFile(_ id: String) {
        var ids = Array(selectedFileIds)
        guard !ids.contains(id) else { return }
        ids.append(id)
        viewModel.activePrompt.codeInterpreterPreloadFileIds = ids.joined(separator: ",")
        viewModel.saveActivePrompt()
    }

    private func removeFile(_ id: String) {
        var ids = Array(selectedFileIds)
        ids.removeAll { $0 == id }
        viewModel.activePrompt.codeInterpreterPreloadFileIds = ids.isEmpty ? nil : ids.joined(separator: ",")
        viewModel.saveActivePrompt()
    }

    private func formatBytes(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func fileIcon(for filename: String) -> Image {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return Image(systemName: "doc.fill")
        case "txt", "md": return Image(systemName: "doc.text.fill")
        case "json": return Image(systemName: "curlybraces")
        case "csv": return Image(systemName: "tablecells.fill")
        case "py": return Image(systemName: "chevron.left.forwardslash.chevron.right")
        case "png", "jpg", "jpeg", "gif": return Image(systemName: "photo.fill")
        default: return Image(systemName: "doc.fill")
        }
    }
}

// MARK: - MCP Tab (Consolidated)

private struct MCPTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Binding var showingConnectorGallery: Bool
    @Binding var showingRemoteSetup: Bool
    @State private var isTesting = false
    @State private var diagStatus: String?
    @State private var showClearConfirm = false

    private var prompt: Prompt { viewModel.activePrompt }
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
            // MARK: Status

            Section {
                Toggle("Enable MCP", isOn: Binding(
                    get: { viewModel.activePrompt.enableMCPTool },
                    set: { newValue in
                        var updated = viewModel.activePrompt
                        updated.enableMCPTool = newValue
                        viewModel.replaceActivePrompt(with: updated)
                        viewModel.saveActivePrompt()
                    }
                ))
            } header: {
                Label("MCP Status", systemImage: "power")
            } footer: {
                Text(mcpEnabled ? "MCP tool calls are active." : "MCP is configured but disabled.")
            }

            // MARK: Configuration

            Section { 
                if remoteConfigured {
                    configuredRemoteRow
                } else if connectorConfigured {
                    configuredConnectorRow
                } else {
                    Text("No MCP server configured.")
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Current Configuration", systemImage: "bolt.shield")
            }

            // MARK: Diagnostics
            if remoteConfigured {
                Section { 
                    if isTesting {
                        HStack { 
                            ProgressView()
                            Text("Testing…")
                        }
                    } else {
                        Button { testMCPConnection() } label: {
                            Label("Test Connection", systemImage: "checkmark.seal")
                        }
                    }

                    if let diagStatus {
                        Text(diagStatus)
                            .font(.caption)
                            .foregroundColor(diagStatus.contains("OK") ? .green : .orange)
                    }
                } header: {
                    Label("Diagnostics", systemImage: "waveform")
                }
            }

            // MARK: Actions

            Section {
                Button { showingConnectorGallery = true } label: {
                    Label("Browse Connectors", systemImage: "square.grid.2x2.fill")
                }

                Button { showingRemoteSetup = true } label: { 
                    Label("Configure Remote Server", systemImage: "server.rack")
                }

                if hasConfiguration {
                    Button(role: .destructive) { showClearConfirm = true } label: {
                        Label("Remove Configuration", systemImage: "trash")
                    }
                }
            } header: {
                Label("Actions", systemImage: "slider.horizontal.3")
            }
        }
.onAppear { diagStatus = nil }
        .alert("Remove MCP Configuration?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { clearMCPConfiguration() }
        } message: {
            Text("This clears all MCP settings and tokens.")
        }
    }

    private var configuredRemoteRow: some View {
        VStack(alignment: .leading, spacing: 4) { 
            Text(prompt.mcpServerLabel).font(.headline)
            Text(prompt.mcpServerURL).font(.caption).foregroundColor(.secondary)
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(mcpEnabled ? .green : .gray)
                    .font(.system(size: 8))
                Text(mcpEnabled ? "Active" : "Disabled")
.font(.caption)
            }
        }
.padding(.vertical, 4)
    }

    private var configuredConnectorRow: some View {
        VStack(alignment: .leading, spacing: 4) { 
            if let connectorId = prompt.mcpConnectorId,
               let connector = MCPConnector.connector(for: connectorId) { 
                Text(connector.name).font(.headline)
                Text(connector.description).font(.caption).foregroundColor(.secondary)
            } else {
                Text("Unknown Connector").font(.headline)
            }
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(mcpEnabled ? .green : .gray)
                    .font(.system(size: 8))
                Text(mcpEnabled ? "Active" : "Disabled")
                    .font(.caption)
            }
        }
.padding(.vertical, 4)
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
                    diagStatus = "OK: \(result.count) tools available"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    diagStatus = "Failed: \(error.localizedDescription)"
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
        diagStatus = nil
    }
}

// MARK: - Advanced Tab (Consolidated)

private struct AdvancedTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingAbout = false
    @State private var showResponseIncludes = false

    private var modelCaps: ModelCompatibilityService.ModelCapabilities? {
        ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)
    }

    var body: some View {
        Form {
            // MARK: Tool Execution

            Section {
                Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("Required").tag("required")
                    Text("None").tag("none")
                }
.pickerStyle(.segmented)

Toggle("Parallel Tool Calls", isOn: $viewModel.activePrompt.parallelToolCalls)

Toggle("Background Mode", isOn: $viewModel.activePrompt.backgroundMode)

                limitToolCallsRow
            } header: {
                Label("Tool Execution", systemImage: "hammer.circle")
            } footer: {
                Text("Control how the model uses tools during generation.")
            }

            // MARK: Request Options

            Section {
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
            } header: {
                Label("Request Options", systemImage: "slider.horizontal.3")
            }

            // MARK: Response Includes

            Section {
                DisclosureGroup("Response Includes", isExpanded: $showResponseIncludes) {
                    Toggle("File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                    Toggle("Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                    Toggle("Web Search Sources", isOn: $viewModel.activePrompt.includeWebSearchSources)
                    Toggle("Code Interpreter Output", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)

                    if modelCaps?.supportsReasoningEffort == true {
                        Toggle("Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                    }

                    logprobsToggle
                }
            } header: {
                Label("Output Options", systemImage: "tray.full")
            } footer: {
                Text("Additional data to include in responses.")
            }

            // MARK: Metadata

            Section {
                TextEditor(text: $viewModel.activePrompt.metadata.bound)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            } header: {
                Label("Custom Metadata", systemImage: "tag")
            } footer: {
                Text("JSON key-value pairs attached to requests.")
            }

            // MARK: About

            Section {
                Button { showingAbout = true } label: {
                    HStack {
                        Label("About & Licenses", systemImage: "info.circle")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                }
            }
        }
.sheet(isPresented: $showingAbout) {
    AboutView()
        }
    }

    @ViewBuilder
    private var limitToolCallsRow: some View {
        Toggle("Limit Tool Calls", isOn: Binding(
            get: { viewModel.activePrompt.maxToolCalls > 0 },
            set: { newValue in
                viewModel.activePrompt.maxToolCalls = newValue ? 4 : 0
            }
        ))

        if viewModel.activePrompt.maxToolCalls > 0 {
            Stepper(
                "Max: \(viewModel.activePrompt.maxToolCalls)",
                value: Binding(
                    get: { max(viewModel.activePrompt.maxToolCalls, 1) },
                    set: { viewModel.activePrompt.maxToolCalls = max(min($0, 32), 1) }
                ),
                in: 1 ... 32
            )
        }
    }

    @ViewBuilder
    private var logprobsToggle: some View {
        Toggle("Output Logprobs", isOn: Binding(
            get: { viewModel.activePrompt.includeOutputLogprobs },
            set: { newValue in
                viewModel.activePrompt.includeOutputLogprobs = newValue
                if newValue, viewModel.activePrompt.topLogprobs == 0 {
                    viewModel.activePrompt.topLogprobs = 5
                }
                if !newValue {
                    viewModel.activePrompt.topLogprobs = 0
                }
            }
        ))
        .disabled(modelCaps?.supportsReasoningEffort == true)

        if viewModel.activePrompt.includeOutputLogprobs {
            Stepper(
                "Top Logprobs: \(viewModel.activePrompt.topLogprobs)",
                value: $viewModel.activePrompt.topLogprobs,
                in: 1 ... 20
            )
        }
    }
}

// MARK: - Apple Integrations Card

#if canImport(EventKit)
import EventKit
import Contacts

private struct AppleIntegrationsCard: View {
    @State private var calendarAccess: EKAuthorizationStatus = .notDetermined
    @State private var remindersAccess: EKAuthorizationStatus = .notDetermined
    @State private var contactsAccess: CNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            integrationRow(
                icon: "calendar",
                color: .red,
                title: "Calendar",
                status: calendarAccess
            )

            integrationRow(
                icon: "checkmark.circle",
                color: .orange,
                title: "Reminders",
                status: remindersAccess
            )

            contactsRow

            if needsPermission {
                Button { requestPermissions() } label: {
                    Label("Grant Access", systemImage: "hand.raised")
                        .font(.caption)
                }
.buttonStyle(.bordered)
    .disabled(isRequesting)
            }
        }
.onAppear { refreshStatus() }
    }

    private var needsPermission: Bool {
        calendarAccess == .notDetermined ||
            remindersAccess == .notDetermined ||
            contactsAccess == .notDetermined
    }

    private func integrationRow(icon: String, color: Color, title: String, status: EKAuthorizationStatus) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.caption)
            Spacer()
            statusBadge(for: status)
        }
    }

    private var contactsRow: some View {
        HStack {
            Image(systemName: "person.crop.circle").foregroundColor(.blue)
            Text("Contacts").font(.caption)
            Spacer()
            contactsStatusBadge
        }
    }

    @ViewBuilder
    private func statusBadge(for status: EKAuthorizationStatus) -> some View {
        switch status {
        case .fullAccess, .authorized:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
        case .denied, .restricted:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption)
        default:
            Image(systemName: "circle").foregroundColor(.secondary).font(.caption)
        }
    }

    @ViewBuilder
    private var contactsStatusBadge: some View {
        switch contactsAccess {
        case .authorized:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
        case .denied, .restricted:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption)
        default:
            Image(systemName: "circle").foregroundColor(.secondary).font(.caption)
        }
    }

    private func refreshStatus() {
        calendarAccess = EKEventStore.authorizationStatus(for: .event)
        remindersAccess = EKEventStore.authorizationStatus(for: .reminder)
        contactsAccess = CNContactStore.authorizationStatus(for: .contacts)
    }

    private func requestPermissions() { 
        isRequesting = true
        Task {
            do { 
                try await AppContainer.shared.appleProvider.connect(presentingAnchor: nil)
                await MainActor.run {
                    refreshStatus()
                    isRequesting = false
                }
            } catch {
                await MainActor.run { 
                    refreshStatus()
                    isRequesting = false
                }
            }
        }
    }
}
#endif

// MARK: - Preview

#Preview {
    SettingsHomeView()
        .environmentObject(ChatViewModel())
}
