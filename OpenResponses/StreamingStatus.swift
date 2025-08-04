import Foundation

/// Represents the various states of a streaming response from the API.
enum StreamingStatus: Equatable {
    case idle
    case connecting
    case processing
    case streaming
    case done
    
    /// A user-friendly description of the current status.
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting..."
        case .processing:
            return "Processing..."
        case .streaming:
            return "Streaming..."
        case .done:
            return "Done"
        }
    }
}
