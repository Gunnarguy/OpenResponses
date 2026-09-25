import SwiftUI

struct ModernResponseSettings: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @AppStorage("realtime_model") private var voiceModel: String = CurrentModelCatalog.realtimeModel
    @State private var showingVoiceSettings = false

    private var modern: Bool { CurrentModelCatalog.isModern(viewModel.activePrompt.openAIModel) }

    var body: some View {
        Section("Current Responses capabilities") {
            if modern {
                Picker("Reasoning context", selection: $viewModel.activePrompt.currentOptions.reasoningContext) {
                    Text("Model default").tag("auto")
                    Text("Current turn").tag("current_turn")
                    Text("All turns").tag("all_turns")
                }
                if CurrentModelCatalog.supportsPro(viewModel.activePrompt.openAIModel) {
                    Picker("Reasoning mode", selection: $viewModel.activePrompt.currentOptions.reasoningMode) {
                        Text("Standard").tag("standard")
                        Text("Pro · more compute").tag("pro")
                    }
                }
                Toggle("Automatic context compaction", isOn: $viewModel.activePrompt.currentOptions.automaticCompaction)
                if viewModel.activePrompt.currentOptions.automaticCompaction {
                    Stepper("Compact at \(viewModel.activePrompt.currentOptions.compactThreshold.formatted()) tokens",
                            value: $viewModel.activePrompt.currentOptions.compactThreshold, in: 10_000...250_000, step: 10_000)
                }
                Toggle("Load tools on demand", isOn: $viewModel.activePrompt.currentOptions.toolSearch)
                Toggle("Hosted shell", isOn: $viewModel.activePrompt.currentOptions.hostedShell)
                Group {
                    Toggle("Async lookups", isOn: $viewModel.activePrompt.currentOptions.asyncTools)
                        .disabled(!CurrentModelCatalog.supportsAsyncTools(viewModel.activePrompt.openAIModel))
                    Toggle("Programmatic tool calling", isOn: $viewModel.activePrompt.currentOptions.programmaticTools)
                    Toggle("Multi-agent beta", isOn: $viewModel.activePrompt.currentOptions.multiAgent)
                    if viewModel.activePrompt.currentOptions.multiAgent {
                        Stepper("Up to \(viewModel.activePrompt.currentOptions.maxSubagents) active subagents", value: $viewModel.activePrompt.currentOptions.maxSubagents, in: 1...8)
                    }
                    Stepper("\(viewModel.activePrompt.currentOptions.multiAgent ? "Client tool calls" : "Tool rounds"): \(viewModel.activePrompt.currentOptions.maxToolRounds)", value: $viewModel.activePrompt.currentOptions.maxToolRounds, in: 1...32)
                }
                .disabled(viewModel.activePrompt.enableComputerUse || viewModel.activePrompt.backgroundMode)
                Text("Async and programmatic execution apply to supported read-only lookups. Writes execute one at a time. Subagents share enabled tools and can increase token usage. Multi-agent runs use WebSocket and return each tool result as it finishes. These options apply to foreground requests with Computer Use turned off.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Tool search defers function and MCP schemas until needed. Shell commands run in an OpenAI container. Pro mode uses more tokens; all-turn reasoning reuses compatible prior reasoning.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Choose a GPT-6 or GPT-5.6 model for these capabilities.").foregroundStyle(.secondary)
            }
            NavigationLink("API Workbench") { APIWorkbenchView() }
        }
        Section("Image generation") {
            Picker("Image model", selection: $viewModel.activePrompt.imageGenerationModel) {
                ForEach(CurrentModelCatalog.imageModels, id: \.self) { model in
                    Text(CurrentModelCatalog.imageModelName(model)).tag(model)
                }
                if !CurrentModelCatalog.imageModels.contains(viewModel.activePrompt.imageGenerationModel) {
                    Text(CurrentModelCatalog.imageModelName(viewModel.activePrompt.imageGenerationModel)).tag(viewModel.activePrompt.imageGenerationModel)
                }
            }
            Picker("Action", selection: $viewModel.activePrompt.currentOptions.imageAction) {
                Text("Automatic").tag("auto")
                Text("Generate").tag("generate")
                Text("Edit").tag("edit")
            }
            Stepper("Partial previews: \(viewModel.activePrompt.currentOptions.partialImages)",
                    value: $viewModel.activePrompt.currentOptions.partialImages, in: 0...3)
            Text("Transparent backgrounds use PNG or WebP. JPEG requests with transparency are sent as PNG.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
        .onChange(of: viewModel.activePrompt.imageGenerationModel) { _, model in
            viewModel.activePrompt.imageGenerationQuality = CurrentModelCatalog.normalizedImageQuality(viewModel.activePrompt.imageGenerationQuality, model: model)
            viewModel.saveActivePrompt()
        }
        Section {
            Picker("Moderation", selection: $viewModel.activePrompt.currentOptions.moderationModel) {
                Text("Off").tag("")
                Text("omni-moderation-latest").tag("omni-moderation-latest")
            }
            if !viewModel.activePrompt.currentOptions.moderationModel.isEmpty {
                Picker("Input policy", selection: $viewModel.activePrompt.currentOptions.moderationInputMode) {
                    Text("Score").tag("score")
                    Text("Block").tag("block")
                }
                Picker("Output policy", selection: $viewModel.activePrompt.currentOptions.moderationOutputMode) {
                    Text("Score").tag("score")
                    Text("Block").tag("block")
                }
            }
        } header: { Text("Response moderation") } footer: {
            Text("OpenAI moderates this response's input and output. Score reports flagged categories; Block stops a flagged response.")
        }
        Section("Hosted tool options") {
            Toggle("Web search: live web access", isOn: $viewModel.activePrompt.currentOptions.webSearchExternalAccess)
            Picker("Code Interpreter memory", selection: $viewModel.activePrompt.currentOptions.codeInterpreterMemoryLimit) {
                Text("Default").tag("")
                ForEach(["1g", "4g", "16g", "64g"], id: \.self) { Text($0.uppercased().replacingOccurrences(of: "G", with: " GB")).tag($0) }
            }
            Toggle("File search: hybrid ranking", isOn: Binding(
                get: { viewModel.activePrompt.currentOptions.hybridEmbeddingWeight != nil },
                set: { enabled in
                    viewModel.activePrompt.currentOptions.hybridEmbeddingWeight = enabled ? 0.5 : nil
                    viewModel.activePrompt.currentOptions.hybridTextWeight = enabled ? 0.5 : nil
                }))
            if let embedding = viewModel.activePrompt.currentOptions.hybridEmbeddingWeight {
                Slider(value: Binding(get: { embedding }, set: {
                    viewModel.activePrompt.currentOptions.hybridEmbeddingWeight = $0
                    viewModel.activePrompt.currentOptions.hybridTextWeight = 1 - $0
                }), in: 0...1, step: 0.1) { Text("Semantic weight") }
                Text("Semantic \(Int(embedding * 100))% · keyword \(100 - Int(embedding * 100))%").font(.caption).foregroundStyle(.secondary)
            }
            Picker("Image input fidelity", selection: $viewModel.activePrompt.currentOptions.imageInputFidelity) {
                Text("Model default").tag("")
                Text("High").tag("high")
                Text("Low").tag("low")
            }
            Stepper("JPEG/WebP compression: \(viewModel.activePrompt.currentOptions.imageOutputCompression.map { "\($0)" } ?? "default")",
                    value: Binding(get: { viewModel.activePrompt.currentOptions.imageOutputCompression ?? 100 },
                                   set: { viewModel.activePrompt.currentOptions.imageOutputCompression = $0 == 100 ? nil : $0 }),
                    in: 0...100, step: 5)
        }
        Section {
            Button {
                showingVoiceSettings = true
            } label: {
                LabeledContent("Voice model, voice and instructions", value: CurrentModelCatalog.supportedRealtimeModel(voiceModel))
            }
        } header: { Text("Voice") } footer: {
            Text("GPT Realtime 2.1 and its mini variant use the Realtime API; GPT-Live 1 uses the Live API. Changes apply to the next voice session.")
        }
        .sheet(isPresented: $showingVoiceSettings) { VoiceModeSettingsSheet() }
        Section("Custom tool") {
            Toggle("Enable custom tool", isOn: $viewModel.activePrompt.enableCustomTool)
            if viewModel.activePrompt.enableCustomTool {
                TextField("Tool name", text: $viewModel.activePrompt.customToolName).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("What the tool does", text: $viewModel.activePrompt.customToolDescription, axis: .vertical)
                if modern {
                    Picker("Input format", selection: $viewModel.activePrompt.currentOptions.customToolFormat) {
                        Text("JSON function").tag("function")
                        Text("Free-form text").tag("text")
                    }
                    .disabled(viewModel.activePrompt.enableComputerUse || viewModel.activePrompt.backgroundMode)
                }
                if viewModel.activePrompt.currentOptions.customToolFormat != "text" || !modern {
                    Text("Parameters schema").font(.caption).foregroundStyle(.secondary)
                    JSONCodeEditor(text: $viewModel.activePrompt.customToolParametersJSON, label: "Function parameters JSON").font(.system(.caption, design: .monospaced)).frame(minHeight: 120)
                }
                Picker("Execution", selection: $viewModel.activePrompt.customToolExecutionType) {
                    Text("Echo input").tag("echo")
                    Text("Calculator").tag("calculator")
                    Text("Webhook").tag("webhook")
                }
                if viewModel.activePrompt.customToolExecutionType == "webhook" {
                    TextField("Webhook URL", text: $viewModel.activePrompt.customToolWebhookURL).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("Posts the tool input to this URL. Free-form text is sent as a JSON object with an input field. Webhooks run directly and are excluded from async/programmatic execution.").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Echo and calculator run locally. Calculator accepts an expression field for JSON functions, or an arithmetic expression for text tools.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: viewModel.activePrompt.currentOptions.asyncTools) { _, enabled in
            if enabled { viewModel.activePrompt.currentOptions.programmaticTools = false }
            viewModel.saveActivePrompt()
        }
        .onChange(of: viewModel.activePrompt.currentOptions.programmaticTools) { _, enabled in
            if enabled { viewModel.activePrompt.currentOptions.asyncTools = false }
            viewModel.saveActivePrompt()
        }
        .onDisappear { viewModel.saveActivePrompt() }
    }
}
