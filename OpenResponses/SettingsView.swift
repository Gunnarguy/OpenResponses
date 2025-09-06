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
    @AppStorage("includeComputerCallOutput") private var includeComputerCallOutput: Bool = false
    @AppStorage("includeFileSearchResults") private var includeFileSearchResults: Bool = false
    @AppStorage("includeInputImageUrls") private var includeInputImageUrls: Bool = false
    @AppStorage("includeOutputLogprobs") private var includeOutputLogprobs: Bool = false
    @AppStorage("includeReasoningContent") private var includeReasoningContent: Bool = false
    
    // Debugging settings
    @AppStorage("detailedNetworkLogging") private var detailedNetworkLogging: Bool = true
    
    // UI state for modals
    @State private var showingAPIInspector = false
    @State private var showingDebugConsole = false
    
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

            Section(header: Text("Model"), footer: Text("Reasoning effort is available for 'o' models and GPT-5. Temperature is available for other models.")) {
                DynamicModelSelector(
                    selectedModel: $viewModel.activePrompt.openAIModel,
                    openAIService: AppContainer.shared.openAIService
                )

                HStack {
                    Picker("Reasoning Effort", selection: $viewModel.activePrompt.reasoningEffort) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    .disabled(!ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel))
                    
                    if !ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
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
                        .disabled(!ModelCompatibilityService.shared.isParameterSupported("temperature", for: viewModel.activePrompt.openAIModel))
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
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
                    // Add specific tool choices when tools are enabled
                    if viewModel.activePrompt.enableCalculator {
                        Text("Calculator").tag("calculator")
                    }
                    if viewModel.activePrompt.enableWebSearch {
                        Text("Web Search").tag("web_search_preview")
                    }
                    if viewModel.activePrompt.enableCodeInterpreter {
                        Text("Code Interpreter").tag("code_interpreter")
                    }
                }
                .accessibilityHint("Controls which tools the AI can use")
                
                VStack(alignment: .leading) {
                    Text("Metadata (JSON)")
                    TextField("Metadata", text: Binding(
                        get: { viewModel.activePrompt.metadata ?? "" },
                        set: { viewModel.activePrompt.metadata = $0.isEmpty ? nil : $0 }
                    ))
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
                        if !ModelCompatibilityService.shared.isToolSupported("web_search_preview", for: viewModel.activePrompt.openAIModel) {
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
                    Picker("Location Type", selection: $webSearchLocationType) {
                        Text("Approximate").tag("approximate")
                        Text("Exact").tag("exact")
                        Text("Disabled").tag("disabled")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("How location context is provided to web searches")
                    
                    Picker("Timezone", selection: $webSearchTimezone) {
                        Text("Pacific").tag("America/Los_Angeles")
                        Text("Mountain").tag("America/Denver")
                        Text("Central").tag("America/Chicago")
                        Text("Eastern").tag("America/New_York")
                        Text("UTC").tag("UTC")
                        Text("London").tag("Europe/London")
                        Text("Tokyo").tag("Asia/Tokyo")
                        Text("Sydney").tag("Australia/Sydney")
                    }
                    .accessibilityHint("Timezone for time-relevant search results")
                    
                    if webSearchLocationType == "exact" {
                        VStack(alignment: .leading) {
                            Text("Latitude: \(String(format: "%.4f", webSearchLatitude))")
                            Slider(value: $webSearchLatitude, in: -90.0...90.0)
                                .accessibilityLabel("Latitude")
                                .accessibilityValue(String(format: "%.4f", webSearchLatitude))
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Longitude: \(String(format: "%.4f", webSearchLongitude))")
                            Slider(value: $webSearchLongitude, in: -180.0...180.0)
                                .accessibilityLabel("Longitude")
                                .accessibilityValue(String(format: "%.4f", webSearchLongitude))
                        }
                        
                        TextField("City", text: $webSearchCity)
                            .accessibilityHint("Optional city name for location context")
                        TextField("Country", text: $webSearchCountry)
                            .accessibilityHint("Optional country name for location context")
                        TextField("Region", text: $webSearchLocationRegion)
                            .accessibilityHint("Optional region name for location context")
                    }
                    
                    Picker("Search Context Size", selection: $webSearchContextSize) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Controls the depth and detail of web search results")
                    
                    Picker("Language", selection: $webSearchLanguage) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Italian").tag("it")
                        Text("Portuguese").tag("pt")
                        Text("Japanese").tag("ja")
                        Text("Chinese").tag("zh")
                        Text("Korean").tag("ko")
                        Text("Russian").tag("ru")
                    }
                    .accessibilityHint("Language preference for search results")
                    
                    Picker("Search Region", selection: $webSearchRegion) {
                        Text("United States").tag("us")
                        Text("Canada").tag("ca")
                        Text("United Kingdom").tag("uk")
                        Text("Germany").tag("de")
                        Text("France").tag("fr")
                        Text("Japan").tag("jp")
                        Text("Australia").tag("au")
                        Text("Global").tag("global")
                    }
                    .accessibilityHint("Regional preference for search results")
                    
                    Stepper("Max Results: \(webSearchMaxResults)", value: $webSearchMaxResults, in: 5...50, step: 5)
                        .accessibilityHint("Maximum number of search results per query")
                    
                    Picker("Safe Search", selection: $webSearchSafeSearch) {
                        Text("Strict").tag("strict")
                        Text("Moderate").tag("moderate")
                        Text("Off").tag("off")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Content filtering level for search results")
                    
                    Picker("Recency Filter", selection: $webSearchRecency) {
                        Text("Auto").tag("auto")
                        Text("24 Hours").tag("24h")
                        Text("Week").tag("week")
                        Text("Month").tag("month")
                        Text("Year").tag("year")
                    }
                    .accessibilityHint("Time-based filtering for search results")
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            // Image Generation Configuration Section
            if viewModel.activePrompt.enableImageGeneration {
                Section(header: Text("Image Generation Configuration"), footer: Text("Configure DALL-E image generation settings including size, quality, and output format.")) {
                    Picker("Image Size", selection: $imageGenerationSize) {
                        Text("Auto").tag("auto")
                        Text("1024x1024").tag("1024x1024")
                        Text("1792x1024").tag("1792x1024")
                        Text("1024x1792").tag("1024x1792")
                    }
                    .accessibilityHint("Select the dimensions for generated images")
                    
                    Picker("Image Quality", selection: $imageGenerationQuality) {
                        Text("Auto").tag("auto")
                        Text("Standard").tag("standard")
                        Text("HD").tag("hd")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Choose image quality level, HD takes longer but produces better results")
                    
                    Picker("Background", selection: $imageGenerationBackground) {
                        Text("Auto").tag("auto")
                        Text("Transparent").tag("transparent")
                        Text("White").tag("white")
                        Text("Black").tag("black")
                    }
                    .accessibilityHint("Background style for generated images")
                    
                    Picker("Output Format", selection: $imageGenerationOutputFormat) {
                        Text("PNG").tag("png")
                        Text("JPEG").tag("jpeg")
                        Text("WebP").tag("webp")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("File format for saved images")
                    
                    Picker("Content Moderation", selection: $imageGenerationModeration) {
                        Text("Auto").tag("auto")
                        Text("Strict").tag("strict")
                        Text("Moderate").tag("moderate")
                        Text("Off").tag("off")
                    }
                    .accessibilityHint("Content filtering level for image generation")
                    
                    if imageGenerationPartialImages > 0 {
                        Stepper("Partial Images: \(imageGenerationPartialImages)", value: $imageGenerationPartialImages, in: 0...10)
                            .accessibilityHint("Number of intermediate images to show during generation")
                    } else {
                        Button("Enable Partial Images") {
                            imageGenerationPartialImages = 1
                        }
                        .accessibilityHint("Show intermediate steps during image generation")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Output Compression: \(imageGenerationOutputCompression)%")
                        Slider(value: Binding(
                            get: { Double(imageGenerationOutputCompression) },
                            set: { imageGenerationOutputCompression = Int($0) }
                        ), in: 10...100, step: 5)
                        .accessibilityLabel("Output compression")
                        .accessibilityHint("Compression level for generated images, lower values reduce file size")
                        .accessibilityValue("\(imageGenerationOutputCompression) percent")
                    }
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }

            // MCP Tool Configuration Section
            if viewModel.activePrompt.enableMCPTool {
                Section(header: Text("MCP Tool Configuration")) {
                    TextField("Server Label", text: Binding(get: { viewModel.activePrompt.mcpServerLabel }, set: { viewModel.activePrompt.mcpServerLabel = $0 }))
                        .accessibilityHint("Label for the MCP server connection")
                    TextField("Server URL", text: Binding(get: { viewModel.activePrompt.mcpServerURL }, set: { viewModel.activePrompt.mcpServerURL = $0 }))
                        .accessibilityHint("URL endpoint for the MCP server")
                    TextEditor(text: Binding(get: { viewModel.activePrompt.mcpHeaders }, set: { viewModel.activePrompt.mcpHeaders = $0 }))
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                        .accessibilityLabel("MCP Headers")
                        .accessibilityHint("JSON headers for MCP server authentication")
                    Picker("Require Approval", selection: Binding(get: { viewModel.activePrompt.mcpRequireApproval }, set: { viewModel.activePrompt.mcpRequireApproval = $0 })) {
                        Text("Always").tag("always")
                        Text("Never").tag("never")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Whether to require user approval for MCP operations")
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }

            // Custom Tool Configuration Section
            if viewModel.activePrompt.enableCustomTool {
                Section(header: Text("Custom Tool Configuration")) {
                    TextField("Tool Name", text: Binding(get: { viewModel.activePrompt.customToolName }, set: { viewModel.activePrompt.customToolName = $0 }))
                        .accessibilityHint("Name for the custom tool function")
                    TextField("Tool Description", text: Binding(get: { viewModel.activePrompt.customToolDescription }, set: { viewModel.activePrompt.customToolDescription = $0 }))
                        .accessibilityHint("Description of what the custom tool does")
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            // Advanced API Settings Section
            Section(header: Text("Advanced API Settings"), footer: Text("These options provide fine-grained control over the OpenAI Responses API. Defaults are recommended for most users.")) {
                HStack {
                    Toggle("Background Mode", isOn: $viewModel.activePrompt.backgroundMode)
                        .accessibilityHint("Enables background processing for API requests")
                    if !ModelCompatibilityService.shared.isParameterSupported("background", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("background", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Stepper("Max Tool Calls: \(viewModel.activePrompt.maxToolCalls)", value: $viewModel.activePrompt.maxToolCalls, in: 0...20)
                        .accessibilityHint("Sets maximum number of tool calls per request")
                    if !ModelCompatibilityService.shared.isParameterSupported("max_tool_calls", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("max_tool_calls", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Toggle("Parallel Tool Calls", isOn: $viewModel.activePrompt.parallelToolCalls)
                        .accessibilityHint("Allows tools to be called simultaneously")
                    if !ModelCompatibilityService.shared.isParameterSupported("parallel_tool_calls", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("parallel_tool_calls", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Picker("Service Tier", selection: $viewModel.activePrompt.serviceTier) {
                        Text("Auto").tag("auto")
                        Text("Default").tag("default")
                        Text("Flex").tag("flex")
                        Text("Priority").tag("priority")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Select API service tier for request priority")
                    if !ModelCompatibilityService.shared.isParameterSupported("service_tier", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("service_tier", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Stepper("Top Logprobs: \(viewModel.activePrompt.topLogprobs)", value: $viewModel.activePrompt.topLogprobs, in: 0...20)
                        .accessibilityHint("Number of top log probabilities to return")
                    if !ModelCompatibilityService.shared.isParameterSupported("top_logprobs", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("top_logprobs", for: viewModel.activePrompt.openAIModel))
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Top P")
                        if !ModelCompatibilityService.shared.isParameterSupported("top_p", for: viewModel.activePrompt.openAIModel) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .help("Not supported by current model")
                        }
                    }
                    Slider(value: $viewModel.activePrompt.topP, in: 0.0...1.0, step: 0.01) {
                        Text("Top P")
                    } minimumValueLabel: {
                        Text("0.0")
                    } maximumValueLabel: {
                        Text("1.0")
                    }
                    .disabled(!ModelCompatibilityService.shared.isParameterSupported("top_p", for: viewModel.activePrompt.openAIModel))
                    .accessibilityLabel("Top P sampling")
                    .accessibilityHint("Controls diversity of word selection")
                    .accessibilityValue(String(format: "%.2f", viewModel.activePrompt.topP))
                    Text("Top P: \(String(format: "%.2f", viewModel.activePrompt.topP))")
                        .accessibilityHidden(true)
                }
                
                HStack {
                    Picker("Truncation", selection: $viewModel.activePrompt.truncationStrategy) {
                        Text("Disabled").tag("disabled")
                        Text("Auto").tag("auto")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Controls how long contexts are truncated")
                    if !ModelCompatibilityService.shared.isParameterSupported("truncation", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("truncation", for: viewModel.activePrompt.openAIModel))
                
                TextField("User Identifier", text: Binding(get: { viewModel.activePrompt.userIdentifier }, set: { viewModel.activePrompt.userIdentifier = $0 }))
                    .accessibilityHint("Optional identifier for tracking user sessions")
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Advanced Include Section
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response. Note: Reasoning content cannot be included when conversation persistence is enabled.")) {
                HStack {
                    Toggle("Include Code Interpreter Outputs", isOn: $viewModel.activePrompt.includeCodeInterpreterOutputs)
                        .accessibilityHint("Includes code execution results in responses")
                    if !ModelCompatibilityService.shared.isToolSupported("code_interpreter", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Code interpreter not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isToolSupported("code_interpreter", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Toggle("Include Computer Call Output", isOn: $viewModel.activePrompt.includeComputerCallOutput)
                        .accessibilityHint("Includes computer interaction results and image URLs in responses")
                    if !ModelCompatibilityService.shared.isToolSupported("computer_use_preview", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Computer use not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isToolSupported("computer_use_preview", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Toggle("Include File Search Results", isOn: $viewModel.activePrompt.includeFileSearchResults)
                        .accessibilityHint("Includes file search metadata in responses")
                    if !ModelCompatibilityService.shared.isToolSupported("file_search", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("File search not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isToolSupported("file_search", for: viewModel.activePrompt.openAIModel))
                
                Toggle("Include Input Image URLs", isOn: $viewModel.activePrompt.includeInputImageUrls)
                    .accessibilityHint("Includes URLs of uploaded images in responses")
                
                HStack {
                    Toggle("Include Output Logprobs", isOn: $viewModel.activePrompt.includeOutputLogprobs)
                        .accessibilityHint("Includes probability scores for generated tokens")
                    if !ModelCompatibilityService.shared.isParameterSupported("top_logprobs", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Logprobs not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("top_logprobs", for: viewModel.activePrompt.openAIModel))
                
                HStack {
                    Toggle("Include Reasoning Content", isOn: $viewModel.activePrompt.includeReasoningContent)
                        .accessibilityHint("Includes encrypted reasoning tokens for stateless conversations")
                    if !ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("Reasoning content not supported by current model")
                    }
                }
                .disabled(!ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: viewModel.activePrompt.openAIModel))
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Text Formatting Section
            Section(header: Text("Text Output Formatting"), footer: Text("Configure the output format for text responses. Use JSON Schema for structured outputs.")) {
                HStack {
                    Picker("Format Type", selection: $viewModel.activePrompt.textFormatType) {
                        Text("Text").tag("text")
                        Text("JSON Schema").tag("json_schema")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint("Choose between plain text or structured JSON output")
                    if viewModel.activePrompt.textFormatType == "json_schema" && !ModelCompatibilityService.shared.isParameterSupported("response_format", for: viewModel.activePrompt.openAIModel) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .help("JSON Schema formatting may have limited support on current model")
                    }
                }
                if viewModel.activePrompt.textFormatType == "json_schema" {
                    TextField("Schema Name", text: Binding(get: { viewModel.activePrompt.jsonSchemaName }, set: { viewModel.activePrompt.jsonSchemaName = $0 }))
                        .accessibilityHint("Name for the JSON schema")
                    TextField("Schema Description", text: Binding(get: { viewModel.activePrompt.jsonSchemaDescription }, set: { viewModel.activePrompt.jsonSchemaDescription = $0 }))
                        .accessibilityHint("Description of the JSON schema purpose")
                    Toggle("Strict Schema", isOn: $viewModel.activePrompt.jsonSchemaStrict)
                        .accessibilityHint("Enforces strict adherence to the JSON schema")
                    TextEditor(text: Binding(get: { viewModel.activePrompt.jsonSchemaContent }, set: { viewModel.activePrompt.jsonSchemaContent = $0 }))
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                        .accessibilityLabel("JSON schema content")
                        .accessibilityHint("Enter the JSON schema definition")
                }
            }
            .disabled(viewModel.activePrompt.enablePublishedPrompt)
            
            // Debugging Section
            Section(header: Text("Debugging"), footer: Text("Settings for debugging and development purposes.")) {
                Toggle("Detailed Network Logging", isOn: $detailedNetworkLogging)
                    .accessibilityHint("Enables verbose logging of network requests for debugging")
                    .onChange(of: detailedNetworkLogging) { _, newValue in
                        print("Detailed network logging \(newValue ? "enabled" : "disabled")")
                    }
                
                Button("API Inspector") {
                    showingAPIInspector = true
                }
                .accessibilityHint("View raw API requests and responses for debugging")
                
                Button("Debug Console") {
                    showingDebugConsole = true
                }
                .accessibilityHint("View real-time debug logs from the app")
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
                    .accessibilityHint("Controls how detailed the reasoning summary is for O-series models")
                }
                .disabled(viewModel.activePrompt.enablePublishedPrompt)
            }
            
            Section {
                Button(role: .destructive) {
                    viewModel.clearConversation()
                } label: {
                    Text("Clear Conversation")
                }
                .accessibilityHint("Removes all messages from the current conversation")
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
        .sheet(isPresented: $showingAPIInspector) {
            APIInspectorView()
        }
        .sheet(isPresented: $showingDebugConsole) {
            DebugConsoleView()
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
