import SwiftUI

struct LegacyMigrationLabView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showingCreateAssistant = false
    @State private var showingConvertAlert = false
    @State private var convertMessage = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assistants API is deprecated by OpenAI and scheduled to shut down on August 26, 2026.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    
                    Text("Use Responses for new work. This lab is for migrating existing Assistants to the Responses Prompt format.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Assistants API Mode") {
                Toggle("Enable Legacy Assistants Mode", isOn: Binding(
                    get: { viewModel.useAssistantsAPI },
                    set: { newValue in
                        if newValue {
                            // Optionally show an alert here before enabling
                            viewModel.useAssistantsAPI = true
                        } else {
                            viewModel.useAssistantsAPI = false
                        }
                    }
                ))
                
                if viewModel.useAssistantsAPI {
                    if viewModel.assistants.isEmpty {
                        Text("No assistants found.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Assistant", selection: Binding(
                            get: { viewModel.selectedAssistantId ?? "" },
                            set: { viewModel.selectedAssistantId = $0.isEmpty ? nil : $0 }
                        )) {
                            ForEach(viewModel.assistants, id: \.id) { assistant in
                                Text(assistant.name ?? assistant.id).tag(assistant.id)
                            }
                        }
                    }
                    
                    Button {
                        showingCreateAssistant = true
                    } label: {
                        Label("Create Assistant", systemImage: "plus.circle")
                    }
                }
            }
            
            Section("Migration Tools") {
                Button {
                    convertAssistantToPrompt()
                } label: {
                    Label("Convert Selected Assistant to Preset", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.selectedAssistantId == nil || viewModel.assistants.isEmpty)
            }
        }
        .navigationTitle("Legacy Migration Lab")
        .sheet(isPresented: $showingCreateAssistant) {
            CreateAssistantSheet()
                .environmentObject(viewModel)
        }
        .alert("Migration Result", isPresented: $showingConvertAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(convertMessage)
        }
    }
    
    private func convertAssistantToPrompt() {
        guard let id = viewModel.selectedAssistantId,
              let assistant = viewModel.assistants.first(where: { $0.id == id }) else { return }
        
        var preset = Prompt.defaultPrompt()
        preset.name = "Migrated: \(assistant.name ?? "Assistant")"
        preset.systemInstructions = assistant.instructions ?? ""
        preset.openAIModel = assistant.model
        
        // Convert tools
        preset.enableCodeInterpreter = false
        preset.enableFileSearch = false
        preset.enableCustomTool = false
        
        var skippedTools: [String] = []
        for tool in assistant.tools {
            if tool.type == "code_interpreter" {
                preset.enableCodeInterpreter = true
            } else if tool.type == "file_search" {
                preset.enableFileSearch = true
            } else if tool.type == "function" {
                skippedTools.append("Function: \(tool.function?.name ?? "unknown")")
            } else {
                skippedTools.append(tool.type)
            }
        }
        
        // Show migrated message
        // We need to add it to PromptLibrary, but for now we just make it the active prompt
        viewModel.replaceActivePrompt(with: preset)
        viewModel.saveActivePrompt()
        
        var msg = "Converted '\(preset.name)' and set it as active."
        if !skippedTools.isEmpty {
            msg += "\n\nNote: The following tools were not automatically mapped and need manual setup: \(skippedTools.joined(separator: ", "))"
        }
        convertMessage = msg
        showingConvertAlert = true
    }
}
