import SwiftUI

// The Responses API options from `ModernResponseOptions` (`Prompt.currentOptions`). Until 3.1 they all sat in one
// "Current Responses capabilities" section at the bottom of Settings → Model, under the model card, which is where
// Local Python, hosted shell, multi-agent and the API Workbench went unseen. Each group now sits on the page whose
// name a person would look under; SettingsHomeView places them.

/// True when the selected model accepts the GPT-6 and GPT-5.6 options.
@MainActor
private func isModern(_ viewModel: ChatViewModel) -> Bool {
    CurrentModelCatalog.isModern(viewModel.activePrompt.openAIModel)
}

/// Reasoning context and Pro mode. Settings → Model & Reasoning.
struct ReasoningOptionsSection: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        if isModern(viewModel) {
            Section {
                Picker("Reuse earlier reasoning", selection: $viewModel.activePrompt.currentOptions.reasoningContext) {
                    Text("Model default").tag("auto")
                    Text("This turn only").tag("current_turn")
                    Text("All turns").tag("all_turns")
                }
                if CurrentModelCatalog.supportsPro(viewModel.activePrompt.openAIModel) {
                    Picker("Reasoning mode", selection: $viewModel.activePrompt.currentOptions.reasoningMode) {
                        Text("Standard").tag("standard")
                        Text("Pro · more compute").tag("pro")
                    }
                }
            } header: {
                Text("Advanced reasoning")
            } footer: {
                Text("All turns lets the model build on its earlier thinking in this chat. Pro mode thinks harder and uses more tokens.")
            }
            .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
        }
    }
}

/// Automatic context compaction. Settings → Response Format.
struct CompactionSection: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Section {
            Toggle("Stream responses", isOn: $viewModel.activePrompt.enableStreaming)
            Picker("When the chat gets too long", selection: $viewModel.activePrompt.truncationStrategy) {
                Text("Stop with an error").tag("disabled")
                Text("Drop the oldest messages").tag("auto")
            }
            if isModern(viewModel) {
                Toggle("Compact long chats automatically", isOn: $viewModel.activePrompt.currentOptions.automaticCompaction)
                if viewModel.activePrompt.currentOptions.automaticCompaction {
                    Stepper("Compact at \(viewModel.activePrompt.currentOptions.compactThreshold.formatted()) tokens",
                            value: $viewModel.activePrompt.currentOptions.compactThreshold, in: 10_000...250_000, step: 10_000)
                }
            }
        } header: {
            Text("Delivery and long chats")
        } footer: {
            Text("Streaming shows the answer as it is written. Compaction condenses earlier messages so a long chat keeps going.")
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
    }
}

/// Hosted shell and Local Python, the two code-running tools besides Code Interpreter. Settings → Tools.
struct CodeRunningToolsSection: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Section {
            if isModern(viewModel) {
                Toggle(isOn: $viewModel.activePrompt.currentOptions.localPython) {
                    SettingsToggleLabel("Local Python", icon: "apple.terminal", tint: .green,
                                        detail: "Runs Python the model writes on this iPhone, after you approve each run. Standard library only, no network, no files.")
                }
                Toggle(isOn: $viewModel.activePrompt.currentOptions.hostedShell) {
                    SettingsToggleLabel("Hosted shell", icon: "terminal.fill", tint: .gray,
                                        detail: "Lets the model run shell commands in an OpenAI container.")
                }
            } else {
                Text("Local Python and the hosted shell need a GPT-6 or GPT-5.6 model. Choose one in Model & Reasoning.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Local Python works offline on this iPhone. The hosted shell and Code Interpreter run on OpenAI's servers.")
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
    }
}

/// How the model calls tools: choice, parallel calls, limits, tool search, async and programmatic calls,
/// multi-agent and background mode. Settings → Agents & Tool Calling.
struct AgentOptionsSections: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Section {
            Picker("Use tools", selection: $viewModel.activePrompt.toolChoice) {
                Text("When useful").tag("auto")
                Text("Always").tag("required")
                Text("Never").tag("none")
            }
            Toggle("Call several tools at once", isOn: $viewModel.activePrompt.parallelToolCalls)
            Toggle("Limit tool calls", isOn: Binding(
                get: { viewModel.activePrompt.maxToolCalls > 0 },
                set: { viewModel.activePrompt.maxToolCalls = $0 ? 4 : 0 }
            ))
            if viewModel.activePrompt.maxToolCalls > 0 {
                Stepper("At most \(viewModel.activePrompt.maxToolCalls) per answer",
                        value: Binding(
                            get: { max(viewModel.activePrompt.maxToolCalls, 1) },
                            set: { viewModel.activePrompt.maxToolCalls = max(min($0, 32), 1) }
                        ),
                        in: 1...32)
            }
        } header: {
            Text("Tool calling")
        } footer: {
            Text("Always makes the model call a tool before it answers. Never answers from the model alone.")
        }

        if isModern(viewModel) {
            Section {
                Toggle(isOn: $viewModel.activePrompt.currentOptions.multiAgent) {
                    SettingsToggleLabel("Multi-agent", icon: "person.3.fill", tint: .purple,
                                        detail: "The model can start helper agents that work in parallel and share your enabled tools. Beta; uses more tokens.")
                }
                if viewModel.activePrompt.currentOptions.multiAgent {
                    Stepper("Up to \(viewModel.activePrompt.currentOptions.maxSubagents) helpers at once",
                            value: $viewModel.activePrompt.currentOptions.maxSubagents, in: 1...8)
                }
                Toggle(isOn: $viewModel.activePrompt.currentOptions.toolSearch) {
                    SettingsToggleLabel("Load tools on demand", icon: "magnifyingglass", tint: .blue,
                                        detail: "Sends function and MCP tool definitions only when the model needs them, which saves tokens with many tools.")
                }
                Toggle(isOn: $viewModel.activePrompt.currentOptions.asyncTools) {
                    SettingsToggleLabel("Async lookups", icon: "arrow.triangle.branch", tint: .teal,
                                        detail: "Read-only lookups run in the background while the model keeps going.")
                }
                .disabled(!CurrentModelCatalog.supportsAsyncTools(viewModel.activePrompt.openAIModel))
                Toggle(isOn: $viewModel.activePrompt.currentOptions.programmaticTools) {
                    SettingsToggleLabel("Programmatic tool calling", icon: "curlybraces", tint: .orange,
                                        detail: "The model writes code that calls several read-only tools in one step.")
                }
                Stepper("\(viewModel.activePrompt.currentOptions.multiAgent ? "Client tool calls" : "Tool rounds"): \(viewModel.activePrompt.currentOptions.maxToolRounds)",
                        value: $viewModel.activePrompt.currentOptions.maxToolRounds, in: 1...32)
            } header: {
                Text("Agents")
            } footer: {
                Text("These apply to foreground requests with Computer Use and Background Mode off. Async and programmatic calls cover read-only lookups; writes run one at a time.")
            }
            .disabled(viewModel.activePrompt.enableComputerUse || viewModel.activePrompt.backgroundMode)
        }

        Section {
            Toggle(isOn: Binding(
                get: { viewModel.activePrompt.backgroundMode },
                set: { newValue in
                    if newValue {
                        viewModel.activePrompt.storeResponses = true
                        viewModel.applyDraftStorePreference(true)
                    }
                    viewModel.activePrompt.backgroundMode = newValue
                }
            )) {
                SettingsToggleLabel("Background mode", icon: "moon.zzz.fill", tint: .indigo,
                                    detail: "Long tasks keep running on OpenAI's servers if you leave the app. Turns on Store on OpenAI.")
            }
        } header: {
            Text("Long tasks")
        }
        .onChange(of: viewModel.activePrompt.currentOptions.asyncTools) { _, enabled in
            if enabled { viewModel.activePrompt.currentOptions.programmaticTools = false }
            viewModel.saveActivePrompt()
        }
        .onChange(of: viewModel.activePrompt.currentOptions.programmaticTools) { _, enabled in
            if enabled { viewModel.activePrompt.currentOptions.asyncTools = false }
            viewModel.saveActivePrompt()
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
    }
}

/// Image model, action, previews, input fidelity and compression. Settings → Tools → Image Generation.
struct ImageGenerationOptionsRows: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Picker("Image model", selection: $viewModel.activePrompt.imageGenerationModel) {
            ForEach(CurrentModelCatalog.imageModels, id: \.self) { model in
                Text(CurrentModelCatalog.imageModelName(model)).tag(model)
            }
            if !CurrentModelCatalog.imageModels.contains(viewModel.activePrompt.imageGenerationModel) {
                Text(CurrentModelCatalog.imageModelName(viewModel.activePrompt.imageGenerationModel)).tag(viewModel.activePrompt.imageGenerationModel)
            }
        }
        Picker("Size", selection: $viewModel.activePrompt.imageGenerationSize) {
            Text("Automatic").tag("auto")
            Text("Square 1024×1024").tag("1024x1024")
            Text("Portrait 1024×1536").tag("1024x1536")
            Text("Landscape 1536×1024").tag("1536x1024")
        }
        let qualities = CurrentModelCatalog.imageQualities(for: viewModel.activePrompt.imageGenerationModel)
        Picker("Quality", selection: $viewModel.activePrompt.imageGenerationQuality) {
            ForEach(qualities, id: \.self) { quality in
                Text(quality == "xhigh" ? "X-High" : quality.capitalized).tag(quality)
            }
            if !qualities.contains(viewModel.activePrompt.imageGenerationQuality) {
                Text(viewModel.activePrompt.imageGenerationQuality).tag(viewModel.activePrompt.imageGenerationQuality)
            }
        }
        Picker("Action", selection: $viewModel.activePrompt.currentOptions.imageAction) {
            Text("Automatic").tag("auto")
            Text("Always generate").tag("generate")
            Text("Edit the attached image").tag("edit")
        }
        Stepper("Previews while drawing: \(viewModel.activePrompt.currentOptions.partialImages)",
                value: $viewModel.activePrompt.currentOptions.partialImages, in: 0...3)
        Picker("Detail read from your images", selection: $viewModel.activePrompt.currentOptions.imageInputFidelity) {
            Text("Model default").tag("")
            Text("High").tag("high")
            Text("Low").tag("low")
        }
        Stepper("JPEG/WebP compression: \(viewModel.activePrompt.currentOptions.imageOutputCompression.map { "\($0)" } ?? "default")",
                value: Binding(get: { viewModel.activePrompt.currentOptions.imageOutputCompression ?? 100 },
                               set: { viewModel.activePrompt.currentOptions.imageOutputCompression = $0 == 100 ? nil : $0 }),
                in: 0...100, step: 5)
            .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
            .onChange(of: viewModel.activePrompt.imageGenerationModel) { _, model in
                viewModel.activePrompt.imageGenerationQuality = CurrentModelCatalog.normalizedImageQuality(viewModel.activePrompt.imageGenerationQuality, model: model)
                viewModel.saveActivePrompt()
            }
    }
}

/// Response moderation. Settings → Privacy & Safety.
struct ModerationSection: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        Section {
            Picker("Moderation", selection: $viewModel.activePrompt.currentOptions.moderationModel) {
                Text("Off").tag("")
                Text("omni-moderation-latest").tag("omni-moderation-latest")
            }
            if !viewModel.activePrompt.currentOptions.moderationModel.isEmpty {
                Picker("Your message", selection: $viewModel.activePrompt.currentOptions.moderationInputMode) {
                    Text("Report only").tag("score")
                    Text("Block if flagged").tag("block")
                }
                Picker("The answer", selection: $viewModel.activePrompt.currentOptions.moderationOutputMode) {
                    Text("Report only").tag("score")
                    Text("Block if flagged").tag("block")
                }
            }
        } header: {
            Text("Content moderation")
        } footer: {
            Text("OpenAI checks each message and answer. Report only lists flagged categories; Block stops a flagged response.")
        }
        .onChange(of: viewModel.activePrompt.modernOptions) { _, _ in viewModel.saveActivePrompt() }
    }
}

/// The custom function tool. Settings → Tools → Custom Tool.
struct CustomToolSections: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        let modern = isModern(viewModel)
        Section {
            Toggle("Enable custom tool", isOn: $viewModel.activePrompt.enableCustomTool)
        } footer: {
            Text("Give the model one tool of your own: it echoes its input, does arithmetic, or posts to your webhook.")
        }
        if viewModel.activePrompt.enableCustomTool {
            Section("Definition") {
                TextField("Tool name", text: $viewModel.activePrompt.customToolName).platformCapitalization(.never).autocorrectionDisabled()
                TextField("What the tool does", text: $viewModel.activePrompt.customToolDescription, axis: .vertical)
                if modern {
                    Picker("Input format", selection: $viewModel.activePrompt.currentOptions.customToolFormat) {
                        Text("JSON function").tag("function")
                        Text("Free-form text").tag("text")
                    }
                    .disabled(viewModel.activePrompt.enableComputerUse || viewModel.activePrompt.backgroundMode)
                }
            }
            if viewModel.activePrompt.currentOptions.customToolFormat != "text" || !modern {
                Section("Parameters schema") {
                    JSONCodeEditor(text: $viewModel.activePrompt.customToolParametersJSON, label: "Function parameters JSON")
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 140)
                }
            }
            Section {
                Picker("When called", selection: $viewModel.activePrompt.customToolExecutionType) {
                    Text("Echo the input").tag("echo")
                    Text("Calculate").tag("calculator")
                    Text("Post to a webhook").tag("webhook")
                }
                if viewModel.activePrompt.customToolExecutionType == "webhook" {
                    TextField("Webhook URL", text: $viewModel.activePrompt.customToolWebhookURL).platformKeyboard(.url).platformCapitalization(.never).autocorrectionDisabled()
                }
            } header: {
                Text("Execution")
            } footer: {
                if viewModel.activePrompt.customToolExecutionType == "webhook" {
                    Text("Posts the tool input to this URL. Free-form text is sent as a JSON object with an input field. Webhooks are excluded from async and programmatic calls.")
                } else {
                    Text("Echo and Calculate run on this device. Calculate accepts an expression field for JSON functions, or an arithmetic expression for text tools.")
                }
            }
        }
    }
}

/// A toggle label with a colored icon tile, a name and one line saying what the setting does.
struct SettingsToggleLabel: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color
    let detail: LocalizedStringKey?

    init(_ title: LocalizedStringKey, icon: String, tint: Color, detail: LocalizedStringKey? = nil) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.detail = detail
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // The tile is decoration; at the accessibility text sizes its width is better spent on the words.
            if !dynamicTypeSize.isAccessibilitySize {
                SettingsIconTile(icon: icon, tint: tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.accessibleSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// The rounded colored square behind a Settings symbol, as in the system Settings app.
struct SettingsIconTile: View {
    let icon: String
    let tint: Color
    #if os(macOS)
    /// System Settings on the Mac draws its sidebar tiles at about 20 points.
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 20
    #else
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 29
    #endif

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}
