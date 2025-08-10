import Foundation
import Combine
import SwiftUI

/// Manages the local library of saved prompts using UserDefaults.
class PromptLibrary: ObservableObject {
    @Published var prompts: [Prompt] = [] {
        didSet {
            savePrompts()
        }
    }
    
    private let userDefaultsKey = "savedPrompts"
    
    init() {
        loadPrompts()
    }
    
    /// Adds a new prompt to the library. Ensures a unique ID so SwiftUI doesn't confuse rows.
    func addPrompt(_ prompt: Prompt) {
        var newPrompt = prompt
        newPrompt.id = UUID() // assign a fresh ID to avoid duplicates with activePrompt
        prompts.append(newPrompt)
    }
    
    /// Updates an existing prompt.
    func updatePrompt(_ prompt: Prompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index] = prompt
        }
    }
    
    /// Deletes a prompt from the library.
    func deletePrompt(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
    }
    
    /// Saves the current list of prompts to UserDefaults.
    private func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// Loads prompts from UserDefaults.
    private func loadPrompts() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Prompt].self, from: data) {
            self.prompts = decoded
            return
        }
        self.prompts = []
    }

    /// Public method to reload prompts from storage (useful on view transitions)
    func reload() {
        loadPrompts()
    }
}
