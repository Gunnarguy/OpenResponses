import SwiftUI

/// A view that displays the current status of a streaming response,
/// showing different stages like "Connecting", "Processing", and "Streaming".
struct StreamingStatusView: View {
    let status: StreamingStatus
    
    private var showAnimatedIndicator: Bool {
        switch status {
        case .thinking, .searchingWeb, .generatingCode, .runningTool:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Show an animated indicator for most "in-progress" states
            if showAnimatedIndicator {
                DotLoadingView()
                    .accessibilityHidden(true) // Hide animation from VoiceOver
            } else {
                Image(systemName: icon(for: status))
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true) // Hide decorative icon
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI status: \(status.description)")
        .accessibilityHint("Current activity of the AI assistant")
    }
    
    /// Returns the appropriate system icon name for a given status.
    private func icon(for status: StreamingStatus) -> String {
        switch status {
        case .connecting:
            return "wifi"
        case .responseCreated:
            return "sparkles.rectangle.stack"
        case .thinking:
            return "brain.head.profile"
        case .searchingWeb:
            return "magnifyingglass"
        case .generatingCode:
            return "chevron.left.forward.slash.chevron.right"
        case .runningTool:
            return "gear"
        case .generatingImage:
            return "photo"
        case .streamingText:
            return "text.alignleft"
        case .finalizing:
            return "checkmark.circle"
        case .done:
            return "checkmark.circle.fill"
        default:
            return "hourglass" // For idle
        }
    }
}

/// A view that creates an animated ellipsis (...) effect with a more fluid motion.
struct DotLoadingView: View {
    @State private var animationStates = [false, false, false]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(animationStates[index] ? 1 : 0.3)
                    .offset(y: animationStates[index] ? -3 : 0)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationStates[index]
                    )
            }
        }
        .onAppear {
            // Trigger the animation for all dots
            for i in 0..<animationStates.count {
                animationStates[i] = true
            }
        }
    }
}
