import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let onDelete: () -> Void
    var isStreaming: Bool = false
    var viewModel: ChatViewModel? = nil

    @ScaledMetric private var bubblePadding: CGFloat = 12
    @ScaledMetric private var cornerRadius: CGFloat = 16

    @State private var showCopied: Bool = false

    var body: some View {
        HStack {
            if message.role == .assistant || message.role == .system {
                // Assistant/system messages aligned to left
                if message.role != .user { Spacer().frame(width: 0) }
            } else {
                Spacer()  // User messages aligned to right
            }

            // Bubble content
            VStack(alignment: .leading, spacing: 8) {
                // Text content (formatted for Markdown and code if needed)
                if let text = message.text, !text.isEmpty {
                    ZStack(alignment: .bottomLeading) {
                        FormattedTextView(text: text)
                        if isStreaming && message.role == .assistant {
                            HStack(spacing: 6) {
                                TypingCursor()
                                if let est = message.tokenUsage?.estimatedOutput, est > 0 {
                                    Text("\(est)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .offset(x: 2, y: 2)
                        }
                    }
                } else if isStreaming && message.role == .assistant {
                    // Show a typing cursor even before first text arrives
                    TypingCursor()
                        .padding(.vertical, 4)
                }

                // Quick actions (copy/share/etc.)
                if let text = message.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    bubbleQuickActions(text: text)
                        .padding(.top, 2)
                }

                // Live/final token usage indicator for assistant messages
                if message.role == .assistant, let usage = message.tokenUsage {
                    TokenUsageCaption(usage: usage)
                        .padding(.top, 2)
                }

                if message.role == .assistant,
                   let reasoning = message.reasoning,
                   !reasoning.isEmpty {
                    AssistantReasoningView(reasoning: reasoning)
                }

                // Tool usage indicator for assistant messages
                if message.role == .assistant {
                    MessageToolIndicator(message: message)
                }

                // Playground-style metadata (response_id, token breakdown, file_ids)
                if message.role == .assistant {
                    MessageMetadataView(message: message)
                        .padding(.top, 4)
                }

                // Show placeholder text for assistant messages with tools but no text
                if message.role == .assistant,
                   (message.text?.isEmpty ?? true),
                   !(message.toolsUsed?.isEmpty ?? true) {
                    Text("Using tools...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }

                // Image content (if any images in the message)
                if let images = message.images, !images.isEmpty {
                    // Iterate by index to avoid relying on UIImage being Hashable/Identifiable
                    ForEach(images.indices, id: \.self) { idx in
                        EnhancedImageView(image: images[idx])
                            .padding(.vertical, 4)
                    }
                }

                // Code interpreter artifacts (files, logs, data outputs)
                if let artifacts = message.artifacts, !artifacts.isEmpty {
                    ArtifactsView(artifacts: artifacts)
                        .padding(.vertical, 4)
                }

                // MCP approval requests
                if let approvalRequests = message.mcpApprovalRequests, !approvalRequests.isEmpty {
                    ForEach(approvalRequests) { approval in
                        MCPApprovalView(
                            approval: approval,
                            onApprove: { reason in
                                // Get viewModel from environment
                                if let viewModel = viewModel {
                                    viewModel.respondToMCPApproval(
                                        approvalRequestId: approval.id,
                                        approve: true,
                                        reason: reason,
                                        messageId: message.id
                                    )
                                }
                            },
                            onReject: { reason in
                                if let viewModel = viewModel {
                                    viewModel.respondToMCPApproval(
                                        approvalRequestId: approval.id,
                                        approve: false,
                                        reason: reason,
                                        messageId: message.id
                                    )
                                }
                            }
                        )
                        .padding(.vertical, 4)
                    }
                }

                // Web content (if any URLs in the message)
                if let webURLs = message.webURLs {
                    ForEach(webURLs, id: \.self) { url in
                        WebContentView(url: url)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(bubblePadding)
            .background(backgroundColor(for: message.role))
            .foregroundColor(foregroundColor(for: message.role))
            .font(font(for: message.role))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
            .contextMenu {
                if let text = message.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        copyToClipboard(text)
                    } label: {
                        Label {
                            Text(showCopied ? "Copied" : "Copy")
                        } icon: {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        }
                    }

                    ShareLink(item: text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if message.role == .assistant {
                        Button {
                            copyToClipboard(message.id.uuidString)
                        } label: {
                            Label("Copy Message ID", systemImage: "number")
                        }
                    }

                    Divider()
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: message))
            .accessibilityHint(accessibilityHint(for: message.role))

            if message.role == .user {
                Spacer().frame(width: 0)  // Preserve spacing for user-aligned bubble
            }
        }
        .padding(message.role == .user ? .trailing : .leading, 10)
        .padding(.bottom, 2)
        .animation(.easeInOut(duration: 0.16), value: message.text)
    }

    // MARK: - Bubble Quick Actions

    @ViewBuilder
    private func bubbleQuickActions(text: String) -> some View {
        HStack(spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 0)
            }

            Button {
                copyToClipboard(text)
            } label: {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(showCopied ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityLabel(Text(showCopied ? "Copied" : "Copy message"))
            }
            .buttonStyle(.plain)

            ShareLink(item: text) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityLabel(Text("Share message"))
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    copyToClipboard(text)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                ShareLink(item: text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                if message.role == .assistant {
                    Button {
                        copyToClipboard(message.id.uuidString)
                    } label: {
                        Label("Copy Message ID", systemImage: "number")
                    }
                }

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityLabel(Text("More actions"))
            }
            .buttonStyle(.plain)

            if message.role != .user {
                Spacer(minLength: 0)
            }
        }
        .padding(.top, 2)
    }

    // Helper: choose bubble background color based on the message role
    private func backgroundColor(for role: ChatMessage.Role) -> Color {
        switch role {
        case .user:
            return Color.accentColor.opacity(0.8)  // user bubble in accent color (slightly transparent)
        case .assistant:
            return Color.gray.opacity(0.2)         // assistant bubble in light gray
        case .system:
            return Color.red.opacity(0.1)          // system messages (e.g., errors) with a very light red background
        }
    }

    // Helper: choose text color based on role
    private func foregroundColor(for role: ChatMessage.Role) -> Color {
        switch role {
        case .user:
            return Color.white                  // white text on colored bubble
        case .assistant:
            return Color.primary                // default text color for assistant
        case .system:
            return Color.red                    // system message text in red for emphasis
        }
    }

    // Helper: choose font style based on role
    private func font(for role: ChatMessage.Role) -> Font {
        switch role {
        case .user, .assistant:
            return .body                        // normal font for user and assistant - supports Dynamic Type
        case .system:
            return .subheadline.italic()        // smaller italic font for system messages - supports Dynamic Type
        }
    }

    // Helper: create accessibility label for message
    private func accessibilityLabel(for message: ChatMessage) -> String {
        let roleText: String
        switch message.role {
        case .user:
            roleText = "Your message"
        case .assistant:
            roleText = "AI response"
        case .system:
            roleText = "System message"
        }

        let messageText = message.text ?? "Image content"
        return "\(roleText): \(messageText)"
    }

    // Helper: create accessibility hint for message role
    private func accessibilityHint(for role: ChatMessage.Role) -> String {
        switch role {
        case .user:
            return "Message you sent to the AI"
        case .assistant:
            return "Response from the AI assistant"
        case .system:
            return "System notification or error message"
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopied = false
        }
    }
}

/// Small caption line that shows tokens: in/out/total, with live estimate when streaming
private struct TokenUsageCaption: View {
    let usage: TokenUsage
    var body: some View {
        let parts: [String] = {
            var p: [String] = []
            if let inTok = usage.input { p.append("in: \(inTok)") }
            if let outTok = usage.output { p.append("out: \(outTok)") }
            else if let est = usage.estimatedOutput { p.append("out (est): \(est)") }
            if let total = usage.total { p.append("total: \(total)") }
            return p
        }()
        return Text(parts.isEmpty ? "" : parts.joined(separator: "  •  "))
            .font(.caption2)
            .foregroundColor(.secondary)
            .accessibilityLabel("Token usage")
    }
}

/// Small blinking cursor to indicate the assistant is still streaming
private struct TypingCursor: View {
    @State private var visible: Bool = true
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .frame(width: 2, height: 16)
            .opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: visible)
            .onAppear { visible = true }
    }
}

/// Collapsible stack that surfaces reasoning traces from reasoning-capable models.
private struct AssistantReasoningView: View {
    let reasoning: [ReasoningTrace]
    @State private var isExpanded: Bool

    init(reasoning: [ReasoningTrace]) {
        self.reasoning = reasoning
        let shouldExpand = reasoning.count <= 2 || reasoning.contains { $0.isSummary }
        _isExpanded = State(initialValue: shouldExpand)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(reasoning) { trace in
                    VStack(alignment: .leading, spacing: 4) {
                        if trace.isSummary {
                            Text("Summary")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        } else if let level = trace.level {
                            Text("Step \(level)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }

                        Text(trace.text)
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Assistant Thinking (\(reasoning.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(isExpanded ? "Hide" : "Show")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
        .padding(.top, 2)
    }
}
