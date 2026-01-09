import SwiftUI
import Combine

/// Coordinates the end-to-end chat experience, binding UI state, OpenAI streaming, and on-device storage.
/// Splitting streaming logic into `ChatViewModel+Streaming` keeps this primary type focused on orchestration.
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var conversations: [Conversation] = []
    @Published var activeConversation: Conversation?
    @Published var streamingStatus: StreamingStatus = .idle
    @Published var isStreaming: Bool = false
    @Published var pendingFileAttachments: [String] = []
    @Published var pendingImageAttachments: [UIImage] = []
    @Published var pendingFileData: [Data] = []
    @Published var pendingFileNames: [String] = []
    @Published var isShowingDocumentPicker = false
    // Audio feature removed
    @Published var selectedImageDetailLevel: String = "auto"
    @Published var activePrompt: Prompt
    @Published var errorMessage: String?
    @Published var isConnectedToNetwork: Bool = true
    /// When enabled and no OpenAI API key is configured, the app simulates responses locally.
    /// This is designed to let new users explore the UI without requiring credentials.
    @Published var exploreModeEnabled: Bool = UserDefaults.standard.bool(forKey: "exploreModeEnabled")
    @Published var currentModelCompatibility: [ModelCompatibilityService.ToolCompatibility] = []
    /// True while we are processing a computer-use tool call and must send computer_call_output
    /// before any new message can be sent. Prevents API 400s due to pending tool output.
    @Published var isAwaitingComputerOutput: Bool = false
    // Computer-use preview removed
    /// When non-nil, a safety confirmation is required before proceeding with a computer-use action.
    @Published var pendingSafetyApproval: SafetyApprovalRequest?

    /// Prevents multiple concurrent computer_call resolution tasks
    private var isResolvingComputerCalls: Bool = false

    /// Cache for container file content to avoid duplicate downloads
    var containerFileCache: [String: Data] = [:]
    /// Cache for processed artifacts to avoid duplicate processing
    var processedAnnotations: Set<String> = []

    /// MCP tool registry: stores discovered tools per server for UI display and instruction generation
    /// Key: server label, Value: array of tool schemas
    @Published var mcpToolRegistry: [String: [[String: AnyCodable]]] = [:]

    // MARK: - Private Properties
    let api: OpenAIServiceProtocol
    private let computerService: ComputerService
    private let storageService: ConversationStorageService
    var streamingMessageId: UUID?
    private var cancellables = Set<AnyCancellable>()
    private var streamingTask: Task<Void, Never>?
    private lazy var networkMonitor = NetworkMonitor.shared

    private let exploreModeDefaultsKey = "exploreModeEnabled"
    // Coalesces rapid-fire text deltas into fewer UI updates per message.
    // Keyed by messageId.
    var deltaBuffers: [UUID: String] = [:]
    private var deltaFlushWorkItems: [UUID: DispatchWorkItem] = [:]
    // Flush after this many milliseconds without new punctuation, to avoid lag.
    private let deltaFlushDebounceMs: Int = 150 // Reduced from 500ms for snappier updates
    // Minimum buffer size before forcing a flush (characters)
    let minBufferSizeForFlush: Int = 20
    /// Captures live reasoning text fragments while the assistant streams.
    private var streamingReasoningTextByMessageId: [UUID: String] = [:]
    /// Provides stable IDs so the UI can diff live reasoning entries without flicker.
    private var streamingReasoningTraceIdByMessageId: [UUID: UUID] = [:]
    /// Buffers streaming MCP argument payloads keyed by tool call item ID.
    var mcpArgumentBuffers: [String: String] = [:]
    // Maintain container file annotations per message to enable sandbox-link fallback fetches
    var containerAnnotationsByMessage: [UUID: [(containerId: String, fileId: String, filename: String?)]] = [:]
    /// Tracks the most recent list_tools error per MCP server to avoid spamming identical alerts.
    /// Accessed from the streaming extension to coordinate surfaced warnings.
    var lastMCPListToolsError: [String: String] = [:]
    /// Remembers the last server label we successfully resolved so events missing this field can reuse it.
    var lastMCPServerLabel: String?
    /// Records MCP tool warnings surfaced to the user to avoid spamming duplicate alerts.
    var surfacedMCPToolWarnings: Set<String> = []
    /// Prevents duplicate execution of the same function call when streaming emits multiple completion events.
    private var pendingFunctionCallIds: Set<String> = []
    private var completedFunctionCallIds: Set<String> = []
    /// Captures temporary summaries derived from tool outputs when the model omits assistant copy.
    private var functionOutputSummariesByMessageId: [UUID: [String]] = [:]

    /// Batches parallel function calls that need to be sent together
    private var pendingParallelCalls: [String: [OutputItem]] = [:]  // responseId -> [calls]
    private var parallelCallOutputs: [String: [String: String]] = [:]  // responseId -> [callId: output]
    private var parallelCallBatchTimer: [String: DispatchWorkItem] = [:]
    private var functionCallCanonicalIds: [String: String] = [:]  // alias -> canonical callId
    /// Maps canonical or alias call identifiers to their originating response for safe rebinding.
    private var functionCallResponseIds: [String: String] = [:]

    /// Reasoning items emitted by the last response, keyed by response ID.
    /// Required for reasoning models (e.g., GPT-5) when echoing tool outputs.
    private var reasoningBufferByResponseId: [String: [[String: Any]]] = [:]

    /// Helper methods to check function call status (accessible from extensions)
    func isCallCompleted(_ callId: String) -> Bool {
        return completedFunctionCallIds.contains(callId)
    }

    func isCallPending(_ callId: String) -> Bool {
        return pendingFunctionCallIds.contains(callId)
    }

    @MainActor
    private func canonicalIdentifier(for call: OutputItem) -> String? {
        let callId = call.callId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let itemId = call.id.trimmingCharacters(in: .whitespacesAndNewlines)

        if let callId, !callId.isEmpty {
            let canonical = functionCallCanonicalIds[callId] ?? callId

            if !itemId.isEmpty {
                if let previous = functionCallCanonicalIds[itemId], previous != canonical {
                    AppLogger.log("♻️ [Batching] Rebinding alias \(itemId) from \(previous) to \(canonical)", category: .openAI, level: .debug)
                    migrateFunctionCallIdentifier(from: previous, to: canonical)
                }
                functionCallCanonicalIds[itemId] = canonical
                if let responseId = functionCallResponseIds[itemId] ?? functionCallResponseIds[callId] {
                    functionCallResponseIds[itemId] = responseId
                    functionCallResponseIds[canonical] = responseId
                }
            }

            functionCallCanonicalIds[callId] = canonical
            return canonical
        }

        guard !itemId.isEmpty else { return nil }

        if let canonical = functionCallCanonicalIds[itemId] {
            return canonical
        }

        functionCallCanonicalIds[itemId] = itemId
        return itemId
    }

    /// Records the identifiers associated with a function call so we can migrate cached outputs later.
    @MainActor
    private func registerFunctionCallIdentifiers(_ call: OutputItem, canonicalId: String, responseId: String) {
        functionCallResponseIds[canonicalId] = responseId

        let trimmedItemId = call.id.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedItemId.isEmpty {
            functionCallResponseIds[trimmedItemId] = responseId
        }

        if let rawCallId = call.callId?.trimmingCharacters(in: .whitespacesAndNewlines), !rawCallId.isEmpty {
            functionCallResponseIds[rawCallId] = responseId
        }
    }

    /// Migrates cached state (outputs, tracking sets) when an alias is rebound to a new canonical identifier.
    @MainActor
    private func migrateFunctionCallIdentifier(from oldId: String, to newId: String) {
        guard !oldId.isEmpty, !newId.isEmpty, oldId != newId else { return }

        if pendingFunctionCallIds.remove(oldId) != nil {
            pendingFunctionCallIds.insert(newId)
        }

        if completedFunctionCallIds.remove(oldId) != nil {
            completedFunctionCallIds.insert(newId)
        }

        for responseId in Array(parallelCallOutputs.keys) {
            var outputs = parallelCallOutputs[responseId] ?? [:]
            if let value = outputs.removeValue(forKey: oldId) {
                outputs[newId] = value
                parallelCallOutputs[responseId] = outputs
                AppLogger.log("♻️ [Batching] Migrated stored output from \(oldId) to \(newId) for response \(responseId)", category: .openAI, level: .debug)
            }
        }

        if let responseId = functionCallResponseIds[oldId] ?? functionCallResponseIds[newId] {
            functionCallResponseIds[newId] = responseId
        }

        // Keep alias mapping pointing to the same response so subsequent lookups remain valid.
        if let responseId = functionCallResponseIds[newId] {
            functionCallResponseIds[oldId] = responseId
        }
    }

    /// Stores a concise status line for the active assistant message when a tool call fails.
    func recordFunctionOutputSummary(_ summary: String, for messageId: UUID) {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var existing = functionOutputSummariesByMessageId[messageId] ?? []
        if !existing.contains(trimmed) {
            existing.append(trimmed)
            functionOutputSummariesByMessageId[messageId] = existing
        }

        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            let joined = existing.joined(separator: "\n\n")
            let current = messages[idx].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if current.isEmpty || current == joined {
                messages[idx].text = joined
            }
        }
    }

    /// Returns the combined summary text for a message, if any.
    func functionOutputSummaryText(for messageId: UUID) -> String? {
        guard let summaries = functionOutputSummariesByMessageId[messageId], !summaries.isEmpty else { return nil }
        return summaries.joined(separator: "\n\n")
    }

    /// Clears any stored summaries once the response finishes.
    func clearFunctionOutputSummaries(for messageId: UUID) {
        functionOutputSummariesByMessageId.removeValue(forKey: messageId)
    }

    // Conversation-level cumulative token usage, updated live during streaming
    @Published var cumulativeTokenUsage: TokenUsage = TokenUsage()

    // Last response token usage for status bar display
    @Published var lastTokenUsage: TokenUsage? = nil

    /// Compact activity feed to surface what's happening under the hood during streaming.
    /// Keep short, user-friendly messages. Updated when status changes or tools run.
    @Published var activityLines: [String] = []
    private var lastActivityLine: String?
    private let maxActivityLines: Int = 12

    /// Tracks retry context for a streaming request keyed by assistant message ID.
    /// Used to transparently retry once when the streaming API emits a transient model_error.
    private struct StreamRetryContext {
        var remainingAttempts: Int
        var basePreviousResponseId: String?
        var userText: String
        var attachments: [[String: Any]]?
        var imageAttachments: [InputImage]?
        var retryScheduled: Bool = false
    }
    private var retryContextByMessageId: [UUID: StreamRetryContext] = [:]

    /// Image generation heartbeat tracking to provide progress feedback during long waits
    private var imageHeartbeatTasks: [UUID: Task<Void, Never>] = [:]
    private var imageHeartbeatCounters: [UUID: Int] = [:]

    /// Fallback mapping from common site keywords to canonical URLs used when the model
    /// requests a first-step screenshot without having navigated yet (e.g., user says "Google").
    /// This keeps the flow moving without blank/"about:blank" screenshots.
    private static let keywordURLMap: [String: String] = [
        // Core examples emphasized in system instructions
        "google": "https://google.com",
        "youtube": "https://youtube.com",
        "amazon": "https://amazon.com",
        "openai": "https://openai.com",
        // Helpful additions
        "bing": "https://bing.com",
        "github": "https://github.com",
        "x": "https://x.com",
        "twitter": "https://twitter.com",
        "reddit": "https://reddit.com",
        "wikipedia": "https://wikipedia.org",
        "apple": "https://apple.com",
        "facebook": "https://facebook.com",
        "instagram": "https://instagram.com",
        "linkedin": "https://linkedin.com",
        "nytimes": "https://nytimes.com",
        // Common device/computer brands to make "go to <brand>" intuitive
        "acer": "https://acer.com",
        "asus": "https://asus.com",
        "lenovo": "https://lenovo.com",
        "dell": "https://dell.com",
        "hp": "https://hp.com",
        "microsoft": "https://microsoft.com",
        "samsung": "https://samsung.com"
    ]

    // MARK: - Computer Use Circuit Breaker
    private var consecutiveWaitCount: Int = 0
    private let maxConsecutiveWaits: Int = 3
    // Tracks which messages have already applied the intent-aware search override,
    // so we don't run it twice (streaming path + resume path).
    private var appliedSearchOverrideForMessage = Set<UUID>()

    // Single-shot Screenshot Mode removed

    // MARK: - Computed Properties
    var messages: [ChatMessage] {
        get { activeConversation?.messages ?? [] }
        set {
            guard var conversation = activeConversation else { return }
            conversation.messages = newValue
            updateActiveConversation(conversation)
            // Recompute cumulative usage when messages change (e.g., when final usage arrives)
            recomputeCumulativeUsage()
        }
    }

    var lastResponseId: String? {
        get { activeConversation?.lastResponseId }
        set {
            guard var conversation = activeConversation else { return }
            conversation.lastResponseId = newValue
            updateActiveConversation(conversation)
        }
    }

    init(
        api: OpenAIServiceProtocol? = nil,
        computerService: ComputerService? = nil,
        storageService: ConversationStorageService? = nil,
        startBackgroundWork: Bool = true
    ) { 
        self.api = api ?? OpenAIService()
        self.computerService = computerService ?? ComputerService()
        self.storageService = storageService ?? ConversationStorageService.shared
        self.activePrompt = Prompt.defaultPrompt()

        loadActivePrompt()
        loadConversations()

        if conversations.isEmpty {
            createNewConversation()
            clearActivity()
        } else {
            activeConversation = conversations.first
        }

        if startBackgroundWork { 
            setupBindings()
        }
        updateModelCompatibility()
    }

    // MARK: - Explore Demo

    func setExploreModeEnabled(_ enabled: Bool) {
        exploreModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: exploreModeDefaultsKey)
    }

    /// Starts (or restarts) a local, offline demo conversation.
    /// This does not make any OpenAI API calls.
    func startExploreDemoConversation() {
        setExploreModeEnabled(true)

        // Reset to a clean conversation so the demo is predictable.
        createNewConversation()
        guard var conv = activeConversation else { return }

        conv.title = "Explore Demo"
        var meta = conv.metadata ?? [:]
        meta["mode"] = "explore_demo"
        conv.metadata = meta
        conv.lastResponseId = nil
        conv.remoteId = nil

        conv.messages = [
            ChatMessage(role: .system, text: "✨ Explore Demo is offline: no API calls are made. Add an OpenAI API key in Settings to chat for real."),
            ChatMessage(role: .assistant, text: exploreDemoWelcomeText(), images: nil),
        ]

        updateActiveConversation(conv)
        clearActivity()
        logActivity("Explore Demo ready (offline)")
    }

    func exitExploreDemo() {
        setExploreModeEnabled(false)
        logActivity("Explore Demo disabled")
    }

    private func exploreDemoWelcomeText() -> String {
        return "Hi! I’m a demo assistant. I can’t call the OpenAI API yet (no key configured), but you can explore the app’s UI and what it *can* do.\n\nTry asking things like:\n• \"Write a SwiftUI view for a settings screen\"\n• \"Summarize a PDF\" (attach a file once you add a key)\n• \"Use web search to find today’s news\"\n• \"Connect Notion via MCP\"\n\nWhen you’re ready: Settings → General → paste your OpenAI API key."
    }

    private func isMissingOpenAIKey() -> Bool {
        let key = KeychainService.shared.load(forKey: "openAIKey")
        return (key == nil || key?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true)
    }

    private func exploreDemoAssistantText(for userText: String) -> String {
        let t = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = t.lowercased()

        if lower.contains("swiftui") || lower.contains("swift") || lower.contains("code") {
            return "(Demo) In the full version, I can write, debug, and explain code for you. Here is an example of what that looks like:\n\n```swift\nimport SwiftUI\n\nstruct DemoLoginView: View {\n    @State private var email = \"\"\n    @State private var password = \"\"\n    \n    var body: some View {\n        VStack(spacing: 20) {\n            Image(systemName: \"lock.shield\")\n                .font(.system(size: 60))\n                .foregroundStyle(.blue)\n                \n            TextField(\"Email\", text: $email)\n                .textFieldStyle(.roundedBorder)\n                .textContentType(.emailAddress)\n                \n            SecureField(\"Password\", text: $password)\n                .textFieldStyle(.roundedBorder)\n            \n            Button(\"Log In\") {\n                // Handle login\n            }\n            .buttonStyle(.borderedProminent)\n            .controlSize(.large)\n        }\n        .padding()\n    }\n}\n```\n\nTo unlock real-time coding assistance, just add your API key in **Settings**."
        }

        if lower.contains("pdf") || lower.contains("file") || lower.contains("document") {
            return """
            (Demo) You can attach PDFs, text files, or images, and I can analyze them.

            **What I can do with files:**
            1. **Summarize** long academic papers or contracts.
            2. **Extract data** into JSON or tables.
            3. **Answer questions** based purely on the document's content.

            *Try adding your API key to upload your own files!*
            """
        }

        if lower.contains("image") || lower.contains("generate") || lower.contains("picture") {
            return """
            (Demo) I can generate images using DALL·E 3 compatible models.

            For example, if you asked for *"a futuristic city with flying cars"*, I would display the high-resolution image right here in the chat.

            You can verify generated images in the **Media** tab later. Enable Image Generation in **Settings → Tools** (requires API key).
            """
        }

        if lower.contains("web search") || lower.contains("browse") || lower.contains("latest") || lower.contains("news") {
            return """
            (Demo) I can browse the live web to find current information.

            **Example Query:** "What is the stock price of Apple right now?"

            **My Response would be:**
            > **Apple Inc. (AAPL)** is trading at **$225.40**, up 1.2% today. (Source: Finance News, 10 mins ago)

            This allows me to answer questions about recent events that aren't in my training data.
            """
        }

        if lower.contains("mcp") || lower.contains("notion") || lower.contains("connector") {
            return """
            (Demo) I support the **Model Context Protocol (MCP)**. This means you can connect me to your personal tools like:

            - **Notion** (read/write pages for you)
            - **Google Drive** (search files)
            - **Local Filesystem** (safe local access)

            Once connected in **Settings → MCP**, I can read your notes and answer questions like *"What is on my reading list in Notion?"*
            """
        }

        if lower.contains("computer") || lower.contains("click") || lower.contains("browser") {
            return """
            (Demo) **Computer Use** is an advanced feature where I can view and interact with websites like a human.

            **How it works:**
            1. You ask: *"Find a flight to NYC under $300"*
            2. I launch a secure browser.
            3. I navigate to travel sites, click buttons, input dates, and screenshot the results for you.

            *Safety Note:* I will always ask for approval before taking sensitive actions.
            """
        }

        return """
        (Demo) Hi! I’m currently in **Demo Mode**.

        I can't call OpenAI without an API Key, but I'm ready to help once you set one up.

        **To unlock the full experience:**
        1. Get a key at [platform.openai.com](https://platform.openai.com/api-keys).
        2. Go to **Settings** (top right).
        3. Paste your **OpenAI API Key**.

        *Your key is stored securely in the iOS Keychain and is never shared with us.*
        """
    }

    private func chunkDemoText(_ text: String) -> [String] {
        // Chunk on sentence-ish boundaries for a more "streaming" feel.
        let separators = CharacterSet(charactersIn: ".!?\\n")
        var chunks: [String] = []
        var buffer = ""
        for ch in text {
            buffer.append(ch)
            if let scalar = ch.unicodeScalars.first, separators.contains(scalar) {
                if !buffer.isEmpty { chunks.append(buffer); buffer = "" }
            }
        }
        if !buffer.isEmpty { chunks.append(buffer) }
        return chunks.isEmpty ? [text] : chunks
    }

    private func appendDemoChunk(_ chunk: String, to messageId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var updated = messages
        let current = updated[idx].text ?? ""
        updated[idx].text = current + chunk
        messages = updated
    }

    // MARK: - Streaming Helpers
    /// Returns true if the provided message is the assistant message currently receiving streamed content.
    func isStreamingAssistantMessage(_ message: ChatMessage) -> Bool {
        return isStreaming && message.role == .assistant && streamingMessageId == message.id
    }
    /// Returns true if the provided message ID is the one currently receiving streamed content.
    func isStreamingMessageId(_ id: UUID) -> Bool {
        return isStreaming && streamingMessageId == id
    }

    // MARK: - Safety approval handling
    /// Encapsulates the context needed to continue a computer-use action after the user approves safety checks.
    struct SafetyApprovalRequest: Identifiable {
        let id = UUID()
        let checks: [SafetyCheck]
        let callId: String
        let action: ComputerAction
        let previousResponseId: String
        let messageId: UUID
    }

    /// Called when the user approves the pending safety checks.
    func approveSafetyChecks() {
        guard let request = pendingSafetyApproval else { return }
        // Keep the sheet open until we start; then clear to dismiss
        pendingSafetyApproval = nil
        Task { [weak self] in
            await self?.executeComputerCallWithApproval(request)
        }
    }

    /// Called when the user denies the pending safety checks; cancels the computer-use chain gracefully.
    func denySafetyChecks() {
        guard let request = pendingSafetyApproval else { return }
        pendingSafetyApproval = nil
        // Inform the user and reset state to avoid API 400s
        let sys = ChatMessage(role: .system, text: "❌ Action canceled. Safety checks were not approved. The assistant won't proceed with this step.")
        messages.append(sys)
        lastResponseId = nil
        isAwaitingComputerOutput = false
        streamingStatus = .idle
        AppLogger.log("[CUA] Safety approval denied by user for callId=\(request.callId)", category: .openAI, level: .info)
    }

    /// Continues the computer-use flow after user approval by executing the action and sending the screenshot back.
    private func executeComputerCallWithApproval(_ request: SafetyApprovalRequest) async {
        AppLogger.log("[CUA] Proceeding after safety approval for callId=\(request.callId), action=\(request.action.type)", category: .openAI, level: .info)
        await MainActor.run { self.isAwaitingComputerOutput = true; self.streamingStatus = .usingComputer }
        do {
            // First-step helper (disabled in ultra-strict): pre-navigation to avoid about:blank screenshots
            if !activePrompt.ultraStrictComputerUse {
                if (request.action.type == "screenshot" && request.action.parameters["url"] == nil) ||
                   (request.action.type == "click" && computerService.isOnBlankPage()) {
                    if let derived = deriveURLForScreenshot(from: request.messageId) {
                        AppLogger.log("[CUA] (approved) Navigating to derived URL before action: \(derived.absoluteString)", category: .openAI, level: .info)
                        let navigateAction = ComputerAction(type: "navigate", parameters: ["url": derived.absoluteString])
                        _ = try await computerService.executeAction(navigateAction)
                        try? await Task.sleep(nanoseconds: 400_000_000)
                    }
                }
            }

            let result = try await computerService.executeAction(request.action)
            if let screenshot = result.screenshot, !screenshot.isEmpty {
                // Attach screenshot to UI
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.id == request.messageId }) {
                        var updatedMessage = self.messages[index]
                        if let imageData = Data(base64Encoded: screenshot), let uiImage = UIImage(data: imageData, scale: 1.0) {
                            if updatedMessage.images == nil { updatedMessage.images = [] }
                            updatedMessage.images?.removeAll()
                            updatedMessage.images?.append(uiImage)
                            var updatedMessages = self.messages
                            updatedMessages[index] = updatedMessage
                            self.messages = updatedMessages
                            self.objectWillChange.send()
                        }
                    }
                }

                // Build output and send computer_call_output with acknowledged safety checks
                let output: [String: Any] = [
                    "type": "computer_screenshot",
                    "image_url": "data:image/png;base64,\(screenshot)"
                ]
                do {
                    let response = try await api.sendComputerCallOutput(
                        callId: request.callId,
                        output: output,
                        model: activePrompt.openAIModel,
                        previousResponseId: request.previousResponseId,
                        acknowledgedSafetyChecks: request.checks,
                        currentUrl: result.currentURL
                    )
                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: request.messageId)
                        self.isAwaitingComputerOutput = false
                    }
                } catch {
                    await MainActor.run {
                        self.handleError(error)
                        self.lastResponseId = nil
                        self.streamingStatus = .idle
                        self.streamingMessageId = nil
                        self.isStreaming = false
                        self.isAwaitingComputerOutput = false
                        let sys = ChatMessage(role: .system, text: "Couldn’t continue the approved computer-use step. I’ll start fresh on the next message.")
                        self.messages.append(sys)
                    }
                }
            } else {
                AppLogger.log("[CUA] (approved) No screenshot produced by action; clearing previousId", category: .openAI, level: .warning)
                await MainActor.run { self.lastResponseId = nil; self.isAwaitingComputerOutput = false }
            }
        } catch {
            AppLogger.log("[CUA] Error while executing approved computer_call: \(error)", category: .openAI, level: .error)
            await MainActor.run {
                self.lastResponseId = nil
                self.isAwaitingComputerOutput = false
                self.handleError(error)
                self.streamingStatus = .idle
                self.streamingMessageId = nil
                self.isStreaming = false
            }
        }
    }

    private func setupBindings() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnectedToNetwork = isConnected
                if !isConnected {
                    self?.handleNetworkDisconnection()
                }
            }
            .store(in: &cancellables)


        $activePrompt
            .dropFirst() // Ignore the initial value on app launch
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                // If a preset was active, any modification turns it into a custom prompt.
                if self.activePrompt.isPreset {
                    self.activePrompt.isPreset = false
                }

                self.saveActivePrompt()
                self.updateModelCompatibility()
            }
            .store(in: &cancellables)

        // Periodic cache cleanup to prevent memory bloat
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupPerformanceCaches()
            }
            .store(in: &cancellables)
    }

    private func updateActiveConversation(_ conversation: Conversation) {
        var conv = conversation
        conv.lastModified = Date() // Update timestamp

        if let index = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[index] = conv
        } else {
            conversations.insert(conv, at: 0)
        }

        activeConversation = conv
        saveConversation(conv)
    }

    /// Updates the current model compatibility information
    private func updateModelCompatibility() {
        let compatibilityService = ModelCompatibilityService.shared
        currentModelCompatibility = compatibilityService.getCompatibleTools(
            for: activePrompt.openAIModel,
            prompt: activePrompt,
            isStreaming: activePrompt.enableStreaming
        )
    }

    /// Recomputes cumulative token usage across the conversation.
    /// Uses final counts when available; falls back to live estimates for in-flight assistant messages.
    func recomputeCumulativeUsage() {
        var inputSum = 0
        var outputSum = 0
        var totalSum = 0
        var estOut = 0
        for m in messages {
            guard m.role == .assistant, let tu = m.tokenUsage else { continue }
            if let i = tu.input { inputSum += i }
            if let o = tu.output { outputSum += o } else if let est = tu.estimatedOutput { estOut += est }
            if let t = tu.total { totalSum += t } else if let i = tu.input, let o = tu.output {
                totalSum += (i + o)
            }
        }
        var agg = TokenUsage()
        agg.input = inputSum == 0 ? nil : inputSum
        agg.output = outputSum == 0 ? nil : outputSum
        agg.total = totalSum == 0 ? nil : totalSum
        agg.estimatedOutput = estOut == 0 ? nil : estOut
        cumulativeTokenUsage = agg

        // Update last token usage from most recent assistant message
        if let lastAssistantMessage = messages.last(where: { $0.role == .assistant }),
           let usage = lastAssistantMessage.tokenUsage,
           let total = usage.total {
            lastTokenUsage = TokenUsage(
                estimatedOutput: usage.estimatedOutput,
                input: usage.input,
                output: usage.output,
                total: total
            )
        }
    }

    // Removed detection UI and related method

    /// Detects if a user message is requesting image generation
    private func detectsImageRequest(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let imageKeywords = [
            "generate an image", "create an image", "make an image", "draw an image",
            "generate a picture", "create a picture", "make a picture", "draw a picture",
            "show me an image", "show me a picture", "visualize", "illustration",
            "generate art", "create art", "make art", "draw art",
            "image of", "picture of", "photo of", "painting of",
            "sketch", "artwork", "render", "design"
        ]

        return imageKeywords.contains { keyword in
            lowercased.contains(keyword)
        }
    }

    // detectsScreenshotRequest removed

    /// Handles network disconnection by informing the user
    private func handleNetworkDisconnection() {
        let networkMessage = ChatMessage(
            role: .system,
            text: "📱 Network connection lost. Please check your internet connection.",
            images: nil
        )
        if !messages.contains(where: { $0.text?.contains("Network connection lost") == true }) {
            messages.append(networkMessage)
        }
    }

    /// Sends a user message and processes the assistant's response.
    /// This appends the user message to the chat and interacts with the OpenAI service.
    func sendUserMessage(_ text: String, bypassMCPGate: Bool = false) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Do not allow sending a new message while a computer-use step is pending.
        if isAwaitingComputerOutput {
            let warn = ChatMessage(role: .system, text: "Please wait—assistant is completing a computer step.", images: nil)
            messages.append(warn)
            return
        }

        // If there is no API key and Explore Demo is not enabled, avoid making a request that will fail.
        if isMissingOpenAIKey(), !exploreModeEnabled {
            let guidance = "🔑 No OpenAI API key is configured. Open Settings → General to add one, or enable Explore Demo (offline) to try the UI without API calls."
            if messages.last?.text != guidance {
                messages.append(ChatMessage(role: .system, text: guidance))
            }
            return
        }

        // Explore Demo: if enabled and no API key is available, simulate a response locally.
        if exploreModeEnabled, isMissingOpenAIKey() {
            // Cancel any previous demo stream.
            streamingTask?.cancel()
            surfacedMCPToolWarnings.removeAll()

            // Drop any pending attachments (demo is offline).
            if !pendingFileAttachments.isEmpty || !pendingFileData.isEmpty || !pendingFileNames.isEmpty || !pendingImageAttachments.isEmpty {
                pendingFileAttachments.removeAll()
                pendingFileData.removeAll()
                pendingFileNames.removeAll()
                pendingImageAttachments.removeAll()
                let sys = ChatMessage(role: .system, text: "ℹ️ Explore Demo is offline and won’t upload files/images. Add an API key to use attachments.")
                messages.append(sys)
            }

            let userMsg = ChatMessage.withURLDetection(role: .user, text: trimmed, images: nil)
            messages.append(userMsg)

            let assistantMsgId = UUID()
            messages.append(ChatMessage(id: assistantMsgId, role: .assistant, text: "", images: nil))
            streamingMessageId = assistantMsgId
            resetStreamingReasoning(for: assistantMsgId)
            isStreaming = true
            streamingStatus = .connecting
            logActivity("Explore Demo (offline)")

            let full = exploreDemoAssistantText(for: trimmed)
            let chunks = chunkDemoText(full)

            streamingTask = Task { [weak self] in
                guard let self = self else { return }
                for c in chunks {
                    if Task.isCancelled { return }
                    await MainActor.run { self.appendDemoChunk(c, to: assistantMsgId) }
                    try? await Task.sleep(nanoseconds: 160_000_000) // ~160ms between chunks
                }
                await MainActor.run {
                    self.streamingMessageId = nil
                    self.isStreaming = false
                    if self.streamingStatus != .idle {
                        self.streamingStatus = .done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                            self?.streamingStatus = .idle
                        }
                    }
                }
            }
            return
        }

        // Log current prompt state for debugging
        AppLogger.log("Sending message with prompt: model=\(activePrompt.openAIModel), enableComputerUse=\(activePrompt.enableComputerUse)", category: .ui, level: .info)

        // MCP gate for remote servers: require a successful list_tools probe with fresh token hash
        if activePrompt.enableMCPTool && !bypassMCPGate {
            let label = activePrompt.mcpServerLabel
            let url = activePrompt.mcpServerURL
            let isRemote = activePrompt.enableMCPTool && !activePrompt.mcpIsConnector && !label.isEmpty && !url.isEmpty
            if isRemote {
                let defaults = UserDefaults.standard
                let headers = activePrompt.secureMCPHeaders
                let desiredKeyRaw = activePrompt.mcpAuthHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines)
                let desiredKey = desiredKeyRaw.isEmpty ? "Authorization" : desiredKeyRaw
                let authHeader = headers[desiredKey] ?? headers["Authorization"]

                // 24h freshness window
                let maxAgeSeconds: Double = 86_400
                let now = Date().timeIntervalSince1970

                // Light Notion guardrail for remote HTTP MCP: integration tokens are invalid here
                let isNotionOfficial = url.lowercased().contains("mcp.notion.com")
                let looksLikeNotion = label.lowercased().contains("notion") || url.lowercased().contains("notion")
                if looksLikeNotion, let raw = authHeader {
                    let lower = raw.lowercased()
                    let tokenCore = lower.hasPrefix("bearer ") ? String(lower.dropFirst(7)) : lower
                    if tokenCore.hasPrefix("ntn_") || tokenCore.hasPrefix("secret_") {
                        if isNotionOfficial {
                            // Auto-fix: move integration token to top-level and remove Authorization header
                            var headersFix = activePrompt.secureMCPHeaders
                            headersFix.removeValue(forKey: desiredKey)
                            headersFix.removeValue(forKey: "Authorization")
                            activePrompt.secureMCPHeaders = headersFix
                            let rawTop = NotionAuthService.shared.stripBearer(raw)
                            KeychainService.shared.save(value: rawTop, forKey: "mcp_manual_\(label)")
                            saveActivePrompt()
                            let sys = ChatMessage(role: .system, text: "✅ Auto-corrected official Notion MCP auth (moved integration token to top‑level). Continuing")
                            messages.append(sys)
                            // Do not return; proceed
                        } else {
                            // Self-hosted with integration token in header: warn but do not block chat
                            let sys = ChatMessage(role: .system, text: "⚠️ This token looks like a Notion integration token, which is invalid for self‑hosted Notion MCP. Use the server‑issued Bearer token from your container logs. Continuing anyway, but the server may return 401.")
                            messages.append(sys)
                            // Do not return; proceed
                        }
                    }
                }

                // Probe state (list_tools health)
                let prOk = defaults.bool(forKey: "mcp_probe_ok_\(label)")
                let prAt = defaults.double(forKey: "mcp_probe_ok_at_\(label)")
                let prFresh = prAt > 0 && (now - prAt) < maxAgeSeconds
                let currentHash: String? = {
                    if let authHeader = authHeader {
                        return NotionAuthService.shared.tokenHash(fromAuthorizationValue: authHeader)
                    }
                    if isNotionOfficial {
                        if let stored = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), !stored.isEmpty {
                            return NotionAuthService.shared.tokenHash(fromAuthorizationValue: stored)
                        }
                    }
                    return nil
                }()
                let prStoredHash = defaults.string(forKey: "mcp_probe_token_hash_\(label)")
                let prHashMatch = (prStoredHash != nil && currentHash != nil && prStoredHash == currentHash)

                let probeSatisfied = prOk && prFresh && prHashMatch

                if !probeSatisfied {
                    let labelForLog = label.isEmpty ? "(unnamed)" : label
                    AppLogger.log("⛔️ [MCP Gate] Remote MCP probe not satisfied for '\(labelForLog)': ok=\(prOk), fresh=\(prFresh), hashMatch=\(prHashMatch). Attempting MCP health probe", category: .openAI, level: .warning)
                    if authHeader == nil && !isNotionOfficial {
                        let guidance = "MCP server needs validation. Open MCP Connector Gallery → Remote server → Test MCP Connection (should show tool count). No Authorization header found in current configuration."
                        let sys = ChatMessage(role: .system, text: guidance)
                        messages.append(sys)
                        return
                    }
                    logActivity("Running MCP tool diagnostics")
                    Task { [weak self] in
                        guard let self = self else { return }
                        do {
                            let result = try await self.api.probeMCPListTools(prompt: self.activePrompt)
                            await MainActor.run {
                                let d = UserDefaults.standard
                                d.set(true, forKey: "mcp_probe_ok_\(label)")
                                d.set(Date().timeIntervalSince1970, forKey: "mcp_probe_ok_at_\(label)")
                                if let authHeader = authHeader {
                                    let authHash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: authHeader)
                                    d.set(authHash, forKey: "mcp_probe_token_hash_\(label)")
                                } else if isNotionOfficial {
                                    // Official Notion MCP uses top-level token; persist its hash for future gate checks
                                    if let stored = KeychainService.shared.load(forKey: "mcp_manual_\(label)"), !stored.isEmpty {
                                        let authHash = NotionAuthService.shared.tokenHash(fromAuthorizationValue: stored)
                                        d.set(authHash, forKey: "mcp_probe_token_hash_\(label)")
                                    }
                                }
                                d.set(result.count, forKey: "mcp_probe_tool_count_\(label)")
                                AppLogger.log("✅ [MCP Gate] MCP probe succeeded for '\(result.label)': \(result.count) tools. Continuing send", category: .openAI, level: .info)
                                self.logActivity("MCP tools validated (\(result.count))")
                                // Retry sending the original message, bypassing the gate this once.
                                self.sendUserMessage(trimmed, bypassMCPGate: true)
                            }
                        } catch {
                            await MainActor.run {
                                AppLogger.log("❌ [MCP Gate] MCP probe failed for '\(labelForLog)': \(error.localizedDescription)", category: .openAI, level: .error)
                                let msg = "MCP tools list failed. Open MCP Connector Gallery → Remote server → Test MCP Connection (should show tool count). Details: \(error.localizedDescription.prefix(180))"
                                let sys = ChatMessage(role: .system, text: msg)
                                self.messages.append(sys)
                            }
                        }
                    }
                    return
                }
            }
        }

        // Cancel any existing streaming task before starting a new one.
        // This prevents receiving chunks from a previous, unfinished stream.
        streamingTask?.cancel()
        surfacedMCPToolWarnings.removeAll()
        // Determine streaming mode up front for logging and flow control
        let streamingEnabled = activePrompt.enableStreaming
        // Keep recent activity so users can see context; do not clear here to avoid flashing.
    logActivity("Connecting to OpenAI API")
        logActivity(streamingEnabled ? "Streaming mode enabled" : "Using non-streaming mode")

        // Append the user's message to the chat with URL detection
        let userMsg = ChatMessage.withURLDetection(role: .user, text: trimmed, images: nil)
        messages.append(userMsg)

    // Prepare a placeholder for the assistant's streaming response
        let assistantMsgId = UUID()
        let assistantMsg = ChatMessage(id: assistantMsgId, role: .assistant, text: "", images: nil)
        messages.append(assistantMsg)
        streamingMessageId = assistantMsgId // Track the new message for streaming
    resetStreamingReasoning(for: assistantMsgId)

        // Disable input while processing
        isStreaming = true

        // Prepare attachments if any are pending
        let attachments: [[String: Any]]? = pendingFileAttachments.isEmpty ? nil : pendingFileAttachments.map { fileId in
            return ["file_id": fileId, "tools": [["type": "file_search"]]]
        }

        // Prepare image attachments if any are pending
        let imageAttachments: [InputImage]? = pendingImageAttachments.isEmpty ? nil : pendingImageAttachments.map { image in
            return InputImage(image: image, detail: selectedImageDetailLevel)
        }

    // Audio removed: no audioAttachment

        // Clear pending attachments now that they are included in the request
        if attachments != nil {
            pendingFileAttachments.removeAll()
        }
        if imageAttachments != nil {
            pendingImageAttachments.removeAll()
        }
        // NOTE: Don't clear pendingFileData/pendingFileNames here - they're still needed for the API call
        // They will be cleared after successful API call completion
    // no-op: audio removed

        // streamingEnabled determined earlier
        print("Using \(streamingEnabled ? "streaming" : "non-streaming") mode")

        // Log the message sending event
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.messageSent,
            parameters: [
                AnalyticsParameter.model: activePrompt.openAIModel,
                AnalyticsParameter.messageLength: trimmed.count,
                AnalyticsParameter.streamingEnabled: streamingEnabled,
                "has_file_attachments": attachments != nil,
                "has_image_attachments": imageAttachments != nil,
                "has_audio_attachment": false,
                "image_count": imageAttachments?.count ?? 0
            ]
        )

    // Compose final user text (no audio flow)
    let finalUserText = trimmed

        // Capture the base previous_response_id for resilience. During streaming, lastResponseId will
        // change to the new streaming response ID; we keep this original value to enable safe retries.
        let basePreviousIdForThisSend = lastResponseId
        // Initialize a single retry attempt for transient model errors (only when streaming is enabled)
        if activePrompt.enableStreaming {
            retryContextByMessageId[assistantMsgId] = StreamRetryContext(
                remainingAttempts: 1,
                basePreviousResponseId: basePreviousIdForThisSend,
                userText: finalUserText,
                attachments: attachments,
                imageAttachments: imageAttachments
            )
        }

        // No audio path: proceed immediately
        // Call the OpenAI API asynchronously
    streamingTask = Task {
            await MainActor.run { self.streamingStatus = .connecting }
            do {
                // Handle file attachments with intelligent conversion to PDF
                var uploadedFileIds: [String] = []

                if !pendingFileData.isEmpty && !pendingFileNames.isEmpty {
                    AppLogger.log("📤 Processing \(pendingFileData.count) file(s) before sending message", category: .openAI, level: .info)

                    for (index, data) in pendingFileData.enumerated() {
                        guard index < pendingFileNames.count else { break }

                        let filename = pendingFileNames[index]
                        let fileExtension = (filename as NSString).pathExtension.lowercased()

                        var dataToUpload = data
                        var filenameToUpload = filename
                        var conversionMethod = "none"

                        // Check if file needs conversion to PDF for Responses API compatibility
                        if fileExtension != "pdf" {
                            // For text-based files, convert to PDF
                            if fileExtension == "txt" || fileExtension == "md" {
                                if let textContent = String(data: data, encoding: .utf8) {
                                    do {
                                        let conversionResult = try FileConverterService.convertTextToPDF(
                                            content: textContent,
                                            originalFilename: filename
                                        )
                                        dataToUpload = conversionResult.convertedData
                                        filenameToUpload = conversionResult.filename
                                        conversionMethod = "text→PDF"
                                        AppLogger.log("✅ Converted \(filename) to PDF (\(dataToUpload.count) bytes)", category: .openAI, level: .info)
                                    } catch {
                                        AppLogger.log("⚠️ Failed to convert \(filename) to PDF: \(error)", category: .openAI, level: .warning)
                                        await MainActor.run {
                                            self.errorMessage = "Failed to convert \(filename) to PDF. Try uploading to File Manager for vector search instead."
                                        }
                                        continue
                                    }
                                } else {
                                    AppLogger.log("⚠️ Could not decode text file \(filename)", category: .openAI, level: .warning)
                                    await MainActor.run {
                                        self.errorMessage = "Could not read text file \(filename)"
                                    }
                                    continue
                                }
                            } else {
                                // Unsupported file type for direct attachment
                                AppLogger.log("⚠️ Unsupported file type for direct attachment: \(filename) (.\(fileExtension))", category: .openAI, level: .warning)
                                await MainActor.run {
                                    self.errorMessage = "Only PDF and text files are supported for direct attachment. Please use the File Manager to upload \(filename) to a vector store for file search."
                                }
                                continue
                            }
                        }

                        // Upload to Files API
                        do {
                            let uploadedFile = try await api.uploadFile(
                                fileData: dataToUpload,
                                filename: filenameToUpload,
                                purpose: "assistants"
                            )
                            uploadedFileIds.append(uploadedFile.id)

                            if conversionMethod != "none" {
                                AppLogger.log("✅ Uploaded converted file \(filenameToUpload) -> \(uploadedFile.id) (\(conversionMethod))", category: .openAI, level: .info)
                                await MainActor.run {
                                    self.logActivity("📄 Converted \(filename) to PDF for API compatibility")
                                }
                            } else {
                                AppLogger.log("✅ Uploaded \(filenameToUpload) -> \(uploadedFile.id)", category: .openAI, level: .info)
                            }
                        } catch {
                            AppLogger.log("❌ Failed to upload \(filenameToUpload): \(error)", category: .openAI, level: .error)
                            await MainActor.run {
                                self.errorMessage = "Failed to upload file \(filenameToUpload): \(error.localizedDescription)"
                            }
                        }
                    }
                }

                // If previous responses are awaiting computer_call_output, resolve them all first.
                // Only do this when the computer tool is both enabled and supported for the current model/streaming mode.
                if self.activePrompt.enableComputerUse {
                    let supported = ModelCompatibilityService.shared.isToolSupported(
                        APICapabilities.ToolType.computer,
                        for: self.activePrompt.openAIModel,
                        isStreaming: streamingEnabled
                    )
                    if supported {
                        _ = try? await self.resolveAllPendingComputerCallsIfAny(for: assistantMsgId)
                    } else {
                        AppLogger.log("[CUA] Skipping pending-call resolution (tool unsupported for model/stream)", category: .openAI, level: .debug)
                    }
                }
                if streamingEnabled {
                    // Use streaming API with uploaded file IDs
                    let stream = api.streamChatRequest(
                        userMessage: finalUserText,
                        prompt: activePrompt,
                        attachments: attachments,
                        fileData: nil,  // Files are now uploaded and converted
                        fileNames: nil,
                        fileIds: uploadedFileIds.isEmpty ? nil : uploadedFileIds,
                        imageAttachments: imageAttachments,
                        previousResponseId: lastResponseId,
                        conversationId: activeConversation?.remoteId
                    )

                    for try await chunk in stream {
                        // Check for cancellation before handling the next chunk
                        if Task.isCancelled {
                            await MainActor.run {
                                self.handleError(CancellationError())
                                self.logActivity("Cancelled")
                            }
                            break
                        }
                        await MainActor.run {
                            self.handleStreamChunk(chunk, for: assistantMsgId)
                        }
                    }
                } else {
                    // Use non-streaming API with uploaded file IDs
                    let response = try await api.sendChatRequest(
                        userMessage: finalUserText,
                        prompt: activePrompt,
                        attachments: attachments,
                        fileData: nil,  // Files are now uploaded and converted
                        fileNames: nil,
                        fileIds: uploadedFileIds.isEmpty ? nil : uploadedFileIds,
                        imageAttachments: imageAttachments,
                        previousResponseId: lastResponseId,
                        conversationId: activeConversation?.remoteId
                    )

                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: assistantMsgId)
                        self.logActivity("Response received")
                    }
                }
            } catch {
                // Handle errors on main thread, unless it's a cancellation
                if !(error is CancellationError) {
                    await MainActor.run {
                        self.handleError(error)
                        self.logActivity("Error: \(error.localizedDescription)")
                        // Clear pending files on error so they don't get stuck
                        self.clearPendingFileAttachments()
                        // Remove the placeholder message on error
                        self.messages.removeAll { $0.id == assistantMsgId }
                        // CRITICAL: Complete streaming state reset on error
                        self.streamingMessageId = nil
                        self.isStreaming = false
                        Task { @MainActor in
                            try await Task.sleep(for: .seconds(2)) // Allows user to see the error
                            self.streamingStatus = .idle
                        }
                    }
                }
            }
            // Ensure we clear the streaming ID when the task is done, after do-catch
            await MainActor.run {
                // If a retry is in progress for this message, skip cleanup/logging here to avoid
                // stomping the retry's state (flicker) and duplicate analytics.
                let retryActive = self.retryContextByMessageId[assistantMsgId]?.retryScheduled == true
                guard !retryActive else {
                    print("Streaming aborted; retry in progress for message: \(assistantMsgId)")
                    return
                }

                // Log the final streamed message
                if let finalMessage = self.messages.first(where: { $0.id == assistantMsgId }) {
                    print("Finished streaming response: \(finalMessage.text ?? "No text content")")

                    // Log the received message
                    AnalyticsService.shared.trackEvent(
                        name: AnalyticsEvent.messageReceived,
                        parameters: [
                            AnalyticsParameter.model: self.activePrompt.openAIModel,
                            AnalyticsParameter.messageLength: finalMessage.text?.count ?? 0,
                            AnalyticsParameter.streamingEnabled: true,
                            "has_images": finalMessage.images?.isEmpty == false
                        ]
                    )
                }

                self.streamingMessageId = nil
                self.isStreaming = false // Re-enable input
                // Stop any image generation heartbeats
                self.stopImageGenerationHeartbeat(for: assistantMsgId)
                // Mark as done and reset after a delay, unless we're awaiting computer output
                if self.isAwaitingComputerOutput {
                    self.streamingStatus = .usingComputer
                } else if self.streamingStatus != .idle {
                    self.streamingStatus = .done
                    self.logActivity("Done")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        self?.streamingStatus = .idle
                    }
                }
            }
        }
    }

    /// Resolve all pending computer_call items before proceeding (handles chained calls like wait → screenshot).
    private func resolveAllPendingComputerCallsIfAny(for messageId: UUID) async throws -> Bool {
        guard activePrompt.enableComputerUse else { return false }

        // Prevent concurrent execution - only one resolution process at a time
        guard !isResolvingComputerCalls else { 
            AppLogger.log("[CUA] resolveAllPending: Already resolving, skipping", category: .openAI, level: .info)
            return false
        }
        isResolvingComputerCalls = true
        defer { isResolvingComputerCalls = false }

        var resolvedAny = false
        var safetyCounter = 0
        while safetyCounter < 5 { // Reduced from 8 to 5 to prevent infinite loops
            safetyCounter += 1
            guard let prevId = lastResponseId else { break }
            AppLogger.log("[CUA] resolveAllPending: Getting response for prevId=\(prevId) (attempt \(safetyCounter)/5)", category: .openAI, level: .info)
            let full: OpenAIResponse
            do { full = try await api.getResponse(responseId: prevId) } catch {
                AppLogger.log("[CUA] getResponse failed while resolving pending calls: \(error)", category: .openAI, level: .warning)
                await MainActor.run { self.lastResponseId = nil }
                break
            }

            // Log all computer call items in the response
            let computerCalls = full.output.filter { $0.type == "computer_call" }
            AppLogger.log("[CUA] resolveAllPending: Found \(computerCalls.count) computer_call items in response", category: .openAI, level: .info)
            for (index, call) in computerCalls.enumerated() {
                AppLogger.log("[CUA] resolveAllPending: computerCall[\(index)]: id=\(call.id), callId=\(call.callId ?? "nil")", category: .openAI, level: .info)
            }

            guard let computerCallItem = full.output.last(where: { $0.type == "computer_call" }) else { break }

            if !activePrompt.ultraStrictComputerUse {
                // HEURISTIC: If we get multiple screenshot calls but the message already has an image,
                // halt to prevent screenshot loops. But allow navigation, clicks, and typing actions.
                if let message = messages.first(where: { $0.id == messageId }), !(message.images?.isEmpty ?? true) {
                    // Check if this is a screenshot action - if so, halt to prevent loops
                    if let action = computerCallItem.action,
                       let actionType = action["type"]?.value as? String,
                       actionType == "screenshot" {
                        AppLogger.log("[CUA] resolveAllPending: Heuristic halt: Message already contains screenshot and another screenshot was requested. Halting to prevent screenshot loops.", category: .openAI, level: .info)
                        await MainActor.run { 
                            self.streamingStatus = .idle // Final state reset
                            self.lastResponseId = nil // Clear to prevent future loops
                        }
                        break // Skip this tool call and exit the loop
                    }

                    // AGGRESSIVE LOOP PREVENTION: If we've made multiple attempts and still on about:blank, stop
                    if safetyCounter >= 3, let action = computerCallItem.action,
                       let actionType = action["type"]?.value as? String,
                       (actionType == "click" || actionType == "type") {
                        AppLogger.log("[CUA] resolveAllPending: Loop prevention: Too many actions (\(safetyCounter)) without progress. Halting.", category: .openAI, level: .warning)
                        await MainActor.run { 
                            self.streamingStatus = .idle
                            self.lastResponseId = nil
                        }
                        break
                    }

                    // URGENT INTERVENTION: If still on about:blank after first action and it's trying to click, stop
                    if safetyCounter >= 2, computerService.isOnBlankPage(),
                       let action = computerCallItem.action,
                       let actionType = action["type"]?.value as? String,
                       actionType == "click" {
                        AppLogger.log("[CUA] resolveAllPending: URGENT: Still clicking on about:blank after attempt \(safetyCounter). AI is not using navigate action properly. Stopping.", category: .openAI, level: .error)
                        await MainActor.run { 
                            self.streamingStatus = .idle
                            self.lastResponseId = nil
                        }
                        break
                    }

                    // Allow navigation, clicks, typing, etc. even if there's already an image
                    AppLogger.log("[CUA] resolveAllPending: Message has image but allowing non-screenshot action: \(String(describing: computerCallItem.action))", category: .openAI, level: .info)
                }
            }

            AppLogger.log("[CUA] resolveAllPending: Processing computerCall id=\(computerCallItem.id), callId=\(computerCallItem.callId ?? "nil")", category: .openAI, level: .info)
            resolvedAny = true
            await MainActor.run { self.isAwaitingComputerOutput = true; self.streamingStatus = .usingComputer }
            do {
                try await handleComputerToolCallFromOutputItem(computerCallItem, previousId: prevId, messageId: messageId)
                // handleNonStreamingResponse inside will update lastResponseId
            } catch {
                AppLogger.log("[CUA] resolveAllPendingComputerCallsIfAny error: \(error)", category: .openAI, level: .warning)
                await MainActor.run { self.lastResponseId = nil; self.isAwaitingComputerOutput = false }
                break
            }
            await MainActor.run {
                // Don't clear awaiting flag if a safety approval is pending
                if self.pendingSafetyApproval == nil {
                    self.isAwaitingComputerOutput = false
                }
            }
            // Loop will check the newly updated lastResponseId for further pending calls
        }

        // Reset wait counter when computer use chain completes (successful or not)
        await MainActor.run { 
            self.consecutiveWaitCount = 0
            // Only clean up stream state if we're not currently in an active streaming session
            // The condition "lastResponseId == nil" was incorrectly triggering at the start of new streams
            // Instead, check if streaming is actually done (not just nil lastResponseId)
            if self.streamingMessageId != nil && !self.isStreaming {
                self.streamingMessageId = nil
                self.streamingStatus = .idle
            }
        }

        return resolvedAny
    }

    /// Handles a computer tool call using a full-response OutputItem (not streaming) and a known previousId
    private func handleComputerToolCallFromOutputItem(_ outputItem: OutputItem, previousId: String, messageId: UUID) async throws {
        guard outputItem.type == "computer_call" else { return }
        let callId = outputItem.callId ?? ""
        AppLogger.log("[CUA] (resume) OutputItem callId='\(callId)', id='\(outputItem.id)'", category: .openAI, level: .info)
        guard !callId.isEmpty else { throw OpenAIServiceError.invalidResponseData }
        guard var actionData = extractComputerActionFromOutputItem(outputItem) else { throw OpenAIServiceError.invalidResponseData }

        if !activePrompt.ultraStrictComputerUse {
            if actionData.type == "screenshot", actionData.parameters["url"] == nil,
               let derived = deriveURLForScreenshot(from: messageId) {
                AppLogger.log("[CUA] (resume) Auto-attaching URL to screenshot action: \(derived.absoluteString)", category: .openAI, level: .info)
                actionData = ComputerAction(type: "screenshot", parameters: ["url": derived.absoluteString])
            }
        }

        if let safetyChecks = outputItem.pendingSafetyChecks, !safetyChecks.isEmpty {
            AppLogger.log("[CUA] (resume) SAFETY CHECKS DETECTED: \(safetyChecks.count) checks pending", category: .openAI, level: .warning)
            for check in safetyChecks {
                AppLogger.log("[CUA] (resume) Safety Check - \(check.code): \(check.message)", category: .openAI, level: .warning)
            }
            await MainActor.run {
                self.pendingSafetyApproval = SafetyApprovalRequest(
                    checks: safetyChecks,
                    callId: callId,
                    action: actionData,
                    previousResponseId: previousId,
                    messageId: messageId
                )
                self.isAwaitingComputerOutput = true
                self.streamingStatus = .usingComputer
                let sys = ChatMessage(role: .system, text: "⚠️ Action requires approval before proceeding.")
                self.messages.append(sys)
            }
            return
        }

        if !activePrompt.ultraStrictComputerUse {
            if actionData.type == "click" && computerService.isOnBlankPage(),
               let derived = deriveURLForScreenshot(from: messageId) {
                AppLogger.log("[CUA] (resume) WebView blank before click; navigating to derived URL: \(derived.absoluteString)", category: .openAI, level: .info)
                _ = try? await computerService.executeAction(ComputerAction(type: "navigate", parameters: ["url": derived.absoluteString]))
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }

        if !activePrompt.ultraStrictComputerUse {
            if !appliedSearchOverrideForMessage.contains(messageId),
               let searchQuery = extractExplicitSearchQuery(for: messageId) {
                let refined = refineSearchPhrase(searchQuery)
                AppLogger.log("[CUA] (resume) Intent override: performing search for query '\(refined)' on current engine", category: .openAI, level: .info)
                do { try await computerService.performSearchIfOnKnownEngine(query: refined) } catch {
                    AppLogger.log("[CUA] (resume) performSearchIfOnKnownEngine failed: \(error)", category: .openAI, level: .warning)
                }
                appliedSearchOverrideForMessage.insert(messageId)
            }
        }

        if !activePrompt.ultraStrictComputerUse {
            if actionData.type == "click", let targetName = extractExplicitClickTarget(for: messageId) {
                if let pt = try? await computerService.findClickablePointByVisibleText(targetName) {
                    AppLogger.log("[CUA] (resume) Click-by-text override resolved '\(targetName)' -> (\(pt.x), \(pt.y))", category: .openAI, level: .info)
                    actionData = ComputerAction(type: "click", parameters: ["x": pt.x, "y": pt.y, "button": "left"])
                } else {
                    AppLogger.log("[CUA] (resume) Click-by-text override failed to resolve target '\(targetName)'; proceeding with model coordinates", category: .openAI, level: .warning)
                }
            }
        }

        AppLogger.log("[CUA] (resume) Executing action type=\(actionData.type) for callId='\(callId)'", category: .openAI)
        let result = try await computerService.executeAction(actionData)

        var abortAfterOutput = false
        if actionData.type == "wait" {
            consecutiveWaitCount += 1
            AppLogger.log("[CUA] (resume) Wait action detected. Consecutive count: \(consecutiveWaitCount)/\(maxConsecutiveWaits)", category: .openAI, level: .warning)
            if consecutiveWaitCount >= maxConsecutiveWaits {
                abortAfterOutput = true
                AppLogger.log("[CUA] (resume) Reached max consecutive waits; will send output and then halt chain.", category: .openAI, level: .error)
            }
        } else {
            consecutiveWaitCount = 0
        }

        if let screenshot = result.screenshot, !screenshot.isEmpty {
            AppLogger.log("[CUA] (resume) Screenshot captured (\(screenshot.count) b64 chars), adding to message", category: .openAI, level: .info)
            await MainActor.run {
                if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                    var updatedMessage = self.messages[index]
                    if let imageData = Data(base64Encoded: screenshot), let rawImage = UIImage(data: imageData, scale: 1.0) {
                        let uiImage = rawImage
                        AppLogger.log("[CUA] (resume) Screenshot decoded successfully - Image size: \(uiImage.size), data length: \(imageData.count) bytes", category: .openAI, level: .info)
                        if updatedMessage.images == nil { updatedMessage.images = [] }
                        updatedMessage.images?.removeAll()
                        updatedMessage.images?.append(uiImage)
                        var updatedMessages = self.messages
                        updatedMessages[index] = updatedMessage
                        self.messages = updatedMessages
                        Task { @MainActor in
                            self.objectWillChange.send()
                            try? await Task.sleep(nanoseconds: 50_000_000)
                            self.objectWillChange.send()
                        }
                        AppLogger.log("[CUA] (resume) Successfully added screenshot to message UI - Image size: \(uiImage.size)", category: .openAI, level: .info)
                    } else {
                        AppLogger.log("[CUA] (resume) FAILED to decode screenshot base64 data", category: .openAI, level: .error)
                    }
                } else {
                    AppLogger.log("[CUA] (resume) FAILED to find message with id \(messageId)", category: .openAI, level: .error)
                }
            }

            let output: [String: Any] = [
                "type": "computer_screenshot",
                "image_url": "data:image/png;base64,\(screenshot)"
            ]

            let acknowledgedSafetyChecks = outputItem.pendingSafetyChecks
            if let safetyChecks = acknowledgedSafetyChecks {
                AppLogger.log("[CUA] (resume) Including \(safetyChecks.count) acknowledged safety checks for callId='\(callId)'", category: .openAI)
            }

            AppLogger.log("[CUA] (resume) Sending computer_call_output with callId='\(callId)'", category: .openAI, level: .info)

            let response = try await api.sendComputerCallOutput(
                callId: callId,
                output: output,
                model: activePrompt.openAIModel,
                previousResponseId: previousId,
                acknowledgedSafetyChecks: acknowledgedSafetyChecks,
                currentUrl: result.currentURL
            )
            if abortAfterOutput {
                await MainActor.run {
                    self.consecutiveWaitCount = 0
                    self.isAwaitingComputerOutput = false
                    self.isStreaming = false
                    self.streamingStatus = .idle
                    self.lastResponseId = nil
                    let sys = ChatMessage(
                        role: .system,
                        text: "⚠️ Computer use interrupted: Too many consecutive wait actions. I sent the last screenshot and stopped."
                    )
                    self.messages.append(sys)
                }
            } else {
                await MainActor.run { self.handleNonStreamingResponse(response, for: messageId) }
            }
        } else {
            AppLogger.log("[CUA] (resume) No screenshot; clearing previousId", category: .openAI, level: .warning)
            await MainActor.run { self.lastResponseId = nil }
        }
    }

    /// Batches parallel function calls from the same response to send together
    private func handleFunctionCallWithBatching(_ call: OutputItem, for messageId: UUID, responseId: String) async {
        var canonicalCallId: String?
        var shouldExecute = false

        await MainActor.run {
            guard let resolvedId = self.canonicalIdentifier(for: call) else {
                AppLogger.log("❌ [Batching] Received function call without identifier for response \(responseId)", category: .openAI, level: .error)
                return
            }

            canonicalCallId = resolvedId

            if self.completedFunctionCallIds.contains(resolvedId) {
                AppLogger.log("♻️ [Batching] Call \(resolvedId) already completed; skipping re-execution", category: .openAI, level: .info)
                return
            }

            if self.pendingFunctionCallIds.contains(resolvedId) {
                AppLogger.log("♻️ [Batching] Call \(resolvedId) is already pending; ignoring duplicate trigger", category: .openAI, level: .debug)
                return
            }

            var registeredCalls = self.pendingParallelCalls[responseId] ?? []
            let alreadyRegistered = registeredCalls.contains { existing in
                guard let existingId = self.canonicalIdentifier(for: existing) else { return false }
                return existingId == resolvedId
            }

            if !alreadyRegistered {
                self.pendingFunctionCallIds.insert(resolvedId)
                registeredCalls.append(call)
                self.pendingParallelCalls[responseId] = registeredCalls
                self.registerFunctionCallIdentifiers(call, canonicalId: resolvedId, responseId: responseId)
                AppLogger.log("📦 [Batching] Registered call \(resolvedId) for response \(responseId). Current batch size: \(registeredCalls.count)", category: .openAI, level: .info)
                shouldExecute = true
            } else {
                self.pendingParallelCalls[responseId] = registeredCalls
                AppLogger.log("📦 [Batching] Call \(resolvedId) already registered for response \(responseId); preventing duplicate registration", category: .openAI, level: .debug)
                return
            }
        }

        guard shouldExecute, let canonicalCallId else { return }

        guard let functionName = call.name else {
            AppLogger.log("❌ [Function Call] No function name in call item", category: .ui, level: .error)
            _ = await MainActor.run { self.pendingFunctionCallIds.remove(canonicalCallId) }
            return
        }

        let output = await executeFunction(call, for: messageId)
        guard let output else {
            _ = await MainActor.run { self.pendingFunctionCallIds.remove(canonicalCallId) }
            return
        }

        if let summary = FunctionOutputSummarizer.failureSummary(functionName: functionName, rawOutput: output) {
            await MainActor.run {
                self.recordFunctionOutputSummary(summary, for: messageId)
            }
        }

        await MainActor.run {
            if self.parallelCallOutputs[responseId] == nil {
                self.parallelCallOutputs[responseId] = [:]
            }
            self.parallelCallOutputs[responseId]?[canonicalCallId] = output
            self.functionCallResponseIds[canonicalCallId] = responseId

            let currentBatch = self.pendingParallelCalls[responseId] ?? []
            let completedCount = self.parallelCallOutputs[responseId]?.count ?? 0

            AppLogger.log("📦 [Batching] Stored output for \(canonicalCallId). Completed \(completedCount)/\(currentBatch.count) calls", category: .openAI, level: .info)

            if completedCount == currentBatch.count {
                AppLogger.log("✅ [Batching] All \(currentBatch.count) parallel calls complete for response \(responseId). Sending batch.", category: .openAI, level: .info)

                self.parallelCallBatchTimer[responseId]?.cancel()
                self.parallelCallBatchTimer.removeValue(forKey: responseId)

                Task { [weak self] in
                    await self?.sendBatchedFunctionOutputs(responseId: responseId, messageId: messageId)
                }
            } else {
                self.parallelCallBatchTimer[responseId]?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    Task { [weak self] in
                        await self?.sendBatchedFunctionOutputs(responseId: responseId, messageId: messageId)
                    }
                }
                self.parallelCallBatchTimer[responseId] = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)

                AppLogger.log("⏱️ [Batching] Waiting for remaining calls (timeout: 5s)", category: .openAI, level: .debug)
            }
        }
    }

    /// Executes a function and returns its output string
    private func executeFunction(_ call: OutputItem, for messageId: UUID) async -> String? {
        guard let functionName = call.name else { return nil }

        guard let callIdentifier = await MainActor.run(body: { self.canonicalIdentifier(for: call) }) else {
            AppLogger.log("❌ [Function Call] Unable to determine canonical identifier", category: .openAI, level: .error)
            return nil
        }

        let alreadyCompleted = await MainActor.run { self.completedFunctionCallIds.contains(callIdentifier) }
        guard !alreadyCompleted else {
            AppLogger.log("♻️ [Function Call] Call \(callIdentifier) already completed; skipping", category: .openAI, level: .info)
            return nil
        }

        AppLogger.log("🔧 [Function Call] Executing: \(functionName)", category: .ui, level: .info)
        AppLogger.log("🔧 [Function Call] Call ID: \(callIdentifier)", category: .ui, level: .info)
        AppLogger.log("🔧 [Function Call] Arguments: \(call.arguments ?? "none")", category: .ui, level: .info)

        let notionFunctions: Set<String> = [
            "searchNotion",
            "getNotionDatabase",
            "getNotionDataSource",
            "createNotionPage",
            "updateNotionPage",
            "appendNotionBlocks"
        ]
        #if canImport(EventKit)
        let baseAppleFunctions = [
            "fetchAppleCalendarEvents",
            "fetchAppleReminders",
            "createAppleCalendarEvent",
            "createAppleReminder"
        ]
        #if canImport(Contacts)
        let appleFunctions = Set(baseAppleFunctions + [
            "searchAppleContacts",
            "getAppleContact",
            "createAppleContact"
        ])
        #else
        let appleFunctions = Set(baseAppleFunctions)
        #endif
        #else
        let appleFunctions = Set<String>()
        #endif

        // Short-circuit tool calls that were disabled in Settings
        var output: String?
        if notionFunctions.contains(functionName) && !activePrompt.enableNotionIntegration {
            AppLogger.log("🔒 [Function Call] Blocked Notion function \(functionName) – integration disabled in settings", category: .ui, level: .info)
            output = "Error: Notion integration is disabled in Settings."
        } else if appleFunctions.contains(functionName) && !activePrompt.enableAppleIntegrations {
            AppLogger.log("🔒 [Function Call] Blocked Apple system function \(functionName) – integrations disabled in settings", category: .ui, level: .info)
            output = "Error: Apple system integrations are disabled in Settings."
        }

        if output == nil {
            // Execute the actual function (use existing switch from handleFunctionCall)
            output = await executeFunctionSwitch(functionName, call: call, messageId: messageId)
        }

        return output
    }

    /// Sends all batched function outputs for a response together
    private func sendBatchedFunctionOutputs(responseId: String, messageId: UUID) async {
        guard let calls = pendingParallelCalls[responseId],
              var outputs = parallelCallOutputs[responseId],
              !calls.isEmpty else {
            AppLogger.log("⚠️ [Batching] No calls or outputs found for response \(responseId)", category: .openAI, level: .warning)
            return
        }

        var payloads: [FunctionCallOutputPayload] = []
        var seenCanonicalIds = Set<String>()
        var completedThisBatch = Set<String>()
        var missingOutputs = Set<String>()

        for call in calls {
            guard let canonicalId = canonicalIdentifier(for: call) else {
                AppLogger.log("⚠️ [Batching] Skipping call without canonical identifier in response \(responseId)", category: .openAI, level: .warning)
                continue
            }

            if seenCanonicalIds.contains(canonicalId) {
                AppLogger.log("📦 [Batching] Removing duplicate registration for call \(canonicalId) before sending batch", category: .openAI, level: .debug)
                continue
            }

            var resolvedOutput = outputs[canonicalId]

            if resolvedOutput == nil {
                if let aliasEntry = outputs.first(where: { key, _ in
                    key != canonicalId && (functionCallCanonicalIds[key] ?? key) == canonicalId
                }) {
                    AppLogger.log("♻️ [Batching] Migrating cached output from alias \(aliasEntry.key) to canonical \(canonicalId)", category: .openAI, level: .debug)
                    outputs.removeValue(forKey: aliasEntry.key)
                    outputs[canonicalId] = aliasEntry.value
                    migrateFunctionCallIdentifier(from: aliasEntry.key, to: canonicalId)
                    resolvedOutput = aliasEntry.value
                }
            }

            guard let output = resolvedOutput else {
                AppLogger.log("⚠️ [Batching] Missing output for call \(canonicalId), skipping", category: .openAI, level: .warning)
                missingOutputs.insert(canonicalId)
                continue
            }

            let payload = FunctionCallOutputPayload(
                callId: canonicalId,
                output: output,
                functionName: call.name ?? "unknown",
                callItem: call
            )
            payloads.append(payload)
            seenCanonicalIds.insert(canonicalId)
            completedThisBatch.insert(canonicalId)
        }

        parallelCallOutputs[responseId] = outputs

        pendingFunctionCallIds.subtract(missingOutputs)

        guard !payloads.isEmpty else {
            AppLogger.log("⚠️ [Batching] No valid payloads constructed for response \(responseId)", category: .openAI, level: .warning)
            pendingParallelCalls.removeValue(forKey: responseId)
            parallelCallOutputs.removeValue(forKey: responseId)
            parallelCallBatchTimer.removeValue(forKey: responseId)
            return
        }

        AppLogger.log("📤 [Batching] Sending \(payloads.count) function outputs together for response \(responseId)", category: .openAI, level: .info)

        let priorResponseId = lastResponseId
        let callsSnapshot = calls
        let outputsSnapshot = outputs

        let succeeded = await sendFunctionOutputBatch(
            payloads,
            messageId: messageId,
            responseId: responseId,
            priorResponseId: priorResponseId
        )

        if succeeded {
            completedFunctionCallIds.formUnion(completedThisBatch)
            pendingFunctionCallIds.subtract(completedThisBatch)
            pendingParallelCalls.removeValue(forKey: responseId)
            parallelCallOutputs.removeValue(forKey: responseId)
            parallelCallBatchTimer.removeValue(forKey: responseId)
            functionCallResponseIds = functionCallResponseIds.filter { $0.value != responseId }
        } else {
            for id in completedThisBatch {
                completedFunctionCallIds.remove(id)
                pendingFunctionCallIds.insert(id)
            }

            parallelCallBatchTimer.removeValue(forKey: responseId)
            pendingParallelCalls[responseId] = callsSnapshot
            parallelCallOutputs[responseId] = outputsSnapshot
            let retryWorkItem = DispatchWorkItem { [weak self] in
                Task { [weak self] in
                    await self?.sendBatchedFunctionOutputs(responseId: responseId, messageId: messageId)
                }
            }
            parallelCallBatchTimer[responseId] = retryWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: retryWorkItem)
            AppLogger.log("⏱️ [Batching] Retrying batch for response \(responseId) in 1s", category: .openAI, level: .debug)
        }
    }

    /// Sends a batch of function call outputs back to the API (used by batching logic)
    private func sendFunctionOutputBatch(
        _ payloads: [FunctionCallOutputPayload],
        messageId: UUID,
        responseId: String,
        priorResponseId: String?
    ) async -> Bool {
        guard !payloads.isEmpty else { return true }

        AppLogger.log("📤 [Batch] Sending \(payloads.count) outputs for response \(responseId)", category: .openAI, level: .info)

        let supportsReasoning = ModelCompatibilityService.shared.getCapabilities(for: activePrompt.openAIModel)?.supportsReasoningEffort == true
        var previousResponseIdForAttempt = priorResponseId
        var reasoningItemsForAttempt: [[String: Any]]?
        var retainedReasoningItems: [[String: Any]]?

        if supportsReasoning, let referenceId = priorResponseId {
            let cached = reasoningBufferByResponseId[referenceId]
            let awaited = await awaitReasoningPayload(for: referenceId, existingPayloads: cached)
            reasoningItemsForAttempt = awaited
            retainedReasoningItems = awaited ?? cached

            if let current = reasoningItemsForAttempt, reasoningPayloadsRequireSummary(current) {
                AppLogger.log("🧠 [Batch] Refreshing reasoning payload from response \(referenceId)", category: .openAI, level: .info)
                do {
                    let fetched = try await api.getResponse(responseId: referenceId)
                    let refreshed = fetched.output.compactMap { makeReasoningPayload(from: $0) }
                    if !refreshed.isEmpty {
                        reasoningItemsForAttempt = refreshed
                        retainedReasoningItems = refreshed
                    }
                } catch {
                    AppLogger.log("⚠️ [Batch] Failed to refresh reasoning items: \(error)", category: .openAI, level: .warning)
                    if case OpenAIServiceError.requestFailed(let statusCode, let message) = error,
                       statusCode == 404 || message.lowercased().contains("not found") {
                        AppLogger.log("♻️ [Batch] Dropping previous_response_id after 404 for \(referenceId)", category: .openAI, level: .info)
                        previousResponseIdForAttempt = nil
                        reasoningItemsForAttempt = retainedReasoningItems
                    } else if reasoningItemsForAttempt == nil {
                        reasoningItemsForAttempt = retainedReasoningItems
                    }
                }
            }

            if let sanitized = sanitizedReasoningPayloads(reasoningItemsForAttempt) {
                reasoningItemsForAttempt = sanitized
                retainedReasoningItems = sanitized
            }
        }

        let shouldStreamFollowUp = activePrompt.enableStreaming
        var followUpCompleted = false
        var attemptsRemaining = previousResponseIdForAttempt == nil ? 1 : 2
        var capturedError: Error?

        attemptLoop: while attemptsRemaining > 0 && !followUpCompleted {
            do {
                if shouldStreamFollowUp {
                    AppLogger.log("📤 [Batch] Streaming batch to OpenAI", category: .openAI, level: .info)
                    if attemptsRemaining == (previousResponseIdForAttempt == nil ? 1 : 2) {
                        streamingMessageId = messageId
                        isStreaming = true
                        streamingStatus = .connecting
                        resetStreamingReasoning(for: messageId)
                    }

                    // NOTE: We do NOT send reasoning items with function outputs.
                    // Per commit 75f6597: "Do NOT replay reasoning items here - they belong to the previous turn"
                    let stream = api.streamFunctionOutputs(
                        outputs: payloads,
                        model: activePrompt.openAIModel,
                        reasoningItems: nil,
                        previousResponseId: previousResponseIdForAttempt,
                        conversationId: activeConversation?.remoteId,
                        prompt: activePrompt
                    )

                    var cancelledMidStream = false
                    for try await chunk in stream {
                        if Task.isCancelled {
                            cancelledMidStream = true
                            handleError(CancellationError())
                            logActivity("Cancelled")
                            break
                        }
                        handleStreamChunk(chunk, for: messageId)
                    }

                    if !cancelledMidStream {
                        followUpCompleted = true
                        if let finalMessage = messages.first(where: { $0.id == messageId }) {
                            AnalyticsService.shared.trackEvent(
                                name: AnalyticsEvent.messageReceived,
                                parameters: [
                                    AnalyticsParameter.model: activePrompt.openAIModel,
                                    AnalyticsParameter.messageLength: finalMessage.text?.count ?? 0,
                                    AnalyticsParameter.streamingEnabled: true,
                                    "has_images": finalMessage.images?.isEmpty == false
                                ]
                            )
                        }
                    } else {
                        capturedError = CancellationError()
                        break
                    }
                } else {
                    AppLogger.log("⚠️ [Batch] Non-streaming batch not implemented", category: .openAI, level: .warning)
                    capturedError = NSError(domain: "BatchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Non-streaming batch not supported"])
                    break
                }
            } catch {
                capturedError = error

                if attemptsRemaining > 1 && isPreviousResponseNotFoundError(error) {
                    AppLogger.log("♻️ [Batch] Retrying without previous_response_id after API rejection", category: .openAI, level: .info)
                    previousResponseIdForAttempt = nil
                    reasoningItemsForAttempt = retainedReasoningItems
                    attemptsRemaining -= 1
                    continue attemptLoop
                }

                break
            }

            if followUpCompleted {
                break
            }

            attemptsRemaining -= 1
        }

        if followUpCompleted {
            if let key = priorResponseId,
               let retained = retainedReasoningItems,
               !retained.isEmpty {
                updateReasoningBuffer(with: retained, responseId: key)
            }
            return true
        }

        if let error = capturedError, !(error is CancellationError) {
            AppLogger.log("❌ [Batch] Error while returning batch: \(error)", category: .openAI, level: .error)
            if shouldSurfaceBatchError(error) {
                handleError(error)
            } else {
                AppLogger.log("ℹ️ [Batch] Suppressed known transient batch error", category: .openAI, level: .info)
            }
        }

        return false
    }

    /// Extracts function execution logic (the big switch statement) to be reused by both batching and non-batching paths
    private func executeFunctionSwitch(_ functionName: String, call: OutputItem, messageId: UUID) async -> String? {
        var output: String?

        switch functionName {
        case "searchNotion":
            struct NotionSearchArgs: Decodable {
                let query: String
                let filter_type: String?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for searchNotion."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(NotionSearchArgs.self, from: argsData)
                let trimmedQuery = decodedArgs.query.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedFilter = NotionService.shared.normalizeSearchFilter(decodedArgs.filter_type)
                let maxResults = trimmedQuery.isEmpty ? 12 : 25
                AppLogger.log("🔍 [searchNotion] Query: \(trimmedQuery), Filter: \(normalizedFilter ?? "none")", category: .network, level: .info)
                logActivity("🔍 Searching Notion for \"\(trimmedQuery.isEmpty ? "(all)" : trimmedQuery)\"")

                let searchResult = try await NotionService.shared.search(
                    query: trimmedQuery,
                    filterType: normalizedFilter,
                    pageSize: maxResults
                )

                let compactResult = NotionService.shared.compactSearchResult(
                    searchResult,
                    maxResults: maxResults,
                    maxProperties: 10,
                    maxPreviewLength: 160
                )

                AppLogger.log("✅ [searchNotion] Got compact result, converting to JSON...", category: .network, level: .info)
                var jsonOutput = try NotionService.shared.prettyJSONString(from: compactResult)
                let safeLimit = 180_000

                if jsonOutput.count > safeLimit {
                    AppLogger.log("⚠️ [searchNotion] Result length \(jsonOutput.count) exceeds safe limit; applying truncation", category: .network, level: .warning)
                    let truncatedPreview = String(jsonOutput.prefix(safeLimit))
                    let truncatedPayload: [String: Any] = [
                        "warning": "Notion search result truncated to avoid context overflow. Refine your query to narrow results.",
                        "truncated": true,
                        "original_length": jsonOutput.count,
                        "preview": truncatedPreview
                    ]
                    jsonOutput = try NotionService.shared.prettyJSONString(from: truncatedPayload)
                }

                output = jsonOutput
                AppLogger.log("✅ [searchNotion] JSON output length: \(jsonOutput.count) chars", category: .network, level: .info)
                AppLogger.log("📋 [searchNotion] Output preview: \(String(jsonOutput.prefix(200)))...", category: .network, level: .info)
            } catch {
                let errorMsg = "Error processing searchNotion: \(error.localizedDescription)"
                AppLogger.log("❌ [searchNotion] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
            }

        case "getNotionDatabase":
            struct NotionGetDbArgs: Decodable {
                let database_id: String
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for getNotionDatabase."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(NotionGetDbArgs.self, from: argsData)
                AppLogger.log("📊 [getNotionDatabase] Database ID: \(decodedArgs.database_id)", category: .network, level: .info)
                logActivity("📊 Fetching Notion database \(decodedArgs.database_id)")
                let dbResult = try await NotionService.shared.getDatabase(databaseId: decodedArgs.database_id)
                AppLogger.log("✅ [getNotionDatabase] Got result, converting to JSON...", category: .network, level: .info)
                let dbJSON = try NotionService.shared.prettyJSONString(from: dbResult)
                output = dbJSON
                AppLogger.log("✅ [getNotionDatabase] JSON output length: \(dbJSON.count) chars", category: .network, level: .info)
                AppLogger.log("📋 [getNotionDatabase] Output preview: \(String(dbJSON.prefix(200)))...", category: .network, level: .info)
            } catch {
                let errorMsg = "Error processing getNotionDatabase: \(error.localizedDescription)"
                AppLogger.log("❌ [getNotionDatabase] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
            }

        case "getNotionDataSource":
            struct NotionGetDataSourceArgs: Decodable {
                let data_source_id: String
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for getNotionDataSource."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(NotionGetDataSourceArgs.self, from: argsData)
                logActivity("📋 Fetching Notion data source \(decodedArgs.data_source_id)")
                let dsResult = try await NotionService.shared.getDataSource(dataSourceId: decodedArgs.data_source_id)
                output = try NotionService.shared.prettyJSONString(from: dsResult)
            } catch {
                output = "Error processing getNotionDataSource: \(error.localizedDescription)"
            }

        case "createNotionPage":
            struct NotionCreatePageArgs: Decodable {
                let data_source_id: String?
                let database_id: String?
                let data_source_name: String?
                let properties: [String: Any]?
                let children: [[String: Any]]?

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    data_source_id = try container.decodeIfPresent(String.self, forKey: .data_source_id)
                    database_id = try container.decodeIfPresent(String.self, forKey: .database_id)
                    data_source_name = try container.decodeIfPresent(String.self, forKey: .data_source_name)

                    // Decode properties and children as raw JSON
                    if let propsData = try? container.decodeIfPresent(Data.self, forKey: .properties),
                       let propsJSON = try? JSONSerialization.jsonObject(with: propsData) as? [String: Any] {
                        properties = propsJSON
                    } else {
                        properties = nil
                    }

                    if let childrenData = try? container.decodeIfPresent(Data.self, forKey: .children),
                       let childrenJSON = try? JSONSerialization.jsonObject(with: childrenData) as? [[String: Any]] {
                        children = childrenJSON
                    } else {
                        children = nil
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case data_source_id, database_id, data_source_name, properties, children
                }
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for createNotionPage."
                break
            }
            do {
                // Parse as raw JSON first to handle nested objects
                guard let argsJSON = try JSONSerialization.jsonObject(with: argsData) as? [String: Any] else {
                    output = "Error: Invalid JSON format for createNotionPage."
                    break
                }

                let dataSourceId = argsJSON["data_source_id"] as? String
                let databaseId = argsJSON["database_id"] as? String
                let dataSourceName = argsJSON["data_source_name"] as? String
                let properties = argsJSON["properties"] as? [String: Any]
                let children = argsJSON["children"] as? [[String: Any]]

                let context = [dataSourceId, databaseId, dataSourceName].compactMap { $0 }.joined(separator: ", ")
                logActivity("➕ Creating Notion page in [\(context)]")

                let pageResult = try await NotionService.shared.createPage(
                    dataSourceId: dataSourceId,
                    databaseId: databaseId,
                    dataSourceName: dataSourceName,
                    properties: properties,
                    children: children
                )
                output = try NotionService.shared.prettyJSONString(from: pageResult)
            } catch {
                output = "Error processing createNotionPage: \(error.localizedDescription)"
            }

        case "updateNotionPage":
            struct NotionUpdatePageArgs: Decodable {
                let page_id: String
                let properties: [String: Any]?
                let archived: Bool?

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    page_id = try container.decode(String.self, forKey: .page_id)
                    archived = try container.decodeIfPresent(Bool.self, forKey: .archived)

                    if let propsData = try? container.decodeIfPresent(Data.self, forKey: .properties),
                       let propsJSON = try? JSONSerialization.jsonObject(with: propsData) as? [String: Any] {
                        properties = propsJSON
                    } else {
                        properties = nil
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case page_id, properties, archived
                }
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for updateNotionPage."
                break
            }
            do {
                guard let argsJSON = try JSONSerialization.jsonObject(with: argsData) as? [String: Any] else {
                    output = "Error: Invalid JSON format for updateNotionPage."
                    break
                }

                guard let pageId = argsJSON["page_id"] as? String else {
                    output = "Error: Missing page_id for updateNotionPage."
                    break
                }

                let properties = argsJSON["properties"] as? [String: Any]
                let archived = argsJSON["archived"] as? Bool

                logActivity("✏️ Updating Notion page \(pageId)")
                let updateResult = try await NotionService.shared.updatePage(
                    pageId: pageId,
                    properties: properties,
                    archived: archived
                )
                output = try NotionService.shared.prettyJSONString(from: updateResult)
            } catch {
                output = "Error processing updateNotionPage: \(error.localizedDescription)"
            }

        case "appendNotionBlocks":
            struct NotionAppendBlocksArgs: Decodable {
                let page_id: String
                let blocks: [[String: Any]]

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    page_id = try container.decode(String.self, forKey: .page_id)

                    if let blocksData = try? container.decode(Data.self, forKey: .blocks),
                       let blocksJSON = try? JSONSerialization.jsonObject(with: blocksData) as? [[String: Any]] {
                        blocks = blocksJSON
                    } else {
                        blocks = []
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case page_id, blocks
                }
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for appendNotionBlocks."
                break
            }
            do {
                guard let argsJSON = try JSONSerialization.jsonObject(with: argsData) as? [String: Any] else {
                    output = "Error: Invalid JSON format for appendNotionBlocks."
                    break
                }

                guard let pageId = argsJSON["page_id"] as? String,
                      let blocks = argsJSON["blocks"] as? [[String: Any]] else {
                    output = "Error: Missing page_id or blocks for appendNotionBlocks."
                    break
                }

                logActivity("📝 Appending blocks to Notion page \(pageId)")
                let appendResult = try await NotionService.shared.appendBlocks(pageId: pageId, blocks: blocks)
                output = try NotionService.shared.prettyJSONString(from: appendResult)
            } catch {
                output = "Error processing appendNotionBlocks: \(error.localizedDescription)"
            }

        #if canImport(EventKit)
        case "fetchAppleCalendarEvents":
            struct FetchCalendarArgs: Decodable {
                let startDate: String
                let endDate: String
                let calendarIdentifiers: [String]?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for fetchAppleCalendarEvents."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(FetchCalendarArgs.self, from: argsData)
                AppLogger.log("📅 [fetchAppleCalendarEvents] Date range: \(decodedArgs.startDate) to \(decodedArgs.endDate)", category: .network, level: .info)
                logActivity("📅 Fetching Apple Calendar events")

                let provider = AppContainer.shared.appleProvider
                let events = try await provider.listEvents(
                    startISO8601: decodedArgs.startDate,
                    endISO8601: decodedArgs.endDate,
                    calendarIdentifiers: decodedArgs.calendarIdentifiers
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(events)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [fetchAppleCalendarEvents] Found \(events.count) events", category: .network, level: .info)
                logActivity("✅ Found \(events.count) calendar events")
            } catch {
                let errorMsg = "Error fetching Apple Calendar events: \(error.localizedDescription)"
                AppLogger.log("❌ [fetchAppleCalendarEvents] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Calendar fetch failed")
            }

        case "fetchAppleReminders":
            struct FetchRemindersArgs: Decodable {
                let startDate: String?
                let endDate: String?
                let completed: Bool?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for fetchAppleReminders."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(FetchRemindersArgs.self, from: argsData)
                AppLogger.log("✅ [fetchAppleReminders] Fetching reminders...", category: .network, level: .info)
                logActivity("✅ Fetching Apple Reminders")

                let provider = AppContainer.shared.appleProvider
                let reminders = try await provider.listReminders(
                    startISO8601: decodedArgs.startDate,
                    endISO8601: decodedArgs.endDate,
                    completed: decodedArgs.completed,
                    listIdentifiers: nil
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(reminders)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [fetchAppleReminders] Found \(reminders.count) reminders", category: .network, level: .info)
                logActivity("✅ Found \(reminders.count) reminders")
            } catch {
                let errorMsg = "Error fetching Apple Reminders: \(error.localizedDescription)"
                AppLogger.log("❌ [fetchAppleReminders] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Reminders fetch failed")
            }

        case "createAppleCalendarEvent":
            struct CreateEventArgs: Decodable {
                let title: String
                let startDate: String
                let endDate: String
                let location: String?
                let notes: String?
                let calendarIdentifier: String?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for createAppleCalendarEvent."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(CreateEventArgs.self, from: argsData)
                AppLogger.log("📅 [createAppleCalendarEvent] Creating event: \(decodedArgs.title)", category: .network, level: .info)
                logActivity("📅 Creating calendar event: \(decodedArgs.title)")

                let provider = AppContainer.shared.appleProvider
                let event = try await provider.createEvent(
                    title: decodedArgs.title,
                    startISO8601: decodedArgs.startDate,
                    endISO8601: decodedArgs.endDate,
                    location: decodedArgs.location,
                    notes: decodedArgs.notes,
                    calendarIdentifier: decodedArgs.calendarIdentifier
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(event)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [createAppleCalendarEvent] Created event successfully", category: .network, level: .info)
                logActivity("✅ Created event: \(decodedArgs.title)")
            } catch {
                let errorMsg = "Error creating Apple Calendar event: \(error.localizedDescription)"
                AppLogger.log("❌ [createAppleCalendarEvent] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Event creation failed")
            }

        case "createAppleReminder":
            struct CreateReminderArgs: Decodable {
                let title: String
                let notes: String?
                let dueDate: String?
                let priority: Int?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for createAppleReminder."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(CreateReminderArgs.self, from: argsData)
                AppLogger.log("📝 [createAppleReminder] Creating reminder: \(decodedArgs.title)", category: .network, level: .info)
                logActivity("📝 Creating Apple Reminder: \(decodedArgs.title)")

                let provider = AppContainer.shared.appleProvider
                let reminder = try await provider.createReminder(
                    title: decodedArgs.title,
                    notes: decodedArgs.notes,
                    dueDateISO8601: decodedArgs.dueDate,
                    listIdentifier: nil  // TODO: Add priority support
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(reminder)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [createAppleReminder] Created reminder successfully", category: .network, level: .info)
                logActivity("✅ Created reminder: \(decodedArgs.title)")
            } catch {
                let errorMsg = "Error creating Apple Reminder: \(error.localizedDescription)"
                AppLogger.log("❌ [createAppleReminder] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Reminder creation failed")
            }

        case "searchAppleContacts":
            struct SearchContactsArgs: Decodable {
                let query: String
                let limit: Int?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for searchAppleContacts."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(SearchContactsArgs.self, from: argsData)
                AppLogger.log("📇 [searchAppleContacts] Query: \(decodedArgs.query)", category: .network, level: .info)
                logActivity("📇 Searching Apple Contacts for '\(decodedArgs.query)'")

                let provider = AppContainer.shared.appleProvider
                let contacts = try await provider.searchContacts(
                    query: decodedArgs.query,
                    limit: decodedArgs.limit ?? 50
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(contacts)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [searchAppleContacts] Found \(contacts.count) contacts", category: .network, level: .info)
                logActivity("✅ Found \(contacts.count) contacts")
            } catch {
                let errorMsg = "Error searching Apple Contacts: \(error.localizedDescription)"
                AppLogger.log("❌ [searchAppleContacts] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Contact search failed")
            }

        case "getAppleContact":
            struct GetContactArgs: Decodable {
                let identifier: String
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for getAppleContact."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(GetContactArgs.self, from: argsData)
                AppLogger.log("📇 [getAppleContact] Identifier: \(decodedArgs.identifier)", category: .network, level: .info)
                logActivity("📇 Fetching contact details")

                let provider = AppContainer.shared.appleProvider
                let contact = try await provider.getContact(identifier: decodedArgs.identifier)

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(contact)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [getAppleContact] Retrieved contact details", category: .network, level: .info)
                logActivity("✅ Retrieved contact details")
            } catch {
                let errorMsg = "Error getting Apple Contact: \(error.localizedDescription)"
                AppLogger.log("❌ [getAppleContact] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Contact fetch failed")
            }

        case "createAppleContact":
            struct CreateContactArgs: Decodable {
                let givenName: String?
                let familyName: String?
                let organizationName: String?
                let phoneNumber: String?
                let phoneLabel: String?
                let emailAddress: String?
                let emailLabel: String?
                let note: String?
            }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                output = "Error: Invalid arguments for createAppleContact."
                break
            }
            do {
                let decodedArgs = try JSONDecoder().decode(CreateContactArgs.self, from: argsData)
                let contactName = [decodedArgs.givenName, decodedArgs.familyName].compactMap { $0 }.joined(separator: " ")
                AppLogger.log("📇 [createAppleContact] Creating contact: \(contactName.isEmpty ? "Unknown" : contactName)", category: .network, level: .info)
                logActivity("📇 Creating Apple Contact: \(contactName.isEmpty ? "Unknown" : contactName)")

                let provider = AppContainer.shared.appleProvider
                let contact = try await provider.createContact(
                    givenName: decodedArgs.givenName,
                    familyName: decodedArgs.familyName,
                    organizationName: decodedArgs.organizationName,
                    phoneNumber: decodedArgs.phoneNumber,
                    phoneLabel: decodedArgs.phoneLabel,
                    emailAddress: decodedArgs.emailAddress,
                    emailLabel: decodedArgs.emailLabel,
                    note: decodedArgs.note
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(contact)
                output = String(data: jsonData, encoding: .utf8) ?? "{}"

                AppLogger.log("✅ [createAppleContact] Created contact successfully", category: .network, level: .info)
                logActivity("✅ Created contact")
            } catch {
                let errorMsg = "Error creating Apple Contact: \(error.localizedDescription)"
                AppLogger.log("❌ [createAppleContact] \(errorMsg)", category: .network, level: .error)
                output = errorMsg
                logActivity("❌ Contact creation failed")
            }
        #endif

        default:
            if activePrompt.enableCustomTool && functionName == activePrompt.customToolName {
                output = await executeCustomTool(argumentsJSON: call.arguments)
            } else {
                output = "Error: Unknown function '\(functionName)'"
            }
        }

        return output
    }

    /// Handles a function call from the API by executing the function and sending the result back.
    private func handleFunctionCall(_ call: OutputItem, for messageId: UUID) async {
        guard let functionName = call.name else {
            AppLogger.log("❌ [Function Call] No function name in call item", category: .ui, level: .error)
            handleError(OpenAIServiceError.invalidResponseData)
            return
        }

    guard let canonicalCallId = await MainActor.run(body: { self.canonicalIdentifier(for: call) }) else {
            AppLogger.log("❌ [Function Call] Unable to determine canonical identifier", category: .openAI, level: .error)
            return
        }

        if let referenceResponseId = lastResponseId {
            registerFunctionCallIdentifiers(call, canonicalId: canonicalCallId, responseId: referenceResponseId)
        }

        let shouldExecute = await MainActor.run { () -> Bool in
            if self.completedFunctionCallIds.contains(canonicalCallId) {
                AppLogger.log("♻️ [Function Call] Call \(canonicalCallId) already completed; skipping", category: .openAI, level: .info)
                return false
            }
            if self.pendingFunctionCallIds.contains(canonicalCallId) {
                AppLogger.log("⏳ [Function Call] Call \(canonicalCallId) already in progress; skipping duplicate trigger", category: .openAI, level: .debug)
                return false
            }
            self.pendingFunctionCallIds.insert(canonicalCallId)
            return true
        }

        guard shouldExecute else { return }

        defer {
            Task { [weak self] in
                await MainActor.run {
                    self?.pendingFunctionCallIds.remove(canonicalCallId)
                }
            }
        }

        AppLogger.log("🔧 [Function Call] Starting execution: \(functionName)", category: .ui, level: .info)
        let callIdForLog = call.id.isEmpty ? canonicalCallId : call.id
        AppLogger.log("🔧 [Function Call] Call ID: \(callIdForLog)", category: .ui, level: .info)
        AppLogger.log("🔧 [Function Call] Arguments: \(call.arguments ?? "none")", category: .ui, level: .info)

        let notionFunctions: Set<String> = [
            "searchNotion",
            "getNotionDatabase",
            "getNotionDataSource",
            "createNotionPage",
            "updateNotionPage",
            "appendNotionBlocks"
        ]
        #if canImport(EventKit)
        let baseAppleFunctions = [
            "fetchAppleCalendarEvents",
            "fetchAppleReminders",
            "createAppleCalendarEvent",
            "createAppleReminder"
        ]
        #if canImport(Contacts)
        let appleFunctions = Set(baseAppleFunctions + [
            "searchAppleContacts",
            "getAppleContact",
            "createAppleContact"
        ])
        #else
        let appleFunctions = Set(baseAppleFunctions)
        #endif
        #else
        let appleFunctions = Set<String>()
        #endif

        // Short-circuit tool calls that were disabled in Settings
        var output: String?
        if notionFunctions.contains(functionName) && !activePrompt.enableNotionIntegration {
            AppLogger.log("🔒 [Function Call] Blocked Notion function \(functionName) – integration disabled in settings", category: .ui, level: .info)
            output = "Error: Notion integration is disabled in Settings."
        } else if appleFunctions.contains(functionName) && !activePrompt.enableAppleIntegrations {
            AppLogger.log("🔒 [Function Call] Blocked Apple system function \(functionName) – integrations disabled in settings", category: .ui, level: .info)
            output = "Error: Apple system integrations are disabled in Settings."
        }

        if output == nil {
            // Execute using extracted switch logic
            output = await executeFunctionSwitch(functionName, call: call, messageId: messageId)
        }

        // If execution returned an error instead of output, bail
        if output?.hasPrefix("Error:") == true && output?.contains("unknown function") == true {
            let errorMsg = ChatMessage(role: .system, text: output!)
            await MainActor.run { messages.append(errorMsg) }
            return
        }

        guard let output else {
            AppLogger.log("❌ [Function Call] No output generated for function \(functionName)", category: .openAI, level: .error)
            return
        }

        // Send the result back to the API
        AppLogger.log("📤 [Function Call] Sending output back to OpenAI API", category: .ui, level: .info)
        AppLogger.log("📤 [Function Call] Output length: \(output.count) chars", category: .ui, level: .info)
        AppLogger.log("📤 [Function Call] Output preview: \(String(output.prefix(300)))...", category: .ui, level: .info)

    var priorResponseId: String? = lastResponseId
        var reasoningReplay = priorResponseId.flatMap { reasoningBufferByResponseId[$0] }
        let supportsReasoning = ModelCompatibilityService.shared.getCapabilities(for: activePrompt.openAIModel)?.supportsReasoningEffort == true

        if supportsReasoning,
           let responseId = priorResponseId,
           reasoningPayloadsRequireSummary(reasoningReplay) {
            AppLogger.log("🧠 [Function Call] Refreshing reasoning payload from response \(responseId)", category: .openAI, level: .info)
            do {
                let fetched = try await api.getResponse(responseId: responseId)
                // Extract reasoning items without storing (they're already in the buffer from streaming)
                let payloads = fetched.output.compactMap { makeReasoningPayload(from: $0) }
                reasoningReplay = payloads.isEmpty ? nil : payloads
            } catch {
                AppLogger.log("⚠️ [Function Call] Failed to refresh reasoning items: \(error)", category: .openAI, level: .warning)
                if case OpenAIServiceError.requestFailed(let statusCode, let message) = error,
                   statusCode == 404 || message.lowercased().contains("not found") {
                    AppLogger.log("♻️ [Function Call] Clearing stale previous_response_id=\(responseId) due to missing response", category: .openAI, level: .info)
                    reasoningBufferByResponseId.removeValue(forKey: responseId)
                    priorResponseId = nil
                    reasoningReplay = nil
                }
            }
        }

        // Sanitize reasoning items if needed (but don't update buffer again - storeReasoningItems already did it)
        if supportsReasoning, priorResponseId != nil {
            let sanitized = sanitizedReasoningPayloads(reasoningReplay)
            reasoningReplay = sanitized
        }

        var previousResponseIdForAttempt = priorResponseId
        var reasoningItemsForAttempt = (reasoningReplay?.isEmpty == true) ? nil : reasoningReplay
        let shouldStreamFollowUp = activePrompt.enableStreaming
        var followUpCompleted = false
        var attemptsRemaining = previousResponseIdForAttempt == nil ? 1 : 2
        var capturedError: Error?

        let functionOutputPayload = FunctionCallOutputPayload(
            callId: canonicalCallId,
            output: output,
            functionName: functionName,
            callItem: call
        )

        attemptLoop: while attemptsRemaining > 0 && !followUpCompleted {
            do {
                if shouldStreamFollowUp {
                    AppLogger.log("📤 [Function Call] Streaming function output to OpenAI", category: .openAI, level: .info)
                    if attemptsRemaining == (previousResponseIdForAttempt == nil ? 1 : 2) {
                        await MainActor.run {
                            self.streamingMessageId = messageId
                            self.isStreaming = true
                            self.streamingStatus = .connecting
                            self.resetStreamingReasoning(for: messageId)
                        }
                    }

                    // NOTE: We do NOT send reasoning items with function outputs.
                    // Per commit 75f6597: "Do NOT replay reasoning items here - they belong to the previous turn"
                    let stream = api.streamFunctionOutputs(
                        outputs: [functionOutputPayload],
                        model: activePrompt.openAIModel,
                        reasoningItems: nil,
                        previousResponseId: previousResponseIdForAttempt,
                        conversationId: self.activeConversation?.remoteId,
                        prompt: activePrompt
                    )

                    var cancelledMidStream = false
                    for try await chunk in stream {
                        if Task.isCancelled {
                            cancelledMidStream = true
                            await MainActor.run {
                                self.handleError(CancellationError())
                                self.logActivity("Cancelled")
                            }
                            break
                        }
                        await MainActor.run {
                            self.handleStreamChunk(chunk, for: messageId)
                        }
                    }

                    if !cancelledMidStream {
                        followUpCompleted = true
                        await MainActor.run {
                            if let finalMessage = self.messages.first(where: { $0.id == messageId }) {
                                AnalyticsService.shared.trackEvent(
                                    name: AnalyticsEvent.messageReceived,
                                    parameters: [
                                        AnalyticsParameter.model: self.activePrompt.openAIModel,
                                        AnalyticsParameter.messageLength: finalMessage.text?.count ?? 0,
                                        AnalyticsParameter.streamingEnabled: true,
                                        "has_images": finalMessage.images?.isEmpty == false
                                    ]
                                )
                            }
                        }
                    } else {
                        capturedError = CancellationError()
                        break
                    }
                } else {
                    AppLogger.log("📤 [Function Call] Calling sendFunctionOutput...", category: .openAI, level: .info)
                    let finalResponse = try await api.sendFunctionOutput(
                        call: call,
                        output: output,
                        model: activePrompt.openAIModel,
                        reasoningItems: reasoningItemsForAttempt,
                        previousResponseId: previousResponseIdForAttempt,
                        conversationId: self.activeConversation?.remoteId,
                        prompt: activePrompt
                    )

                    AppLogger.log("✅ [Function Call] Got response from sendFunctionOutput", category: .openAI, level: .info)
                    AppLogger.log("✅ [Function Call] Response ID: \(finalResponse.id)", category: .openAI, level: .info)
                    AppLogger.log("✅ [Function Call] Output items count: \(finalResponse.output.count)", category: .openAI, level: .info)

                    for (index, item) in finalResponse.output.enumerated() {
                        AppLogger.log("📋 [Function Call] Output item \(index): type=\(item.type), id=\(item.id)", category: .openAI, level: .info)
                        if let content = item.content {
                            AppLogger.log("📋 [Function Call] Output item \(index) has \(content.count) content parts", category: .openAI, level: .info)
                            for (cIndex, c) in content.enumerated() {
                                AppLogger.log("📋 [Function Call] Content \(cIndex): type=\(c.type), text=\(c.text?.prefix(100) ?? "none")", category: .openAI, level: .info)
                            }
                        }
                    }

                    await MainActor.run {
                        AppLogger.log("🎯 [Function Call] Calling handleNonStreamingResponse...", category: .ui, level: .info)
                        self.handleNonStreamingResponse(finalResponse, for: messageId)
                        AppLogger.log("✅ [Function Call] Completed handleNonStreamingResponse", category: .ui, level: .info)
                    }

                    followUpCompleted = true
                }

                if followUpCompleted {
                    break
                }
            } catch {
                if attemptsRemaining > 1 && isPreviousResponseNotFoundError(error) {
                    AppLogger.log("♻️ [Function Call] Retrying without previous_response_id after API rejection", category: .openAI, level: .info)
                    if let previousId = previousResponseIdForAttempt {
                        reasoningBufferByResponseId.removeValue(forKey: previousId)
                        if priorResponseId == previousId {
                            priorResponseId = nil
                        }
                    }
                    previousResponseIdForAttempt = nil
                    reasoningItemsForAttempt = nil
                    attemptsRemaining -= 1
                    continue attemptLoop
                }

                capturedError = error
                break
            }

            attemptsRemaining -= 1
        }

        if followUpCompleted {
            completedFunctionCallIds.insert(canonicalCallId)
            if let key = priorResponseId {
                reasoningBufferByResponseId.removeValue(forKey: key)
            }
        } else if let error = capturedError, !(error is CancellationError) {
            AppLogger.log("❌ [Function Call] Error while returning function output: \(error)", category: .openAI, level: .error)
            await MainActor.run {
                self.handleError(error)
            }
        }
    }

    private func isPreviousResponseNotFoundError(_ error: Error) -> Bool {
        guard case OpenAIServiceError.requestFailed(let statusCode, let message) = error else {
            return false
        }

        if statusCode != 400 { return false }
        let lowered = message.lowercased()
        return lowered.contains("previous_response_not_found") || lowered.contains("previous response with id")
    }

    /// Execute built-in calculator function. Returns a string result or error.
    private func evaluateCalculator(argumentsJSON: String?) -> String {
        do {
            struct CalcArgs: Decodable { let expression: String }
            guard let argsData = argumentsJSON?.data(using: .utf8) else {
                throw NSError(domain: "CalcError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid arguments format"])
            }
            let decodedArgs = try JSONDecoder().decode(CalcArgs.self, from: argsData)
            let expression = NSExpression(format: decodedArgs.expression)
            if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
                return result.stringValue
            }
            throw NSError(domain: "CalcError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid math expression"])
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    /// Execute a user-defined custom tool based on the selected execution type.
    /// - Modes:
    ///   - echo: returns the arguments JSON verbatim
    ///   - calculator: expects { expression: string } and evaluates like built-in
    ///   - webhook: POSTs JSON to a user-provided URL and returns text body
    private func executeCustomTool(argumentsJSON: String?) async -> String {
        switch activePrompt.customToolExecutionType {
        case "echo":
            return argumentsJSON ?? "{}"
        case "calculator":
            return evaluateCalculator(argumentsJSON: argumentsJSON)
        case "webhook":
            let urlString = activePrompt.customToolWebhookURL
            guard !urlString.isEmpty, let url = URL(string: urlString) else {
                return "Error: Missing or invalid webhook URL"
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = argumentsJSON?.data(using: .utf8) ?? Data("{}".utf8)
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    return "Error: Webhook status \(status)"
                }
                // Try to decode as UTF-8 text; otherwise return base64
                return String(data: data, encoding: .utf8) ?? data.base64EncodedString()
            } catch {
                return "Error: \(error.localizedDescription)"
            }
        default:
            return argumentsJSON ?? "{}"
        }
    }

    /// Handles MCP approval request by sending mcp_approval_response to API
    func respondToMCPApproval(approvalRequestId: String, approve: Bool, reason: String?, messageId: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else {
            AppLogger.log("⚠️ [MCP] Could not find message for approval response", category: .openAI, level: .warning)
            return
        }

        let trimmedReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Update the approval status in the message
        if var approvalRequests = messages[messageIndex].mcpApprovalRequests,
           let approvalIndex = approvalRequests.firstIndex(where: { $0.id == approvalRequestId }) {
            approvalRequests[approvalIndex].status = approve ? .approved : .rejected
            if let trimmedReason, !trimmedReason.isEmpty, !approve {
                approvalRequests[approvalIndex].reason = trimmedReason
            } else {
                approvalRequests[approvalIndex].reason = nil
            }
            messages[messageIndex].mcpApprovalRequests = approvalRequests
        }

        // Log the decision
        AppLogger.log("🔒 [MCP] User \(approve ? "approved" : "rejected") approval request \(approvalRequestId)", category: .openAI, level: .info)
        if let trimmedReason, !trimmedReason.isEmpty, !approve {
            AppLogger.log("  Reason: \(trimmedReason)", category: .openAI, level: .debug)
        }

        logActivity("MCP: \(approve ? "Approved" : "Rejected") tool call")

        // Send the approval response to the API
        streamingTask?.cancel()
        streamingMessageId = messageId // Ensure approval stream updates the originating message

        streamingTask = Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.streamingStatus = .connecting
                self.isStreaming = true
                self.resetStreamingReasoning(for: messageId)
            }

            do {
                // Build approval response input
                let approvalResponse = self.buildMCPApprovalResponsePayload(
                    approvalRequestId: approvalRequestId,
                    approve: approve,
                    reason: trimmedReason
                )

                // Send the response using previous_response_id to continue the conversation
                if self.activePrompt.enableStreaming {
                    // Streaming mode
                    let stream = self.api.streamMCPApprovalResponse(
                        approvalResponse: approvalResponse,
                        model: self.activePrompt.openAIModel,
                        previousResponseId: self.lastResponseId,
                        prompt: self.activePrompt
                    )

                    for try await event in stream {
                        await MainActor.run {
                            self.handleStreamChunk(event, for: messageId)
                        }
                    }
                } else {
                    // Non-streaming mode
                    let response = try await self.api.sendMCPApprovalResponse(
                        approvalResponse: approvalResponse,
                        model: self.activePrompt.openAIModel,
                        previousResponseId: self.lastResponseId,
                        prompt: self.activePrompt
                    )

                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: messageId)
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.logActivity("Error sending approval response")
                    self.streamingStatus = .idle
                    self.isStreaming = false
                    self.streamingMessageId = nil
                }
            }
        }
    }

    func buildMCPApprovalResponsePayload(approvalRequestId: String, approve: Bool, reason: String?) -> [String: Any] {
        var payload: [String: Any] = [
            "type": "mcp_approval_response",
            "approval_request_id": approvalRequestId,
            "approve": approve
        ]

        if let reason, !reason.isEmpty, !approve {
            payload["reason"] = reason
        }

        return payload
    }

    /// Determines the current model to use from UserDefaults (or default).
    func currentModel() -> String {
        return activePrompt.openAIModel
    }

    // MARK: - Active Prompt Management

    /// Saves the current `activePrompt` to UserDefaults.
    func saveActivePrompt() {
        // Do not save if the active prompt is a temporary preset
        if activePrompt.isPreset { return }

        if let encoded = try? JSONEncoder().encode(activePrompt) {
            UserDefaults.standard.set(encoded, forKey: "activePrompt")
            print("Active prompt saved.")
        }
    }

    /// Ensures reasoning-related toggles line up with the currently selected model.
    @discardableResult
    private func enforceReasoningDefaults(for prompt: inout Prompt, previousModelId: String?) -> Bool {
        let compatibilityService = ModelCompatibilityService.shared
        let supportsReasoning = compatibilityService
            .getCapabilities(for: prompt.openAIModel)?
            .supportsReasoningEffort == true
        let previousSupportedReasoning: Bool = {
            guard let previousModelId else { return false }
            return compatibilityService
                .getCapabilities(for: previousModelId)?
                .supportsReasoningEffort == true
        }()

        var didChange = false

        if supportsReasoning {
            if !prompt.includeReasoningContent && !previousSupportedReasoning {
                prompt.includeReasoningContent = true
                didChange = true
            }
        } else if prompt.includeReasoningContent {
            prompt.includeReasoningContent = false
            didChange = true
        }

        return didChange
    }

    /// Replaces the active prompt, normalizing capabilities before storing it.
    @discardableResult
    func replaceActivePrompt(with prompt: Prompt, previousModelId: String? = nil) -> Bool {
        var updatedPrompt = prompt
        let baselineModel = previousModelId ?? activePrompt.openAIModel
        let reasoningChanged = enforceReasoningDefaults(for: &updatedPrompt, previousModelId: baselineModel)
        activePrompt = updatedPrompt
        return reasoningChanged
    }

    /// Force reset the active prompt to default values
    func resetToDefaultPrompt() {
        let defaultPrompt = Prompt.defaultPrompt()
        replaceActivePrompt(with: defaultPrompt, previousModelId: nil)
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        saveActivePrompt()
        print("Prompt reset to default and saved.")
    }

    /// Loads the `activePrompt` from UserDefaults.
    private func loadActivePrompt() {
        if let data = UserDefaults.standard.data(forKey: "activePrompt"),
           let decoded = try? JSONDecoder().decode(Prompt.self, from: data) {
            var prompt = decoded
            var needsSave = false

            // Ensure computer use stays aligned with model capabilities
            let compatibilityService = ModelCompatibilityService.shared
            let supportsComputerUse = compatibilityService.isToolSupported(
                .computer,
                for: prompt.openAIModel,
                isStreaming: prompt.enableStreaming
            )

            if prompt.enableComputerUse && !supportsComputerUse {
                AppLogger.log(
                    "[Settings] Disabling computer use – model \(prompt.openAIModel) does not support the computer tool",
                    category: .ui,
                    level: .info
                )
                prompt.enableComputerUse = false
                prompt.ultraStrictComputerUse = false
                needsSave = true
            }

            if prompt.enableNotionIntegration {
                let hasNotionToken = KeychainService.shared.load(forKey: "notionApiKey")?.isEmpty == false
                if !hasNotionToken {
                    // Prevent stale toggles when the backing Notion token has been removed
                    AppLogger.log(
                        "[Settings] Disabling Notion integration – no token available in keychain",
                        category: .ui,
                        level: .info
                    )
                    prompt.enableNotionIntegration = false
                    needsSave = true
                }
            }

            // Migration: Update truncation from "disabled" to "auto" for better context management
            if prompt.truncationStrategy == "disabled" {
                print("Migrating truncation strategy from 'disabled' to 'auto'")
                prompt.truncationStrategy = "auto"
                needsSave = true
            }

            // Validate the model name - if it's a UUID or invalid, reset to default
            if isInvalidModelName(prompt.openAIModel) {
                print("Invalid model name detected: \(prompt.openAIModel), resetting to default")
                prompt.openAIModel = "gpt-4o"
                needsSave = true
            }

            let reasoningChanged = enforceReasoningDefaults(for: &prompt, previousModelId: nil)
            activePrompt = prompt

            if needsSave || reasoningChanged {
                saveActivePrompt() // Save all migrations at once
            }

            print("Active prompt loaded.")
        } else {
            // If no saved prompt is found, use the default
            replaceActivePrompt(with: Prompt.defaultPrompt(), previousModelId: nil)
            print("No saved prompt found, initialized with default.")
        }
    }

    /// Checks if a model name is invalid (e.g., a UUID instead of a proper model name)
    private func isInvalidModelName(_ modelName: String) -> Bool {
        // Check if it's a UUID format
        if UUID(uuidString: modelName) != nil {
            return true
        }

        // Check if it's empty or contains invalid characters for a model name
        if modelName.isEmpty || modelName.contains("Optional(") {
            return true
        }

        return false
    }

    // MARK: - Conversation Management

    func loadConversations() {
        do {
            conversations = try storageService.loadConversations()
            if conversations.isEmpty {
                createNewConversation()
            } else {
                activeConversation = conversations.first
            }
        } catch {
            handleError(error)
            if conversations.isEmpty {
                createNewConversation()
            }
        }
    }

    func createNewConversation() {
        let storePreference = activePrompt.storeResponses
        let newConversation = Conversation.new(storePreference: storePreference)
        conversations.insert(newConversation, at: 0)
        activeConversation = newConversation
        saveConversation(newConversation)
    }

    func saveConversation(_ conversation: Conversation) {
        do {
            try storageService.saveConversation(conversation)
        } catch {
            handleError(error)
        }
    }

    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        do {
            try storageService.deleteConversation(withId: conversation.id)
        } catch {
            handleError(error)
        }

        if activeConversation?.id == conversation.id {
            activeConversation = conversations.first
            if activeConversation == nil {
                createNewConversation()
            }
        }
    }

    func selectConversation(_ conversation: Conversation) {
        activeConversation = conversation
    }


    /// Schedules a flush for the buffered text deltas of this message.
    /// If immediate is true, flush right away; otherwise, debounce for a short interval.
    func scheduleDeltaFlush(for messageId: UUID, messageIndex: Int, immediate: Bool) {
        // Cancel any pending work
        if let work = deltaFlushWorkItems[messageId] { work.cancel() }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.flushDeltaBuffer(for: messageId, messageIndex: messageIndex)
        }
        deltaFlushWorkItems[messageId] = work

        if immediate {
            DispatchQueue.main.async(execute: work)
        } else {
            let delay = DispatchTime.now() + .milliseconds(deltaFlushDebounceMs)
            DispatchQueue.main.asyncAfter(deadline: delay, execute: work)
        }
    }

    /// Flushes the buffer into the message text and clears the buffer.
    private func flushDeltaBuffer(for messageId: UUID, messageIndex: Int) {
        guard let buffered = deltaBuffers[messageId], !buffered.isEmpty else { return }
        var updated = messages
        let currentText = updated[messageIndex].text ?? ""
        updated[messageIndex].text = currentText + buffered
        messages = updated
        deltaBuffers[messageId] = nil
    }

    /// Flush if buffer exists, regardless of known message index (e.g., on completion cleanup)
    func flushDeltaBufferIfNeeded(for messageId: UUID) {
        guard let buffered = deltaBuffers[messageId], !buffered.isEmpty else { return }
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            flushDeltaBuffer(for: messageId, messageIndex: idx)
        } else {
            deltaBuffers[messageId] = nil
        }
        // Cancel any pending work after final flush
        if let work = deltaFlushWorkItems[messageId] { work.cancel() }
        deltaFlushWorkItems[messageId] = nil
    }

    /// Attempts to transparently retry a failed streaming request once for transient errors.
    /// Returns true if a retry was scheduled; false if not eligible (no retry context or already retried).
    func attemptStreamingRetry(for messageId: UUID, reason: String) -> Bool {
        // If any buffered text exists, flush it before deciding eligibility
        flushDeltaBufferIfNeeded(for: messageId)
        // If Notion MCP preflight was revoked/not OK, skip retry to avoid bypassing the gate
        if activePrompt.enableMCPTool {
            let label = activePrompt.mcpServerLabel
            let url = activePrompt.mcpServerURL
            let isNotion = label.lowercased().contains("notion") || url.lowercased().contains("notion")
            if isNotion {
                let ok = UserDefaults.standard.bool(forKey: "mcp_preflight_ok_\(label)")
                if ok == false {
                    AppLogger.log("[Streaming Retry] Skipping retry because Notion MCP preflight is not OK for '\(label)'", category: .openAI, level: .warning)
                    return false
                }
            }
        }
        guard var ctx = retryContextByMessageId[messageId], ctx.remainingAttempts > 0 else { return false }

        // Only retry if no text has been streamed yet (avoid duplicating partial outputs)
        if let idx = messages.firstIndex(where: { $0.id == messageId }), let text = messages[idx].text, !text.isEmpty {
            return false
        }

        // Decrement attempts and persist; mark retry as scheduled to prevent duplicate notes
        ctx.remainingAttempts -= 1
        if !ctx.retryScheduled {
            AppLogger.log("[Streaming Retry] Temporary issue: \(reason). Retrying once", category: .openAI, level: .warning)
            // Surface via status chip rather than adding a red system message to the chat
            streamingStatus = .connecting
        }
        ctx.retryScheduled = true
        retryContextByMessageId[messageId] = ctx

        // Cancel the current stream and start a fresh one with the original previous_response_id
        streamingTask?.cancel()
        streamingMessageId = messageId
        isStreaming = true
        streamingStatus = .connecting
        resetStreamingReasoning(for: messageId)

        // Backoff briefly to avoid immediate repeat failures
        streamingTask = Task { [ctx, weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000) // 800ms backoff
            guard let self = self else { return }
            do {
                let stream = self.api.streamChatRequest(
                    userMessage: ctx.userText,
                    prompt: self.activePrompt,
                    attachments: ctx.attachments,
                    fileData: nil,
                    fileNames: nil,
                    fileIds: nil,
                    imageAttachments: ctx.imageAttachments,
                    previousResponseId: ctx.basePreviousResponseId,
                    conversationId: self.activeConversation?.remoteId
                )
                for try await chunk in stream {
                    if Task.isCancelled { 
                        await MainActor.run { [weak self] in
                            self?.handleError(CancellationError())
                        }
                        break
                    }
                    await MainActor.run { self.handleStreamChunk(chunk, for: messageId) }
                }
            } catch {
                // If retry itself throws (network, etc.), surface the error and reset state
                await MainActor.run {
                    self.handleError(error)
                    self.isStreaming = false
                    self.streamingStatus = .idle
                    self.streamingMessageId = nil
                    self.retryContextByMessageId.removeValue(forKey: messageId)
                }
            }
            await MainActor.run {
                // On completion of retry streaming attempt, perform standard cleanup if not awaiting tools
                if let finalMessage = self.messages.first(where: { $0.id == messageId }) {
                    print("Finished streaming response (retry): \(finalMessage.text ?? "No text content")")
                    AnalyticsService.shared.trackEvent(
                        name: AnalyticsEvent.messageReceived,
                        parameters: [
                            AnalyticsParameter.model: self.activePrompt.openAIModel,
                            AnalyticsParameter.messageLength: finalMessage.text?.count ?? 0,
                            AnalyticsParameter.streamingEnabled: true,
                            "has_images": finalMessage.images?.isEmpty == false
                        ]
                    )
                }
                self.streamingMessageId = nil
                self.isStreaming = false
                if self.isAwaitingComputerOutput {
                    self.streamingStatus = .usingComputer
                } else if self.streamingStatus != .idle {
                    self.streamingStatus = .done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        self?.streamingStatus = .idle
                    }
                }
                // Retry path complete—clear context
                self.retryContextByMessageId.removeValue(forKey: messageId)
            }
        }

        // Analytics: mark retry attempted
        AnalyticsService.shared.trackEvent(
            name: "streaming_retry_attempted",
            parameters: [
                "reason": reason,
                AnalyticsParameter.model: activePrompt.openAIModel
            ]
        )
        return true
    }

    /// Handles computer tool calls by fetching the full response to get complete action details
    func handleComputerToolCallWithFullResponse(_ item: StreamingItem, messageId: UUID) async {
        guard activePrompt.enableComputerUse else { return }
        guard let previousId = lastResponseId else { return }

        AppLogger.log("[CUA] Handling computer_call item.id=\(item.id), previousResponseId=\(previousId)", category: .openAI)
        await MainActor.run { self.isAwaitingComputerOutput = true; self.streamingStatus = .usingComputer }
        do {
            // Prefer using the streaming item details directly to avoid 404s from GET /responses/{id}
            var callId: String? = item.callId
            var pendingSafety: [SafetyCheck]? = item.pendingSafetyChecks
            var actionData: ComputerAction? = extractComputerAction(from: item)

            if callId == nil || actionData == nil {
                // Fallback: fetch the full response only if required data is missing
                do {
                    let fullResponse = try await api.getResponse(responseId: previousId)
                    AppLogger.log("[CUA] Fetched full response for prevId=\(previousId) with \(fullResponse.output.count) items (fallback)", category: .openAI)
                    if let match = fullResponse.output.first(where: { $0.type == "computer_call" && $0.id == item.id }) {
                        if callId == nil { callId = match.callId }
                        if pendingSafety == nil { pendingSafety = match.pendingSafetyChecks }
                        if actionData == nil { actionData = extractComputerActionFromOutputItem(match) }
                    }
                } catch {
                    // If fetching fails (e.g., 404), proceed with what we have if possible
                    AppLogger.log("[CUA] Fallback getResponse failed: \(error). Proceeding with streaming item when possible.", category: .openAI, level: .warning)
                }
            }

            guard let finalCallId = callId, !finalCallId.isEmpty else {
                AppLogger.log("[CUA] Missing call_id for computer_call id=\(item.id). Cannot send output.", category: .openAI, level: .error)
                await MainActor.run { self.lastResponseId = nil }
                await MainActor.run { self.isAwaitingComputerOutput = false }
                return
            }

            guard let actionData = actionData else {
                AppLogger.log("[CUA] Failed to extract action for computer_call id=\(item.id)", category: .openAI, level: .error)
                await MainActor.run { self.lastResponseId = nil }
                await MainActor.run { self.isAwaitingComputerOutput = false }
                return
            }

            // Minimal generic guardrails to prevent unhelpful first-step blank screenshots or clicks:
            // - If the model requests a bare screenshot and we're effectively on about:blank, try to
            //   derive the intended URL from the user's message and attach it to the screenshot action.
            // - If the model attempts to click while still on about:blank, navigate first using the
            //   same derivation to reach the likely target site.
            var actionToExecute = actionData
            if !activePrompt.ultraStrictComputerUse {
                if actionToExecute.type == "screenshot", actionToExecute.parameters["url"] == nil,
                   let derivedURL = deriveURLForScreenshot(from: messageId) {
                    AppLogger.log("[CUA] (streaming) Auto-attaching URL to screenshot action: \(derivedURL.absoluteString)", category: .openAI, level: .info)
                    actionToExecute = ComputerAction(type: "screenshot", parameters: ["url": derivedURL.absoluteString])
                }
                if actionToExecute.type == "click", computerService.isOnBlankPage(),
                   let derivedURL = deriveURLForScreenshot(from: messageId) {
                    AppLogger.log("[CUA] (streaming) WebView blank before click; navigating to derived URL: \(derivedURL.absoluteString)", category: .openAI, level: .info)
                    _ = try? await computerService.executeAction(ComputerAction(type: "navigate", parameters: ["url": derivedURL.absoluteString]))
                    try? await Task.sleep(nanoseconds: 400_000_000)
                }
            }

            // Intent-guided override (streaming path): if the user's instruction was an explicit search,
            // perform the search directly on known engines BEFORE executing the model's first UI action.
            // This prevents the model from clicking promo tiles and ensures the first screenshot shows results.
            if !activePrompt.ultraStrictComputerUse {
                if !appliedSearchOverrideForMessage.contains(messageId),
                   let searchQueryRaw = extractExplicitSearchQuery(for: messageId) {
                    let refined = refineSearchPhrase(searchQueryRaw)
                    AppLogger.log("[CUA] (streaming) Intent override: performing search for query '\(refined)' on current engine", category: .openAI, level: .info)
                    do { try await computerService.performSearchIfOnKnownEngine(query: refined) } catch {
                        AppLogger.log("[CUA] (streaming) performSearchIfOnKnownEngine failed: \(error)", category: .openAI, level: .warning)
                    }
                    appliedSearchOverrideForMessage.insert(messageId)
                }
            }

            // If the action is a click and the user asked to click a named thing, resolve by text.
            if !activePrompt.ultraStrictComputerUse {
                if actionToExecute.type == "click", let targetName = extractExplicitClickTarget(for: messageId) {
                    if let pt = try? await computerService.findClickablePointByVisibleText(targetName) {
                        AppLogger.log("[CUA] (streaming) Click-by-text override resolved '\(targetName)' -> (\(pt.x), \(pt.y))", category: .openAI, level: .info)
                        actionToExecute = ComputerAction(type: "click", parameters: ["x": pt.x, "y": pt.y, "button": "left"])
                    } else {
                        AppLogger.log("[CUA] (streaming) Click-by-text override failed to resolve target '\(targetName)'; proceeding with model coordinates", category: .openAI, level: .warning)
                    }
                }
            }

            // Note: We still execute the model-directed action; the above is a minimal preconditioning step.
            AppLogger.log("[CUA] Executing action type=\(actionToExecute.type) params=\(actionToExecute.parameters)", category: .openAI)

            // Check for pending safety checks – pause and ask the user
            if let safetyChecks = pendingSafety, !safetyChecks.isEmpty {
                AppLogger.log("[CUA] SAFETY CHECKS DETECTED: \(safetyChecks.count) checks pending", category: .openAI, level: .warning)
                for check in safetyChecks {
                    AppLogger.log("[CUA] Safety Check - \(check.code): \(check.message)", category: .openAI, level: .warning)
                }
                await MainActor.run {
                    self.pendingSafetyApproval = SafetyApprovalRequest(
                        checks: safetyChecks,
                        callId: finalCallId,
                        action: actionData,
                        previousResponseId: previousId,
                        messageId: messageId
                    )
                    self.isAwaitingComputerOutput = true
                    self.streamingStatus = .usingComputer
                    let sys = ChatMessage(role: .system, text: "⚠️ Action requires approval before proceeding.")
                    self.messages.append(sys)
                }
                return // Wait for user decision
            }


            let result = try await computerService.executeAction(actionToExecute)

            // Check for consecutive wait actions to prevent infinite loops - but do this AFTER executing the action
            // so we can capture any screenshots or results first
            var abortAfterOutput = false
            if actionData.type == "wait" {
                consecutiveWaitCount += 1
                AppLogger.log("[CUA] (streaming) Wait action detected. Consecutive count: \(consecutiveWaitCount)/\(maxConsecutiveWaits)", category: .openAI, level: .warning)
                if consecutiveWaitCount >= maxConsecutiveWaits {
                    // Don't return yet; mark to abort after we send the output so the tool call is satisfied.
                    abortAfterOutput = true
                    AppLogger.log("[CUA] (streaming) Max consecutive waits reached; will send output and then halt chain.", category: .openAI, level: .error)
                }
            } else {
 consecutiveWaitCount = 0
            }

            // Attach screenshot to UI if available
            if let screenshot = result.screenshot, !screenshot.isEmpty {
                AppLogger.log("[CUA] (streaming) Screenshot captured (\(screenshot.count) b64 chars), adding to message", category: .openAI, level: .info)
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = self.messages[index]
                        if let imageData = Data(base64Encoded: screenshot), let rawImage = UIImage(data: imageData, scale: 1.0) {
                            // Ensure the image has a proper CGImage
                            let uiImage: UIImage
                            if rawImage.cgImage == nil {
                                AppLogger.log("[CUA] (streaming) WARNING: UIImage has no CGImage, attempting to recreate", category: .openAI, level: .warning)
                                // Try to recreate the image from PNG data
                                if let pngData = rawImage.pngData(), let recreatedImage = UIImage(data: pngData) {
                                    uiImage = recreatedImage
                                } else {
                                    AppLogger.log("[CUA] (streaming) FAILED to recreate image with CGImage", category: .openAI, level: .error)
                                    return
                                }
                            } else {
                                uiImage = rawImage
                            }

                            AppLogger.log("[CUA] (streaming) Screenshot decoded successfully - Image size: \(uiImage.size), data length: \(imageData.count) bytes", category: .openAI, level: .info)
                            AppLogger.log("[CUA] (streaming) CGImage present: \(uiImage.cgImage != nil), orientation: \(uiImage.imageOrientation.rawValue)", category: .openAI, level: .info)

                            if updatedMessage.images == nil { updatedMessage.images = [] }
                            updatedMessage.images?.removeAll()
                            updatedMessage.images?.append(uiImage)

                            AppLogger.log("[CUA] (streaming) About to update message with \(updatedMessage.images?.count ?? 0) images", category: .openAI, level: .info)

                            // Update the message in the messages array
                            var updatedMessages = self.messages
                            updatedMessages[index] = updatedMessage
                            self.messages = updatedMessages  // This triggers the setter and UI update

                            AppLogger.log("[CUA] (streaming) Message updated, now has \(self.messages[index].images?.count ?? 0) images", category: .openAI, level: .info)

                            // Force multiple UI refresh cycles
                            Task { @MainActor in
                                self.objectWillChange.send()
                                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                                self.objectWillChange.send()
                                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                                self.objectWillChange.send()
                            }

                            AppLogger.log("[CUA] (streaming) Successfully added screenshot to message UI - Image size: \(uiImage.size)", category: .openAI, level: .info)
                        } else {
                            AppLogger.log("[CUA] (streaming) FAILED to decode screenshot base64 data", category: .openAI, level: .error)
                        }
                    } else {
                        AppLogger.log("[CUA] (streaming) FAILED to find message with id \(messageId)", category: .openAI, level: .error)
                    }
                }

                let output: [String: Any] = [
                    "type": "computer_screenshot",
                    "image_url": "data:image/png;base64,\(screenshot)"
                ]
                // Include acknowledged safety checks if they were present
                let acknowledgedSafetyChecks = pendingSafety

                AppLogger.log("[CUA] Sending computer_call_output for call_id=\(finalCallId)", category: .openAI)
                if let safetyChecks = acknowledgedSafetyChecks {
                    AppLogger.log("[CUA] Including \(safetyChecks.count) acknowledged safety checks", category: .openAI)
                }

                do {
                    let response = try await api.sendComputerCallOutput(
                        callId: finalCallId,
                        output: output,
                        model: activePrompt.openAIModel,
                        previousResponseId: previousId,
                        acknowledgedSafetyChecks: acknowledgedSafetyChecks,
                        currentUrl: result.currentURL
                    )
                    if abortAfterOutput {
                        await MainActor.run {
                            self.consecutiveWaitCount = 0
                            self.isAwaitingComputerOutput = false
                            self.isStreaming = false
                            self.streamingStatus = .idle
                            self.lastResponseId = nil
                            let sys = ChatMessage(
                                role: .system,
                                text: "⚠️ Computer use interrupted: Too many consecutive wait actions. I sent the last screenshot and stopped."
                            )
                            self.messages.append(sys)
                        }
                    } else {
                        await MainActor.run {
                            self.handleNonStreamingResponse(response, for: messageId)
                            self.isAwaitingComputerOutput = false
                        }
                    }
                } catch {
                    AppLogger.log("[CUA] Failed to send computer_call_output: \(error)", category: .openAI, level: .error)
                    // Important: Clear previous response ID so subsequent user messages
                    // don't reference a pending computer_call and trigger 400 errors like
                    // "No tool output found for computer call ...".
                    await MainActor.run {
                        self.handleError(error)
                        self.lastResponseId = nil
                        // CRITICAL FIX: Complete streaming state reset on computer_call_output network failure
                        self.streamingStatus = .idle
                        self.streamingMessageId = nil
                        self.isStreaming = false
                        self.isAwaitingComputerOutput = false
                        // Provide a lightweight, user-visible hint in the chat
                        let sys = ChatMessage(role: .system, text: "Couldn’t continue the previous computer-use step. I’ll start fresh on the next message.", images: nil)
                        self.messages.append(sys)
                        self.isAwaitingComputerOutput = false
                    }
                }
            } else {
                AppLogger.log("[CUA] No screenshot produced by action; clearing previousId to avoid API 400", category: .openAI, level: .warning)
                await MainActor.run { self.lastResponseId = nil; self.isAwaitingComputerOutput = false }
            }
        } catch {
            AppLogger.log("[CUA] Error while handling computer_call: \(error)", category: .openAI, level: .error)
            await MainActor.run { 
                self.lastResponseId = nil
                self.isAwaitingComputerOutput = false
                self.handleError(error)
                // CRITICAL FIX: Complete streaming state reset on computer tool error
                self.streamingStatus = .idle
                self.streamingMessageId = nil
                self.isStreaming = false
                Task { @MainActor in
                    try await Task.sleep(for: .seconds(2)) // Allows user to see the error
                    self.streamingStatus = .idle
                }
            }
        }
    }

    /// Extracts computer action from a full response OutputItem (has complete action data)
    private func extractComputerActionFromOutputItem(_ item: OutputItem) -> ComputerAction? {
        guard item.type == "computer_call", let actionData = item.action else {
            return nil
        }

        let actionDict = actionData.reduce(into: [String: Any]()) { result, entry in
            if let value = entry.value.value {
                result[entry.key] = value
            }
        }

        guard let actionType = actionDict["type"] as? String else {
            return nil
        }

        return ComputerAction(type: actionType, parameters: actionDict)
    }

    /// Derives a URL to navigate to for a screenshot-only action when the model didn't provide one.
    /// Tries to parse the user's last message for a renderable URL; otherwise returns nil.
    private func deriveURLForScreenshot(from messageId: UUID) -> URL? {
        // Find the user's message immediately before the assistant messageId
        guard let idx = messages.firstIndex(where: { $0.id == messageId }), idx > 0 else { return nil }
        // Search backwards for the nearest user message
        for i in stride(from: idx - 1, through: 0, by: -1) {
            let m = messages[i]
            if m.role == .user, let text = m.text {
                let lower = text.lowercased()
                // Helper: try to convert a token like "brandcom" -> "brand.com" using common TLDs
                func urlFromConcatenatedDomain(_ token: String) -> URL? {
                    let tlds = [
                        "com","org","net","io","co","ai","app","dev","info","biz","me","gg","xyz","us","uk","de","ca","au","edu","gov"
                    ]
                    for tld in tlds {
                        if token.hasSuffix(tld), token.count > tld.count {
                            let prefix = String(token.dropLast(tld.count))
                            // Ensure prefix ends with a letter/number
                            if let last = prefix.last, last.isLetter || last.isNumber {
                                let host = "\(prefix).\(tld)"
                                return URL(string: "https://\(host)")
                            }
                        }
                    }
                    return nil
                }
                // Heuristic 1: handle phrases like "go to X" or "open X"
                if lower.contains("go to ") || lower.contains("open ") {
                    let trigger = lower.contains("go to ") ? "go to " : "open "
                    if let range = lower.range(of: trigger) {
                        // Use the original-case text for extraction (preserve dots and host casing for URLComponents)
                        let originalTail = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        // First, try to extract an explicit URL or domain from the tail using our detector
                        let urlsInTail = URLDetector.extractRenderableURLs(from: originalTail)
                        if let first = urlsInTail.first {
                            // Normalize: ensure https scheme and lowercase host
                            if var comps = URLComponents(url: first, resolvingAgainstBaseURL: false) {
                                if comps.scheme == nil { comps.scheme = "https" }
                                comps.host = comps.host?.lowercased()
                                if let normalized = comps.url { return normalized }
                            }
                            return first
                        }
                        // If not found, fall back to a simple domain token at the beginning of the tail
                        // Stop at whitespace or punctuation
                        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",.;:!?"))
                        let token = originalTail.split(whereSeparator: { ch in
                            guard let scalar = ch.unicodeScalars.first else { return false }
                            return separators.contains(scalar)
                        }).first.map(String.init) ?? originalTail
                        let tokenLower = token.lowercased()
                        if tokenLower.contains(".") {
                            // Build https URL from domain-like token
                            return URL(string: tokenLower.hasPrefix("http") ? tokenLower : "https://\(tokenLower)")
                        }
                        // NEW: Handle concatenated domain like "strykercom" -> "stryker.com"
                        if let concatenated = urlFromConcatenatedDomain(tokenLower) { return concatenated }
                        // Map common brand to canonical URL
                        if let mapped = Self.keywordURLMap.first(where: { tokenLower.contains($0.key) })?.value,
                           let url = URL(string: mapped) {
                            return url
                        }
                        // Fallback: try https://<token>.com if token is single word and alphanumeric
                        if tokenLower.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines) == nil,
                           tokenLower.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) {
                            if let url = URL(string: "https://\(tokenLower).com") { return url }
                        }
                    }
                }

                // Heuristic 2: explicit "search <query>" or "find <query>" → Google search
                if lower.contains("search ") || lower.contains("find ") {
                    let trigger = lower.contains("search ") ? "search " : "find "
                    if let range = lower.range(of: trigger) {
                        let q = String(lower[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
                        return URL(string: "https://www.google.com/search?q=\(encoded)")
                    }
                }

                // Heuristic 3: extract any explicit URL/domain in the text
                let urls = URLDetector.extractRenderableURLs(from: text)
                if let first = urls.first {
                    // Normalize: ensure https scheme and lowercase host to avoid redirects like Google.com -> www.google.com
                    if var comps = URLComponents(url: first, resolvingAgainstBaseURL: false) {
                        if comps.scheme == nil { comps.scheme = "https" }
                        comps.host = comps.host?.lowercased()
                        if let normalized = comps.url { return normalized }
                    }
                    return first
                }
                // Simple domain hint like "google.com" without scheme
                let tokens = text
                    .replacingOccurrences(of: ",", with: " ")
                    .replacingOccurrences(of: "\n", with: " ")
                    .split(separator: " ")
                    .map { String($0) }
                if let domain = tokens.first(where: { $0.contains(".") && !$0.contains(" ") && !$0.contains("http") }) {
                    let host = domain.lowercased()
                    return URL(string: "https://\(host)")
                }
                // NEW: Try concatenated TLDs in tokens (e.g., "Strykercom")
                if let cat = tokens
                    .map({ $0.trimmingCharacters(in: .punctuationCharacters).lowercased() })
                    .compactMap({ urlFromConcatenatedDomain($0) })
                    .first {
                    return cat
                }
                // Brand/keyword hint like "Google" or "OpenAI" (no dot). Map with a curated list.
                if let match = Self.keywordURLMap.first(where: { lower.contains($0.key) })?.value,
                   let url = URL(string: match) {
                    return url
                }
                // FINAL FALLBACK: if message is short and single-word like "acer", try https://acer.com
                let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 1,
                   !trimmed.contains(" "),
                   !trimmed.contains("."),
                   trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) {
                    if let url = URL(string: "https://\(trimmed).com") { return url }
                }
                // Fallback: if instruction looks like a query (e.g., "search OpenAI in that field"), go to Google
                if lower.contains("search") {
                    return URL(string: "https://google.com")
                }
                break
            }
        }
        return nil
    }

    /// Extracts an explicit search query from the nearest user message.
    /// Examples:
    /// - "search OpenAI" → "OpenAI"
    /// - "ok search for potato chips" → "potato chips"
    /// - "type in Amazon.com in the search field" → "Amazon.com"
    /// - "find best laptops" → "best laptops"
    /// - "go to google and search RTX 5090" → "RTX 5090"
    private func extractExplicitSearchQuery(for messageId: UUID) -> String? {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }), idx > 0 else { return nil }
        for i in stride(from: idx - 1, through: 0, by: -1) {
            let m = messages[i]
            guard m.role == .user, let text = m.text else { continue }
            let lower = text.lowercased()

            // Accept both Substring and String to avoid call-site mismatch
            func cleanQuery(_ raw: Substring) -> String? {
                var q = String(raw).trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove filler like a leading "for " or surrounding quotes
                if q.lowercased().hasPrefix("for ") {
                    q = String(q.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                }
                q = q.trimmingCharacters(in: CharacterSet(charactersIn: "\"'` "))
                // Avoid obviously empty/trivial
                if q.isEmpty { return nil }
                return q
            }
            func cleanQuery(_ raw: String) -> String? { return cleanQuery(raw[raw.startIndex...]) }

            // UI nouns we should not interpret as queries (e.g., "search bar")
            let uiNouns: Set<String> = ["bar","box","field","icon","button","tab","area","input"]

            // Pattern 0: "type <query> in (…bar/box/field)" — common phrasing
            if let r = lower.range(of: "type ") {
                var tailLower = lower[r.upperBound...]
                // Look for a known UI suffix after the query to bound it
                let suffixes = [
                    " in the search bar", " in that search bar", " into the search bar",
                    " in the search box", " in that search box", " into the search box",
                    " in the search field", " in that search field", " into the search field",
                    " in the bar", " in that bar", " into the bar",
                    " in the box", " in that box", " into the box",
                    " in the field", " in that field", " into the field",
                    " in search", " into search"
                ]
                if let sfxRange = suffixes
                    .compactMap({ tailLower.range(of: $0) })
                    .sorted(by: { $0.lowerBound < $1.lowerBound })
                    .first {
                    tailLower = tailLower[..<sfxRange.lowerBound]
                }
                if let cleaned = cleanQuery(tailLower) { return cleaned }
            }

            // Pattern 1: "search <query>" or "search for <query>" (but ignore UI nouns like "search bar")
            if let r = lower.range(of: "search ") {
                let tailLower = lower[r.upperBound...]
                if let firstWordSub = tailLower.split(whereSeparator: { $0.isWhitespace }).first {
                    let firstWord = String(firstWordSub).trimmingCharacters(in: CharacterSet.punctuationCharacters).lowercased()
                    if uiNouns.contains(firstWord) == false {
                        if let cleaned = cleanQuery(tailLower) { return cleaned }
                    }
                } else if let cleaned = cleanQuery(tailLower) { return cleaned }
            }
            // Pattern 2: "find <query>" or "find for <query>" (also ignore UI nouns)
            if let r = lower.range(of: "find ") {
                let tailLower = lower[r.upperBound...]
                if let firstWordSub = tailLower.split(whereSeparator: { $0.isWhitespace }).first {
                    let firstWord = String(firstWordSub).trimmingCharacters(in: CharacterSet.punctuationCharacters).lowercased()
                    if uiNouns.contains(firstWord) == false {
                        if let cleaned = cleanQuery(tailLower) { return cleaned }
                    }
                } else if let cleaned = cleanQuery(tailLower) { return cleaned }
            }
            // Pattern 3: "type in <query> ..."
            if let r = lower.range(of: "type in ") {
                var tail = text[r.upperBound...]
                // Trim suffixes like "in the search field" or "and press enter"
                let suffixes = [" in the search field", " in search", " into the search field", " and press enter", " then press enter"]
                for sfx in suffixes {
                    if let range = tail.lowercased().range(of: sfx) {
                        tail = tail[..<range.lowerBound]
                        break
                    }
                }
                if let cleaned = cleanQuery(tail) { return cleaned }
            }
            // Pattern 3b: "put/enter/input/write/key in/paste <query> in (that|the) (search )?(bar|box|field)"
            do {
                let prefixes = ["put ", "enter ", "input ", "write ", "key in ", "paste "]
                let suffixes = [
                    " in the search bar", " in that search bar", " into the search bar",
                    " in the search box", " in that search box", " into the search box",
                    " in the search field", " in that search field", " into the search field",
                    " in the bar", " in that bar", " into the bar",
                    " in the box", " in that box", " into the box",
                    " in the field", " in that field", " into the field",
                    " in search", " into search"
                ]
                // Try each prefix; extract text between prefix and a following suffix (if any)
                for pfx in prefixes {
                    if let pr = lower.range(of: pfx) {
                        let startIdx = pr.upperBound
                        // If a known suffix exists after the prefix, extract up to it; else take the rest
                        var segment = text[startIdx...]
                        if let sfxRange = suffixes.compactMap({ lower.range(of: $0, range: startIdx..<lower.endIndex) }).sorted(by: { $0.lowerBound < $1.lowerBound }).first {
                            segment = text[startIdx..<sfxRange.lowerBound]
                        }
                        if let cleaned = cleanQuery(segment) { return cleaned }
                    }
                }
            }
            // Pattern 4: "go to google ... and search <query>"
            if lower.contains("go to google") || lower.contains("open google") {
                if let andR = lower.range(of: "and ") {
                    let tailLower = lower[andR.upperBound...]
                    if let sr = tailLower.range(of: "search ") {
                        if let cleaned = cleanQuery(text[sr.upperBound...]) { return cleaned }
                    }
                }
            }
            break
        }
        return nil
    }

    /// Extract an explicit click target text from the nearest user message, e.g.:
    /// - click "Backpack Name"
    /// - click the item named "Backpack Name"
    /// - click the one named 'Backpack Name'
    private func extractExplicitClickTarget(for messageId: UUID) -> String? {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }), idx > 0 else { return nil }
        for i in stride(from: idx - 1, through: 0, by: -1) {
            let m = messages[i]
            guard m.role == .user, let text = m.text else { continue }
            let lower = text.lowercased()
            guard let cr = lower.range(of: "click ") else { break }
            let tail = text[cr.upperBound...]
            // Prefer quoted targets
            if let qr = tail.range(of: #"\"([^\"]+)\""#, options: .regularExpression) {
                let inside = tail[qr].dropFirst().dropLast() // remove quotes
                let value = String(inside)
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return value }
            }
            if let qr = tail.range(of: #"'([^']+)'"#, options: .regularExpression) {
                let inside = tail[qr].dropFirst().dropLast()
                let value = String(inside)
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return value }
            }
            // Fallback pattern: "named <X>"
            if let nr = lower.range(of: "named ") {
                let namedTail = text[nr.upperBound...]
                // up to punctuation or line end
                let stopSet = CharacterSet(charactersIn: ",.;:!?\n")
                let fragment = namedTail.prefix { ch in
                    guard let sc = ch.unicodeScalars.first else { return true }
                    return !stopSet.contains(sc)
                }
                let value = String(fragment).trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
            break
        }
        return nil
    }

    /// Normalizes verbose search phrases into concise queries.
    /// Examples:
    /// - "find me some pencils" -> "pencils"
    /// - "find some running shoes" -> "running shoes"
    /// - "show me laptops" -> "laptops"
    private func refineSearchPhrase(_ raw: String) -> String {
        var q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = q.lowercased()
        // Strip common leading filler
        let leadingPatterns = [
            "find me some ", "find me ", "find some ", "find ",
            "show me some ", "show me ", "show ",
            "look for ", "search for ", "search ", "get me ", "get "
        ]
        for p in leadingPatterns {
            if lower.hasPrefix(p) {
                q = String(q.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        // Strip trivial trailing filler
        let trailing = [" please", " thanks", ".", ",", "!"]
        for t in trailing { if q.lowercased().hasSuffix(t) { q = String(q.dropLast(t.count)) } }
        return q.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extracts computer action from streaming item
    private func extractComputerAction(from item: StreamingItem) -> ComputerAction? {
        guard item.type == "computer_call", let actionDict = item.action else {
            return nil
        }

        guard let actionType = actionDict["type"]?.value as? String else {
            return nil
        }

        var parameters: [String: Any] = [:]
        for (key, anyCodableValue) in actionDict {
            if key != "type" {
                parameters[key] = anyCodableValue.value
            }
        }

        return ComputerAction(type: actionType, parameters: parameters)
    }

    /// Sends computer call output back to OpenAI API
    private func sendComputerCallOutput(item: StreamingItem, output: Any, previousId: String, messageId: UUID) async {
        do {
            let response = try await api.sendComputerCallOutput(
                call: item,
                output: output,
                model: activePrompt.openAIModel,
                previousResponseId: previousId
            )
            await MainActor.run {
                self.handleNonStreamingResponse(response, for: messageId)
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
                // CRITICAL FIX: Reset streaming status on computer_call_output network failure
                self.streamingStatus = .idle
                self.isStreaming = false
                self.isAwaitingComputerOutput = false
            }
        }
    }

    /// Handles a screenshot received during streaming for computer use.
    func handleComputerScreenshot(_ chunk: StreamingEvent, for messageId: UUID) {
        AppLogger.log("[CUA] handleComputerScreenshot: Processing streaming screenshot event", category: .openAI, level: .info)

        guard let item = chunk.item,
              let content = item.content?.first,
              let imageData = extractImageDataFromContent(content)
        else {
            AppLogger.log("[CUA] handleComputerScreenshot: FAILED to extract image data from streaming chunk", category: .openAI, level: .error)
            return
        }

        if let image = UIImage(data: imageData) {
            if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessages = messages
                if updatedMessages[msgIndex].images == nil {
                    updatedMessages[msgIndex].images = []
                }
                // Replace previous screenshot if one exists
                updatedMessages[msgIndex].images?.removeAll()
                updatedMessages[msgIndex].images?.append(image)
                messages = updatedMessages
            }
        }
    }

    /// Helper method to extract image data from various content types
    private func extractImageDataFromContent(_ content: StreamingContentItem) -> Data? {
        // Try different ways to get image data based on content type
        if let imageUrl = content.imageURL ?? content.text,
           let imageDataString = imageUrl.split(separator: ",").last.map(String.init),
           let imageData = Data(base64Encoded: imageDataString) {
            return imageData
        }
        return nil
    }

    /// Handles the completion of a streaming item, such as an image or tool call.
    /// For gpt-image-1, the "completed" event often does not include the final image bytes in `item.content`.
    /// We primarily rely on partial_image updates for previews/finals and an existing fallback that fetches
    /// the full response if images are returned as image_url/image_file content.
    func handleCompletedStreamingItem(_ item: StreamingItem, for messageId: UUID) {
        // Ensure the message still exists before proceeding
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }

        if item.type == "function_call" {
            let status = item.status?.lowercased() ?? "unknown"
            if status == "in_progress" {
                AppLogger.log("⏳ [Function Call] Streaming item \(item.id) still in progress (callId=\(item.callId ?? "none"))", category: .openAI, level: .debug)
                return
            }

            AppLogger.log("🔔 [Function Call] Streaming item completed: id=\(item.id), callId=\(item.callId ?? "none"), name=\(item.name ?? "<unknown>")", category: .openAI, level: .info)
            let outputItem = OutputItem(streamingItem: item)

            // Check if this is part of a parallel batch by looking at the response ID
            if let responseId = lastResponseId {
                Task { [weak self] in
                    guard let self else { return }
                    await self.handleFunctionCallWithBatching(outputItem, for: messageId, responseId: responseId)
                }
            } else {
                // No response ID available, execute immediately
                Task { [weak self] in
                    guard let self else { return }
                    await self.handleFunctionCall(outputItem, for: messageId)
                }
            }
            return
        }

        // Handle image generation completion
        if item.type == "image_generation_call" {
            // Completed event may not carry image bytes. If partials arrived, the last partial is already appended.
            // If the model returned images as image_url/image_file elsewhere, our fallback path (final getResponse)
            // will fetch them. So we only log a lightweight note here.
            AppLogger.log("ℹ️ [Image Generation] Completed event received for item \(item.id). Awaiting any final image_url/image_file in subsequent items, if provided.", category: .openAI, level: .info)
        }

        // Handle MCP tool completion
        if item.type == "mcp_call" {
            let status = item.status?.lowercased()
            let resolved = resolveServerLabel(
                serverLabel: item.serverLabel,
                itemServerLabel: item.serverLabel,
                fallbackId: item.id
            )
            if resolved.usedFallback {
                AppLogger.log("ℹ️ [MCP] call completion missing server_label; using '\(resolved.label)'", category: .openAI, level: .debug)
            }
            let serverLabel = resolved.label
            lastMCPServerLabel = serverLabel
            let displayName: String
            if let toolName = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !toolName.isEmpty {
                displayName = toolName
            } else {
                let suffix = String(item.id.prefix(6))
                displayName = "MCP tool \(suffix)"
            }

            if status == "failed" {
                let errorDescription = describeMCPError(status: status, stringError: nil, structuredError: item.error)
                AppLogger.log("❌ [MCP] Tool call failed: \(displayName) on server \(serverLabel) - \(errorDescription)", category: .openAI, level: .error)
                logActivity("MCP: \(displayName) failed - \(errorDescription)")

                var updatedMessages = messages
                let failureText = renderMCPFailureText(
                    serverLabel: serverLabel,
                    toolName: displayName,
                    errorDescription: errorDescription,
                    rawArguments: item.arguments
                )
                let existing = updatedMessages[messageIndex].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                updatedMessages[messageIndex].text = existing.isEmpty ? failureText : "\(existing)\n\n\(failureText)"
                if updatedMessages[messageIndex].toolsUsed == nil {
                    updatedMessages[messageIndex].toolsUsed = []
                }
                if !updatedMessages[messageIndex].toolsUsed!.contains("mcp") {
                    updatedMessages[messageIndex].toolsUsed!.append("mcp")
                }
                messages = updatedMessages
                return
            }

            if status == "completed" || status == "done" {
                AppLogger.log("✅ [MCP] Tool call completed: \(displayName) on server \(serverLabel)", category: .openAI, level: .info)
            } else {
                AppLogger.log("ℹ️ [MCP] Tool call status '\(status ?? "unknown")' for item \(item.id) on server \(serverLabel)", category: .openAI, level: .debug)
            }

            var updatedMessages = messages
            var mutated = false
            if updatedMessages[messageIndex].toolsUsed == nil {
                updatedMessages[messageIndex].toolsUsed = []
                mutated = true
            }
            if updatedMessages[messageIndex].toolsUsed?.contains("mcp") == false {
                updatedMessages[messageIndex].toolsUsed?.append("mcp")
                AppLogger.log("🔧 [MCP Tool Tracking] Added MCP tool to message \(messageId)", category: .openAI, level: .debug)
                mutated = true
            }
            if mutated {
                messages = updatedMessages
            }
        }

        // Note: For other image types like image_file/image_url, they would be handled by the annotation system
        // or the fallback mechanism that fetches the final response
    }

    /// Handles partial image updates from gpt-image-1 model
    /// The base64 data for partial images is provided in `partial_image_b64` at the event level.
    /// We decode it and append/replace the latest preview image.
    func handlePartialImageUpdate(_ chunk: StreamingEvent, for messageId: UUID) {
        // Prefer the documented partial_image_b64, but also accept common alternates
        let candidates: [String?] = [chunk.partialImageB64, chunk.imageB64, chunk.dataB64, chunk.item?.content?.first?.text]
        guard let b64 = candidates.compactMap({ $0 }).first,
              let imageData = Data(base64Encoded: b64),
              let image = UIImage(data: imageData) else {
            return
        }

        // We'll track partial images using a different approach since UIImage doesn't have isPartial
        if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
            var updatedMessages = messages
            if updatedMessages[msgIndex].images == nil {
                updatedMessages[msgIndex].images = []
            }

            // For partial image updates, we'll replace the last image if it exists
            // This assumes partial updates replace the previous partial image
            if !updatedMessages[msgIndex].images!.isEmpty {
                updatedMessages[msgIndex].images!.removeLast()
            }
            updatedMessages[msgIndex].images?.append(image)
            messages = updatedMessages
        }
    }

    /// Resolves image links mentioned in assistant text and appends any fetched images or file artifacts to the message.
    /// Supports data:image base64 and http(s) image URLs. sandbox:/ paths are resolved via container annotations when possible.
    func consumeImageLinks(_ links: [String], for messageId: UUID) async {
        let sandboxLinks = links.filter { $0.lowercased().hasPrefix("sandbox:/") }
        let sawSandbox = !sandboxLinks.isEmpty
        let sawSandboxImage = sandboxLinks.contains { link in
            let normalized = link.replacingOccurrences(of: "sandbox:/", with: "sandbox://")
            let ext = (URL(string: normalized)?.pathExtension ?? "").lowercased()
            return ["png", "jpg", "jpeg", "gif", "webp"].contains(ext)
        }
        // Decode inline data URLs first to provide instant previews
        for link in links {
            if link.lowercased().hasPrefix("data:image/") {
                if let commaIdx = link.firstIndex(of: ",") {
                    let b64 = String(link[link.index(after: commaIdx)...])
                    if let data = Data(base64Encoded: b64), let image = UIImage(data: data) {
                        await MainActor.run { [weak self] in self?.appendImage(image, to: messageId) }
                    }
                }
            }
        }

        // Then fetch remote http(s) image URLs
        for link in links {
            if let url = URL(string: link), ["http","https"].contains(url.scheme?.lowercased() ?? "") {
                do {
                    let (data, resp) = try await URLSession.shared.data(from: url)
                    guard (resp as? HTTPURLResponse)?.statusCode == 200 else { continue }
                    if let image = UIImage(data: data) {
                        await MainActor.run { [weak self] in self?.appendImage(image, to: messageId) }
                    }
                } catch {
                    AppLogger.log("Failed to fetch image URL: \(link) — \(error)", category: .openAI, level: .warning)
                }
            }
        }

        // If sandbox links were found, try to resolve them using container annotations (filename match) and fetch via container endpoint
        if sawSandbox {
            var appendedSandboxArtifact = false
            // Extract lastPathComponent-like filenames from sandbox links
            let filenames: [String] = sandboxLinks.compactMap { link in
                guard link.lowercased().hasPrefix("sandbox:/") else { return nil }
                // Convert to a URL-compatible string to use URL parsing for path components
                let normalized = link.replacingOccurrences(of: "sandbox:/", with: "sandbox://")
                return URL(string: normalized)?.lastPathComponent
            }
            let filenameSet = Set(filenames.map { $0.lowercased() })
            if let annos = containerAnnotationsByMessage[messageId], !annos.isEmpty {
                for match in annos where filenameSet.contains((match.filename ?? "").lowercased()) {
                    let annotationKey = "\(match.containerId)_\(match.fileId)"
                    let alreadyHasArtifact = await MainActor.run { [weak self] in
                        guard let self, let idx = self.messages.firstIndex(where: { $0.id == messageId }) else { return false }
                        return self.messages[idx].artifacts?.contains(where: { $0.fileId == match.fileId }) == true
                    }
                    if alreadyHasArtifact {
                        continue
                    }
                    do {
                        let data: Data
                        if let cached = containerFileCache[annotationKey] {
                            data = cached
                        } else {
                            data = try await api.fetchContainerFileContent(containerId: match.containerId, fileId: match.fileId)
                            containerFileCache[annotationKey] = data
                        }
                        let artifact = createArtifact(
                            fileId: match.fileId,
                            filename: match.filename ?? match.fileId,
                            containerId: match.containerId,
                            data: data
                        )
                        await MainActor.run { [weak self] in
                            self?.appendArtifact(artifact, to: messageId)
                        }
                        appendedSandboxArtifact = true
                    } catch {
                        AppLogger.log("Sandbox link fallback fetch failed for \(match.filename ?? match.fileId): \(error)", category: .openAI, level: .warning)
                    }
                }
            }
            // If after fallback we still have no images or artifacts, add a one-time note
            await MainActor.run { [weak self] in
                guard let self = self, let idx = self.messages.firstIndex(where: { $0.id == messageId }) else { return }
                let hasImages = !(self.messages[idx].images?.isEmpty ?? true)
                let hasArtifacts = !(self.messages[idx].artifacts?.isEmpty ?? true)
                let alreadyNoted = self.messages.contains {
                    $0.text?.contains("Note: The assistant referenced a sandbox file path.") == true
                    || $0.text?.contains("Note: The assistant referenced a sandbox image path.") == true
                }
                if !hasImages && !hasArtifacts && !appendedSandboxArtifact && !alreadyNoted {
                    let noteText = sawSandboxImage
                        ? "Note: The assistant referenced a sandbox image path. These aren’t directly accessible in the app. Ask it to return the image as an image_file or http(s) link to preview it here."
                        : "Note: The assistant referenced a sandbox file path. These aren’t directly accessible in the app. Ask it to attach the file (e.g., via code interpreter output) or provide an http(s) link."
                    let note = ChatMessage(role: .system, text: noteText)
                    self.messages.append(note)
                }
            }
        }
    }

    /// Appends an image to the specified message safely on the main thread.
    /// - Ensures the correct message is targeted by re-finding it by ID.
    /// - Deduplicates identical images by comparing PNG-encoded bytes.
    /// - Emits a lightweight log for diagnostics.
    @MainActor
    private func appendImage(_ image: UIImage, to messageId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var updated = messages
        if updated[idx].images == nil { updated[idx].images = [] }
        let alreadyHas = updated[idx].images!.contains { existing in
            guard let a = existing.pngData(), let b = image.pngData() else { return false }
            return a == b
        }
        if !alreadyHas {
            updated[idx].images?.append(image)
            AppLogger.log("🖼️ Appended image to message \(messageId), total images=\(updated[idx].images?.count ?? 0)", category: .ui, level: .info)
        } else {
            AppLogger.log("🖼️ Skipped duplicate image for message \(messageId)", category: .ui, level: .debug)
        }
        messages = updated
    }

    /// Handles errors that occur during API calls or other operations.
    func handleError(_ error: Error) {
        let specificError = OpenAIServiceError.from(error: error)
        let errorText = specificError.userFriendlyDescription

        if let streamingId = streamingMessageId {
            finalizeStreamingReasoning(for: streamingId)
        }

        // Log the error with analytics
        AnalyticsService.shared.trackError(specificError, context: "ChatViewModel")

        // Set the error message to be displayed in an alert
        self.errorMessage = errorText

        // Provide more user-friendly error messages for production
        let userFriendlyText: String
        switch specificError {
        case .missingAPIKey:
            userFriendlyText = "⚠️ Please add your OpenAI API key in Settings to start chatting."
        case .requestFailed(let statusCode, let message):
            if statusCode == 401 {
                userFriendlyText = "⚠️ Invalid API key. Please check your OpenAI API key in Settings."
            } else if statusCode == 403 {
                userFriendlyText = "⚠️ Access denied. Your API key may not have the required permissions."
            } else if statusCode >= 500 {
                userFriendlyText = "⚠️ OpenAI servers are temporarily unavailable. Please try again in a moment."
            } else {
                userFriendlyText = "⚠️ Request failed: \(message)"
            }
        case .rateLimited(let retryAfter, _):
            userFriendlyText = "⚠️ Rate limit reached. Please wait \(retryAfter) seconds before trying again."
        case .invalidResponseData:
            userFriendlyText = "⚠️ Received unexpected data from OpenAI. Please try again."
        case .networkError:
            userFriendlyText = "⚠️ No internet connection. Please check your network and try again."
        case .decodingError:
            userFriendlyText = "⚠️ Unable to process OpenAI's response. Please try again."
        case .fileError(let message):
            userFriendlyText = "⚠️ File operation failed: \(message)"
        case .invalidRequest(let message):
            userFriendlyText = "⚠️ Invalid request: \(message)"
        }

        // Also append a system message to the chat for context
        let errorMsg = ChatMessage(role: .system, text: userFriendlyText, images: nil)
        messages.append(errorMsg)

        // If rate limited, disable input temporarily
        if case .rateLimited(let retryAfter, _) = specificError {
            isStreaming = true // Disable input
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(retryAfter)) { [weak self] in
                self?.isStreaming = false // Re-enable input after delay
            }
        }
    }

    /// Resets the conversation by clearing messages and forgetting the last response ID.
    func clearConversation() {
        guard var conversation = activeConversation else { return }
        conversation.messages.removeAll()
        conversation.lastResponseId = nil

        // Clear performance caches
        containerFileCache.removeAll()
        processedAnnotations.removeAll()
        deltaBuffers.removeAll()
        deltaFlushWorkItems.values.forEach { $0.cancel() }
        deltaFlushWorkItems.removeAll()
        surfacedMCPToolWarnings.removeAll()
        streamingReasoningTextByMessageId.removeAll()
        streamingReasoningTraceIdByMessageId.removeAll()
        reasoningBufferByResponseId.removeAll()
        functionCallResponseIds.removeAll()

        updateActiveConversation(conversation)
    }

    /// Deletes a specific message from the active conversation.
    func deleteMessage(_ message: ChatMessage) {
        guard var conversation = activeConversation,
              let index = conversation.messages.firstIndex(where: { $0.id == message.id })
        else { return }

        conversation.messages.remove(at: index)
        streamingReasoningTextByMessageId.removeValue(forKey: message.id)
        streamingReasoningTraceIdByMessageId.removeValue(forKey: message.id)
        updateActiveConversation(conversation)
    }

    /// Cancels the ongoing streaming request.
    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        // Cleanup any buffered deltas and pending flush tasks for the current message
        if let streamingId = streamingMessageId {
            if let work = deltaFlushWorkItems[streamingId] { work.cancel() }
            deltaFlushWorkItems[streamingId] = nil
            flushDeltaBufferIfNeeded(for: streamingId)
            // Stop any image generation heartbeats
            stopImageGenerationHeartbeat(for: streamingId)
            finalizeStreamingReasoning(for: streamingId)
        }

        // Update UI immediately
        isStreaming = false
        streamingStatus = .idle

        // If there was a message being streamed, update its text to show it was cancelled
        if let streamingId = streamingMessageId, let msgIndex = messages.firstIndex(where: { $0.id == streamingId }) {
            var updatedMessages = messages
            if updatedMessages[msgIndex].text?.isEmpty ?? true {
                // If no content was received, remove the placeholder message
                updatedMessages.remove(at: msgIndex)
            } else {
                // If some content was received, mark it as cancelled
                updatedMessages[msgIndex].text = (updatedMessages[msgIndex].text ?? "") + "\n\n[Streaming cancelled by user]"
            }
            messages = updatedMessages // Trigger UI update
        }

        streamingMessageId = nil
    }

    /// Updates the streaming status based on the event type and item context
    func updateStreamingStatus(for eventType: String, item: StreamingItem? = nil, messageId: UUID? = nil) {
        switch eventType {
        case "response.created":
            streamingStatus = .connecting
            logActivity("Response registered")
        case "response.in_progress":
            // Generic in-progress heartbeat from the API
            if streamingStatus == .idle { streamingStatus = .thinking }
            logActivity("Analyzing request")
        case "response.output_text.delta":
            streamingStatus = .streamingText
            // Do not log every token to avoid spam
        case "response.output_item.added":
            // When a new output item is added (e.g., reasoning, tool call, message)
            if let typ = item?.type {
                if typ == "reasoning" { streamingStatus = .thinking }
                logActivity("Started output: \(typ)")
            } else {
                logActivity("Started output item")
            }
        case "response.output_item.delta":
            // Deltas for a specific output item (e.g., reasoning tokens)
            if let typ = item?.type, typ == "reasoning" { streamingStatus = .thinking }
            // Avoid per-token spam; rely on status change and other milestones
            break
        case "response.output_item.completed":
            if let typ = item?.type {
                logActivity("Completed output: \(typ)")
            } else {
                logActivity("Completed output item")
            }
        case "response.image_generation_call.in_progress":
            streamingStatus = .generatingImage
            logActivity("🎨 Starting image render")
            // Start a heartbeat to show progress during long generation times
            // Only start if not already running for this message
            if let msgId = messageId, imageHeartbeatTasks[msgId] == nil {
                startImageGenerationHeartbeat(for: msgId)
            }
        case "response.image_generation_call.partial_image":
            streamingStatus = .imageGenerationProgress("Generating image")
            logActivity("🖼️ Updating image preview")
       case "response.computer_call.in_progress", "computer.in_progress",
           "response.computer_call.screenshot_taken", "computer.screenshot",
           "response.computer_call.action_performed", "computer.action",
           "response.computer_call.completed", "computer.completed":
            // Always surface the simple, recognizable "Using computer" chip in the UI
            streamingStatus = .usingComputer
            switch eventType {
            case "response.computer_call.in_progress", "computer.in_progress":
                logActivity("Computer: staging action")
            case "response.computer_call.screenshot_taken", "computer.screenshot":
                logActivity("Computer: captured screenshot")
            case "response.computer_call.action_performed", "computer.action":
                if let action = item?.action, let type = action["type"]?.value as? String {
                    logActivity("Computer: executed \(type)")
                } else {
                    logActivity("Computer: executed action")
                }
            case "response.computer_call.completed", "computer.completed":
                logActivity("Computer: step complete")
            default: break
            }
        case "response.tool_call.started":
            if let toolName = item?.name {
                // Special-case the computer tool to keep the UX consistent
                if toolName == APICapabilities.ToolType.computer.rawValue || toolName == "computer" {
                    streamingStatus = .usingComputer
                    logActivity("Computer tool engaged")
                } else if toolName == "code_interpreter" {
                    streamingStatus = .generatingCode
                    logActivity("Code interpreter engaged")
                } else if toolName == "fetchAppleCalendarEvents" {
                    streamingStatus = .runningTool("Calendar")
                    logActivity("📅 Fetching Apple Calendar events")
                } else if toolName == "createAppleCalendarEvent" {
                    streamingStatus = .runningTool("Calendar")
                    logActivity("📅 Creating calendar event")
                } else if toolName == "fetchAppleReminders" {
                    streamingStatus = .runningTool("Reminders")
                    logActivity("✅ Fetching Apple Reminders")
                } else if toolName == "createAppleReminder" {
                    streamingStatus = .runningTool("Reminders")
                    logActivity("📝 Creating Apple Reminder")
                } else {
                    streamingStatus = .runningTool(toolName)
                    logActivity("Executing tool: \(toolName)")
                }
            } else {
                streamingStatus = .runningTool("unknown")
                logActivity("Executing tool")
            }
        case "response.output_text.annotation.added":
            // When artifacts are being processed from code interpreter
            streamingStatus = .processingArtifacts
            logActivity("Processing generated files")
        case "response.mcp_list_tools.added", "response.mcp_list_tools.updated", "response.mcp_list_tools.in_progress", "response.mcp_list_tools.completed", "response.mcp_list_tools.failed":
            let serverLabel = item?.serverLabel ?? "MCP"
            let status = item?.status?.lowercased()
            if status == "failed" || item?.error != nil {
                streamingStatus = .runningTool("MCP error")
                logActivity("⚠️ MCP: Listing tools failed for \(serverLabel)")
            } else {
                streamingStatus = .runningTool("MCP: \(serverLabel)")
                if eventType.hasSuffix("completed") || status == "completed" {
                    logActivity("✅ MCP: Tools ready from \(serverLabel)")
                } else if eventType.hasSuffix("in_progress") {
                    logActivity("🔧 MCP: Listing tools for \(serverLabel)")
                } else {
                    logActivity("🔧 MCP: Updating tools for \(serverLabel)")
                }
            }
        case "response.mcp_call.added", "response.mcp_call.in_progress":
            if let toolName = item?.name, let serverLabel = item?.serverLabel {
                streamingStatus = .runningTool("MCP: \(toolName)")
                logActivity("🔧 MCP: Invoking \(toolName) on \(serverLabel)")
            } else if let toolName = item?.name {
                streamingStatus = .runningTool("MCP: \(toolName)")
                logActivity("🔧 MCP: Invoking \(toolName)")
            } else {
                streamingStatus = .runningTool("MCP")
                logActivity("🔧 MCP: Running tool call")
            }
        case "response.mcp_call.done", "response.mcp_call.completed", "response.mcp_call.failed":
            let toolName = item?.name ?? "MCP tool"
            let status = item?.status?.lowercased()
            let isFailureEvent = eventType.hasSuffix("failed")
            if status == "failed" || item?.error != nil || isFailureEvent {
                streamingStatus = .runningTool("MCP error")
                logActivity("⚠️ MCP: \(toolName) failed")
            } else {
                logActivity("✅ MCP: \(toolName) completed")
            }
        case "response.mcp_call_arguments.delta":
            if let name = item?.name ?? item?.serverLabel {
                logActivity("🔧 MCP: Assembling arguments for \(name)")
            } else {
                logActivity("🔧 MCP: Assembling tool arguments")
            }
        case "response.mcp_call_arguments.done":
            if let name = item?.name ?? item?.serverLabel {
                logActivity("✅ MCP: Arguments ready for \(name)")
            } else {
                logActivity("✅ MCP: Arguments ready")
            }
        case "response.mcp_approval_request.added":
            if let toolName = item?.name, let serverLabel = item?.serverLabel {
                streamingStatus = .runningTool("MCP: Awaiting approval")
                logActivity("🔒 MCP: \(toolName) on \(serverLabel) awaiting approval")
            } else {
                streamingStatus = .runningTool("MCP: Awaiting approval")
                logActivity("🔒 MCP: Approval required")
            }
        case "response.done", "response.completed":
            // Prefer idle when we've explicitly finished the stream in handleStreamChunk
            streamingStatus = .idle
            logActivity("Response delivered")
        default:
            // Keep current status for unknown events
            break
        }
    }

    /// Convenience method for updating status with just event type
    func updateStreamingStatus(for eventType: String) {
        updateStreamingStatus(for: eventType, item: nil, messageId: nil)
    }

    /// Clears any pending file attachments and related temporary buffers.
    /// This is called on error/completion to ensure no stale attachments leak into the next request.
    func clearPendingFileAttachments() {
        pendingFileAttachments.removeAll()
        pendingImageAttachments.removeAll()
        pendingFileData.removeAll()
        pendingFileNames.removeAll()
    }

    // MARK: - Attachment Helpers (used by ChatView)
    /// Appends selected images to the pending attachments list.
    func attachImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        pendingImageAttachments.append(contentsOf: images)
    }

    /// Removes a pending image attachment by index safely.
    func removeImageAttachment(at index: Int) {
        guard pendingImageAttachments.indices.contains(index) else { return }
        pendingImageAttachments.remove(at: index)
    }

    /// Removes a pending file attachment by index safely.
    func removeFileAttachment(at index: Int) {
        // Keep names/data arrays in sync when removing
        if pendingFileNames.indices.contains(index) {
            pendingFileNames.remove(at: index)
        }
        if pendingFileData.indices.contains(index) {
            pendingFileData.remove(at: index)
        }
        // For file_search-style attachments referenced by ID, maintain that list too
        if pendingFileAttachments.indices.contains(index) {
            pendingFileAttachments.remove(at: index)
        }
    }

    /// Exports the current conversation as formatted text for sharing
    func exportConversationText() -> String {
        guard let conversation = activeConversation, !conversation.messages.isEmpty else {
            return "No conversation to export."
        }

        var exportText = "# \(conversation.title)\n"
        exportText += "Exported from OpenResponses\n"
        exportText += "Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"

        for message in conversation.messages {
            let rolePrefix: String
            switch message.role {
            case .user:
                rolePrefix = "👤 User:"
            case .assistant:
                rolePrefix = "🤖 Assistant:"
            case .system:
                rolePrefix = "⚙️ System:"
            }

            exportText += "\(rolePrefix)\n"
            if let text = message.text, !text.isEmpty {
                exportText += "\(text)\n"
            }

            if let images = message.images, !images.isEmpty {
                exportText += "[Contains \(images.count) image(s)]\n"
            }

            if let artifacts = message.artifacts, !artifacts.isEmpty {
                exportText += "[Contains \(artifacts.count) artifact(s): "
                exportText += artifacts.map { "\($0.filename) (\($0.artifactType.rawValue))" }.joined(separator: ", ")
                exportText += "]\n"
            }

            exportText += "\n---\n\n"
        }

        return exportText
    }
}

// MARK: - Artifact Management
extension ChatViewModel {
    /// Create an artifact from raw data based on file type
    func createArtifact(fileId: String, filename: String, containerId: String, data: Data) -> CodeInterpreterArtifact {
        let ext = (filename as NSString).pathExtension.lowercased()

        // Determine MIME type from extension
        let mimeType = mimeTypeForExtension(ext)

        // Create appropriate content based on file type
        let content: ArtifactContent

        // Image types
        if ["jpg", "jpeg", "png", "gif"].contains(ext) {
            if let image = UIImage(data: data) {
                content = .image(image)
            } else {
                content = .error("Invalid image data")
            }
        }
        // Text-based types that should be displayed as text
        else if ["txt", "log", "py", "js", "html", "css", "json", "csv", "md", "c", "cpp", "java", "rb", "php", "sh", "ts", "xml"].contains(ext) {
            if let textContent = String(data: data, encoding: .utf8) {
                content = .text(textContent)
            } else {
                content = .error("Could not decode text content")
            }
        }
        // Binary data files
        else {
            content = .data(data)
        }

        return CodeInterpreterArtifact(
            fileId: fileId,
            filename: filename,
            containerId: containerId,
            mimeType: mimeType,
            content: content
        )
    }

    /// Append an artifact to a message
    func appendArtifact(_ artifact: CodeInterpreterArtifact, to messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        if messages[index].artifacts == nil {
            messages[index].artifacts = []
        }
        messages[index].artifacts?.append(artifact)

        // If it's an image artifact, also add to the legacy images array for backward compatibility
        if case .image(let image) = artifact.content {
            appendImage(image, to: messageId)
        }
    }

    /// Get MIME type for file extension
    private func mimeTypeForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "txt": return "text/plain"
        case "log": return "text/plain"
        case "py": return "text/x-python"
        case "js": return "text/javascript"
        case "html": return "text/html"
        case "css": return "text/css"
        case "json": return "application/json"
        case "csv": return "text/csv"
        case "md": return "text/markdown"
        case "c": return "text/x-c"
        case "cpp": return "text/x-c++"
        case "java": return "text/x-java"
        case "rb": return "text/x-ruby"
        case "php": return "text/x-php"
        case "sh": return "application/x-sh"
        case "ts": return "application/typescript"
        case "xml": return "application/xml"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        case "tar": return "application/x-tar"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Reasoning Replay Support
extension ChatViewModel {
    /// Clears any live reasoning buffers tied to a given assistant message.
    func resetStreamingReasoning(for messageId: UUID) {
        streamingReasoningTextByMessageId[messageId] = ""
        streamingReasoningTraceIdByMessageId.removeValue(forKey: messageId)

        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages
            updated[index].reasoning = nil
            messages = updated
        }
    }

    /// Appends a reasoning delta emitted during streaming to the live transcript panel.
    func appendStreamingReasoning(delta: String, to messageId: UUID) {
        let trimmed = delta.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var aggregate = streamingReasoningTextByMessageId[messageId] ?? ""

        if trimmed == aggregate {
            return
        } else if !aggregate.isEmpty, trimmed.hasPrefix(aggregate) {
            aggregate = trimmed
        } else if !aggregate.isEmpty, aggregate.hasSuffix(trimmed) {
            return
        } else if !aggregate.isEmpty, aggregate.contains(trimmed) {
            return
        } else {
            aggregate.append(aggregate.isEmpty ? trimmed : " " + trimmed)
        }
        streamingReasoningTextByMessageId[messageId] = aggregate

        let traceId = streamingReasoningTraceIdByMessageId[messageId] ?? UUID()
        streamingReasoningTraceIdByMessageId[messageId] = traceId

        let trace = ReasoningTrace(id: traceId, text: aggregate, isSummary: true)
        updateStreamingReasoningTrace(trace, messageId: messageId)
    }

    /// Removes live reasoning buffers once the final reasoning payload arrives.
    func finalizeStreamingReasoning(for messageId: UUID) {
        streamingReasoningTextByMessageId.removeValue(forKey: messageId)
        streamingReasoningTraceIdByMessageId.removeValue(forKey: messageId)
    }

    private func updateStreamingReasoningTrace(_ trace: ReasoningTrace, messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        var updated = messages
        var reasoning = updated[index].reasoning ?? []
        if let existingIndex = reasoning.firstIndex(where: { $0.id == trace.id }) {
            reasoning[existingIndex] = trace
        } else {
            reasoning.insert(trace, at: 0)
        }
        updated[index].reasoning = reasoning
        messages = updated
    }

    @discardableResult
    func storeReasoningItems(from response: OpenAIResponse) -> [[String: Any]]? {
        let payloads = response.output.compactMap { makeReasoningPayload(from: $0) }
        updateReasoningBuffer(with: payloads, responseId: response.id)
        return payloads.isEmpty ? nil : payloads
    }

    @discardableResult
    func storeReasoningItems(from response: StreamingResponse) -> [[String: Any]]? {
        let payloads = (response.output ?? []).compactMap { makeReasoningPayload(from: $0) }
        updateReasoningBuffer(with: payloads, responseId: response.id)
        return payloads.isEmpty ? nil : payloads
    }

    /// Transforms the cached reasoning payload dictionaries into display-ready trace models.
    func convertReasoningPayloadsToTraces(_ payloads: [[String: Any]]) -> [ReasoningTrace] {
        guard !payloads.isEmpty else { return [] }

        var summaries: [ReasoningTrace] = []
        var details: [ReasoningTrace] = []
        var seenTexts = Set<String>()

        for payload in payloads {
            guard (payload["type"] as? String) == "reasoning" else { continue }

            if let summaryItems = payload["summary"] as? [[String: Any]] {
                for item in summaryItems {
                    guard let text = item["text"] as? String else { continue }
                    let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty, seenTexts.insert(cleaned).inserted else { continue }
                    summaries.append(ReasoningTrace(text: cleaned, isSummary: true))
                }
            }

            if let contentItems = payload["content"] as? [[String: Any]] {
                for item in contentItems {
                    guard let text = item["text"] as? String else { continue }
                    let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty, seenTexts.insert(cleaned).inserted else { continue }
                    let level = item["level"] as? Int ?? payload["level"] as? Int
                    details.append(ReasoningTrace(text: cleaned, level: level))
                }
            }
        }

        return summaries + details
    }

    /// Binds the latest reasoning trace list to the assistant message associated with a response ID.
    func applyReasoningTraces(responseId: String?, to messageId: UUID) {
        let payloads: [[String: Any]]?
        if let responseId, let cached = reasoningBufferByResponseId[responseId] {
            payloads = cached
        } else if let liveText = streamingReasoningTextByMessageId[messageId]?.trimmingCharacters(in: .whitespacesAndNewlines), !liveText.isEmpty {
            payloads = [[
                "type": "reasoning",
                "summary": [["text": liveText]]
            ]]
        } else {
            payloads = nil
        }

        guard let payloads else {
            finalizeStreamingReasoning(for: messageId)
            return
        }

        let traces = convertReasoningPayloadsToTraces(payloads)

        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else {
            finalizeStreamingReasoning(for: messageId)
            return
        }

        var updatedMessages = messages
        updatedMessages[messageIndex].reasoning = traces.isEmpty ? nil : traces
        messages = updatedMessages
        finalizeStreamingReasoning(for: messageId)
    }

    func updateReasoningBuffer(with payloads: [[String: Any]]?, responseId: String) {
        guard let payloads else {
            reasoningBufferByResponseId.removeValue(forKey: responseId)
            AppLogger.log("🧠 [Reasoning] Removed cache entry for response \(responseId)", category: .openAI, level: .debug)
            return
        }

        reasoningBufferByResponseId[responseId] = payloads
        if payloads.isEmpty {
            AppLogger.log("🧠 [Reasoning] Cached empty reasoning payload for response \(responseId)", category: .openAI, level: .debug)
        } else {
            AppLogger.log("🧠 [Reasoning] Cached \(payloads.count) reasoning item(s) for response \(responseId)", category: .openAI, level: .info)
        }
    }

    func reasoningPayloadsRequireSummary(_ payloads: [[String: Any]]?) -> Bool {
        guard let payloads else { return true }
        guard !payloads.isEmpty else { return false }
        return payloads.contains { entry in
            guard (entry["type"] as? String) == "reasoning" else { return false }
            return entry["summary"] == nil
        }
    }

    func sanitizedReasoningPayloads(_ payloads: [[String: Any]]?) -> [[String: Any]]? {
        guard var payloads = payloads else { return nil }
        guard !payloads.isEmpty else { return [] }
        for index in payloads.indices {
            guard (payloads[index]["type"] as? String) == "reasoning" else { continue }
            if payloads[index]["summary"] == nil {
                payloads[index]["summary"] = []
            }
        }
        return payloads
    }

    func awaitReasoningPayload(for responseId: String, existingPayloads: [[String: Any]]?) async -> [[String: Any]]? {
        if let existingPayloads, !existingPayloads.isEmpty {
            return existingPayloads
        }

        let pollInterval = UInt64(150_000_000) // 150ms
        let maxAttempts = 20
        var attempt = 0

        while attempt < maxAttempts && !Task.isCancelled {
            if let payloads = reasoningBufferByResponseId[responseId], !payloads.isEmpty {
                return payloads
            }

            attempt += 1
            do {
                try await Task.sleep(nanoseconds: pollInterval)
            } catch {
                break
            }
        }

        return reasoningBufferByResponseId[responseId] ?? existingPayloads
    }

    func shouldSurfaceBatchError(_ error: Error) -> Bool {
        guard case OpenAIServiceError.requestFailed(_, let message) = error else { return true }
        let normalized = message.lowercased()
        if normalized.contains("missing reasoning item") ||
            normalized.contains("missing reasoning") ||
            normalized.contains("no tool output found") {
            return false
        }
        return true
    }

    func makeReasoningPayload(from item: OutputItem) -> [String: Any]? {
        guard item.type == "reasoning" else { return nil }

        var dict: [String: Any] = [
            "type": item.type,
            "id": item.id
        ]

        if let content = item.content {
            let contentPayloads = content.compactMap { makeReasoningContentPayload(from: $0) }
            if !contentPayloads.isEmpty {
                dict["content"] = contentPayloads
            }
        }

        let summaryPayloads = makeReasoningSummaryPayload(from: item.summary)
        if !summaryPayloads.isEmpty {
            dict["summary"] = summaryPayloads
        }

        return dict
    }

    func makeReasoningPayload(from item: StreamingOutputItem) -> [String: Any]? {
        guard item.type == "reasoning" else { return nil }

        var dict: [String: Any] = [
            "type": item.type,
            "id": item.id
        ]

        if let status = item.status { dict["status"] = status }
        if let role = item.role { dict["role"] = role }

        if let content = item.content {
            let contentPayloads = content.compactMap { makeReasoningContentPayload(from: $0) }
            if !contentPayloads.isEmpty {
                dict["content"] = contentPayloads
            }
        }

        let summaryPayloads = makeReasoningSummaryPayload(from: item.summary)
        if !summaryPayloads.isEmpty {
            dict["summary"] = summaryPayloads
        }

        return dict
    }

    func makeReasoningPayload(from item: StreamingItem) -> [String: Any]? {
        guard item.type == "reasoning" else { return nil }

        var dict: [String: Any] = [
            "type": item.type,
            "id": item.id
        ]

        if let status = item.status { dict["status"] = status }
        if let role = item.role { dict["role"] = role }

        if let content = item.content {
            let contentPayloads = content.compactMap { makeReasoningContentPayload(from: $0) }
            if !contentPayloads.isEmpty {
                dict["content"] = contentPayloads
            }
        }

        if dict["summary"] == nil {
            dict["summary"] = []
        }

        return dict
    }

    func cacheStreamingReasoningItem(_ item: StreamingItem, responseId: String?) {
        guard let payload = makeReasoningPayload(from: item) else { return }
        guard let resolvedResponseId = responseId ?? lastResponseId else { return }

        var existing = reasoningBufferByResponseId[resolvedResponseId] ?? []
        if let idx = existing.firstIndex(where: { ($0["id"] as? String) == item.id }) {
            existing[idx] = payload
        } else {
            existing.append(payload)
        }

        updateReasoningBuffer(with: existing, responseId: resolvedResponseId)
    }

    func makeReasoningContentPayload(from content: ContentItem) -> [String: Any]? {
        var dict: [String: Any] = ["type": content.type]

        if let text = content.text { dict["text"] = text }
        if let imageURL = content.imageURL?.url {
            dict["image_url"] = ["url": imageURL]
        }
        if let imageFile = content.imageFile?.file_id {
            dict["image_file"] = ["file_id": imageFile]
        }

        return dict
    }

    func makeReasoningContentPayload(from content: StreamingContentItem) -> [String: Any]? {
        var dict: [String: Any] = ["type": content.type]

        if let text = content.text { dict["text"] = text }
        if let imageURL = content.imageURL { dict["image_url"] = ["url": imageURL] }

        return dict
    }

    func makeReasoningSummaryPayload(from summary: [SummaryItem]?) -> [[String: Any]] {
        guard let summary, !summary.isEmpty else { return [] }
        return summary.map { [
            "type": $0.type,
            "text": $0.text
        ] }
    }
}

// MARK: - Activity Feed Helpers
extension ChatViewModel {
    /// Append a short, user-friendly line to the activity feed, deduplicated and capped.
    func logActivity(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if lastActivityLine == trimmed { return }
        lastActivityLine = trimmed
        activityLines.append(trimmed)
        if activityLines.count > maxActivityLines {
            activityLines.removeFirst(activityLines.count - maxActivityLines)
        }
    }
    /// Clear activity feed and last-line tracker.
    func clearActivity() {
        activityLines.removeAll()
        lastActivityLine = nil
    }

    /// Starts a heartbeat task during image generation to show periodic progress updates
    private func startImageGenerationHeartbeat(for messageId: UUID) {
        // Cancel any existing heartbeat for this message
        imageHeartbeatTasks[messageId]?.cancel()
        imageHeartbeatCounters[messageId] = 0

        imageHeartbeatTasks[messageId] = Task { [weak self] in
            guard let self = self else { return }

            let heartbeatMessages = [
                "🎨 Composing image",
                "🖼️ Refining details",
                "✨ Adding lighting effects",
                "🎨 Adjusting composition",
                "🖼️ Enhancing quality",
                "✨ Almost ready"
            ]

            var counter = 0
            while !Task.isCancelled {
                // Check if the streaming message is still active (without weak self here since we're in the capture)
                guard self.streamingMessageId == messageId else { break }

                // Wait 3-5 seconds between heartbeats (randomized to feel more natural)
                let delay = Double.random(in: 3.0...5.0)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                guard self.streamingMessageId == messageId else { break }

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    let index = counter % heartbeatMessages.count
                    self.logActivity(heartbeatMessages[index])
                    self.imageHeartbeatCounters[messageId] = counter

                    // Update streaming status with progress indicator
                    if counter > 0 {
                        let progressText = heartbeatMessages[index]
                        self.streamingStatus = .imageGenerationProgress(progressText)
                    }
                }
                counter += 1
            }

            // Cleanup
            await MainActor.run { [weak self] in
                self?.imageHeartbeatTasks[messageId] = nil
                self?.imageHeartbeatCounters[messageId] = nil
            }
        }
    }

    /// Stops the image generation heartbeat for a specific message
    func stopImageGenerationHeartbeat(for messageId: UUID) {
        imageHeartbeatTasks[messageId]?.cancel()
        imageHeartbeatTasks[messageId] = nil
        imageHeartbeatCounters[messageId] = nil
    }

    /// Periodic cleanup of performance caches to prevent memory bloat
    private func cleanupPerformanceCaches() {
        // Keep only the 20 most recent container file cache entries
        if containerFileCache.count > 20 {
            let keysToRemove = containerFileCache.keys.prefix(containerFileCache.count - 20)
            keysToRemove.forEach { containerFileCache.removeValue(forKey: $0) }
        }

        // Clear processed annotations older than current conversation
        let currentMessageIds = Set(messages.map { $0.id })
        processedAnnotations = processedAnnotations.filter { annotation in
            // Keep annotations that might still be relevant
            currentMessageIds.contains { $0.uuidString.contains(annotation.prefix(8)) }
        }

        AppLogger.log("Cleaned performance caches: \(containerFileCache.count) files, \(processedAnnotations.count) annotations", category: .ui, level: .debug)
    }
}

// MARK: - Token Estimation
extension ChatViewModel {
    /// Lightweight token estimator for live counts during streaming.
    /// Heuristic: combine char/4 and words*1.33 to avoid wild swings; final values replaced on completion.
    static func estimateTokens(for text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let compact = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let words = compact.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let chars = compact.count
        let byChars = max(1, chars / 4)
        let byWords = max(1, Int(Double(words) * 1.33))
        return max(1, (byChars + byWords) / 2)
    }
}

// MARK: - Non-Streaming Response Handling
extension ChatViewModel {
    /// Records tool usage for analytics and marks the tool on the message.
    func trackToolUsage(for messageId: UUID, tool: String) {
        // Update message toolsUsed for quick UI badges
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages
            if updated[idx].toolsUsed == nil { updated[idx].toolsUsed = [] }
            if !updated[idx].toolsUsed!.contains(tool) {
                updated[idx].toolsUsed!.append(tool)
                messages = updated
            }
        }

        // Analytics
        AnalyticsService.shared.trackEvent(
            name: "tool_used",
            parameters: [
                "tool": tool,
                AnalyticsParameter.model: activePrompt.openAIModel
            ]
        )
    }

    /// Overload that infers tool name from a streaming item.
    func trackToolUsage(_ item: StreamingItem, for messageId: UUID) {
        let tool: String
        switch item.type {
        case "mcp_call", "mcp_list_tools", "mcp_call_output":
            tool = "mcp"
        case "computer_call", "computer_call_output":
            tool = "computer"
        case "image_generation_call", "image_generation":
            tool = "image_generation"
        case "function_call", "function_call_output":
            tool = "function"
        case "web_search_call", "web_search":
            tool = "web_search"
        case "file_search_call", "file_search":
            tool = "file_search"
        case "code_interpreter_call", "code_interpreter":
            tool = "code_interpreter"
        default:
            tool = item.type
        }
        trackToolUsage(for: messageId, tool: tool)
    }
    /// Handles non-streaming responses from the OpenAI API.
    /// Consolidates text, images, token usage, and triggers follow-up tool workflows.
    private func handleNonStreamingResponse(_ response: OpenAIResponse, for messageId: UUID) {
        AppLogger.log("🎬 [handleNonStreamingResponse] Starting...", category: .openAI, level: .info)
        AppLogger.log("🎬 [handleNonStreamingResponse] Response ID: \(response.id)", category: .openAI, level: .info)
        AppLogger.log("🎬 [handleNonStreamingResponse] Message ID: \(messageId)", category: .openAI, level: .info)

        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else {
            AppLogger.log("❌ [handleNonStreamingResponse] Could not find message with ID \(messageId)", category: .openAI, level: .error)
            return
        }

        AppLogger.log("✅ [handleNonStreamingResponse] Found message at index \(messageIndex)", category: .openAI, level: .info)

        // Persist response ID so the next request can continue the conversation.
        lastResponseId = response.id
        AppLogger.log("Updated lastResponseId to: \(response.id)", category: .openAI, level: .info)

        _ = storeReasoningItems(from: response)

        // Determine if response contains a new assistant message before dispatching tool calls again.
        let hasAssistantMessage = response.output.contains { item in
            item.type == "message" && (item.content?.contains { ($0.type == "output_text" || $0.type == "text") && ($0.text?.isEmpty == false) } ?? false)
        }

        if !hasAssistantMessage,
           let functionCallItem = response.output.first(where: { $0.type == "function_call" }) {
            AppLogger.log("🔧 [handleNonStreamingResponse] No assistant message yet; handling function call \(functionCallItem.name ?? "<unknown>")", category: .openAI, level: .info)
            Task { [weak self] in
                guard let self = self else { return }
                await self.handleFunctionCall(functionCallItem, for: messageId)
            }
            return
        } else if hasAssistantMessage {
            AppLogger.log("✅ [handleNonStreamingResponse] Detected assistant message content; skipping function-call recursion", category: .openAI, level: .info)
        } else {
            AppLogger.log("⚠️ [handleNonStreamingResponse] No assistant message or function calls detected", category: .openAI, level: .warning)
        }

        var updatedMessage = messages[messageIndex]

        // Consolidate assistant text from any output item (reasoning blocks excluded when possible).
        let allContents = response.output
            .compactMap { $0.content }
            .flatMap { $0 }

        AppLogger.log("📋 [handleNonStreamingResponse] Total content parts: \(allContents.count)", category: .openAI, level: .info)

        for (index, content) in allContents.enumerated() {
            AppLogger.log("📋 [handleNonStreamingResponse] Content \(index): type=\(content.type), hasText=\(content.text != nil), textLength=\(content.text?.count ?? 0)", category: .openAI, level: .info)
        }

        if let textContent = allContents.first(where: { ($0.type == "output_text" || $0.type == "text") && ($0.text?.isEmpty == false) }) {
            updatedMessage.text = textContent.text ?? ""
            AppLogger.log("✅ [handleNonStreamingResponse] Set message text from output_text/text: \(updatedMessage.text?.count ?? 0) chars", category: .openAI, level: .info)
        } else if let anyText = allContents.first(where: { $0.text?.isEmpty == false })?.text {
            updatedMessage.text = anyText
            AppLogger.log("✅ [handleNonStreamingResponse] Set message text from any content: \(updatedMessage.text?.count ?? 0) chars", category: .openAI, level: .info)
        } else {
            AppLogger.log("⚠️ [handleNonStreamingResponse] No text content found in response", category: .openAI, level: .warning)
        }

        // Retrieve image content bundled in the response.
        for outputItem in response.output {
            for content in outputItem.content ?? [] where content.type == "image_file" || content.type == "image_url" {
                Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        let data = try await api.fetchImageData(for: content)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                if let idx = self.messages.firstIndex(where: { $0.id == messageId }) {
                                    if self.messages[idx].images == nil { self.messages[idx].images = [] }
                                    self.messages[idx].images?.append(image)
                                }
                            }
                        }
                    } catch {
                        AppLogger.log("Failed to fetch image data: \(error)", category: .openAI, level: .warning)
                    }
                }
            }
        }

        // Parse assistant text for external image links and load previews when reachable.
        if let text = updatedMessage.text, !text.isEmpty {
            let links = URLDetector.extractImageLinks(from: text)
            if !links.isEmpty {
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.consumeImageLinks(links, for: messageId)
                }
            }
        }

        // Store deterministic token usage metrics supplied by the API.
        if let usage = response.usage {
            var usageModel = updatedMessage.tokenUsage ?? TokenUsage()
            usageModel.input = usage.promptTokens
            usageModel.output = usage.completionTokens
            usageModel.total = usage.totalTokens
            updatedMessage.tokenUsage = usageModel
        }

        messages[messageIndex] = updatedMessage
        applyReasoningTraces(responseId: response.id, to: messageId)
        recomputeCumulativeUsage()

        AppLogger.log("💬 [handleNonStreamingResponse] Final message text: \(updatedMessage.text ?? "<no text>")", category: .openAI, level: .info)
        AppLogger.log("💬 [handleNonStreamingResponse] Message text length: \(updatedMessage.text?.count ?? 0) chars", category: .openAI, level: .info)
        AppLogger.log("💬 [handleNonStreamingResponse] Message updated in array at index \(messageIndex)", category: .openAI, level: .info)

        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.messageReceived,
            parameters: [
                AnalyticsParameter.model: activePrompt.openAIModel,
                AnalyticsParameter.messageLength: updatedMessage.text?.count ?? 0,
                AnalyticsParameter.streamingEnabled: false,
                "has_images": updatedMessage.images?.isEmpty == false
            ]
        )

        AppLogger.log("✅ [handleNonStreamingResponse] Completed successfully", category: .openAI, level: .info)

        // Auto-resolve any computer calls that arrive in non-streaming mode to keep chains progressing.
        if activePrompt.enableComputerUse,
           response.output.contains(where: { $0.type == "computer_call" }),
           !isResolvingComputerCalls {
            Task { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.isAwaitingComputerOutput = true
                    self.streamingStatus = .usingComputer
                }
                _ = try? await self.resolveAllPendingComputerCallsIfAny(for: messageId)
                await MainActor.run {
                    self.isAwaitingComputerOutput = false
                    if self.streamingMessageId != nil && self.lastResponseId == nil {
                        self.streamingMessageId = nil
                        self.isStreaming = false
                        self.streamingStatus = .idle
                        AppLogger.log("Computer use completed - cleaning up stream state", category: .openAI, level: .info)
                    }
                }
            }
        } else if !activePrompt.enableComputerUse || !response.output.contains(where: { $0.type == "computer_call" }) {
            if streamingMessageId != nil {
                streamingMessageId = nil
                isStreaming = false
                streamingStatus = .idle
                AppLogger.log("Non-streaming response completed - cleaning up stream state", category: .openAI, level: .info)
            }
        }
    }
}
