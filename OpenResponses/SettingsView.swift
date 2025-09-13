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
        Section(header: Text("Tools"), footer: Text("Enable the capabilities your assistant can use. Image generation is disabled during streaming.")) {
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
            Section(header: Text("Advanced API Settings"), footer: Text("These options provide fine-grained control over the OpenAI Responses API. Defaults are recommended for most users.")) {
                Toggle("Background Mode", isOn: $viewModel.activePrompt.backgroundMode)
                // Modality picker removed (audio out of scope and no 'modality' field in Prompt)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response.")) {
                Toggle("Include Computer Use Output", isOn: $viewModel.activePrompt.includeComputerUseOutput)
                Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Include Web Search Results", isOn: $viewModel.activePrompt.includeWebSearchResults)
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
                Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
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
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
