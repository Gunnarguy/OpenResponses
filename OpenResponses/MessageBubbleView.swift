import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let onDelete: () -> Void
    
    @ScaledMetric private var bubblePadding: CGFloat = 12
    @ScaledMetric private var cornerRadius: CGFloat = 16
    
    var body: some View {
        HStack {
            if message.role == .assistant || message.role == .system {
                // Assistant/system messages aligned to left
                if message.role != .user { Spacer().frame(width: 0) }
            } else {
                Spacer()  // User messages aligned to right
            }
            
            // Bubble content
            VStack(alignment: .leading, spacing: 8) {
                // Text content (formatted for Markdown and code if needed)
                if let text = message.text, !text.isEmpty {
                    FormattedTextView(text: text)
                }
                
                // Tool usage indicator for assistant messages
                if message.role == .assistant {
                    MessageToolIndicator(message: message)
                }
                
                // Show placeholder text for assistant messages with tools but no text
                if message.role == .assistant, 
                   (message.text?.isEmpty ?? true),
                   !(message.toolsUsed?.isEmpty ?? true) {
                    Text("Using tools...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                // Image content (if any images in the message)
                if let images = message.images {
                    ForEach(images, id: \.self) { uiImage in
                        EnhancedImageView(image: uiImage)
                            .padding(.vertical, 4)
                    }
                }
                
                // Web content (if any URLs in the message)
                if let webURLs = message.webURLs {
                    ForEach(webURLs, id: \.self) { url in
                        WebContentView(url: url)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(bubblePadding)
            .background(backgroundColor(for: message.role))
            .foregroundColor(foregroundColor(for: message.role))
            .font(font(for: message.role))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: message))
            .accessibilityHint(accessibilityHint(for: message.role))
            
            if message.role == .user {
                Spacer().frame(width: 0)  // Preserve spacing for user-aligned bubble
            }
        }
        .padding(message.role == .user ? .trailing : .leading, 10)
        .padding(.bottom, 2)
    }
    
    // Helper: choose bubble background color based on the message role
    private func backgroundColor(for role: ChatMessage.Role) -> Color {
        switch role {
        case .user:
            return Color.accentColor.opacity(0.8)  // user bubble in accent color (slightly transparent)
        case .assistant:
            return Color.gray.opacity(0.2)         // assistant bubble in light gray
        case .system:
            return Color.red.opacity(0.1)          // system messages (e.g., errors) with a very light red background
        }
    }
    
    // Helper: choose text color based on role
    private func foregroundColor(for role: ChatMessage.Role) -> Color {
        switch role {
        case .user:
            return Color.white                  // white text on colored bubble
        case .assistant:
            return Color.primary                // default text color for assistant
        case .system:
            return Color.red                    // system message text in red for emphasis
        }
    }
    
    // Helper: choose font style based on role
    private func font(for role: ChatMessage.Role) -> Font {
        switch role {
        case .user, .assistant:
            return .body                        // normal font for user and assistant - supports Dynamic Type
        case .system:
            return .subheadline.italic()        // smaller italic font for system messages - supports Dynamic Type
        }
    }
    
    // Helper: create accessibility label for message
    private func accessibilityLabel(for message: ChatMessage) -> String {
        let roleText: String
        switch message.role {
        case .user:
            roleText = "Your message"
        case .assistant:
            roleText = "AI response"
        case .system:
            roleText = "System message"
        }
        
        let messageText = message.text ?? "Image content"
        return "\(roleText): \(messageText)"
    }
    
    // Helper: create accessibility hint for message role
    private func accessibilityHint(for role: ChatMessage.Role) -> String {
        switch role {
        case .user:
            return "Message you sent to the AI"
        case .assistant:
            return "Response from the AI assistant"
        case .system:
            return "System notification or error message"
        }
    }
}
