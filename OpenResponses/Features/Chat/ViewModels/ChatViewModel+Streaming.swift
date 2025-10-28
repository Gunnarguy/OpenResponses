import SwiftUI

@MainActor
extension ChatViewModel {
    /// Processes a single streaming event emitted by the OpenAI Responses API.
    /// - Parameters:
    ///   - chunk: Incoming event from the streaming sequence.
    ///   - messageId: Identifier of the assistant message currently being populated.
    func handleStreamChunk(_ chunk: StreamingEvent, for messageId: UUID) {
        guard streamingMessageId == messageId else { return }
        guard messages.firstIndex(where: { $0.id == messageId }) != nil else { return }

        updateStreamingStatus(for: chunk.type, item: chunk.item, messageId: messageId)
        if let response = chunk.response {
            lastResponseId = response.id
        }

        switch chunk.type {
        case "response.output_text.annotation.added":
            handleAnnotationAddedChunk(chunk, messageId: messageId)
        case "error":
            handleStreamingErrorChunk(chunk, messageId: messageId)
        case "response.failed":
            handleResponseFailedChunk(chunk, messageId: messageId)
        case "response.output_text.delta":
            handleTextDeltaChunk(chunk, messageId: messageId)
        case "response.content_part.done":
            handleContentPartDoneChunk(chunk, messageId: messageId)
        case "response.output_item.done":
            handleOutputItemDoneChunk(chunk, messageId: messageId)
        case "response.done", "response.completed":
            handleResponseCompletion(chunk, messageId: messageId)
        case "response.image_generation_call.partial_image":
            handlePartialImageUpdate(chunk, for: messageId)
        case "response.image_generation_call.completed":
            handleImageGenerationCompletedChunk(chunk, messageId: messageId)
        case "response.computer_call.in_progress",
             "response.computer_call.screenshot_taken",
             "response.computer_call.action_performed",
             "response.computer_call.completed":
            handleComputerCallEvent(chunk, messageId: messageId)
        case "response.output_item.added":
            handleOutputItemAddedChunk(chunk, messageId: messageId)
        case "response.output_item.completed":
            handleOutputItemCompletedChunk(chunk, messageId: messageId)
        case "response.mcp_list_tools.added", "response.mcp_list_tools.updated":
            handleMCPListToolsChunk(chunk, messageId: messageId)
        case "response.mcp_call.added":
            handleMCPCallAddedChunk(chunk, messageId: messageId)
        case "response.mcp_call.done":
            handleMCPCallDoneChunk(chunk, messageId: messageId)
        case "response.mcp_approval_request.added":
            handleMCPApprovalRequestChunk(chunk, messageId: messageId)
        default:
            break
        }
    }

    /// Handles annotations that reference generated files from tool calls or code execution.
    private func handleAnnotationAddedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        let annoFileId = chunk.fileId ?? chunk.annotation?.fileId
        let annoFilename = chunk.filename ?? chunk.annotation?.filename
        let annoContainerId = chunk.containerId ?? chunk.annotation?.containerId

        guard let fileId = annoFileId, let filename = annoFilename,
              messages.firstIndex(where: { $0.id == messageId }) != nil else {
            return
        }

    let annotationKey = "\(annoContainerId ?? "")_\(fileId)"
        guard !processedAnnotations.contains(annotationKey) else { return }
        processedAnnotations.insert(annotationKey)

        if let cid = annoContainerId {
            var list = containerAnnotationsByMessage[messageId] ?? []
            list.append((containerId: cid, fileId: fileId, filename: filename))
            containerAnnotationsByMessage[messageId] = list
        }

        Task {
            do {
                let data: Data
                if let cachedData = containerFileCache[annotationKey] {
                    data = cachedData
                    AppLogger.log("Using cached data for \(filename)", category: .openAI, level: .debug)
                } else {
                    if let containerId = annoContainerId, fileId.hasPrefix("cfile_") {
                        AppLogger.log("Fetching container file content container_id=\(containerId), file_id=\(fileId), filename=\(filename)", category: .openAI, level: .info)
                        data = try await api.fetchContainerFileContent(containerId: containerId, fileId: fileId)
                    } else {
                        let contentItem = ContentItem(type: "image_file", text: nil, imageURL: nil, imageFile: ImageFileContent(file_id: fileId))
                        data = try await api.fetchImageData(for: contentItem)
                    }
                    containerFileCache[annotationKey] = data
                }

                let artifact = self.createArtifact(
                    fileId: fileId,
                    filename: filename,
                    containerId: annoContainerId ?? "unknown",
                    data: data
                )

                await MainActor.run {
                    self.appendArtifact(artifact, to: messageId)
                }

                AppLogger.log("Successfully processed artifact: \(filename) (\(artifact.artifactType.rawValue), \(data.count) bytes)", category: .openAI, level: .info)
            } catch {
                AppLogger.log("Failed to fetch annotation file (file_id=\(fileId), container_id=\(annoContainerId ?? "none")): \(error)", category: .openAI, level: .warning)
                let errorArtifact = CodeInterpreterArtifact(
                    fileId: fileId,
                    filename: filename,
                    containerId: annoContainerId ?? "unknown",
                    mimeType: nil,
                    content: .error("Failed to load: \(error.localizedDescription)")
                )

                await MainActor.run {
                    self.appendArtifact(errorArtifact, to: messageId)
                }
            }
        }
    }

    /// Handles streaming error events. Attempts a retry before surfacing the issue to the user.
    private func handleStreamingErrorChunk(_ chunk: StreamingEvent, messageId: UUID) {
        // Check for standalone error event (e.g., context_length_exceeded)
        let errorMessage: String
        let errorCode: String
        
        if let errorInfo = chunk.errorInfo {
            // Standalone error event with errorInfo
            errorMessage = errorInfo.message
            errorCode = errorInfo.code ?? "unknown"
        } else if let responseError = chunk.response?.error {
            // Error nested in response object
            errorMessage = responseError.message
            errorCode = responseError.code ?? "unknown"
        } else {
            // Fallback
            errorMessage = "An unknown error occurred during streaming"
            errorCode = "unknown"
        }
        
        AppLogger.log("🚨 [Streaming Error] Code: \(errorCode) - \(errorMessage)", category: .openAI, level: .error)
        AppLogger.log("🔍 [Error Context] Event type: \(chunk.type), Response ID: \(chunk.response?.id ?? "none")", category: .openAI, level: .info)
        
        // Auto-revoke Notion preflight on 401 Unauthorized during MCP operations
        if errorCode == "http_error" || errorMessage.lowercased().contains("unauthorized") || errorMessage.contains("401") {
            let label = activePrompt.mcpServerLabel
            let url = activePrompt.mcpServerURL
            let isNotion = label.lowercased().contains("notion") || url.lowercased().contains("notion")
            if isNotion {
                revokeNotionPreflight(for: label)
                let note = ChatMessage(
                    role: .system,
                    text: "MCP Notion authorization failed (401). Re-run Test Connection in Remote Server Setup and ensure your integration has access to at least one page or database."
                )
                messages.append(note)
                // Abort streaming immediately after Notion 401; do not attempt retry
                isStreaming = false
                streamingStatus = .idle
                streamingMessageId = nil
                isAwaitingComputerOutput = false
                return
            }
        }

        // Special handling for context_length_exceeded
        if errorCode == "context_length_exceeded" {
            AppLogger.log("💡 [Context Length] Conversation history too large - offering to start fresh", category: .openAI, level: .info)
            messages.append(ChatMessage(
                role: .system, 
                text: "⚠️ Context Window Exceeded\n\nYour conversation history is too large. To continue:\n• Clear conversation history (Chat menu → Clear History)\n• Or start a new conversation"
            ))
            isStreaming = false
            streamingStatus = .idle
            streamingMessageId = nil
            isAwaitingComputerOutput = false
            return
        }

        if attemptStreamingRetry(for: messageId, reason: errorMessage) {
            return
        }

        messages.append(ChatMessage(role: .system, text: "⚠️ Error: \(errorMessage)"))
        isStreaming = false
        streamingStatus = .idle
        streamingMessageId = nil
        isAwaitingComputerOutput = false
    }

    /// Handles "response.failed" events emitted when the server aborts the response.
    private func handleResponseFailedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        let errorMessage = chunk.response?.error?.message ?? "The request failed"
        let errorCode = chunk.response?.error?.code ?? "unknown"
        let responseStatus = chunk.response?.status ?? "unknown"
        AppLogger.log("🚨 [Response Failed] Status: \(responseStatus), Error: \(errorCode) - \(errorMessage)", category: .openAI, level: .error)

        if let response = chunk.response, let output = response.output {
            for (index, outputItem) in output.enumerated() {
                AppLogger.log("🔍 [Response Failed Output \(index)] Type: \(outputItem.type), ID: \(outputItem.id), Status: \(outputItem.status ?? "unknown")", category: .openAI, level: .info)
                if let content = outputItem.content {
                    for contentItem in content where contentItem.type.contains("mcp") {
                        AppLogger.log("🔍 [MCP Content Error] Type: \(contentItem.type)", category: .openAI, level: .info)
                    }
                }
            }
        }

        if attemptStreamingRetry(for: messageId, reason: errorMessage) {
            return
        }

        messages.append(ChatMessage(role: .system, text: "⚠️ Request failed: \(errorMessage)"))
        isStreaming = false
        streamingStatus = .idle
        streamingMessageId = nil
        isAwaitingComputerOutput = false
    }

    /// Buffers text deltas and coalesces them into fewer UI updates for smoother rendering.
    private func handleTextDeltaChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let delta = chunk.delta,
              let messageIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }

        AppLogger.log("Buffering text delta (len=\(delta.count)) for index \(messageIndex)", category: .ui, level: .debug)
        let existing = deltaBuffers[messageId] ?? ""
        deltaBuffers[messageId] = existing + delta

        let totalText = (messages[messageIndex].text ?? "") + (deltaBuffers[messageId] ?? "")
        let estimate = ChatViewModel.estimateTokens(for: totalText)
        var updated = messages
        var usage = updated[messageIndex].tokenUsage ?? TokenUsage()
        usage.estimatedOutput = estimate
        updated[messageIndex].tokenUsage = usage
        messages = updated
        recomputeCumulativeUsage()

        let bufferedText = deltaBuffers[messageId] ?? ""
        let shouldFlushNow = delta.last.map { ".!?\n\r".contains($0) } ?? false || bufferedText.count >= minBufferSizeForFlush
        scheduleDeltaFlush(for: messageId, messageIndex: messageIndex, immediate: shouldFlushNow)
    }

    /// Persists completed content parts such as generated images.
    private func handleContentPartDoneChunk(_ chunk: StreamingEvent, messageId: UUID) {
        if let item = chunk.item {
            handleCompletedStreamingItem(item, for: messageId)
        }
    }

    /// Handles completion of output items and triggers tool-specific follow-up actions.
    private func handleOutputItemDoneChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let item = chunk.item else { return }
        handleCompletedStreamingItem(item, for: messageId)
        trackToolUsage(item, for: messageId)

        if item.type == "computer_call" {
            isAwaitingComputerOutput = true
            streamingStatus = .usingComputer
            Task { [weak self] in
                await self?.handleComputerToolCallWithFullResponse(item, messageId: messageId)
            }
        }
    }

    /// Finalizes the response once the stream signals completion.
    func handleResponseCompletion(_ chunk: StreamingEvent, messageId: UUID) {
        AppLogger.log("Streaming response completed for message: \(messageId)", category: .streaming, level: .info)
        clearPendingFileAttachments()
        flushDeltaBufferIfNeeded(for: messageId)

        if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages
            var usage = updated[msgIndex].tokenUsage ?? TokenUsage()
            if let finalUsage = chunk.response?.usage {
                usage.input = finalUsage.inputTokens
                usage.output = finalUsage.outputTokens
                usage.total = finalUsage.totalTokens
                usage.estimatedOutput = nil
            } else {
                let finalText = updated[msgIndex].text ?? ""
                usage.estimatedOutput = ChatViewModel.estimateTokens(for: finalText)
            }
            updated[msgIndex].tokenUsage = usage
            messages = updated
            recomputeCumulativeUsage()
        }

        if !isAwaitingComputerOutput {
            isStreaming = false
            streamingStatus = .idle
            streamingMessageId = nil
        } else {
            streamingStatus = .usingComputer
            AppLogger.log("Stream completed; continuing with computer use", category: .streaming, level: .debug)
        }

        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }),
              let text = messages[msgIndex].text, !text.isEmpty else { return }

        let detectedURLs = URLDetector.extractRenderableURLs(from: text)
        if !detectedURLs.isEmpty {
            var updatedMessages = messages
            updatedMessages[msgIndex].webURLs = detectedURLs
            messages = updatedMessages
            AppLogger.log("Detected \(detectedURLs.count) renderable URLs in assistant response", category: .ui, level: .debug)
        }

        let imageLinks = URLDetector.extractImageLinks(from: text)
        if !imageLinks.isEmpty {
            Task { [weak self] in
                guard let self else { return }
                await self.consumeImageLinks(imageLinks, for: messageId)
            }
        }

        if (messages[msgIndex].images?.isEmpty ?? true), let finalId = lastResponseId {
            Task { [weak self] in
                guard let self else { return }
                do {
                    let full = try await self.api.getResponse(responseId: finalId)
                    for outputItem in full.output {
                        for content in outputItem.content ?? [] where content.type == "image_file" || content.type == "image_url" {
                            do {
                                let data = try await self.api.fetchImageData(for: content)
                                if let image = UIImage(data: data) {
                                    await MainActor.run {
                                        if let idx = self.messages.firstIndex(where: { $0.id == messageId }) {
                                            if self.messages[idx].images == nil { self.messages[idx].images = [] }
                                            self.messages[idx].images?.append(image)
                                        }
                                    }
                                }
                            } catch {
                                AppLogger.log("Fallback image fetch failed: \(error)", category: .openAI, level: .warning)
                            }
                        }
                    }
                } catch {
                    AppLogger.log("Fallback getResponse failed: \(error)", category: .openAI, level: .warning)
                }
            }
        }
    }

    /// Handles completion events from the image generation API.
    private func handleImageGenerationCompletedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let item = chunk.item else { return }
        streamingStatus = .imageGenerationCompleting
        logActivity("🎨 Finalizing image…")
        handleCompletedStreamingItem(item, for: messageId)
        stopImageGenerationHeartbeat(for: messageId)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.streamingStatus = .imageReady
            self?.logActivity("🖼️ Image generated successfully!")
        }
    }

    /// Handles all computer-use streaming events to keep the UI in sync.
    func handleComputerCallEvent(_ chunk: StreamingEvent, messageId: UUID) {
        switch chunk.type {
        case "response.computer_call.in_progress":
            trackToolUsage(for: messageId, tool: "computer")
            updateStreamingStatus(for: "computer.in_progress")
        case "response.computer_call.screenshot_taken":
            updateStreamingStatus(for: "computer.screenshot")
            handleComputerScreenshot(chunk, for: messageId)
        case "response.computer_call.action_performed":
            updateStreamingStatus(for: "computer.action")
        case "response.computer_call.completed":
            if let item = chunk.item {
                handleCompletedStreamingItem(item, for: messageId)
            }
            updateStreamingStatus(for: "computer.completed")
        default:
            break
        }
    }

    /// Tracks tool usage whenever a new output item is emitted.
    private func handleOutputItemAddedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        if let item = chunk.item {
            trackToolUsage(item, for: messageId)
        }
    }

    /// Handles completion notifications for output items.
    private func handleOutputItemCompletedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        if let item = chunk.item {
            handleCompletedStreamingItem(item, for: messageId)
        }
    }
    
    // MARK: - MCP Event Handlers
    
    /// Handles MCP list_tools events that report available tools from the remote server.
    private func handleMCPListToolsChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let serverLabel = chunk.serverLabel ?? chunk.item?.serverLabel else {
            AppLogger.log("⚠️ [MCP] list_tools event missing server_label", category: .openAI, level: .warning)
            return
        }
        
        let status = chunk.item?.status?.lowercased()
        let structuredError = chunk.item?.error
        let inlineError = chunk.error

        if status == "failed" || structuredError != nil || (inlineError?.isEmpty == false) {
            let errorDescription = describeMCPError(status: status, stringError: inlineError, structuredError: structuredError)
            AppLogger.log("❌ [MCP] Server '\(serverLabel)' failed to list tools: \(errorDescription)", category: .openAI, level: .error)
            logActivity("MCP: \(serverLabel) list_tools failed - \(errorDescription)")
            mcpToolRegistry.removeValue(forKey: serverLabel)
            
            // If Notion MCP returned 401/Unauthorized, revoke preflight to force revalidation
            let lower = errorDescription.lowercased()
            if lower.contains("401") || lower.contains("unauthorized") {
                revokeNotionPreflight(for: serverLabel)
            }

            let signature = "\(status ?? "failed")|\(errorDescription)"
            if lastMCPListToolsError[serverLabel] != signature {
                lastMCPListToolsError[serverLabel] = signature
                var message = "⚠️ MCP server '\(serverLabel)' could not list its tools: \(errorDescription)."
                if let hint = hintForMCPServer(serverLabel) {
                    message += " \(hint)"
                }
                messages.append(ChatMessage(role: .system, text: message))
            }
            return
        }

        lastMCPListToolsError.removeValue(forKey: serverLabel)

        let toolCount = chunk.tools?.count ?? 0
        AppLogger.log("🔧 [MCP] Server '\(serverLabel)' listed \(toolCount) available tools", category: .openAI, level: .info)
        
        // Store tools in registry for future reference
        if let tools = chunk.tools {
            mcpToolRegistry[serverLabel] = tools
            
            // Log each tool for debugging
            for tool in tools {
                if let name = tool["name"]?.value as? String {
                    let description = (tool["description"]?.value as? String) ?? "No description"
                    AppLogger.log("  - \(name): \(description)", category: .openAI, level: .debug)
                }
            }
        }
        
        logActivity("MCP: \(serverLabel) has \(toolCount) tools available")
        trackToolUsage(for: messageId, tool: "mcp")
    }
    
    /// Handles MCP call events when the assistant invokes an MCP tool.
    private func handleMCPCallAddedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let toolName = chunk.name, let serverLabel = chunk.serverLabel else {
            AppLogger.log("⚠️ [MCP] call event missing name or server_label", category: .openAI, level: .warning)
            return
        }
        
        AppLogger.log("🔧 [MCP] Calling tool '\(toolName)' on server '\(serverLabel)'", category: .openAI, level: .info)
        
        // Log arguments if present
        if let arguments = chunk.arguments {
            AppLogger.log("  Arguments: \(arguments)", category: .openAI, level: .debug)
        }
        
        logActivity("MCP: Calling \(toolName) on \(serverLabel)…")
        streamingStatus = .runningTool(toolName)
        trackToolUsage(for: messageId, tool: "mcp")
    }
    
    /// Handles MCP call completion events with output or errors.
    private func handleMCPCallDoneChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let toolName = chunk.name, let serverLabel = chunk.serverLabel else {
            AppLogger.log("⚠️ [MCP] call.done event missing name or server_label", category: .openAI, level: .warning)
            return
        }
        
        let status = chunk.item?.status?.lowercased()
        let structuredError = chunk.item?.error
        let inlineError = chunk.error

        if status == "failed" || structuredError != nil || (inlineError?.isEmpty == false) {
            let errorDescription = describeMCPError(status: status, stringError: inlineError, structuredError: structuredError)
            AppLogger.log("❌ [MCP] Tool '\(toolName)' on '\(serverLabel)' failed: \(errorDescription)", category: .openAI, level: .error)
            logActivity("MCP: \(toolName) failed - \(errorDescription)")

            var message = "⚠️ MCP tool '\(toolName)' on server '\(serverLabel)' failed: \(errorDescription)."
            if let hint = hintForMCPServer(serverLabel) {
                message += " \(hint)"
            }
            messages.append(ChatMessage(role: .system, text: message))
        } else if let output = chunk.output {
            AppLogger.log("✅ [MCP] Tool '\(toolName)' on '\(serverLabel)' completed", category: .openAI, level: .info)
            AppLogger.log("  Output: \(output)", category: .openAI, level: .debug)
            logActivity("MCP: \(toolName) completed")
        } else {
            AppLogger.log("✅ [MCP] Tool '\(toolName)' on '\(serverLabel)' completed (no output)", category: .openAI, level: .info)
            logActivity("MCP: \(toolName) completed")
        }
    }
    
    /// Handles MCP approval request events when user authorization is needed.
    private func handleMCPApprovalRequestChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let approvalRequestId = chunk.approvalRequestId,
              let toolName = chunk.name,
              let serverLabel = chunk.serverLabel else {
            AppLogger.log("⚠️ [MCP] approval_request event missing required fields", category: .openAI, level: .warning)
            return
        }
        
        let arguments = chunk.arguments ?? "{}"
        
        AppLogger.log("🔒 [MCP] Approval requested for tool '\(toolName)' on server '\(serverLabel)' (id: \(approvalRequestId))", category: .openAI, level: .info)
        AppLogger.log("  Arguments: \(arguments)", category: .openAI, level: .debug)
        
        // Create approval request object
        let approvalRequest = MCPApprovalRequest(
            id: approvalRequestId,
            toolName: toolName,
            serverLabel: serverLabel,
            arguments: arguments,
            status: .pending,
            reason: nil
        )
        
        // Add to current message
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            if messages[index].mcpApprovalRequests == nil {
                messages[index].mcpApprovalRequests = []
            }
            messages[index].mcpApprovalRequests?.append(approvalRequest)
        }
        
        logActivity("MCP: Approval needed for \(toolName)")
    }
}

// MARK: - MCP Error Helpers
private extension ChatViewModel {
    /// Clears stored preflight state for a given MCP server label so future sends will revalidate.
    func revokeNotionPreflight(for label: String) {
        let d = UserDefaults.standard
        // Preflight flags
        d.set(false, forKey: "mcp_preflight_ok_\(label)")
        d.removeObject(forKey: "mcp_preflight_ok_at_\(label)")
        d.removeObject(forKey: "mcp_preflight_token_hash_\(label)")
        d.removeObject(forKey: "mcp_preflight_user_\(label)")
        // Probe flags (list_tools health)
        d.set(false, forKey: "mcp_probe_ok_\(label)")
        d.removeObject(forKey: "mcp_probe_ok_at_\(label)")
        d.removeObject(forKey: "mcp_probe_token_hash_\(label)")
        AppLogger.log("🔐 [MCP] Revoked preflight and probe state for '\(label)' due to auth failure", category: .openAI, level: .warning)
    }
    /// Builds a readable description for MCP failures, prioritizing structured error data when available.
    func describeMCPError(status: String?, stringError: String?, structuredError: MCPToolError?) -> String {
        let trimmedStatus = status?.lowercased() == "failed" ? "failed" : nil
        var base = stringError?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let structuredError {
            let structuredMessage = structuredError.message.trimmingCharacters(in: .whitespacesAndNewlines)
            if !structuredMessage.isEmpty {
                base = structuredMessage
            }
            var metadata: [String] = []
            if let code = structuredError.code {
                metadata.append("code \(code)")
            }
            if !structuredError.type.isEmpty {
                metadata.append(structuredError.type)
            }
            if let trimmedStatus {
                metadata.append("status \(trimmedStatus)")
            }
            if metadata.isEmpty {
                return base.isEmpty ? "Unknown error" : base
            } else {
                let headline = base.isEmpty ? "Unknown error" : base
                return "\(headline) (\(metadata.joined(separator: ", ")))"
            }
        }

        if let trimmedStatus {
            if base.isEmpty {
                return "Unknown error (status \(trimmedStatus))"
            }
            return "\(base) (status \(trimmedStatus))"
        }

        return base.isEmpty ? "Unknown error" : base
    }

    /// Provides human guidance for well-known MCP servers when authentication issues are detected.
    func hintForMCPServer(_ serverLabel: String) -> String? {
        let normalized = serverLabel.lowercased()
        if normalized.contains("notion") {
            return "Verify that your Notion integration token is current and the relevant pages/databases are shared with the integration."
        }
        return nil
    }
}
