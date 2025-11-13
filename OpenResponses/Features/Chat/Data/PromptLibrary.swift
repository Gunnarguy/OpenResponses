import Foundation
import Combine
import SwiftUI

/// Manages the local library of saved prompts using UserDefaults.
@MainActor
final class PromptLibrary: ObservableObject {
    @Published private(set) var prompts: [Prompt] = []

    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    init(userDefaults: UserDefaults = .standard, userDefaultsKey: String = "savedPrompts") {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        loadPrompts()
    }

    /// Adds a new prompt to the library. Ensures a unique ID so SwiftUI doesn't confuse rows.
    func addPrompt(_ prompt: Prompt) {
        var newPrompt = prompt
        newPrompt.id = UUID() // assign a fresh ID to avoid duplicates with activePrompt
        prompts.append(newPrompt)
        savePrompts()
    }

    /// Updates an existing prompt.
    func updatePrompt(_ prompt: Prompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index] = prompt
            savePrompts()
        }
    }

    /// Deletes a prompt from the library.
    func deletePrompt(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
        savePrompts()
    }

    /// Saves the current list of prompts to UserDefaults.
    private func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Loads prompts from UserDefaults.
    private func loadPrompts() {
        if let data = userDefaults.data(forKey: userDefaultsKey),
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
