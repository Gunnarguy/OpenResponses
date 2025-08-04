import SwiftUI

/// A view that displays the current status of a streaming response,
/// showing different stages like "Connecting", "Processing", and "Streaming".
struct StreamingStatusView: View {
    let status: StreamingStatus
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated ellipsis for processing, or a static icon for other statuses
            if status == .processing {
                DotLoadingView()
            } else {
                Image(systemName: icon(for: status))
                    .font(.system(size: 12, weight: .semibold))
            }
            
            // Display the status text from the enum's description
            Text(status.description)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .transition(.opacity.animation(.easeInOut))
    }
    
    /// Returns the appropriate system icon name for a given status.
    private func icon(for status: StreamingStatus) -> String {
        switch status {
        case .connecting:
            return "wifi"
        case .streaming:
            return "sparkles"
        case .done:
            return "checkmark.circle"
        default:
            return "hourglass" // For idle and processing
        }
    }
}

/// A view that creates an animated ellipsis (...) effect.
struct DotLoadingView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            // Three dots that scale up and down with a delay
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 4, height: 4)
                    .scaleEffect(scale)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: scale
                    )
            }
        }
        .onAppear {
            // Trigger the animation when the view appears
            self.scale = 0.5
        }
    }
}
