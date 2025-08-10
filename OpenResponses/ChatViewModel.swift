import SwiftUI
import Combine

class ChatViewModel: ObservableObject { // Conforms to ObservableObject
    @Published var messages: [ChatMessage] = []
    @Published var streamingStatus: StreamingStatus = .idle // Tracks the streaming state
    @Published var isStreaming: Bool = false // To disable UI during streaming
    @Published var pendingFileAttachments: [String] = [] // To hold file IDs for the next message
    @Published var activePrompt: Prompt // Holds the current settings configuration
    @Published var errorMessage: String? // Holds the current error message for display

    private let api = OpenAIService()              // Service for API calls
    private var lastResponseId: String? = nil      // Store the last response ID for continuity
    private var streamingMessageId: UUID? = nil    // Tracks the message being actively streamed
    private var cancellables = Set<AnyCancellable>()
    private var streamingTask: Task<Void, Never>? // Task for managing the streaming process

    init() {
        // Initialize with a default prompt configuration
        self.activePrompt = Prompt.defaultPrompt()
        
        // Load the last used prompt from UserDefaults or create a default
        loadActivePrompt()
        
        // Observe changes to the active prompt and save them
        $activePrompt
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // Debounce to avoid excessive saving
            .sink { [weak self] updatedPrompt in
                self?.saveActivePrompt()
            }
            .store(in: &cancellables)
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
                // Upload the file using the API service
                let fileId = try await api.uploadFile(from: url)
                
                // Stop accessing the resource once we're done
                url.stopAccessingSecurityScopedResource()
                
                await MainActor.run {
                    // Add the file ID to the pending list
                    self.pendingFileAttachments.append(fileId)
                    
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
        
        // Store the response ID for conversation continuity
        if let responseId = response.id {
            lastResponseId = responseId
        }
        
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
    }
    
    /// Handles a function call from the API by executing the function and sending the result back.
    private func handleFunctionCall(_ call: OutputItem, for messageId: UUID) async {
        guard let functionName = call.name, let _ = call.callId else {
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
    private func saveActivePrompt() {
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
    
    /// Process a single chunk from the OpenAI streaming response.
    private func handleStreamChunk(_ chunk: StreamingEvent, for messageId: UUID) {
        // Ensure we are still streaming this message to prevent race conditions
        guard streamingMessageId == messageId else {
            print("Ignoring chunk for a completed or old stream.")
            return
        }

        // Find the message to update
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        // Update the streaming status based on the event
        updateStreamingStatus(for: chunk.type)
        
        // Update the last response ID for continuity if we have a response object
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
    
    /// Updates the streaming status based on the event type from the API.
    private func updateStreamingStatus(for eventType: String) {
        switch eventType {
        case "response.created":
            streamingStatus = .connecting
        case "response.output_item.added":
            // Set to processing only if it's a tool call, otherwise wait for text
            // This logic can be refined if we know the item type
            if streamingStatus == .connecting {
                streamingStatus = .processing
            }
        case "response.output_text.delta":
            if streamingStatus != .streaming {
                streamingStatus = .streaming
            }
        case "response.done":
            streamingStatus = .done
        default:
            // No status change for other events
            break
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
        var errorText = "An error occurred."
        if let serviceError = error as? OpenAIServiceError {
            switch serviceError {
            case .missingAPIKey:
                errorText = "API Key is missing. Please set your OpenAI API key in Settings."
            case .requestFailed(_, let message):
                errorText = "API request failed: \(message)"
            case .invalidResponseData:
                errorText = "Received invalid data from the API."
            }
        } else if error is CancellationError {
            errorText = "The request was cancelled."
        } else {
            errorText = error.localizedDescription
        }
        
        // Set the error message to be displayed in an alert
        self.errorMessage = errorText
        
        // Also append a system message to the chat for context
        let errorMsg = ChatMessage(role: .system, text: "⚠️ \(errorText)", images: nil)
        messages.append(errorMsg)
        
        // Set the error message for display
        self.errorMessage = errorText
    }
    
    /// Resets the conversation by clearing messages and forgetting the last response ID.
    func clearConversation() {
        messages.removeAll()
        lastResponseId = nil
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
