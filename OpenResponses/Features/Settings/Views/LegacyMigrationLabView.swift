import SwiftUI

struct LegacyMigrationLabView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var assistantJSON = ""
    @State private var showingConvertAlert = false
    @State private var convertMessage = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Assistants API shut down on August 26, 2026.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    
                    Text("Import a retained Assistant JSON export and convert its instructions to a Responses preset. The retired API cannot retrieve missing exports.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Import retained export") {
                TextEditor(text: $assistantJSON).font(.system(.caption, design: .monospaced)).frame(minHeight: 120)
                Button("Import Assistant JSON") {
                    do {
                        let data = Data(assistantJSON.utf8)
                        let imported: [Assistant]
                        if let single = try? JSONDecoder().decode(Assistant.self, from: data) { imported = [single] }
                        else if let list = try? JSONDecoder().decode([Assistant].self, from: data) { imported = list }
                        else { imported = try JSONDecoder().decode(AssistantListResponse<Assistant>.self, from: data).data }
                        viewModel.assistants = imported
                        viewModel.selectedAssistantId = imported.first?.id
                        assistantJSON = ""
                    } catch {
                        convertMessage = "Invalid Assistant export: \(error.localizedDescription)"
                        showingConvertAlert = true
                    }
                }.disabled(assistantJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if !viewModel.assistants.isEmpty {
                    Picker("Assistant", selection: Binding(get: { viewModel.selectedAssistantId ?? "" }, set: { viewModel.selectedAssistantId = $0 })) {
                        ForEach(viewModel.assistants) { assistant in
                            Text(assistant.name ?? assistant.id).tag(assistant.id)
                        }
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
        .onAppear { viewModel.useAssistantsAPI = false }
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
        preset.openAIModel = CurrentModelCatalog.isRetired(assistant.model) ? CurrentModelCatalog.defaultModel : assistant.model
        
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
