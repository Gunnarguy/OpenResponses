import SwiftUI
import Combine

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
    @Published var currentModelCompatibility: [ModelCompatibilityService.ToolCompatibility] = []
    /// True while we are processing a computer-use tool call and must send computer_call_output
    /// before any new message can be sent. Prevents API 400s due to pending tool output.
    @Published var isAwaitingComputerOutput: Bool = false
    // Computer-use preview removed
    
    /// Prevents multiple concurrent computer_call resolution tasks
    private var isResolvingComputerCalls: Bool = false

    // MARK: - Private Properties
    private let api: OpenAIServiceProtocol
    private let computerService: ComputerService
    private let storageService: ConversationStorageService
    private var streamingMessageId: UUID?
    private var cancellables = Set<AnyCancellable>()
    private var streamingTask: Task<Void, Never>?
    private lazy var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Computer Use Circuit Breaker
    private var consecutiveWaitCount: Int = 0
    private let maxConsecutiveWaits: Int = 3

    // Single-shot Screenshot Mode removed

    // MARK: - Computed Properties
    var messages: [ChatMessage] {
        get { activeConversation?.messages ?? [] }
        set {
            guard var conversation = activeConversation else { return }
            conversation.messages = newValue
            updateActiveConversation(conversation)
        }
    }

    private var lastResponseId: String? {
        get { activeConversation?.lastResponseId }
        set {
            guard var conversation = activeConversation else { return }
            conversation.lastResponseId = newValue
            updateActiveConversation(conversation)
        }
    }

    init(api: OpenAIServiceProtocol? = nil, computerService: ComputerService? = nil, storageService: ConversationStorageService? = nil) {
        self.api = api ?? OpenAIService()
        self.computerService = computerService ?? ComputerService()
        self.storageService = storageService ?? ConversationStorageService.shared
        self.activePrompt = Prompt.defaultPrompt()
        
        loadActivePrompt()
        loadConversations()
        
        if conversations.isEmpty {
            createNewConversation()
        } else {
            activeConversation = conversations.first
        }
        
        setupBindings()
        updateModelCompatibility()
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
    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Do not allow sending a new message while a computer-use step is pending.
        if isAwaitingComputerOutput {
            let warn = ChatMessage(role: .system, text: "Please wait—assistant is completing a computer step.", images: nil)
            messages.append(warn)
            return
        }
        
        // Log current prompt state for debugging
        AppLogger.log("Sending message with prompt: model=\(activePrompt.openAIModel), enableComputerUse=\(activePrompt.enableComputerUse)", category: .ui, level: .info)
        
        // Cancel any existing streaming task before starting a new one.
        // This prevents receiving chunks from a previous, unfinished stream.
        streamingTask?.cancel()
        
        // Append the user's message to the chat with URL detection
        let userMsg = ChatMessage.withURLDetection(role: .user, text: trimmed, images: nil)
        messages.append(userMsg)
        
        // Prepare a placeholder for the assistant's streaming response
        let assistantMsgId = UUID()
        let assistantMsg = ChatMessage(id: assistantMsgId, role: .assistant, text: "", images: nil)
        messages.append(assistantMsg)
        streamingMessageId = assistantMsgId // Track the new message for streaming
        
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
        if !pendingFileData.isEmpty {
            pendingFileData.removeAll()
            pendingFileNames.removeAll()
        }
    // no-op: audio removed
        
        // Check if streaming is enabled from the active prompt
        let streamingEnabled = activePrompt.enableStreaming
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

        // No audio path: proceed immediately
        // Call the OpenAI API asynchronously
    streamingTask = Task {
            await MainActor.run { self.streamingStatus = .connecting }
            do {
                // If previous responses are awaiting computer_call_output, resolve them all first.
                if self.activePrompt.enableComputerUse {
                    _ = try? await self.resolveAllPendingComputerCallsIfAny(for: assistantMsgId)
                }
                if streamingEnabled {
                    // Use streaming API
                    let stream = api.streamChatRequest(userMessage: finalUserText, prompt: activePrompt, attachments: attachments, fileData: pendingFileData, fileNames: pendingFileNames, imageAttachments: imageAttachments, previousResponseId: lastResponseId)
                    
                    for try await chunk in stream {
                        // Check for cancellation before handling the next chunk
                        if Task.isCancelled {
                            await MainActor.run {
                                self.handleError(CancellationError())
                            }
                            break
                        }
                        await MainActor.run {
                            self.handleStreamChunk(chunk, for: assistantMsgId)
                        }
                    }
                } else {
                    // Use non-streaming API
                    let response = try await api.sendChatRequest(userMessage: finalUserText, prompt: activePrompt, attachments: attachments, fileData: pendingFileData, fileNames: pendingFileNames, imageAttachments: imageAttachments, previousResponseId: lastResponseId)
                    
                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: assistantMsgId)
                    }
                }
            } catch {
                // Handle errors on main thread, unless it's a cancellation
                if !(error is CancellationError) {
                    await MainActor.run {
                        self.handleError(error)
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
                // Mark as done and reset after a delay, unless we're awaiting computer output
                if self.isAwaitingComputerOutput {
                    self.streamingStatus = .usingComputer
                } else if self.streamingStatus != .idle {
                    self.streamingStatus = .done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.streamingStatus = .idle
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
        while safetyCounter < 8 { // prevent infinite loops
            safetyCounter += 1
            guard let prevId = lastResponseId else { break }
            AppLogger.log("[CUA] resolveAllPending: Getting response for prevId=\(prevId)", category: .openAI, level: .info)
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
            
            // HEURISTIC: If we get another tool call but the message already has an image,
            // assume the primary request is fulfilled and halt further actions to prevent loops.
            if let message = messages.first(where: { $0.id == messageId }), !(message.images?.isEmpty ?? true) {
                AppLogger.log("[CUA] resolveAllPending: Heuristic halt: Message already contains an image. Halting further tool calls to prevent loops.", category: .openAI, level: .info)
                await MainActor.run { 
                    self.streamingStatus = .idle // Final state reset
                    self.lastResponseId = nil // Clear to prevent future loops
                }
                break // Skip this tool call and exit the loop
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
            await MainActor.run { self.isAwaitingComputerOutput = false }
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

        // Heuristic: If the model asked for a bare screenshot as the first step, derive a URL
        // from the user's message so we don't capture an empty white page.
        if actionData.type == "screenshot", actionData.parameters["url"] == nil,
           let derived = deriveURLForScreenshot(from: messageId) {
            AppLogger.log("[CUA] (resume) Auto-attaching URL to screenshot action: \(derived.absoluteString)", category: .openAI, level: .info)
            actionData = ComputerAction(type: "screenshot", parameters: ["url": derived.absoluteString])
        }
        
        // Check for pending safety checks
        if let safetyChecks = outputItem.pendingSafetyChecks, !safetyChecks.isEmpty {
            AppLogger.log("[CUA] (resume) SAFETY CHECKS DETECTED: \(safetyChecks.count) checks pending", category: .openAI, level: .warning)
            for check in safetyChecks {
                AppLogger.log("[CUA] (resume) Safety Check - \(check.code): \(check.message)", category: .openAI, level: .warning)
            }
            AppLogger.log("[CUA] (resume) Auto-acknowledging safety checks to proceed with computer use", category: .openAI, level: .info)
        }
        
        AppLogger.log("[CUA] (resume) Executing action type=\(actionData.type) for callId='\(callId)'", category: .openAI)
    let result = try await computerService.executeAction(actionData)
        
        // Check for consecutive wait actions to prevent infinite loops - but do this AFTER executing the action
        // so we can capture any screenshots or results first
        if actionData.type == "wait" {
            consecutiveWaitCount += 1
            AppLogger.log("[CUA] (resume) Wait action detected. Consecutive count: \(consecutiveWaitCount)/\(maxConsecutiveWaits)", category: .openAI, level: .warning)
            
            if consecutiveWaitCount >= maxConsecutiveWaits {
                AppLogger.log("[CUA] (resume) BREAKING INFINITE WAIT LOOP: \(consecutiveWaitCount) consecutive waits detected. Aborting computer use chain.", category: .openAI, level: .error)
                await MainActor.run {
                    self.consecutiveWaitCount = 0 // Reset counter
                    
                    // Add a system message to inform the user
                    let errorMessage = ChatMessage(
                        role: .system,
                        text: "⚠️ Computer use interrupted: Too many consecutive wait actions detected. The previous screenshot (if any) has been preserved."
                    )
                    self.messages.append(errorMessage)
                    
                    // Clear any streaming status
                    self.isStreaming = false
                    self.streamingStatus = .idle
                    self.lastResponseId = nil
                }
                return // Exit without continuing the computer use chain
            }
        } else {
            // Reset wait counter for non-wait actions
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
                        
                        // Update the message in the messages array
                        var updatedMessages = self.messages
                        updatedMessages[index] = updatedMessage
                        self.messages = updatedMessages  // This triggers the setter and UI update
                        
                        // Explicitly notify that the UI should refresh and give it a moment to process
                        Task { @MainActor in
                            self.objectWillChange.send()
                            // Give SwiftUI a moment to process the change
                            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                            self.objectWillChange.send() // Second notification to ensure UI updates
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
            
            // Include acknowledged safety checks if they were present
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
            await MainActor.run { self.handleNonStreamingResponse(response, for: messageId) }
        } else {
            AppLogger.log("[CUA] (resume) No screenshot; clearing previousId", category: .openAI, level: .warning)
            await MainActor.run { self.lastResponseId = nil }
        }
    }

    /// Internal helper to perform the send after optional transcription is done
    private func performSend(finalUserText: String, fileAttachments: [[String: Any]]?, imageAttachments: [InputImage]?, previousResponseId: String?, assistantMsgId: UUID) async {
        let streamingEnabled = activePrompt.enableStreaming
        await MainActor.run { self.streamingStatus = .connecting }
        do {
            if streamingEnabled {
                let stream = api.streamChatRequest(userMessage: finalUserText, prompt: activePrompt, attachments: fileAttachments, fileData: pendingFileData, fileNames: pendingFileNames, imageAttachments: imageAttachments, previousResponseId: previousResponseId)
                for try await chunk in stream {
                    if Task.isCancelled { await MainActor.run { self.handleError(CancellationError()) }; break }
                    await MainActor.run { self.handleStreamChunk(chunk, for: assistantMsgId) }
                }
            } else {
                let response = try await api.sendChatRequest(userMessage: finalUserText, prompt: activePrompt, attachments: fileAttachments, fileData: pendingFileData, fileNames: pendingFileNames, imageAttachments: imageAttachments, previousResponseId: previousResponseId)
                await MainActor.run { self.handleNonStreamingResponse(response, for: assistantMsgId) }
            }
        } catch {
            if !(error is CancellationError) {
                await MainActor.run {
                    self.handleError(error)
                    self.messages.removeAll { $0.id == assistantMsgId }
                    self.streamingStatus = .idle
                }
            }
        }
        await MainActor.run {
            if let finalMessage = self.messages.first(where: { $0.id == assistantMsgId }) {
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
            if self.streamingStatus != .idle { self.streamingStatus = .done; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.streamingStatus = .idle } }
        }
    }

    private func trackToolUsage(for messageId: UUID, tool: String) {
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        var updatedMessages = messages
        if updatedMessages[msgIndex].toolsUsed == nil {
            updatedMessages[msgIndex].toolsUsed = []
        }
        if !updatedMessages[msgIndex].toolsUsed!.contains(tool) {
            updatedMessages[msgIndex].toolsUsed!.append(tool)
            messages = updatedMessages
        }
    }

    /// Track which tools were used in a streaming response
    private func trackToolUsage(_ item: StreamingItem, for messageId: UUID) {
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        var toolName: String?
        
        // Detect tool type from the streaming item
        switch item.type {
        case "tool_call":
            if let name = item.name {
                switch name {
                case APICapabilities.ToolType.computer.rawValue:
                    toolName = "computer"
                case "web_search":
                    toolName = "web_search"
                case "code_interpreter":
                    toolName = "code_interpreter"
                case "file_search":
                    toolName = "file_search"
                default:
                    toolName = name
                }
            }
        case "computer_call":
            toolName = "computer"
        case "image_generation_call":
            toolName = "image_generation"
        default:
            break
        }
        
        // Add the tool to the message's toolsUsed array
        if let tool = toolName {
            var updatedMessages = messages
            if updatedMessages[msgIndex].toolsUsed == nil {
                updatedMessages[msgIndex].toolsUsed = []
            }
            if !updatedMessages[msgIndex].toolsUsed!.contains(tool) {
                updatedMessages[msgIndex].toolsUsed!.append(tool)
                messages = updatedMessages
                print("🔧 [Tool Tracking] Added tool '\(tool)' to message \(messageId)")
            }
        }
    }
    
    /// Handles the selection of a file, uploads it, and prepares it for the next message.
    func attachFile(from url: URL) {
        // Ensure we can access the file's data
        guard url.startAccessingSecurityScopedResource() else {
            handleError(NSError(domain: "FileAttachmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access file."]))
            return
        }
        
        // Show a status message
        let attachingMessage = ChatMessage(role: .system, text: "Attaching \(url.lastPathComponent)...", images: nil)
        messages.append(attachingMessage)
        
        Task {
            do {
                // Read file data
                let fileData = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                // Upload the file using the API service
                let openAIFile = try await api.uploadFile(
                    fileData: fileData,
                    filename: filename,
                    purpose: "assistants"
                )
                
                // Stop accessing the resource once we're done
                url.stopAccessingSecurityScopedResource()
                
                await MainActor.run {
                    // Add the file ID to the pending list
                    self.pendingFileAttachments.append(openAIFile.id)
                    
                    // Update the status message
                    if let lastMessageIndex = self.messages.lastIndex(where: { $0.id == attachingMessage.id }) {
                        self.messages[lastMessageIndex].text = "✅ File '\(url.lastPathComponent)' attached. It will be sent with your next message."
                    }
                }
            } catch {
                url.stopAccessingSecurityScopedResource()
                await MainActor.run {
                    self.handleError(error)
                    // Update the status message to show failure
                    if let lastMessageIndex = self.messages.lastIndex(where: { $0.id == attachingMessage.id }) {
                        self.messages[lastMessageIndex].text = "❌ Failed to attach file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// Handles the selection of images for attachment to the next message
    func attachImages(_ images: [UIImage]) {
        // Add images to pending attachments
        pendingImageAttachments.append(contentsOf: images)
        
        // Show a status message
        let imageCount = images.count
        let statusText = imageCount == 1 ? 
            "✅ Image attached. It will be sent with your next message." :
            "✅ \(imageCount) images attached. They will be sent with your next message."
        
        let attachingMessage = ChatMessage(role: .system, text: statusText, images: nil)
        messages.append(attachingMessage)
    }
    
    /// Removes an image from pending attachments
    func removeImageAttachment(at index: Int) {
        guard index < pendingImageAttachments.count else { return }
        pendingImageAttachments.remove(at: index)
        
        // Update status message if no images remain
        if pendingImageAttachments.isEmpty {
            let statusMessage = ChatMessage(role: .system, text: "All image attachments removed.", images: nil)
            messages.append(statusMessage)
        }
    }
    
    /// Removes a file from pending attachments
    func removeFileAttachment(at index: Int) {
        guard index < pendingFileData.count && index < pendingFileNames.count else { return }
        pendingFileData.remove(at: index)
        pendingFileNames.remove(at: index)
        
        // Update status message if no files remain
        if pendingFileData.isEmpty {
            let statusMessage = ChatMessage(role: .system, text: "All file attachments removed.", images: nil)
            messages.append(statusMessage)
        }
    }
    
    /// Clears all pending image attachments
    func clearImageAttachments() {
        pendingImageAttachments.removeAll()
    }
    
    // Audio attach/remove removed
    
    /// Handle non-streaming response from OpenAI API
    private func handleNonStreamingResponse(_ response: OpenAIResponse, for messageId: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        // CRITICAL: Update the lastResponseId to maintain conversation state.
        // This ID is required for the next message to continue the conversation.
        self.lastResponseId = response.id
        print("Updated lastResponseId to: \(response.id)")
        
        // Single-shot mode disabled: do not halt on repeated screenshot requests; let stream complete
        
        // Check for and handle function calls
        if let outputItem = response.output.first, outputItem.type == "function_call" {
            Task {
                await handleFunctionCall(outputItem, for: messageId)
            }
            return // Stop further processing, as we'll get a new response
        }
        
        // Update the message with the complete response
        var updatedMessage = messages[messageIndex]
        
        // Extract text content from the response
        if let outputItem = response.output.first,
           let textContent = outputItem.content?.first(where: { $0.type == "output_text" }) {
            updatedMessage.text = textContent.text ?? ""
        }
        
        // Extract images if any
        if let outputItem = response.output.first {
            // Safely unwrap the optional content array before iterating
            for content in outputItem.content ?? [] where content.type == "image_file" || content.type == "image_url" {
                Task {
                    do {
                        let data = try await api.fetchImageData(for: content)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                // Find the message again to avoid race conditions
                                if let msgIndex = self.messages.firstIndex(where: { $0.id == messageId }) {
                                    if self.messages[msgIndex].images == nil {
                                        self.messages[msgIndex].images = []
                                    }
                                    self.messages[msgIndex].images?.append(image)
                                }
                            }
                        }
                    } catch {
                        print("Failed to fetch image data: \(error)")
                    }
                }
            }
        }
        
        messages[messageIndex] = updatedMessage
        
        // Log the final response
        print("Received non-streaming response: \(updatedMessage.text ?? "No text content")")
        
        // Log the received message
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.messageReceived,
            parameters: [
                AnalyticsParameter.model: activePrompt.openAIModel,
                AnalyticsParameter.messageLength: updatedMessage.text?.count ?? 0,
                AnalyticsParameter.streamingEnabled: false,
                "has_images": updatedMessage.images?.isEmpty == false
            ]
        )

        // If the model returned a computer_call in this non-streaming response (e.g., after
        // sending computer_call_output), immediately resolve it to keep the chain moving
        // without waiting for the next user turn.
        if activePrompt.enableComputerUse,
           response.output.contains(where: { $0.type == "computer_call" }),
           !isResolvingComputerCalls {
            Task { [weak self] in
                guard let self = self else { return }
                await MainActor.run { self.isAwaitingComputerOutput = true; self.streamingStatus = .usingComputer }
                _ = try? await self.resolveAllPendingComputerCallsIfAny(for: messageId)
                await MainActor.run { 
                    self.isAwaitingComputerOutput = false
                    // If no more computer calls are pending and we were streaming, clean up the stream
                    if self.streamingMessageId != nil && self.lastResponseId == nil {
                        self.streamingMessageId = nil
                        self.isStreaming = false
                        self.streamingStatus = .idle
                        print("Computer use completed - cleaning up stream state")
                    }
                }
            }
        } else if !activePrompt.enableComputerUse || !response.output.contains(where: { $0.type == "computer_call" }) {
            // No computer calls in response, safe to clean up streaming state if we were streaming
            if streamingMessageId != nil {
                streamingMessageId = nil
                isStreaming = false
                streamingStatus = .idle
                print("Non-streaming response completed - cleaning up stream state")
            }
        }
    }
    
    /// Handles a function call from the API by executing the function and sending the result back.
    private func handleFunctionCall(_ call: OutputItem, for messageId: UUID) async {
        guard let functionName = call.name else {
            handleError(OpenAIServiceError.invalidResponseData)
            return
        }

        // Dispatch by function name. Only user-defined custom tools are supported now.
        let output: String
        if activePrompt.enableCustomTool && functionName == activePrompt.customToolName {
            output = await executeCustomTool(argumentsJSON: call.arguments)
        } else {
            let errorMsg = ChatMessage(role: .system, text: "Error: Assistant tried to call unknown function '\(functionName)'.")
            await MainActor.run { messages.append(errorMsg) }
            return
        }

        // Send the result back to the API
        do {
            let finalResponse = try await api.sendFunctionOutput(
                call: call,
                output: output,
                model: activePrompt.openAIModel,
                previousResponseId: lastResponseId
            )

            await MainActor.run {
                self.handleNonStreamingResponse(finalResponse, for: messageId)
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
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
    
    /// Force reset the active prompt to default values
    func resetToDefaultPrompt() {
        self.activePrompt = Prompt.defaultPrompt()
        UserDefaults.standard.removeObject(forKey: "activePrompt")
        saveActivePrompt()
        print("Prompt reset to default and saved.")
    }
    
    /// Loads the `activePrompt` from UserDefaults.
    private func loadActivePrompt() {
        if let data = UserDefaults.standard.data(forKey: "activePrompt"),
           let decoded = try? JSONDecoder().decode(Prompt.self, from: data) {
            self.activePrompt = decoded
            
            // Migration: Enable computer use by default for existing prompts
            if !self.activePrompt.enableComputerUse {
                print("Migrating existing prompt to enable computer use by default")
                self.activePrompt.enableComputerUse = true
                saveActivePrompt() // Save the migrated prompt
            }
            
            // Validate the model name - if it's a UUID or invalid, reset to default
            if isInvalidModelName(decoded.openAIModel) {
                print("Invalid model name detected: \(decoded.openAIModel), resetting to default")
                self.activePrompt.openAIModel = "gpt-4o"
                saveActivePrompt() // Save the corrected prompt
            }
            
            print("Active prompt loaded.")
        } else {
            // If no saved prompt is found, use the default
            self.activePrompt = Prompt.defaultPrompt()
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
        let newConversation = Conversation.new()
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
    
    /// Process a single chunk from the OpenAI streaming response.
    private func handleStreamChunk(_ chunk: StreamingEvent, for messageId: UUID) {
        // Ensure we are still streaming this message to prevent race conditions
        guard streamingMessageId == messageId else {
            return
        }

        // Find the message to update
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        // Update the streaming status based on the event, passing the item for context
        updateStreamingStatus(for: chunk.type, item: chunk.item)
        
        // Update the last response ID for continuity. This is critical for maintaining conversation state.
        // The ID is received in events like 'response.created' and 'response.output_item.added'.
        if let response = chunk.response {
            lastResponseId = response.id
        }
        
        // Handle different types of streaming events
        switch chunk.type {
        case "error":
            // Handle API errors during streaming
            let errorMessage = chunk.response?.error?.message ?? "An unknown error occurred during streaming"
            
            AppLogger.log("🚨 [Streaming Error] \(errorMessage)", category: .openAI, level: .error)
            
            // Add an error message to the UI
            let systemMessage = ChatMessage(
                role: .system,
                text: "⚠️ Error: \(errorMessage)"
            )
            messages.append(systemMessage)
            
            // CRITICAL: Complete streaming state reset on error
            isStreaming = false
            streamingStatus = .idle
            streamingMessageId = nil
            isAwaitingComputerOutput = false
            
        case "response.failed":
            // Handle failed responses
            let errorMessage = chunk.response?.error?.message ?? "The request failed"
            
            AppLogger.log("🚨 [Response Failed] \(errorMessage)", category: .openAI, level: .error)
            
            // Add an error message to the UI  
            let systemMessage = ChatMessage(
                role: .system,
                text: "⚠️ Request failed: \(errorMessage)"
            )
            messages.append(systemMessage)
            
            // CRITICAL: Complete streaming state reset on failure
            isStreaming = false
            streamingStatus = .idle
            streamingMessageId = nil
            isAwaitingComputerOutput = false
            
        case "response.output_text.delta":
            // Handle text delta updates
            if let delta = chunk.delta {
                print("🔥 [UI Update] Processing text delta: '\(delta)' for message index \(msgIndex)")
                var updatedMessages = messages
                let currentText = updatedMessages[msgIndex].text ?? ""
                updatedMessages[msgIndex].text = currentText + delta
                messages = updatedMessages // This triggers the computed property setter and UI update
                print("🔥 [UI Update] Updated message text to: '\(updatedMessages[msgIndex].text ?? "")'")
            }
            
        case "response.content_part.done":
            // Handle completion of content items (like images)
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            // Computer-use screenshot handling removed
            
        case "response.output_item.done":
            // Handle completion of output items
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
                // Track tool usage
                trackToolUsage(item, for: messageId)
                // If the completed item is a computer tool call, get the full response to extract the action
                if item.type == "computer_call" {
                    // Immediately surface the UI state to show we're continuing with computer use
                    self.isAwaitingComputerOutput = true
                    self.streamingStatus = .usingComputer
                    Task {
                        await self.handleComputerToolCallWithFullResponse(item, messageId: messageId)
                    }
                }
            }
            // Computer-use screenshot handling removed
            
        case "response.done", "response.completed":
            // Handle completion of the entire response
            print("Streaming response completed for message: \(messageId)")

            // CRITICAL: Only reset streaming flags if we're not awaiting computer output
            // If we're awaiting computer output, keep the stream alive for computer use continuation
            if !isAwaitingComputerOutput {
                isStreaming = false
                streamingStatus = .idle
                streamingMessageId = nil
            } else {
                // Keep streaming alive but update status to show computer use is continuing
                streamingStatus = .usingComputer
                print("Stream completed but computer use is continuing - keeping stream alive")
            }

            // After streaming is complete, detect and add URLs to the message
            if let msgIndex = messages.firstIndex(where: { $0.id == messageId }),
               let text = messages[msgIndex].text, !text.isEmpty {
                let detectedURLs = URLDetector.extractRenderableURLs(from: text)
                if !detectedURLs.isEmpty {
                    var updatedMessages = messages
                    updatedMessages[msgIndex].webURLs = detectedURLs
                    messages = updatedMessages
                    print("🌐 [Web Content] Detected \(detectedURLs.count) renderable URLs in assistant response")
                    for url in detectedURLs {
                        print("🌐 [Web Content] Will render: \(url)")
                    }
                }
            }
            
        case "response.image_generation_call.partial_image":
            // Handle partial image preview from gpt-image-1
            handlePartialImageUpdate(chunk, for: messageId)
            
        case "response.image_generation_call.completed":
            // Handle completed image generation
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            
        // Computer Use streaming events
        case "response.computer_call.in_progress":
            // Computer is starting an action - track tool usage
            trackToolUsage(for: messageId, tool: "computer")
            updateStreamingStatus(for: "computer.in_progress")
            
        case "response.computer_call.screenshot_taken":
            // Computer took a screenshot - display it to user
            updateStreamingStatus(for: "computer.screenshot")
            handleComputerScreenshot(chunk, for: messageId)
            
        case "response.computer_call.action_performed":
            // Computer performed an action (click, type, etc.)
            updateStreamingStatus(for: "computer.action")
            
        case "response.computer_call.completed":
            // Computer use action completed
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            updateStreamingStatus(for: "computer.completed")
            
        default:
            // Other events are handled by the status updater
            break
        }
    }

    /// Handles computer tool calls by fetching the full response to get complete action details
    private func handleComputerToolCallWithFullResponse(_ item: StreamingItem, messageId: UUID) async {
        guard activePrompt.enableComputerUse else { return }
        guard let previousId = lastResponseId else { return }

        AppLogger.log("[CUA] Handling computer_call item.id=\(item.id), previousResponseId=\(previousId)", category: .openAI)
        await MainActor.run { self.isAwaitingComputerOutput = true; self.streamingStatus = .usingComputer }
        do {
            // Fetch the full response to get the complete computer_call action (includes call_id)
            let fullResponse = try await api.getResponse(responseId: previousId)
            AppLogger.log("[CUA] Fetched full response for prevId=\(previousId) with \(fullResponse.output.count) items", category: .openAI)

            guard let computerCallItem = fullResponse.output.first(where: { $0.type == "computer_call" && $0.id == item.id }) else {
                AppLogger.log("[CUA] No matching computer_call item found in full response for streaming item.id=\(item.id)", category: .openAI, level: .warning)
                await MainActor.run { self.lastResponseId = nil }
                await MainActor.run { self.isAwaitingComputerOutput = false }
                return
            }

            let callId = computerCallItem.callId ?? item.callId ?? ""
            if callId.isEmpty {
                AppLogger.log("[CUA] Missing call_id for computer_call id=\(computerCallItem.id). Cannot send output.", category: .openAI, level: .error)
                await MainActor.run { self.lastResponseId = nil }
                await MainActor.run { self.isAwaitingComputerOutput = false }
                return
            }

            guard var actionData = extractComputerActionFromOutputItem(computerCallItem) else {
                AppLogger.log("[CUA] Failed to extract action for computer_call id=\(computerCallItem.id)", category: .openAI, level: .error)
                await MainActor.run { self.lastResponseId = nil }
                await MainActor.run { self.isAwaitingComputerOutput = false }
                return
            }

            // Heuristic for first-step screenshot: derive URL from user's prompt
            if actionData.type == "screenshot", actionData.parameters["url"] == nil,
               let derived = deriveURLForScreenshot(from: messageId) {
                AppLogger.log("[CUA] Auto-attaching URL to screenshot action: \(derived.absoluteString)", category: .openAI, level: .info)
                actionData = ComputerAction(type: "screenshot", parameters: ["url": derived.absoluteString])
            }

            AppLogger.log("[CUA] Executing action type=\(actionData.type) params=\(actionData.parameters)", category: .openAI)
            
            // Check for pending safety checks
            if let safetyChecks = computerCallItem.pendingSafetyChecks, !safetyChecks.isEmpty {
                AppLogger.log("[CUA] SAFETY CHECKS DETECTED: \(safetyChecks.count) checks pending", category: .openAI, level: .warning)
                for check in safetyChecks {
                    AppLogger.log("[CUA] Safety Check - \(check.code): \(check.message)", category: .openAI, level: .warning)
                }
                
                // For now, automatically acknowledge all safety checks to allow the computer use to proceed
                // In a production app, you might want to prompt the user for confirmation
                // TODO: Implement user confirmation UI for safety checks
                AppLogger.log("[CUA] Auto-acknowledging safety checks to proceed with computer use", category: .openAI, level: .info)
            }
            
            
            let result = try await computerService.executeAction(actionData)
            
            // Check for consecutive wait actions to prevent infinite loops - but do this AFTER executing the action
            // so we can capture any screenshots or results first
            if actionData.type == "wait" {
                consecutiveWaitCount += 1
                AppLogger.log("[CUA] (streaming) Wait action detected. Consecutive count: \(consecutiveWaitCount)/\(maxConsecutiveWaits)", category: .openAI, level: .warning)
                
                if consecutiveWaitCount >= maxConsecutiveWaits {
                    AppLogger.log("[CUA] (streaming) BREAKING INFINITE WAIT LOOP: \(consecutiveWaitCount) consecutive waits detected. Aborting computer use chain.", category: .openAI, level: .error)
                    await MainActor.run {
                        self.consecutiveWaitCount = 0 // Reset counter
                        self.isAwaitingComputerOutput = false // Reset computer use flag
                        
                        // Add a system message to inform the user
                        let errorMessage = ChatMessage(
                            role: .system,
                            text: "⚠️ Computer use interrupted: Too many consecutive wait actions detected. The previous screenshot (if any) has been preserved."
                        )
                        self.messages.append(errorMessage)
                        
                        // Clear any streaming status
                        self.isStreaming = false
                        self.streamingStatus = .idle
                        self.lastResponseId = nil
                    }
                    return // Exit without continuing the computer use chain
                }
            } else {
                // Reset wait counter for non-wait actions
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
                let acknowledgedSafetyChecks = computerCallItem.pendingSafetyChecks
                
                AppLogger.log("[CUA] Sending computer_call_output for call_id=\(callId)", category: .openAI)
                if let safetyChecks = acknowledgedSafetyChecks {
                    AppLogger.log("[CUA] Including \(safetyChecks.count) acknowledged safety checks", category: .openAI)
                }
                
                do {
                    let response = try await api.sendComputerCallOutput(
                        callId: callId,
                        output: output,
                        model: activePrompt.openAIModel,
                        previousResponseId: previousId,
                        acknowledgedSafetyChecks: acknowledgedSafetyChecks,
                        currentUrl: result.currentURL
                    )
                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: messageId)
                        self.isAwaitingComputerOutput = false
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
        
        let actionDict = actionData.mapValues { $0.value }
        
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
                break
            }
        }
        return nil
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
    private func handleComputerScreenshot(_ chunk: StreamingEvent, for messageId: UUID) {
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
    private func handleCompletedStreamingItem(_ item: StreamingItem, for messageId: UUID) {
        // Find the message to update
        guard messages.firstIndex(where: { $0.id == messageId }) != nil else { return }
        
        // Handle image generation completion
        if item.type == "image_generation_call" || item.type == "image_file" || item.type == "image_url" {
            // For now, skip trying to fetch image data from streaming items
            // This functionality may need to be implemented differently
            print("Skipping image fetch for streaming item of type: \(item.type)")
        }
    }
    
    /// Handles partial image updates from gpt-image-1 model
    private func handlePartialImageUpdate(_ chunk: StreamingEvent, for messageId: UUID) {
        guard let dataString = chunk.item?.content?.first?.text,
              let imageData = Data(base64Encoded: dataString),
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
    
    /// Handles errors that occur during API calls or other operations.
    func handleError(_ error: Error) {
        let specificError = OpenAIServiceError.from(error: error)
        let errorText = specificError.userFriendlyDescription
        
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
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(retryAfter)) {
                self.isStreaming = false // Re-enable input after delay
            }
        }
    }
    
    /// Resets the conversation by clearing messages and forgetting the last response ID.
    func clearConversation() {
        guard var conversation = activeConversation else { return }
        conversation.messages.removeAll()
        conversation.lastResponseId = nil
        updateActiveConversation(conversation)
    }
    
    /// Deletes a specific message from the active conversation.
    func deleteMessage(_ message: ChatMessage) {
        guard var conversation = activeConversation,
              let index = conversation.messages.firstIndex(where: { $0.id == message.id })
        else { return }

        conversation.messages.remove(at: index)
        updateActiveConversation(conversation)
    }

    /// Cancels the ongoing streaming request.
    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        
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
    private func updateStreamingStatus(for eventType: String, item: StreamingItem? = nil) {
        switch eventType {
        case "response.created":
            streamingStatus = .connecting
        case "response.output_text.delta":
            streamingStatus = .streamingText
        case "response.image_generation_call.in_progress":
            streamingStatus = .generatingImage
        case "response.image_generation_call.partial_image":
            streamingStatus = .generatingImage
        case "response.computer_call.in_progress", "computer.in_progress",
             "response.computer_call.screenshot_taken", "computer.screenshot",
             "response.computer_call.action_performed", "computer.action",
             "response.computer_call.completed", "computer.completed":
            // Always surface the simple, recognizable "Using computer" chip in the UI
            streamingStatus = .usingComputer
        case "response.tool_call.started":
            if let toolName = item?.name {
                // Special-case the computer tool to keep the UX consistent
                if toolName == APICapabilities.ToolType.computer.rawValue || toolName == "computer" {
                    streamingStatus = .usingComputer
                } else {
                    streamingStatus = .runningTool(toolName)
                }
            } else {
                streamingStatus = .runningTool("unknown")
            }
        case "response.done", "response.completed":
            // Prefer idle when we've explicitly finished the stream in handleStreamChunk
            streamingStatus = .idle
        default:
            // Keep current status for unknown events
            break
        }
    }
    
    /// Convenience method for updating status with just event type
    private func updateStreamingStatus(for eventType: String) {
        updateStreamingStatus(for: eventType, item: nil)
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
            
            exportText += "\n---\n\n"
        }
        
        return exportText
    }
}
