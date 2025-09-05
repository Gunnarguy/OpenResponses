import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showSettings: Bool = false
    @State private var showFilePicker: Bool = false // To present the file importer
    @FocusState private var inputFocused: Bool  // Focus state for the input field
    
    var body: some View {
        NavigationStack {
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
                                MessageBubbleView(message: message)
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
                                    // Attachment action
                                    showFilePicker = true
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
            .navigationTitle("OpenResponses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings button in the navigation bar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityConfiguration(
                        label: "Settings",
                        hint: AccessibilityUtils.Hint.settingsButton,
                        identifier: AccessibilityUtils.Identifier.settingsButton
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                // Settings presented modally in a NavigationStack
                NavigationStack {
                    SettingsView()
                        .environmentObject(viewModel)
                        .navigationBarTitle("Settings", displayMode: .inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showSettings = false
                                }
                            }
                        }
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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}
