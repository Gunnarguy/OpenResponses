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
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false
    @State private var showingAPIInspector = false
    @State private var showingDebugConsole = false
    @State private var selectedPresetId: UUID?
    
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
    
    private func shouldShowCard(_ cardTitle: String, searchTerms: [String] = []) -> Bool {
        guard isSearching && !searchText.isEmpty else { return true }
        
        let searchLower = searchText.lowercased()
        let titleLower = cardTitle.lowercased()
        
        // Check main title
        if titleLower.contains(searchLower) { return true }
        
        // Check additional search terms for this card
        for term in searchTerms {
            if term.lowercased().contains(searchLower) { return true }
        }
        
        return false
    }
    
    private var hasVisibleCards: Bool {
        guard isSearching && !searchText.isEmpty else { return true }
        
        return shouldShowCard("Presets", searchTerms: ["prompt", "template", "library"]) ||
               shouldShowCard("API Configuration", searchTerms: ["key", "openai", "authentication"]) ||
               shouldShowCard("Model Selection", searchTerms: ["gpt", "claude", "model", "compatibility", "temperature", "reasoning", "parameters"]) ||
               shouldShowCard("Tools", searchTerms: ["file", "search", "computer", "code", "interpreter"]) ||
               (showingAdvanced && (
                   shouldShowCard("Advanced Configuration", searchTerms: ["parameters", "tokens", "json", "schema", "truncation", "tool choice"]) ||
                   shouldShowCard("Developer Tools", searchTerms: ["debug", "console", "reset", "logs"])
               ))
    }
    
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
                        if shouldShowCard("Presets", searchTerms: ["prompt", "template", "library"]) {
                            presetCard
                        }
                        
                        if shouldShowCard("API Configuration", searchTerms: ["key", "openai", "authentication"]) {
                            apiConfigurationCard
                        }
                        
                        if shouldShowCard("Model Selection", searchTerms: ["gpt", "claude", "model", "compatibility", "temperature", "reasoning", "parameters"]) {
                            modelConfigurationCard
                        }
                        
                        if shouldShowCard("Tools", searchTerms: ["file", "search", "computer", "code", "interpreter"]) {
                            toolsCard
                        }
                        
                        if showingAdvanced {
                            if shouldShowCard("Advanced Configuration", searchTerms: ["parameters", "tokens", "json", "schema", "truncation", "tool choice"]) {
                                // Advanced Settings Card
                                SettingsCard(
                                    title: "Advanced Configuration", 
                                    icon: "slider.horizontal.3",
                                    color: .purple
                                ) {
                                    advancedConfigurationCard
                                }
                            }
                            
                            if shouldShowCard("Developer Tools", searchTerms: ["debug", "console", "reset", "logs"]) {
                                // Debug Card
                                SettingsCard(
                                    title: "Developer Tools",
                                    icon: "hammer.fill",
                                    color: .red
                                ) {
                                    debugCard
                                }
                            }
                        }
                        
                        // Show message if no results found
                        if isSearching && !searchText.isEmpty && !hasVisibleCards {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No settings found")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Try searching for 'API', 'model', 'tools', or 'advanced'")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
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
    }
}

/// Tool toggle card with expandable configuration
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
                        .stroke(isEnabled ? color.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Card Content Views

extension SettingsView {
    
    /// Modern preset selection card
    private var presetCard: some View {
        SettingsCard(title: "Preset Library", icon: "book.fill", color: .green) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Load saved configurations or create new presets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Load Preset", selection: $selectedPresetId) {
                    Text("Current Settings").tag(nil as UUID?)
                        .foregroundColor(.primary)
                    
                    if !promptLibrary.prompts.isEmpty {
                        Divider()
                        ForEach(promptLibrary.prompts) { prompt in
                            Label(prompt.name, systemImage: "bookmark.fill")
                                .tag(prompt.id as UUID?)
                        }
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPresetId) { _, newValue in
                    if let preset = promptLibrary.prompts.first(where: { $0.id == newValue }) {
                        applyPreset(preset)
                    }
                }
                
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
        }
    }
    
    /// Enhanced API configuration card
    private var apiConfigurationCard: some View {
        SettingsCard(title: "API Configuration", icon: "key.fill", color: .blue) {
            VStack(alignment: .leading, spacing: 16) {
                // API Key Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("OpenAI API Key")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HelpButton(text: "Enter your OpenAI API key (starts with 'sk-'). You can find this in your OpenAI dashboard under API Keys. Keep it secure and never share it publicly.")
                        
                        Spacer()
                        
                        Image(systemName: keyValidationStatus.icon)
                            .foregroundColor(keyValidationStatus.color)
                            .font(.caption)
                            .rotationEffect(.degrees(keyValidationStatus == .validating ? 360 : 0))
                            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: keyValidationStatus == .validating)
                            .symbolEffect(.pulse, isActive: keyValidationStatus == .validating)
                    }
                    
                    HStack {
                        SecureField("Enter your API key (sk-...)", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        if !apiKey.isEmpty {
                            Button(action: { apiKey = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if keyValidationStatus == .invalid {
                        Text("API key should start with 'sk-'")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                // Published Prompt Section
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
                    
                    if viewModel.activePrompt.enablePublishedPrompt {
                        TextField("Published Prompt ID", text: $viewModel.activePrompt.publishedPromptId)
                            .textFieldStyle(.roundedBorder)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    /// Modern model configuration card
    private var modelConfigurationCard: some View {
        SettingsCard(title: "Model Configuration", icon: "cpu.fill", color: .purple) {
            VStack(alignment: .leading, spacing: 20) {
                // Model Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Model")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DynamicModelSelector(
                        selectedModel: $viewModel.activePrompt.openAIModel,
                        openAIService: AppContainer.shared.openAIService
                    )
                    .onChange(of: viewModel.activePrompt.openAIModel) { _, newModel in
                        // Auto-enable computer use for computer-use-preview model
                        if newModel == "computer-use-preview" {
                            viewModel.activePrompt.enableComputerUse = true
                        }
                        viewModel.saveActivePrompt()
                    }
                    
                    // Model info and reset
                    HStack {
                        Text("Current: \(viewModel.activePrompt.openAIModel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Reset to Default") {
                            viewModel.activePrompt.openAIModel = "gpt-4o"
                            // Disable computer use for non-computer models
                            viewModel.activePrompt.enableComputerUse = false
                            viewModel.saveActivePrompt()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
                
                Divider()
                
                // System Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Instructions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Guide the assistant's behavior and personality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.activePrompt.systemInstructions)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                    
                    if viewModel.activePrompt.systemInstructions.isEmpty {
                        Text("e.g., 'You are a helpful and knowledgeable assistant.'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Developer Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Developer Instructions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Hidden instructions with higher priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.activePrompt.developerInstructions)
                        .frame(minHeight: 60)
                        .padding(.horizontal, 8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                }
                
                Divider()
                
                // Model Parameters
                modelParametersSection
                
                // Response Settings
                responseSettingsSection
            }
        }
    }
    
    /// Model parameters section - groups temperature, reasoning, and other model-specific settings
    private var modelParametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Parameters")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Temperature (for compatible models) - moved here from Advanced Configuration
            if ModelCompatibilityService.shared.isParameterSupported("temperature", for: viewModel.activePrompt.openAIModel) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(viewModel.activePrompt.temperature, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $viewModel.activePrompt.temperature, in: 0...2, step: 0.01)
                        .tint(.purple)
                        .disabled(viewModel.activePrompt.enablePublishedPrompt)
                    
                    Text("Controls creativity vs. focus (0.0-2.0)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Quick preset buttons for common temperature values
                    HStack(spacing: 8) {
                        Button("Focused (0.2)") {
                            viewModel.activePrompt.temperature = 0.2
                            viewModel.saveActivePrompt()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.blue)
                        
                        Button("Balanced (0.7)") {
                            viewModel.activePrompt.temperature = 0.7
                            viewModel.saveActivePrompt()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.green)
                        
                        Button("Creative (1.2)") {
                            viewModel.activePrompt.temperature = 1.2
                            viewModel.saveActivePrompt()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.orange)
                    }
                    .font(.caption2)
                }
            }
            
            // Reasoning Effort (for compatible models) - grouped with temperature
            if ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reasoning Effort")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    
                    Picker("Reasoning Effort", selection: $viewModel.activePrompt.reasoningEffort) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.activePrompt.enablePublishedPrompt)
                    
                    Text("How much the model should think before responding")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !viewModel.activePrompt.reasoningSummary.isEmpty || ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reasoning Summary")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Optional reasoning approach guide", text: $viewModel.activePrompt.reasoningSummary)
                            .textFieldStyle(.roundedBorder)
                            .disabled(viewModel.activePrompt.enablePublishedPrompt)
                        
                        Text("Guide how the model should approach complex problems")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Top P - another core model parameter that belongs with temp/reasoning
            if ModelCompatibilityService.shared.isParameterSupported("top_p", for: viewModel.activePrompt.openAIModel) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Top P (Nucleus Sampling)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(viewModel.activePrompt.topP, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $viewModel.activePrompt.topP, in: 0...1, step: 0.01)
                        .tint(.purple)
                        .disabled(viewModel.activePrompt.enablePublishedPrompt)
                    
                    Text("Alternative to temperature - controls token selection diversity")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Response settings section
    private var responseSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Toggle(isOn: $viewModel.activePrompt.enableStreaming) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Streaming")
                        .font(.subheadline)
                    
                    Text("Real-time response generation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.purple)
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Output Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(viewModel.activePrompt.maxOutputTokens)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Stepper("", value: $viewModel.activePrompt.maxOutputTokens, in: 0...32768, step: 64)
                    .labelsHidden()
                    .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
        }
    }
    
    
    /// Modern tools configuration card
    private var toolsCard: some View {
        SettingsCard(title: "AI Tools & Capabilities", icon: "wrench.and.screwdriver.fill", color: .orange) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enable powerful AI tools for enhanced capabilities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Vector Store IDs (comma-separated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("vs_123, vs_456", text: $viewModel.activePrompt.selectedVectorStoreIds.bound)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            
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
                
                VStack(alignment: .leading, spacing: 8) {
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
                }
                
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
            
            Section(header: Text("Structured Output").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
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
            }
            
            Section(header: Text("Response Includes").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select which extra data to include in API responses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
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
            }
            
            Section(header: Text("Web Search Location").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Customize location-based search results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
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
            }
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
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
