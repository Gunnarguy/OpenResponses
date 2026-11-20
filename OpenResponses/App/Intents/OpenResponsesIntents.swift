import AppIntents
import Foundation
import UIKit
import UniformTypeIdentifiers

// Shortcuts, Siri and the Action button (3.1).
//
// Ask OpenResponses sends one question with a saved preset (or the current settings) and returns
// the answer as text, without opening the app. New Chat opens the app on an empty chat with text and
// files already in place, through the same inbox the share sheet uses (`SharedInbox`).

// MARK: - Presets as Shortcuts parameters

struct PresetEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Preset" }
    static var defaultQuery: PresetQuery { PresetQuery() }

    var id: UUID
    var name: String
    var model: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(model)")
    }
}

struct PresetQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [PresetEntity] {
        ShortcutPromptStore.savedPresets().filter { identifiers.contains($0.id) }.map(\.entity)
    }

    func suggestedEntities() async throws -> [PresetEntity] {
        ShortcutPromptStore.savedPresets().map(\.entity)
    }
}

private extension Prompt {
    var entity: PresetEntity {
        PresetEntity(id: id, name: name.isEmpty ? "Untitled preset" : name, model: openAIModel)
    }
}

// MARK: - Reading settings outside the chat screen

/// Reads the settings a shortcut runs with from where the app keeps them: the saved presets
/// (`PromptLibrary`, UserDefaults `savedPrompts`) and the current settings (`activePrompt`).
enum ShortcutPromptStore {
    nonisolated static func savedPresets(_ defaults: UserDefaults = .standard) -> [Prompt] {
        guard let data = defaults.data(forKey: "savedPrompts"),
              let prompts = try? JSONDecoder().decode([Prompt].self, from: data)
        else { return [] }
        return prompts
    }

    nonisolated static func currentSettings(_ defaults: UserDefaults = .standard) -> Prompt {
        if let data = defaults.data(forKey: "activePrompt"),
           let prompt = try? JSONDecoder().decode(Prompt.self, from: data) {
            return prompt
        }
        return Prompt.defaultPrompt()
    }

    /// The settings with every tool the app itself has to run turned off.
    ///
    /// A shortcut makes one request and reads its answer; nobody is there to approve a browser
    /// step or a Python run, and no chat is open to run a function call, a Calendar or Notion
    /// lookup, or a multi-agent turn. Tools OpenAI runs (web search, file search, code interpreter,
    /// image generation, hosted shell, connectors) stay as the preset has them.
    nonisolated static func forShortcut(_ prompt: Prompt) -> Prompt {
        var prompt = prompt
        prompt.enableComputerUse = false
        prompt.enableCustomTool = false
        prompt.enableAppleIntegrations = false
        prompt.enableNotionIntegration = false
        prompt.enableStreaming = false
        prompt.backgroundMode = false
        var options = prompt.currentOptions
        options.localPython = false
        options.multiAgent = false
        options.asyncTools = false
        options.programmaticTools = false
        prompt.currentOptions = options
        return prompt
    }
}

// MARK: - Errors a shortcut shows

struct ShortcutError: Error, CustomLocalizedStringResourceConvertible {
    let message: String
    init(_ message: String) { self.message = message }
    var localizedStringResource: LocalizedStringResource { "\(message)" }
}

// MARK: - Ask OpenResponses

struct AskOpenResponsesIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask OpenResponses" }
    static var description: IntentDescription {
        IntentDescription(
            "Sends a question to OpenAI with one of your presets and returns the answer as text. Tools the app runs on this device (the browser, local Python, Calendar, Reminders, Contacts and Notion lookups) are off for shortcuts.",
            categoryName: "Chat"
        )
    }

    @Parameter(title: "Question", inputOptions: String.IntentInputOptions(multiline: true), requestValueDialog: "What do you want to ask?")
    var question: String

    @Parameter(title: "Preset", description: "A saved preset. Without one, the app's current settings are used.")
    var preset: PresetEntity?

    @Parameter(title: "Attachment", description: "An image, PDF or text file sent with the question.")
    var attachment: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Summary("Ask \(\.$question)") {
            \.$preset
            \.$attachment
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let answer = try await ShortcutAsk.run(question: question, presetID: preset?.id, attachment: attachment)
        return .result(value: answer, dialog: "\(answer)")
    }
}

/// The request an Ask shortcut makes, kept apart from the intent so a test can run it.
enum ShortcutAsk {
    @MainActor
    static func run(
        question: String,
        presetID: UUID?,
        attachment: IntentFile?,
        service: OpenAIServiceProtocol? = nil,
        defaults: UserDefaults = .standard
    ) async throws -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ShortcutError("Type a question to ask.") }

        // The same consent the chat asks for before anything leaves the device.
        guard defaults.integer(forKey: AppFeatureFlags.aiDataSharingConsentVersionKey) >= AppFeatureFlags.aiDataSharingConsentVersion else {
            throw ShortcutError("Open OpenResponses and send one message first, so you can choose Allow & Send. Shortcuts use the same permission.")
        }
        guard let key = KeychainService.shared.load(forKey: "openAIKey"), !key.isEmpty else {
            throw ShortcutError("Add your OpenAI API key in OpenResponses first.")
        }

        let base: Prompt
        if let presetID {
            guard let saved = ShortcutPromptStore.savedPresets(defaults).first(where: { $0.id == presetID }) else {
                throw ShortcutError("That preset no longer exists. Pick another one in the shortcut.")
            }
            base = saved
        } else {
            base = ShortcutPromptStore.currentSettings(defaults)
        }
        let prompt = ShortcutPromptStore.forShortcut(base)

        var images: [InputImage]?
        var fileData: [Data]?
        var fileNames: [String]?
        if let attachment {
            let data = attachment.data
            let name = attachment.filename
            if attachment.type?.conforms(to: .image) == true || UTType(filenameExtension: (name as NSString).pathExtension)?.conforms(to: .image) == true,
               let image = UIImage(data: data) {
                images = [InputImage(image: image, detail: "auto")]
            } else {
                fileData = [data]
                fileNames = [name]
            }
        }

        // Its own service: a one-off request that must not record a chain the chat could mistake for its own.
        let service = service ?? {
            let oneOff = OpenAIService()
            oneOff.recordsInstructionChains = false
            return oneOff
        }()
        let response = try await service.sendChatRequest(
            userMessage: trimmed,
            prompt: prompt,
            attachments: nil,
            fileData: fileData,
            fileNames: fileNames,
            fileIds: nil,
            imageAttachments: images,
            audioAttachments: nil,
            previousResponseId: nil,
            conversationId: nil
        )
        return try answerText(from: response)
    }

    /// The answer's text, or the reason there is none.
    nonisolated static func answerText(from response: OpenAIResponse) throws -> String {
        if let message = response.error?.message, !message.isEmpty {
            throw ShortcutError("OpenAI returned an error: \(message)")
        }
        var parts: [String] = []
        for item in response.output where item.type == "message" {
            for content in item.content ?? [] where content.type == "output_text" || content.type == "text" {
                if let piece = content.text { parts.append(piece) }
            }
        }
        let text = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { return text }
        if response.output.contains(where: { $0.type == "mcp_approval_request" }) {
            throw ShortcutError("A connector asked for approval. Run this question in the app, or set that connector to never ask.")
        }
        if let reason = response.incompleteDetails?.reason {
            throw ShortcutError("The answer stopped early (\(reason)). Try a preset with a higher output limit.")
        }
        throw ShortcutError("The model returned no text.")
    }
}

// MARK: - New Chat

struct NewChatIntent: AppIntent {
    static var title: LocalizedStringResource { "New Chat in OpenResponses" }
    static var description: IntentDescription {
        IntentDescription(
            "Opens OpenResponses on a new chat with your text in the message field and any files attached. Nothing is sent until you tap Send.",
            categoryName: "Chat"
        )
    }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true))
    var text: String?

    @Parameter(title: "Files")
    var files: [IntentFile]?

    static var parameterSummary: some ParameterSummary {
        Summary("New chat with \(\.$text)") {
            \.$files
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let attached: [(SharedInbox.File, Data)] = (files ?? []).map { file in
            let isImage = file.type?.conforms(to: .image) == true
                || UTType(filenameExtension: (file.filename as NSString).pathExtension)?.conforms(to: .image) == true
            return (SharedInbox.File(name: file.filename, kind: isImage ? .image : .file), file.data)
        }
        try SharedInbox.shared.deliver(text: text ?? "", files: attached, source: "shortcut")
        NotificationCenter.default.post(name: .sharedInboxDidChange, object: nil)
        return .result()
    }
}

// MARK: - Phrases for Siri, Spotlight and the Action button

struct OpenResponsesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskOpenResponsesIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Ask \(.applicationName) a question",
                "Ask \(.applicationName) with \(\.$preset)"
            ],
            shortTitle: "Ask",
            systemImageName: "bubble.left.and.text.bubble.right"
        )
        AppShortcut(
            intent: NewChatIntent(),
            phrases: [
                "New chat in \(.applicationName)",
                "Start a chat in \(.applicationName)"
            ],
            shortTitle: "New Chat",
            systemImageName: "square.and.pencil"
        )
    }
}

extension Notification.Name {
    /// Posted when something lands in `SharedInbox` while the app is running.
    static let sharedInboxDidChange = Notification.Name("sharedInboxDidChange")
}
