import SwiftUI

/// Playground-style compact status bar showing model, tools, and attachments
/// Provides information density without clutter
struct ChatStatusBar: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingRequestInspector = false
    @State private var showingSettings = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Scrollable section for model and active tools
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    modelBadge
                    
                    if viewModel.activePrompt.enableWebSearch {
                        webSearchBadge
                    }
                    
                    if viewModel.activePrompt.enableFileSearch {
                        fileSearchBadge
                    }
                    
                    if viewModel.activePrompt.enableCodeInterpreter {
                        codeInterpreterBadge
                    }
                    
                    if viewModel.activePrompt.enableComputerUse {
                        computerUseBadge
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Right-aligned actions (always visible and uncompressed)
            HStack(spacing: 12) {
                if !viewModel.pendingFileData.isEmpty {
                    attachmentsBadge
                }
                
                if !viewModel.pendingImageAttachments.isEmpty {
                    imagesBadge
                }
                
                // Token usage (if available from last response)
                if let usage = viewModel.lastTokenUsage {
                    tokenBadge(usage: usage)
                }
                
                // Request inspector button (curly braces icon like Playground)
                Button {
                    showingRequestInspector = true
                } label: {
                    Image(systemName: "curlybraces")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .fixedSize()
                
                // Settings button (gear icon)
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .fixedSize()
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .font(.caption)
        .sheet(isPresented: $showingRequestInspector) {
            RequestInspectorView(userMessage: "Preview")
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsHomeView()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Model Badge
    
    private var modelBadge: some View {
        Text(viewModel.activePrompt.openAIModel)
            .fontWeight(.medium)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modelColor.opacity(0.15))
            .foregroundColor(modelColor)
            .cornerRadius(6)
    }
    
    private var modelColor: Color {
        let model = viewModel.activePrompt.openAIModel
        if model.contains("o1") || model.contains("o3") {
            return .purple
        } else if model.contains("4o") {
            return .blue
        } else if model.contains("4") {
            return .green
        } else {
            return .gray
        }
    }
    
    // MARK: - Tool Badges
    
    private var webSearchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "globe")
                .font(.caption2)
            Text("Web Search")
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var fileSearchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.caption2)
            Text("File Search")
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.purple)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var codeInterpreterBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.caption2)
            Text("Code Interpreter")
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var computerUseBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "desktopcomputer")
                .font(.caption2)
            Text("Computer Use")
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.indigo)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Attachment Badges
    
    private var attachmentsBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "paperclip")
                .font(.caption2)
            Text("\(viewModel.pendingFileData.count)")
                .fontWeight(.medium)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var imagesBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.caption2)
            Text("\(viewModel.pendingImageAttachments.count)")
                .fontWeight(.medium)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Token Badge
    
    private func tokenBadge(usage: TokenUsage) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.caption2)
            if let total = usage.total {
                Text("\(total)")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ChatStatusBar()
            .environmentObject({
                let vm = ChatViewModel(api: OpenAIService())
                vm.activePrompt.openAIModel = "gpt-4o"
                vm.activePrompt.enableWebSearch = true
                vm.activePrompt.enableFileSearch = true
                vm.activePrompt.enableCodeInterpreter = true
                vm.pendingFileData = [Data(), Data()]
                return vm
            }())
        
        Spacer()
    }
}
