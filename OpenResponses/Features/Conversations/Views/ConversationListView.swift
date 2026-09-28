import SwiftUI

/// A view that displays a list of conversations and allows the user to switch between them.
struct ConversationListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool

    @State private var selectedTab: Int = 0
    @State private var query = ""
    @State private var hits: [ConversationSearchHit] = []
    @State private var isSearching = false
    @State private var searchesByMeaning = true

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

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

                if selectedTab == 0, !trimmedQuery.isEmpty {
                    searchResults
                } else if selectedTab == 0 {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button(action: {
                                viewModel.selectConversation(conversation)
                                isPresented = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(conversation.title)
                                        .font(.headline)
                                    // A static "5 minutes ago" rather than a ticking timer, which clips and chatters in VoiceOver.
                                    Text(conversation.lastModified.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundStyle(Color.accessibleSecondaryText)
                                }
                            }
                            .foregroundStyle(.primary)
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
                            ForEach(viewModel.remoteConversations.filter { trimmedQuery.isEmpty || ($0.title ?? "").localizedCaseInsensitiveContains(trimmedQuery) }) { summary in
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
            .searchable(text: $query, prompt: "Search conversations")
            .task {
                // Embed new or changed messages while the list is open, so the first search is quick.
                await ConversationSearchIndex.shared.update(with: searchableMessages())
            }
            .task(id: query) { await runSearch() }
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

    private var searchResults: some View {
        List {
            if hits.isEmpty {
                Text(isSearching ? "Searching..." : "No conversations match.")
                    .foregroundStyle(.secondary)
            }
            ForEach(hits) { hit in
                if let conversation = viewModel.conversations.first(where: { $0.id == hit.conversationID }) {
                    Button(action: {
                        viewModel.selectConversation(conversation)
                        isPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .font(.headline)
                            Text(hit.snippet)
                                .font(.subheadline)
                                .foregroundStyle(Color.accessibleSecondaryText)
                                .lineLimit(3)
                            Text(conversation.lastModified.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(Color.accessibleSecondaryText)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            Section {
            } footer: {
                Text(searchesByMeaning
                     ? "Matches by meaning using Apple's on-device language model. Your conversations stay on this device."
                     : "Matches words. Search by meaning needs Apple's language model for your language, which this device does not have. Your conversations stay on this device.")
            }
        }
    }

    /// Titles and message text of every local conversation, copied for the search index.
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
        guard selectedTab == 0, !trimmedQuery.isEmpty else { hits = []; return }
        isSearching = true
        try? await Task.sleep(for: .milliseconds(250)) // Typing pauses before a search runs.
        guard !Task.isCancelled else { return }
        let found = await ConversationSearchIndex.shared.search(trimmedQuery, in: searchableMessages())
        searchesByMeaning = await ConversationSearchIndex.shared.isSemantic
        guard !Task.isCancelled else { return }
        hits = found
        isSearching = false
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let conversation = viewModel.conversations[index]
            viewModel.deleteConversation(conversation)
        }
    }
}
