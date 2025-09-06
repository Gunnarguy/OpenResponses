import SwiftUI

/// A view that displays a list of conversations and allows the user to switch between them.
struct ConversationListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
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
