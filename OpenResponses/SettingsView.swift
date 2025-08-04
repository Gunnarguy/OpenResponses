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
    @AppStorage("openAIKey") private var apiKey: String = ""
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
    
    // Response streaming setting
    @AppStorage("enableStreaming") private var enableStreaming: Bool = true
    
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFileManager = false
    
    // Supported models list for the Picker
    private let modelOptions: [String] = ["gpt-4o", "o3", "o3-mini", "o1", "gpt-4-1106-preview"]
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API")) {
                SecureField("API Key (sk-...)", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            // System instructions section
            Section(header: Text("System Instructions"), footer: Text("Set a persistent system prompt to guide the assistant's behavior. This will be sent as the 'instructions' field in every request.")) {
                TextEditor(text: $systemInstructions)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                    .padding(.vertical, 2)
                if systemInstructions.isEmpty {
                    Text("e.g. 'You are a helpful assistant.'")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            Section(header: Text("Developer Instructions"), footer: Text("Set hidden developer instructions to fine-tune the assistant's behavior with higher priority.")) {
                TextEditor(text: $developerInstructions)
                    .frame(minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                    .padding(.vertical, 2)
                if developerInstructions.isEmpty {
                    Text("e.g. 'Always respond in Markdown.'")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            Section(header: Text("Model"), footer: Text("Reasoning effort is only available for 'o' models. Temperature is only available for other models.")) {
                Picker("Model", selection: $selectedModel) {
                    ForEach(modelOptions, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.navigationLink)  // Use a navigation link style for model selection

                // Reasoning models: O1, O3, etc.
                Picker("Reasoning Effort", selection: $reasoningEffort) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)
                .disabled(!selectedModel.starts(with: "o"))
                
                // Standard models: provide temperature slider
                VStack(alignment: .leading) {
                    Text("Temperature: \(String(format: "%.1f", temperature))")
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                }
                .disabled(selectedModel.starts(with: "o"))
            }
            
            Section(header: Text("Response Settings"), footer: Text("Adjust response generation parameters. Streaming provides real-time output.")) {
                Toggle("Enable Streaming", isOn: $enableStreaming)
                
                VStack(alignment: .leading) {
                    Text("Max Output Tokens: \(maxOutputTokens == 0 ? "Default" : String(maxOutputTokens))")
                    Slider(value: Binding(
                        get: { Double(maxOutputTokens) },
                        set: { maxOutputTokens = Int($0) }
                    ), in: 0...4096, step: 64)
                }
                
                VStack(alignment: .leading) {
                    Text("Presence Penalty: \(String(format: "%.1f", presencePenalty))")
                    Slider(value: $presencePenalty, in: -2.0...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Frequency Penalty: \(String(format: "%.1f", frequencyPenalty))")
                    Slider(value: $frequencyPenalty, in: -2.0...2.0, step: 0.1)
                }
            }
            
            Section(header: Text("Tools"), footer: Text("Configure which AI tools are available for the assistant to use. Note: Image generation is automatically disabled when streaming is enabled.")) {
                Toggle("Web Search", isOn: $enableWebSearch)
                Toggle("Code Interpreter", isOn: $enableCodeInterpreter)
                Toggle("Calculator (Custom Tool)", isOn: $enableCalculator)
                HStack {
                    Toggle("Image Generation", isOn: $enableImageGeneration)
                        .disabled(enableStreaming)
                    if enableStreaming && enableImageGeneration {
                        Text("(Disabled in streaming mode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Toggle("File Search", isOn: $enableFileSearch)
                
                if enableFileSearch {
                    Button("Manage Files & Vector Stores") {
                        showingFileManager = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            // Web Search Configuration Section
            if enableWebSearch {
                Section(header: Text("Web Search Configuration"), footer: Text("Customize how the web search tool behaves. Location settings help provide geographically relevant results.")) {
                    // Location settings
                    Picker("Location Type", selection: $webSearchLocationType) {
                        Text("Approximate").tag("approximate")
                        Text("Exact").tag("exact")
                        Text("Disabled").tag("disabled")
                    }
                    .pickerStyle(.segmented)
                    
                    if webSearchLocationType != "disabled" {
                        Picker("Timezone", selection: $webSearchTimezone) {
                            Text("Pacific (Los Angeles)").tag("America/Los_Angeles")
                            Text("Mountain (Denver)").tag("America/Denver")
                            Text("Central (Chicago)").tag("America/Chicago")
                            Text("Eastern (New York)").tag("America/New_York")
                            Text("UTC").tag("UTC")
                            Text("London").tag("Europe/London")
                            Text("Tokyo").tag("Asia/Tokyo")
                            Text("Sydney").tag("Australia/Sydney")
                        }
                        .pickerStyle(.navigationLink)
                        
                        if webSearchLocationType == "exact" {
                            VStack(alignment: .leading) {
                                Text("Latitude: \(String(format: "%.4f", webSearchLatitude))")
                                Slider(value: $webSearchLatitude, in: -90...90, step: 0.1)
                                
                                Text("Longitude: \(String(format: "%.4f", webSearchLongitude))")
                                Slider(value: $webSearchLongitude, in: -180...180, step: 0.1)
                            }
                        }
                    }
                    
                    // Search context and quality settings
                    Picker("Search Context Size", selection: $webSearchContextSize) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    
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
                    .pickerStyle(.navigationLink)
                    
                    Picker("Region", selection: $webSearchRegion) {
                        Text("United States").tag("us")
                        Text("Canada").tag("ca")
                        Text("United Kingdom").tag("uk")
                        Text("Germany").tag("de")
                        Text("France").tag("fr")
                        Text("Japan").tag("jp")
                        Text("Australia").tag("au")
                        Text("Global").tag("wt")
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Advanced settings
                    VStack(alignment: .leading) {
                        Text("Max Results: \(webSearchMaxResults)")
                        Slider(value: Binding(
                            get: { Double(webSearchMaxResults) },
                            set: { webSearchMaxResults = Int($0) }
                        ), in: 5...50, step: 5)
                    }
                    
                    Picker("Safe Search", selection: $webSearchSafeSearch) {
                        Text("Strict").tag("strict")
                        Text("Moderate").tag("moderate")
                        Text("Off").tag("off")
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Recency Filter", selection: $webSearchRecency) {
                        Text("Auto").tag("auto")
                        Text("Recent (24h)").tag("day")
                        Text("This Week").tag("week")
                        Text("This Month").tag("month")
                        Text("This Year").tag("year")
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            
            // Advanced Web Search Location Section
            if enableWebSearch {
                Section(header: Text("Advanced Web Search Location"), footer: Text("Optionally specify city, country, and region for more precise web search relevance.")) {
                    TextField("City", text: $webSearchCity)
                    TextField("Country (ISO code, e.g. US)", text: $webSearchCountry)
                    TextField("Region (e.g. California)", text: $webSearchLocationRegion)
                }
            }
            
            // Advanced API Settings Section
            Section(header: Text("Advanced API Settings"), footer: Text("These options provide fine-grained control over the OpenAI Responses API. Defaults are recommended for most users.")) {
                Toggle("Background Mode", isOn: $backgroundMode)
                Stepper("Max Tool Calls: \(maxToolCalls)", value: $maxToolCalls, in: 0...20)
                Toggle("Parallel Tool Calls", isOn: $parallelToolCalls)
                Picker("Service Tier", selection: $serviceTier) {
                    Text("Auto").tag("auto")
                    Text("Default").tag("default")
                    Text("Flex").tag("flex")
                    Text("Priority").tag("priority")
                }
                .pickerStyle(.segmented)
                Stepper("Top Logprobs: \(topLogprobs)", value: $topLogprobs, in: 0...20)
                Slider(value: $topP, in: 0.0...1.0, step: 0.01) {
                    Text("Top P")
                } minimumValueLabel: {
                    Text("0.0")
                } maximumValueLabel: {
                    Text("1.0")
                }
                Text("Top P: \(String(format: "%.2f", topP))")
                Picker("Truncation", selection: $truncationStrategy) {
                    Text("Disabled").tag("disabled")
                    Text("Auto").tag("auto")
                }
                .pickerStyle(.segmented)
                TextField("User Identifier", text: $userIdentifier)
            }
            
            // Advanced Include Section
            Section(header: Text("API Response Includes"), footer: Text("Select which extra data to include in the API response. Note: Reasoning content cannot be included when conversation persistence is enabled.")) {
                Toggle("Include Code Interpreter Outputs", isOn: $includeCodeInterpreterOutputs)
                Toggle("Include File Search Results", isOn: $includeFileSearchResults)
                Toggle("Include Input Image URLs", isOn: $includeInputImageUrls)
                Toggle("Include Output Logprobs", isOn: $includeOutputLogprobs)
                Toggle("Include Reasoning Content", isOn: $includeReasoningContent)
                    .disabled(true) // Disabled because it conflicts with store: true (conversation persistence)
                    .foregroundColor(.secondary)
            }
            
            // Text Formatting Section
            Section(header: Text("Text Output Formatting"), footer: Text("Configure the output format for text responses. Use JSON Schema for structured outputs.")) {
                Picker("Format Type", selection: $textFormatType) {
                    Text("Text").tag("text")
                    Text("JSON Schema").tag("json_schema")
                }
                .pickerStyle(.segmented)
                if textFormatType == "json_schema" {
                    TextField("Schema Name", text: $jsonSchemaName)
                    TextField("Schema Description", text: $jsonSchemaDescription)
                    Toggle("Strict Schema", isOn: $jsonSchemaStrict)
                    TextEditor(text: $jsonSchemaContent)
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            
            // Advanced Reasoning Section
            if selectedModel.starts(with: "o") {
                Section(header: Text("Advanced Reasoning"), footer: Text("Configure summary output for reasoning models.")) {
                    Picker("Reasoning Summary", selection: $reasoningSummary) {
                        Text("Auto").tag("auto")
                        Text("Concise").tag("concise")
                        Text("Detailed").tag("detailed")
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // Image Generation Section
            if enableImageGeneration {
                Section(header: Text("Image Generation Settings"), footer: Text("Advanced options for image generation tool.")) {
                    Picker("Size", selection: $imageGenerationSize) {
                        Text("Auto").tag("auto")
                        Text("1024x1024").tag("1024x1024")
                        Text("1024x1536").tag("1024x1536")
                        Text("1536x1024").tag("1536x1024")
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Quality", selection: $imageGenerationQuality) {
                        Text("Auto").tag("auto")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    Picker("Background", selection: $imageGenerationBackground) {
                        Text("Auto").tag("auto")
                        Text("Transparent").tag("transparent")
                        Text("Opaque").tag("opaque")
                    }
                    .pickerStyle(.segmented)
                    Picker("Output Format", selection: $imageGenerationOutputFormat) {
                        Text("PNG").tag("png")
                        Text("WEBP").tag("webp")
                        Text("JPEG").tag("jpeg")
                    }
                    .pickerStyle(.segmented)
                    Picker("Moderation", selection: $imageGenerationModeration) {
                        Text("Auto").tag("auto")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                    Stepper("Partial Images: \(imageGenerationPartialImages)", value: $imageGenerationPartialImages, in: 0...3)
                    Stepper("Output Compression: \(imageGenerationOutputCompression)", value: $imageGenerationOutputCompression, in: 0...100)
                }
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
            // Set default values if not already set
            setDefaultToolSettings()
        }
        .onChange(of: selectedModel) { _, _ in
            // If model changes, clear conversation to avoid cross-model threading issues
            viewModel.clearConversation()
        }
        .sheet(isPresented: $showingFileManager) {
            FileManagerView()
        }
    }
    
    /// Sets default values for tool settings if they haven't been configured yet
    private func setDefaultToolSettings() {
        // Check if these keys exist, if not set defaults
        if UserDefaults.standard.object(forKey: "enableWebSearch") == nil {
            UserDefaults.standard.set(true, forKey: "enableWebSearch")
        }
        if UserDefaults.standard.object(forKey: "enableCodeInterpreter") == nil {
            UserDefaults.standard.set(true, forKey: "enableCodeInterpreter")
        }
        if UserDefaults.standard.object(forKey: "enableImageGeneration") == nil {
            UserDefaults.standard.set(true, forKey: "enableImageGeneration")
        }
        if UserDefaults.standard.object(forKey: "enableFileSearch") == nil {
            UserDefaults.standard.set(false, forKey: "enableFileSearch")
        }
        if UserDefaults.standard.object(forKey: "enableStreaming") == nil {
            UserDefaults.standard.set(true, forKey: "enableStreaming")
        }
        
        // Set defaults for web search configuration
        if UserDefaults.standard.object(forKey: "webSearchLocationType") == nil {
            UserDefaults.standard.set("approximate", forKey: "webSearchLocationType")
        }
        if UserDefaults.standard.object(forKey: "webSearchTimezone") == nil {
            UserDefaults.standard.set("America/Los_Angeles", forKey: "webSearchTimezone")
        }
        if UserDefaults.standard.object(forKey: "webSearchContextSize") == nil {
            UserDefaults.standard.set("high", forKey: "webSearchContextSize")
        }
        if UserDefaults.standard.object(forKey: "webSearchLanguage") == nil {
            UserDefaults.standard.set("en", forKey: "webSearchLanguage")
        }
        if UserDefaults.standard.object(forKey: "webSearchRegion") == nil {
            UserDefaults.standard.set("us", forKey: "webSearchRegion")
        }
        if UserDefaults.standard.object(forKey: "webSearchMaxResults") == nil {
            UserDefaults.standard.set(10, forKey: "webSearchMaxResults")
        }
        if UserDefaults.standard.object(forKey: "webSearchSafeSearch") == nil {
            UserDefaults.standard.set("moderate", forKey: "webSearchSafeSearch")
        }
        if UserDefaults.standard.object(forKey: "webSearchRecency") == nil {
            UserDefaults.standard.set("auto", forKey: "webSearchRecency")
        }
        if UserDefaults.standard.object(forKey: "webSearchLatitude") == nil {
            UserDefaults.standard.set(37.7749, forKey: "webSearchLatitude") // San Francisco
        }
        if UserDefaults.standard.object(forKey: "webSearchLongitude") == nil {
            UserDefaults.standard.set(-122.4194, forKey: "webSearchLongitude") // San Francisco
        }
    }
    
    /// Provides a recommendation on whether streaming should be enabled based on current tool selection
    /// - Returns: A tuple with (shouldStream: Bool, reason: String?)
    private func getStreamingRecommendation() -> (shouldStream: Bool, reason: String?) {
        // If image generation is enabled, recommend disabling streaming
        if enableImageGeneration {
            return (false, "Image generation works better without streaming")
        }
        
        // For most other cases, streaming is beneficial
        return (true, nil)
    }
}
