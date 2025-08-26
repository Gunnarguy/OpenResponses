import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onAttach: () -> Void // Callback for attachment button
    
    @ScaledMetric private var minTextHeight: CGFloat = 40
    @ScaledMetric private var maxTextHeight: CGFloat = 100
    @ScaledMetric private var buttonPadding: CGFloat = 8
    @ScaledMetric private var containerPadding: CGFloat = 10
    
    var body: some View {
        HStack(alignment: .center) {
            // Attachment button
            Button(action: {
                onAttach()
            }) {
                Image(systemName: "paperclip")
                    .foregroundColor(.gray)
                    .padding(buttonPadding)
            }
            .accessibilityConfiguration(
                label: "Attach files",
                hint: AccessibilityUtils.Hint.fileAttachButton
            )
            
            ZStack(alignment: .leading) {
                // Placeholder text
                if text.isEmpty {
                    Text("Message")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                // Multi-line text editor for user input
                TextEditor(text: $text)
                    .frame(minHeight: minTextHeight, maxHeight: maxTextHeight)  // allow TextEditor to grow dynamically
                    .padding(5)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                    .focused(isFocused)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    .accessibilityConfiguration(
                        label: "Message input",
                        hint: AccessibilityUtils.Hint.chatInput,
                        identifier: AccessibilityUtils.Identifier.chatInput
                    )
            }
            
            Button(action: {
                onSend()
            }) {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Disabled state (no text to send)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(buttonPadding)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityConfiguration(
                label: "Send message",
                hint: AccessibilityUtils.Hint.sendButton,
                identifier: AccessibilityUtils.Identifier.sendButton
            )
        }
        .padding(.all, containerPadding)
    }
}
