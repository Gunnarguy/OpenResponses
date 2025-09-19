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
    // MCP-specific states
    case mcpApprovalRequested
    case mcpProceeding

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
            return "Executing code..."
        case .processingArtifacts:
            return "📄 Processing generated files..."
        case .usingComputer:
            return "🖥️ Using computer..."
        case .runningTool(let name):
            return "Running tool: \(name)..."
        case .generatingImage:
            return "Creating image..."
        case .imageGenerationProgress(let progress):
            return "✨ \(progress)"
        case .imageGenerationCompleting:
            return "🎨 Finalizing image..."
        case .imageReady:
            return "🖼️ Image ready!"
        case .streamingText:
            return "Streaming response..."
        case .finalizing:
            return "Finalizing..."
        case .done:
            return "Done"
        case .mcpApprovalRequested:
            return "🔐 MCP approval required..."
        case .mcpProceeding:
            return "🔗 Continuing with MCP tool..."
        }
    }
}
