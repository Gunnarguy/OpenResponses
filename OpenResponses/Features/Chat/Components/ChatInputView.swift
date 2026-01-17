import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onSelectPhotos: () -> Void // Callback for photo library
    var onSelectFiles: () -> Void // Callback for file picker
    var onTakePhoto: () -> Void // Callback for camera
    var onVectorStoreUpload: (() -> Void)? = nil // Callback for vector store file upload
    var vectorStoreCount: Int = 0 // Number of selected vector stores (0, 1, or 2)
    var fileSearchEnabled: Bool = false // Whether file search is enabled
    var currentModel: String = "gpt-4o"
    
    @ScaledMetric private var buttonPadding: CGFloat = 8
    @ScaledMetric private var containerPadding: CGFloat = 10
    @ScaledMetric private var inputCornerRadius: CGFloat = 20
    @ScaledMetric private var sendButtonSize: CGFloat = 32

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmedText.isEmpty
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Attachment menu button - shows popover near the paperclip
            Menu {
                Button {
                    onTakePhoto()
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                
                Button {
                    onSelectPhotos()
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                
                Button {
                    onSelectFiles()
                } label: {
                    Label("Choose Files", systemImage: "folder")
                }
            } label: {
                Image(systemName: "paperclip")
                    .foregroundColor(.secondary)
                    .padding(buttonPadding)
            }
            .accessibilityConfiguration(
                label: "Attach files or photos",
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
            
            // Audio recording removed
            
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.vertical, 6)
                .accessibilityConfiguration(
                    label: "Message input",
                    hint: AccessibilityUtils.Hint.chatInput,
                    identifier: AccessibilityUtils.Identifier.chatInput
                )
            
            Button(action: {
                onSend()
            }) {
                ZStack {
                    Circle()
                        .fill(canSend ? Color.accentColor : Color.secondary.opacity(0.15))
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSend ? .white : .secondary)
                }
                .frame(width: sendButtonSize, height: sendButtonSize)
            }
            .disabled(!canSend)
            .accessibilityConfiguration(
                label: "Send message",
                hint: AccessibilityUtils.Hint.sendButton,
                identifier: AccessibilityUtils.Identifier.sendButton
            )
        }
        .padding(.all, containerPadding)
        .background(
            RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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
