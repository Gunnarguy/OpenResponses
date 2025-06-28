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
                if let text = message.text {
                    FormattedTextView(text: text, isAssistant: message.role == .assistant)
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

/// A view that formats a text string from the assistant, rendering Markdown and code blocks.
struct FormattedTextView: View {
    let text: String
    let isAssistant: Bool
    
    var body: some View {
        // We will manually handle code blocks for better formatting
        if text.contains("```") {
            // Split text by triple backticks to identify code blocks
            let parts = text.components(separatedBy: "```")
            VStack(alignment: .leading, spacing: 0) {
                // Use ForEach instead of for loop to work with ViewBuilder
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if index % 2 == 0 {
                        // Regular text (outside code blocks) - render as Markdown
                        Text((try? AttributedString(markdown: part, options: .init())) ?? AttributedString(part))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                    } else {
                        // Code block content
                        Text(part)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(white: 0.9))
                            .cornerRadius(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                    }
                }
            }
        } else {
            // No code block present, render the text as attributed Markdown
            Text((try? AttributedString(markdown: text, options: .init())) ?? AttributedString(text))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
