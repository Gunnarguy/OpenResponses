import Foundation

/// Represents the various states of a streaming response from the API, providing real-time feedback.
enum StreamingStatus: Equatable {
    case idle
    case connecting
    case responseCreated
    case thinking
    case searchingWeb
    case generatingCode
    case runningTool(String) // Associated value for the tool name
    case generatingImage
    case streamingText
    case finalizing
    case done

    /// A user-friendly description of the current status.
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting to OpenAI..."
        case .responseCreated:
            return "Response initiated..."
        case .thinking:
            return "Thinking..."
        case .searchingWeb:
            return "Searching the web..."
        case .generatingCode:
            return "Generating code..."
        case .runningTool(let name):
            return "Running tool: \(name)..."
        case .generatingImage:
            return "Creating image..."
        case .streamingText:
            return "Streaming response..."
        case .finalizing:
            return "Finalizing..."
        case .done:
            return "Done"
        }
    }
}
