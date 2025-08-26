import Foundation

/// A container for managing dependencies across the application.
class AppContainer {
    /// The shared singleton instance of the app container.
    static let shared = AppContainer()

    /// The service responsible for handling OpenAI API communications.
    /// It conforms to `OpenAIServiceProtocol` for better testability and modularity.
    let openAIService: OpenAIServiceProtocol

    /// Initializes the container and sets up the dependencies.
    /// For now, it creates a standard `OpenAIService`. In a testing environment,
    /// a mock service could be injected here.
    init() {
        self.openAIService = OpenAIService()
    }

    /// Creates a `ChatViewModel` with its required dependencies.
    /// - Returns: A fully configured `ChatViewModel`.
    func makeChatViewModel() -> ChatViewModel {
        return ChatViewModel(api: openAIService)
    }
}
