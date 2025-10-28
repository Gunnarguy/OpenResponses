import Foundation
// Import the StreamingEvent model
import SwiftUI  // This should already be there for access to UI types
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A service class responsible for communicating with the OpenAI API.
class OpenAIService: OpenAIServiceProtocol {
    private let apiURL = URL(string: "https://api.openai.com/v1/responses")!
    
    private struct ErrorResponse: Decodable {
        let error: ErrorDetail
    }

    private struct ErrorDetail: Decodable {
        let message: String
    }
    
    /// Sends a chat request to the OpenAI Responses API with the given user message and parameters.
    /// - Parameters:
    ///   - userMessage: The user's input prompt.
    ///   - prompt: The configuration object containing all settings for the request.
    ///   - attachments: An optional array of file attachments.
    ///   - fileData: An optional array of file data to upload directly.
    ///   - fileNames: An optional array of filenames corresponding to the file data.
    ///   - imageAttachments: An optional array of image attachments.
    ///   - previousResponseId: The ID of the previous response for continuity (if any).
    /// - Returns: The decoded OpenAIResponse.
    func sendChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, fileIds: [String]?, imageAttachments: [InputImage]?, previousResponseId: String?) async throws -> OpenAIResponse {
        // Ensure API key is set
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        // Build the request JSON payload from the prompt object
        let requestObject = buildRequestObject(
            for: prompt,
            userMessage: userMessage,
            attachments: attachments,
            fileData: fileData,
            fileNames: fileNames,
            fileIds: fileIds,
            imageAttachments: imageAttachments,
            previousResponseId: previousResponseId,
            stream: false
        )

        // Serialize JSON payload
    let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        
    // Don't print raw JSON here; AnalyticsService handles sanitized/omitted logging centrally
        
        // Prepare URLRequest with authorization header
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 120 // Increased timeout
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Log the API request with detailed information
        AnalyticsService.shared.logAPIRequest(
            url: apiURL,
            method: "POST",
            headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
            body: jsonData
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "responses",
                AnalyticsParameter.requestMethod: "POST",
                AnalyticsParameter.requestSize: jsonData.count,
                AnalyticsParameter.model: prompt.openAIModel,
                AnalyticsParameter.streamingEnabled: false
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        // Check for non-200 status codes and handle errors gracefully
        if httpResponse.statusCode != 200 {
            // Attempt to decode the structured error response from OpenAI
            var errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                // Fallback to a generic status code message if decoding fails
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            
            // Specifically handle rate limiting (429)
            if httpResponse.statusCode == 429 {
                // Extract the retry-after header value if available
                let retryAfterSeconds = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap(Int.init) ?? 60
                throw OpenAIServiceError.rateLimited(retryAfterSeconds, errorMessage)
            }
            
            // Log the detailed error
            AnalyticsService.shared.logAPIResponse(
                url: apiURL,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields,
                body: data
            )
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "responses",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAIAPI"
                ]
            )
            
            // Throw a specific error with the decoded message
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        // Log the successful response
        AnalyticsService.shared.logAPIResponse(
            url: apiURL,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "responses",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count,
                AnalyticsParameter.model: prompt.openAIModel
            ]
        )
        
        // Decode JSON data into OpenAIResponse model
        do {
            let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return apiResponse
        } catch {
            print("Decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Sends a chat request and streams the response back.
    /// - Parameters:
    ///   - userMessage: The user's input prompt.
    ///   - prompt: The configuration object containing all settings for the request.
    ///   - attachments: An optional array of file attachments.
    ///   - fileData: An optional array of file data to upload directly.
    ///   - fileNames: An optional array of filenames corresponding to the file data.
    ///   - imageAttachments: An optional array of image attachments.
    ///   - previousResponseId: The ID of the previous response for continuity.
    /// - Returns: An asynchronous stream of `StreamingEvent` chunks.
    func streamChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, fileIds: [String]?, imageAttachments: [InputImage]?, previousResponseId: String?) -> AsyncThrowingStream<StreamingEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Ensure API key is set
                    guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
                        throw OpenAIServiceError.missingAPIKey
                    }
                    
                    // Build the request JSON payload from the prompt object
                    let requestObject = buildRequestObject(
                        for: prompt,
                        userMessage: userMessage,
                        attachments: attachments,
                        fileData: fileData,
                        fileNames: fileNames,
                        fileIds: fileIds,
                        imageAttachments: imageAttachments,
                        previousResponseId: previousResponseId,
                        stream: true
                    )
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
                    
                    // Avoid printing the full JSON directly to console; it's captured via AnalyticsService with sanitization
                    
                    var request = URLRequest(url: apiURL)
                    request.timeoutInterval = 120
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    
                    // Log the streaming API request
                    AnalyticsService.shared.logAPIRequest(
                        url: apiURL,
                        method: "POST",
                        headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
                        body: jsonData
                    )
                    AnalyticsService.shared.trackEvent(
                        name: AnalyticsEvent.apiRequestSent,
                        parameters: [
                            AnalyticsParameter.endpoint: "responses",
                            AnalyticsParameter.requestMethod: "POST",
                            AnalyticsParameter.requestSize: jsonData.count,
                            AnalyticsParameter.model: prompt.openAIModel,
                            AnalyticsParameter.streamingEnabled: true
                        ]
                    )
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenAIServiceError.invalidResponseData
                    }
                    
                    // Check status code and provide detailed error information
                    if httpResponse.statusCode != 200 {
                        // Collect error response data by reading the bytes
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        
                        // Try to decode structured error message
                        var errorMessage: String
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: errorData) {
                            errorMessage = errorResponse.error.message
                        } else {
                            errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        }
                        
                        // Specifically handle rate limiting (429)
                        if httpResponse.statusCode == 429 {
                            let retryAfterSeconds = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap(Int.init) ?? 60
                            throw OpenAIServiceError.rateLimited(retryAfterSeconds, errorMessage)
                        }
                        
                        // Log the error response
                        AnalyticsService.shared.logAPIResponse(
                            url: apiURL,
                            statusCode: httpResponse.statusCode,
                            headers: httpResponse.allHeaderFields,
                            body: errorData
                        )
                        AnalyticsService.shared.trackEvent(
                            name: AnalyticsEvent.networkError,
                            parameters: [
                                AnalyticsParameter.endpoint: "responses",
                                AnalyticsParameter.statusCode: httpResponse.statusCode,
                                AnalyticsParameter.streamingEnabled: true,
                                AnalyticsParameter.errorCode: httpResponse.statusCode,
                                AnalyticsParameter.errorDomain: "OpenAIStreamingAPI"
                            ]
                        )
                        
                        throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
                    }
                    
                    // Log the initial successful response headers
                    AnalyticsService.shared.trackEvent(
                        name: AnalyticsEvent.apiResponseReceived,
                        parameters: [
                            AnalyticsParameter.endpoint: "responses",
                            AnalyticsParameter.statusCode: httpResponse.statusCode,
                            AnalyticsParameter.streamingEnabled: true,
                            AnalyticsParameter.model: prompt.openAIModel
                        ]
                    )
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let dataString = String(line.dropFirst(6))
                            if dataString == "[DONE]" {
                                // Log the completion of the stream
                                AppLogger.log(
                                    "Stream completed with [DONE] marker",
                                    category: .streaming,
                                    level: .debug
                                )
                                continuation.finish()
                                return
                            }
                            
                            guard let data = dataString.data(using: .utf8) else { continue }
                            
                            do {
                                let decodedChunk = try JSONDecoder().decode(StreamingEvent.self, from: data)
                                
                                // Optimized logging: Only log structured events for important types
                                let importantEventTypes = [
                                    "response.created", "response.completed", "response.failed",
                                    "response.image_generation_call.completed", "response.computer_call.completed"
                                ]
                                
                                if importantEventTypes.contains(decodedChunk.type) {
                                    AnalyticsService.shared.logStreamingEvent(
                                        eventType: decodedChunk.type,
                                        data: dataString,
                                        parsedEvent: decodedChunk
                                    )
                                }
                                
                                // Track analytics only for milestone events to reduce overhead
                                if ["response.created", "response.completed", "response.failed"].contains(decodedChunk.type) {
                                    AnalyticsService.shared.trackEvent(
                                        name: AnalyticsEvent.streamingEventReceived,
                                        parameters: [
                                            AnalyticsParameter.eventType: decodedChunk.type,
                                            AnalyticsParameter.sequenceNumber: decodedChunk.sequenceNumber
                                        ]
                                    )
                                }
                                
                                continuation.yield(decodedChunk)
                            } catch {
                                // Use the structured logging format for decoding errors
                                AppLogger.log(
                                    "Stream decoding error: \(error.localizedDescription)\nData: \(dataString)",
                                    category: .streaming,
                                    level: .warning
                                )
                                
                                // Still log via analytics service for consistency
                                AnalyticsService.shared.logStreamingEvent(
                                    eventType: "decoding_error",
                                    data: dataString,
                                    parsedEvent: ["error": error.localizedDescription]
                                )
                                // Continue processing other chunks even if one fails to decode
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Retrieves a model response with the given ID.
    /// - Parameter responseId: The ID of the response to retrieve.
    /// - Returns: The `OpenAIResponse` object.
    func getResponse(responseId: String) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        let url = URL(string: "https://api.openai.com/v1/responses/\(responseId)")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            print("Get response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Builds default system instructions that are aware of computer use capabilities
    private func buildDefaultComputerUseInstructions(prompt: Prompt) -> String {
        if prompt.enableComputerUse && prompt.openAIModel == "computer-use-preview" {
            return """
You are a precise assistant using a 440x956 iPhone-like screen. Do exactly what the user asks—no guesses.

Core rules:
- If current_url is blank or "about:blank", do not screenshot/wait first. Navigate to a relevant page. For search-like requests ("show me", "find", "search for"), navigate to a global search engine and search the exact query; if a site/URL is named, navigate there directly.
- Take one small, precise action at a time, then screenshot to reassess. Click only clear, visible targets at their center. If you can’t find it, say so (don’t guess).
- Never do more than 2 consecutive waits. If nothing changes, take a concrete step (navigate/scroll/click) instead.
- If a cookie/consent banner blocks content, click the visible "Accept all" (or equivalent) before proceeding.

Available actions: click, double_click, scroll, type, keypress, wait, screenshot, move, drag.
"""
        } else {
            return "You are a helpful assistant."
        }
    }
    
    /// Builds system instructions; for computer-use-preview we prefer action-only loops and omit instructions unless explicitly provided
    private func buildInstructions(prompt: Prompt) -> String {
        // For CUA, default to no system instructions unless user explicitly set them
        if prompt.enableComputerUse && prompt.openAIModel == "computer-use-preview" {
            return prompt.systemInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // If user provided custom instructions, use them
        let userInstructions = prompt.systemInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userInstructions.isEmpty && userInstructions != "You are a helpful assistant." {
            return userInstructions
        }
        
        // Build dynamic instructions based on enabled tools
        var instructions: [String] = []
        
        // Base instruction
        instructions.append("You are a helpful assistant.")
        
        // Add MCP-specific guidance if MCP is enabled
        // Note: The model automatically receives tool schemas from OpenAI's framework
        // We just need to encourage proactive usage
        if prompt.enableMCPTool {
            if prompt.mcpIsConnector, let connectorId = prompt.mcpConnectorId {
                // Connector-specific instructions
                let connectorName = MCPConnector.library.first(where: { $0.id == connectorId })?.name ?? connectorId
                instructions.append("\n\nYou have access to \(connectorName) through an MCP connector. Use the available tools proactively when relevant to help the user.")
            } else if !prompt.mcpServerLabel.isEmpty {
                // Remote server instructions - be more directive about search capabilities
                let searchGuidance: String
                if prompt.mcpServerLabel.lowercased().contains("notion") {
                    searchGuidance = "When the user asks about their content, databases, pages, or workspace items, immediately use the search tools to find what they're looking for. Don't ask for IDs or URLs first—search proactively."
                } else {
                    searchGuidance = "Use the available tools proactively when relevant to help the user."
                }
                instructions.append("\n\nYou have access to an MCP server (\(prompt.mcpServerLabel)). The available tools are automatically provided to you. \(searchGuidance)")
            }
        }
        
        // Add file search guidance if enabled
        if prompt.enableFileSearch, let vectorStoreIds = prompt.selectedVectorStoreIds, !vectorStoreIds.isEmpty {
            instructions.append("\n\nYou have access to file_search to query uploaded documents. Use it when the user's question relates to the available files.")
        }
        
        // Add code interpreter guidance if enabled
        if prompt.enableCodeInterpreter {
            instructions.append("\n\nYou can run Python code via code_interpreter for analysis, calculations, and file processing.")
        }
        
        return instructions.joined()
    }

    /// Builds the request dictionary from a Prompt object and other parameters.
    /// This function is the central point for constructing the JSON payload for the OpenAI API.
    /// It intelligently assembles input messages, tools, and parameters based on the `Prompt` settings and model compatibility.
    private func buildRequestObject(for prompt: Prompt, userMessage: String?, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, fileIds: [String]?, imageAttachments: [InputImage]?, previousResponseId: String?, stream: Bool, customInput: [[String: Any]]? = nil) -> [String: Any] {
        var requestObject = baseRequestMetadata(for: prompt, stream: stream)
        
        // If customInput is provided (e.g., for MCP approval response), use it directly
        if let customInput = customInput {
            requestObject["input"] = customInput
        } else {
            requestObject["input"] = buildInputMessages(
                for: prompt,
                userMessage: userMessage ?? "",
                attachments: attachments,
                fileData: fileData,
                fileNames: fileNames,
                fileIds: fileIds,
                imageAttachments: imageAttachments
            )
        }

        let (tools, forceImageToolChoice) = assembleTools(
            for: prompt,
            userMessage: userMessage ?? "",
            isStreaming: stream
        )

        if let encodedTools = encodeTools(tools) {
            requestObject["tools"] = encodedTools
        }

        let hasComputerTool = tools.contains { if case .computer = $0 { return true } else { return false } }
        let includeArray = buildIncludeArray(for: prompt, hasComputerTool: hasComputerTool)
        if !includeArray.isEmpty {
            requestObject["include"] = includeArray
        }

        mergeTopLevelParameters(for: prompt, into: &requestObject)

        if let reasoning = buildReasoningObject(for: prompt) {
            requestObject["reasoning"] = reasoning
        }

        if let prevId = previousResponseId {
            requestObject["previous_response_id"] = prevId
        }

        if prompt.backgroundMode {
            requestObject["background"] = true
        }

        applyToolChoice(
            for: prompt,
            forceImageToolChoice: forceImageToolChoice,
            into: &requestObject
        )

        if let textFormat = buildTextFormat(for: prompt) {
            requestObject["text"] = textFormat
        }

        if let promptObject = buildPromptObject(for: prompt) {
            requestObject["prompt"] = promptObject
        }

        return requestObject
    }

    /// Builds base metadata for a request, adding instructions, store flag, and stream options.
    private func baseRequestMetadata(for prompt: Prompt, stream: Bool) -> [String: Any] {
        var metadata: [String: Any] = [
            "model": prompt.openAIModel,
            "store": true
        ]

        let instructions = buildInstructions(prompt: prompt)
        if !instructions.isEmpty, !(prompt.openAIModel == "computer-use-preview" && instructions == "You are a helpful assistant.") {
            metadata["instructions"] = instructions
        }

        if stream {
            metadata["stream"] = true
            metadata["stream_options"] = ["include_obfuscation": false]
        }

        return metadata
    }

    /// Assembles the tool list for the given request and returns whether tool choice should be forced.
    private func assembleTools(for prompt: Prompt, userMessage: String, isStreaming: Bool) -> ([APICapabilities.Tool], Bool) {
        var tools = buildTools(for: prompt, userMessage: userMessage, isStreaming: isStreaming)
        var forceImageToolChoice = false

        if prompt.openAIModel == "computer-use-preview" && !tools.contains(where: { if case .computer = $0 { return true } else { return false } }) {
            let environment: String
            #if os(iOS)
            environment = "browser"
            #elseif os(macOS)
            environment = "mac"
            #else
            environment = "browser"
            #endif
            let screenSize: CGSize
            #if os(iOS)
            screenSize = CGSize(width: 440, height: 956)
            #elseif os(macOS)
            screenSize = CGSize(width: 1920, height: 1080)
            #else
            screenSize = CGSize(width: 1920, height: 1080)
            #endif
            tools.append(.computer(
                environment: environment,
                displayWidth: Int(screenSize.width),
                displayHeight: Int(screenSize.height)
            ))
        }

        if prompt.openAIModel == "computer-use-preview" {
            tools.removeAll { tool in
                if case .computer = tool { return false }
                return true
            }
        }

        if shouldForceImageGeneration(for: prompt, userMessage: userMessage, availableTools: tools) {
            let hasImageTool = tools.contains { if case .imageGeneration = $0 { return true } else { return false } }
            if hasImageTool {
                tools = tools.filter { if case .imageGeneration = $0 { return true } else { return false } }
                forceImageToolChoice = true
                AppLogger.log("Image intent detected — restricting tools to image_generation for this turn", category: .openAI, level: .info)
            }
        }

        AppLogger.log("Built tools array: \(tools.count) tools - \(tools)", category: .openAI, level: .info)
        return (tools, forceImageToolChoice)
    }

    /// Encodes tools into a JSON-compatible array payload.
    private func encodeTools(_ tools: [APICapabilities.Tool]) -> [Any]? {
        guard !tools.isEmpty else {
            AppLogger.log("No tools to include in request", category: .openAI, level: .info)
            return nil
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let toolsData = try encoder.encode(tools)
            if let json = try JSONSerialization.jsonObject(with: toolsData) as? [Any] {
                AppLogger.log("Successfully added tools to request", category: .openAI, level: .info)
                return json
            }
            return nil
        } catch {
            AppLogger.log("Failed to encode tools: \(error)", category: .openAI, level: .error)
            return nil
        }
    }

    /// Merges top-level sampling parameters into the request and applies model-specific overrides.
    private func mergeTopLevelParameters(for prompt: Prompt, into request: inout [String: Any]) {
        var parameters = buildParameters(for: prompt)
        if prompt.openAIModel == "computer-use-preview" {
            parameters["truncation"] = "auto"
        }

        for (key, value) in parameters {
            request[key] = value
        }
    }

    /// Applies explicit or inferred tool choice values.
    private func applyToolChoice(for prompt: Prompt, forceImageToolChoice: Bool, into request: inout [String: Any]) {
        if !prompt.toolChoice.isEmpty && prompt.toolChoice != "auto" {
            request["tool_choice"] = prompt.toolChoice
            return
        }

        if forceImageToolChoice {
            request["tool_choice"] = "required"
            AppLogger.log("Auto tool_choice override → required (only image_generation available)", category: .openAI, level: .info)
        }
    }

    /// Detects if we should force the image_generation tool for this turn based on the user message.
    /// - Conditions:
    ///   - Image generation is enabled for the prompt and supported for the model/streaming mode
    ///   - The built tools include image_generation
    ///   - The user's message strongly indicates intent to create an image (not just analyze)
    ///   - The selected model is not the dedicated computer-use model
    private func shouldForceImageGeneration(for prompt: Prompt, userMessage: String, availableTools: [APICapabilities.Tool]) -> Bool {
        guard prompt.enableImageGeneration else { return false }
        guard availableTools.contains(where: { if case .imageGeneration = $0 { return true } else { return false } }) else { return false }
        guard prompt.openAIModel != "computer-use-preview" else { return false }

        let text = userMessage.lowercased()
        // Common verbs and nouns indicating image creation
        let positiveHints = [
            "generate an image", "generate a picture", "create an image", "create a picture", "draw ", "sketch ",
            "make an image", "make a picture", "illustration", "poster", "logo", "icon", "wallpaper", "artwork",
            "render ", "paint ", "photorealistic", "photo of ", "image of ", "picture of ", "cover art", "thumbnail"
        ]
        // Phrases that imply analysis rather than generation
        let negativeHints = ["analyze this image", "describe this image", "caption this image", "what is in this image"]

        let hasPositive = positiveHints.contains { text.contains($0) }
        let hasNegative = negativeHints.contains { text.contains($0) }
        return hasPositive && !hasNegative
    }

    /// Constructs the `input` array for the request, including developer instructions and user content.
    private func buildInputMessages(for prompt: Prompt, userMessage: String, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, fileIds: [String]?, imageAttachments: [InputImage]?) -> [[String: Any]] {
        var inputMessages: [[String: Any]] = []
        
        // Add developer instructions if provided
        if !prompt.developerInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputMessages.append(["role": "developer", "content": prompt.developerInstructions])
        }
        
        // Handle user message with attachments and/or images
    // Always use structured content array with input_text to match API guidance
    var userContent: Any = [["type": "input_text", "text": userMessage]]
        
        // Check if we have any attachments or images to create a content array
        let hasFileAttachments = attachments?.isEmpty == false
        let hasImageAttachments = imageAttachments?.isEmpty == false
        let hasDirectFileData = fileData?.isEmpty == false
        let hasUploadedFileIds = fileIds?.isEmpty == false
        if hasFileAttachments || hasImageAttachments || hasDirectFileData || hasUploadedFileIds {
            var contentArray: [[String: Any]] = [["type": "input_text", "text": userMessage]]
            
            // Add file attachments (file_id references)
            if let attachments = attachments, !attachments.isEmpty {
                let validatedAttachments = attachments.compactMap { attachment -> [String: Any]? in
                    guard let fileId = attachment["file_id"] as? String else {
                        AppLogger.log("Missing file_id in attachment: \(attachment)", category: .openAI, level: .warning)
                        return nil
                    }
                    return ["type": "input_file", "file_id": fileId]
                }
                
                if !validatedAttachments.isEmpty {
                    contentArray.append(contentsOf: validatedAttachments)
                }
            }
            
            // Add uploaded file IDs (from Files API upload)
            if let fileIds = fileIds, !fileIds.isEmpty {
                for fileId in fileIds {
                    let fileContent: [String: Any] = [
                        "type": "input_file",
                        "file_id": fileId
                    ]
                    contentArray.append(fileContent)
                }
            }
            
            // Add direct file uploads (file_data) - only for small files
            if let fileData = fileData, let fileNames = fileNames, !fileData.isEmpty, !fileNames.isEmpty {
                for (index, data) in fileData.enumerated() {
                    guard index < fileNames.count else {
                        AppLogger.log("File data and names count mismatch", category: .openAI, level: .warning)
                        break
                    }
                    
                    let base64String = data.base64EncodedString()
                    let fileContent: [String: Any] = [
                        "type": "input_file",
                        "file_data": base64String,
                        "filename": fileNames[index]
                    ]
                    contentArray.append(fileContent)
                }
            }
            
            // Add image attachments
            if let imageAttachments = imageAttachments, !imageAttachments.isEmpty {
                let imageContentArray = imageAttachments.compactMap { inputImage -> [String: Any]? in
                    var imageContent: [String: Any] = [
                        "type": "input_image",
                        "detail": inputImage.detail
                    ]
                    
                    if let imageUrl = inputImage.imageUrl {
                        imageContent["image_url"] = imageUrl
                    } else if let fileId = inputImage.fileId {
                        imageContent["file_id"] = fileId
                    } else {
                        AppLogger.log("InputImage missing both image_url and file_id", category: .openAI, level: .warning)
                        return nil
                    }
                    
                    return imageContent
                }
                
                if !imageContentArray.isEmpty {
                    contentArray.append(contentsOf: imageContentArray)
                }
            }
            
            userContent = contentArray
        }
        
        inputMessages.append(["role": "user", "content": userContent])
        return inputMessages
    }

    /// Assembles the `tools` array for the request, checking for model compatibility.
    private func buildTools(for prompt: Prompt, userMessage: String, isStreaming: Bool) -> [APICapabilities.Tool] {
        var tools: [APICapabilities.Tool] = []
        
        AppLogger.log("Building tools for prompt: enableComputerUse=\(prompt.enableComputerUse), model=\(prompt.openAIModel)", category: .openAI, level: .info)
        let compatibilityService = ModelCompatibilityService.shared
        let isDeepResearch = prompt.openAIModel.contains("deep-research")

        if prompt.enableWebSearch {
            if isDeepResearch {
                // Deep research models require the preview web search tool
                tools.append(.webSearchPreview)
            } else if compatibilityService.isToolSupported(APICapabilities.ToolType.webSearch, for: prompt.openAIModel, isStreaming: isStreaming) {
                tools.append(.webSearch)
            }
        }

        if prompt.enableCodeInterpreter, compatibilityService.isToolSupported(APICapabilities.ToolType.codeInterpreter, for: prompt.openAIModel, isStreaming: isStreaming) {
            // API currently only accepts "auto" for container.type; enforce to avoid 400s
            let requestedContainer = prompt.codeInterpreterContainerType
            let containerType = (requestedContainer == "auto" || requestedContainer.isEmpty) ? "auto" : "auto"

            // Parse optional comma-separated file IDs into a sanitized array
            let parsedIds = prompt.codeInterpreterPreloadFileIds?
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let fileIds: [String]? = (parsedIds?.isEmpty == false) ? parsedIds : nil

            tools.append(.codeInterpreter(containerType: containerType, fileIds: fileIds))
        }

        if prompt.enableImageGeneration, compatibilityService.isToolSupported(APICapabilities.ToolType.imageGeneration, for: prompt.openAIModel, isStreaming: isStreaming) {
            tools.append(.imageGeneration(model: "gpt-image-1", size: "auto", quality: "high", outputFormat: "png"))
        }

        if prompt.enableFileSearch, compatibilityService.isToolSupported(APICapabilities.ToolType.fileSearch, for: prompt.openAIModel, isStreaming: isStreaming) {
            let vectorStoreIds = (prompt.selectedVectorStoreIds ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if !vectorStoreIds.isEmpty {
                // Build ranking options if configured
                var rankingOptions: RankingOptions? = nil
                if let ranker = prompt.fileSearchRanker, !ranker.isEmpty,
                   let threshold = prompt.fileSearchScoreThreshold {
                    rankingOptions = RankingOptions(ranker: ranker, scoreThreshold: threshold)
                }
                
                tools.append(.fileSearch(
                    vectorStoreIds: vectorStoreIds,
                    maxNumResults: prompt.fileSearchMaxResults,
                    rankingOptions: rankingOptions,
                    filters: nil // TODO: Add attribute filter support from UI
                ))
            }
        }

        if prompt.enableComputerUse, compatibilityService.isToolSupported(APICapabilities.ToolType.computer, for: prompt.openAIModel, isStreaming: isStreaming) {
            AppLogger.log("Computer tool is enabled and supported", category: .openAI, level: .info)
            // Computer Use tool with proper API parameters
            // Detect environment based on platform
            let environment: String
            #if os(iOS)
            environment = "browser"  // Use browser environment for iOS
            #elseif os(macOS)
            environment = "mac"      // Use mac environment for macOS
            #else
            environment = "browser"  // Default to browser for other platforms
            #endif
            
            // Get screen dimensions (use reasonable defaults to avoid main thread issues)
            let screenSize: CGSize
            #if os(iOS)
            screenSize = CGSize(width: 440, height: 956) // Default iPhone size
            #elseif os(macOS)
            screenSize = CGSize(width: 1920, height: 1080) // Default Mac size
            #else
            screenSize = CGSize(width: 1920, height: 1080) // Default size
            #endif
            
            tools.append(.computer(
                environment: environment,
                displayWidth: Int(screenSize.width),
                displayHeight: Int(screenSize.height)
            ))
            AppLogger.log("Added computer tool with environment=\(environment), width=\(Int(screenSize.width)), height=\(Int(screenSize.height))", category: .openAI, level: .info)
        } else {
            AppLogger.log("Computer tool not added: enabled=\(prompt.enableComputerUse), supported=\(compatibilityService.isToolSupported(APICapabilities.ToolType.computer, for: prompt.openAIModel, isStreaming: isStreaming))", category: .openAI, level: .info)
        }

        if prompt.enableCustomTool, compatibilityService.isToolSupported(APICapabilities.ToolType.function, for: prompt.openAIModel, isStreaming: isStreaming) {
            let schema: APICapabilities.JSONSchema
            if let data = prompt.customToolParametersJSON.data(using: .utf8),
               let parsedDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                schema = APICapabilities.JSONSchema(parsedDict)
            } else {
                schema = APICapabilities.JSONSchema(["type": "object", "properties": [:], "additionalProperties": true])
            }
            
            let function = APICapabilities.Function(
                name: prompt.customToolName,
                description: prompt.customToolDescription,
                parameters: schema,
                strict: false
            )
            tools.append(.function(function: function))
        }
        
        // MCP Tool (Connector or Remote Server)
        if prompt.enableMCPTool, compatibilityService.isToolSupported(APICapabilities.ToolType.mcp, for: prompt.openAIModel, isStreaming: isStreaming) {
            // Check if this is a connector (OpenAI-maintained) or remote server (custom)
            if prompt.mcpIsConnector {
                // Connector path: requires connector_id and OAuth token from keychain
                if let connectorId = prompt.mcpConnectorId, !connectorId.isEmpty {
                    
                    // BULLETPROOF CHECK: Verify this is a REAL OpenAI connector
                    // Derive IDs from MCPConnector.library to avoid drift with hardcoded lists.
                    let validConnectors = Set(
                        MCPConnector.library
                            .filter { $0.requiresRemoteServer == false }
                            .map { $0.id }
                    )
                    
                    if validConnectors.contains(connectorId) {
                        // Valid connector - proceed with configuration
                        // Load OAuth token from keychain with pattern: "mcp_connector_{connectorId}"
                        let authKey = "mcp_connector_\(connectorId)"
                        let authorization = KeychainService.shared.load(forKey: authKey)
                        
                        // Parse allowed tools if specified
                        var allowedTools: [String]? = nil
                        if !prompt.mcpAllowedTools.isEmpty {
                            allowedTools = prompt.mcpAllowedTools
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                        }
                        
                        // Get approval setting (default to "never") and normalize for API
                        let requireApproval = normalizeMCPApproval(prompt.mcpRequireApproval)
                        
                        // Get connector name from library for logging
                        let connectorName = MCPConnector.library.first(where: { $0.id == connectorId })?.name ?? connectorId
                        
                        tools.append(.mcp(
                            serverLabel: connectorName,
                            serverURL: nil, // Connectors use connector_id, not server_url
                            connectorId: connectorId,
                            authorization: authorization,
                            headers: nil,
                            requireApproval: requireApproval,
                            allowedTools: allowedTools,
                            serverDescription: nil
                        ))
                        
                        AppLogger.log("Added MCP connector: \(connectorName) (id: \(connectorId))", category: .openAI, level: .info)
                    } else {
                        // Invalid connector ID - log error and skip
                        AppLogger.log("⚠️ INVALID CONNECTOR: '\(connectorId)' does not exist in OpenAI's system. Check MCPConnector.swift configuration.", category: .openAI, level: .error)
                    }
                } else {
                    AppLogger.log("MCP connector enabled but missing connector_id", category: .openAI, level: .warning)
                }
            } else {
                // Remote server path: requires server_url and optional auth
                if !prompt.mcpServerLabel.isEmpty && !prompt.mcpServerURL.isEmpty {
                    let authResolution = resolveMCPAuthorization(for: prompt)

                    // Parse allowed tools if specified
                    var allowedTools: [String]? = nil
                    if !prompt.mcpAllowedTools.isEmpty {
                        allowedTools = prompt.mcpAllowedTools
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    }

                    // Determine the approval requirement (default to "never") and normalize for API
                    let requireApproval = normalizeMCPApproval(prompt.mcpRequireApproval)
                    let serverDescription = descriptionForMCPServer(label: prompt.mcpServerLabel)

                    tools.append(.mcp(
                        serverLabel: prompt.mcpServerLabel,
                        serverURL: prompt.mcpServerURL,
                        connectorId: nil, // Remote servers don't use connector_id
                        authorization: authResolution.authorization,
                        headers: authResolution.headers,
                        requireApproval: requireApproval,
                        allowedTools: allowedTools,
                        serverDescription: serverDescription
                    ))

                    if let headers = authResolution.headers {
                        AppLogger.log("Added MCP remote server: \(prompt.mcpServerLabel) with \(headers.count) custom headers", category: .openAI, level: .info)
                    } else if let authorization = authResolution.authorization {
                        AppLogger.log("Added MCP remote server: \(prompt.mcpServerLabel) using authorization token (\(authorization.count) chars)", category: .openAI, level: .info)
                    } else {
                        AppLogger.log("Added MCP remote server: \(prompt.mcpServerLabel) with no auth (public server)", category: .openAI, level: .info)
                    }
                } else {
                    AppLogger.log("MCP remote server enabled but missing configuration (label or URL)", category: .openAI, level: .warning)
                }
            }
        }
        
        // Ensure deep-research models always include at least one of the required tools
        // per API: one of 'web_search_preview' or 'file_search' must be present.
        if isDeepResearch {
            let hasPreviewSearch = tools.contains { if case .webSearchPreview = $0 { return true } else { return false } }
            let hasFileSearch = tools.contains { if case .fileSearch = $0 { return true } else { return false } }
            if !hasPreviewSearch && !hasFileSearch {
                tools.append(.webSearchPreview)
                AppLogger.log("Deep-research model detected — auto-adding web_search_preview tool to satisfy API requirements", category: .openAI, level: .info)
            }
        }

        return tools
    }

    private func resolveMCPAuthorization(for prompt: Prompt) -> (authorization: String?, headers: [String: String]?) {
        // Determine desired auth header key (default to Authorization) and normalize formatting like sanitizeMCPHeaders()
        let desiredKeyRaw = prompt.mcpAuthHeaderKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let desiredKeyBase = desiredKeyRaw.isEmpty ? "Authorization" : desiredKeyRaw
        let normalizedDesiredKey = desiredKeyBase.split(separator: "-")
            .map { part in
                var lower = part.lowercased()
                if lower == "id" { lower = "ID" }
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: "-")

        // Prefer structured secure headers so we can support multiple header values.
        let secureHeaders = prompt.secureMCPHeaders
        if !secureHeaders.isEmpty {
            var sanitizedHeaders = sanitizeMCPHeaders(secureHeaders, serverLabel: prompt.mcpServerLabel)

            var topLevelAuth: String? = nil
        if normalizedDesiredKey == "Authorization" {
            if let tokenVal = sanitizedHeaders["Authorization"] {
                topLevelAuth = ensureBearerPrefix(tokenVal)
                // Always remove Authorization header to avoid API 400:
                // "Cannot specify both 'authorization' parameter and 'Authorization' header."
                sanitizedHeaders.removeValue(forKey: "Authorization")
                if prompt.mcpKeepAuthInHeaders {
                    AppLogger.log("mcpKeepAuthInHeaders is ON but ignored: using top-level authorization only to satisfy OpenAI API constraints", category: .mcp, level: .warning)
                }
            }
        } else {
                // Custom header key path: keep auth only in headers under custom key. Remove Authorization if present.
                if let moved = sanitizedHeaders.removeValue(forKey: "Authorization"), sanitizedHeaders[normalizedDesiredKey] == nil {
                    sanitizedHeaders[normalizedDesiredKey] = ensureBearerPrefix(moved)
                }
                topLevelAuth = nil
            }

            let headerKeys = sanitizedHeaders.keys.sorted().joined(separator: ", ")
            AppLogger.log("Resolved MCP auth for '\(prompt.mcpServerLabel)': authHeaderKey=\(normalizedDesiredKey), topLevelAuth=\(topLevelAuth != nil), keepAuthInHeaders=\(prompt.mcpKeepAuthInHeaders), headerKeys=[\(headerKeys)]", category: .openAI, level: .debug)
            return (topLevelAuth, sanitizedHeaders.isEmpty ? nil : sanitizedHeaders)
        }

        // Fall back to legacy string-based authorization storage.
        var legacyAuth: String? = nil
        if let stored = KeychainService.shared.load(forKey: "mcp_manual_\(prompt.mcpServerLabel)"), !stored.isEmpty {
            legacyAuth = stored
        } else if !prompt.mcpHeaders.isEmpty {
            legacyAuth = prompt.mcpHeaders
        }

        if let auth = legacyAuth, !auth.isEmpty {
            if normalizedDesiredKey == "Authorization" {
                AppLogger.log("Resolved legacy MCP authorization token (top-level) for label \(prompt.mcpServerLabel)", category: .openAI, level: .debug)
                return (ensureBearerPrefix(auth), nil)
            } else {
                // Put legacy auth under the custom header key
                var headers: [String: String] = [:]
                headers[normalizedDesiredKey] = ensureBearerPrefix(auth)
                let sanitized = sanitizeMCPHeaders(headers, serverLabel: prompt.mcpServerLabel)
                let keys = sanitized.keys.sorted().joined(separator: ", ")
                AppLogger.log("Resolved legacy MCP authorization token (headers-only: \(normalizedDesiredKey)) for label \(prompt.mcpServerLabel); headerKeys=[\(keys)]", category: .openAI, level: .debug)
                return (nil, sanitized)
            }
        }

        return (nil, nil)
    }

    private func sanitizeMCPHeaders(_ headers: [String: String], serverLabel: String) -> [String: String] {
        var sanitized: [String: String] = [:]

        for (key, value) in headers {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else { continue }

            // Normalize header capitalization to avoid duplicates (e.g., authorization vs Authorization)
            let normalizedKey = key.split(separator: "-")
                .map { part in
                    var lower = part.lowercased()
                    if lower == "id" { lower = "ID" }
                    return lower.prefix(1).uppercased() + lower.dropFirst()
                }
                .joined(separator: "-")
            sanitized[normalizedKey] = trimmedValue
        }

        if let auth = sanitized["Authorization"] {
            sanitized["Authorization"] = ensureBearerPrefix(auth)
        }

        // Notion requires a version header; default it when missing.
        if serverLabel.lowercased().contains("notion"), sanitized["Notion-Version"] == nil {
            AppLogger.log("Notion MCP configuration missing Notion-Version header; using 2022-06-28", category: .mcp, level: .warning)
            sanitized["Notion-Version"] = "2022-06-28"
        }

        return sanitized
    }

    // Normalize UI/legacy approval strings to API-compliant values.
    private func normalizeMCPApproval(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "", "auto", "allow": return "never"
        case "prompt", "ask", "review", "confirm": return "always"
        case "always", "never": return trimmed
        case "deny": return "always"
        default: return trimmed
        }
    }

    private func ensureBearerPrefix(_ token: String) -> String {
        if token.lowercased().hasPrefix("bearer ") {
            return token
        }
        return "Bearer \(token)"
    }

    private func descriptionForMCPServer(label: String) -> String? {
        let normalized = label.lowercased()
        if normalized.contains("notion") {
            return "Official Notion MCP server"
        }
        if normalized.contains("filesystem") {
            return "Local filesystem MCP server"
        }
        return nil
    }

    /// Gathers various API parameters based on model compatibility.
    private func buildParameters(for prompt: Prompt) -> [String: Any] {
        var parameters: [String: Any] = [:]
        let compatibilityService = ModelCompatibilityService.shared

        if compatibilityService.isParameterSupported("temperature", for: prompt.openAIModel) {
            parameters["temperature"] = prompt.temperature
        }
        
        if compatibilityService.isParameterSupported("top_p", for: prompt.openAIModel) {
            parameters["top_p"] = prompt.topP
        }
        
        if compatibilityService.isParameterSupported("parallel_tool_calls", for: prompt.openAIModel) {
            parameters["parallel_tool_calls"] = prompt.parallelToolCalls
        }
        
        if compatibilityService.isParameterSupported("max_output_tokens", for: prompt.openAIModel) && prompt.maxOutputTokens > 0 {
            parameters["max_output_tokens"] = prompt.maxOutputTokens
        }
        
        if compatibilityService.isParameterSupported("truncation", for: prompt.openAIModel) && !prompt.truncationStrategy.isEmpty {
            parameters["truncation"] = prompt.truncationStrategy
        }
        
        // Add missing parameters that exist in UI but weren't in request
        if compatibilityService.isParameterSupported("service_tier", for: prompt.openAIModel) && !prompt.serviceTier.isEmpty {
            parameters["service_tier"] = prompt.serviceTier
        }
        
        if compatibilityService.isParameterSupported("top_logprobs", for: prompt.openAIModel) && prompt.topLogprobs > 0 {
            // Avoid logprobs on reasoning models to prevent API errors
            let caps = compatibilityService.getCapabilities(for: prompt.openAIModel)
            if caps?.supportsReasoningEffort == true {
                AppLogger.log("Omitting top_logprobs param for reasoning model: \(prompt.openAIModel)", category: .openAI, level: .info)
            } else {
                parameters["top_logprobs"] = prompt.topLogprobs
            }
        }
        
        if compatibilityService.isParameterSupported("user_identifier", for: prompt.openAIModel) && !prompt.userIdentifier.isEmpty {
            parameters["user"] = prompt.userIdentifier
        }
        
        if compatibilityService.isParameterSupported("max_tool_calls", for: prompt.openAIModel) && prompt.maxToolCalls > 0 {
            parameters["max_tool_calls"] = prompt.maxToolCalls
        }
        
        // Parse metadata JSON string into a dictionary
        if let metadataString = prompt.metadata, !metadataString.isEmpty {
            do {
                if let data = metadataString.data(using: .utf8),
                   let parsedMetadata = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    parameters["metadata"] = parsedMetadata
                }
            } catch {
                print("Invalid metadata JSON format, skipping: \(error)")
            }
        }
        
        return parameters
    }

    /// Constructs the `reasoning` object for models that support it.
    private func buildReasoningObject(for prompt: Prompt) -> [String: Any]? {
        let compatibilityService = ModelCompatibilityService.shared
        // Special-case: computer-use-preview supports reasoning.summary without effort
        if prompt.openAIModel == "computer-use-preview" {
            // Default to concise summary for visibility into actions unless the user overrides.
            let summary = prompt.reasoningSummary.isEmpty ? "concise" : prompt.reasoningSummary
            return ["summary": summary]
        }

        guard compatibilityService.isParameterSupported("reasoning_effort", for: prompt.openAIModel), !prompt.reasoningEffort.isEmpty else {
            return nil
        }

        var reasoningObject: [String: Any] = ["effort": prompt.reasoningEffort]

        // Add reasoning summary for specific reasoning models
        if (prompt.openAIModel.starts(with: "o") || prompt.openAIModel.starts(with: "gpt-5")) && !prompt.reasoningSummary.isEmpty {
            reasoningObject["summary"] = prompt.reasoningSummary
        }

        return reasoningObject
    }
    
    /// Constructs the `include` array from boolean properties in the prompt.
    /// - Parameters:
    ///   - prompt: The active prompt settings.
    ///   - hasComputerTool: Whether the current request includes the computer tool.
    private func buildIncludeArray(for prompt: Prompt, hasComputerTool: Bool) -> [String] {
        var includeArray: [String] = []
        
        if prompt.includeCodeInterpreterOutputs {
            // Note: code_interpreter outputs are not supported in the current API
            // This option is kept for UI compatibility but won't be added to the request
        }
        
        if prompt.includeFileSearchResults {
            includeArray.append("file_search_call.results")
        }
        
        if prompt.includeWebSearchResults {
            includeArray.append("web_search_call.results")
        }
        
        if prompt.includeOutputLogprobs {
            // Some reasoning-capable models do not support returning logprobs in the include payload
            // (API returns 400: "logprobs are not supported with reasoning models.")
            let caps = ModelCompatibilityService.shared.getCapabilities(for: prompt.openAIModel)
            let disallowForReasoning = (caps?.supportsReasoningEffort == true)
            if !disallowForReasoning {
                includeArray.append("message.output_text.logprobs")
            } else {
                AppLogger.log("Omitting include for output logprobs due to reasoning model: \(prompt.openAIModel)", category: .openAI, level: .info)
            }
        }
        
        if prompt.includeReasoningContent {
            // Only reasoning-capable models support encrypted reasoning content include
            let caps = ModelCompatibilityService.shared.getCapabilities(for: prompt.openAIModel)
            if caps?.supportsReasoningEffort == true {
                includeArray.append("reasoning.encrypted_content")
            } else {
                AppLogger.log("Omitting include for reasoning.encrypted_content (unsupported by model: \(prompt.openAIModel))", category: .openAI, level: .info)
            }
        }
        
        // Include computer tool outputs only when the computer tool is actually added for this request
        // or when using the dedicated computer-use model (which always uses the computer tool).
        if hasComputerTool || prompt.openAIModel == "computer-use-preview" {
            if prompt.enableComputerUse || prompt.includeComputerUseOutput {
                includeArray.append("computer_call_output.output.image_url")
            }
        }
        
        if prompt.includeInputImageUrls {
            includeArray.append("message.input_image.image_url")
        }
        
        return includeArray
    }
    
    /// Constructs the `text` format object for structured outputs if JSON schema is enabled.
    private func buildTextFormat(for prompt: Prompt) -> [String: Any]? {
        guard prompt.textFormatType == "json_schema" && !prompt.jsonSchemaName.isEmpty else {
            return nil
        }
        
        var schema: [String: Any] = [:]
        
        // Parse the JSON schema content if provided
        if !prompt.jsonSchemaContent.isEmpty {
            do {
                if let data = prompt.jsonSchemaContent.data(using: .utf8),
                   let parsedSchema = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    schema = parsedSchema
                }
            } catch {
                print("Invalid JSON schema format, using empty schema: \(error)")
                schema = ["type": "object", "properties": [:]]
            }
        } else {
            schema = ["type": "object", "properties": [:]]
        }
        
        return [
            "format": [
                "type": "json_schema",
                "name": prompt.jsonSchemaName,
                "description": prompt.jsonSchemaDescription.isEmpty ? prompt.jsonSchemaName : prompt.jsonSchemaDescription,
                "strict": prompt.jsonSchemaStrict,
                "schema": schema
            ]
        ]
    }
    
    /// Constructs the `prompt` object for published prompts if enabled.
    private func buildPromptObject(for prompt: Prompt) -> [String: Any]? {
        guard prompt.enablePublishedPrompt && !prompt.publishedPromptId.isEmpty else {
            return nil
        }
        
        var promptObject: [String: Any] = [
            "id": prompt.publishedPromptId
        ]
        
        if !prompt.publishedPromptVersion.isEmpty {
            promptObject["version"] = prompt.publishedPromptVersion
        }
        
        return promptObject
    }

    /// Sends the output of a function call back to the API to get a final response.
    /// - Parameters:
    ///   - call: The original `OutputItem` that represented the function call.
    ///   - output: The string result from executing the function locally.
    ///   - model: The model name to use.
    ///   - previousResponseId: The ID of the response that contained the function call.
    /// - Returns: The final `OpenAIResponse` from the assistant.
    func sendFunctionOutput(call: OutputItem, output: String, model: String, previousResponseId: String?) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        // The original function call from the assistant
        let functionCallMessage: [String: Any] = [
            "type": "function_call",
            "name": call.name ?? "",
            "arguments": call.arguments ?? "",
            "call_id": call.callId ?? ""
        ]
        
        // The result from our local execution
        let functionOutputMessage: [String: Any] = [
            "type": "function_call_output",
            "call_id": call.callId ?? "",
            "output": output
        ]
        
        // We need to send back the function call and our output
        let inputMessages = [functionCallMessage, functionOutputMessage]
        
        var requestObject: [String: Any] = [
            "model": model,
            "store": true,
            "input": inputMessages
        ]
        
        if let prevId = previousResponseId {
            requestObject["previous_response_id"] = prevId
        }
        
        // We don't need to resend tools or other complex parameters,
        // as we are continuing a specific tool-use turn.
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        
        // Don't print raw JSON here; centralized logging below will handle sanitization/omission
        
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 120
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData        // Log the function output API request
        AnalyticsService.shared.logAPIRequest(
            url: apiURL,
            method: "POST",
            headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
            body: jsonData
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "responses_function_output",
                AnalyticsParameter.requestMethod: "POST",
                AnalyticsParameter.requestSize: jsonData.count,
                AnalyticsParameter.model: model
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        
        // Log the response
        AnalyticsService.shared.logAPIResponse(
            url: apiURL,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "responses_function_output",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAIFunctionAPI"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "responses_function_output",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count,
                AnalyticsParameter.model: model
            ]
        )
        
        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            print("Function output response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Sends an MCP approval response back to the API to continue execution after user authorization.
    /// - Parameters:
    ///   - approvalResponse: The approval response dictionary with type, approval_request_id, approve, and optional reason.
    ///   - model: The model name to use.
    ///   - previousResponseId: The ID of the response that contained the approval request.
    ///   - prompt: The prompt configuration for tools and settings.
    /// - Returns: The OpenAIResponse containing the tool execution result.
    func sendMCPApprovalResponse(
        approvalResponse: [String: Any],
        model: String,
        previousResponseId: String?,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        // Build request with approval response as input
        let requestObject = buildRequestObject(
            for: prompt,
            userMessage: nil, // No user message for approval response
            attachments: nil,
            fileData: nil,
            fileNames: nil,
            fileIds: nil,
            imageAttachments: nil,
            previousResponseId: previousResponseId,
            stream: false,
            customInput: [approvalResponse] // Pass approval response as input
        )
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 120
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        AnalyticsService.shared.logAPIRequest(
            url: apiURL,
            method: "POST",
            headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
            body: jsonData
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "responses_mcp_approval",
                AnalyticsParameter.requestMethod: "POST",
                AnalyticsParameter.requestSize: jsonData.count,
                AnalyticsParameter.model: model
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        AnalyticsService.shared.logAPIResponse(
            url: apiURL,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "responses_mcp_approval",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAI_MCP_API"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "responses_mcp_approval",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count,
                AnalyticsParameter.model: model
            ]
        )
        
        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            print("MCP approval response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Streams an MCP approval response to continue execution after user authorization.
    func streamMCPApprovalResponse(
        approvalResponse: [String: Any],
        model: String,
        previousResponseId: String?,
        prompt: Prompt
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
                        continuation.finish(throwing: OpenAIServiceError.missingAPIKey)
                        return
                    }
                    
                    // Build request with approval response as input
                    let requestObject = buildRequestObject(
                        for: prompt,
                        userMessage: nil,
                        attachments: nil,
                        fileData: nil,
                        fileNames: nil,
                        fileIds: nil,
                        imageAttachments: nil,
                        previousResponseId: previousResponseId,
                        stream: true,
                        customInput: [approvalResponse]
                    )
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
                    
                    var request = URLRequest(url: apiURL)
                    request.timeoutInterval = 120
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    
                    AnalyticsService.shared.trackEvent(
                        name: AnalyticsEvent.apiRequestSent,
                        parameters: [
                            AnalyticsParameter.endpoint: "responses_mcp_approval_stream",
                            AnalyticsParameter.requestMethod: "POST",
                            AnalyticsParameter.model: model
                        ]
                    )
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OpenAIServiceError.invalidResponseData)
                        return
                    }
                    
                    if httpResponse.statusCode != 200 {
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        continuation.finish(throwing: OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage))
                        return
                    }
                    
                    // Parse SSE stream
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            if let data = jsonString.data(using: .utf8) {
                                do {
                                    let event = try JSONDecoder().decode(StreamingEvent.self, from: data)
                                    continuation.yield(event)
                                } catch {
                                    AppLogger.log("Failed to decode MCP approval streaming event: \(error)", category: .openAI, level: .warning)
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - MCP Convenience Calls

    /// Non-streaming: Call a specific MCP tool with arguments, ensuring MCP is enabled and whitelisted to the tool.
    func callMCP(
        serverLabel: String,
        tool: String,
        argumentsJSON: String,
        prompt: Prompt
    ) async throws -> OpenAIResponse {
        var derived = prompt
        derived.enableMCPTool = true
        derived.mcpIsConnector = false
        derived.mcpServerLabel = serverLabel
        // Keep server URL/headers from existing prompt (user config) if present
        derived.mcpAllowedTools = tool // whitelist single tool
        derived.mcpRequireApproval = normalizeMCPApproval(derived.mcpRequireApproval)
        // Force the model to actually use a tool this turn
        derived.toolChoice = "required"

        // Build a minimal directive – models also receive schemas for tools.
        let directive = "Use the MCP tool '\(tool)' with these arguments: \(argumentsJSON.isEmpty ? "{}" : argumentsJSON)."
        return try await sendChatRequest(
            userMessage: directive,
            prompt: derived,
            attachments: nil,
            fileData: nil,
            fileNames: nil,
            fileIds: nil,
            imageAttachments: nil,
            previousResponseId: nil
        )
    }

    /// Streaming: Call a specific MCP tool with arguments, returning streaming events.
    func callMCP(
        serverLabel: String,
        tool: String,
        argumentsJSON: String,
        prompt: Prompt,
        stream: Bool
    ) -> AsyncThrowingStream<StreamingEvent, Error> {
        var derived = prompt
        derived.enableMCPTool = true
        derived.mcpIsConnector = false
        derived.mcpServerLabel = serverLabel
        derived.mcpAllowedTools = tool // whitelist single tool
        derived.mcpRequireApproval = normalizeMCPApproval(derived.mcpRequireApproval)
        derived.toolChoice = "required"

        let directive = "Use the MCP tool '\(tool)' with these arguments: \(argumentsJSON.isEmpty ? "{}" : argumentsJSON)."
        return streamChatRequest(
            userMessage: directive,
            prompt: derived,
            attachments: nil,
            fileData: nil,
            fileNames: nil,
            fileIds: nil,
            imageAttachments: nil,
            previousResponseId: nil
        )
    }
    
    /// Probes MCP list_tools by initiating a lightweight streaming turn and returning the discovered tool count.
    /// This avoids mutating chat state and completes as soon as the list_tools event arrives or times out.
    func probeMCPListTools(prompt: Prompt) async throws -> (label: String, count: Int) {
        var derived = prompt
        // Ensure MCP is enabled and do not force a particular tool so the platform performs list_tools handshake
        derived.enableMCPTool = true
        derived.toolChoice = "auto"
        
        // Use a minimal directive; platform should perform list_tools when MCP tool is configured
        let targetLabel = derived.mcpServerLabel
        let userMessage = "MCP health probe: list available tools for '\(targetLabel)' and then stop."
        
        let stream = streamChatRequest(
            userMessage: userMessage,
            prompt: derived,
            attachments: nil,
            fileData: nil,
            fileNames: nil,
            fileIds: nil,
            imageAttachments: nil,
            previousResponseId: nil
        )
        
        var foundLabel = targetLabel
        var toolsCount: Int?
        let start = Date()
        
        do {
            for try await event in stream {
                // Capture label if provided by event
                if let sl = event.serverLabel ?? event.item?.serverLabel {
                    foundLabel = sl
                }
                // Success path: tools listed
                if event.type == "response.mcp_list_tools.added" || event.type == "response.mcp_list_tools.updated" {
                    toolsCount = event.tools?.count ?? 0
                    break
                }
                // Error events surfaced by streaming
                if event.type == "error" {
                    let msg = event.error ?? event.errorInfo?.message ?? "Unknown MCP error"
                    let lower = msg.lowercased()
                    if lower.contains("401") || lower.contains("unauthorized") {
                        throw OpenAIServiceError.requestFailed(401, msg)
                    }
                    throw OpenAIServiceError.invalidRequest(msg)
                }
                if let respErrMsg = event.response?.error?.message {
                    let lower = respErrMsg.lowercased()
                    if lower.contains("401") || lower.contains("unauthorized") {
                        throw OpenAIServiceError.requestFailed(401, respErrMsg)
                    } else {
                        throw OpenAIServiceError.invalidRequest(respErrMsg)
                    }
                }
                // Safety timeout
                if Date().timeIntervalSince(start) > 12 {
                    break
                }
            }
        } catch {
            throw error
        }
        
        if let c = toolsCount {
            AppLogger.log("🧪 MCP probe success: '\(foundLabel)' listed \(c) tools", category: .mcp, level: .info)
            return (label: foundLabel, count: c)
        } else {
            AppLogger.log("🧪 MCP probe did not receive list_tools events for '\(foundLabel)' within timeout", category: .mcp, level: .warning)
            throw OpenAIServiceError.requestFailed(0, "MCP list_tools did not complete in time")
        }
    }
    
    /// Sends a computer-use call output back to the API to continue an agentic turn.
    /// Per OpenAI's CUA docs, the follow-up should include a single `computer_call_output`
    /// item with a screenshot payload and must keep the computer tool configured.
    func sendComputerCallOutput(
        call: StreamingItem,
        output: Any,
        model: String,
        previousResponseId: String?,
        acknowledgedSafetyChecks: [SafetyCheck]? = nil,
        currentUrl: String? = nil
    ) async throws -> OpenAIResponse {
        return try await sendComputerCallOutput(
            callId: call.callId ?? "",
            output: output,
            model: model,
            previousResponseId: previousResponseId,
            acknowledgedSafetyChecks: acknowledgedSafetyChecks,
            currentUrl: currentUrl
        )
    }

    /// Sends a computer-use call output back to the API using an explicit call ID.
    func sendComputerCallOutput(
        callId: String,
        output: Any,
        model: String,
        previousResponseId: String?,
        acknowledgedSafetyChecks: [SafetyCheck]? = nil,
        currentUrl: String? = nil
    ) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        // Build the required `computer_call_output` item.
        // NOTE: The API expects `output` to be a structured content object representing the screenshot
        // (e.g., { "type": "computer_screenshot", "image_url": "data:image/png;base64,..." }).
        var computerOutputMessage: [String: Any] = [
            "type": "computer_call_output",
            "call_id": callId,
            "output": output
        ]
        
        // Add acknowledged safety checks if provided
        if let safetyChecks = acknowledgedSafetyChecks, !safetyChecks.isEmpty {
            computerOutputMessage["acknowledged_safety_checks"] = safetyChecks.map { safetyCheck in
                [
                    "id": safetyCheck.id,
                    "code": safetyCheck.code,
                    "message": safetyCheck.message
                ]
            }
        }
        
        // Add current URL if provided (helps with safety checks)
        if let url = currentUrl {
            computerOutputMessage["current_url"] = url
        }

        // Always include the computer tool configuration on follow-ups to keep the CUA context.
        // Use sensible defaults for environment and display if we can't derive real values here.
        let environment: String
        #if os(iOS)
        environment = "browser"
        #elseif os(macOS)
        environment = "mac"
        #else
        environment = "browser"
        #endif
        let screenSize: CGSize
        #if os(iOS)
        screenSize = CGSize(width: 440, height: 956)
        #elseif os(macOS)
        screenSize = CGSize(width: 1920, height: 1080)
        #else
        screenSize = CGSize(width: 1920, height: 1080)
        #endif

        // Encode tool config using our codable Tool enum for correctness.
        var toolsJSON: [Any] = []
        do {
            let tools: [APICapabilities.Tool] = [
                .computer(environment: environment, displayWidth: Int(screenSize.width), displayHeight: Int(screenSize.height))
            ]
            let encoder = JSONEncoder()
            let toolsData = try encoder.encode(tools)
            if let parsed = try JSONSerialization.jsonObject(with: toolsData) as? [Any] {
                toolsJSON = parsed
            }
        } catch {
            // If tool encoding fails, we still try to proceed without explicit tools (API may still accept).
            AppLogger.log("Failed to encode computer tool for follow-up: \(error)", category: .openAI, level: .warning)
        }

        var requestObject: [String: Any] = [
            "model": model,
            "store": true,
            "input": [computerOutputMessage],
            "truncation": "auto"
        ]

        if !toolsJSON.isEmpty {
            requestObject["tools"] = toolsJSON
        }

        if let prevId = previousResponseId {
            requestObject["previous_response_id"] = prevId
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        // Avoid manual body logging here; AnalyticsService will log this request with sanitization/omission
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 120
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        AnalyticsService.shared.logAPIRequest(
            url: apiURL,
            method: "POST",
            headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
            body: jsonData
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }

        AnalyticsService.shared.logAPIResponse(
            url: apiURL,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )

        if httpResponse.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, message)
        }

        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    // MARK: - Backward compatibility methods for computer use
    
    /// Convenience method for backward compatibility - delegates to main method with default parameters
    func sendComputerCallOutput(
        call: StreamingItem,
        output: Any,
        model: String,
        previousResponseId: String?
    ) async throws -> OpenAIResponse {
        return try await sendComputerCallOutput(
            call: call,
            output: output,
            model: model,
            previousResponseId: previousResponseId,
            acknowledgedSafetyChecks: nil,
            currentUrl: nil
        )
    }
    
    /// Convenience method for backward compatibility - delegates to main method with default parameters
    func sendComputerCallOutput(
        callId: String,
        output: Any,
        model: String,
        previousResponseId: String?
    ) async throws -> OpenAIResponse {
        return try await sendComputerCallOutput(
            callId: callId,
            output: output,
            model: model,
            previousResponseId: previousResponseId,
            acknowledgedSafetyChecks: nil,
            currentUrl: nil
        )
    }
    
    /// Fetches image data either from an OpenAI file ID or a direct URL.
    /// - Parameter imageContent: The content object containing either a file_id or url.
    /// - Returns: Raw image data.
    func fetchImageData(for imageContent: ContentItem) async throws -> Data {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        if let fileInfo = imageContent.imageFile {
            // Download image via OpenAI file API using file_id
            let fileId = fileInfo.file_id
            let fileURL = URL(string: "https://api.openai.com/v1/files/\(fileId)/content")!
            var req = URLRequest(url: fileURL)
            req.timeoutInterval = 120
            req.httpMethod = "GET"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw OpenAIServiceError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? -1, "Failed to fetch image file")
            }
            return data
        } else if let urlInfo = imageContent.imageURL {
            // Download image from the provided URL
            let url = URL(string: urlInfo.url)!
            var req = URLRequest(url: url)
            req.timeoutInterval = 120
            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw OpenAIServiceError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? -1, "Failed to fetch image URL")
            }
            return data
        }
        throw OpenAIServiceError.invalidResponseData
    }

    /// Downloads raw bytes of a file that resides inside a tool container (e.g., code interpreter container).
    /// This is required for annotations like container_file_citation that reference cfile_* along with a container_id.
    func fetchContainerFileContent(containerId: String, fileId: String) async throws -> Data {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        // Endpoint per Responses/Tools containers: /v1/containers/{container_id}/files/{file_id}/content
        guard let url = URL(string: "https://api.openai.com/v1/containers/\(containerId)/files/\(fileId)/content") else {
            throw OpenAIServiceError.invalidRequest("Invalid container or file id")
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 120
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Log the request for diagnostics
        AnalyticsService.shared.logAPIRequest(
            url: url,
            method: "GET",
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: nil
        )

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        if status != 200 {
            AnalyticsService.shared.logAPIResponse(url: url, statusCode: status, headers: (response as? HTTPURLResponse)?.allHeaderFields ?? [:], body: data)
            if status == 404 {
                throw OpenAIServiceError.requestFailed(status, "Container file not found or expired: \(fileId)")
            }
            throw OpenAIServiceError.requestFailed(status, "Failed to fetch container file content")
        }

        AnalyticsService.shared.logAPIResponse(url: url, statusCode: status, headers: (response as? HTTPURLResponse)?.allHeaderFields ?? [:], body: data)
        return data
    }
    
    /// Prepares file attachment objects for inclusion in API requests
    /// - Parameters:
    ///   - fileIds: Array of file IDs to attach
    /// - Returns: Array of properly formatted file attachment objects
    func prepareFileAttachments(fileIds: [String]) -> [[String: Any]] {
        return fileIds.map { fileId in
            // The only required properties for input_file objects are:
            // 1. type: "input_file"
            // 2. file_id: the ID of the uploaded file
            return [
                "type": "input_file",
                "file_id": fileId
            ]
        }
    }
    
    /// Creates a properly formatted tool configuration based on current API requirements
    /// - Parameters:
    ///   - toolType: The type of tool ("web_search_preview", "code_interpreter", etc.)
    ///   - vectorStoreId: Optional vector store ID for file_search tool
    /// - Returns: A dictionary representing the tool configuration
    /// 
    /// Note: Tool configurations have been simplified to avoid API parameter errors.
    /// The OpenAI API is strict about which parameters are accepted for each tool type.
    private func createToolConfiguration(for toolType: String, vectorStoreId: String? = nil) -> [String: Any] {
        switch toolType {
        case "web_search_preview":
            // Simplified to basic configuration to avoid "unknown parameter" errors
            return [
                "type": "web_search_preview"
            ]
        case "code_interpreter":
            // Code interpreter requires specifying a container type
            return [
                "type": "code_interpreter",
                "container": [ "type": "auto" ]
            ]
        case "image_generation":
            // Image generation parameters for gpt-image-1 with enhanced capabilities
            return [
                "type": "image_generation",
                "model": "gpt-image-1",
                "size": "auto",
                "quality": "high",
                "output_format": "png",
                "background": "auto",
                "moderation": "low",
                "partial_images": 3
            ]
        case "file_search":
            var config: [String: Any] = [
                "type": "file_search"
            ]
            // Include vector store configuration directly in the tool
            if let vectorStoreId = vectorStoreId {
                config["vector_store_ids"] = [vectorStoreId]
            }
            return config
        default:
            return [:]
        }
    }
    
    
    // Calculator tool configuration removed
    
    /// Creates the configuration for the MCP tool
    /// - Returns: A dictionary representing the MCP tool configuration
    private func createMCPToolConfiguration(from prompt: Prompt) -> [String: Any] {
        var headers: [String: String] = [:]
        if let data = prompt.mcpHeaders.data(using: .utf8),
           let parsedHeaders = try? JSONDecoder().decode([String: String].self, from: data) {
            headers = parsedHeaders
        }

        // Map internal approval values to API-compliant values
        let requireApprovalValue: String = {
            switch prompt.mcpRequireApproval {
            case "allow": return "never"
            case "deny": return "always"
            case "prompt": return "always" // prompt -> always require approval (safest)
            default: return prompt.mcpRequireApproval // pass through in case it's already API-compliant
            }
        }()
        
        // Sanitize server_label: must start with a letter and contain only letters, digits, '-', '_'
        // Replace spaces with underscores and filter out invalid characters
        let sanitizedLabel = prompt.mcpServerLabel
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        
        // Ensure it starts with a letter (if not, prepend "mcp_")
        let finalLabel = sanitizedLabel.first?.isLetter == true ? sanitizedLabel : "mcp_\(sanitizedLabel)"

        var config: [String: Any] = [
            "type": "mcp",
            "server_label": finalLabel,
            "server_url": prompt.mcpServerURL,
            "headers": headers,
            "require_approval": requireApprovalValue,
        ]

        // Parse allowed tools from comma-separated string
        // If empty, omit allowed_tools to enable ALL tools from the server (ubiquitous access)
        // If specified, restrict to only those tools (security whitelist)
        let allowedToolsString = prompt.mcpAllowedTools.trimmingCharacters(in: .whitespacesAndNewlines)
        if !allowedToolsString.isEmpty {
            let allowed = allowedToolsString
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !allowed.isEmpty {
                config["allowed_tools"] = allowed
                AppLogger.log("MCP: Restricting to \(allowed.count) specific tools", category: .openAI, level: .info)
            }
        } else {
            // Empty = allow ALL tools discovered from server
            AppLogger.log("MCP: Allowing ALL tools from server (ubiquitous mode)", category: .openAI, level: .info)
        }

        return config
    }

    /// Creates the configuration for the custom function tool.
    /// Responses API expects function tools to have top-level name/parameters.
    private func createCustomToolConfiguration(from prompt: Prompt) -> [String: Any] {
        // Try to parse user-provided JSON schema; fall back to permissive object
        let parsedSchema: [String: Any]
        if let data = prompt.customToolParametersJSON.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parsedSchema = obj
        } else {
            parsedSchema = ["type": "object", "properties": [:], "additionalProperties": true]
        }

        return [
            "type": "function",
            "name": prompt.customToolName,
            "description": prompt.customToolDescription,
            "parameters": parsedSchema,
            "strict": false
        ]
    }
    
    /// Creates the configuration for the file search tool
    /// - Parameter vectorStoreIds: Array of vector store IDs to search
    /// - Returns: A dictionary representing the file search tool configuration
    private func createFileSearchToolConfiguration(vectorStoreIds: [String]) -> [String: Any] {
        return [
            "type": "file_search",
            "vector_store_ids": vectorStoreIds
        ]
    }
    
    /// Creates the configuration for the web search tool
    /// - Returns: A dictionary representing the web search tool configuration
    private func createWebSearchToolConfiguration(from prompt: Prompt) -> [String: Any] {
        var config: [String: Any] = ["type": "web_search"]
        
        if let searchContextSize = prompt.searchContextSize, !searchContextSize.isEmpty {
            config["search_context_size"] = searchContextSize
        }
        
        var userLocation: [String: String] = [:]
        if let userLocationCity = prompt.userLocationCity, !userLocationCity.isEmpty {
            userLocation["city"] = userLocationCity
        }
        if let userLocationCountry = prompt.userLocationCountry, !userLocationCountry.isEmpty {
            userLocation["country"] = userLocationCountry
        }
        if let userLocationRegion = prompt.userLocationRegion, !userLocationRegion.isEmpty {
            userLocation["region"] = userLocationRegion
        }
        if let userLocationTimezone = prompt.userLocationTimezone, !userLocationTimezone.isEmpty {
            userLocation["timezone"] = userLocationTimezone
        }
        
        if !userLocation.isEmpty {
            userLocation["type"] = "approximate"
            config["user_location"] = userLocation
        }
        
        return config
    }
    
    /// Checks if a tool is supported by the given model
    /// - Parameters:
    ///   - toolType: The type of tool to check
    ///   - model: The model to check compatibility with
    ///   - isStreaming: Whether the request is using streaming mode
    /// - Returns: True if the tool is supported by the model and streaming mode
    private func isToolSupported(_ toolType: String, for model: String, isStreaming: Bool = false) -> Bool {
        switch toolType {
        case "code_interpreter":
            // Code interpreter is supported by GPT-4 models and newer o-series models.
            return model.starts(with: "gpt-4") || model.starts(with: "o1") || model.starts(with: "o3") || model.starts(with: "gpt-5")
        case "image_generation":
            // Image generation is supported by GPT-4 models.
            // It is disabled in streaming mode as images are sent as a complete block.
            if isStreaming {
                return false
            }
            return model.starts(with: "gpt-4")
        case "web_search_preview":
            // Web search is generally supported across models and works with both streaming and non-streaming
            return true
        case "file_search":
            // File search is supported by most models and works with both streaming and non-streaming
            return true
        default:
            return false
        }
    }
    
    // MARK: - File Management Functions
    
    /// Uploads a file to OpenAI for use with assistants, fine-tuning, or vector stores
    /// - Parameters:
    ///   - fileData: The file data to upload
    ///   - filename: The name of the file
    ///   - purpose: The purpose of the file (e.g., "assistants", "fine-tune", "vision")
    /// - Returns: The uploaded file information
    func uploadFile(fileData: Data, filename: String, purpose: String = "assistants") async throws -> OpenAIFile {
        AppLogger.log("📤 Starting file upload: \(filename) (\(formatBytes(fileData.count)))", category: .openAI, level: .info)
        
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            AppLogger.log("❌ Upload failed: Missing API key", category: .openAI, level: .error)
            throw OpenAIServiceError.missingAPIKey
        }
        
        let boundary = UUID().uuidString
        let url = URL(string: "https://api.openai.com/v1/files")!
        
        AppLogger.log("   🌐 Endpoint: POST \(url.absoluteString)", category: .openAI, level: .debug)
        AppLogger.log("   📋 Purpose: \(purpose)", category: .openAI, level: .debug)
        AppLogger.log("   📦 Boundary: \(boundary)", category: .openAI, level: .debug)
        
        // Create a dedicated URLSession configuration for large uploads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minutes
        config.timeoutIntervalForResource = 600 // 10 minutes total
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        let session = URLSession(configuration: config)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // Prevent connection reuse that might be causing issues
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        // Create multipart form data
        var body = Data()
        
        // Add purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(purpose)\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        AppLogger.log("   ⏫ Sending \(formatBytes(body.count)) to OpenAI...", category: .openAI, level: .info)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.log("❌ Invalid HTTP response received", category: .openAI, level: .error)
                throw OpenAIServiceError.invalidResponseData
            }
            
            AppLogger.log("   📡 Response: HTTP \(httpResponse.statusCode)", category: .openAI, level: .debug)
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    AppLogger.log("❌ Error response: \(responseString)", category: .openAI, level: .error)
                    print("Error uploading file: \(responseString)")
                }
                let errorMessage: String
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    errorMessage = errorResponse.error.message
                    AppLogger.log("   ⚠️ Error message: \(errorMessage)", category: .openAI, level: .error)
                } else {
                    errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                }
                throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
            }
            
            let file = try JSONDecoder().decode(OpenAIFile.self, from: data)
            AppLogger.log("✅ File uploaded successfully! ID: \(file.id), Size: \(formatBytes(file.bytes))", category: .openAI, level: .info)
            return file
            
        } catch let urlError as URLError {
            // Handle network-specific errors with more context
            let errorDescription: String
            switch urlError.code {
            case .networkConnectionLost:
                errorDescription = "Network connection lost during upload. For large files (18+ MB), try using a physical device instead of Simulator or check your network connection."
                AppLogger.log("❌ Network connection lost (error -1005) - Large file upload interrupted", category: .openAI, level: .error)
            case .timedOut:
                errorDescription = "Upload timed out. The file may be too large or your connection too slow."
                AppLogger.log("❌ Upload timed out", category: .openAI, level: .error)
            case .secureConnectionFailed:
                errorDescription = "SSL/TLS handshake failed. This can happen with Simulator - try a real device."
                AppLogger.log("❌ Secure connection failed (SSL error)", category: .openAI, level: .error)
            default:
                errorDescription = urlError.localizedDescription
                AppLogger.log("❌ Network error: \(urlError.localizedDescription) (code: \(urlError.code.rawValue))", category: .openAI, level: .error)
            }
            throw OpenAIServiceError.fileError(errorDescription)
        } catch {
            AppLogger.log("❌ Failed to decode file upload response: \(error)", category: .openAI, level: .error)
            print("Decoding error for file upload: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Helper to format byte counts
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Lists all files uploaded to OpenAI
    /// - Parameter purpose: Optional filter by purpose
    /// - Returns: List of files
    func listFiles(purpose: String? = nil) async throws -> [OpenAIFile] {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        var urlString = "https://api.openai.com/v1/files"
        if let purpose = purpose {
            urlString += "?purpose=\(purpose)"
        }
        
        guard let url = URL(string: urlString) else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error listing files: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let response = try JSONDecoder().decode(FileListResponse.self, from: data)
            return response.data
        } catch {
            print("Decoding error for file list: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Deletes a file from OpenAI
    /// - Parameter fileId: The ID of the file to delete
    func deleteFile(fileId: String) async throws {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/files/\(fileId)")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error deleting file: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
    }
    
    // MARK: - Vector Store Management Functions
    
    /// Creates a new vector store
    /// - Parameters:
    ///   - name: Optional name for the vector store
    ///   - fileIds: Optional list of file IDs to add to the vector store
    ///   - expiresAfterDays: Optional expiration in days
    /// - Returns: The created vector store
    func createVectorStore(name: String? = nil, fileIds: [String]? = nil, expiresAfterDays: Int? = nil) async throws -> VectorStore {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores")!
        
        var requestObject: [String: Any] = [:]
        
        if let name = name {
            requestObject["name"] = name
        }
        
        if let fileIds = fileIds, !fileIds.isEmpty {
            requestObject["file_ids"] = fileIds
        }
        
        if let days = expiresAfterDays {
            requestObject["expires_after"] = [
                "anchor": "last_active_at",
                "days": days
            ]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error creating vector store: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            return try JSONDecoder().decode(VectorStore.self, from: data)
        } catch {
            print("Decoding error for vector store creation: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Lists all vector stores
    /// - Returns: List of vector stores
    func listVectorStores() async throws -> [VectorStore] {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        var allVectorStores: [VectorStore] = []
        var after: String? = nil
        var hasMore = true
        
        // Pagination loop to fetch all vector stores
        while hasMore {
            var urlComponents = URLComponents(string: "https://api.openai.com/v1/vector_stores")!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "100") // Max allowed by API
            ]
            if let after = after {
                queryItems.append(URLQueryItem(name: "after", value: after))
            }
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw OpenAIServiceError.invalidResponseData
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIServiceError.invalidResponseData
            }
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error listing vector stores: \(responseString)")
                }
                let errorMessage: String
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    errorMessage = errorResponse.error.message
                } else {
                    errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                }
                throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
            }
            
            do {
                let response = try JSONDecoder().decode(VectorStoreListResponse.self, from: data)
                allVectorStores.append(contentsOf: response.data)
                hasMore = response.hasMore
                after = response.lastId
            } catch {
                print("Decoding error for vector store list: \(error)")
                throw OpenAIServiceError.invalidResponseData
            }
        }
        
        return allVectorStores
    }
    
    /// Lists vector stores with pagination support
    /// - Parameters:
    ///   - limit: Number of results to return (max 100)
    ///   - after: Cursor for pagination
    /// - Returns: Paginated vector store response
    func listVectorStoresPaginated(limit: Int = 20, after: String? = nil) async throws -> VectorStoreListResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        var urlComponents = URLComponents(string: "https://api.openai.com/v1/vector_stores")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(min(limit, 100))) // Ensure we don't exceed API limit
        ]
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error listing vector stores: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let response = try JSONDecoder().decode(VectorStoreListResponse.self, from: data)
            return response
        } catch {
            print("Decoding error for vector store list: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Deletes a vector store
    /// - Parameter vectorStoreId: The ID of the vector store to delete
    func deleteVectorStore(vectorStoreId: String) async throws {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error deleting vector store: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
    }
    
    /// Updates a vector store
    /// - Parameters:
    ///   - vectorStoreId: The ID of the vector store to update
    ///   - name: Optional new name for the vector store
    ///   - expiresAfter: Optional new expiration settings
    ///   - metadata: Optional new metadata
    /// - Returns: The updated vector store object
    func updateVectorStore(vectorStoreId: String, name: String?, expiresAfter: ExpiresAfter?, metadata: [String: Any]?) async throws -> VectorStore {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)")!
        
        var requestObject: [String: Any] = [:]
        
        if let name = name, !name.isEmpty {
            requestObject["name"] = name
        }
        
        if let expiresAfter = expiresAfter {
            requestObject["expires_after"] = [
                "anchor": expiresAfter.anchor,
                "days": expiresAfter.days
            ]
        }
        
        if let metadata = metadata {
            requestObject["metadata"] = metadata
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
        
        // Debug: Print the update request
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Vector Store Update Request JSON: \(jsonString)")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 120 // Increased timeout
        request.httpMethod = "POST"  // OpenAI uses POST for vector store updates
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error updating vector store: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            return try JSONDecoder().decode(VectorStore.self, from: data)
        } catch {
            print("Decoding error for vector store update: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Adds a file to a vector store
    /// - Parameters:
    ///   - vectorStoreId: The ID of the vector store
    ///   - fileId: The ID of the file to add
    ///   - chunkingStrategy: Optional chunking configuration
    ///   - attributes: Optional file metadata for filtering
    /// - Returns: The vector store file relationship
    func addFileToVectorStore(
        vectorStoreId: String,
        fileId: String,
        chunkingStrategy: ChunkingStrategy? = nil,
        attributes: [String: String]? = nil
    ) async throws -> VectorStoreFile {
        AppLogger.log("🔗 Adding file to vector store", category: .openAI, level: .info)
        AppLogger.log("   📁 File ID: \(fileId)", category: .openAI, level: .debug)
        AppLogger.log("   📦 Vector Store ID: \(vectorStoreId)", category: .openAI, level: .debug)
        
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            AppLogger.log("❌ Missing API key", category: .openAI, level: .error)
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)/files")!
        AppLogger.log("   🌐 Endpoint: POST \(url.absoluteString)", category: .openAI, level: .debug)
        
        var requestObject: [String: Any] = [
            "file_id": fileId
        ]
        
        // Add chunking strategy if provided
        if let chunkingStrategy = chunkingStrategy {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if let chunkData = try? encoder.encode(chunkingStrategy),
               let chunkDict = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any] {
                requestObject["chunking_strategy"] = chunkDict
                AppLogger.log("   ⚙️ Custom chunking strategy applied", category: .openAI, level: .debug)
                if let chunkType = (chunkDict["type"] as? String) {
                    AppLogger.log("      Type: \(chunkType)", category: .openAI, level: .debug)
                }
                if let staticDict = chunkDict["static"] as? [String: Any] {
                    if let maxTokens = staticDict["max_chunk_size_tokens"] as? Int {
                        AppLogger.log("      Max tokens: \(maxTokens)", category: .openAI, level: .debug)
                    }
                    if let overlap = staticDict["chunk_overlap_tokens"] as? Int {
                        AppLogger.log("      Overlap: \(overlap)", category: .openAI, level: .debug)
                    }
                }
            }
        } else {
            AppLogger.log("   ⚙️ Using default chunking strategy", category: .openAI, level: .debug)
        }
        
        // Add attributes if provided
        if let attributes = attributes, !attributes.isEmpty {
            requestObject["attributes"] = attributes
            AppLogger.log("   🏷️ File attributes: \(attributes)", category: .openAI, level: .debug)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
        
        if let prettyJSON = String(data: jsonData, encoding: .utf8) {
            AppLogger.log("   📤 Request body: \(prettyJSON)", category: .openAI, level: .debug)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        AppLogger.log("   ⏫ Sending request to OpenAI...", category: .openAI, level: .info)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.log("❌ Invalid HTTP response", category: .openAI, level: .error)
            throw OpenAIServiceError.invalidResponseData
        }
        
        AppLogger.log("   📡 Response: HTTP \(httpResponse.statusCode)", category: .openAI, level: .debug)
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                AppLogger.log("❌ Error response: \(responseString)", category: .openAI, level: .error)
                print("Error adding file to vector store: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
                AppLogger.log("   ⚠️ Error message: \(errorMessage)", category: .openAI, level: .error)
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let vectorStoreFile = try JSONDecoder().decode(VectorStoreFile.self, from: data)
            AppLogger.log("✅ File successfully added to vector store!", category: .openAI, level: .info)
            AppLogger.log("   📊 Status: \(vectorStoreFile.status)", category: .openAI, level: .debug)
            AppLogger.log("   📈 Usage bytes: \(vectorStoreFile.usageBytes)", category: .openAI, level: .debug)
            
            if let responseString = String(data: data, encoding: .utf8) {
                AppLogger.log("   📥 Full response: \(responseString)", category: .openAI, level: .debug)
            }
            
            return vectorStoreFile
        } catch {
            AppLogger.log("❌ Failed to decode response: \(error)", category: .openAI, level: .error)
            print("Decoding error for vector store file: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Lists files in a vector store
    /// - Parameter vectorStoreId: The ID of the vector store
    /// - Returns: List of files in the vector store
    func listVectorStoreFiles(vectorStoreId: String) async throws -> [VectorStoreFile] {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)/files")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error listing vector store files: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let response = try JSONDecoder().decode(VectorStoreFileListResponse.self, from: data)
            return response.data
        } catch {
            print("Decoding error for vector store file list: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Removes a file from a vector store
    /// - Parameters:
    ///   - vectorStoreId: The ID of the vector store
    ///   - fileId: The ID of the file to remove
    func removeFileFromVectorStore(vectorStoreId: String, fileId: String) async throws {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)/files/\(fileId)")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 120 // Increased timeout
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error removing file from vector store: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
    }
    
    /// Uploads a file to OpenAI from a local URL
    /// - Parameter url: The URL of the file to upload.
    /// - Returns: The ID of the uploaded file.
    func uploadFile(from url: URL) async throws -> String {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let uploadURL = URL(string: "https://api.openai.com/v1/files")!
        
        // Prepare multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: uploadURL)
        request.timeoutInterval = 120
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("user_data\r\n".data(using: .utf8)!)
        
        // Add file data
        let filename = url.lastPathComponent
        let fileData = try Data(contentsOf: url)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIServiceError.requestFailed(statusCode, "File upload failed: \(errorMessage)")
        }
        
        // Decode the response to get the file ID
        struct FileUploadResponse: Decodable {
            let id: String
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(FileUploadResponse.self, from: data)
            return decodedResponse.id
        } catch {
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    private func createWebSearchConfiguration() -> [String: Any] {
        // The API seems to have changed and no longer accepts these detailed parameters.
        // Simplified to basic configuration to avoid "unknown parameter" errors.
        return [
            "type": "web_search_preview"
        ]
    }

    private func createImageGenerationConfiguration() -> [String: Any] {
        let defaults = UserDefaults.standard
        var config: [String: Any] = [
            "type": "image_generation",
            "model": "gpt-image-1",
            "size": defaults.string(forKey: "imageGenerationSize") ?? "auto",
            "quality": defaults.string(forKey: "imageGenerationQuality") ?? "auto",
            "background": defaults.string(forKey: "imageGenerationBackground") ?? "auto",
            "output_format": defaults.string(forKey: "imageGenerationOutputFormat") ?? "png",
            "moderation": defaults.string(forKey: "imageGenerationModeration") ?? "auto"
        ]
        
        let partialImages = defaults.integer(forKey: "imageGenerationPartialImages")
        if partialImages > 0 {
            config["partial_images"] = partialImages
        }
        
        return config
    }
    
    /// Lists available models from the OpenAI API.
    /// - Returns: An array of OpenAIModel objects representing available models.
    func listModels() async throws -> [OpenAIModel] {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/models")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let modelsResponse = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
            return modelsResponse.data.sorted { $0.id < $1.id }
        } catch {
            print("Models decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }

    // Removed: computer_use_preview probe utility
    
    /// Creates a new vector store (protocol conformance method)
    /// - Parameters:
    ///   - name: Name for the vector store
    ///   - fileIds: Optional list of file IDs to add to the vector store
    /// - Returns: The created vector store
    func createVectorStore(name: String, fileIds: [String]?) async throws -> VectorStore {
        return try await createVectorStore(name: name, fileIds: fileIds, expiresAfterDays: nil)
    }

    
    // MARK: - Missing Response Management Endpoints
    
    /// Deletes a model response with the given ID.
    /// - Parameter responseId: The ID of the response to delete.
    /// - Returns: DeleteResponseResult indicating success.
    func deleteResponse(responseId: String) async throws -> DeleteResponseResult {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/responses/\(responseId)")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Log the delete request
        AnalyticsService.shared.logAPIRequest(
            url: url,
            method: "DELETE",
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: nil
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "delete_response",
                AnalyticsParameter.requestMethod: "DELETE",
                "response_id": responseId
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        // Log the response
        AnalyticsService.shared.logAPIResponse(
            url: url,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "delete_response",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAIDeleteAPI"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "delete_response",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count
            ]
        )
        
        do {
            return try JSONDecoder().decode(DeleteResponseResult.self, from: data)
        } catch {
            print("Delete response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Cancels a model response that is in progress.
    /// - Parameter responseId: The ID of the response to cancel.
    /// - Returns: The updated OpenAIResponse with cancelled status.
    func cancelResponse(responseId: String) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/responses/\(responseId)/cancel")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Log the cancel request
        AnalyticsService.shared.logAPIRequest(
            url: url,
            method: "POST",
            headers: ["Authorization": "Bearer \(apiKey)", "Content-Type": "application/json"],
            body: nil
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "cancel_response",
                AnalyticsParameter.requestMethod: "POST",
                "response_id": responseId
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        // Log the response
        AnalyticsService.shared.logAPIResponse(
            url: url,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "cancel_response",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAICancelAPI"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "cancel_response",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count
            ]
        )
        
        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            print("Cancel response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    /// Returns a list of input items for a given response.
    /// - Parameter responseId: The ID of the response to retrieve input items for.
    /// - Returns: InputItemsResponse containing the list of input items.
    func listInputItems(responseId: String) async throws -> InputItemsResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/responses/\(responseId)/input_items")!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Log the input items request
        AnalyticsService.shared.logAPIRequest(
            url: url,
            method: "GET",
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: nil
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiRequestSent,
            parameters: [
                AnalyticsParameter.endpoint: "input_items",
                AnalyticsParameter.requestMethod: "GET",
                "response_id": responseId
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        // Log the response
        AnalyticsService.shared.logAPIResponse(
            url: url,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "input_items",
                    AnalyticsParameter.statusCode: httpResponse.statusCode,
                    AnalyticsParameter.errorCode: httpResponse.statusCode,
                    AnalyticsParameter.errorDomain: "OpenAIInputItemsAPI"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "input_items",
                AnalyticsParameter.statusCode: httpResponse.statusCode,
                AnalyticsParameter.responseSize: data.count
            ]
        )
        
        do {
            return try JSONDecoder().decode(InputItemsResponse.self, from: data)
        } catch {
            print("Input items response decoding error: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
}
