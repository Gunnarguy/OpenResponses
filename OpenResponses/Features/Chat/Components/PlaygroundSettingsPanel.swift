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
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Model Section
                Section("Model") {
                    Picker("Select Model", selection: $viewModel.activePrompt.openAIModel) {
                        ForEach(["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4", "o1-preview", "o1-mini", "o3-mini", "computer-use-preview"], id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.activePrompt.openAIModel) { _, newModel in
                        let compatibilityService = ModelCompatibilityService.shared
                        let supportsComputer = compatibilityService.isToolSupported(
                            .computer,
                            for: newModel,
                            isStreaming: viewModel.activePrompt.enableStreaming
                        )
                        if supportsComputer && newModel == "computer-use-preview" {
                            viewModel.activePrompt.enableComputerUse = true
                        } else if !supportsComputer && viewModel.activePrompt.enableComputerUse {
                            viewModel.activePrompt.enableComputerUse = false
                            viewModel.activePrompt.ultraStrictComputerUse = false
                        }
                    }
                }
                
                // MARK: - Tools Section
                Section("Tools") {
                    Toggle("File Search", isOn: $viewModel.activePrompt.enableFileSearch)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    
                    Toggle("Code Interpreter", isOn: $viewModel.activePrompt.enableCodeInterpreter)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                    
                    Toggle("Computer Use", isOn: $viewModel.activePrompt.enableComputerUse)
                        .toggleStyle(SwitchToggleStyle(tint: .indigo))
                        .disabled(!isComputerUseSupported)

                    if !isComputerUseSupported {
                        Text("Computer use requires the computer-use-preview model.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Parameters Section
                Section("Parameters") {
                    // Temperature
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
                    
                    // Top P
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
