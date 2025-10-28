import SwiftUI
import Combine

/// Modern Settings view for configuring the OpenAI API integration and tools.
/// 
/// Features:
/// - Intuitive card-based layout with modern design
/// - Enhanced API key configuration with validation
/// - Advanced model selection with compatibility indicators
/// - Comprehensive tool configuration with visual feedback
/// - Organized advanced settings with logical grouping
/// - Smooth animations and visual transitions
struct SettingsView: View {
    /// MCP (Model Context Protocol) configuration
    private var mcpConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            mcpConnectionSummary
            Divider()
            mcpActionButtons
        }
    }
    
    private var mcpConnectionSummary: some View {
        let prompt = viewModel.activePrompt
        let label = prompt.mcpServerLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = prompt.mcpServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedTools = prompt.mcpAllowedTools.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasConnectorConfigured = prompt.enableMCPTool && prompt.mcpIsConnector && prompt.mcpConnectorId?.isEmpty == false
        let hasRemoteConfigured = prompt.enableMCPTool && !prompt.mcpIsConnector && !label.isEmpty && !url.isEmpty
        let remoteTokenExists = hasRemoteConfigured ? (KeychainService.shared.load(forKey: "mcp_manual_\(label)") != nil) : false

        return VStack(alignment: .leading, spacing: 12) {
            if !prompt.enableMCPTool {
                Text("MCP is currently disabled. Enable the toggle above to link connectors or remote servers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if hasConnectorConfigured, let connectorId = prompt.mcpConnectorId, let connector = MCPConnector.connector(for: connectorId) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: connector.icon)
                            .foregroundColor(Color(hex: connector.color))
                        Text("Connected to \(connector.name)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(connector.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !allowedTools.isEmpty {
                        let toolCount = allowedTools.split(separator: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                        Text("Allowed tools: \(toolCount) (custom whitelist)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Allowed tools: all tools exposed by the connector")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text("Approval mode: \(prompt.mcpRequireApproval.capitalized)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if hasRemoteConfigured {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "server.rack")
                            .foregroundColor(.cyan)
                        Text("Remote server: \(label)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !allowedTools.isEmpty {
                        let toolCount = allowedTools.split(separator: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                        Text("Allowed tools: \(toolCount) (custom whitelist)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Allowed tools: all tools reported by the server")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text("Approval mode: \(prompt.mcpRequireApproval.capitalized)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(remoteTokenExists ? "Auth token stored securely in Keychain" : "Auth token missing — open the editor to provide one")
                        .font(.caption2)
                        .foregroundColor(remoteTokenExists ? .green : .orange)
                    if url.lowercased().contains("notion") {
                        Text("Uses the official Notion MCP server described at modelcontextprotocol.io")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No connector or remote server configured yet. Use the actions below to connect your services.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.cyan.opacity(0.08))
        .cornerRadius(10)
    }
    
    private var mcpActionButtons: some View {
        let prompt = viewModel.activePrompt
        let hasConnectorConfigured = prompt.enableMCPTool && prompt.mcpIsConnector && prompt.mcpConnectorId?.isEmpty == false
        let hasRemoteConfigured = prompt.enableMCPTool && !prompt.mcpIsConnector && !prompt.mcpServerLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !prompt.mcpServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                showingConnectorGallery = true
            } label: {
                Label("Open Connector Gallery", systemImage: "link.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            
            if hasRemoteConfigured {
                Button {
                    presentedRemoteConnector = remoteConnectorForActiveConfig()
                } label: {
                    Label("Edit Remote Server", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
            } else {
                Menu {
                    if let notionConnector = notionConnector {
                        Button("Official Notion Server") {
                            presentedRemoteConnector = notionConnector
                        }
                    }
                    Button("Custom MCP Server") {
                        presentedRemoteConnector = customRemoteConnector
                    }
                } label: {
                    Label("Add Remote Server", systemImage: "server.rack")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
            }
            
            if hasConnectorConfigured {
                Button(role: .destructive) {
                    disconnectMCPConnector()
                } label: {
                    Label("Disconnect Connector", systemImage: "trash")
                }
            } else if hasRemoteConfigured {
                Button(role: .destructive) {
                    disconnectRemoteMCP()
                } label: {
                    Label("Disconnect Remote Server", systemImage: "trash")
                }
            }
        }
    }
    
    private func disconnectMCPConnector() {
        guard let connectorId = viewModel.activePrompt.mcpConnectorId else { return }
        let keychainKey = "mcp_connector_\(connectorId)"
        KeychainService.shared.delete(forKey: keychainKey)
        viewModel.activePrompt.enableMCPTool = false
        viewModel.activePrompt.mcpConnectorId = nil
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpServerLabel = ""
        viewModel.activePrompt.mcpServerURL = ""
        viewModel.saveActivePrompt()
        AppLogger.log("🔌 SettingsView disconnected connector: \(connectorId)", category: .general, level: .info)
    }
    
    private func disconnectRemoteMCP() {
        let label = viewModel.activePrompt.mcpServerLabel
        if !label.isEmpty {
            KeychainService.shared.delete(forKey: "mcp_manual_\(label)")
            KeychainService.shared.delete(forKey: "mcp_auth_\(label)")
        }
        viewModel.activePrompt.enableMCPTool = false
        viewModel.activePrompt.mcpServerLabel = ""
        viewModel.activePrompt.mcpServerURL = ""
        viewModel.activePrompt.mcpAllowedTools = ""
        viewModel.activePrompt.mcpRequireApproval = "never"
        viewModel.activePrompt.mcpIsConnector = false
        viewModel.activePrompt.mcpConnectorId = nil
        viewModel.saveActivePrompt()
        AppLogger.log("🔌 SettingsView disconnected remote MCP server", category: .general, level: .info)
    }
    
    private func remoteConnectorForActiveConfig() -> MCPConnector {
        let url = viewModel.activePrompt.mcpServerURL.lowercased()
        if url.contains("notion"), let notion = notionConnector {
            return notion
        }
        return customRemoteConnector
    }
    
    private var notionConnector: MCPConnector? {
        MCPConnector.connector(for: "connector_notion")
    }
    
    private var customRemoteConnector: MCPConnector {
        MCPConnector(
            id: "remote_custom",
            name: "Custom MCP Server",
            description: "Connect to any MCP server by providing its HTTPS endpoint and authorization token.",
            icon: "server.rack",
            color: "#0FA3B1",
            oauthScopes: [],
            oauthInstructions: "Enter the HTTPS server URL (or local tunnel) and provide the token expected by your MCP deployment.",
            setupURL: nil,
            category: .development,
            popularTools: [],
            requiresRemoteServer: true
        )
    }
    
    // MARK: - Properties
    
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false
    @State private var showingAPIInspector = false
    @State private var showingDebugConsole = false
    @State private var selectedPresetId: UUID?
    @State private var showingConnectorGallery = false
    @State private var presentedRemoteConnector: MCPConnector?
    
    // Enhanced UI state management
    @State private var expandedSections: Set<SettingsSection> = [.essentials, .tools]
    @State private var isValidatingKey = false
    @State private var keyValidationStatus: ValidationStatus = .unknown
    @State private var showingAdvanced = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showingQuickPresets = false
    
    @StateObject private var promptLibrary = PromptLibrary()
    
    private var isImageGenerationSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(.imageGeneration, for: viewModel.activePrompt.openAIModel, isStreaming: viewModel.activePrompt.enableStreaming)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Modern header
                    HeaderView()
                    
                    // Search bar
                    SearchBar(searchText: $searchText, isSearching: $isSearching)
                    
                    // Quick actions bar
                    QuickActionsBar(
                        showingFileManager: $showingFileManager,
                        showingPromptLibrary: $showingPromptLibrary,
                        showingAPIInspector: $showingAPIInspector,
                        showingQuickPresets: $showingQuickPresets
                    )
                    
                    // Usage Analytics (only show if not searching)
                    if !isSearching {
                        UsageAnalyticsCard()
                    }
                    
                    // Main content cards
                    VStack(spacing: 20) {
                        presetCard
                        apiConfigurationCard
                        modelConfigurationCard
                        toolsCard
                        
                        if showingAdvanced {
                            SettingsCard(
                                title: "Advanced Configuration",
                                icon: "slider.horizontal.3",
                                color: .purple
                            ) {
                                advancedConfigurationCard
                            }
                            
                            SettingsCard(
                                title: "Developer Tools",
                                icon: "hammer.fill",
                                color: .red
                            ) {
                                debugCard
                            }
                        }
                    }
                    
                    // Toggle advanced settings
                    AdvancedToggleButton(showingAdvanced: $showingAdvanced)
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Extra space for navigation
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            setupOnAppear()
        }
        .onChange(of: promptLibrary.prompts) { _, prompts in
            validatePresetSelection(with: prompts)
        }
        .onChange(of: viewModel.activePrompt) { _, newPrompt in
            handleActivePromptChange(newPrompt)
        }
        .onChange(of: apiKey) { _, newValue in
            handleAPIKeyChange(newValue)
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingPromptLibrary) {
            PromptLibraryView(library: promptLibrary, createPromptFromCurrentSettings: {
                return viewModel.activePrompt
            })
            .onDisappear {
                promptLibrary.reload()
            }
        }
        .sheet(isPresented: $showingAPIInspector) { APIInspectorView() }
        .sheet(isPresented: $showingDebugConsole) { DebugConsoleView() }
        .sheet(isPresented: $showingQuickPresets) {
            QuickPresetsView { preset in
                applyPreset(preset)
                showingQuickPresets = false
            }
        }
        .sheet(isPresented: $showingConnectorGallery) {
            MCPConnectorGalleryView(viewModel: viewModel)
        }
        .sheet(item: $presentedRemoteConnector) { connector in
            RemoteServerSetupView(viewModel: viewModel, connector: connector)
        }
    }
}

// MARK: - Card Content Views

extension SettingsView {
    
    /// Modern preset selection card
    private var presetCard: some View {
        SettingsCard(title: "Preset Library", icon: "book.fill", color: .green) {
            VStack(alignment: .leading, spacing: 16) {
                presetDescription
                presetPicker
                presetManageButton
            }
        }
    }
    
    // MARK: - Preset Card Components
    
    private var presetDescription: some View {
        Text("Load saved configurations or create new presets")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var presetPicker: some View {
        Picker("Load Preset", selection: $selectedPresetId) {
            Text("Current Settings").tag(nil as UUID?)
                .foregroundColor(.primary)
            
            presetPickerDividerAndItems
        }
        .pickerStyle(.menu)
        .onChange(of: selectedPresetId) { _, newValue in
            if let preset = promptLibrary.prompts.first(where: { $0.id == newValue }) {
                applyPreset(preset)
            }
        }
    }
    
    @ViewBuilder
    private var presetPickerDividerAndItems: some View {
        if !promptLibrary.prompts.isEmpty {
            Divider()
            ForEach(promptLibrary.prompts) { prompt in
                Label(prompt.name, systemImage: "bookmark.fill")
                    .tag(prompt.id as UUID?)
            }
        }
    }
    
    private var presetManageButton: some View {
        Button(action: { showingPromptLibrary = true }) {
            Label("Manage Presets", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    /// Enhanced API configuration card
    private var apiConfigurationCard: some View {
        SettingsCard(title: "API Configuration", icon: "key.fill", color: .blue) {
            VStack(alignment: .leading, spacing: 16) {
                apiKeySection
                Divider()
                publishedPromptSection
            }
        }
    }
    
    // MARK: - API Configuration Card Components
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            apiKeyHeader
            apiKeyInputField
            apiKeyValidationError
        }
    }
    
    @ViewBuilder
    private var apiKeyValidationError: some View {
        if keyValidationStatus == .invalid {
            Text("API key should start with 'sk-'")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
    
    private var apiKeyHeader: some View {
        HStack {
            Text("OpenAI API Key")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HelpButton(text: "Enter your OpenAI API key (starts with 'sk-'). You can find this in your OpenAI dashboard under API Keys. Keep it secure and never share it publicly.")
            
            Spacer()
            
            apiKeyStatusIcon
        }
    }
    
    private var apiKeyStatusIcon: some View {
        Image(systemName: keyValidationStatus.icon)
            .foregroundColor(keyValidationStatus.color)
            .font(.caption)
            .rotationEffect(.degrees(keyValidationStatus == .validating ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: keyValidationStatus == .validating)
            .symbolEffect(.pulse, isActive: keyValidationStatus == .validating)
    }
    
    private var apiKeyInputField: some View {
        HStack {
            SecureField("Enter your API key (sk-...)", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            apiKeyClearButton
        }
    }
    
    @ViewBuilder
    private var apiKeyClearButton: some View {
        if !apiKey.isEmpty {
            Button(action: { apiKey = "" }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var publishedPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.activePrompt.enablePublishedPrompt) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use Published Prompt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Override settings with an OpenAI Playground prompt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.blue)
            
            publishedPromptIdField
        }
    }
    
    @ViewBuilder
    private var publishedPromptIdField: some View {
        if viewModel.activePrompt.enablePublishedPrompt {
            TextField("Published Prompt ID", text: $viewModel.activePrompt.publishedPromptId)
                .textFieldStyle(.roundedBorder)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    /// Modern model configuration card
    private var modelConfigurationCard: some View {
        SettingsCard(title: "Model Configuration", icon: "cpu.fill", color: .purple) {
            ModelConfigurationView(
                activePrompt: $viewModel.activePrompt,
                openAIService: AppContainer.shared.openAIService,
                onSave: { viewModel.saveActivePrompt() }
            )
        }
    }
    
    
    /// Modern tools configuration card
    private var toolsCard: some View {
        SettingsCard(title: "AI Tools & Capabilities", icon: "wrench.and.screwdriver.fill", color: .orange) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enable powerful AI tools for enhanced capabilities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                toolsCardComputerUseSection
                
                // Web Search Tool
                ToolToggleCard(
                    title: "Web Search",
                    description: "Search the internet for up-to-date information",
                    icon: "magnifyingglass.circle.fill",
                    color: .blue,
                    isEnabled: $viewModel.activePrompt.enableWebSearch,
                    isSupported: true,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    webSearchConfiguration
                }
                
                // Code Interpreter Tool
                ToolToggleCard(
                    title: "Code Interpreter",
                    description: "Execute Python code and analyze files",
                    icon: "terminal.fill",
                    color: .green,
                    isEnabled: $viewModel.activePrompt.enableCodeInterpreter,
                    isSupported: true,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    codeInterpreterConfiguration
                }
                
                // Image Generation Tool
                ToolToggleCard(
                    title: "Image Generation",
                    description: "Create images with DALL-E",
                    icon: "photo.artframe",
                    color: .purple,
                    isEnabled: $viewModel.activePrompt.enableImageGeneration,
                    isSupported: isImageGenerationSupported,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    EmptyView()
                }
                
                // File Search Tool
                ToolToggleCard(
                    title: "File Search",
                    description: "Search through uploaded documents",
                    icon: "doc.text.magnifyingglass",
                    color: .indigo,
                    isEnabled: $viewModel.activePrompt.enableFileSearch,
                    isSupported: true,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    fileSearchConfiguration
                }
                
                // MCP Tool
                ToolToggleCard(
                    title: "MCP Servers",
                    description: "Connect to external tools via Model Context Protocol",
                    icon: "externaldrive.connected.to.line.below",
                    color: .cyan,
                    isEnabled: $viewModel.activePrompt.enableMCPTool,
                    isSupported: true,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    mcpConfiguration
                }
                
                // Custom Function Tool
                ToolToggleCard(
                    title: "Custom Function Tool",
                    description: "Create custom functions for specific tasks",
                    icon: "function",
                    color: .teal,
                    isEnabled: $viewModel.activePrompt.enableCustomTool,
                    isSupported: true,
                    isDisabled: viewModel.activePrompt.enablePublishedPrompt
                ) {
                    customToolConfiguration
                }
                
                // Compatibility Summary
                ModelCompatibilityView(
                    modelId: viewModel.activePrompt.openAIModel,
                    prompt: viewModel.activePrompt,
                    isStreaming: viewModel.activePrompt.enableStreaming
                )
            }
        }
    }
    
    // MARK: - Tools Card Components
    
    @ViewBuilder
    private var toolsCardComputerUseSection: some View {
        // Computer Use Tool - only show for computer-use-preview model
        if viewModel.activePrompt.openAIModel == "computer-use-preview" {
            ToolToggleCard(
                title: "Computer Use",
                description: "Navigate and interact with websites (auto-enabled for this model)",
                icon: "display",
                color: .red,
                isEnabled: .constant(true), // Always enabled for computer-use-preview
                isSupported: true,
                isDisabled: true // Make it read-only since it's required for this model
            ) {
                computerUseConfiguration
            }
        }
    }
    
    /// Computer Use configuration - simplified since it's only available on computer-use-preview
    private var computerUseConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Computer Use is automatically enabled for this model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("The computer-use-preview model is specifically designed for screen interaction tasks.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Toggle(isOn: $viewModel.activePrompt.ultraStrictComputerUse) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ultra-strict Mode")
                        .font(.caption)
                    
                    Text("Disable all app-side helpers for pure model control")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.red)
        }
    }
    
    /// Web Search configuration
    private var webSearchConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search Mode", text: $viewModel.activePrompt.webSearchMode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Search Instructions (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.activePrompt.webSearchInstructions)
                    .frame(minHeight: 60)
                    .padding(.horizontal, 8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Max Pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(viewModel.activePrompt.webSearchMaxPages)", value: $viewModel.activePrompt.webSearchMaxPages, in: 1...20)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Crawl Depth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(viewModel.activePrompt.webSearchCrawlDepth)", value: $viewModel.activePrompt.webSearchCrawlDepth, in: 0...5)
                        .labelsHidden()
                }
            }
        }
    }
    
    /// Code Interpreter configuration
    private var codeInterpreterConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Container Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Container Type", selection: $viewModel.activePrompt.codeInterpreterContainerType) {
                    Text("Auto").tag("auto")
                    Text("Secure").tag("secure")
                    Text("GPU").tag("gpu")
                }
                .pickerStyle(.segmented)
                
                Text("Note: Current API accepts only 'auto'. Other options are future-facing.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Preload File IDs (comma-separated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("file_123, file_456", text: $viewModel.activePrompt.codeInterpreterPreloadFileIds.bound)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                Text("Files to make available in the interpreter environment")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// File Search configuration
    private var fileSearchConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            fileSearchVectorStoreField
            fileSearchAdvancedOptions
            fileSearchOpenManagerButton
        }
    }
    
    // MARK: - File Search Configuration Components
    
    private var fileSearchVectorStoreField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vector Store IDs (comma-separated)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("vs_123, vs_456", text: $viewModel.activePrompt.selectedVectorStoreIds.bound)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
    }
    
    private var fileSearchAdvancedOptions: some View {
        DisclosureGroup("Advanced Search Options") {
            Text("Max Results: \(viewModel.activePrompt.fileSearchMaxResults.map { "\($0)" } ?? "10")")
                .font(.caption)
            
            Slider(
                value: Binding(
                    get: { Double(viewModel.activePrompt.fileSearchMaxResults ?? 10) },
                    set: { viewModel.activePrompt.fileSearchMaxResults = Int($0) }
                ),
                in: 1...50,
                step: 1
            )
            
            Text("Ranking: \(viewModel.activePrompt.fileSearchRanker ?? "Auto")")
                .font(.caption)
                .padding(.top, 8)
            
            Picker("Ranker", selection: $viewModel.activePrompt.fileSearchRanker.bound) {
                Text("Auto").tag(Optional<String>.none)
                Text("Auto (Explicit)").tag(Optional("auto"))
                Text("Default 2024-08-21").tag(Optional("default-2024-08-21"))
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var fileSearchMaxResultsControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Max Results")
                    .font(.caption)
                Spacer()
                Text(viewModel.activePrompt.fileSearchMaxResults.map { "\($0)" } ?? "Default (10)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("Clear") {
                    viewModel.activePrompt.fileSearchMaxResults = nil
                    viewModel.saveActivePrompt()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.activePrompt.fileSearchMaxResults ?? 10) },
                        set: { viewModel.activePrompt.fileSearchMaxResults = Int($0) }
                    ),
                    in: 1...50,
                    step: 1
                )
                .onChange(of: viewModel.activePrompt.fileSearchMaxResults) { _, _ in
                    viewModel.saveActivePrompt()
                }
            }
            
            Text("Controls how many result chunks are returned (1-50). Lower values save tokens, higher values provide more context.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var fileSearchOpenManagerButton: some View {
        Button(action: { showingFileManager = true }) {
            Label("Open File Manager", systemImage: "folder.fill")
                .font(.subheadline)
                .foregroundColor(.indigo)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    /// Custom Tool configuration
    private var customToolConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Function Name", text: $viewModel.activePrompt.customToolName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            TextField("Description", text: $viewModel.activePrompt.customToolDescription)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Execution Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Execution Type", selection: $viewModel.activePrompt.customToolExecutionType) {
                    Text("Echo").tag("echo")
                    Text("Calculator").tag("calculator")
                    Text("Webhook").tag("webhook")
                }
                .pickerStyle(.segmented)
            }
            
            if viewModel.activePrompt.customToolExecutionType == "webhook" {
                TextField("Webhook URL", text: $viewModel.activePrompt.customToolWebhookURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Parameters JSON Schema")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.activePrompt.customToolParametersJSON)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            }
        }
    }
    
    @ViewBuilder
    private var advancedSettingsSection: some View {
        Group {
            Section(header: Text("Advanced API Parameters"), footer: Text("Fine-grained control over model behavior and API features.")) {
                Toggle("Background Mode", isOn: $viewModel.activePrompt.backgroundMode)

                // Allow models to call multiple tools in parallel when supported
                HStack {
                    Toggle("Parallel tool calls", isOn: $viewModel.activePrompt.parallelToolCalls)
                        .disabled(!ModelCompatibilityService.shared.isParameterSupported("parallel_tool_calls", for: viewModel.activePrompt.openAIModel))
                    if !ModelCompatibilityService.shared.isParameterSupported("parallel_tool_calls", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Top P: \(String(format: "%.2f", viewModel.activePrompt.topP))")
                        if !ModelCompatibilityService.shared.isParameterSupported("top_p", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .help("Not supported by current model")
                        }
                    }
                    Slider(value: $viewModel.activePrompt.topP, in: 0...1, step: 0.01)
                        .disabled(!ModelCompatibilityService.shared.isParameterSupported("top_p", for: viewModel.activePrompt.openAIModel))
                    Text("Nucleus sampling - higher values increase randomness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("Required").tag("required") 
                    Text("None").tag("none")
                }
                .pickerStyle(.segmented)
                
                Picker("Truncation Strategy", selection: $viewModel.activePrompt.truncationStrategy) {
                    Text("Disabled").tag("disabled")
                    Text("Auto").tag("auto")
                }
                .pickerStyle(.segmented)
                
                Picker("Service Tier", selection: $viewModel.activePrompt.serviceTier) {
                    Text("Auto").tag("auto")
                    Text("Default").tag("default")
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Stepper("Top Logprobs: \(viewModel.activePrompt.topLogprobs)", value: $viewModel.activePrompt.topLogprobs, in: 0...20)
                        .disabled(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true)
                    if ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by reasoning models")
                    }
                }
                
                Stepper("Max Tool Calls: \(viewModel.activePrompt.maxToolCalls == 0 ? "Unlimited" : String(viewModel.activePrompt.maxToolCalls))", value: $viewModel.activePrompt.maxToolCalls, in: 0...50)
                
                TextField("User Identifier (optional)", text: $viewModel.activePrompt.userIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metadata (JSON)")
                    TextEditor(text: $viewModel.activePrompt.metadata.bound)
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    Text("Custom metadata as JSON object")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Structured Output"), footer: Text("Force the model to respond with structured JSON according to a schema.")) {
                Picker("Text Format", selection: $viewModel.activePrompt.textFormatType) {
                    Text("Text").tag("text")
                    Text("JSON Schema").tag("json_schema")
                }
                .pickerStyle(.segmented)
                
                if viewModel.activePrompt.textFormatType == "json_schema" {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Schema Name", text: $viewModel.activePrompt.jsonSchemaName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        TextField("Schema Description (optional)", text: $viewModel.activePrompt.jsonSchemaDescription)
                            .textFieldStyle(.roundedBorder)
                        
                        Toggle("Strict Mode", isOn: $viewModel.activePrompt.jsonSchemaStrict)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("JSON Schema")
                            TextEditor(text: $viewModel.activePrompt.jsonSchemaContent)
                                .frame(minHeight: 120)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                            Text("Define the structure of the expected JSON response")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response for debugging and advanced use cases.")) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Include Code Interpreter Outputs", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                    Text("Not currently returned by the API; kept for future compatibility.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Toggle("Include Computer Use Output", isOn: $viewModel.activePrompt.includeComputerUseOutput)  
                Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
                HStack {
                    Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                        .disabled(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true)
                    if ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by reasoning models")
                    }
                }
                HStack {
                    Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                        .disabled(!(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true))
                    if !(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Only supported on reasoning-capable models (e.g., o-series)")
                    }
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Web Search Location"), footer: Text("Customize location-based search results. Leave blank for automatic detection.")) {
                TextField("City", text: $viewModel.activePrompt.userLocationCity.bound)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Country", text: $viewModel.activePrompt.userLocationCountry.bound)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Region/State", text: $viewModel.activePrompt.userLocationRegion.bound)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Timezone", text: $viewModel.activePrompt.userLocationTimezone.bound)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                HStack {
                    Button("Auto-fill Timezone") {
                        viewModel.activePrompt.userLocationTimezone = TimeZone.current.identifier
                    }
                    .foregroundColor(.accentColor)
                    Spacer()
                    if let timezone = viewModel.activePrompt.userLocationTimezone, !timezone.isEmpty {
                        Text("Current: \(timezone)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
        }
    }
    
    /// Advanced configuration card with comprehensive API parameters
    private var advancedConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            advancedParametersSection
            structuredOutputSection
            responseIncludesSection
            webSearchLocationSection
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
    }
    
    // MARK: - Advanced Configuration Components
    
    private var advancedParametersSection: some View {
        Section(header: Text("Advanced Parameters").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("Required").tag("required") 
                    Text("None").tag("none")
                }
                .pickerStyle(.segmented)
                
                Picker("Truncation Strategy", selection: $viewModel.activePrompt.truncationStrategy) {
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
            
            advancedParametersSteppers
            advancedParametersMetadata
        }
    }
    
    private var advancedParametersSteppers: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Stepper("Top Logprobs: \(viewModel.activePrompt.topLogprobs)", value: $viewModel.activePrompt.topLogprobs, in: 0...20)
                    .disabled(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true)
                advancedParametersReasoningIcon
            }
            
            Stepper("Max Tool Calls: \(viewModel.activePrompt.maxToolCalls == 0 ? "Unlimited" : String(viewModel.activePrompt.maxToolCalls))", value: $viewModel.activePrompt.maxToolCalls, in: 0...50)
            
            TextField("User Identifier (optional)", text: $viewModel.activePrompt.userIdentifier)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
    }
    
    @ViewBuilder
    private var advancedParametersReasoningIcon: some View {
        if ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .help("Not supported by reasoning models")
        }
    }
    
    private var advancedParametersMetadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Metadata (JSON)")
            TextEditor(text: $viewModel.activePrompt.metadata.bound)
                .frame(minHeight: 60)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            Text("Custom metadata as JSON object")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var structuredOutputSection: some View {
        Section(header: Text("Structured Output").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Text Format", selection: $viewModel.activePrompt.textFormatType) {
                    Text("Text").tag("text")
                    Text("JSON Schema").tag("json_schema")
                }
                .pickerStyle(.segmented)
                
                structuredOutputJsonSchemaSection
            }
        }
    }
    
    @ViewBuilder
    private var structuredOutputJsonSchemaSection: some View {
        if viewModel.activePrompt.textFormatType == "json_schema" {
            jsonSchemaFields
        }
    }
    
    private var jsonSchemaFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Schema Name", text: $viewModel.activePrompt.jsonSchemaName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            TextField("Schema Description (optional)", text: $viewModel.activePrompt.jsonSchemaDescription)
                .textFieldStyle(.roundedBorder)
            
            Toggle("Strict Mode", isOn: $viewModel.activePrompt.jsonSchemaStrict)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("JSON Schema")
                TextEditor(text: $viewModel.activePrompt.jsonSchemaContent)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                Text("Define the structure of the expected JSON response")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
    
    private var responseIncludesSection: some View {
        Section(header: Text("Response Includes").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select which extra data to include in API responses")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                responseIncludesToggles
            }
        }
    }
    
    private var responseIncludesToggles: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Include Code Interpreter Outputs", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                Text("Not currently returned by the API; kept for future compatibility.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Toggle("Include Computer Use Output", isOn: $viewModel.activePrompt.includeComputerUseOutput)  
            Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
            Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
            Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
            
            responseIncludesOutputLogprobs
            responseIncludesReasoningContent
        }
    }
    
    @ViewBuilder
    private var responseIncludesOutputLogprobs: some View {
        HStack {
            Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                .disabled(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true)
            if ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .help("Not supported by reasoning models")
            }
        }
    }
    
    @ViewBuilder
    private var responseIncludesReasoningContent: some View {
        HStack {
            Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                .disabled(!(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true))
            if !(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .help("Only supported on reasoning-capable models (e.g., o-series)")
            }
        }
    }
    
    private var webSearchLocationSection: some View {
        Section(header: Text("Web Search Location").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Customize location-based search results")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                webSearchLocationFields
            }
        }
    }
    
    private var webSearchLocationFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("City", text: $viewModel.activePrompt.userLocationCity.bound)
                .textFieldStyle(.roundedBorder)
            
            TextField("Country", text: $viewModel.activePrompt.userLocationCountry.bound)
                .textFieldStyle(.roundedBorder)
            
            TextField("Region/State", text: $viewModel.activePrompt.userLocationRegion.bound)
                .textFieldStyle(.roundedBorder)
            
            TextField("Timezone", text: $viewModel.activePrompt.userLocationTimezone.bound)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            HStack {
                Button("Auto-fill Timezone") {
                    viewModel.activePrompt.userLocationTimezone = TimeZone.current.identifier
                }
                .foregroundColor(.accentColor)
                
                Spacer()
                
                webSearchLocationCurrentTimezone
            }
        }
    }
    
    @ViewBuilder
    private var webSearchLocationCurrentTimezone: some View {
        if let timezone = viewModel.activePrompt.userLocationTimezone, !timezone.isEmpty {
            Text("Current: \(timezone)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// Debug configuration card with developer tools
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Section(header: Text("Debug Tools").font(.headline)) {
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { showingAPIInspector = true }) {
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                Text("API Inspector")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(CardButtonStyle(color: .blue))
                    }
                    
                    HStack {
                        Button(action: { showingDebugConsole = true }) {
                            HStack {
                                Image(systemName: "terminal")
                                    .foregroundColor(.green)
                                Text("Debug Console")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(CardButtonStyle(color: .green))
                    }
                }
            }
            
            Section(header: Text("Advanced Options").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Ultra-strict Computer Use", isOn: $viewModel.activePrompt.ultraStrictComputerUse)
                    Text("When enabled, the assistant executes only the model's actions. No pre-navigation, search overrides, or click-by-text.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Minimize API Log Bodies", isOn: Binding(
                        get: { AppLogger.minimizeOpenAILogBodies },
                        set: { newValue in
                            AppLogger.minimizeOpenAILogBodies = newValue
                            UserDefaults.standard.set(newValue, forKey: "minimizeOpenAILogBodies")
                        }
                    ))
                    Text("When enabled, request and response bodies are omitted from logs to reduce noise.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Reset Actions").font(.headline)) {
                VStack(spacing: 12) {
                    Button("Reset Onboarding") {
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    }
                    .buttonStyle(ActionButtonStyle(color: .blue))
                    
                    Button("Reset All Settings") {
                        viewModel.resetToDefaultPrompt()
                    }
                    .buttonStyle(ActionButtonStyle(color: .orange))
                    
                    Button("Clear Conversation") {
                        viewModel.clearConversation()
                    }
                    .buttonStyle(ActionButtonStyle(color: .red, isDestructive: true))
                }
            }
        }
    }
    
    @ViewBuilder
    private var debugSection: some View {
        Group {
            Section(header: Text("Debugging")) {
                Button("API Inspector") { showingAPIInspector = true }
                Button("Debug Console") { showingDebugConsole = true }
                
                Button("Reset Onboarding") {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }
                .foregroundColor(.blue)
                
                Button("Reset All Settings") {
                    viewModel.resetToDefaultPrompt()
                }
                .foregroundColor(.orange)
            }
            
            Section {
                Toggle("Ultra-strict computer use (no helpers)", isOn: $viewModel.activePrompt.ultraStrictComputerUse)
                    .accessibilityLabel("Ultra-strict computer use")
                    .accessibilityHint("When enabled, the assistant executes only the model's actions. No pre-navigation, search overrides, or click-by-text.")
                Toggle("Minimize API Log Bodies", isOn: Binding(
                    get: { AppLogger.minimizeOpenAILogBodies },
                    set: { newValue in
                        AppLogger.minimizeOpenAILogBodies = newValue
                        UserDefaults.standard.set(newValue, forKey: "minimizeOpenAILogBodies")
                    }
                ))
                .accessibilityLabel("Minimize API Log Bodies")
                .accessibilityHint("When enabled, request and response bodies are omitted from logs to reduce noise.")
                Button(role: .destructive) {
                    viewModel.clearConversation()
                } label: {
                    Text("Clear Conversation")
                }
            }
        }
    }
    
    }

// MARK: - Custom Button Styles

/// Modern card-style button with hover effects
struct CardButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Enhanced action button with modern styling
struct ActionButtonStyle: ButtonStyle {
    let color: Color
    let isDestructive: Bool
    
    init(color: Color = .blue, isDestructive: Bool = false) {
        self.color = color
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDestructive ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Supporting Types

enum SettingsSection: String, CaseIterable {
    case essentials = "Essentials"
    case model = "Model"
    case tools = "Tools"
    case advanced = "Advanced"
    case debug = "Debug"
}

enum ValidationStatus {
    case unknown, validating, valid, invalid
    
    var color: Color {
        switch self {
        case .unknown: return .secondary
        case .validating: return .orange
        case .valid: return .green
        case .invalid: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "key"
        case .validating: return "hourglass"
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        }
    }
}

/// Search bar for filtering settings
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search settings...", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        isSearchFieldFocused = false
                    }
                    .onChange(of: searchText) { _, newValue in
                        isSearching = !newValue.isEmpty
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchFieldFocused = false
                        isSearching = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSearchFieldFocused ? .blue : .clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
        }
        .padding(.horizontal)
    }
}

/// Text view that highlights search matches
struct HighlightedText: View {
    let text: String
    let searchText: String
    
    var body: some View {
        if searchText.isEmpty {
            Text(text)
        } else {
            let searchRanges = findRanges(of: searchText, in: text)
            
            if searchRanges.isEmpty {
                Text(text)
            } else {
                buildAttributedText()
            }
        }
    }
    
    private func findRanges(of searchText: String, in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: searchText, options: [.caseInsensitive], range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<text.endIndex
        }
        
        return ranges
    }
    
    private func buildAttributedText() -> some View {
        let ranges = findRanges(of: searchText, in: text)
        let segments = buildTextSegments(from: text, ranges: ranges)
        
        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Text(segment.text)
                    .foregroundColor(segment.isHighlighted ? .white : .primary)
                    .background(segment.isHighlighted ? .blue : .clear)
            }
        }
    }
    
    private struct TextSegment {
        let text: String
        let isHighlighted: Bool
    }
    
    private func buildTextSegments(from text: String, ranges: [Range<String.Index>]) -> [TextSegment] {
        var segments: [TextSegment] = []
        var currentIndex = text.startIndex
        
        for range in ranges {
            // Add text before the match
            if currentIndex < range.lowerBound {
                segments.append(TextSegment(text: String(text[currentIndex..<range.lowerBound]), isHighlighted: false))
            }
            
            // Add highlighted match
            segments.append(TextSegment(text: String(text[range]), isHighlighted: true))
            currentIndex = range.upperBound
        }
        
        // Add remaining text
        if currentIndex < text.endIndex {
            segments.append(TextSegment(text: String(text[currentIndex..<text.endIndex]), isHighlighted: false))
        }
        
        return segments
    }
}

/// Usage analytics dashboard card
struct UsageAnalyticsCard: View {
    @AppStorage("totalAPIRequests") private var totalRequests: Int = 0
    @AppStorage("totalTokensUsed") private var totalTokens: Int = 0
    @AppStorage("lastAPICallTime") private var lastCallTime: Double = 0
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { 
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 30)
                    
                    Text("Usage Analytics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Quick stats
                    if !isExpanded {
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(totalRequests)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                Text("Requests")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(formatTokens(totalTokens))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                Text("Tokens")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
                .padding()
                .background(.green.opacity(0.05))
            }
            .buttonStyle(.plain)
            
            // Detailed content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Statistics grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(
                            title: "Total Requests",
                            value: "\(totalRequests)",
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Total Tokens",
                            value: formatTokens(totalTokens),
                            icon: "textformat",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Last API Call",
                            value: lastCallTime > 0 ? formatTimeAgo(Date(timeIntervalSince1970: lastCallTime)) : "Never",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    
                    // Quick actions
                    HStack {
                        Button("Reset Statistics") {
                            totalRequests = 0
                            totalTokens = 0
                            lastCallTime = 0
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1), in: Capsule())
                        
                        Spacer()
                        
                        Text("Session stats • Updates automatically")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95))
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: isExpanded)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1000 {
            return String(format: "%.1fK", Double(tokens) / 1000)
        } else {
            return "\(tokens)"
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

/// Small stat card for analytics
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Quick presets selection view
struct QuickPresetsView: View {
    let onPresetSelected: (Prompt) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let presetTemplates: [PresetTemplate] = [
        PresetTemplate(
            name: "Creative Writing",
            description: "Optimized for creative content, stories, and imaginative tasks",
            icon: "pencil.and.scribble",
            color: .purple,
            settings: { prompt in
                prompt.temperature = 0.9
                prompt.topP = 0.9
                prompt.enableStreaming = true
                prompt.openAIModel = "gpt-4o"
                prompt.systemInstructions = "You are a creative writing assistant. Help with storytelling, character development, and imaginative content. Be creative, engaging, and supportive of artistic expression."
            }
        ),
        PresetTemplate(
            name: "Code Review",
            description: "Structured for code analysis, debugging, and technical reviews",
            icon: "chevron.left.forwardslash.chevron.right",
            color: .blue,
            settings: { prompt in
                prompt.temperature = 0.2
                prompt.topP = 0.1
                prompt.enableStreaming = true
                prompt.openAIModel = "gpt-4o"
                prompt.enableCodeInterpreter = true
                prompt.systemInstructions = "You are a senior software engineer conducting code reviews. Provide detailed, constructive feedback on code quality, performance, security, and best practices."
            }
        ),
        PresetTemplate(
            name: "Data Analysis",
            description: "Configured for data processing, statistics, and analytical tasks",
            icon: "chart.bar.xaxis",
            color: .green,
            settings: { prompt in
                prompt.temperature = 0.3
                prompt.topP = 0.3
                prompt.enableStreaming = true
                prompt.openAIModel = "gpt-4o"
                prompt.enableCodeInterpreter = true
                prompt.enableFileSearch = true
                prompt.systemInstructions = "You are a data analyst. Help with data interpretation, statistical analysis, visualization suggestions, and insights discovery."
            }
        ),
        PresetTemplate(
            name: "Research Assistant",
            description: "Optimized for research, fact-checking, and information gathering",
            icon: "magnifyingglass.circle",
            color: .teal,
            settings: { prompt in
                prompt.temperature = 0.4
                prompt.topP = 0.4
                prompt.enableStreaming = true
                prompt.openAIModel = "gpt-4o"
                prompt.enableWebSearch = true
                prompt.systemInstructions = "You are a research assistant. Help with finding accurate information, fact-checking, summarizing sources, and providing well-researched insights."
            }
        ),
        PresetTemplate(
            name: "Computer Use",
            description: "Configured for computer interaction and automation tasks",
            icon: "desktopcomputer",
            color: .red,
            settings: { prompt in
                prompt.temperature = 0.1
                prompt.topP = 0.1
                prompt.enableStreaming = true
                prompt.openAIModel = "computer-use-preview"
                prompt.enableComputerUse = true
                prompt.systemInstructions = "You are a computer use assistant. Help with automating tasks, navigating interfaces, and interacting with applications efficiently and safely."
            }
        ),
        PresetTemplate(
            name: "Balanced Assistant",
            description: "Well-rounded settings for general-purpose conversations",
            icon: "scale.3d",
            color: .indigo,
            settings: { prompt in
                prompt.temperature = 0.7
                prompt.topP = 0.8
                prompt.enableStreaming = true
                prompt.openAIModel = "gpt-4o"
                prompt.systemInstructions = "You are a helpful, knowledgeable, and balanced AI assistant. Provide accurate, thoughtful responses while being conversational and engaging."
            }
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose a template optimized for your specific use case")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Preset cards
                    ForEach(presetTemplates, id: \.name) { template in
                        PresetTemplateCard(template: template) {
                            var prompt = Prompt.defaultPrompt()
                            template.settings(&prompt)
                            onPresetSelected(prompt)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PresetTemplate {
    let name: String
    let description: String
    let icon: String
    let color: Color
    let settings: (inout Prompt) -> Void
}

struct PresetTemplateCard: View {
    let template: PresetTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(template.color)
                    .frame(width: 40, height: 40)
                    .background(template.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(template.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(CardButtonStyle(color: template.color))
    }
}

/// Help button with tooltip
struct HelpButton: View {
    let text: String
    @State private var showingHelp = false
    
    var body: some View {
        Button(action: { showingHelp = true }) {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingHelp, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: 250)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Modern UI Components

/// Modern header with gradient background
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Configure your AI assistant")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.9))
                    .symbolEffect(.pulse)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

/// Quick actions toolbar
struct QuickActionsBar: View {
    @Binding var showingFileManager: Bool
    @Binding var showingPromptLibrary: Bool
    @Binding var showingAPIInspector: Bool
    @Binding var showingQuickPresets: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "folder.fill",
                    title: "Files",
                    color: .orange,
                    action: { showingFileManager = true }
                )
                
                QuickActionButton(
                    icon: "book.fill",
                    title: "Library",
                    color: .green,
                    action: { showingPromptLibrary = true }
                )
                
                QuickActionButton(
                    icon: "wand.and.stars",
                    title: "Presets",
                    color: .purple,
                    action: { showingQuickPresets = true }
                )
                
                QuickActionButton(
                    icon: "network",
                    title: "Inspector",
                    color: .blue,
                    action: { showingAPIInspector = true }
                )
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, height: 50)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(CardButtonStyle(color: color))
        .hoverEffect(.highlight)
    }
}

/// Modern card container
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    @State private var isExpanded = true
    
    init(
        title: String,
        icon: String,
        color: Color = .blue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { 
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 30)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
                .padding()
                .background(color.opacity(0.05))
            }
            .buttonStyle(.plain)
            
            // Content
            if isExpanded {
                content
                    .padding()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

/// Advanced settings toggle
struct AdvancedToggleButton: View {
    @Binding var showingAdvanced: Bool
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring()) {
                showingAdvanced.toggle()
            }
        }) {
            HStack {
                Image(systemName: showingAdvanced ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(showingAdvanced ? "Hide Advanced Settings" : "Show Advanced Settings")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setup and Event Handlers

extension SettingsView {
    private func setupOnAppear() {
        promptLibrary.reload()
        let activeId = viewModel.activePrompt.id
        if promptLibrary.prompts.contains(where: { $0.id == activeId }) {
            selectedPresetId = activeId
        } else {
            selectedPresetId = nil
        }
        apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
        validateAPIKey()
    }
    
    private func validatePresetSelection(with prompts: [Prompt]) {
        if let sel = selectedPresetId, prompts.contains(where: { $0.id == sel }) == false {
            selectedPresetId = nil
        }
    }
    
    private func handleActivePromptChange(_ newPrompt: Prompt) {
        if promptLibrary.prompts.first(where: { $0.id == newPrompt.id }) == nil {
            selectedPresetId = nil
        }
    }
    
    private func handleAPIKeyChange(_ newValue: String) {
        KeychainService.shared.save(value: newValue, forKey: "openAIKey")
        validateAPIKey()
    }
    
    private func validateAPIKey() {
        guard !apiKey.isEmpty else {
            keyValidationStatus = .unknown
            return
        }
        
        keyValidationStatus = apiKey.hasPrefix("sk-") ? .valid : .invalid
    }
    
    private func applyPreset(_ preset: Prompt) {
        viewModel.activePrompt = preset
    }
}

// MARK: - Tool Toggle Card

/// Expandable card for tool configuration with toggle
struct ToolToggleCard<Content: View>: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isEnabled: Bool
    let isSupported: Bool
    let isDisabled: Bool
    let content: Content
    
    @State private var isExpanded = false
    
    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isEnabled: Binding<Bool>,
        isSupported: Bool,
        isDisabled: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self._isEnabled = isEnabled
        self.isSupported = isSupported
        self.isDisabled = isDisabled
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main toggle row
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? color : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isSupported {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                Toggle("", isOn: $isEnabled)
                    .disabled(!isSupported || isDisabled)
                    .tint(color)
                    .onChange(of: isEnabled) { _, newValue in
                        if newValue {
                            withAnimation(.spring()) {
                                isExpanded = true
                            }
                        }
                    }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEnabled && isSupported && !isDisabled {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
            }
            
            // Expandable configuration content
            if isEnabled && isExpanded {
                Divider()
                    .padding(.horizontal, -16)
                
                content
                    .padding(.top, 12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? color.opacity(0.05) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isEnabled ? color.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Helper to bind optional strings in TextFields  
extension Optional where Wrapped == String {
    func orEmpty() -> String {
        return self ?? ""
    }
    
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
