import Foundation
// Import the StreamingEvent model
import SwiftUI  // This should already be there for access to UI types

/// A service class responsible for communicating with the OpenAI API.
class OpenAIService {
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
    ///   - previousResponseId: The ID of the previous response for continuity (if any).
    /// - Returns: The decoded OpenAIResponse.
    func sendChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, previousResponseId: String?) async throws -> OpenAIResponse {
        // Ensure API key is set
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        // Build the request JSON payload from the prompt object
        let requestObject = buildRequestObject(
            for: prompt,
            userMessage: userMessage,
            attachments: attachments,
            previousResponseId: previousResponseId,
            stream: false
        )

        // Serialize JSON payload
        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        
        // For debugging: Print the JSON request
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("OpenAI Request JSON: \(jsonString)")
        }
        
        // Prepare URLRequest with authorization header
        var request = URLRequest(url: apiURL)
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
        
        // Perform HTTP request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        let statusCode = httpResponse.statusCode
        if statusCode != 200 {
            // Try to decode error message from response - print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response: \(responseString)")
            }
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            }
            
            // Log the error response
            AnalyticsService.shared.logAPIResponse(
                url: apiURL,
                statusCode: statusCode,
                headers: httpResponse.allHeaderFields,
                body: data
            )
            AnalyticsService.shared.trackEvent(
                name: AnalyticsEvent.networkError,
                parameters: [
                    AnalyticsParameter.endpoint: "responses",
                    AnalyticsParameter.statusCode: statusCode,
                    AnalyticsParameter.errorCode: statusCode,
                    AnalyticsParameter.errorDomain: "OpenAIAPI"
                ]
            )
            
            throw OpenAIServiceError.requestFailed(statusCode, errorMessage)
        }
        
        // Log the successful response
        AnalyticsService.shared.logAPIResponse(
            url: apiURL,
            statusCode: statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )
        AnalyticsService.shared.trackEvent(
            name: AnalyticsEvent.apiResponseReceived,
            parameters: [
                AnalyticsParameter.endpoint: "responses",
                AnalyticsParameter.statusCode: statusCode,
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
    ///   - previousResponseId: The ID of the previous response for continuity.
    /// - Returns: An asynchronous stream of `StreamingEvent` chunks.
    func streamChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, previousResponseId: String?) -> AsyncThrowingStream<StreamingEvent, Error> {
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
                        previousResponseId: previousResponseId,
                        stream: true
                    )
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
                    
                    // For debugging: Print the JSON request for streaming
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("OpenAI Streaming Request JSON: \(jsonString)")
                    }
                    
                    var request = URLRequest(url: apiURL)
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
                        
                        // Print raw response for debugging
                        if let responseString = String(data: errorData, encoding: .utf8) {
                            print("Streaming error response: \(responseString)")
                        }
                        
                        // Try to decode structured error message
                        let errorMessage: String
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: errorData) {
                            errorMessage = errorResponse.error.message
                        } else {
                            errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
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
                                
                                // Log the streaming event using the enhanced structured logging
                                AnalyticsService.shared.logStreamingEvent(
                                    eventType: decodedChunk.type,
                                    data: dataString,
                                    parsedEvent: decodedChunk
                                )
                                
                                // Track analytics event (high-level metrics)
                                AnalyticsService.shared.trackEvent(
                                    name: AnalyticsEvent.streamingEventReceived,
                                    parameters: [
                                        AnalyticsParameter.eventType: decodedChunk.type,
                                        AnalyticsParameter.sequenceNumber: decodedChunk.sequenceNumber
                                    ]
                                )
                                
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

    /// Builds the request dictionary from a Prompt object and other parameters.
    private func buildRequestObject(for prompt: Prompt, userMessage: String, attachments: [[String: Any]]?, previousResponseId: String?, stream: Bool) -> [String: Any] {
        var requestObject: [String: Any] = [:]

        // If a published prompt ID is provided, use it.
        if prompt.enablePublishedPrompt, !prompt.publishedPromptId.isEmpty {
            requestObject = [
                "prompt": [
                    "id": prompt.publishedPromptId,
                    "version": prompt.publishedPromptVersion
                ],
                "store": true
            ]
            
            var inputMessages: [[String: Any]] = [["role": "user", "content": userMessage]]
            
            if !prompt.developerInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputMessages.insert(["role": "developer", "content": prompt.developerInstructions], at: 0)
            }
            requestObject["input"] = inputMessages

        } else {
            // Build the request from individual settings in the prompt object
            requestObject = [
                "model": prompt.openAIModel,
                "store": true
            ]

            var inputMessages: [[String: Any]] = []

            if !prompt.systemInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                requestObject["instructions"] = prompt.systemInstructions
            }
            
            if !prompt.developerInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputMessages.append(["role": "developer", "content": [["type": "input_text", "text": prompt.developerInstructions]]])
            }
            
            // Handle user message and attachments
            var userContent: [[String: Any]] = [["type": "input_text", "text": userMessage]]
            if let attachments = attachments {
                // The OpenAI API has strict requirements for content objects
                // We need to transform our attachments to valid content objects
                let validatedAttachments = attachments.compactMap { attachment -> [String: Any]? in
                    // Start with a clean slate for each attachment
                    var validContent: [String: Any] = [:]
                    
                    // Check file type if file_search is enabled - we only want to include PDFs
                    if prompt.enableFileSearch {
                        if let filename = attachment["filename"] as? String, 
                           !filename.lowercased().hasSuffix(".pdf") {
                            AppLogger.log(
                                "File search enabled but non-PDF file attached: \(filename). Only PDF files are supported for file search.",
                                category: .openAI,
                                level: .warning
                            )
                            // Skip this attachment or return a message about unsupported file type
                            return nil
                        }
                    }
                    
                    // Set the correct type based on what we're attaching
                    validContent["type"] = "input_file"
                    
                    // Extract file_id from the attachment
                    if let fileId = attachment["file_id"] as? String {
                        validContent["file_id"] = fileId
                    } else if let fileId = attachment["id"] as? String {
                        validContent["file_id"] = fileId
                    } else {
                        // If we can't find a file ID, we can't create a valid attachment
                        AppLogger.log(
                            "Missing file_id in attachment: \(attachment)",
                            category: .openAI,
                            level: .warning
                        )
                        return nil
                    }
                    
                    return validContent
                }
                
                // Only add attachments that we successfully validated
                if !validatedAttachments.isEmpty {
                    userContent.append(contentsOf: validatedAttachments)
                }
            }
            inputMessages.append(["role": "user", "content": userContent])
            
            requestObject["input"] = inputMessages
            
            var tools: [[String: Any]] = []
            if prompt.enableWebSearch {
                tools.append(createWebSearchToolConfiguration(from: prompt))
            }
            if prompt.enableCodeInterpreter {
                tools.append(["type": "code_interpreter", "container": ["type": "auto"]])
            }
            if prompt.enableImageGeneration && !stream { // Image generation not supported in streaming
                // Image generation parameters are set based on user preferences
                tools.append([
                    "type": "image_generation",
                    "size": "auto",
                    "quality": "high",
                    "output_format": "png",
                    "background": "auto",
                    "moderation": "low",
                    "partial_images": 3
                ])
            }
            if prompt.enableCalculator {
                tools.append(createCalculatorToolConfiguration())
            }
            if prompt.enableMCPTool {
                tools.append(createMCPToolConfiguration(from: prompt))
            }
            if prompt.enableCustomTool {
                tools.append(createCustomToolConfiguration(from: prompt))
            }
            if prompt.enableFileSearch {
                // Check if we have any PDF attachments (needed for file search)
                let hasPdfAttachments = attachments?.contains { attachment in
                    if let filename = attachment["filename"] as? String,
                       filename.lowercased().hasSuffix(".pdf") {
                        return true
                    }
                    return false
                } ?? false
                
                // Only add file search if we have PDFs or if specific vector stores are provided
                let idsArray = (prompt.selectedVectorStoreIds ?? "").split(separator: ",").map(String.init).filter { !$0.isEmpty }
                
                if !idsArray.isEmpty || hasPdfAttachments {
                    if !idsArray.isEmpty {
                        // We have actual vector store IDs, use them
                        tools.append(createFileSearchToolConfiguration(fileIds: idsArray))
                    } else {
                        // If we have no vector store IDs, use our placeholder solution
                        // The API requires at least one vector store ID
                        tools.append(createFileSearchToolConfiguration())
                        
                        // Log that we're using a placeholder
                        AppLogger.log(
                            "Using placeholder vector store ID for file search",
                            category: .openAI,
                            level: .warning
                        )
                    }
                } else {
                    // Log that we're skipping file search tool due to no PDFs
                    AppLogger.log(
                        "Skipping file search tool: No PDF files attached and no vector stores provided",
                        category: .openAI,
                        level: .warning
                    )
                }
            }
            
            if !tools.isEmpty {
                requestObject["tools"] = tools
            }

            if prompt.openAIModel.starts(with: "o") {
                requestObject["reasoning"] = [
                    "effort": prompt.reasoningEffort,
                    "summary": prompt.reasoningSummary
                ]
            } else {
                requestObject["temperature"] = prompt.temperature
                requestObject["top_p"] = prompt.topP
            }

            // Advanced API parameters
            requestObject["background"] = prompt.backgroundMode
            if prompt.maxOutputTokens > 0 { requestObject["max_output_tokens"] = prompt.maxOutputTokens }
            if prompt.maxToolCalls > 0 { requestObject["max_tool_calls"] = prompt.maxToolCalls }
            requestObject["parallel_tool_calls"] = prompt.parallelToolCalls
            if !prompt.serviceTier.isEmpty { requestObject["service_tier"] = prompt.serviceTier }
            if prompt.topLogprobs > 0 { requestObject["top_logprobs"] = prompt.topLogprobs }
            if !prompt.truncationStrategy.isEmpty { requestObject["truncation"] = prompt.truncationStrategy }
            if !prompt.userIdentifier.isEmpty { requestObject["user"] = prompt.userIdentifier }
            
            var include: [String] = []
            if prompt.includeCodeInterpreterOutputs { include.append("code_interpreter_call.outputs") }
            if prompt.includeFileSearchResults { include.append("file_search_call.results") }
            if prompt.includeInputImageUrls { include.append("message.input_image.image_url") }
            if prompt.includeOutputLogprobs { include.append("message.output_text.logprobs") }
            if !include.isEmpty { requestObject["include"] = include }

            if prompt.textFormatType == "json_schema", !prompt.jsonSchemaName.isEmpty, !prompt.jsonSchemaContent.isEmpty {
                requestObject["text"] = [
                    "format": [
                        "type": "json_schema",
                        "name": prompt.jsonSchemaName,
                        "description": prompt.jsonSchemaDescription,
                        "strict": prompt.jsonSchemaStrict,
                        "schema": try? JSONSerialization.jsonObject(with: Data(prompt.jsonSchemaContent.utf8))
                    ]
                ]
            } else {
                var textObject: [String: Any] = ["format": ["type": "text"]]
                if prompt.openAIModel.starts(with: "o3") {
                    textObject["verbosity"] = "medium"
                }
                requestObject["text"] = textObject
            }
        }

        if stream {
            requestObject["stream"] = true
        }
        
        // Attachments are now handled within the input construction
        
        if let prevId = previousResponseId {
            requestObject["previous_response_id"] = prevId
        }
        
        return requestObject
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
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("OpenAI Function Output Request JSON: \(jsonString)")
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Log the function output API request
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
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw OpenAIServiceError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? -1, "Failed to fetch image URL")
            }
            return data
        }
        throw OpenAIServiceError.invalidResponseData
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
            // Image generation parameters are set based on user preferences
            return [
                "type": "image_generation",
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
    
    
    /// Creates the configuration for the custom calculator tool
    /// - Returns: A dictionary representing the calculator tool configuration
    private func createCalculatorToolConfiguration() -> [String: Any] {
        // Responses API expects function tools to have top-level 'name' & 'parameters'
        return [
            "type": "function",
            "name": "calculator",
            "description": "Evaluate mathematical expressions and return the result.",
            "parameters": [
                "type": "object",
                "properties": [
                    "expression": [
                        "type": "string",
                        "description": "A mathematical expression to evaluate, e.g., '5+3*2'"
                    ]
                ],
                "required": ["expression"],
                "additionalProperties": false
            ],
            "strict": true
        ]
    }
    
    /// Creates the configuration for the MCP tool
    /// - Returns: A dictionary representing the MCP tool configuration
    private func createMCPToolConfiguration(from prompt: Prompt) -> [String: Any] {
        var headers: [String: String] = [:]
        if let data = prompt.mcpHeaders.data(using: .utf8),
           let parsedHeaders = try? JSONDecoder().decode([String: String].self, from: data) {
            headers = parsedHeaders
        }

        return [
            "type": "mcp",
            "server_label": prompt.mcpServerLabel,
            "server_url": prompt.mcpServerURL,
            "headers": headers,
            "require_approval": prompt.mcpRequireApproval,
            "allowed_tools": [] // This could be made configurable in the future
        ]
    }

    /// Creates the configuration for the custom tool
    /// - Returns: A dictionary representing the custom tool configuration
    private func createCustomToolConfiguration(from prompt: Prompt) -> [String: Any] {
        return [
            "type": "function",
            "function": [
                "name": prompt.customToolName,
                "description": prompt.customToolDescription,
                "parameters": ["type": "object", "properties": [:]] // Assuming no parameters for simplicity
            ]
        ]
    }
    
    /// Creates the configuration for the file search tool
    /// - Parameter fileIds: Array of file IDs to search
    /// - Returns: A dictionary representing the file search tool configuration
    private func createFileSearchToolConfiguration(fileIds: [String]? = nil) -> [String: Any] {
        var config: [String: Any] = ["type": "file_search"]
        
        if let fileIds = fileIds, !fileIds.isEmpty {
            config["file_ids"] = fileIds
        }
        
        // Add a placeholder vector store ID - required by the API
        // The API requires at least one vector store ID
        config["vector_store_ids"] = ["vs_placeholder"]
        
        return config
    }
    
    /// Creates the configuration for the web search tool
    /// - Returns: A dictionary representing the web search tool configuration
    private func createWebSearchToolConfiguration(from prompt: Prompt) -> [String: Any] {
        var config: [String: Any] = ["type": "web_search_preview"]
        
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
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let boundary = UUID().uuidString
        let url = URL(string: "https://api.openai.com/v1/files")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error uploading file: \(responseString)")
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
            return try JSONDecoder().decode(OpenAIFile.self, from: data)
        } catch {
            print("Decoding error for file upload: \(error)")
            throw OpenAIServiceError.invalidResponseData
        }
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
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores")!
        
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
            return response.data
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
    /// - Returns: The vector store file relationship
    func addFileToVectorStore(vectorStoreId: String, fileId: String) async throws -> VectorStoreFile {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorStoreId)/files")!
        
        let requestObject: [String: Any] = [
            "file_id": fileId
        ]
        
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
                print("Error adding file to vector store: \(responseString)")
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
            return try JSONDecoder().decode(VectorStoreFile.self, from: data)
        } catch {
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
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add purpose field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
        body.append("assistants\r\n".data(using: .utf8)!)
        
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
}
