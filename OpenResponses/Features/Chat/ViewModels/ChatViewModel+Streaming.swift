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
        case "response.output_item.delta":
            handleOutputItemDeltaChunk(chunk, messageId: messageId)
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
        case "response.mcp_list_tools.added", "response.mcp_list_tools.updated", "response.mcp_list_tools.in_progress", "response.mcp_list_tools.completed", "response.mcp_list_tools.failed":
            handleMCPListToolsChunk(chunk, messageId: messageId)
        case "response.mcp_call.added", "response.mcp_call.in_progress":
            handleMCPCallAddedChunk(chunk, messageId: messageId)
        case "response.mcp_call.done", "response.mcp_call.completed", "response.mcp_call.failed":
            handleMCPCallDoneChunk(chunk, messageId: messageId)
        case "response.mcp_call_arguments.delta":
            handleMCPArgumentsDeltaChunk(chunk, messageId: messageId)
        case "response.mcp_call_arguments.done":
            handleMCPArgumentsDoneChunk(chunk, messageId: messageId)
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
        finalizeStreamingReasoning(for: messageId)
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
        finalizeStreamingReasoning(for: messageId)
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

    /// Handles incremental updates for output items, including reasoning traces.
    private func handleOutputItemDeltaChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let item = chunk.item else { return }

        switch item.type {
        case "reasoning":
            handleReasoningDelta(item, messageId: messageId)
        default:
            break
        }
    }

    /// Captures live reasoning deltas so the UI can surface the assistant's chain of thought.
    private func handleReasoningDelta(_ item: StreamingItem, messageId: UUID) {
        let fragments = item.content?.compactMap { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        guard !fragments.isEmpty else { return }

        let combined = fragments.filter { !$0.isEmpty }.joined(separator: " ")
        guard !combined.isEmpty else { return }

        AppLogger.log("🧠 [Streaming] Reasoning delta received (len=\(combined.count))", category: .streaming, level: .debug)
        appendStreamingReasoning(delta: combined, to: messageId)
    }

    /// Finalizes the response once the stream signals completion.
    func handleResponseCompletion(_ chunk: StreamingEvent, messageId: UUID) {
        AppLogger.log("🎬 [Streaming] Response completed for message: \(messageId)", category: .streaming, level: .info)
        if let responseId = chunk.response?.id {
            AppLogger.log("🎬 [Streaming] Final response ID: \(responseId)", category: .streaming, level: .info)
            if let response = chunk.response {
                _ = storeReasoningItems(from: response)
            }
        } else {
            AppLogger.log("🎬 [Streaming] No response ID on completion chunk", category: .streaming, level: .debug)
        }
        if let outputItems = chunk.response?.output {
            AppLogger.log("📦 [Streaming] Completion contains \(outputItems.count) output items", category: .streaming, level: .info)
            for (index, item) in outputItems.enumerated() {
                AppLogger.log("📦 [Streaming] Output[\(index)] id=\(item.id), type=\(item.type), status=\(item.status ?? "none"), role=\(item.role ?? "none")", category: .streaming, level: .info)
                if let content = item.content, !content.isEmpty {
                    AppLogger.log("📄 [Streaming] Output[\(index)] has \(content.count) content parts", category: .streaming, level: .info)
                    for (cIndex, part) in content.enumerated() {
                        AppLogger.log("📄 [Streaming] Content[\(cIndex)] type=\(part.type), text=\(part.text?.prefix(120) ?? "<none>")", category: .streaming, level: .info)
                    }
                } else {
                    AppLogger.log("📄 [Streaming] Output[\(index)] has no content array", category: .streaming, level: .debug)
                }
            }
        } else {
            AppLogger.log("📦 [Streaming] Completion chunk has no output items", category: .streaming, level: .debug)
        }
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

            let approvalRequestsFromCompletion = extractApprovalRequests(from: chunk.response?.output)
            if !approvalRequestsFromCompletion.isEmpty {
                if updated[msgIndex].mcpApprovalRequests == nil { updated[msgIndex].mcpApprovalRequests = [] }
                let existingIds = Set(updated[msgIndex].mcpApprovalRequests!.map { $0.id })
                for request in approvalRequestsFromCompletion where !existingIds.contains(request.id) {
                    updated[msgIndex].mcpApprovalRequests?.append(request)
                }
                if updated[msgIndex].toolsUsed == nil { updated[msgIndex].toolsUsed = [] }
                if !updated[msgIndex].toolsUsed!.contains("mcp") {
                    updated[msgIndex].toolsUsed!.append("mcp")
                }
            }

            let existing = updated[msgIndex].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty {
                if let synthesized = buildTextFromOutput(chunk.response?.output) {
                    AppLogger.log("📝 [Streaming] Synthesized text of length \(synthesized.count)", category: .streaming, level: .info)
                    updated[msgIndex].text = synthesized
                } else if let mcpText = buildTextFromMCPItems(chunk.response?.output) {
                    AppLogger.log("📝 [Streaming] Synthesized MCP text of length \(mcpText.count)", category: .streaming, level: .info)
                    updated[msgIndex].text = mcpText
                } else if let approvalText = buildTextFromApprovalRequests(approvalRequestsFromCompletion) {
                    AppLogger.log("📝 [Streaming] Synthesized approval text of length \(approvalText.count)", category: .streaming, level: .info)
                    updated[msgIndex].text = approvalText
                } else {
                    AppLogger.log("⚠️ [Streaming] Unable to synthesize text from completion output", category: .streaming, level: .warning)
                }
            }
            messages = updated
            recomputeCumulativeUsage()
        }

        applyReasoningTraces(responseId: chunk.response?.id, to: messageId)

        if !isAwaitingComputerOutput {
            isStreaming = false
            streamingStatus = .idle
            streamingMessageId = nil
        } else {
            streamingStatus = .usingComputer
            AppLogger.log("Stream completed; continuing with computer use", category: .streaming, level: .debug)
        }

        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else { return }

        let finalText = messages[msgIndex].text ?? ""
        AppLogger.log("💬 [Streaming] Final message text length: \(finalText.count)", category: .streaming, level: .info)
        AppLogger.log("💬 [Streaming] Final message text preview: \(finalText.prefix(200))", category: .streaming, level: .info)

        guard !finalText.isEmpty else { return }

        let text = finalText

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
    logActivity("🎨 Finalizing image")
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
    
    /// Handles MCP list_tools events, which report available tools from the remote server.
    /// This function is critical for registering which tools the model is allowed to call.
    private func handleMCPListToolsChunk(_ chunk: StreamingEvent, messageId: UUID) {
        let resolved = resolveServerLabel(
            serverLabel: chunk.serverLabel,
            itemServerLabel: chunk.item?.serverLabel,
            fallbackId: chunk.item?.id
        )
        if resolved.usedFallback {
            AppLogger.log("list_tools event missing server_label; using fallback '\(resolved.label)'", category: .mcp, level: .debug)
        }
        let serverLabel = resolved.label
        lastMCPServerLabel = serverLabel
        
        let status = chunk.item?.status?.lowercased()
        let structuredError = chunk.item?.error
        let inlineError = chunk.error

        // Handle cases where the list_tools call itself fails.
        if status == "failed" || structuredError != nil || (inlineError?.isEmpty == false) {
            let errorDescription = describeMCPError(status: status, stringError: inlineError, structuredError: structuredError)
            AppLogger.log("Server '\(serverLabel)' failed to list tools: \(errorDescription)", category: .mcp, level: .error)
            logActivity("MCP: \(serverLabel) list_tools failed - \(errorDescription)")
            mcpToolRegistry.removeValue(forKey: serverLabel)
            
            // If Notion MCP returned 401/Unauthorized, revoke preflight to force revalidation.
            let lower = errorDescription.lowercased()
            if lower.contains("401") || lower.contains("unauthorized") {
                revokeNotionPreflight(for: serverLabel)
            }

            // Avoid spamming the user with identical errors.
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

        let discoveredTools = chunk.tools ?? chunk.item?.tools
        let toolCount = discoveredTools?.count ?? 0
        AppLogger.log("Server '\(serverLabel)' listed \(toolCount) available tools.", category: .mcp, level: .info)
        
        // If the server explicitly reports zero tools, inform the user and prevent subsequent calls.
        if toolCount == 0 {
            let message = "⚠️ MCP server '\(serverLabel)' reported it has no available tools. The integration may be misconfigured or lack permissions."
            if mcpToolRegistry[serverLabel] != nil || lastMCPListToolsError[serverLabel] == nil {
                messages.append(ChatMessage(role: .system, text: message))
                lastMCPListToolsError[serverLabel] = "no-tools-listed" // Prevents repeated messages.
            }
        }
        
        // Store tools in the registry for future reference.
        if let tools = discoveredTools {
            mcpToolRegistry[serverLabel] = tools
            
            // Log each tool for debugging.
            for tool in tools {
                if let name = tool["name"]?.value as? String {
                    let description = (tool["description"]?.value as? String) ?? "No description"
                    AppLogger.log("  - Registered Tool: \(name): \(description)", category: .mcp, level: .debug)
                }
            }
        }
        
        logActivity("MCP: \(serverLabel) has \(toolCount) tools available")
        trackToolUsage(for: messageId, tool: "mcp")
    }
    
    /// Handles the start of an MCP tool call invocation from the assistant.
    private func handleMCPCallAddedChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let toolName = chunk.name ?? chunk.item?.name else {
            AppLogger.log("MCP call event is missing the tool name. This is a stream anomaly.", category: .mcp, level: .warning)
            return
        }
        let resolved = resolveServerLabel(
            serverLabel: chunk.serverLabel,
            itemServerLabel: chunk.item?.serverLabel,
            fallbackId: chunk.item?.id ?? chunk.itemId
        )
        if resolved.usedFallback {
            AppLogger.log("MCP call event missing server_label; using fallback '\(resolved.label)'", category: .mcp, level: .debug)
        }
        let serverLabel = resolved.label
        lastMCPServerLabel = serverLabel
        
        AppLogger.log("Calling tool '\(toolName)' on server '\(serverLabel)'.", category: .mcp, level: .info)
        
        // Log arguments if present in the initial chunk.
        if let arguments = chunk.arguments {
            AppLogger.log("  Initial arguments: \(arguments)", category: .mcp, level: .debug)
        }

        // Initialize buffer for streaming arguments.
        if let itemId = chunk.itemId ?? chunk.item?.id {
            if let initial = chunk.arguments, !initial.isEmpty {
                mcpArgumentBuffers[itemId] = initial
            } else {
                mcpArgumentBuffers[itemId] = ""
            }
        }
        
    logActivity("MCP: Calling \(toolName) on \(serverLabel)")
        streamingStatus = .runningTool(toolName)
        trackToolUsage(for: messageId, tool: "mcp")
    }
    
    /// Handles the completion of an MCP tool call, processing its output or error.
    private func handleMCPCallDoneChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let toolName = chunk.name ?? chunk.item?.name else {
            AppLogger.log("MCP call.done event is missing the tool name. This is a stream anomaly.", category: .mcp, level: .warning)
            return
        }
        let resolved = resolveServerLabel(
            serverLabel: chunk.serverLabel,
            itemServerLabel: chunk.item?.serverLabel,
            fallbackId: chunk.item?.id ?? chunk.itemId
        )
        if resolved.usedFallback {
            AppLogger.log("MCP call.done event missing server_label; using fallback '\(resolved.label)'", category: .mcp, level: .debug)
        }
        let serverLabel = resolved.label
        lastMCPServerLabel = serverLabel
        
        let status = chunk.item?.status?.lowercased()
        let structuredError = chunk.item?.error
        let inlineError = chunk.error

        // Handle failed tool calls.
        if status == "failed" || structuredError != nil || (inlineError?.isEmpty == false) {
            let errorDescription = describeMCPError(status: status, stringError: inlineError, structuredError: structuredError)
            AppLogger.log("Tool '\(toolName)' on '\(serverLabel)' failed: \(errorDescription)", category: .mcp, level: .error)
            logActivity("MCP: \(toolName) failed - \(errorDescription)")

            var message = "⚠️ MCP tool '\(toolName)' on server '\(serverLabel)' failed: \(errorDescription)."
            if let hint = hintForMCPServer(serverLabel) {
                message += " \(hint)"
            }

            let callIdentifier = chunk.item?.id ?? chunk.itemId ?? "\(serverLabel)|\(toolName)"
            let normalizedError = errorDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let rawArguments = (chunk.item?.arguments ?? chunk.arguments)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let argumentSignature = rawArguments.count > 512 ? String(rawArguments.prefix(512)) : rawArguments
            let warningKey = "\(callIdentifier)|\(normalizedError)|\(argumentSignature)"
            let inserted = surfacedMCPToolWarnings.insert(warningKey).inserted
            if inserted {
                messages.append(ChatMessage(role: .system, text: message))
            } else {
                AppLogger.log("Skipping duplicate MCP failure warning for '\(toolName)' on '\(serverLabel)'", category: .mcp, level: .debug)
            }
        // Handle successful tool calls.
        } else if let output = chunk.output {
            AppLogger.log("Tool '\(toolName)' on '\(serverLabel)' completed successfully.", category: .mcp, level: .info)
            AppLogger.log("  Output: \(output)", category: .mcp, level: .debug)
            logActivity("MCP: \(toolName) completed")

            // Render the output into the chat message.
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                var updated = messages
                let textBlock = renderMCPOutputText(serverLabel: serverLabel, toolName: toolName, rawOutput: output)
                let existing = (updated[index].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                updated[index].text = existing.isEmpty ? textBlock : (existing + "\n\n" + textBlock)
                messages = updated
            }
        } else {
            AppLogger.log("Tool '\(toolName)' on '\(serverLabel)' completed with no output.", category: .mcp, level: .info)
            logActivity("MCP: \(toolName) completed")
        }

        // Clean up argument buffer for this tool call.
        if let argumentKey = chunk.item?.id ?? chunk.itemId {
            mcpArgumentBuffers.removeValue(forKey: argumentKey)
        }
    }
    
    /// Buffers streaming MCP argument deltas for debugging and eventual display.
    private func handleMCPArgumentsDeltaChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let itemId = chunk.itemId ?? chunk.item?.id else { return }
        let fragment = chunk.argumentsDelta ?? chunk.arguments ?? chunk.delta
        guard let fragment, !fragment.isEmpty else { return }

        // Append the new fragment to the buffer for this item.
        let existing = mcpArgumentBuffers[itemId] ?? ""
        mcpArgumentBuffers[itemId] = existing + fragment

        let previewLimit = 160
    let preview = fragment.count > previewLimit ? String(fragment.prefix(previewLimit)) + "…" : fragment
        AppLogger.log("MCP arguments delta for item \(itemId): \(preview)", category: .mcp, level: .debug)

        if let toolName = chunk.name ?? chunk.item?.name, let serverLabel = chunk.serverLabel ?? chunk.item?.serverLabel {
            logActivity("MCP: Streaming arguments for \(toolName) on \(serverLabel)")
        }
    }

    /// Finalizes streaming MCP arguments and logs the complete payload for debugging.
    private func handleMCPArgumentsDoneChunk(_ chunk: StreamingEvent, messageId: UUID) {
        guard let itemId = chunk.itemId ?? chunk.item?.id else { return }
        defer { mcpArgumentBuffers.removeValue(forKey: itemId) }

        let aggregate = chunk.arguments ?? chunk.item?.arguments ?? mcpArgumentBuffers[itemId]
        guard let aggregate, !aggregate.isEmpty else { return }

        // Log the finalized arguments, pretty-printed if possible.
        if let pretty = prettyPrintArguments(aggregate) {
            AppLogger.log("MCP arguments finalized for item \(itemId):\n\(pretty)", category: .mcp, level: .debug)
        } else {
            let previewLimit = 200
            let preview = aggregate.count > previewLimit ? String(aggregate.prefix(previewLimit)) + "…" : aggregate
            AppLogger.log("MCP arguments finalized for item \(itemId): \(preview)", category: .mcp, level: .debug)
        }

        if let toolName = chunk.name ?? chunk.item?.name, let serverLabel = chunk.serverLabel ?? chunk.item?.serverLabel {
            logActivity("MCP: Arguments ready for \(toolName) on \(serverLabel)")
        } else {
            logActivity("MCP: Arguments ready")
        }
    }
    
    /// Handles MCP approval request events when user authorization is needed for a tool call.
    private func handleMCPApprovalRequestChunk(_ chunk: StreamingEvent, messageId: UUID) {
        // Prefer top-level fields, but fall back to item payload, as stream structure can vary.
        let approvalRequestId = chunk.approvalRequestId ?? chunk.item?.approvalRequestId
        let toolName = chunk.name ?? chunk.item?.name
        
        guard let approvalRequestId, let toolName else {
            AppLogger.log("MCP approval_request event is missing required fields (ID or tool name).", category: .mcp, level: .warning)
            return
        }
        let resolved = resolveServerLabel(
            serverLabel: chunk.serverLabel,
            itemServerLabel: chunk.item?.serverLabel,
            fallbackId: chunk.item?.id ?? approvalRequestId
        )
        if resolved.usedFallback {
            AppLogger.log("MCP approval_request missing server_label; using fallback '\(resolved.label)'", category: .mcp, level: .debug)
        }
        let serverLabel = resolved.label
        lastMCPServerLabel = serverLabel
        
        let arguments = chunk.arguments ?? chunk.item?.arguments ?? "{}"
        
        AppLogger.log("Approval requested for tool '\(toolName)' on server '\(serverLabel)' (id: \(approvalRequestId)).", category: .mcp, level: .info)
        AppLogger.log("  Arguments: \(arguments)", category: .mcp, level: .debug)
        
        // Create the approval request object to be stored with the message.
        let approvalRequest = MCPApprovalRequest(
            id: approvalRequestId,
            toolName: toolName,
            serverLabel: serverLabel,
            arguments: arguments,
            status: .pending,
            reason: nil
        )
        
        // Add the request to the current message to render the approval UI.
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updated = messages
            if updated[index].mcpApprovalRequests == nil {
                updated[index].mcpApprovalRequests = []
            }
            updated[index].mcpApprovalRequests?.append(approvalRequest)
            
            // Mark that an MCP tool was used for clearer UI hints.
            if updated[index].toolsUsed == nil { updated[index].toolsUsed = [] }
            if !updated[index].toolsUsed!.contains("mcp") {
                updated[index].toolsUsed!.append("mcp")
            }

            // If no other text has been generated, inject a summary of the approval request.
            if shouldInjectApprovalSummary(for: updated[index]) {
                let summary = makeApprovalSummary(toolName: toolName, serverLabel: serverLabel, rawArguments: arguments)
                updated[index].text = summary
            }

            messages = updated
        }
        
        logActivity("MCP: Approval needed for \(toolName)")
    }
}

// MARK: - MCP UI and Error Formatting Helpers
extension ChatViewModel {
    /// Synthesizes a user-facing message from final streaming output items when no assistant text delta was received.
    /// This is a fallback for tool-only responses.
    func buildTextFromOutput(_ output: [StreamingOutputItem]?) -> String? {
        guard let output else { return nil }
        var segments: [String] = []
        AppLogger.log("buildTextFromOutput scanning \(output.count) items", category: .streaming, level: .debug)
        for item in output where item.type == "message" {
            guard let content = item.content else { continue }
            AppLogger.log("Found message item id=\(item.id) with \(content.count) content blocks", category: .streaming, level: .debug)
            for block in content {
                if let text = block.text, !text.isEmpty {
                    AppLogger.log("Appending block text len=\(text.count)", category: .streaming, level: .debug)
                    segments.append(text)
                }
            }
        }
        let combined = segments.joined()
        let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        AppLogger.log("Combined text len=\(combined.count), trimmed len=\(trimmed.count)", category: .streaming, level: .debug)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Determines whether to synthesize user-facing copy for an approval-only response.
    /// This prevents overwriting a message that already has content.
    func shouldInjectApprovalSummary(for message: ChatMessage) -> Bool {
        let existing = message.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return existing.isEmpty
    }

    /// Generates a concise, human-readable summary explaining a pending approval request.
    func makeApprovalSummary(toolName: String, serverLabel: String, rawArguments: String) -> String {
        var parts: [String] = ["Approval required to run **\(toolName)** on **\(serverLabel)**."]
        if let prettyArgs = prettyPrintArguments(rawArguments) {
            parts.append("Arguments:\n```json\n\(prettyArgs)\n```")
        }
        return parts.joined(separator: "\n\n")
    }

    /// Attempts to pretty-print a JSON string for easier human review.
    /// - Parameter json: The raw JSON string from the tool call.
    /// - Returns: A formatted string or `nil` if parsing fails.
    func prettyPrintArguments(_ json: String) -> String? {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "{}", let data = trimmed.data(using: .utf8) else { return nil }

        do {
            let object = try JSONSerialization.jsonObject(with: data)

            // Pretty-print dictionaries
            if let dict = object as? [String: Any], !dict.isEmpty {
                let pretty = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
                return String(data: pretty, encoding: .utf8)
            }

            // Pretty-print arrays
            if let array = object as? [Any], !array.isEmpty {
                let pretty = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
                return String(data: pretty, encoding: .utf8)
            }
            
            // Fallback for simple values
            if let value = object as? CustomStringConvertible {
                return value.description
            }
        } catch {
            AppLogger.log("Failed to pretty-print approval arguments: \(error)", category: .ui, level: .debug)
        }

        return nil
    }

    /// Renders the output of a successful MCP tool call into a user-visible text block.
    func renderMCPOutputText(serverLabel: String, toolName: String, rawOutput: String) -> String {
        let trimmed = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First, try to extract a clean text block from the JSON.
        if let extracted = extractTextFromMCPJSON(trimmed), !extracted.isEmpty {
            return "MCP result from **\(serverLabel)** (`\(toolName)`):\n\n\(extracted)"
        }
        // If not, pretty-print the full JSON output.
        if let pretty = prettyPrintArguments(trimmed) {
            return "MCP result from **\(serverLabel)** (`\(toolName)`):\n\n```json\n\(pretty)\n```"
        }
        // Fallback for empty or non-JSON output.
        return "MCP result from **\(serverLabel)** (`\(toolName)`) completed with no output."
    }

    /// Formats a user-facing error message for a failed MCP tool call.
    func renderMCPFailureText(serverLabel: String, toolName: String, errorDescription: String, rawArguments: String?) -> String {
        var segments: [String] = [
            "⚠️ MCP error from **\(serverLabel)** (`\(toolName)`): \(errorDescription)"
        ]

        // Include the arguments that led to the failure for debugging.
        if let rawArguments {
            let trimmed = rawArguments.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, trimmed != "{}" {
                if let pretty = prettyPrintArguments(trimmed) {
                    segments.append("Arguments:\n```json\n\(pretty)\n```")
                } else {
                    segments.append("Arguments:\n\(trimmed)")
                }
            }
        }

        return segments.joined(separator: "\n\n")
    }

    /// Attempts to extract human-readable text from common MCP JSON output shapes (e.g., `{"content": [{"type": "text", "text": "..."}]}`).
    func extractTextFromMCPJSON(_ json: String) -> String? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            var texts: [String] = []

            // Recursive walker to find all text values.
            func walk(_ value: Any) {
                if let dict = value as? [String: Any] {
                    // Heuristic: check for a "text" key with a string value.
                    if let t = dict["text"] as? String, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        texts.append(t)
                    }
                    // Recurse into all dictionary values.
                    for (_, v) in dict {
                        walk(v)
                    }
                } else if let arr = value as? [Any] {
                    // Recurse into all array elements.
                    for v in arr { walk(v) }
                }
            }

            walk(obj)
            let joined = texts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return joined.isEmpty ? nil : joined
        } catch {
            AppLogger.log("Failed to parse MCP output JSON for text extraction: \(error)", category: .mcp, level: .debug)
            return nil
        }
    }

    /// Builds a complete, user-facing message from a list of completed MCP tool calls.
    /// This is a fallback used when the assistant does not generate a summary message of its own.
    func buildTextFromMCPItems(_ items: [StreamingOutputItem]?) -> String? {
        guard let items else { return nil }
        var sections: [String] = []
        for it in items where it.type == "mcp_call" {
            let status = it.status?.lowercased()
            let resolved = resolveServerLabel(
                serverLabel: it.serverLabel,
                itemServerLabel: it.serverLabel,
                fallbackId: it.id
            )
            if resolved.usedFallback {
                AppLogger.log("buildTextFromMCPItems using fallback label '\(resolved.label)'", category: .mcp, level: .debug)
            }
            let server = resolved.label
            lastMCPServerLabel = server
            let rawName = it.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (rawName?.isEmpty == false) ? rawName! : "MCP tool \(String(it.id.prefix(6)))"

            switch status {
            case "completed", "done":
                let output = it.output ?? ""
                sections.append(renderMCPOutputText(serverLabel: server, toolName: name, rawOutput: output))
            case "failed":
                let errorDescription = describeMCPError(status: status, stringError: nil, structuredError: it.error)
                let failureText = renderMCPFailureText(
                    serverLabel: server,
                    toolName: name,
                    errorDescription: errorDescription,
                    rawArguments: it.arguments
                )
                sections.append(failureText)
            default:
                continue
            }
        }
        let joined = sections.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    /// Builds a user-facing message from approval requests that were part of the final completion payload.
    func buildTextFromApprovalRequests(_ requests: [MCPApprovalRequest]) -> String? {
        guard !requests.isEmpty else { return nil }
        let sections = requests.map { request in
            makeApprovalSummary(
                toolName: request.toolName,
                serverLabel: request.serverLabel,
                rawArguments: request.arguments
            )
        }
        let joined = sections.joined(separator: "\n\n---\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    /// Extracts `MCPApprovalRequest` objects from the final list of streaming output items.
    func extractApprovalRequests(from items: [StreamingOutputItem]?) -> [MCPApprovalRequest] {
        guard let items else { return [] }
        var collected: [MCPApprovalRequest] = []
        var seenIds = Set<String>()
        for item in items where item.type == "mcp_approval_request" {
            guard let tool = item.name else {
                AppLogger.log("Approval item in final output is missing tool name.", category: .mcp, level: .debug)
                continue
            }
            let resolved = resolveServerLabel(
                serverLabel: item.serverLabel,
                itemServerLabel: item.serverLabel,
                fallbackId: item.id
            )
            if resolved.usedFallback {
                AppLogger.log("Approval item missing server_label; using fallback '\(resolved.label)'", category: .mcp, level: .debug)
            }
            let server = resolved.label
            lastMCPServerLabel = server
            let identifier = item.approvalRequestId ?? item.id
            if seenIds.contains(identifier) { continue }
            seenIds.insert(identifier)
            let args = item.arguments ?? "{}"
            let request = MCPApprovalRequest(
                id: identifier,
                toolName: tool,
                serverLabel: server,
                arguments: args,
                status: .pending,
                reason: nil
            )
            collected.append(request)
        }
        return collected
    }

    /// Safely resolves the server label for an MCP event, using fallbacks if the primary label is missing.
    /// This is crucial for maintaining context when stream events omit metadata.
    func resolveServerLabel(serverLabel: String?, itemServerLabel: String?, fallbackId: String?) -> (label: String, usedFallback: Bool) {
        // 1. Prefer the direct `server_label` on the event itself.
        if let direct = trimmedIfNotEmpty(serverLabel) {
            return (direct, false)
        }
        // 2. Fall back to the label on the nested `item` object.
        if let alternate = trimmedIfNotEmpty(itemServerLabel) {
            return (alternate, false)
        }
        // 3. Use the last seen MCP server label in this streaming session.
        if let cached = trimmedIfNotEmpty(lastMCPServerLabel) {
            return (cached, true)
        }
        // 4. Use the server label from the active prompt settings.
        if let promptLabel = trimmedIfNotEmpty(activePrompt.mcpServerLabel) {
            return (promptLabel, true)
        }
        // 5. If it's a known connector, use its name.
        if activePrompt.mcpIsConnector, let connectorId = activePrompt.mcpConnectorId,
           let connector = MCPConnector.connector(for: connectorId) {
            return (connector.name, true)
        }
        // 6. As a last resort, create a label from the item's ID.
        if let fallbackId, !fallbackId.isEmpty {
            let suffix = String(fallbackId.prefix(6))
            return ("MCP \(suffix)", true)
        }
        // 7. Absolute fallback.
        return ("MCP Server", true)
    }

    /// Helper to check if a string is non-nil, non-empty, and returns it after trimming whitespace.
    private func trimmedIfNotEmpty(_ value: String?) -> String? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        return raw
    }

    /// Clears stored preflight and probe health state for a given MCP server label.
    /// This is called after an authentication failure (e.g., 401) to force re-validation on the next request.
    func revokeNotionPreflight(for label: String) {
        let d = UserDefaults.standard
        // Preflight flags (for `sendUserMessage` validation)
        d.set(false, forKey: "mcp_preflight_ok_\(label)")
        d.removeObject(forKey: "mcp_preflight_ok_at_\(label)")
        d.removeObject(forKey: "mcp_preflight_token_hash_\(label)")
        d.removeObject(forKey: "mcp_preflight_user_\(label)")
        // Probe flags (for `list_tools` health check)
        d.set(false, forKey: "mcp_probe_ok_\(label)")
        d.removeObject(forKey: "mcp_probe_ok_at_\(label)")
        d.removeObject(forKey: "mcp_probe_token_hash_\(label)")
        AppLogger.log("Revoked preflight and probe state for '\(label)' due to auth failure.", category: .mcp, level: .warning)
    }
    
    /// Builds a readable description for MCP failures, prioritizing structured error data when available.
    /// - Parameters:
    ///   - status: The `status` field from the event (e.g., "failed").
    ///   - stringError: A simple error string from the event.
    ///   - structuredError: A complex `MCPToolError` object.
    /// - Returns: A formatted, human-readable error string.
    func describeMCPError(status: String?, stringError: String?, structuredError: MCPToolError?) -> String {
        let trimmedStatus = status?.lowercased() == "failed" ? "failed" : nil
        var base = stringError?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Prioritize the detailed message from the structured error object.
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
            
            let headline = base.isEmpty ? "Unknown error" : base
            return metadata.isEmpty ? headline : "\(headline) (\(metadata.joined(separator: ", ")))"
        }

        // Fallback for simpler error shapes.
        if let trimmedStatus {
            return base.isEmpty ? "Unknown error (status \(trimmedStatus))" : "\(base) (status \(trimmedStatus))"
        }

        return base.isEmpty ? "Unknown error" : base
    }

    /// Provides helpful, human-readable guidance for well-known MCP servers when authentication issues are detected.
    func hintForMCPServer(_ serverLabel: String) -> String? {
        let normalized = serverLabel.lowercased()
        if normalized.contains("notion") {
            return "Verify that your Notion integration token is current and that the relevant pages/databases have been shared with the integration."
        }
        if normalized.contains("gmail") {
            return "Try reconnecting your Google account in Settings. The authorization may have expired or been revoked."
        }
        return nil
    }
}
