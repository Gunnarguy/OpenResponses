import SwiftUI

/// Playground-style request inspector showing the actual JSON payload
/// Lets power users see exactly what's being sent to the OpenAI API
struct RequestInspectorView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    let userMessage: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Info banner
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Request Preview")
                                .font(.headline)
                            Text("This is the actual JSON payload that will be sent to the OpenAI Responses API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // JSON payload
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Request Body")
                                .font(.headline)
                            Spacer()
                            Button {
                                copyToClipboard()
                            } label: {
                                Label(copiedToClipboard ? "Copied!" : "Copy", systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Text(formattedJSON)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    // Request details
                    requestDetails
                }
                .padding()
            }
            .navigationTitle("Request Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Request Details
    
    private var requestDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request Details")
                .font(.headline)
            
            DetailRow(label: "Endpoint", value: "POST /v1/responses")
            DetailRow(label: "Model", value: viewModel.activePrompt.openAIModel)
            DetailRow(label: "Streaming", value: viewModel.activePrompt.enableStreaming ? "Enabled" : "Disabled")
            
            if viewModel.activePrompt.enableFileSearch {
                DetailRow(label: "file_search", value: "Enabled")
                if let storeIds = viewModel.activePrompt.selectedVectorStoreIds {
                    DetailRow(label: "Vector Stores", value: storeIds.split(separator: ",").count.description)
                }
            }
            
            if viewModel.activePrompt.enableCodeInterpreter {
                DetailRow(label: "code_interpreter", value: "Enabled")
            }
            
            if viewModel.activePrompt.enableComputerUse {
                DetailRow(label: "computer", value: "Enabled")
            }
            
            if !viewModel.pendingFileData.isEmpty {
                DetailRow(label: "File Attachments", value: "\(viewModel.pendingFileData.count)")
            }
            
            if !viewModel.pendingImageAttachments.isEmpty {
                DetailRow(label: "Image Attachments", value: "\(viewModel.pendingImageAttachments.count)")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - JSON Generation
    
    private var formattedJSON: String {
        let requestObject = buildPreviewRequest()
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestObject, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    private func buildPreviewRequest() -> [String: Any] {
        var request: [String: Any] = [
            "model": viewModel.activePrompt.openAIModel
        ]
        
        // Input array
        var inputArray: [[String: Any]] = []
        
        // Add developer instructions if present
        if !viewModel.activePrompt.developerInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputArray.append([
                "role": "developer",
                "content": viewModel.activePrompt.developerInstructions
            ])
        }
        
        // Add user message
        var userContent: [[String: Any]] = [
            ["type": "input_text", "text": userMessage]
        ]
        
        // Add file attachments
        for fileName in viewModel.pendingFileNames {
            userContent.append([
                "type": "input_file",
                "file_data": "<base64_encoded_data>",
                "filename": fileName
            ])
        }
        
        // Add image attachments (as base64 for preview)
        for (index, _) in viewModel.pendingImageAttachments.enumerated() {
            userContent.append([
                "type": "input_image",
                "image_data": "<base64_encoded_image_\(index + 1)>",
                "detail": "auto"
            ])
        }
        
        inputArray.append([
            "role": "user",
            "content": userContent
        ])
        
        request["input"] = inputArray
        
        // Instructions
        if !viewModel.activePrompt.systemInstructions.isEmpty {
            request["instructions"] = viewModel.activePrompt.systemInstructions
        }
        
        // Tools
        var tools: [[String: Any]] = []
        
        if viewModel.activePrompt.enableFileSearch {
            var fileSearchTool: [String: Any] = ["type": "file_search"]
            if let storeIds = viewModel.activePrompt.selectedVectorStoreIds {
                fileSearchTool["vector_store_ids"] = storeIds.split(separator: ",").map { String($0) }
            }
            tools.append(fileSearchTool)
        }
        
        if viewModel.activePrompt.enableCodeInterpreter {
            tools.append(["type": "code_interpreter"])
        }
        
        if viewModel.activePrompt.enableComputerUse {
            tools.append([
                "type": "computer",
                "display_width_px": 1024,
                "display_height_px": 768
            ])
        }
        
        if !tools.isEmpty {
            request["tools"] = tools
        }
        
        // Parameters
        if viewModel.activePrompt.temperature != 1.0 {
            request["temperature"] = viewModel.activePrompt.temperature
        }
        
        if viewModel.activePrompt.maxOutputTokens > 0 {
            request["max_output_tokens"] = viewModel.activePrompt.maxOutputTokens
        }
        
        if viewModel.activePrompt.topP != 1.0 {
            request["top_p"] = viewModel.activePrompt.topP
        }
        
        // Streaming
        request["stream"] = viewModel.activePrompt.enableStreaming
        
        // Previous response ID if continuing conversation
        if let lastResponseId = viewModel.lastResponseId {
            request["previous_response_id"] = lastResponseId
        }
        
        return request
    }
    
    // MARK: - Copy Action
    
    private func copyToClipboard() {
#if os(iOS)
        UIPasteboard.general.string = formattedJSON
        copiedToClipboard = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
        }
#endif
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    RequestInspectorView(userMessage: "Analyze this document")
        .environmentObject({
            let vm = ChatViewModel(api: OpenAIService())
            vm.activePrompt.openAIModel = "gpt-4o"
            vm.activePrompt.enableFileSearch = true
            vm.activePrompt.selectedVectorStoreIds = "vs_123,vs_456"
            vm.pendingFileData = [Data()]
            vm.pendingFileNames = ["document.pdf"]
            return vm
        }())
}
