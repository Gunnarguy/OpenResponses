import SwiftUI

/// A view that displays a list of conversations and allows the user to switch between them.
struct ConversationListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool

    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Source", selection: $selectedTab) {
                    Text("Local").tag(0)
                    Text("Remote").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 1 {
                        viewModel.fetchRemoteConversations()
                    }
                }

                if selectedTab == 0 {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button(action: {
                                viewModel.selectConversation(conversation)
                                isPresented = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(conversation.title)
                                        .font(.headline)
                                    Text(conversation.lastModified, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                } else {
                    if viewModel.isFetchingRemoteConversations {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.remoteConversations.isEmpty {
                        Text("No remote conversations found.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.remoteConversations) { summary in
                                Button(action: {
                                    viewModel.fetchAndSwitchToRemoteConversation(summary)
                                    isPresented = false
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(summary.title ?? "Untitled Conversation")
                                            .font(.headline)
                                        if let updatedAt = summary.updatedAt {
                                            let date = Date(timeIntervalSince1970: TimeInterval(updatedAt))
                                            Text(date, style: .relative)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.createNewConversation()
                        isPresented = false
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let conversation = viewModel.conversations[index]
            viewModel.deleteConversation(conversation)
        }
    }
}
