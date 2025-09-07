import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showFilePicker: Bool = false // To present the file importer
    @State private var showImagePicker: Bool = false // To present the image picker
    @State private var showAttachmentMenu: Bool = false // To show attachment options
    @FocusState private var inputFocused: Bool  // Focus state for the input field
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.messages.isEmpty {
                    // Empty state view
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to OpenResponses")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start a conversation with AI using the input field below. Use the attachment button to include files, or access Settings from the toolbar.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !viewModel.isConnectedToNetwork {
                            Label("No internet connection", systemImage: "wifi.slash")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message) {
                                viewModel.deleteMessage(message)
                            }
                            .id(message.id)  // Mark each message for scroll reference
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    // Show streaming status when not idle
                    if viewModel.streamingStatus != .idle && viewModel.streamingStatus != .done {
                        StreamingStatusView(status: viewModel.streamingStatus)
                            .padding(.bottom, 8)
                    }
                    
                    // Input area container
                    VStack(spacing: 0) {
                        // Selected images preview
                        if !viewModel.pendingImageAttachments.isEmpty {
                            SelectedImagesView(
                                images: $viewModel.pendingImageAttachments,
                                detailLevel: $viewModel.selectedImageDetailLevel,
                                onRemove: { index in
                                    viewModel.removeImageAttachment(at: index)
                                }
                            )
                        }
                        
                        // Compact tool indicator above input
                        CompactToolIndicator(
                            modelId: viewModel.activePrompt.openAIModel,
                            prompt: viewModel.activePrompt,
                            isStreaming: viewModel.activePrompt.enableStreaming
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        
                        // Input area at the bottom
                        HStack(alignment: .bottom, spacing: 12) {
                            if viewModel.isStreaming {
                                Button(action: {
                                    viewModel.cancelStreaming()
                                }) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                                .accessibilityConfiguration(
                                    label: "Stop streaming",
                                    hint: AccessibilityUtils.Hint.stopStreaming,
                                    identifier: AccessibilityUtils.Identifier.stopStreamingButton
                                )
                                .padding(.bottom, 8)
                            }
                            
                            ChatInputView(text: $userInput, isFocused: $inputFocused, onSend: {
                                // Send action
                                viewModel.sendUserMessage(userInput)
                                userInput = ""              // Clear the input field
                                inputFocused = false        // Dismiss keyboard
                            }, onAttach: {
                                // Show attachment options menu
                                showAttachmentMenu = true
                            })
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to the bottom whenever a new message is added
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                viewModel.attachFile(from: url)
            case .failure(let error):
                viewModel.handleError(error)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            NavigationView {
                ImagePickerView { selectedImages in
                    if !selectedImages.isEmpty {
                        viewModel.attachImages(selectedImages)
                    }
                }
                .navigationTitle("Select Images")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showImagePicker = false
                        }
                    }
                }
            }
        }
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentMenu, titleVisibility: .visible) {
            Button("📷 Select Images") {
                showImagePicker = true
            }
            Button("📁 Select File") {
                showFilePicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose the type of content to attach to your message.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}
