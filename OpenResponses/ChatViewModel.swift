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
    @Published var activePrompt: Prompt
    @Published var errorMessage: String?
    @Published var isConnectedToNetwork: Bool = true
    @Published var currentModelCompatibility: [ModelCompatibilityService.ToolCompatibility] = []

    // MARK: - Private Properties
    private let api: OpenAIServiceProtocol
    private let storageService: ConversationStorageService
    private var streamingMessageId: UUID?
    private var cancellables = Set<AnyCancellable>()
    private var streamingTask: Task<Void, Never>?
    private let networkMonitor = NetworkMonitor.shared

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

    init(api: OpenAIServiceProtocol? = nil, storageService: ConversationStorageService = .shared) {
        self.api = api ?? OpenAIService()
        self.storageService = storageService
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
        
        // Cancel any existing streaming task before starting a new one.
        // This prevents receiving chunks from a previous, unfinished stream.
        streamingTask?.cancel()
        
        // Append the user's message to the chat
        let userMsg = ChatMessage(role: .user, text: trimmed, images: nil)
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
        
        // Clear pending attachments now that they are included in the request
        if attachments != nil {
            pendingFileAttachments.removeAll()
        }
        
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
                "has_attachments": attachments != nil
            ]
        )
        
        // Call the OpenAI API asynchronously
        streamingTask = Task {
            await MainActor.run { self.streamingStatus = .connecting }
            do {
                if streamingEnabled {
                    // Use streaming API
                    let stream = api.streamChatRequest(userMessage: trimmed, prompt: activePrompt, attachments: attachments, previousResponseId: lastResponseId)
                    
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
                    let response = try await api.sendChatRequest(userMessage: trimmed, prompt: activePrompt, attachments: attachments, previousResponseId: lastResponseId)
                    
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
                        self.streamingStatus = .idle // Reset on error
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
                // Mark as done and reset after a delay
                if self.streamingStatus != .idle {
                    self.streamingStatus = .done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.streamingStatus = .idle
                    }
                }
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
    
    /// Handle non-streaming response from OpenAI API
    private func handleNonStreamingResponse(_ response: OpenAIResponse, for messageId: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        // CRITICAL: Update the lastResponseId to maintain conversation state.
        // This ID is required for the next message to continue the conversation.
        self.lastResponseId = response.id
        print("Updated lastResponseId to: \(response.id)")
        
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
    }
    
    /// Handles a function call from the API by executing the function and sending the result back.
    private func handleFunctionCall(_ call: OutputItem, for messageId: UUID) async {
        guard let functionName = call.name else {
            handleError(OpenAIServiceError.invalidResponseData)
            return
        }
        
        // For now, we only handle the calculator
        guard functionName == "calculator" else {
            let errorMsg = ChatMessage(role: .system, text: "Error: Assistant tried to call unknown function '\(functionName)'.")
            await MainActor.run { messages.append(errorMsg) }
            return
        }
        
        // Execute the calculator function
        var functionResult: String
        do {
            // Safely decode the expression from the arguments JSON
            struct CalcArgs: Decodable { let expression: String }
            guard let argsData = call.arguments?.data(using: .utf8) else {
                throw NSError(domain: "CalcError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid arguments format"])
            }
            let decodedArgs = try JSONDecoder().decode(CalcArgs.self, from: argsData)
            
            // Evaluate the expression
            let expression = NSExpression(format: decodedArgs.expression)
            if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
                functionResult = result.stringValue
            } else {
                throw NSError(domain: "CalcError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid math expression"])
            }
        } catch {
            functionResult = "Error: \(error.localizedDescription)"
        }
        
        // Send the result back to the API
        do {
            let finalResponse = try await api.sendFunctionOutput(
                call: call,
                output: functionResult,
                model: activePrompt.openAIModel,
                previousResponseId: lastResponseId
            )
            
            // Handle the final response from the model
            await MainActor.run {
                self.handleNonStreamingResponse(finalResponse, for: messageId)
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
    
    /// Determines the current model to use from UserDefaults (or default).
    private func currentModel() -> String {
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
    
    /// Loads the `activePrompt` from UserDefaults.
    private func loadActivePrompt() {
        if let data = UserDefaults.standard.data(forKey: "activePrompt"),
           let decoded = try? JSONDecoder().decode(Prompt.self, from: data) {
            self.activePrompt = decoded
            print("Active prompt loaded.")
        } else {
            // If no saved prompt is found, use the default
            self.activePrompt = Prompt.defaultPrompt()
            print("No saved prompt found, initialized with default.")
        }
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
            print("Ignoring chunk for a completed or old stream.")
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
        case "response.output_item.content.delta":
            // Handle text delta updates
            if let delta = chunk.delta {
                let currentText = messages[msgIndex].text ?? ""
                messages[msgIndex].text = currentText + delta
            }
            
        case "response.output_item.content.done":
            // Handle completion of content items (like images)
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            
        case "response.output_item.done":
            // Handle completion of output items
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            
        case "response.done":
            // Handle completion of the entire response
            print("Streaming response completed for message: \(messageId)")
            
        default:
            // Other events are handled by the status updater
            break
        }
    }
    
    /// Updates the streaming status based on the event type from the API, providing more granular feedback.
    private func updateStreamingStatus(for eventType: String, item: StreamingItem? = nil) {
        // Use a dispatch queue to ensure status updates are processed sequentially
        // and don't get overwritten by rapid-fire events.
        DispatchQueue.main.async {
            switch eventType {
            case "response.created":
                self.streamingStatus = .responseCreated
            case "response.queued":
                self.streamingStatus = .connecting
            case "response.in_progress":
                self.streamingStatus = .connecting
            case "response.output_item.added":
                // Check the item type to determine what the model is doing
                if let item = item {
                    switch item.type {
                    case "reasoning":
                        self.streamingStatus = .thinking
                    case "message":
                        // This indicates we're about to receive text
                        self.streamingStatus = .streamingText
                    case "tool_call":
                        // Handle specific tools
                        if let toolName = item.name {
                            switch toolName {
                            case "web_search_preview":
                                self.streamingStatus = .searchingWeb
                            case "code_interpreter":
                                self.streamingStatus = .generatingCode
                            case "image_generation":
                                self.streamingStatus = .generatingImage
                            default:
                                self.streamingStatus = .runningTool(toolName)
                            }
                        } else {
                            self.streamingStatus = .runningTool("Unknown")
                        }
                    default:
                        break
                    }
                }
            case "response.output_item.reasoning.started":
                self.streamingStatus = .thinking
            case "response.output_item.tool_call.started":
                // Determine the specific tool being used
                if let toolName = item?.name {
                    switch toolName {
                    case "web_search_preview":
                        self.streamingStatus = .searchingWeb
                    case "code_interpreter":
                        self.streamingStatus = .generatingCode
                    case "image_generation":
                        self.streamingStatus = .generatingImage
                    default:
                        self.streamingStatus = .runningTool(toolName)
                    }
                }
            case "response.content_part.added":
                // We're about to start receiving content
                self.streamingStatus = .streamingText
            case "response.output_text.delta":
                // Once we receive the first text delta, we are actively streaming.
                if self.streamingStatus != .streamingText {
                    self.streamingStatus = .streamingText
                }
            case "response.output_item.done":
                // An output item finished, but we might have more coming
                break
            case "response.output_text.done":
                // Text output is complete for this item
                break
            case "response.content_part.done":
                // Content part is complete
                break
            case "response.completed", "response.done":
                self.streamingStatus = .finalizing
            default:
                // No status change for other events, but let's log what we're missing
                print("Unhandled streaming event: \(eventType)")
                break
            }
        }
    }
    
    /// Handle completed streaming items (like images or final text)
    private func handleCompletedStreamingItem(_ item: StreamingItem, for messageId: UUID) {
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        // Skip reasoning and system outputs
        if item.type == "reasoning" || item.type == "system" {
            return
        }
        
        // Process content items
        if let contentItems = item.content {
            for contentItem in contentItems {
                if let text = contentItem.text, !text.isEmpty {
                    // Update text content (this might be redundant with delta updates)
                    messages[msgIndex].text = text
                }
                
                // Handle image content (note: streaming typically doesn't include images)
                if contentItem.type.hasPrefix("image") {
                    // For now, we'll just log this as images are typically not streamed
                    print("Image content detected in streaming response: \(contentItem.type)")
                }
            }
        }
    }
    
    /// Handle errors by appending a system message describing the issue.
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
            if messages[msgIndex].text?.isEmpty ?? true {
                // If no content was received, remove the placeholder message
                messages.remove(at: msgIndex)
            } else {
                // If some content was received, mark it as cancelled
                messages[msgIndex].text = (messages[msgIndex].text ?? "") + "\n\n[Streaming cancelled by user]"
            }
        }
        
        streamingMessageId = nil
    }
}
