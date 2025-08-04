import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var userInput: String = ""
    @State private var showSettings: Bool = false
    @FocusState private var inputFocused: Bool  // Focus state for the input field
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)  // Mark each message for scroll reference
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        // Show streaming status when not idle
                        if viewModel.streamingStatus != .idle && viewModel.streamingStatus != .done {
                            StreamingStatusView(status: viewModel.streamingStatus)
                                .padding(.bottom, 4)
                        }
                        
                        // Input area at the bottom
                        ChatInputView(text: $userInput, isFocused: $inputFocused) {
                            // Send action
                            viewModel.sendUserMessage(userInput)
                            userInput = ""              // Clear the input field
                            inputFocused = false        // Dismiss keyboard
                        }
                    }
                    .padding(.top, 8)
                    .background(.ultraThinMaterial)
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
    }
}
