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
    
    // Tool configuration settings
    @AppStorage("enableWebSearch") private var enableWebSearch: Bool = true
    @AppStorage("enableCodeInterpreter") private var enableCodeInterpreter: Bool = true
    @AppStorage("enableImageGeneration") private var enableImageGeneration: Bool = true
    @AppStorage("enableFileSearch") private var enableFileSearch: Bool = false
    
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
            
            Section(header: Text("Response Settings"), footer: Text("Streaming shows responses as they're generated, providing a more interactive experience. Disable streaming when using image generation or when you prefer to receive complete responses at once.")) {
                Toggle("Enable Streaming", isOn: $enableStreaming)
            }
            
            Section(header: Text("Tools"), footer: Text("Configure which AI tools are available for the assistant to use. Note: Image generation is automatically disabled when streaming is enabled.")) {
                Toggle("Web Search", isOn: $enableWebSearch)
                Toggle("Code Interpreter", isOn: $enableCodeInterpreter)
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
