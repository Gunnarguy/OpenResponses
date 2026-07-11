import SwiftUI

struct CreateAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ChatViewModel
    
    @State private var name: String = ""
    @State private var instructions: String = "You are a helpful assistant."
    @State private var model: String = "gpt-4o-mini"
    
    @State private var useCodeInterpreter = false
    @State private var useFileSearch = false
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let availableModels = ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-5.6", "gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo", "gpt-4-turbo"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Assistant Name", text: $name)
                    Picker("Model", selection: $model) {
                        ForEach(availableModels, id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                }
                
                Section(header: Text("Instructions")) {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 120)
                }
                
                Section(header: Text("Tools"), footer: Text("Enable OpenAI-hosted tools for this assistant.")) {
                    Toggle("Code Interpreter", isOn: $useCodeInterpreter)
                    Toggle("File Search", isOn: $useFileSearch)
                }
            }
            .navigationTitle("Create Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveAssistant()
                    }
                    .disabled(name.isEmpty || isSaving)
                    .fontWeight(.bold)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { newValue in if !newValue { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func saveAssistant() {
        isSaving = true
        
        var tools: [AssistantTool] = []
        if useCodeInterpreter {
            tools.append(AssistantTool(type: "code_interpreter", function: nil))
        }
        if useFileSearch {
            tools.append(AssistantTool(type: "file_search", function: nil))
        }
        
        Task {
            do {
                try await viewModel.createNewAssistant(
                    name: name,
                    model: model,
                    instructions: instructions,
                    tools: tools.isEmpty ? nil : tools
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to create assistant: \(error.localizedDescription)"
                    self.isSaving = false
                }
            }
        }
    }
}
