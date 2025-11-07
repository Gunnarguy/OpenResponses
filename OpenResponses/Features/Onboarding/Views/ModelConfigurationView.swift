//
//  ModelConfigurationView.swift
//  OpenResponses
//
//  Created to reduce complexity in SettingsView
//

import SwiftUI

struct ModelConfigurationView: View {
    @Binding var activePrompt: Prompt
    let openAIService: any OpenAIServiceProtocol
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            modelSelectionSection
            Divider()
            systemInstructionsSection
            developerInstructionsSection
            Divider()
            modelParametersSection
            responseSettingsSection
        }
    }
    
    // MARK: - Model Selection
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Model")
                .font(.subheadline)
                .fontWeight(.medium)
            
            DynamicModelSelector(
                selectedModel: $activePrompt.openAIModel,
                openAIService: openAIService
            )
            .onChange(of: activePrompt.openAIModel) { _, newModel in
                let compatibilityService = ModelCompatibilityService.shared
                let supportsComputer = compatibilityService.isToolSupported(
                    .computer,
                    for: newModel,
                    isStreaming: activePrompt.enableStreaming
                )

                if supportsComputer && newModel == "computer-use-preview" {
                    // Dedicated model – flip computer use on automatically
                    activePrompt.enableComputerUse = true
                } else if !supportsComputer && activePrompt.enableComputerUse {
                    // Selecting a non-computer model should immediately disable the toggle
                    activePrompt.enableComputerUse = false
                    activePrompt.ultraStrictComputerUse = false
                }
                onSave()
            }
            
            modelInfoRow
        }
    }
    
    @ViewBuilder
    private var modelInfoRow: some View {
        HStack {
            Text("Current: \(activePrompt.openAIModel)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Reset to Default") {
                activePrompt.openAIModel = "gpt-4o"
                activePrompt.enableComputerUse = false
                onSave()
            }
            .font(.caption)
            .foregroundColor(.orange)
        }
    }
    
    // MARK: - System Instructions
    
    private var systemInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Instructions")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Guide the assistant's behavior and personality")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $activePrompt.systemInstructions)
                .frame(minHeight: 80)
                .padding(.horizontal, 8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
            
            systemInstructionsPlaceholder
        }
    }
    
    @ViewBuilder
    private var systemInstructionsPlaceholder: some View {
        if activePrompt.systemInstructions.isEmpty {
            Text("e.g., 'You are a helpful and knowledgeable assistant.'")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    // MARK: - Developer Instructions
    
    private var developerInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Instructions")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Advanced model guidance (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $activePrompt.developerInstructions)
                .frame(minHeight: 60)
                .padding(.horizontal, 8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }
    
    // MARK: - Model Parameters
    
    private var modelParametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Parameters")
                .font(.subheadline)
                .fontWeight(.medium)
            
            modelParametersControls
        }
    }
    
    @ViewBuilder
    private var modelParametersControls: some View {
        if ModelCompatibilityService.shared.isParameterSupported("temperature", for: activePrompt.openAIModel) {
            temperatureControl
        }
        
        if ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: activePrompt.openAIModel) {
            reasoningEffortControl
            modelParametersReasoningSummary
        }
        
        if ModelCompatibilityService.shared.isParameterSupported("top_p", for: activePrompt.openAIModel) {
            topPControl
        }
    }
    
    private var temperatureControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Temperature")
                Spacer()
                Text(String(format: "%.2f", activePrompt.temperature))
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Slider(value: $activePrompt.temperature, in: 0...2, step: 0.01)
                .onChange(of: activePrompt.temperature) { _, _ in
                    onSave()
                }
        }
    }
    
    private var reasoningEffortControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reasoning Effort")
                Spacer()
                Text(activePrompt.reasoningEffort)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Picker("Reasoning Effort", selection: $activePrompt.reasoningEffort) {
                Text("Low").tag("low")
                Text("Medium").tag("medium")
                Text("High").tag("high")
            }
            .pickerStyle(.segmented)
            .onChange(of: activePrompt.reasoningEffort) { _, _ in
                onSave()
            }
        }
    }
    
    private var topPControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top P")
                Spacer()
                Text(String(format: "%.2f", activePrompt.topP))
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Slider(value: $activePrompt.topP, in: 0...1, step: 0.01)
                .onChange(of: activePrompt.topP) { _, _ in
                    onSave()
                }
        }
    }
    
    @ViewBuilder
    private var modelParametersReasoningSummary: some View {
        if !activePrompt.reasoningSummary.isEmpty || ModelCompatibilityService.shared.isParameterSupported("reasoning_effort", for: activePrompt.openAIModel) {
            reasoningSummaryField
        }
    }
    
    private var reasoningSummaryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reasoning Summary")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Optional reasoning approach guide", text: $activePrompt.reasoningSummary)
                .textFieldStyle(.roundedBorder)
                .disabled(activePrompt.enablePublishedPrompt)
                .onChange(of: activePrompt.reasoningSummary) { _, _ in
                    onSave()
                }
            
            Text("Guide how the model should approach complex problems")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Response Settings
    
    private var responseSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            textFormatTypePicker
            maxOutputTokensControl
        }
    }
    
    private var textFormatTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Format")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Text Format", selection: $activePrompt.textFormatType) {
                Text("Text").tag("text")
                Text("JSON Schema").tag("json_schema")
            }
            .pickerStyle(.segmented)
            .onChange(of: activePrompt.textFormatType) { _, _ in
                onSave()
            }
        }
    }
    
    private var maxOutputTokensControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Max Output Tokens")
                Spacer()
                Text(activePrompt.maxOutputTokens > 0 ? String(activePrompt.maxOutputTokens) : "Auto")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Toggle("Limit Response Length", isOn: Binding(
                get: { activePrompt.maxOutputTokens > 0 },
                set: { enabled in
                    activePrompt.maxOutputTokens = enabled ? 4096 : 0
                    onSave()
                }
            ))
            .font(.caption)
        }
    }
}
