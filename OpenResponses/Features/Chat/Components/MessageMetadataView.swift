//
//  MessageMetadataView.swift
//  OpenResponses
//
//  Playground-style metadata display for assistant messages.
//  Shows message ID and token breakdown for transparency.
//

import SwiftUI

struct MessageMetadataView: View {
    let message: ChatMessage
    @State private var showCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Message ID (for assistant messages with token usage)
            if message.role == .assistant, message.tokenUsage != nil {
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("message_id:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(message.id.uuidString.prefix(8) + "...")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Button {
                        copyToClipboard(message.id.uuidString, label: "Message ID")
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption2)
                            .foregroundColor(showCopied ? .green : .secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Token usage breakdown (if available)
            if message.role == .assistant, let usage = message.tokenUsage {
                HStack(spacing: 12) {
                    if let input = usage.input {
                        tokenBadge(label: "in", value: input, color: .blue)
                    }
                    if let output = usage.output {
                        tokenBadge(label: "out", value: output, color: .green)
                    } else if let estimated = usage.estimatedOutput {
                        tokenBadge(label: "out (est)", value: estimated, color: .orange)
                    }
                    if let total = usage.total {
                        tokenBadge(label: "total", value: total, color: .purple)
                    }
                }
            }
            
            // File IDs from artifacts (for code interpreter outputs)
            if let artifacts = message.artifacts, !artifacts.isEmpty {
                ForEach(artifacts, id: \.id) { artifact in
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("file_id:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(String(artifact.fileId.prefix(12)) + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Button {
                            copyToClipboard(artifact.fileId, label: "File ID")
                        } label: {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(showCopied ? .green : .secondary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func tokenBadge(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        showCopied = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MessageMetadataView(
            message: ChatMessage(
                id: UUID(),
                role: .assistant,
                text: "Sample response",
                tokenUsage: TokenUsage(
                    estimatedOutput: nil,
                    input: 150,
                    output: 350,
                    total: 500
                )
            )
        )
        
        MessageMetadataView(
            message: ChatMessage(
                id: UUID(),
                role: .assistant,
                text: "Sample with artifacts",
                tokenUsage: TokenUsage(
                    estimatedOutput: nil,
                    input: 200,
                    output: 450,
                    total: 650
                ),
                artifacts: [
                    CodeInterpreterArtifact(
                        id: "artifact_123",
                        fileId: "file-abc123xyz",
                        filename: "output.csv",
                        containerId: "container_456",
                        mimeType: "text/csv",
                        content: .text("Sample CSV data")
                    )
                ]
            )
        )
    }
    .padding()
}
