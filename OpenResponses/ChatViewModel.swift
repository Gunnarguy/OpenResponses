import SwiftUI
import Combine

class ChatViewModel: ObservableObject { // Conforms to ObservableObject
    @Published var messages: [ChatMessage] = []
    private let api = OpenAIService()              // Service for API calls
    private var lastResponseId: String? = nil      // Store the last response ID for continuity
    
    /// Sends a user message and processes the assistant's response.
    /// This appends the user message to the chat and interacts with the OpenAI service.
    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Append the user's message to the chat
        let userMsg = ChatMessage(role: .user, text: trimmed, images: nil)
        messages.append(userMsg)
        
        // Call the OpenAI API asynchronously
        Task {
            do {
                // Send request to OpenAI Responses API (with previous_response_id for context if available)
                let response = try await api.sendChatRequest(userMessage: trimmed, model: currentModel(), previousResponseId: lastResponseId)
                
                // Process the API response on the main thread to update UI
                await MainActor.run {
                    self.handleOpenAIResponse(response)
                }
            } catch {
                // Handle errors (e.g., missing API key or network/API errors) on main thread
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    /// Determines the current model to use from UserDefaults (or default).
    private func currentModel() -> String {
        return UserDefaults.standard.string(forKey: "openAIModel") ?? "gpt-4o"
    }
    
    /// Process the OpenAIResponse and append assistant messages (including any tool outputs like images).
    private func handleOpenAIResponse(_ response: OpenAIResponse) {
        lastResponseId = response.id  // Save the ID for the next request's continuity
        for output in response.output {
            // Skip any reasoning-only outputs or hidden system messages if present
            if output.type == "reasoning" || output.type == "system" {
                continue
            }
            // Concatenate all text segments in the output content
            var fullText = ""
            let collectedImages: [UIImage] = []
            if let contentItems = output.content {
                for item in contentItems {
                    if let textSegment = item.text, !textSegment.isEmpty {
                        fullText += textSegment
                    }
                    // If the content item is an image (either file or URL), fetch and collect it
                    if item.type.hasPrefix("image"), (item.imageFile != nil || item.imageURL != nil) {
                        Task {
                            if let data = try? await api.fetchImageData(for: item), let image = UIImage(data: data) {
                                // Append the image as a new message (or could add to existing message)
                                let imageMsg = ChatMessage(role: .assistant, text: nil, images: [image])
                                await MainActor.run {
                                    self.messages.append(imageMsg)
                                }
                            }
                        }
                    }
                }
            }
            // If there's any text from the assistant, append it as a message
            if !fullText.isEmpty {
                let assistantMsg = ChatMessage(role: .assistant, text: fullText, images: collectedImages.isEmpty ? nil : collectedImages)
                messages.append(assistantMsg)
            }
            // Note: Images, if any, will be appended asynchronously as they are fetched.
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
