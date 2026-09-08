import SwiftUI

struct ModernResponseSettings: View {
    @EnvironmentObject private var viewModel: ChatViewModel

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
                        .disabled(CurrentModelCatalog.family(viewModel.activePrompt.openAIModel) != "gpt-6-astra")
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
                Text("Choose Astra or a GPT-5.6 model for these capabilities.").foregroundStyle(.secondary)
            }
            NavigationLink("API Workbench") { APIWorkbenchView() }
        }
        Section("Image generation") {
            Picker("Image model", selection: $viewModel.activePrompt.imageGenerationModel) {
                Text("GPT Image 2").tag("gpt-image-2")
                if viewModel.activePrompt.imageGenerationModel != "gpt-image-2" {
                    Text("\(viewModel.activePrompt.imageGenerationModel) · older model").tag(viewModel.activePrompt.imageGenerationModel)
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
        .onChange(of: viewModel.activePrompt.imageGenerationModel) { _, _ in viewModel.saveActivePrompt() }
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
