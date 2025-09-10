import SwiftUI

/// A development/testing view to demonstrate web content rendering
struct WebContentTestView: View {
    @State private var testMessages: [ChatMessage] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(testMessages) { message in
                        MessageBubbleView(message: message) {
                            // Delete message
                            if let index = testMessages.firstIndex(where: { $0.id == message.id }) {
                                testMessages.remove(at: index)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Web Content Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Add Test", systemImage: "plus") {
                        Button("Add gunzino.me") {
                            addTestMessage(url: "https://gunzino.me")
                        }
                        Button("Add Apple.com") {
                            addTestMessage(url: "https://apple.com")
                        }
                        Button("Add GitHub") {
                            addTestMessage(url: "https://github.com")
                        }
                        Button("Add Text with URL") {
                            addMessageWithEmbeddedURL()
                        }
                    }
                }
            }
        }
    }
    
    private func addTestMessage(url: String) {
        guard let url = URL(string: url) else { return }
        
        let message = ChatMessage(
            role: .assistant,
            text: "Here's the website you requested:",
            webURLs: [url]
        )
        testMessages.append(message)
    }
    
    private func addMessageWithEmbeddedURL() {
        let text = "Check out this awesome website: https://gunzino.me - it has some really cool content!"
        let message = ChatMessage.withURLDetection(
            role: .assistant,
            text: text
        )
        testMessages.append(message)
    }
}

#Preview {
    WebContentTestView()
}
