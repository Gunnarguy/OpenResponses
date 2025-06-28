import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                // Placeholder text
                if text.isEmpty {
                    Text("Message")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                // Multi-line text editor for user input
                TextEditor(text: $text)
                    .frame(minHeight: 40, maxHeight: 100)  // allow TextEditor to grow up to 100pt
                    .padding(5)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                    .focused(isFocused)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
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
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.all, 10)
    }
}
