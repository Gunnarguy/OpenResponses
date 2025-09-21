import SwiftUI
import Combine
// CoreLocation removed – no longer using device location here

/// Settings view for configuring the OpenAI API integration and tools.
/// 
/// Features:
/// - API key configuration
/// - Model selection (supports O-series reasoning models and standard GPT models)
/// - Tool toggles for Web Search, Code Interpreter, and Image Generation
/// - Temperature setting for non-reasoning models
/// - Reasoning effort setting for O-series models
struct SettingsView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false
    @State private var showingAPIInspector = false
    @State private var showingDebugConsole = false
    @State private var selectedPresetId: UUID?
    
    @StateObject private var promptLibrary = PromptLibrary()
    // UI state for collapsing tool groups
    @State private var showCoreTools: Bool = true
    @State private var showCustomTools: Bool = false
    // Location autofill removed (kept only timezone autofill)

    // LocationHelper removed. We only support timezone autofill now.

    // All @AppStorage properties are removed. The view will now bind directly to viewModel.activePrompt.

    private var isImageGenerationSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(.imageGeneration, for: viewModel.activePrompt.openAIModel, isStreaming: viewModel.activePrompt.enableStreaming)
    }
    
    var body: some View {
        Form {
            presetSection
            apiSection
            publishedPromptSection
            systemInstructionsSection
            developerInstructionsSection
            modelSection
            responseSettingsSection
            toolsSection
            advancedSettingsSection
            debugSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            promptLibrary.reload()
            // Only select a preset if the active prompt exists in the library; otherwise nil to avoid invalid Picker selection
            let activeId = viewModel.activePrompt.id
            if promptLibrary.prompts.contains(where: { $0.id == activeId }) {
                selectedPresetId = activeId
            } else {
                selectedPresetId = nil
            }
            apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
        }
        // If the library changes (add/remove), keep the Picker selection valid
        .onChange(of: promptLibrary.prompts) { _, prompts in
            if let sel = selectedPresetId, prompts.contains(where: { $0.id == sel }) == false {
                selectedPresetId = nil
            }
        }
        .onChange(of: viewModel.activePrompt) { _, newPrompt in
            if promptLibrary.prompts.first(where: { $0.id == newPrompt.id }) == nil {
                selectedPresetId = nil
            }
        }
        .onChange(of: apiKey) { _, newValue in
            KeychainService.shared.save(value: newValue, forKey: "openAIKey")
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
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var presetSection: some View {
        Section(header: Text("Preset Library")) {
            Picker("Load Preset", selection: $selectedPresetId) {
                Text("None (Current Settings)").tag(nil as UUID?)
                ForEach(promptLibrary.prompts) { prompt in
                    Text(prompt.name).tag(prompt.id as UUID?)
                }
            }
            .onChange(of: selectedPresetId) { _, newValue in
                if let preset = promptLibrary.prompts.first(where: { $0.id == newValue }) {
                    applyPreset(preset)
                }
            }
            
            Button("Manage Presets") {
                showingPromptLibrary = true
            }
            .foregroundColor(.accentColor)
        }
    }
    
    @ViewBuilder
    private var apiSection: some View {
        Section(header: Text("OpenAI API")) {
            SecureField("API Key (sk-...)", text: $apiKey)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibilityConfiguration(
                    label: "API Key",
                    hint: AccessibilityUtils.Hint.apiKeyField,
                    identifier: AccessibilityUtils.Identifier.apiKeyField
                )
        }
    }
    
    @ViewBuilder
    private var publishedPromptSection: some View {
        Section(header: Text("Published Prompt"), footer: Text("Use a prompt published from the OpenAI Playground. When enabled, this will override most other settings.")) {
            Toggle("Use Published Prompt", isOn: $viewModel.activePrompt.enablePublishedPrompt)
            TextField("Published Prompt ID", text: $viewModel.activePrompt.publishedPromptId)
                .disabled(!viewModel.activePrompt.enablePublishedPrompt)
        }
    }
    
    @ViewBuilder
    private var systemInstructionsSection: some View {
        Section(header: Text("System Instructions"), footer: Text("Set a persistent system prompt to guide the assistant's behavior. This will be sent as the 'instructions' field in every request.")) {
            TextEditor(text: $viewModel.activePrompt.systemInstructions)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                .padding(.vertical, 2)
                .accessibilityConfiguration(
                    label: "System instructions",
                    hint: AccessibilityUtils.Hint.systemInstructions,
                    identifier: AccessibilityUtils.Identifier.systemInstructionsField
                )
            if viewModel.activePrompt.systemInstructions.isEmpty {
                Text("e.g. 'You are a helpful assistant.'")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
    }
    
    @ViewBuilder
    private var modelSection: some View {
        Section(header: Text("Model"), footer: Text("Reasoning effort is available for 'o' models and GPT-5. Temperature is available for other models.")) {
            DynamicModelSelector(
                selectedModel: $viewModel.activePrompt.openAIModel,
                openAIService: AppContainer.shared.openAIService
            )
            
            // Reset button for corrupted model selection
            HStack {
                Button("Reset Model to Default") {
                    viewModel.activePrompt.openAIModel = "gpt-4o"
                    viewModel.saveActivePrompt()
                }
                .foregroundColor(.red)
                .font(.caption)
                
                Spacer()
                
                Text("Current: \(viewModel.activePrompt.openAIModel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)

            HStack {
                Picker("Reasoning Effort", selection: $viewModel.activePrompt.reasoningEffort) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) || viewModel.activePrompt.enablePublishedPrompt)
                
                if !ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .help("Not supported by current model")
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Reasoning Summary field for reasoning models
            if ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                VStack(alignment: .leading) {
                    Text("Reasoning Summary")
                    TextField("Summary of reasoning approach (optional)", text: $viewModel.activePrompt.reasoningSummary)
                        .textFieldStyle(.roundedBorder)
                    Text("Optional summary to guide the model's reasoning approach")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Temperature: \(String(format: "%.1f", viewModel.activePrompt.temperature))")
                    if !ModelCompatibilityService.shared.isParameterSupported("temperature", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by reasoning models")
                    }
                }
                Slider(value: $viewModel.activePrompt.temperature, in: 0...2, step: 0.1)
                    .disabled(!ModelCompatibilityService.shared.isParameterSupported("temperature", for: viewModel.activePrompt.openAIModel) || viewModel.activePrompt.enablePublishedPrompt)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
    }

    // MARK: - Section Views
    
    @ViewBuilder
    private var developerInstructionsSection: some View {
        Section(header: Text("Developer Instructions"), footer: Text("Set hidden developer instructions to fine-tune the assistant's behavior with higher priority.")) {
            TextEditor(text: $viewModel.activePrompt.developerInstructions)
                .frame(minHeight: 60)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                .padding(.vertical, 2)
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
    }
    
    @ViewBuilder
    private var responseSettingsSection: some View {
        Section(header: Text("Response Settings"), footer: Text("Adjust response generation parameters. Streaming provides real-time output.")) {
            Toggle("Enable Streaming", isOn: $viewModel.activePrompt.enableStreaming)
            Stepper("Max Output Tokens: \(viewModel.activePrompt.maxOutputTokens)", value: $viewModel.activePrompt.maxOutputTokens, in: 0...32768, step: 64)
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
    }
    
    @ViewBuilder
    private var toolsSection: some View {
        Section(header: Text("Tools"), footer: Text("Enable the capabilities your assistant can use. Some tools are model-dependent; see compatibility below.")) {
            // Computer Use
            Toggle("Computer Use", isOn: $viewModel.activePrompt.enableComputerUse)
                .accessibilityLabel("Enable Computer Use")
                .disabled(!ModelCompatibilityService.shared.isToolSupported(APICapabilities.ToolType.computer, for: viewModel.activePrompt.openAIModel, isStreaming: viewModel.activePrompt.enableStreaming))
            if !ModelCompatibilityService.shared.isToolSupported(.computer, for: viewModel.activePrompt.openAIModel, isStreaming: viewModel.activePrompt.enableStreaming) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Computer Use isn’t supported with the current model/streaming combo.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        Button("Use computer-use-preview") {
                            viewModel.activePrompt.openAIModel = "computer-use-preview"
                            viewModel.activePrompt.enableStreaming = true
                            viewModel.activePrompt.enableComputerUse = true
                            viewModel.saveActivePrompt()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        // Offer disabling streaming only if that would enable Computer Use for this model.
                        if ModelCompatibilityService.shared.isToolSupported(.computer, for: viewModel.activePrompt.openAIModel, isStreaming: false) {
                            Button("Disable streaming") {
                                viewModel.activePrompt.enableStreaming = false
                                viewModel.saveActivePrompt()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                }
            }

            // Core tools
            Toggle("Web Search", isOn: $viewModel.activePrompt.enableWebSearch)
            if viewModel.activePrompt.enableWebSearch {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Search Mode (e.g., default)", text: $viewModel.activePrompt.webSearchMode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Instructions (optional)")
                        TextEditor(text: $viewModel.activePrompt.webSearchInstructions)
                            .frame(minHeight: 60)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }
                    HStack {
                        Stepper("Max Pages: \(viewModel.activePrompt.webSearchMaxPages)", value: $viewModel.activePrompt.webSearchMaxPages, in: 0...20)
                        Spacer()
                        Stepper("Crawl Depth: \(viewModel.activePrompt.webSearchCrawlDepth)", value: $viewModel.activePrompt.webSearchCrawlDepth, in: 0...5)
                    }
                }
                .padding(.top, 4)
            }
            Toggle("Code Interpreter", isOn: $viewModel.activePrompt.enableCodeInterpreter)
            if viewModel.activePrompt.enableCodeInterpreter {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Container Type", selection: $viewModel.activePrompt.codeInterpreterContainerType) {
                        Text("Auto").tag("auto")
                        Text("Secure").tag("secure")
                        Text("GPU").tag("gpu")
                    }
                    .pickerStyle(.segmented)
                    Text("Note: Current API accepts only 'auto'. Other options are future-facing.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preload File IDs (comma-separated)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("file_123, file_456", text: $viewModel.activePrompt.codeInterpreterPreloadFileIds.bound)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        Text("Files to make available in the code interpreter environment")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            Toggle("Image Generation", isOn: $viewModel.activePrompt.enableImageGeneration)
                .disabled(!isImageGenerationSupported)
            if !isImageGenerationSupported {
                Text("Image generation is not supported by the current model")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // File Search + Vector Stores
            Toggle("File Search", isOn: $viewModel.activePrompt.enableFileSearch)
            if viewModel.activePrompt.enableFileSearch {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vector Store IDs (comma-separated)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("vs_123, vs_456", text: $viewModel.activePrompt.selectedVectorStoreIds.bound)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Open File Manager") { showingFileManager = true }
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
                .padding(.top, 4)
            }

            // Custom Function Tool
            Toggle("Custom Function Tool", isOn: $viewModel.activePrompt.enableCustomTool)
            if viewModel.activePrompt.enableCustomTool {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Function Name", text: $viewModel.activePrompt.customToolName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("Description", text: $viewModel.activePrompt.customToolDescription)
                        .textFieldStyle(.roundedBorder)
                    Picker("Execution Type", selection: $viewModel.activePrompt.customToolExecutionType) {
                        Text("Echo").tag("echo")
                        Text("Calculator").tag("calculator")
                        Text("Webhook").tag("webhook")
                    }
                    .pickerStyle(.segmented)
                    if viewModel.activePrompt.customToolExecutionType == "webhook" {
                        TextField("Webhook URL", text: $viewModel.activePrompt.customToolWebhookURL)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Parameters JSON Schema")
                        TextEditor(text: $viewModel.activePrompt.customToolParametersJSON)
                            .frame(minHeight: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }
                }
                .padding(.top, 4)
            }

            // Compatibility summary
            ModelCompatibilityView(
                modelId: viewModel.activePrompt.openAIModel,
                prompt: viewModel.activePrompt,
                isStreaming: viewModel.activePrompt.enableStreaming
            )
        }
        .disabled(viewModel.activePrompt.enablePublishedPrompt)
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
    
    private func loadAPIKey() {
        apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
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
