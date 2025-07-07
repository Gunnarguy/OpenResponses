import SwiftUI
import Combine

class ChatViewModel: ObservableObject { // Conforms to ObservableObject
    @Published var messages: [ChatMessage] = []
    private let api = OpenAIService()              // Service for API calls
    private var lastResponseId: String? = nil      // Store the last response ID for continuity
    private var streamingMessageId: UUID? = nil    // Tracks the message being actively streamed
    
    /// Sends a user message and processes the assistant's response.
    /// This appends the user message to the chat and interacts with the OpenAI service.
    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Append the user's message to the chat
        let userMsg = ChatMessage(role: .user, text: trimmed, images: nil)
        messages.append(userMsg)
        
        // Prepare a placeholder for the assistant's streaming response
        let assistantMsgId = UUID()
        let assistantMsg = ChatMessage(id: assistantMsgId, role: .assistant, text: "", images: nil)
        messages.append(assistantMsg)
        streamingMessageId = assistantMsgId // Track the new message for streaming
        
        // Check if streaming is enabled
        let streamingEnabled = UserDefaults.standard.bool(forKey: "enableStreaming")
        print("Using \(streamingEnabled ? "streaming" : "non-streaming") mode")
        
        // Call the OpenAI API asynchronously
        Task {
            do {
                if streamingEnabled {
                    // Use streaming API
                    let stream = api.streamChatRequest(userMessage: trimmed, model: currentModel(), previousResponseId: lastResponseId)
                    
                    for try await chunk in stream {
                        await MainActor.run { 
                            self.handleStreamChunk(chunk, for: assistantMsgId)
                        }
                    }
                } else {
                    // Use non-streaming API
                    let response = try await api.sendChatRequest(userMessage: trimmed, model: currentModel(), previousResponseId: lastResponseId)
                    
                    await MainActor.run {
                        self.handleNonStreamingResponse(response, for: assistantMsgId)
                    }
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    self.handleError(error)
                    // Remove the placeholder message on error
                    self.messages.removeAll { $0.id == assistantMsgId }
                }
            }
            // Ensure we clear the streaming ID when the task is done, after do-catch
            await MainActor.run {
                self.streamingMessageId = nil
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
        
        // Update the message with the complete response
        var updatedMessage = messages[messageIndex]
        
        // Extract text content from the response
        if let outputItem = response.output.first,
           let textContent = outputItem.content?.first(where: { $0.type == "text" }) {
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
    }
    
    /// Determines the current model to use from UserDefaults (or default).
    private func currentModel() -> String {
        return UserDefaults.standard.string(forKey: "openAIModel") ?? "gpt-4o"
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
            // Handle other streaming event types or log for debugging
            print("Received streaming event type: \(chunk.type)")
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
    private func handleError(_ error: Error) {
        var errorText = "An error occurred."
        if let serviceError = error as? OpenAIServiceError {
            switch serviceError {
            case .missingAPIKey:
                errorText = "⚠️ API Key is missing. Please set your OpenAI API key in Settings."
            case .requestFailed(_, let message):
                errorText = "⚠️ API request failed: \(message)"
            case .invalidResponseData:
                errorText = "⚠️ Received invalid data from the API."
            }
        } else {
            errorText = "⚠️ \(error.localizedDescription)"
        }
        let errorMsg = ChatMessage(role: .system, text: errorText, images: nil)
        messages.append(errorMsg)
    }
    
    /// Resets the conversation by clearing messages and forgetting the last response ID.
    func clearConversation() {
        messages.removeAll()
        lastResponseId = nil
    }
}
