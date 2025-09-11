import SwiftUI

/// Visual component showing model compatibility and tool usage status
struct ModelCompatibilityView: View {
    let modelId: String
    let prompt: Prompt
    let isStreaming: Bool
    @State private var showDetails = false
    
    private let compatibilityService = ModelCompatibilityService.shared
    
    init(modelId: String, prompt: Prompt, isStreaming: Bool) {
        self.modelId = modelId
        self.prompt = prompt
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with model info
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("Model: \(modelId)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick overview
            ModelOverviewCard(modelId: modelId, isStreaming: isStreaming)
            
            // Tools status
            ToolsStatusGrid(modelId: modelId, prompt: prompt, isStreaming: isStreaming)
            
            if showDetails {
                // Detailed parameter compatibility
                ParameterCompatibilitySection(modelId: modelId)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Quick overview card showing model category and key capabilities
struct ModelOverviewCard: View {
    let modelId: String
    let isStreaming: Bool
    
    private let compatibilityService = ModelCompatibilityService.shared
    
    init(modelId: String, isStreaming: Bool) {
        self.modelId = modelId
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Model category icon
            VStack {
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                Text(categoryName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Key capabilities
            VStack(alignment: .leading, spacing: 4) {
                if let capabilities = compatibilityService.getCapabilities(for: modelId) {
                    HStack {
                        Image(systemName: capabilities.supportsStreaming ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(capabilities.supportsStreaming ? .green : .red)
                        Text("Streaming")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: capabilities.supportsReasoningEffort ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(capabilities.supportsReasoningEffort ? .green : .red)
                        Text("Reasoning")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: capabilities.supportsTemperature ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(capabilities.supportsTemperature ? .green : .red)
                        Text("Temperature")
                            .font(.caption)
                    }
                } else {
                    Text("Unknown model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        guard let capabilities = compatibilityService.getCapabilities(for: modelId) else {
            return "questionmark.circle"
        }
        
        switch capabilities.category {
        case .reasoning:
            return "brain.head.profile"
        case .standard:
            return "message.circle"
        case .latest:
            return "sparkles"
        case .preview:
            return "flask"
        }
    }
    
    private var categoryColor: Color {
        guard let capabilities = compatibilityService.getCapabilities(for: modelId) else {
            return .gray
        }
        
        switch capabilities.category {
        case .reasoning:
            return .purple
        case .standard:
            return .blue
        case .latest:
            return .orange
        case .preview:
            return .pink
        }
    }
    
    private var categoryName: String {
        guard let capabilities = compatibilityService.getCapabilities(for: modelId) else {
            return "Unknown"
        }
        
        switch capabilities.category {
        case .reasoning:
            return "Reasoning"
        case .standard:
            return "Standard"
        case .latest:
            return "Latest"
        case .preview:
            return "Preview"
        }
    }
}

/// Grid showing the status of all tools
struct ToolsStatusGrid: View {
    let modelId: String
    let prompt: Prompt
    let isStreaming: Bool
    
    private let compatibilityService = ModelCompatibilityService.shared
    
    init(modelId: String, prompt: Prompt, isStreaming: Bool) {
        self.modelId = modelId
        self.prompt = prompt
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tools")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(compatibilityService.getCompatibleTools(for: modelId, prompt: prompt, isStreaming: isStreaming), id: \.name) { tool in
                    ToolStatusCard(tool: tool)
                }
            }
        }
    }
}

/// Individual tool status card
struct ToolStatusCard: View {
    let tool: ModelCompatibilityService.ToolCompatibility
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: toolIcon)
                    .foregroundColor(statusColor)
                    .font(.caption)
                
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            // Restrictions if any
            if !tool.restrictions.isEmpty {
                ForEach(tool.restrictions, id: \.self) { restriction in
                    Text(restriction)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            // Status text
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var toolIcon: String {
        switch tool.name {
        case "web_search_preview":
            return "globe"
        case "code_interpreter":
            return "terminal"
        case "image_generation":
            return "photo"
        case "file_search":
            return "doc.text.magnifyingglass"
        case "computer_use_preview":
            return "display"
    // calculator removed
        default:
            return "wrench.and.screwdriver"
        }
    }
    
    private var displayName: String {
        switch tool.name {
        case "web_search_preview":
            return "Web Search"
        case "code_interpreter":
            return "Code Interpreter"
        case "image_generation":
            return "Image Generation"
        case "file_search":
            return "File Search"
        case "computer_use_preview":
            return "Computer Use"
    // calculator removed
        default:
            return tool.name.capitalized
        }
    }
    
    private var statusColor: Color {
        if !tool.isSupported {
            return .red
        } else if tool.isUsed {
            return .green
        } else if tool.isEnabled {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if tool.isUsed {
            return .green.opacity(0.1)
        } else if tool.isEnabled && !tool.isSupported {
            return .red.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if tool.isUsed {
            return .green.opacity(0.3)
        } else if tool.isEnabled && !tool.isSupported {
            return .red.opacity(0.3)
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var statusText: String {
        if !tool.isSupported {
            return "Not supported"
        } else if tool.isUsed {
            return "Active"
        } else if tool.isEnabled {
            return "Enabled but unused"
        } else {
            return "Available"
        }
    }
}

/// Detailed parameter compatibility section
struct ParameterCompatibilitySection: View {
    let modelId: String
    
    private let compatibilityService = ModelCompatibilityService.shared
    
    init(modelId: String) {
        self.modelId = modelId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parameters")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 6) {
                ForEach(compatibilityService.getParameterCompatibility(for: modelId), id: \.name) { parameter in
                    ParameterRow(parameter: parameter)
                }
            }
        }
        .padding(.top, 8)
    }
}

/// Individual parameter row
struct ParameterRow: View {
    let parameter: ModelCompatibilityService.ParameterCompatibility
    
    var body: some View {
        HStack {
            Image(systemName: parameter.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(parameter.isSupported ? .green : .red)
                .font(.caption)
            
            Text(parameter.name)
                .font(.caption)
                .fontWeight(.medium)
            
            if let defaultValue = parameter.defaultValue {
                Text("(\(String(describing: defaultValue)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !parameter.restrictions.isEmpty {
                Text(parameter.restrictions.first ?? "")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

/// Compact tool indicator for chat interface
struct CompactToolIndicator: View {
    let modelId: String
    let prompt: Prompt
    let isStreaming: Bool
    
    private let compatibilityService = ModelCompatibilityService.shared
    
    init(modelId: String, prompt: Prompt, isStreaming: Bool) {
        self.modelId = modelId
        self.prompt = prompt
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        let activeTools = compatibilityService.getCompatibleTools(for: modelId, prompt: prompt, isStreaming: isStreaming)
            .filter { $0.isUsed }
        
        if !activeTools.isEmpty {
            HStack(spacing: 4) {
                ForEach(activeTools, id: \.name) { tool in
                    Image(systemName: toolIcon(for: tool.name))
                        .foregroundColor(.green)
                        .font(.caption2)
                }
                
                Text("\(activeTools.count) active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func toolIcon(for toolName: String) -> String {
        switch toolName {
        case "web_search_preview": return "globe"
        case "code_interpreter": return "terminal"
        case "image_generation": return "photo"
        case "file_search": return "doc.text.magnifyingglass"
        case "computer": return "display"
        default: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Preview

struct ModelCompatibilityView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePrompt = Prompt.defaultPrompt()
        
        VStack(spacing: 16) {
            ModelCompatibilityView(
                modelId: "gpt-4o",
                prompt: samplePrompt,
                isStreaming: false
            )
            
            ModelCompatibilityView(
                modelId: "o3",
                prompt: samplePrompt,
                isStreaming: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

/// Tool indicator for individual messages showing what tools were used
struct MessageToolIndicator: View {
    let message: ChatMessage
    @EnvironmentObject private var viewModel: ChatViewModel
    
    var body: some View {
        // Use actual tools tracked in the message, fallback to text-based detection
        let toolsUsed = message.toolsUsed ?? detectToolsUsed(in: message.text ?? "")
        
        if !toolsUsed.isEmpty {
            HStack(spacing: 6) {
                ForEach(toolsUsed, id: \.self) { tool in
                    HStack(spacing: 4) {
                        Image(systemName: toolIcon(for: tool))
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(toolDisplayName(for: tool))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
    }
    
    /// Detect which tools were used based on message content patterns
    private func detectToolsUsed(in text: String) -> [String] {
        var toolsUsed: [String] = []
        
        // Check for web search patterns
        if text.contains("searched") || text.contains("found") || text.contains("according to") {
            toolsUsed.append("web_search")
        }
        
        // Check for code execution patterns
        if text.contains("```python") || text.contains("executed") || text.contains("calculation") {
            toolsUsed.append("code_interpreter")
        }
        
        // Check for file search patterns
        if text.contains("document") || text.contains("file") || text.contains("based on the uploaded") {
            toolsUsed.append("file_search")
        }
        
        // Check for image generation patterns
        if text.contains("generated") && text.contains("image") {
            toolsUsed.append("image_generation")
        }
        
        // Check for computer use patterns
        if text.contains("computer") || text.contains("screen") || text.contains("clicked") || text.contains("typed") {
            toolsUsed.append("computer")
        }
        
        return toolsUsed
    }
    
    private func toolIcon(for tool: String) -> String {
        switch tool {
        case "web_search": return "globe"
        case "code_interpreter": return "terminal"
        case "file_search": return "doc.text.magnifyingglass"
        case "image_generation": return "photo"
        case "computer": return "display"
        default: return "wrench.and.screwdriver"
        }
    }
    
    private func toolDisplayName(for tool: String) -> String {
        switch tool {
        case "web_search": return "Web"
        case "code_interpreter": return "Code"
        case "file_search": return "Files"
        case "image_generation": return "Image"
        case "computer": return "Computer"
        default: return "Tool"
        }
    }
}
