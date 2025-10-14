import SwiftUI

/// Playground-style compact status bar showing model, tools, and attachments
/// Provides information density without clutter
struct ChatStatusBar: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showingRequestInspector = false
    @State private var showingSettings = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Model badge
            modelBadge
            
            // Active tools
            if viewModel.activePrompt.enableFileSearch {
                fileSearchBadge
            }
            
            if viewModel.activePrompt.enableCodeInterpreter {
                codeInterpreterBadge
            }
            
            if viewModel.activePrompt.enableComputerUse {
                computerUseBadge
            }
            
            Spacer()
            
            // Pending attachments count
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
            
            // Settings button (gear icon)
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
            PlaygroundSettingsPanel()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Model Badge
    
    private var modelBadge: some View {
        Text(viewModel.activePrompt.openAIModel)
            .fontWeight(.medium)
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
    
    private var fileSearchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.caption2)
            Text("file_search")
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
            Text("code_interpreter")
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
            Text("computer")
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
                vm.activePrompt.enableFileSearch = true
                vm.activePrompt.enableCodeInterpreter = true
                vm.pendingFileData = [Data(), Data()]
                return vm
            }())
        
        Spacer()
    }
}
