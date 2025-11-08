import Foundation

/// Represents the various states of a streaming response from the API, providing real-time feedback.
enum StreamingStatus: Equatable {
    case idle
    case connecting
    case responseCreated
    case thinking
    case searchingWeb
    case generatingCode
    case processingArtifacts // New: when processing code interpreter outputs
    case usingComputer
    case runningTool(String) // Associated value for the tool name
    case generatingImage
    case imageGenerationProgress(String) // For streaming image generation updates
    case imageGenerationCompleting
    case imageReady
    case streamingText
    case finalizing
    case done

    /// A user-friendly description of the current status.
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .connecting:
            return "Establishing OpenAI session"
        case .responseCreated:
            return "Response registered"
        case .thinking:
            return "Analyzing request"
        case .searchingWeb:
            return "Researching web sources"
        case .generatingCode:
            return "Building code solution"
        case .processingArtifacts:
            return "📄 Reviewing generated files"
        case .usingComputer:
            return "🖥️ Controlling computer session"
        case .runningTool(let name):
            return "Executing tool: \(name)"
        case .generatingImage:
            return "Rendering image"
        case .imageGenerationProgress(let progress):
            return "✨ \(progress)"
        case .imageGenerationCompleting:
            return "🎨 Wrapping up image"
        case .imageReady:
            return "🖼️ Image ready"
        case .streamingText:
            return "Delivering response"
        case .finalizing:
            return "Finalizing response"
        case .done:
            return "Complete"
        }
    }
}
