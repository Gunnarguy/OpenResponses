import SwiftUI
import UIKit

/// Settings, laid out like the system Settings app: one list of named pages, each row showing what is set now, and a
/// search field that finds any option by name.
///
/// Until 3.1 Settings was five segmented tabs (General, Model, Tools, MCP, Advanced). Local Python, the hosted shell,
/// multi-agent, moderation, the voice settings and the API Workbench sat at the bottom of the Model tab under one
/// "Current Responses capabilities" heading, Decisions and Batch under Advanced, and Verbosity appeared twice. Gunnar,
/// 2026-11-19: "holy shit are some of the best options hidden".
struct SettingsHomeView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @StateObject private var promptLibrary = PromptLibrary()
    @Environment(\.dismiss) private var dismiss

    @State private var path: [SettingsPage] = []
    @State private var searchText = ""
    @State private var hasApiKey = false
    @State private var showingPromptLibrary = false
    @State private var showingVoiceSettings = false
    @AppStorage(AppTextSize.storageKey) private var textSizeSetting = AppTextSize.system
    @State private var showingAbout = false
    @State private var resetConfirm = false
    @State private var showingFiles = false

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                if searchText.isEmpty {
                    rootSections
                } else {
                    searchResults
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: SettingsPage.self) { page in
                destination(for: page)
            }
        }
        .onAppear(perform: refreshKeyStatus)
        .onReceive(NotificationCenter.default.publisher(for: .openAIKeyDidChange)) { _ in refreshKeyStatus() }
        .sheet(isPresented: $showingPromptLibrary) {
            PromptLibraryView(
                library: promptLibrary,
                createPromptFromCurrentSettings: { viewModel.activePrompt }
            )
        }
        .sheet(isPresented: $showingVoiceSettings) { VoiceModeSettingsSheet() }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .sheet(isPresented: $showingFiles) { FileManagerView().environmentObject(viewModel) }
    }

    private func refreshKeyStatus() {
        hasApiKey = !(KeychainService.shared.load(forKey: "openAIKey") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var prompt: Prompt { viewModel.activePrompt }

    // MARK: Root

    @ViewBuilder
    private var rootSections: some View {
        Section {
            NavigationLink(value: SettingsPage.account) {
                SettingsRow("OpenAI API Key", icon: hasApiKey ? "key.fill" : "key.slash", tint: hasApiKey ? .green : .red,
                            value: hasApiKey ? "Saved" : "Not set")
            }
            if !hasApiKey || viewModel.exploreModeEnabled {
                Toggle(isOn: Binding(
                    get: { viewModel.exploreModeEnabled },
                    set: { viewModel.setExploreModeEnabled($0) }
                )) {
                    SettingsToggleLabel("Demo Mode", icon: "play.circle.fill", tint: .orange,
                                        detail: "Try the app with built-in answers. Nothing is sent to OpenAI.")
                }
                if viewModel.exploreModeEnabled {
                    Button { viewModel.startExploreDemoConversation(); dismiss() } label: {
                        Label("Start Demo", systemImage: "sparkles")
                    }
                    Button(role: .destructive) { viewModel.exitExploreDemo() } label: {
                        Label("Exit Demo", systemImage: "xmark.circle")
                    }
                }
            }
        }

        Section {
            NavigationLink(value: SettingsPage.model) {
                SettingsRow("Model & Reasoning", icon: "cpu", tint: .blue, value: modelSummary)
            }
            NavigationLink(value: SettingsPage.instructions) {
                SettingsRow("Instructions", icon: "text.quote", tint: .indigo, value: instructionsSummary)
            }
            NavigationLink(value: SettingsPage.responseFormat) {
                SettingsRow("Response Format", icon: "text.alignleft", tint: .teal, value: responseSummary)
            }
            Button { showingVoiceSettings = true } label: {
                SettingsRow("Voice", icon: "waveform", tint: .pink,
                            value: CurrentModelCatalog.supportedRealtimeModel(UserDefaults.standard.string(forKey: "realtime_model") ?? CurrentModelCatalog.realtimeModel))
            }
            .buttonStyle(.plain)
        } header: {
            SettingsSectionHeader("Assistant", icon: "sparkles")
        }

        Section {
            NavigationLink(value: SettingsPage.tools) {
                SettingsRow("Tools", icon: "wrench.and.screwdriver.fill", tint: .orange, value: toolsSummary)
            }
            NavigationLink(value: SettingsPage.agents) {
                SettingsRow("Agents & Tool Calling", icon: "person.3.fill", tint: .purple, value: agentsSummary)
            }
            if AppFeatureFlags.isMCPAvailable {
                NavigationLink(value: SettingsPage.connections) {
                    SettingsRow("Connectors", icon: "link", tint: .cyan, value: connectorSummary(viewModel.activePrompt))
                }
            }
            Button { showingFiles = true } label: {
                SettingsRow("Files & Vector Stores", icon: "folder.fill", tint: .brown, value: nil)
            }
            .buttonStyle(.plain)
        } header: {
            SettingsSectionHeader("What the assistant can do", icon: "wrench.and.screwdriver")
        } footer: {
            Text("Tools let the assistant search the web, read your files, run code, draw images, use your calendar and more.")
        }

        Section {
            Button { showingPromptLibrary = true } label: {
                SettingsRow("Prompt Library", icon: "books.vertical.fill", tint: .mint, value: nil)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) { resetConfirm = true } label: {
                Label("Reset All Prompt Settings", systemImage: "arrow.counterclockwise")
            }
            .alert("Reset Prompt Settings?", isPresented: $resetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { viewModel.resetToDefaultPrompt() }
            } message: {
                Text("Restore the model, instructions, tools and options to their defaults. Your API key, conversations and voice choice are kept.")
            }
        } header: {
            SettingsSectionHeader("Presets", icon: "bookmark")
        }

        Section {
            NavigationLink(value: SettingsPage.workbench) {
                SettingsRow("API Workbench", icon: "hammer.fill", tint: .gray, value: nil)
            }
            NavigationLink(value: SettingsPage.decisions) {
                SettingsRow("Decisions", icon: "checklist", tint: .green, value: nil)
            }
            NavigationLink(value: SettingsPage.batch) {
                SettingsRow("Batch Jobs", icon: "clock.arrow.circlepath", tint: .blue, value: nil)
            }
            NavigationLink(value: SettingsPage.developer) {
                SettingsRow("Request Options", icon: "slider.horizontal.3", tint: .gray, value: serviceTierName)
            }
        } header: {
            SettingsSectionHeader("Developer", icon: "hammer")
        } footer: {
            Text("Send any API request by hand, ask yes-or-no and scoring questions, run batches, and choose what each response includes.")
        }

        Section {
            NavigationLink(value: SettingsPage.privacy) {
                SettingsRow("Privacy & Safety", icon: "hand.raised.fill", tint: .blue, value: prompt.storeResponses ? "Stored on OpenAI" : "Not stored")
            }
            NavigationLink(value: SettingsPage.textSize) {
                SettingsRow("Text Size", icon: "textformat.size", tint: .blue, value: AppTextSize.summary(textSizeSetting))
            }
            Button { showingAbout = true } label: {
                SettingsRow("About, Licenses & Rating", icon: "info.circle.fill", tint: .gray, value: nil)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Summaries shown on the root rows

    private var modelSummary: String {
        let caps = ModelCompatibilityService.shared.getCapabilities(for: prompt.openAIModel)
        guard caps?.supportsReasoningEffort == true else { return prompt.openAIModel }
        return "\(prompt.openAIModel) · \(ModelConfigurationView.effortName(prompt.reasoningEffort))"
    }

    private var instructionsSummary: String {
        let text = prompt.systemInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "None" : "Custom"
    }

    private var responseSummary: String {
        var parts = [prompt.textFormatType == "json_schema" ? "JSON" : "Text"]
        if !prompt.enableStreaming { parts.append("no streaming") }
        return parts.joined(separator: " · ")
    }

    private var enabledToolNames: [String] {
        var names: [String] = []
        if prompt.enableWebSearch { names.append("Web") }
        if prompt.enableFileSearch { names.append("Files") }
        if prompt.enableCodeInterpreter { names.append("Code") }
        if prompt.currentOptions.localPython { names.append("Python") }
        if prompt.currentOptions.hostedShell { names.append("Shell") }
        if prompt.enableImageGeneration { names.append("Images") }
        if prompt.enableComputerUse { names.append("Computer") }
        if prompt.enableAppleIntegrations { names.append("Apple") }
        if prompt.enableCustomTool { names.append("Custom") }
        return names
    }

    private var toolsSummary: String {
        let names = enabledToolNames
        if names.isEmpty { return "None on" }
        if names.count <= 3 { return names.joined(separator: ", ") }
        return "\(names.count) on"
    }

    private var agentsSummary: String {
        if prompt.backgroundMode { return "Background" }
        if prompt.currentOptions.multiAgent { return "Multi-agent" }
        switch prompt.toolChoice {
        case "required": return "Always use tools"
        case "none": return "No tools"
        default: return "Automatic"
        }
    }

    private var serviceTierName: String {
        switch prompt.serviceTier {
        case "default": return "Standard"
        case "auto", "": return "Auto"
        default: return prompt.serviceTier.capitalized
        }
    }

    // MARK: Search

    @ViewBuilder
    private var searchResults: some View {
        let matches = SettingsSearchIndex.matches(searchText)
        if matches.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            Section("Settings") {
                ForEach(matches) { entry in
                    Button {
                        open(entry.page)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).foregroundStyle(.primary)
                            Text(entry.location).font(.caption).foregroundStyle(Color.accessibleSecondaryText)
                        }
                    }
                }
            }
        }
    }

    private func open(_ page: SettingsPage) {
        searchText = ""
        switch page {
        case .voice: showingVoiceSettings = true
        case .about: showingAbout = true
        case .promptLibrary: showingPromptLibrary = true
        case .files: showingFiles = true
        default: path = [page]
        }
    }

    // MARK: Pages

    @ViewBuilder
    private func destination(for page: SettingsPage) -> some View {
        switch page {
        case .account: AccountPage()
        case .model:
            Form {
                ModelConfigurationView(activePrompt: $viewModel.activePrompt, openAIService: AppContainer.shared.openAIService,
                                       onSave: { viewModel.saveActivePrompt() }, part: .model)
                ReasoningOptionsSection()
            }
            .navigationTitle("Model & Reasoning")
        case .instructions:
            Form {
                ModelConfigurationView(activePrompt: $viewModel.activePrompt, openAIService: AppContainer.shared.openAIService,
                                       onSave: { viewModel.saveActivePrompt() }, part: .instructions)
            }
            .navigationTitle("Instructions")
            .onDisappear { viewModel.saveActivePrompt() }
        case .responseFormat:
            Form {
                ModelConfigurationView(activePrompt: $viewModel.activePrompt, openAIService: AppContainer.shared.openAIService,
                                       onSave: { viewModel.saveActivePrompt() }, part: .responseFormat)
                CompactionSection()
            }
            .navigationTitle("Response Format")
            .onDisappear { viewModel.saveActivePrompt() }
        case .tools: ToolsTab().navigationTitle("Tools")
        case .customTool:
            Form { CustomToolSections() }
                .navigationTitle("Custom Tool")
                .onDisappear { viewModel.saveActivePrompt() }
        case .agents:
            Form { AgentOptionsSections() }
                .navigationTitle("Agents & Tool Calling")
                .onDisappear { viewModel.saveActivePrompt() }
        case .connections: MCPConnectionsView(viewModel: viewModel)
        case .workbench: APIWorkbenchView()
        case .decisions: DecisionsView()
        case .batch: BatchJobsView()
        case .developer: AdvancedTab().navigationTitle("Request Options")
        case .privacy: PrivacyPage()
        case .textSize: TextSizeSettingsView()
        case .voice, .about, .promptLibrary, .files: EmptyView()
        }
    }
}

/// Every page Settings can open. Sheets (voice, about, prompt library) are listed so search can open them.
enum SettingsPage: Hashable {
    case account, model, instructions, responseFormat, voice
    case tools, customTool, agents, connections, files
    case promptLibrary
    case workbench, decisions, batch, developer
    case privacy, textSize, about
}

/// A Settings row: colored icon tile, name, and the current value in gray on the right.
struct SettingsRow: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color
    let value: String?

    init(_ title: LocalizedStringKey, icon: String, tint: Color, value: String?) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.value = value
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // At the accessibility text sizes one line has room for a word or two, so the icon goes and the
                // value sits under the title; side by side they broke words into pieces ("Op / en / AI").
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(.primary)
                    if let value {
                        Text(value).foregroundStyle(Color.accessibleSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    SettingsIconTile(icon: icon, tint: tint)
                    Text(title).foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    if let value {
                        Text(value)
                            .foregroundStyle(Color.accessibleSecondaryText)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// "2 of 3 on": how many saved connections this chat uses.
@MainActor
func connectorSummary(_ prompt: Prompt) -> String {
    let all = MCPConnectionStore.shared.connections
    guard !all.isEmpty else { return "None yet" }
    let ids = Set(prompt.currentOptions.mcpConnectionIDs ?? [])
    let on = prompt.enableMCPTool ? all.filter { ids.contains($0.id) }.count : 0
    return "\(on) of \(all.count) on"
}

/// A root section header. The Form's own header style stops growing before the largest text sizes (the
/// accessibility audit reported "Dynamic Type font sizes are partially unsupported" on 2026-11-19), so the
/// header sets a text style that scales the whole way. An HStack rather than a Label: the audit misreads a
/// Label's text frame (see knownLabelFrameQuirks in the UI tests).
struct SettingsSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    init(_ title: LocalizedStringKey, icon: String) { self.title = title; self.icon = icon }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).accessibilityHidden(true)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.accessibleSecondaryText)
        .textCase(nil)
    }
}

// MARK: - Search index

/// Every option a person might look for, with the words they might use, and the page that holds it.
struct SettingsSearchIndex {
    struct Entry: Identifiable {
        let title: String
        let location: String
        let page: SettingsPage
        let keywords: String
        var id: String { title + location }
    }

    static func matches(_ query: String) -> [Entry] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        return entries.filter { entry in
            let haystack = (entry.title + " " + entry.location + " " + entry.keywords).lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    static let entries: [Entry] = [
        Entry(title: "OpenAI API Key", location: "API Key", page: .account, keywords: "key sk token account sign"),
        Entry(title: "Demo Mode", location: "Settings", page: .account, keywords: "explore demo offline try"),
        Entry(title: "Model", location: "Model & Reasoning", page: .model, keywords: "gpt sol luna astra choose switch"),
        Entry(title: "Reasoning Effort", location: "Model & Reasoning", page: .model, keywords: "think thinking effort high low"),
        Entry(title: "Reasoning Summary", location: "Model & Reasoning", page: .model, keywords: "thoughts summary show thinking"),
        Entry(title: "Answer Length (Verbosity)", location: "Model & Reasoning", page: .model, keywords: "verbosity short long concise"),
        Entry(title: "Temperature and Top P", location: "Model & Reasoning", page: .model, keywords: "creativity random sampling"),
        Entry(title: "Pro Reasoning Mode", location: "Model & Reasoning", page: .model, keywords: "pro compute harder"),
        Entry(title: "Reuse Earlier Reasoning", location: "Model & Reasoning", page: .model, keywords: "reasoning context turns"),
        Entry(title: "System Instructions", location: "Instructions", page: .instructions, keywords: "prompt persona personality behavior"),
        Entry(title: "Developer Instructions", location: "Instructions", page: .instructions, keywords: "rules developer"),
        Entry(title: "JSON Schema Output", location: "Response Format", page: .responseFormat, keywords: "structured json format schema"),
        Entry(title: "Limit Response Length", location: "Response Format", page: .responseFormat, keywords: "max output tokens length"),
        Entry(title: "Stream Responses", location: "Response Format", page: .responseFormat, keywords: "streaming live typing"),
        Entry(title: "Compact Long Chats", location: "Response Format", page: .responseFormat, keywords: "compaction context long truncation"),
        Entry(title: "Voice", location: "Voice", page: .voice, keywords: "realtime live audio speak talk voice"),
        Entry(title: "Text Size", location: "Text Size", page: .textSize, keywords: "font text size bigger smaller larger dynamic type readable zoom"),
        Entry(title: "Web Search", location: "Tools", page: .tools, keywords: "internet browse search domains location"),
        Entry(title: "File Search", location: "Tools", page: .tools, keywords: "vector store documents rag hybrid"),
        Entry(title: "Code Interpreter", location: "Tools", page: .tools, keywords: "python sandbox charts memory"),
        Entry(title: "Local Python", location: "Tools", page: .tools, keywords: "python pyodide device offline code"),
        Entry(title: "Hosted Shell", location: "Tools", page: .tools, keywords: "shell terminal container bash"),
        Entry(title: "Image Generation", location: "Tools", page: .tools, keywords: "draw picture image size quality"),
        Entry(title: "Computer Use", location: "Tools", page: .tools, keywords: "browser click automate"),
        Entry(title: "Apple Calendar, Reminders and Contacts", location: "Tools", page: .tools, keywords: "calendar reminders contacts events apple"),
        Entry(title: "Notion", location: "Connectors", page: .connections, keywords: "notion mcp connector sign in"),
        Entry(title: "Custom Tool", location: "Tools", page: .customTool, keywords: "function webhook calculator echo"),
        Entry(title: "Connectors", location: "Connectors", page: .connections, keywords: "mcp connectors connected apps servers remote registry integrations linear slack github figma"),
        Entry(title: "Files & Vector Stores", location: "Files", page: .files, keywords: "upload files vector stores manage"),
        Entry(title: "Multi-agent", location: "Agents & Tool Calling", page: .agents, keywords: "subagents agents helpers parallel"),
        Entry(title: "Load Tools on Demand", location: "Agents & Tool Calling", page: .agents, keywords: "tool search defer"),
        Entry(title: "Async Lookups", location: "Agents & Tool Calling", page: .agents, keywords: "async background tools"),
        Entry(title: "Programmatic Tool Calling", location: "Agents & Tool Calling", page: .agents, keywords: "programmatic code tools"),
        Entry(title: "Tool Choice", location: "Agents & Tool Calling", page: .agents, keywords: "required auto none use tools"),
        Entry(title: "Parallel Tool Calls", location: "Agents & Tool Calling", page: .agents, keywords: "parallel several"),
        Entry(title: "Limit Tool Calls", location: "Agents & Tool Calling", page: .agents, keywords: "max tool calls"),
        Entry(title: "Background Mode", location: "Agents & Tool Calling", page: .agents, keywords: "background long task"),
        Entry(title: "Prompt Library", location: "Presets", page: .promptLibrary, keywords: "presets save load"),
        Entry(title: "API Workbench", location: "Developer", page: .workbench, keywords: "raw request endpoint curl http"),
        Entry(title: "Decisions", location: "Developer", page: .decisions, keywords: "classify yes no score choice luna"),
        Entry(title: "Batch Jobs", location: "Developer", page: .batch, keywords: "batch jsonl bulk"),
        Entry(title: "Service Tier", location: "Request Options", page: .developer, keywords: "flex fast priority speed cost"),
        Entry(title: "Response Includes and Logprobs", location: "Request Options", page: .developer, keywords: "include logprobs sources results"),
        Entry(title: "Custom Metadata", location: "Request Options", page: .developer, keywords: "metadata json tags"),
        Entry(title: "Store on OpenAI", location: "Privacy & Safety", page: .privacy, keywords: "store retention history"),
        Entry(title: "Content Moderation", location: "Privacy & Safety", page: .privacy, keywords: "moderation block flagged safety"),
        Entry(title: "Data Sharing Consent", location: "Privacy & Safety", page: .privacy, keywords: "consent privacy policy sharing"),
        Entry(title: "Safety Identifier and Prompt Cache Key", location: "Privacy & Safety", page: .privacy, keywords: "cache identity safety identifier"),
        Entry(title: "About and Licenses", location: "About", page: .about, keywords: "version licenses rate review"),
    ]
}

// MARK: - API Key page

private struct AccountPage: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var apiKey: String = ""
    @State private var saveState: ApiKeySaveState = .idle
    @State private var lastSavedNormalized: String = ""
    @State private var pendingSave: DispatchWorkItem?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    SecureField("sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .onSubmit { commit(apiKey) }
                        .accessibilityConfiguration(
                            hint: AccessibilityUtils.Hint.apiKeyField,
                            identifier: AccessibilityUtils.Identifier.apiKeyField
                        )
                    if !apiKey.isEmpty {
                        Button { apiKey = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear API key")
                    }
                    saveStatusBadge
                }
            } header: {
                Text("OpenAI API Key")
            } footer: {
                Text("Every request uses this key and is billed to your OpenAI account. It is stored in this device's Keychain. Create one at platform.openai.com.")
            }
        }
        .navigationTitle("API Key")
        .onAppear {
            let loaded = KeychainService.shared.load(forKey: "openAIKey") ?? ""
            apiKey = loaded
            lastSavedNormalized = normalize(loaded)
            saveState = .idle
        }
        .onChange(of: apiKey) { _, newValue in schedule(newValue) }
        .onDisappear { commit(apiKey) }
    }

    @ViewBuilder
    private var saveStatusBadge: some View {
        switch saveState {
        case .idle:
            if normalize(apiKey) != lastSavedNormalized {
                Button { commit(apiKey) } label: {
                    Image(systemName: "checkmark.circle").foregroundColor(.blue)
                }
                .accessibilityLabel("Save API key")
            }
        case .saving:
            ProgressView().controlSize(.small)
        case .saved:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).accessibilityLabel("Saved")
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).accessibilityLabel("Not saved")
        }
    }

    private func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func schedule(_ raw: String) {
        guard normalize(raw) != lastSavedNormalized else { return }
        pendingSave?.cancel()
        let work = DispatchWorkItem { [raw] in commit(raw) }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func commit(_ raw: String) {
        pendingSave?.cancel()
        pendingSave = nil
        let normalized = normalize(raw)
        guard normalized != lastSavedNormalized else { return }
        saveState = .saving
        DispatchQueue.global(qos: .userInitiated).async {
            let success = normalized.isEmpty
                ? KeychainService.shared.delete(forKey: "openAIKey")
                : KeychainService.shared.save(value: normalized, forKey: "openAIKey")
            DispatchQueue.main.async {
                self.lastSavedNormalized = normalized
                self.saveState = success ? .saved : .failed
                NotificationCenter.default.post(name: .openAIKeyDidChange, object: nil)
            }
        }
    }
}

private enum ApiKeySaveState: Equatable {
    case idle, saving, saved, failed
}

// MARK: - Privacy & Safety page

private struct PrivacyPage: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @AppStorage("aiDataSharingConsentVersion") private var aiDataSharingConsentVersion = 0

    var body: some View {
        Form {
            Section {
                Toggle(isOn: storeResponsesBinding) {
                    SettingsToggleLabel("Store on OpenAI", icon: "externaldrive.fill.badge.icloud", tint: .blue,
                                        detail: "Keeps responses on OpenAI so a chat can continue from them and Background Mode works. Off: nothing is kept there.")
                }
            } header: {
                Text("Storage")
            }

            ModerationSection()

            Section {
                Text("Prompts, attachments, and request-related tool data are sent to OpenAI only after you approve the first live request.")
                Text(aiDataSharingConsentVersion >= AppFeatureFlags.aiDataSharingConsentVersion
                     ? "First-send consent has been granted on this device."
                     : "You'll see the data-sharing notice before the first live request.")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondaryText)
                Link(destination: URL(string: "https://github.com/Gunnarguy/OpenResponses/blob/main/PRIVACY.md")!) {
                    Label("Open Privacy Policy", systemImage: "lock.shield")
                }
                if aiDataSharingConsentVersion >= AppFeatureFlags.aiDataSharingConsentVersion {
                    Button(role: .destructive) {
                        aiDataSharingConsentVersion = 0
                        viewModel.resetAIDataSharingConsent()
                    } label: {
                        Label("Reset First-Send Consent", systemImage: "arrow.counterclockwise")
                    }
                }
            } header: {
                Text("Data sharing")
            } footer: {
                Text("Demo Mode stays offline and never sends requests to OpenAI.")
            }

            Section {
                TextField("Safety identifier", text: $viewModel.activePrompt.safetyIdentifier)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                TextField("Prompt cache key", text: $viewModel.activePrompt.promptCacheKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            } header: {
                Text("Identity and caching")
            } footer: {
                Text("The safety identifier is a hashed user ID OpenAI uses for abuse detection. A prompt cache key groups requests that share a long prompt so they answer faster.")
            }
        }
        .navigationTitle("Privacy & Safety")
        .onDisappear { viewModel.saveActivePrompt() }
    }

    private var storeResponsesBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activePrompt.storeResponses },
            set: { newValue in
                viewModel.activePrompt.storeResponses = newValue
                viewModel.applyDraftStorePreference(newValue)
                if !newValue {
                    viewModel.activePrompt.backgroundMode = false
                }
            }
        )
    }
}

// MARK: - Tools Tab (Consolidated with Inline Selection)

private struct ToolsTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingFileManager = false
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
                Toggle(isOn: $viewModel.activePrompt.enableWebSearch) {
                    SettingsToggleLabel("Web Search", icon: "globe", tint: .blue,
                                        detail: "Looks things up on the web and cites its sources.")
                }

                if viewModel.activePrompt.enableWebSearch {
                    Toggle("Live web access", isOn: $viewModel.activePrompt.currentOptions.webSearchExternalAccess)
                    DisclosureGroup("Domains, location and search instructions", isExpanded: $showWebSearchAdvanced) {
                        webSearchOptions
                    }
                    .font(.subheadline)
                }
            } header: {
                Text("Search")
            }

            // MARK: File Search with Smart Vector Store Selection

            Section {
                Toggle(isOn: $viewModel.activePrompt.enableFileSearch) {
                    SettingsToggleLabel("File Search", icon: "doc.text.magnifyingglass", tint: .purple,
                                        detail: "Answers from documents you uploaded to a vector store.")
                }

                if viewModel.activePrompt.enableFileSearch {
                    vectorStoreSelectionView
                    Toggle("Hybrid ranking (meaning + keywords)", isOn: Binding(
                        get: { viewModel.activePrompt.currentOptions.hybridEmbeddingWeight != nil },
                        set: { enabled in
                            viewModel.activePrompt.currentOptions.hybridEmbeddingWeight = enabled ? 0.5 : nil
                            viewModel.activePrompt.currentOptions.hybridTextWeight = enabled ? 0.5 : nil
                        }))
                    if let embedding = viewModel.activePrompt.currentOptions.hybridEmbeddingWeight {
                        Slider(value: Binding(get: { embedding }, set: {
                            viewModel.activePrompt.currentOptions.hybridEmbeddingWeight = $0
                            viewModel.activePrompt.currentOptions.hybridTextWeight = 1 - $0
                        }), in: 0...1, step: 0.1) { Text("Meaning weight") }
                        Text("Meaning \(Int(embedding * 100))% · keywords \(100 - Int(embedding * 100))%")
                            .font(.caption).foregroundStyle(Color.accessibleSecondaryText)
                    }
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
                Text("Your documents")
            } footer: {
                if viewModel.activePrompt.enableFileSearch, !availableVectorStores.isEmpty {
                    Text("Select up to 2 vector stores. \(selectedVectorStoreIds.count)/2 selected.")
                }
            }

            // MARK: Code

            Section {
                Toggle(isOn: $viewModel.activePrompt.enableCodeInterpreter) {
                    SettingsToggleLabel("Code Interpreter", icon: "chart.xyaxis.line", tint: .orange,
                                        detail: "Runs Python in an OpenAI sandbox to calculate, analyze files and draw charts.")
                }
                if viewModel.activePrompt.enableCodeInterpreter {
                    fileSelectionView
                    Picker("Sandbox memory", selection: $viewModel.activePrompt.currentOptions.codeInterpreterMemoryLimit) {
                        Text("Default").tag("")
                        ForEach(["1g", "4g", "16g", "64g"], id: \.self) { Text($0.uppercased().replacingOccurrences(of: "G", with: " GB")).tag($0) }
                    }
                }
            } header: {
                Text("Run code")
            } footer: {
                if viewModel.activePrompt.enableCodeInterpreter, !availableFiles.isEmpty {
                    Text("Files you select are loaded into the sandbox. \(selectedFileIds.count) selected.")
                }
            }

            CodeRunningToolsSection()

            // MARK: Create

            Section {
                Toggle(isOn: $viewModel.activePrompt.enableImageGeneration) {
                    SettingsToggleLabel("Image Generation", icon: "paintpalette.fill", tint: .pink,
                                        detail: isImageGenerationSupported ? "Draws and edits images in the chat." : "Not available with the selected model.")
                }
                .disabled(!isImageGenerationSupported)

                if viewModel.activePrompt.enableImageGeneration {
                    DisclosureGroup("Model, size, quality and more", isExpanded: $showImageGenAdvanced) {
                        ImageGenerationOptionsRows()
                    }
                    .font(.subheadline)
                }
            } header: {
                Text("Create")
            }

            // MARK: Act

            Section {
                computerUseToggle
                #if canImport(EventKit)
                    Toggle(isOn: $viewModel.activePrompt.enableAppleIntegrations) {
                        SettingsToggleLabel("Calendar, Reminders & Contacts", icon: "calendar", tint: .red,
                                            detail: "Reads and adds events, reminders and contacts on this iPhone, with your permission.")
                    }
                    if viewModel.activePrompt.enableAppleIntegrations {
                        AppleIntegrationsCard()
                    }
                #endif
                NavigationLink(value: SettingsPage.customTool) {
                    SettingsRow("Custom Tool", icon: "puzzlepiece.extension.fill", tint: .gray,
                                value: viewModel.activePrompt.enableCustomTool ? "On" : "Off")
                }
            } header: {
                Text("Act for you")
            }

            // MARK: Connected apps

            Section {
                if AppFeatureFlags.isMCPAvailable {
                    NavigationLink(value: SettingsPage.connections) {
                        SettingsRow("Connectors", icon: "link", tint: .cyan, value: connectorSummary(viewModel.activePrompt))
                    }
                }
            } header: {
                Text("Other apps")
            } footer: {
                Text("Connect Notion, Linear, Slack, Figma and thousands of other services so the assistant can use them.")
            }
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView().environmentObject(viewModel)
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
        .onDisappear { viewModel.saveActivePrompt() }
        .onAppear {
            loadVectorStores()
            loadFiles()
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

                    Text("Up to 100 domains in each list. Separate with commas. Subdomains are included.")
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
                    Text("• Context size not supported on o3, deep research models")
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

        Toggle(isOn: computerUseBinding) {
            SettingsToggleLabel("Computer Use", icon: "cursorarrow.click.2", tint: .indigo,
                                detail: isComputerUseSupported
                                    ? "The model drives this app's browser one click at a time, and asks you before risky steps."
                                    : "Needs a computer-capable model such as GPT-6 Sol, Astra or Luna.")
        }
            .disabled(!isComputerUseSupported)
            .alert("Enable Computer Use?", isPresented: $showComputerUseDisclosure) {
                Button("Continue") {
                    viewModel.activePrompt.enableComputerUse = true
                    hasShownComputerUseDisclosure = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Computer Use lets the model drive the app's own browser, one click or keystroke at a time. It asks for your approval when OpenAI flags a safety check. Only allow actions you trust.")
            }

        if isComputerUseSupported, viewModel.activePrompt.enableComputerUse {
            Toggle(isOn: $viewModel.activePrompt.ultraStrictComputerUse) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict mode")
                    Text("Turns off the app's helper steps so only the model acts.")
                        .font(.caption).foregroundStyle(Color.accessibleSecondaryText)
                }
            }
        }
    }

    // MARK: - Helper Methods



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

// MARK: - Advanced Tab (Consolidated)

private struct AdvancedTab: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    private var modelCaps: ModelCompatibilityService.ModelCapabilities? {
        ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)
    }

    var body: some View {
        Form {
            Section {
                Picker("Service tier", selection: $viewModel.activePrompt.serviceTier) {
                    ForEach(tierOptions, id: \.self) { tier in
                        Text(tierLabel(tier)).tag(tier)
                    }
                }
                Picker("Prompt cache lifetime", selection: cacheLifetime) {
                    Text("30 minutes").tag("30m")
                    Text("12 hours").tag("12h")
                }
                .disabled(!supportsCacheOptions)
            } header: {
                Text("Speed and cost")
            } footer: {
                Text(speedAndCostFooter)
            }

            Section {
                Toggle("File search results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Web search results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                Toggle("Web search sources", isOn: $viewModel.activePrompt.includeWebSearchSources)
                Toggle("Code Interpreter output", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                if modelCaps?.supportsReasoningEffort == true {
                    Toggle("Encrypted reasoning content", isOn: $viewModel.activePrompt.includeReasoningContent)
                }
                logprobsToggle
            } header: {
                Text("Include in each response")
            } footer: {
                Text("Extra data the API returns with each answer, shown in the message details. Logprobs are not available on reasoning models.")
            }

            Section {
                TextEditor(text: $viewModel.activePrompt.metadata.bound)
                    .font(.system(.callout, design: .monospaced))
                    .frame(minHeight: 90)
                    .accessibilityLabel("Custom metadata JSON")
            } header: {
                Text("Custom metadata")
            } footer: {
                Text("JSON key-value pairs attached to each request, such as {\"project\": \"demo\"}.")
            }
        }
        .onDisappear { viewModel.saveActivePrompt() }
    }

    /// The tiers the selected model offers, plus the saved one if it does not offer it, so the picker still shows it.
    private var tierOptions: [String] {
        let offered = CurrentModelCatalog.serviceTiers(for: viewModel.activePrompt.openAIModel)
        let saved = viewModel.activePrompt.serviceTier
        return offered.contains(saved) || saved.isEmpty ? offered : offered + [saved]
    }

    private var savedTierIsOffered: Bool {
        let saved = viewModel.activePrompt.serviceTier
        return saved.isEmpty || CurrentModelCatalog.requestServiceTier(saved, model: viewModel.activePrompt.openAIModel) != nil
    }

    private func tierLabel(_ tier: String) -> String {
        let name: String
        switch tier {
        case "auto": name = "Auto"
        case "default": name = "Standard"
        case "flex": name = "Flex · cheaper, slower"
        case "fast", "priority": name = "Fast"
        case "ultrafast": name = "Ultrafast"
        default: name = tier.capitalized
        }
        return CurrentModelCatalog.serviceTiers(for: viewModel.activePrompt.openAIModel).contains(tier) || tier == "priority"
            ? name : name + " · not on this model"
    }

    /// `prompt_cache_options` is accepted on GPT-5.6 and later.
    private var supportsCacheOptions: Bool {
        ModelCompatibilityService.shared.isParameterSupported("prompt_cache_options", for: viewModel.activePrompt.openAIModel)
    }

    /// `prompt_cache_options.ttl`: "30m" (the default, written at 1.25 times the input rate) or "12h" (2.5 times),
    /// Responses API only (prompt caching guide, read 2026-11-20). 30 minutes clears the saved options.
    private var cacheLifetime: Binding<String> {
        Binding(
            get: { viewModel.activePrompt.promptCacheOptions?.ttl == "12h" ? "12h" : "30m" },
            set: { ttl in
                var options = viewModel.activePrompt.promptCacheOptions ?? PromptCacheOptions(mode: "implicit")
                if ttl == "12h" {
                    options.ttl = "12h"
                    viewModel.activePrompt.promptCacheOptions = options
                } else if options.mode == "implicit" {
                    viewModel.activePrompt.promptCacheOptions = nil
                } else {
                    options.ttl = nil
                    viewModel.activePrompt.promptCacheOptions = options
                }
            }
        )
    }

    private var speedAndCostFooter: String {
        let model = viewModel.activePrompt.openAIModel
        var lines = ["Flex costs less and may queue. Fast and Ultrafast answer sooner at a higher price. GPT-6.2 models have no Flex; Ultrafast is on GPT-6.2 Astra and Sol, GPT-6 Astra and GPT-6.1 Sol."]
        if !savedTierIsOffered {
            lines.append("\(tierLabel(viewModel.activePrompt.serviceTier).replacingOccurrences(of: " · not on this model", with: "")) isn't offered on \(model), so requests leave the tier out and OpenAI uses Auto.")
        }
        if viewModel.activePrompt.serviceTier == "ultrafast", CurrentModelCatalog.baseID(model).hasPrefix("gpt-6.2") {
            lines.append("Ultrafast on GPT-6.2 costs 3 times Standard through February 28, 2027, and 6 times from March 1, 2027.")
        }
        lines.append(supportsCacheOptions
            ? "A 12-hour cache keeps a reused prefix of 1,024 tokens or more for longer. Writing it costs 2.5 times the input rate instead of 1.25 times."
            : "Cache lifetime needs GPT-5.6 or later.")
        return lines.joined(separator: " ")
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
