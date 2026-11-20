import SwiftUI

struct ToolTimelineView: View {
    let timeline: [ToolExecutionTimeline]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(timeline) { event in
                ToolExecutionCard(event: event)
            }
        }
    }
}

struct ToolExecutionCard: View {
    let event: ToolExecutionTimeline
    @State private var isExpanded = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var iconWidth: CGFloat = 16

    private var icon: some View {
        Image(systemName: iconName)
            .font(.subheadline)
            .foregroundColor(statusColor)
            .accessibilityHidden(true)
    }

    private var name: some View {
        Text(event.displayName)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var status: some View {
        if event.status == .running {
            ProgressView()
                .controlSize(.mini)
        } else {
            // The icon carries the status color; the word stays readable on the fill.
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(Color.accessibleSecondaryText)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.down")
            .font(.caption2)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .accessibilityHidden(true)
    }

    var iconName: String {
        switch event.toolType {
        case "computer": return "display"
        case "mcp_call": return "server.rack"
        case "function_call": return "function"
        case "web_search_call", "web_search": return "globe"
        case "file_search_call", "file_search": return "doc.text.magnifyingglass"
        case "code_interpreter_call", "code_interpreter": return "terminal"
        case "image_generation_call", "image_generation": return "photo"
        case "shell_call", "shell_call_output": return "terminal"
        case "program", "program_output": return "curlybraces"
        case "multi_agent_call", "message": return "person.3"
        case "tool_search_call": return "magnifyingglass"
        case "compaction": return "arrow.down.right.and.arrow.up.left"
        default: return "hammer"
        }
    }

    var statusColor: Color {
        switch event.status {
        case .queued: return .gray
        case .running: return .blue
        case .awaitingApproval: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }

    var statusText: String {
        switch event.status {
        case .queued: return "Queued"
        case .running: return "Running"
        case .awaitingApproval: return "Needs Approval"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        // One line has room for a word or two at these sizes, so the status goes under the
                        // name; side by side they broke into "fet / c…" and "Fai / led" (2026-11-19).
                        VStack(alignment: .leading, spacing: 4) {
                            name
                            // No tool icon here: at these sizes it pushed the status to "Fail / ed", and the
                            // word itself says what the icon's color did.
                            HStack(spacing: 8) {
                                status
                                Spacer(minLength: 0)
                                chevron
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            icon.frame(width: iconWidth, alignment: .center)
                            name
                            Spacer()
                            status
                            chevron
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let args = event.rawArguments, !args.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.toolType == "code_interpreter_call" ? "Code:" : "Arguments:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(args)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    if let screenshot = event.screenshotThumbnail, let uiImage = UIImage(data: screenshot) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                    if let output = event.rawOutputPreview, !output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Output:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            ScrollView(.vertical, showsIndicators: true) {
                                Text(output)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxHeight: 100)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
    }
}
