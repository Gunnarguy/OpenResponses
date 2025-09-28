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
        let errorMessage = chunk.response?.error?.message ?? "An unknown error occurred during streaming"
        let errorCode = chunk.response?.error?.code ?? "unknown"
    AppLogger.log("🚨 [Streaming Error] Code: \(errorCode) - \(errorMessage)", category: .openAI, level: .error)
    AppLogger.log("🔍 [Error Context] Event type: \(chunk.type), Response ID: \(chunk.response?.id ?? "none")", category: .openAI, level: .info)

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
}
