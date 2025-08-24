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
    @State private var apiKey: String = ""
    @AppStorage("openAIModel") private var selectedModel: String = "gpt-4o"
    @AppStorage("reasoningEffort") private var reasoningEffort: String = "medium"
    @AppStorage("temperature") private var temperature: Double = 1.0
    /// System instructions for the assistant (persistent system prompt)
    @AppStorage("systemInstructions") private var systemInstructions: String = ""
    /// Developer instructions for the assistant (for fine-tuning behavior)
    @AppStorage("developerInstructions") private var developerInstructions: String = ""
    
    // Tool configuration settings
    @AppStorage("enableWebSearch") private var enableWebSearch: Bool = true
    @AppStorage("enableCodeInterpreter") private var enableCodeInterpreter: Bool = true
    @AppStorage("enableImageGeneration") private var enableImageGeneration: Bool = true
    @AppStorage("enableFileSearch") private var enableFileSearch: Bool = false
    @AppStorage("enableCalculator") private var enableCalculator: Bool = true
    
    // MCP Tool Settings
    @AppStorage("enableMCPTool") private var enableMCPTool: Bool = false
    @AppStorage("mcpServerLabel") private var mcpServerLabel: String = "paypal"
    @AppStorage("mcpServerURL") private var mcpServerURL: String = "https://mcp.paypal.com/sse"
    @AppStorage("mcpHeaders") private var mcpHeaders: String = "{\"Authorization\": \"Bearer s\"}"
    @AppStorage("mcpRequireApproval") private var mcpRequireApproval: String = "always"

    // Custom Tool Settings
    @AppStorage("enableCustomTool") private var enableCustomTool: Bool = false
    @AppStorage("customToolName") private var customToolName: String = "custom_tool_placeholder"
    @AppStorage("customToolDescription") private var customToolDescription: String = "A placeholder for a custom tool."

    // Web Search configuration settings
    @AppStorage("webSearchLocationType") private var webSearchLocationType: String = "approximate"
    @AppStorage("webSearchTimezone") private var webSearchTimezone: String = "America/Los_Angeles"
    @AppStorage("webSearchContextSize") private var webSearchContextSize: String = "high"
    @AppStorage("webSearchLanguage") private var webSearchLanguage: String = "en"
    @AppStorage("webSearchRegion") private var webSearchRegion: String = "us"
    @AppStorage("webSearchMaxResults") private var webSearchMaxResults: Int = 10
    @AppStorage("webSearchSafeSearch") private var webSearchSafeSearch: String = "moderate"
    @AppStorage("webSearchRecency") private var webSearchRecency: String = "auto"
    @AppStorage("webSearchLatitude") private var webSearchLatitude: Double = 37.7749
    @AppStorage("webSearchLongitude") private var webSearchLongitude: Double = -122.4194
    
    // Advanced web search location settings
    @AppStorage("webSearchCity") private var webSearchCity: String = ""
    @AppStorage("webSearchCountry") private var webSearchCountry: String = ""
    @AppStorage("webSearchLocationRegion") private var webSearchLocationRegion: String = ""
    
    // Advanced API configuration settings
    @AppStorage("backgroundMode") private var backgroundMode: Bool = false
    @AppStorage("maxOutputTokens") private var maxOutputTokens: Int = 0
    @AppStorage("presencePenalty") private var presencePenalty: Double = 0.0
    @AppStorage("frequencyPenalty") private var frequencyPenalty: Double = 0.0
    @AppStorage("maxToolCalls") private var maxToolCalls: Int = 0
    @AppStorage("parallelToolCalls") private var parallelToolCalls: Bool = true
    @AppStorage("serviceTier") private var serviceTier: String = "auto"
    @AppStorage("topLogprobs") private var topLogprobs: Int = 0
    @AppStorage("topP") private var topP: Double = 1.0
    @AppStorage("truncationStrategy") private var truncationStrategy: String = "disabled"
    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    
    // Text formatting settings
    @AppStorage("textFormatType") private var textFormatType: String = "text"
    @AppStorage("jsonSchemaName") private var jsonSchemaName: String = ""
    @AppStorage("jsonSchemaDescription") private var jsonSchemaDescription: String = ""
    @AppStorage("jsonSchemaStrict") private var jsonSchemaStrict: Bool = false
    @AppStorage("jsonSchemaContent") private var jsonSchemaContent: String = ""
    
    // Advanced reasoning settings
    @AppStorage("reasoningSummary") private var reasoningSummary: String = "auto"
    
    // Image generation settings
    @AppStorage("imageGenerationSize") private var imageGenerationSize: String = "auto"
    @AppStorage("imageGenerationQuality") private var imageGenerationQuality: String = "auto"
    @AppStorage("imageGenerationBackground") private var imageGenerationBackground: String = "auto"
    @AppStorage("imageGenerationOutputFormat") private var imageGenerationOutputFormat: String = "png"
    @AppStorage("imageGenerationModeration") private var imageGenerationModeration: String = "auto"
    @AppStorage("imageGenerationPartialImages") private var imageGenerationPartialImages: Int = 0
    @AppStorage("imageGenerationOutputCompression") private var imageGenerationOutputCompression: Int = 100
    
    // Advanced include settings
    @AppStorage("includeCodeInterpreterOutputs") private var includeCodeInterpreterOutputs: Bool = false
    @AppStorage("includeFileSearchResults") private var includeFileSearchResults: Bool = false
    @AppStorage("includeInputImageUrls") private var includeInputImageUrls: Bool = false
    @AppStorage("includeOutputLogprobs") private var includeOutputLogprobs: Bool = false
    @AppStorage("includeReasoningContent") private var includeReasoningContent: Bool = false
    
    // Debugging settings
    @AppStorage("detailedNetworkLogging") private var detailedNetworkLogging: Bool = true
    
    // Response streaming setting
    @AppStorage("enableStreaming") private var enableStreaming: Bool = true
    
    // Published Prompt settings
    @AppStorage("enablePublishedPrompt") private var enablePublishedPrompt: Bool = false
    @AppStorage("publishedPromptId") private var publishedPromptId: String = ""
    @AppStorage("publishedPromptVersion") private var publishedPromptVersion: String = "1"
    
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFileManager = false
    @State private var showingPromptLibrary = false
    @StateObject private var promptLibrary = PromptLibrary()
    @State private var selectedPresetId: UUID?

    // Supported models list for the Picker
    private let modelOptions: [String] = ["gpt-5", "gpt-4o", "o3", "o3-mini", "o1", "gpt-4-1106-preview"]
    
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
            }
            
            Section(header: Text("Published Prompt"), footer: Text("Use a prompt published from the OpenAI Playground. When enabled, this will override most other settings.")) {
                Toggle("Use Published Prompt", isOn: $viewModel.activePrompt.enablePublishedPrompt)
                if viewModel.activePrompt.enablePublishedPrompt {
                    TextField("Prompt ID (pmpt_...)", text: Binding(
                        get: { viewModel.activePrompt.publishedPromptId },
                        set: { viewModel.activePrompt.publishedPromptId = $0 }
                    ))
                    TextField("Prompt Version", text: $viewModel.activePrompt.publishedPromptVersion)
                }
            }
            
            // System instructions section
            Section(header: Text("System Instructions"), footer: Text("Set a persistent system prompt to guide the assistant's behavior. This will be sent as the 'instructions' field in every request.")) {
                TextEditor(text: Binding(
                    get: { viewModel.activePrompt.systemInstructions },
                    set: { viewModel.activePrompt.systemInstructions = $0 }
                ))
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                    .padding(.vertical, 2)
                if viewModel.activePrompt.systemInstructions.isEmpty {
                    Text("e.g. 'You are a helpful assistant.'")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Developer Instructions"), footer: Text("Set hidden developer instructions to fine-tune the assistant's behavior with higher priority.")) {
                TextEditor(text: Binding(
                    get: { viewModel.activePrompt.developerInstructions },
                    set: { viewModel.activePrompt.developerInstructions = $0 }
                ))
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

            Section(header: Text("Model"), footer: Text("Reasoning effort is only available for 'o' models. Temperature is only available for other models.")) {
                Picker("Model", selection: $viewModel.activePrompt.openAIModel) {
                    ForEach(modelOptions, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker("Reasoning Effort", selection: $viewModel.activePrompt.reasoningEffort) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)
                .disabled(!viewModel.activePrompt.openAIModel.starts(with: "o"))
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(String(format: "%.1f", viewModel.activePrompt.temperature))")
                    Slider(value: $viewModel.activePrompt.temperature, in: 0...2, step: 0.1)
                }
                .disabled(viewModel.activePrompt.openAIModel.starts(with: "o"))
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Response Settings"), footer: Text("Adjust response generation parameters. Streaming provides real-time output.")) {
                Toggle("Enable Streaming", isOn: $viewModel.activePrompt.enableStreaming)
                
                VStack(alignment: .leading) {
                    Text("Max Output Tokens: \(viewModel.activePrompt.maxOutputTokens == 0 ? "Default" : String(viewModel.activePrompt.maxOutputTokens))")
                    Slider(value: Binding(
                        get: { Double(viewModel.activePrompt.maxOutputTokens) },
                        set: { viewModel.activePrompt.maxOutputTokens = Int($0) }
                    ), in: 0...4096, step: 64)
                }
                
                VStack(alignment: .leading) {
                    Text("Presence Penalty: \(String(format: "%.1f", viewModel.activePrompt.presencePenalty))")
                    Slider(value: $viewModel.activePrompt.presencePenalty, in: -2.0...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Frequency Penalty: \(String(format: "%.1f", viewModel.activePrompt.frequencyPenalty))")
                    Slider(value: $viewModel.activePrompt.frequencyPenalty, in: -2.0...2.0, step: 0.1)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            Section(header: Text("Tools"), footer: Text("Configure which AI tools are available for the assistant to use. Note: Image generation is automatically disabled when streaming is enabled.")) {
                Toggle("Web Search", isOn: $viewModel.activePrompt.enableWebSearch)
                Toggle("Code Interpreter", isOn: $viewModel.activePrompt.enableCodeInterpreter)
                Toggle("Calculator (Custom Tool)", isOn: $viewModel.activePrompt.enableCalculator)
                HStack {
                    Toggle("Image Generation", isOn: $viewModel.activePrompt.enableImageGeneration)
                        .disabled(viewModel.activePrompt.enableStreaming)
                    if viewModel.activePrompt.enableStreaming && viewModel.activePrompt.enableImageGeneration {
                        Text("(Disabled in streaming mode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Toggle("File Search", isOn: $viewModel.activePrompt.enableFileSearch)
                Toggle("MCP Tool", isOn: $viewModel.activePrompt.enableMCPTool)
                Toggle("Custom Tool", isOn: $viewModel.activePrompt.enableCustomTool)
                
                if viewModel.activePrompt.enableFileSearch {
                    Button("Manage Files & Vector Stores") {
                        showingFileManager = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)

            // MCP Tool Configuration Section
            if viewModel.activePrompt.enableMCPTool {
                Section(header: Text("MCP Tool Configuration")) {
                    TextField("Server Label", text: Binding(get: { viewModel.activePrompt.mcpServerLabel }, set: { viewModel.activePrompt.mcpServerLabel = $0 }))
                    TextField("Server URL", text: Binding(get: { viewModel.activePrompt.mcpServerURL }, set: { viewModel.activePrompt.mcpServerURL = $0 }))
                    TextEditor(text: Binding(get: { viewModel.activePrompt.mcpHeaders }, set: { viewModel.activePrompt.mcpHeaders = $0 }))
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    Picker("Require Approval", selection: Binding(get: { viewModel.activePrompt.mcpRequireApproval }, set: { viewModel.activePrompt.mcpRequireApproval = $0 })) {
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
                    TextField("Tool Name", text: Binding(get: { viewModel.activePrompt.customToolName }, set: { viewModel.activePrompt.customToolName = $0 }))
                    TextField("Tool Description", text: Binding(get: { viewModel.activePrompt.customToolDescription }, set: { viewModel.activePrompt.customToolDescription = $0 }))
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
                    Text("Flex").tag("flex")
                    Text("Priority").tag("priority")
                }
                .pickerStyle(.segmented)
                Stepper("Top Logprobs: \(viewModel.activePrompt.topLogprobs)", value: $viewModel.activePrompt.topLogprobs, in: 0...20)
                Slider(value: $viewModel.activePrompt.topP, in: 0.0...1.0, step: 0.01) {
                    Text("Top P")
                } minimumValueLabel: {
                    Text("0.0")
                } maximumValueLabel: {
                    Text("1.0")
                }
                Text("Top P: \(String(format: "%.2f", viewModel.activePrompt.topP))")
                Picker("Truncation", selection: $viewModel.activePrompt.truncationStrategy) {
                    Text("Disabled").tag("disabled")
                    Text("Auto").tag("auto")
                }
                .pickerStyle(.segmented)
                TextField("User Identifier", text: Binding(get: { viewModel.activePrompt.userIdentifier }, set: { viewModel.activePrompt.userIdentifier = $0 }))
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Advanced Include Section
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response. Note: Reasoning content cannot be included when conversation persistence is enabled.")) {
                Toggle("Include Code Interpreter Outputs", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
                Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Text Formatting Section
            Section(header: Text("Text Output Formatting"), footer: Text("Configure the output format for text responses. Use JSON Schema for structured outputs.")) {
                Picker("Format Type", selection: $viewModel.activePrompt.textFormatType) {
                    Text("Text").tag("text")
                    Text("JSON Schema").tag("json_schema")
                }
                .pickerStyle(.segmented)
                if viewModel.activePrompt.textFormatType == "json_schema" {
                    TextField("Schema Name", text: Binding(get: { viewModel.activePrompt.jsonSchemaName }, set: { viewModel.activePrompt.jsonSchemaName = $0 }))
                    TextField("Schema Description", text: Binding(get: { viewModel.activePrompt.jsonSchemaDescription }, set: { viewModel.activePrompt.jsonSchemaDescription = $0 }))
                    Toggle("Strict Schema", isOn: $viewModel.activePrompt.jsonSchemaStrict)
                    TextEditor(text: Binding(get: { viewModel.activePrompt.jsonSchemaContent }, set: { viewModel.activePrompt.jsonSchemaContent = $0 }))
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Debugging Section
            Section(header: Text("Debugging"), footer: Text("Settings for debugging and development purposes.")) {
                Toggle("Detailed Network Logging", isOn: $detailedNetworkLogging)
                    .onChange(of: detailedNetworkLogging) { _, newValue in
                        print("Detailed network logging \(newValue ? "enabled" : "disabled")")
                    }
            }
            
            // Advanced Reasoning Section
            if viewModel.activePrompt.openAIModel.starts(with: "o") {
                Section(header: Text("Advanced Reasoning"), footer: Text("Configure summary output for reasoning models.")) {
                    Picker("Reasoning Summary", selection: $viewModel.activePrompt.reasoningSummary) {
                        Text("Auto").tag("auto")
                        Text("Concise").tag("concise")
                        Text("Detailed").tag("detailed")
                    }
                    .pickerStyle(.segmented)
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
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
            // When the view appears, if no preset is selected, it means we are using the "live" settings.
            // We can set the selectedPresetId to nil to reflect this.
            // Reload presets from storage to ensure the Picker shows the latest list
            promptLibrary.reload()
            if promptLibrary.prompts.first(where: { $0.id == viewModel.activePrompt.id }) == nil {
                selectedPresetId = nil
            } else {
                selectedPresetId = viewModel.activePrompt.id
            }
            
            apiKey = KeychainService.shared.load(forKey: "openAIKey") ?? ""
        }
        .onChange(of: viewModel.activePrompt) { _, _ in
            // If the active prompt changes to one that isn't in the library, deselect the picker.
            if promptLibrary.prompts.first(where: { $0.id == viewModel.activePrompt.id }) == nil {
                selectedPresetId = nil
            }
        }
        .onChange(of: apiKey) { _, newValue in
            KeychainService.shared.save(value: newValue, forKey: "openAIKey")
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView()
        }
        .sheet(isPresented: $showingPromptLibrary) {
            // Pass a method to the library view to create a prompt from current settings
            PromptLibraryView(library: promptLibrary, createPromptFromCurrentSettings: {
                // Return the current state of the view model's active prompt
                return viewModel.activePrompt
            })
            .onDisappear {
                // Refresh after managing presets to reflect changes in the Picker
                promptLibrary.reload()
            }
        }
    }

    /// Applies a saved preset to the active prompt in the view model.
    private func applyPreset(_ preset: Prompt) {
        viewModel.activePrompt = preset
        // The view will automatically update because it's bound to viewModel.activePrompt
    }
    
    /// Provides a recommendation on whether streaming should be enabled based on current tool selection
    /// - Returns: A tuple with (shouldStream: Bool, reason: String?)
    private func getStreamingRecommendation() -> (shouldStream: Bool, reason: String?) {
        // If image generation is enabled, recommend disabling streaming
        if viewModel.activePrompt.enableImageGeneration {
            return (false, "Image generation works better without streaming")
        }
        
        // For most other cases, streaming is beneficial
        return (true, nil)
    }
}
