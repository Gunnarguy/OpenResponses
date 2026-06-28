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

    var iconName: String {
        switch event.toolType {
        case "computer": return "display"
        case "mcp_call": return "server.rack"
        case "function_call": return "function"
        case "web_search_call", "web_search": return "globe"
        case "file_search_call", "file_search": return "doc.text.magnifyingglass"
        case "code_interpreter_call", "code_interpreter": return "terminal"
        case "image_generation_call", "image_generation": return "photo"
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
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .foregroundColor(statusColor)
                        .frame(width: 16, alignment: .center)
                    
                    Text(event.toolName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if event.status == .running {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Text(statusText)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
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
                            Text("Arguments:")
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
