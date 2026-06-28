import SwiftUI

/// Playground-style request inspector showing the actual JSON payload
/// Lets power users see exactly what's being sent to the OpenAI API
struct RequestInspectorView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false

    let userMessage: String

    private var usesBackgroundPolling: Bool {
        viewModel.activePrompt.backgroundMode
    }

    private var effectiveStreamingEnabled: Bool {
        viewModel.activePrompt.enableStreaming && !usesBackgroundPolling
    }

    private var supportsTemperature: Bool {
        ModelCompatibilityService.shared.isParameterSupported(
            "temperature",
            for: viewModel.activePrompt.openAIModel,
            reasoningEffort: viewModel.activePrompt.reasoningEffort
        )
    }

    private var supportsTopP: Bool {
        ModelCompatibilityService.shared.isParameterSupported(
            "top_p",
            for: viewModel.activePrompt.openAIModel,
            reasoningEffort: viewModel.activePrompt.reasoningEffort
        )
    }

    var body: some View {
        NavigationStack {
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

                    // Validation Warnings
                    if !validationWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Validation Warnings")
                                    .font(.headline)
                            }
                            ForEach(validationWarnings, id: \.self) { warning in
                                Text("• \(warning)")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
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
            DetailRow(label: "Streaming", value: effectiveStreamingEnabled ? "Enabled" : "Disabled")

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
    
    private var validationWarnings: [String] {
        var warnings: [String] = []
        let prompt = viewModel.activePrompt
        
        if viewModel.activeConversation?.remoteId != nil && viewModel.lastResponseId != nil {
            warnings.append("Both conversation ID and previous_response_id are set. The API may reject this.")
        }
        
        if prompt.backgroundMode && !prompt.storeResponses {
            warnings.append("Background mode requires 'store: true'.")
        }
        
        let caps = ModelCompatibilityService.shared.getCapabilities(for: prompt.openAIModel)
        let supportsReasoning = caps?.supportsReasoningEffort == true
        
        if prompt.reasoningEffort != "none" && !supportsReasoning {
            warnings.append("Reasoning effort '\(prompt.reasoningEffort)' is not supported by model '\(prompt.openAIModel)'.")
        }
        
        if prompt.reasoningEffort != "none" && supportsReasoning {
            if prompt.temperature != 1.0 {
                warnings.append("Temperature cannot be modified when reasoning effort is active.")
            }
            if prompt.topP != 1.0 {
                warnings.append("Top P cannot be modified when reasoning effort is active.")
            }
            if prompt.includeOutputLogprobs {
                warnings.append("Logprobs are not supported when reasoning effort is active.")
            }
        }
        
        if prompt.enableFileSearch {
            if let ids = prompt.selectedVectorStoreIds, !ids.isEmpty {
                // Good
            } else {
                warnings.append("File search is enabled but no vector stores are attached.")
            }
        }
        
        if prompt.enableComputerUse {
            let supportsComputer = ModelCompatibilityService.shared.isToolSupported(.computer, for: prompt.openAIModel, isStreaming: effectiveStreamingEnabled)
            if !supportsComputer {
                warnings.append("Computer use is enabled on an unsupported model or in an incompatible streaming configuration.")
            }
        }
        
        return warnings
    }

    private func buildPreviewRequest() -> [String: Any] {
        var requestObject = viewModel.api.buildPreviewRequestObject(
            for: viewModel.activePrompt,
            userMessage: userMessage,
            attachments: nil,
            fileData: nil,
            fileNames: nil,
            fileIds: nil,
            imageAttachments: nil,
            audioAttachments: nil,
            previousResponseId: viewModel.lastResponseId,
            conversationId: viewModel.activeConversation?.remoteId,
            stream: effectiveStreamingEnabled
        )
        
        // Find the 'input' array and append our placeholder attachments if any
        if var inputArray = requestObject["input"] as? [[String: Any]],
           let userIndex = inputArray.firstIndex(where: { $0["role"] as? String == "user" }),
           var userMessageDict = inputArray[userIndex]["content"] as? [[String: Any]] {
           
            for fileName in viewModel.pendingFileNames {
                userMessageDict.append([
                    "type": "input_file",
                    "file_data": "<base64_encoded_data>",
                    "filename": fileName
                ])
            }
            
            for (index, _) in viewModel.pendingImageAttachments.enumerated() {
                userMessageDict.append([
                    "type": "input_image",
                    "image_data": "<base64_encoded_image_\(index + 1)>",
                    "detail": "auto"
                ])
            }
            
            inputArray[userIndex]["content"] = userMessageDict
            requestObject["input"] = inputArray
        }
        
        // Secret redaction for preview
        if var toolsArray = requestObject["tools"] as? [[String: Any]] {
            for (toolIndex, var tool) in toolsArray.enumerated() {
                if let toolType = tool["type"] as? String, toolType.hasPrefix("mcp_") {
                    // Redact headers
                    if var headers = tool["headers"] as? [String: Any] {
                        if headers["Authorization"] != nil {
                            headers["Authorization"] = "[REDACTED_SECRET]"
                        }
                        tool["headers"] = headers
                        toolsArray[toolIndex] = tool
                    }
                }
            }
            requestObject["tools"] = toolsArray
        }
        
        return requestObject
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
