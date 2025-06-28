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
    
    // Tool configuration settings
    @AppStorage("enableWebSearch") private var enableWebSearch: Bool = true
    @AppStorage("enableCodeInterpreter") private var enableCodeInterpreter: Bool = true
    @AppStorage("enableImageGeneration") private var enableImageGeneration: Bool = true
    
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Supported models list for the Picker
    private let modelOptions: [String] = ["gpt-4o", "o3", "o3-mini", "o1"]
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API")) {
                SecureField("API Key (sk-...)", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
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
            
            Section(header: Text("Tools"), footer: Text("Configure which AI tools are available for the assistant to use.")) {
                Toggle("Web Search", isOn: $enableWebSearch)
                Toggle("Code Interpreter", isOn: $enableCodeInterpreter)
                Toggle("Image Generation", isOn: $enableImageGeneration)
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
        .onChange(of: selectedModel) { newModel in
            // If model changes, clear conversation to avoid cross-model threading issues
            viewModel.clearConversation()
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
    }
}
