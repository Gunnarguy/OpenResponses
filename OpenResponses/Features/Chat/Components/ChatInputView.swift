import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onAttach: () -> Void // Callback for attachment button
    var onVectorStoreUpload: (() -> Void)? = nil // Callback for vector store file upload
    var vectorStoreCount: Int = 0 // Number of selected vector stores (0, 1, or 2)
    var fileSearchEnabled: Bool = false // Whether file search is enabled
    var onImageGenerate: (() -> Void)? = nil // Optional callback for quick image generation
    var currentModel: String = "gpt-4o"
    
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
            
            // Vector Store file upload button (smart context-aware)
            if let onVectorStoreUpload = onVectorStoreUpload {
                VectorStoreUploadButton(
                    action: onVectorStoreUpload,
                    vectorStoreCount: vectorStoreCount,
                    fileSearchEnabled: fileSearchEnabled
                )
            }
            
            // Quick image generation button (if callback provided)
            if let onImageGenerate = onImageGenerate {
                Button(action: onImageGenerate) {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(.blue)
                        .padding(buttonPadding)
                }
                .accessibilityLabel("Quick image generation")
                .accessibilityHint("Tap to start generating an image")
            }
            
            // Audio recording removed
            
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

// MARK: - Vector Store Upload Button

/// A beautiful, context-aware button for uploading files to vector stores
/// Shows smart badges and hints based on the conversation's vector store state
struct VectorStoreUploadButton: View {
    let action: () -> Void
    let vectorStoreCount: Int
    let fileSearchEnabled: Bool
    
    @ScaledMetric private var buttonPadding: CGFloat = 8
    @State private var isPulsing = false
    
    private var buttonColor: Color {
        if !fileSearchEnabled {
            return .gray.opacity(0.5)
        }
        switch vectorStoreCount {
        case 0: return .orange // Needs setup
        case 1: return .purple // Ready to go
        case 2: return .indigo // Full power
        default: return .purple
        }
    }
    
    private var accessibilityLabel: String {
        switch vectorStoreCount {
        case 0: return "Add files to vector store - No stores selected"
        case 1: return "Add files to vector store - 1 store active"
        case 2: return "Add files to vector store - 2 stores active"
        default: return "Add files to vector store"
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(buttonColor)
                    .padding(buttonPadding)
                    .scaleEffect(isPulsing && fileSearchEnabled && vectorStoreCount == 0 ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                
                // Smart badge showing store count
                if vectorStoreCount > 0 {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text("\(vectorStoreCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 8, y: -4)
                }
            }
        }
        .disabled(!fileSearchEnabled)
        .opacity(fileSearchEnabled ? 1.0 : 0.3)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(fileSearchEnabled ? "Tap to upload files to vector stores for AI search" : "Enable File Search in settings first")
        .onAppear {
            // Start pulsing if file search is on but no stores selected
            if fileSearchEnabled && vectorStoreCount == 0 {
                isPulsing = true
            }
        }
        .onChange(of: fileSearchEnabled) { _, newValue in
            isPulsing = newValue && vectorStoreCount == 0
        }
        .onChange(of: vectorStoreCount) { _, newCount in
            isPulsing = fileSearchEnabled && newCount == 0
        }
    }
}
