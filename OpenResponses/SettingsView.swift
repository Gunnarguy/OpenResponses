import SwiftUI

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

    // All @AppStorage properties are removed. The view will now bind directly to viewModel.activePrompt.
    
    var body: some View {
        Form {
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
            
            Section(header: Text("Published Prompt"), footer: Text("Use a prompt published from the OpenAI Playground. When enabled, this will override most other settings.")) {
                Toggle("Use Published Prompt", isOn: $viewModel.activePrompt.enablePublishedPrompt)
                if viewModel.activePrompt.enablePublishedPrompt {
                    TextField("Prompt ID (pmpt_...)", text: $viewModel.activePrompt.publishedPromptId)
                    TextField("Prompt Version", text: $viewModel.activePrompt.publishedPromptVersion)
                }
            }
            
            // System instructions section
            Section(header: Text("System Instructions"), footer: Text("Set a persistent system prompt to guide the assistant's behavior. This will be sent as the 'instructions' field in every request.")) {
                TextEditor(text: $viewModel.activePrompt.systemInstructions)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
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
            
            Section(header: Text("Developer Instructions"), footer: Text("Set hidden developer instructions to fine-tune the assistant's behavior with higher priority.")) {
                TextEditor(text: $viewModel.activePrompt.developerInstructions)
                    .frame(minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                    .padding(.vertical, 2)
                if viewModel.activePrompt.developerInstructions.isEmpty {
                    Text("e.g. 'Always respond in Markdown.'")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)

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
            
            Section(header: Text("Response Settings"), footer: Text("Adjust response generation parameters. Streaming provides real-time output.")) {
                HStack {
                    Toggle("Enable Streaming", isOn: $viewModel.activePrompt.enableStreaming)
                        .accessibilityHint("Enables real-time response streaming from the AI")
                    if !(ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsStreaming ?? true) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .help("Streaming not supported by current model")
                    }
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Max Output Tokens: \(viewModel.activePrompt.maxOutputTokens == 0 ? "Default" : String(viewModel.activePrompt.maxOutputTokens))")
                        if !ModelCompatibilityService.shared.isParameterSupported("max_output_tokens", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .help("Not supported by current model")
                        }
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.activePrompt.maxOutputTokens) },
                        set: { viewModel.activePrompt.maxOutputTokens = Int($0) }
                    ), in: 0...4096, step: 64)
                    .disabled(!ModelCompatibilityService.shared.isParameterSupported("max_output_tokens", for: viewModel.activePrompt.openAIModel))
                    .accessibilityLabel("Max output tokens")
                    .accessibilityHint("Limits the maximum number of tokens in AI responses")
                    .accessibilityValue("\(viewModel.activePrompt.maxOutputTokens == 0 ? "Default" : String(viewModel.activePrompt.maxOutputTokens))")
                }
                
                Picker("Tool Choice", selection: $viewModel.activePrompt.toolChoice) {
                    Text("Auto").tag("auto")
                    Text("None").tag("none")
                    if viewModel.activePrompt.enableCalculator { Text("Calculator").tag("calculator") }
                    if viewModel.activePrompt.enableWebSearch { Text("Web Search").tag("web_search") }
                    if viewModel.activePrompt.enableCodeInterpreter { Text("Code Interpreter").tag("code_interpreter") }
                }
                .accessibilityHint("Controls which tools the AI can use")
                
                VStack(alignment: .leading) {
                    Text("Metadata (JSON)")
                    TextField("Metadata", text: $viewModel.activePrompt.metadata.bound)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityHint("Optional metadata to attach to requests in JSON format")
                    Text("Optional metadata to attach to requests (JSON format)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Tools"), footer: Text("Configure which AI tools are available for the assistant to use. Note: Image generation is automatically disabled when streaming is enabled.")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Web Search", isOn: $viewModel.activePrompt.enableWebSearch)
                            .accessibilityHint("Allows the AI to search the internet for current information")
                        if !ModelCompatibilityService.shared.isToolSupported("web_search", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Not supported by current model")
                        }
                    }
                    
                    HStack {
                        Toggle("Code Interpreter", isOn: $viewModel.activePrompt.enableCodeInterpreter)
                            .accessibilityHint("Enables the AI to run Python code and analyze data")
                        if !ModelCompatibilityService.shared.isToolSupported("code_interpreter", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Not supported by current model")
                        }
                    }
                    
                    HStack {
                        Toggle("Calculator (Custom Tool)", isOn: $viewModel.activePrompt.enableCalculator)
                            .accessibilityHint("Provides mathematical calculation capabilities")
                        if !ModelCompatibilityService.shared.isToolSupported("function", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Function tools not supported by current model")
                        }
                    }
                    
                    HStack {
                        Toggle("Image Generation", isOn: $viewModel.activePrompt.enableImageGeneration)
                            .disabled(viewModel.activePrompt.enableStreaming)
                            .accessibilityHint("Allows the AI to create images with DALL-E")
                        if viewModel.activePrompt.enableStreaming && viewModel.activePrompt.enableImageGeneration {
                            Text("(Disabled in streaming mode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Image generation disabled")
                        } else if !ModelCompatibilityService.shared.isToolSupported("image_generation", for: viewModel.activePrompt.openAIModel, isStreaming: viewModel.activePrompt.enableStreaming) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Not supported by current model or streaming mode")
                        }
                    }
                    
                    HStack {
                        Toggle("File Search", isOn: $viewModel.activePrompt.enableFileSearch)
                            .accessibilityHint("Enables searching through uploaded files and documents")
                        if !ModelCompatibilityService.shared.isToolSupported("file_search", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Not supported by current model")
                        }
                    }
                    
                    HStack {
                        Toggle("MCP Tool", isOn: $viewModel.activePrompt.enableMCPTool)
                            .accessibilityHint("Connects to Model Context Protocol servers")
                        if !ModelCompatibilityService.shared.isToolSupported("function", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Function tools not supported by current model")
                        }
                    }
                    
                    HStack {
                        Toggle("Custom Tool", isOn: $viewModel.activePrompt.enableCustomTool)
                            .accessibilityHint("Enables user-defined custom tools")
                        if !ModelCompatibilityService.shared.isToolSupported("function", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("Function tools not supported by current model")
                        }
                    }
                }
                
                if viewModel.activePrompt.enableFileSearch {
                    VStack(alignment: .leading) {
                        Text("Vector Store IDs")
                        TextField("Comma-separated vector store IDs", text: $viewModel.activePrompt.selectedVectorStoreIds.bound)
                            .textFieldStyle(.roundedBorder)
                        Text("Enter vector store IDs separated by commas, e.g., vs_123,vs_456")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Manage Files & Vector Stores") {
                        showingFileManager = true
                    }
                    .foregroundColor(.accentColor)
                    .accessibilityHint("Open file management interface for organizing uploaded documents")
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Web Search Configuration Section
            if viewModel.activePrompt.enableWebSearch {
                Section(header: Text("Web Search Configuration"), footer: Text("Customize web search behavior including location, language, and result filtering.")) {
                    Picker("Context Size", selection: $viewModel.activePrompt.searchContextSize.bound) {
                        Text("Medium").tag("medium")
                        Text("Low").tag("low")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("City", text: $viewModel.activePrompt.userLocationCity.bound)
                    TextField("Country", text: $viewModel.activePrompt.userLocationCountry.bound)
                    TextField("Region", text: $viewModel.activePrompt.userLocationRegion.bound)
                    TextField("Timezone", text: $viewModel.activePrompt.userLocationTimezone.bound)
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            // MCP Tool Configuration Section
            if viewModel.activePrompt.enableMCPTool {
                Section(header: Text("MCP Tool Configuration")) {
                    TextField("Server Label", text: $viewModel.activePrompt.mcpServerLabel)
                    TextField("Server URL", text: $viewModel.activePrompt.mcpServerURL)
                    TextEditor(text: $viewModel.activePrompt.mcpHeaders)
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    Picker("Require Approval", selection: $viewModel.activePrompt.mcpRequireApproval) {
                        Text("Always").tag("always")
                        Text("Never").tag("never")
                    }
                    .pickerStyle(.segmented)
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }

            // Custom Tool Configuration Section
            if viewModel.activePrompt.enableCustomTool {
                Section(header: Text("Custom Tool Configuration")) {
                    TextField("Tool Name", text: $viewModel.activePrompt.customToolName)
                    TextField("Tool Description", text: $viewModel.activePrompt.customToolDescription)
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            // Advanced API Settings Section
            Section(header: Text("Advanced API Settings"), footer: Text("These options provide fine-grained control over the OpenAI Responses API. Defaults are recommended for most users.")) {
                Toggle("Background Mode", isOn: $viewModel.activePrompt.backgroundMode)
                Stepper("Max Tool Calls: \(viewModel.activePrompt.maxToolCalls)", value: $viewModel.activePrompt.maxToolCalls, in: 0...20)
                Toggle("Parallel Tool Calls", isOn: $viewModel.activePrompt.parallelToolCalls)
                Picker("Service Tier", selection: $viewModel.activePrompt.serviceTier) {
                    Text("Auto").tag("auto")
                    Text("Default").tag("default")
                }
                .pickerStyle(.segmented)
                Stepper("Top Logprobs: \(viewModel.activePrompt.topLogprobs)", value: $viewModel.activePrompt.topLogprobs, in: 0...20)
                VStack(alignment: .leading) {
                    Text("Top P: \(String(format: "%.2f", viewModel.activePrompt.topP))")
                    Slider(value: $viewModel.activePrompt.topP, in: 0.0...1.0, step: 0.01)
                }
                Picker("Truncation", selection: $viewModel.activePrompt.truncationStrategy) {
                    Text("Auto").tag("auto")
                    Text("Disabled").tag("disabled")
                }
                .pickerStyle(.segmented)
                TextField("User Identifier", text: $viewModel.activePrompt.userIdentifier)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Advanced Include Section
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response. Note: Code Interpreter outputs are not currently supported by the API.")) {
                Toggle("Include Code Interpreter Outputs", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                    .disabled(true) // Disabled since not supported by current API
                Toggle("Include Computer Call Output", isOn: $viewModel.activePrompt.includeComputerCallOutput)
                Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
                Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Text Formatting Section
            Section(header: Text("Text Output Formatting"), footer: Text("Configure the output format for text responses.")) {
                Picker("Format Type", selection: $viewModel.activePrompt.textFormatType) {
                    Text("Text").tag("text")
                    Text("JSON Schema").tag("json_schema")
                }
                .pickerStyle(.segmented)
                if viewModel.activePrompt.textFormatType == "json_schema" {
                    TextField("Schema Name", text: $viewModel.activePrompt.jsonSchemaName)
                    TextField("Schema Description", text: $viewModel.activePrompt.jsonSchemaDescription)
                    Toggle("Strict Schema", isOn: $viewModel.activePrompt.jsonSchemaStrict)
                    TextEditor(text: $viewModel.activePrompt.jsonSchemaContent)
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Debugging Section
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
                Button(role: .destructive) {
                    viewModel.clearConversation()
                } label: {
                    Text("Clear Conversation")
                }
            }
        }
        .onAppear {
            promptLibrary.reload()
            selectedPresetId = viewModel.activePrompt.id
            apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
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

    private func applyPreset(_ preset: Prompt) {
        viewModel.activePrompt = preset
    }
}

// Helper to bind optional strings in TextFields
extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
