//
//  PlaygroundSettingsPanel.swift
//  OpenResponses
//
//  Unified settings panel organized like OpenAI Playground sidebar.
//  Consolidates model, tools, parameters, and files in one place.
//

import SwiftUI

struct PlaygroundSettingsPanel: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingExportView = false
    @State private var showingCreateAssistant = false
    
    private var activeVectorStoreIds: [String] {
        guard let ids = viewModel.activePrompt.selectedVectorStoreIds, !ids.isEmpty else { return [] }
        return ids
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var isComputerUseSupported: Bool {
        ModelCompatibilityService.shared.isToolSupported(
            .computer,
            for: viewModel.activePrompt.openAIModel,
            isStreaming: viewModel.activePrompt.enableStreaming
        )
    }

    private var supportsTemperature: Bool {
        ModelCompatibilityService.shared.isParameterSupported(
            "temperature",
            for: viewModel.activePrompt.openAIModel,
            reasoningEffort: viewModel.activePrompt.reasoningEffort
        )
    }

    private var supportsTopP: Bool {
        ModelCompatibilityService.shared.isParameterSupported(
            "top_p",
            for: viewModel.activePrompt.openAIModel,
            reasoningEffort: viewModel.activePrompt.reasoningEffort
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Model Section
                Section("Model") {
                    Picker("Select Model", selection: $viewModel.activePrompt.openAIModel) {
                        ForEach(["gpt-5.6-terra", "gpt-5.6-sol", "gpt-5.6-luna", "gpt-5.6", "gpt-5.5", "gpt-5.5-pro", "gpt-5.5-mini", "gpt-5.5-nano", "gpt-5.4", "gpt-5.4-pro", "gpt-5.4-mini", "gpt-5.4-nano", "gpt-5.2", "gpt-5.2-pro", "gpt-5.1", "gpt-5", "gpt-5-mini", "gpt-5-nano", "gpt-4o", "gpt-4o-mini", "o3", "o3-mini", "computer-use-preview"], id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.activePrompt.openAIModel) { oldModel, newModel in
                        var updatedPrompt = viewModel.activePrompt
                        updatedPrompt.openAIModel = newModel
                        _ = viewModel.replaceActivePrompt(with: updatedPrompt, previousModelId: oldModel)
                        viewModel.saveActivePrompt()
                    }
                    
                    if ModelCompatibilityService.shared.getCapabilities(for: viewModel.activePrompt.openAIModel)?.supportsReasoningEffort == true {
                        Picker("Reasoning Effort", selection: Binding(
                            get: { viewModel.activePrompt.reasoningEffort },
                            set: { newValue in
                                viewModel.activePrompt.reasoningEffort = newValue
                                viewModel.saveActivePrompt()
                            }
                        )) {
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reasoning Summary")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Optional reasoning approach guide", text: Binding(
                                get: { viewModel.activePrompt.reasoningSummary },
                                set: { newValue in
                                    viewModel.activePrompt.reasoningSummary = newValue
                                    viewModel.saveActivePrompt()
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)
                    }

                    if ModelCompatibilityService.shared.isParameterSupported("verbosity", for: viewModel.activePrompt.openAIModel) {
                        Picker("Verbosity", selection: Binding(
                            get: { viewModel.activePrompt.verbosity },
                            set: { newValue in
                                viewModel.activePrompt.verbosity = newValue
                                viewModel.saveActivePrompt()
                            }
                        )) {
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                    }
                }

                // MARK: - Tools Section
                Section("Tools") {
                    Toggle(isOn: $viewModel.activePrompt.enableFileSearch) {
                        Text("File Search")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .purple))

                    Toggle(isOn: $viewModel.activePrompt.enableCodeInterpreter) {
                        Text("Code Interpreter")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    Toggle(isOn: $viewModel.activePrompt.enableComputerUse) {
                        Text("Computer Use")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .indigo))
                    .disabled(!isComputerUseSupported)

                    if !isComputerUseSupported {
                        Text("Choose a computer-capable model like gpt-5.5 or gpt-5.5-mini.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Toggle(isOn: $viewModel.activePrompt.enableInputModeration) {
                        Text("Input Moderation")
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                }

                // MARK: - Parameters Section
                Section("Parameters") {
                    if supportsTemperature {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperature")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f", viewModel.activePrompt.temperature))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $viewModel.activePrompt.temperature, in: 0...2, step: 0.01)
                            Text("Controls randomness. Lower = focused, higher = creative")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Max Output Tokens
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Output Tokens")
                                .font(.subheadline)
                            Spacer()
                            Text("\(viewModel.activePrompt.maxOutputTokens)")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(viewModel.activePrompt.maxOutputTokens) },
                            set: { viewModel.activePrompt.maxOutputTokens = Int($0) }
                        ), in: 1...16000, step: 100)
                        Text("Maximum tokens in the response")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    if supportsTopP {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Top P")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f", viewModel.activePrompt.topP))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $viewModel.activePrompt.topP, in: 0...1, step: 0.01)
                            Text("Nucleus sampling. Alternative to temperature")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if !supportsTemperature || !supportsTopP {
                        Text("Sampling controls are only available for this model when reasoning effort is set to none.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Files & Vector Stores Section
                Section("Files & Vector Stores") {
                    // Attached files
                    if !viewModel.pendingFileData.isEmpty {
                        HStack {
                            Image(systemName: "paperclip")
                                .foregroundColor(.orange)
                            Text("\(viewModel.pendingFileData.count) file\(viewModel.pendingFileData.count == 1 ? "" : "s") attached")
                                .font(.subheadline)
                        }
                    }

                    // Attached images
                    if !viewModel.pendingImageAttachments.isEmpty {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            Text("\(viewModel.pendingImageAttachments.count) image\(viewModel.pendingImageAttachments.count == 1 ? "" : "s") attached")
                                .font(.subheadline)
                        }
                    }

                    // Active vector stores
                    if !activeVectorStoreIds.isEmpty {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.purple)
                            Text("\(activeVectorStoreIds.count) vector store\(activeVectorStoreIds.count == 1 ? "" : "s") active")
                                .font(.subheadline)
                        }
                    }

                    // Info text
                    Text("Use the Files icon in Settings or attachment buttons in chat to manage files and vector stores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - Advanced Section
                Section("Advanced") {
                    Button {
                        dismiss()
                        NotificationCenter.default.post(name: NSNotification.Name("ShowFullSettings"), object: nil)
                    } label: {
                        Label("Full Settings", systemImage: "gearshape.2")
                    }
                    Text("Manage API keys, MCP servers, integrations, and all advanced options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                    Button {
                        showingExportView = true
                    } label: {
                        Label("Export & Import", systemImage: "arrow.up.arrow.down.circle")
                    }

                    Text("Export conversation as JSON or import previous conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - Reset Section
                Section {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportView) {
            ConversationExportView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingCreateAssistant) {
            CreateAssistantSheet()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Actions

    private func resetToDefaults() {
        viewModel.activePrompt.temperature = 1.0
        viewModel.activePrompt.maxOutputTokens = 2048
        viewModel.activePrompt.topP = 1.0

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Preview

#Preview {
    PlaygroundSettingsPanel()
        .environmentObject({
            let vm = ChatViewModel()
            vm.activePrompt.enableFileSearch = true
            vm.activePrompt.enableCodeInterpreter = true
            return vm
        }())
}
