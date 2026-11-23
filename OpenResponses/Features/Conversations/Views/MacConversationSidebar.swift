#if os(macOS)
import SwiftUI

/// The Mac window's sidebar: every local conversation, newest first, selectable, with the same on-device search as
/// the iPhone list (by meaning where Apple's language model is available, by words otherwise). Delete is in each
/// row's context menu and on the Delete key. On iPhone and iPad the list is ConversationListView, in a sheet.
struct MacConversationSidebar: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var query = ""
    @State private var hits: [ConversationSearchHit] = []
    @State private var isSearching = false
    @State private var pendingDelete: Conversation?

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var selection: Binding<UUID?> {
        Binding(
            get: { viewModel.activeConversation?.id },
            set: { id in
                guard let id, id != viewModel.activeConversation?.id,
                      let conversation = viewModel.conversations.first(where: { $0.id == id }) else { return }
                viewModel.selectConversation(conversation)
            }
        )
    }

    private var shownConversations: [Conversation] {
        guard !trimmedQuery.isEmpty else { return viewModel.conversations.sorted { $0.lastModified > $1.lastModified } }
        let order = hits.map(\.conversationID)
        return order.compactMap { id in viewModel.conversations.first { $0.id == id } }
    }

    var body: some View {
        List(selection: selection) {
            if !trimmedQuery.isEmpty, shownConversations.isEmpty {
                Text(isSearching ? "Searching…" : "No conversations match.")
                    .foregroundStyle(.secondary)
            }
            ForEach(shownConversations) { conversation in
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .lineLimit(1)
                    if let snippet = hits.first(where: { $0.conversationID == conversation.id })?.snippet, !trimmedQuery.isEmpty {
                        Text(snippet)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(conversation.lastModified.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .tag(conversation.id)
                .contextMenu {
                    Button("Delete Conversation…", role: .destructive) { pendingDelete = conversation }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $query, placement: .sidebar, prompt: "Search conversations")
        .onDeleteCommand {
            if let active = viewModel.activeConversation { pendingDelete = active }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.createNewConversation()
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
                .help("New Chat (⌘N)")
                .disabled(viewModel.isStreaming)
            }
        }
        .confirmationDialog("Delete “\(pendingDelete?.title ?? "")”?",
                            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { viewModel.deleteConversation(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("The conversation is removed from this Mac.")
        }
        .task {
            // Embed new or changed messages, so the first search is quick.
            await ConversationSearchIndex.shared.update(with: searchableMessages())
        }
        .task(id: query) { await runSearch() }
    }

    private func searchableMessages() -> [SearchableMessage] {
        viewModel.conversations.flatMap { conversation in
            [SearchableMessage(conversationID: conversation.id, messageID: conversation.id, text: conversation.title)]
                + conversation.messages.compactMap { message in
                    guard message.role != .system, let text = message.text, !text.isEmpty else { return nil }
                    return SearchableMessage(conversationID: conversation.id, messageID: message.id, text: text)
                }
        }
    }

    private func runSearch() async {
        guard !trimmedQuery.isEmpty else { hits = []; return }
        isSearching = true
        try? await Task.sleep(for: .milliseconds(250)) // Typing pauses before a search runs.
        guard !Task.isCancelled else { return }
        let found = await ConversationSearchIndex.shared.search(trimmedQuery, in: searchableMessages())
        guard !Task.isCancelled else { return }
        hits = found
        isSearching = false
    }
}
#endif
