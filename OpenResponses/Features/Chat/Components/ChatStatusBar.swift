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
            PlaygroundSettingsPanel()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Model Badge
    
    private var modelBadge: some View {
        Menu {
            Picker("Model", selection: Binding(
                get: { viewModel.activePrompt.openAIModel },
                set: { newModel in
                    let oldModel = viewModel.activePrompt.openAIModel
                    var updatedPrompt = viewModel.activePrompt
                    updatedPrompt.openAIModel = newModel
                    _ = viewModel.replaceActivePrompt(with: updatedPrompt, previousModelId: oldModel)
                    viewModel.saveActivePrompt()
                }
            )) {
                Group {
                    Text("gpt-5.6-terra").tag("gpt-5.6-terra")
                    Text("gpt-5.6-sol").tag("gpt-5.6-sol")
                    Text("gpt-5.6-luna").tag("gpt-5.6-luna")
                    Text("gpt-5.6").tag("gpt-5.6")
                }
                Group {
                    Text("gpt-5.5").tag("gpt-5.5")
                    Text("gpt-5.5-pro").tag("gpt-5.5-pro")
                    Text("gpt-5.5-mini").tag("gpt-5.5-mini")
                }
                Group {
                    Text("gpt-5.4").tag("gpt-5.4")
                    Text("gpt-5.4-pro").tag("gpt-5.4-pro")
                    Text("gpt-5.4-mini").tag("gpt-5.4-mini")
                }
                Group {
                    Text("gpt-5").tag("gpt-5")
                    Text("gpt-5-mini").tag("gpt-5-mini")
                    Text("o3").tag("o3")
                    Text("o3-mini").tag("o3-mini")
                    Text("gpt-4o").tag("gpt-4o")
                    Text("gpt-4o-mini").tag("gpt-4o-mini")
                    Text("computer-use-preview").tag("computer-use-preview")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.activePrompt.openAIModel)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modelColor.opacity(0.15))
            .foregroundColor(modelColor)
            .cornerRadius(6)
        }
    }
    
    private var modelColor: Color {
        let model = viewModel.activePrompt.openAIModel
        if model.contains("gpt-5.6") {
            return .teal
        } else if model.contains("gpt-5") {
            return .indigo
        } else if model.contains("o1") || model.contains("o3") {
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
        Image(systemName: "globe")
            .font(.caption2)
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var fileSearchBadge: some View {
        Image(systemName: "doc.text.magnifyingglass")
            .font(.caption2)
            .foregroundColor(.purple)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var codeInterpreterBadge: some View {
        Image(systemName: "chevron.left.forwardslash.chevron.right")
            .font(.caption2)
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var computerUseBadge: some View {
        Image(systemName: "desktopcomputer")
            .font(.caption2)
            .foregroundColor(.indigo)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
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
