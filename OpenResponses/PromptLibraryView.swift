import SwiftUI

/// A view for managing the local library of saved prompts.
struct PromptLibraryView: View {
    @StateObject var library: PromptLibrary
    @State private var showingAddEditPrompt = false
    @State private var promptToEdit: Prompt?
    
    /// A closure that provides a new `Prompt` object with the current app settings.
    var createPromptFromCurrentSettings: () -> Prompt
    
    var body: some View {
        NavigationView {
            List {
                ForEach(library.prompts) { prompt in
                    VStack(alignment: .leading) {
                        Text(prompt.name).font(.headline)
                        Text(prompt.description).font(.caption).foregroundColor(.gray)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(prompt.name). \(prompt.description)")
                    .accessibilityHint("Tap to edit this preset")
                    .onTapGesture {
                        promptToEdit = prompt
                        showingAddEditPrompt = true
                    }
                }
                .onDelete(perform: library.deletePrompt)
            }
            .navigationTitle("Preset Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        promptToEdit = nil
                        showingAddEditPrompt = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityConfiguration(
                        label: "Add preset",
                        hint: AccessibilityUtils.Hint.addPreset,
                        identifier: AccessibilityUtils.Identifier.addPresetButton
                    )
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .accessibilityConfiguration(
                            hint: AccessibilityUtils.Hint.editMode,
                            identifier: AccessibilityUtils.Identifier.editButton
                        )
                }
            }
            .sheet(isPresented: $showingAddEditPrompt, onDismiss: {
                // Reload after add/edit to reflect latest saved presets
                library.reload()
            }) {
                AddEditPromptView(
                    library: library,
                    promptToEdit: $promptToEdit,
                    createPromptFromCurrentSettings: createPromptFromCurrentSettings
                )
            }
        }
        .onAppear {
            // Ensure we always show the current presets from storage
            library.reload()
        }
    }
}

/// A view for adding or editing a prompt in the library.
struct AddEditPromptView: View {
    @ObservedObject var library: PromptLibrary
    @Binding var promptToEdit: Prompt?
    
    /// A closure that provides a new `Prompt` object with the current app settings.
    var createPromptFromCurrentSettings: () -> Prompt
    
    @State private var currentSettings: Prompt
    
    @Environment(\.dismiss) private var dismiss
    
    init(library: PromptLibrary, promptToEdit: Binding<Prompt?>, createPromptFromCurrentSettings: @escaping () -> Prompt) {
        self.library = library
        self._promptToEdit = promptToEdit
        self.createPromptFromCurrentSettings = createPromptFromCurrentSettings
        
        if let existingPrompt = promptToEdit.wrappedValue {
            _currentSettings = State(initialValue: existingPrompt)
        } else {
            // When adding a new prompt, capture the current settings from the main view.
            _currentSettings = State(initialValue: createPromptFromCurrentSettings())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Details")) {
                    TextField("Preset Name", text: $currentSettings.name)
                    TextField("Description", text: $currentSettings.description)
                }
                
                Section(header: Text("Preset Configuration")) {
                    Text("This preset will save all the current settings from the main screen.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(promptToEdit == nil ? "Add Preset" : "Edit Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(currentSettings.name.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        if let _ = promptToEdit {
            library.updatePrompt(currentSettings)
        } else {
            library.addPrompt(currentSettings)
        }
    }
}
