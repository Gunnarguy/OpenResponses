//
//  ModelConfigurationView.swift
//  OpenResponses
//
//  The model, instruction and response-shape controls, as Form sections. Settings shows each part on its own page
//  (Model & Reasoning, Instructions, Response Format) instead of one long card, so each control sits under a name a
//  person would look for.
//

import SwiftUI

struct ModelConfigurationView: View {
    enum Part {
        /// Model picker, reasoning effort and summary, verbosity, temperature and top P.
        case model
        /// System and developer instructions.
        case instructions
        /// Text or JSON schema output and the response length limit.
        case responseFormat
    }

    @Binding var activePrompt: Prompt
    let openAIService: any OpenAIServiceProtocol
    let onSave: () -> Void
    var part: Part = .model

    var body: some View {
        switch part {
        case .model:
            modelSelectionSection
            modelParametersSection
        case .instructions:
            instructionsSections
        case .responseFormat:
            responseFormatSections
        }
    }

    private var compat: ModelCompatibilityService { .shared }

    // MARK: - Model Selection

    private var modelSelectionSection: some View {
        Section {
            DynamicModelSelector(
                selectedModel: $activePrompt.openAIModel,
                openAIService: openAIService
            )
            .onChange(of: activePrompt.openAIModel) { oldModel, newModel in
                applyModelChange(from: oldModel, to: newModel)
            }

            Button("Reset to Default Model") {
                activePrompt.openAIModel = Prompt.defaultPrompt().openAIModel
                activePrompt.enableComputerUse = false
                onSave()
            }
        } header: {
            Text("Model")
        } footer: {
            Text("Every chat request uses this model. Some tools and options below depend on it.")
        }
    }

    private func applyModelChange(from oldModel: String, to newModel: String) {
        let supportsComputer = compat.isToolSupported(.computer, for: newModel, isStreaming: activePrompt.enableStreaming)
        if !supportsComputer && activePrompt.enableComputerUse {
            // Selecting a non-computer model should immediately disable the toggle
            activePrompt.enableComputerUse = false
            activePrompt.ultraStrictComputerUse = false
        }

        let supportsReasoning = compat.getCapabilities(for: newModel)?.supportsReasoningEffort == true
        let previousSupportedReasoning = compat.getCapabilities(for: oldModel)?.supportsReasoningEffort == true

        if supportsReasoning, !previousSupportedReasoning,
           let defaultReasoningEffort = compat.defaultReasoningEffort(for: newModel)
        {
            activePrompt.reasoningEffort = defaultReasoningEffort
        }
        if supportsReasoning {
            activePrompt.reasoningEffort = CurrentModelCatalog.normalizedEffort(activePrompt.reasoningEffort, model: newModel)
        }
        if supportsReasoning && !previousSupportedReasoning && !activePrompt.includeReasoningContent {
            activePrompt.includeReasoningContent = true
        } else if !supportsReasoning && activePrompt.includeReasoningContent {
            activePrompt.includeReasoningContent = false
        }
        onSave()
    }

    // MARK: - Model Parameters

    @ViewBuilder
    private var modelParametersSection: some View {
        let model = activePrompt.openAIModel
        let reasoning = compat.isParameterSupported("reasoning_effort", for: model)
        let verbosity = compat.isParameterSupported("verbosity", for: model)
        let temperature = compat.isParameterSupported("temperature", for: model, reasoningEffort: activePrompt.reasoningEffort)
        let topP = compat.isParameterSupported("top_p", for: model, reasoningEffort: activePrompt.reasoningEffort)

        if reasoning {
            Section {
                Picker("Effort", selection: $activePrompt.reasoningEffort) {
                    ForEach(CurrentModelCatalog.reasoningEfforts(for: model), id: \.self) { option in
                        Text(Self.effortName(option)).tag(option)
                    }
                }
                .onChange(of: activePrompt.reasoningEffort) { _, _ in onSave() }

                Picker("Show reasoning summary", selection: Binding(
                    get: { ["auto", "concise", "detailed"].contains(activePrompt.reasoningSummary) ? activePrompt.reasoningSummary : "" },
                    set: { activePrompt.reasoningSummary = $0 }
                )) {
                    Text("Off").tag("")
                    Text("Automatic").tag("auto")
                    Text("Concise").tag("concise")
                    Text("Detailed").tag("detailed")
                }
                .onChange(of: activePrompt.reasoningSummary) { _, _ in onSave() }
            } header: {
                Text("Reasoning")
            } footer: {
                Text("More effort thinks longer before answering: better on hard problems, slower and more tokens. The summary shows what the model thought about, when the model offers one.")
            }
        }

        if verbosity || temperature || topP {
            Section {
                if verbosity {
                    Picker("Answer length", selection: $activePrompt.verbosity) {
                        Text("Short").tag("low")
                        Text("Medium").tag("medium")
                        Text("Long").tag("high")
                        if !["low", "medium", "high"].contains(activePrompt.verbosity) {
                            Text(activePrompt.verbosity.capitalized).tag(activePrompt.verbosity)
                        }
                    }
                    .onChange(of: activePrompt.verbosity) { _, _ in onSave() }
                }
                if temperature {
                    sliderRow("Temperature", value: $activePrompt.temperature, range: 0...2)
                }
                if topP {
                    sliderRow("Top P", value: $activePrompt.topP, range: 0...1)
                }
            } header: {
                Text("Style")
            } footer: {
                if temperature {
                    Text("Temperature: lower is more predictable, higher is more varied. Top P narrows the words the model picks from.")
                }
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(title, value: String(format: "%.2f", value.wrappedValue))
            Slider(value: value, in: range, step: 0.01) { Text(title) }
                .onChange(of: value.wrappedValue) { _, _ in onSave() }
        }
    }

    static func effortName(_ option: String) -> String {
        switch option {
        case "none": return "None"
        case "minimal": return "Minimal"
        case "xhigh": return "X-High"
        default: return option.capitalized
        }
    }

    // MARK: - Instructions

    @ViewBuilder
    private var instructionsSections: some View {
        Section {
            TextEditor(text: $activePrompt.systemInstructions)
                .frame(minHeight: 140)
                .accessibilityLabel("System instructions")
        } header: {
            Text("System instructions")
        } footer: {
            Text("Sent with every message: who the assistant is and how it should answer. Example: \"You are a concise assistant. Answer in plain English.\"")
        }

        Section {
            TextEditor(text: $activePrompt.developerInstructions)
                .frame(minHeight: 100)
                .accessibilityLabel("Developer instructions")
        } header: {
            Text("Developer instructions")
        } footer: {
            Text("Optional. Rules the model weighs above the conversation, such as output formats or things to avoid.")
        }
    }

    // MARK: - Response Format

    @ViewBuilder
    private var responseFormatSections: some View {
        Section {
            Picker("Output", selection: $activePrompt.textFormatType) {
                Text("Text").tag("text")
                Text("JSON Schema").tag("json_schema")
            }
            .pickerStyle(.segmented)
            .onChange(of: activePrompt.textFormatType) { _, _ in onSave() }

            Toggle("Limit response length", isOn: Binding(
                get: { activePrompt.maxOutputTokens > 0 },
                set: { enabled in
                    activePrompt.maxOutputTokens = enabled ? 4096 : 0
                    onSave()
                }
            ))
            if activePrompt.maxOutputTokens > 0 {
                Stepper("Up to \(activePrompt.maxOutputTokens.formatted()) tokens",
                        value: $activePrompt.maxOutputTokens, in: 256...32768, step: 256)
            }
        } header: {
            Text("Output")
        } footer: {
            Text("JSON Schema makes every answer valid JSON in the shape you define below.")
        }

        if activePrompt.textFormatType == "json_schema" {
            Section {
                TextField("Schema name", text: $activePrompt.jsonSchemaName)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                TextField("Schema description", text: $activePrompt.jsonSchemaDescription)
                Toggle("Strict validation", isOn: $activePrompt.jsonSchemaStrict)
                JSONCodeEditor(text: $activePrompt.jsonSchemaContent, label: "Output JSON schema")
                    .frame(minHeight: 160)
            } header: {
                Text("JSON Schema")
            } footer: {
                Text("A full JSON Schema definition, sent to the Responses API as written.")
            }
        }
    }
}
