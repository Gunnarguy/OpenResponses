import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    // Observe activity visibility to update the Details panel in real-time
    @ObservedObject private var activityVisibility = ActivityVisibility.shared
    @State private var userInput: String = ""
    @State private var showFilePicker: Bool = false // To present the file importer
    @State private var showImagePicker: Bool = false // To present the image picker
    @State private var showAttachmentMenu: Bool = false // To show attachment options
    @State private var showVectorStoreUpload: Bool = false // To show vector store upload flow
    @State private var uploadSuccessMessage: String? = nil // Success message after upload
    @FocusState private var inputFocused: Bool  // Focus state for the input field
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView { mainScrollContent }
            .safeAreaInset(edge: .bottom) {
                bottomInset
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to the bottom whenever a new message is added
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            // Also scroll when the last message’s images change, since we add screenshots without changing count
            .onChange(of: viewModel.messages.last?.images?.count ?? 0) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            // Scroll smoothly as the streaming assistant message grows in text length
            .onChange(of: viewModel.messages.last?.text?.count ?? 0) { _, _ in
                if let last = viewModel.messages.last, last.role == .assistant {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker(
                selectedFileData: $viewModel.pendingFileData,
                selectedFilenames: $viewModel.pendingFileNames
            )
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
        // Safety approval sheet for computer-use actions
        .sheet(
            isPresented: Binding(
                get: { viewModel.pendingSafetyApproval != nil },
                set: { newValue in if !newValue { viewModel.pendingSafetyApproval = nil } }
            )
        ) {
            SafetyApprovalSheet()
                .environmentObject(viewModel)
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
        .sheet(isPresented: $showVectorStoreUpload) {
            VectorStoreSmartUploadView(onUploadComplete: { successCount, failedCount in
                if successCount > 0 {
                    uploadSuccessMessage = "✅ Successfully uploaded \(successCount) file\(successCount == 1 ? "" : "s") to vector store\(failedCount > 0 ? " (\(failedCount) failed)" : "")"
                }
            })
                .environmentObject(viewModel)
        }
        .alert("Upload Complete", isPresented: .constant(uploadSuccessMessage != nil)) {
            Button("OK") {
                uploadSuccessMessage = nil
            }
        } message: {
            Text(uploadSuccessMessage ?? "")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
    
    // MARK: - Subviews split for compiler performance

    @ViewBuilder
    private var mainScrollContent: some View {
        if viewModel.messages.isEmpty {
            emptyStateView
        } else {
            messagesList
        }
    }

    @ViewBuilder
    private var bottomInset: some View {
        VStack(spacing: 0) {
            statusAndTokensRow
            inputArea
        }
    }

    @ViewBuilder
    private var statusAndTokensRow: some View {
        // Status + cumulative tokens row (always shows tokens; status appears when active)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if viewModel.streamingStatus != .idle && viewModel.streamingStatus != .done {
                    StreamingStatusView(status: viewModel.streamingStatus)
                }
                ConversationTokenCounterView(usage: viewModel.cumulativeTokenUsage)
                Spacer(minLength: 0)
                // Toggle to show/hide activity details
                ActivityToggleButton()
            }
            // Inline activity details when enabled
            if activityVisibility.isVisible {
                ActivityFeedView(lines: viewModel.activityLines)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 0) {
            selectedAttachmentPreviews

            // Compact tool indicator above input
            CompactToolIndicator(
                modelId: viewModel.activePrompt.openAIModel,
                prompt: viewModel.activePrompt,
                isStreaming: viewModel.activePrompt.enableStreaming
            )
            .padding(.horizontal)
            .padding(.bottom, 4)

            inputRow

            imageSuggestions
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var selectedAttachmentPreviews: some View {
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

        // Selected files preview
        if !viewModel.pendingFileNames.isEmpty {
            SelectedFilesView(
                fileNames: viewModel.pendingFileNames,
                onRemove: { index in
                    viewModel.removeFileAttachment(at: index)
                }
            )
        }
    }

    @ViewBuilder
    private var inputRow: some View {
        // Input area at the bottom
        HStack(alignment: .bottom, spacing: 12) {
            if viewModel.isStreaming {
                Button(action: { viewModel.cancelStreaming() }) {
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

            ChatInputView(
                text: $userInput,
                isFocused: $inputFocused,
                onSend: {
                    // Send action
                    viewModel.sendUserMessage(userInput)
                    userInput = ""              // Clear the input field
                    inputFocused = false        // Dismiss keyboard
                },
                onAttach: { showAttachmentMenu = true },
                onVectorStoreUpload: { showVectorStoreUpload = true },
                vectorStoreCount: viewModel.activePrompt.selectedVectorStoreIds?.split(separator: ",").count ?? 0,
                fileSearchEnabled: viewModel.activePrompt.enableFileSearch,
                onImageGenerate: {
                    // Quick image generation
                    userInput = "Generate an image of "
                    inputFocused = true
                },
                currentModel: viewModel.currentModel()
            )
            .disabled(viewModel.isAwaitingComputerOutput)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var imageSuggestions: some View {
        // Show image suggestions when user types image-related keywords and input is focused
        if inputFocused && shouldShowImageSuggestions(for: userInput) {
            ImageSuggestionView(inputText: $userInput) { suggestion in
                userInput = suggestion
                // Auto-send the suggestion or let user edit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    inputFocused = true
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
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
    }

    @ViewBuilder
    private var messagesList: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.messages) { message in
                let isCurrentStreamingAssistant: Bool = viewModel.isStreamingAssistantMessage(message)
                MessageBubbleView(message: message, onDelete: {
                    viewModel.deleteMessage(message)
                }, isStreaming: isCurrentStreamingAssistant)
                .id(message.id)  // Mark each message for scroll reference
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    /// Determines if image suggestions should be shown based on user input
    private func shouldShowImageSuggestions(for input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let imageKeywords = ["image", "picture", "photo", "draw", "create", "generate", "make"]
        
        // Only show suggestions if input contains image-related keywords
        return imageKeywords.contains { keyword in
            trimmed.contains(keyword)
        }
    }
}
