import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    
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
                // Image content (if any images in the message)
                if let images = message.images {
                    ForEach(images, id: \.self) { uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
            .background(backgroundColor(for: message.role))
            .foregroundColor(foregroundColor(for: message.role))
            .font(font(for: message.role))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
            
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
            return .body                        // normal font for user and assistant
        case .system:
            return .subheadline.italic()        // smaller italic font for system messages
        }
    }
}
