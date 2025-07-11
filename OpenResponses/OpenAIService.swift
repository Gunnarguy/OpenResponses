import Foundation

/// Errors that can occur when calling the OpenAI API.
enum OpenAIServiceError: Error {
    case missingAPIKey
    case requestFailed(Int, String)  // HTTP status code and message
    case invalidResponseData
}

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
    ///   - model: The model name to use (e.g., "gpt-4o", "o3", "o3-mini").
    ///   - previousResponseId: The ID of the previous response for continuity (if any).
    /// - Returns: The decoded OpenAIResponse.
    func sendChatRequest(userMessage: String, model: String, previousResponseId: String?) async throws -> OpenAIResponse {
        // Ensure API key is set
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        // Build the request JSON payload
        var requestObject: [String: Any] = [
            "model": model,
            "store": true
        ]

        var inputMessages: [[String: Any]] = []

        // Add system instructions based on model preference
        if let instructions = UserDefaults.standard.string(forKey: "systemInstructions"), !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if modelPrefersSystemMessage(model) {
                inputMessages.append(["role": "system", "content": instructions])
            } else {
                requestObject["instructions"] = instructions
            }
        }
        
        // Add the user's message to the input
        inputMessages.append(["role": "user", "content": userMessage])
        requestObject["input"] = inputMessages
        
        // Build tools array based on user preferences and model compatibility
        var tools: [[String: Any]] = []
        
        // Add web search tool if enabled
        if UserDefaults.standard.bool(forKey: "enableWebSearch") {
            tools.append(createToolConfiguration(for: "web_search_preview"))
        }
        
        // Add code interpreter tool if enabled and supported by the model
        if UserDefaults.standard.bool(forKey: "enableCodeInterpreter") && isToolSupported("code_interpreter", for: model, isStreaming: false) {
            tools.append(createToolConfiguration(for: "code_interpreter"))
        }
        
        // Add image generation tool if enabled and supported by the model
        if UserDefaults.standard.bool(forKey: "enableImageGeneration") && isToolSupported("image_generation", for: model, isStreaming: false) {
            tools.append(createToolConfiguration(for: "image_generation"))
        }
        
        // Add file search tool if enabled and vector store(s) are selected
        if UserDefaults.standard.bool(forKey: "enableFileSearch") {
            // Support multi-store selection (comma-separated IDs)
            let multiIds = UserDefaults.standard.string(forKey: "selectedVectorStoreIds") ?? ""
            let idsArray = multiIds.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
            if !idsArray.isEmpty {
                tools.append(["type": "file_search", "vector_store_ids": idsArray])
            } else if let vectorStoreId = UserDefaults.standard.string(forKey: "selectedVectorStore"), !vectorStoreId.isEmpty {
                tools.append(createToolConfiguration(for: "file_search", vectorStoreId: vectorStoreId))
            }
        }
        
        // Only add tools array if there are tools enabled
        if !tools.isEmpty {
            requestObject["tools"] = tools
        }
        
        // Debug: Print tools configuration
        print("Non-streaming request - Tools enabled: \(tools.count) tools")
        for (index, tool) in tools.enumerated() {
            print("Tool \(index): \(tool["type"] ?? "unknown")")
        }
        
        // Set appropriate sampling or reasoning parameters based on model type
        if model.starts(with: "o") {
            // O-series reasoning model: use reasoning.effort parameter
            let effort = UserDefaults.standard.string(forKey: "reasoningEffort") ?? "medium"
            requestObject["reasoning"] = ["effort": effort]
        } else {
            // Standard model (e.g. GPT-4/GPT-4o): use temperature and top_p
            let temp = UserDefaults.standard.double(forKey: "temperature")
            requestObject["temperature"] = temp == 0.0 ? 1.0 : temp  // default to 1.0 if not set
            requestObject["top_p"] = 1.0  // using full distribution by default (top_p=1)
        }
        
        if let prevId = previousResponseId {
            requestObject["previous_response_id"] = prevId  // Link to last response for context continuity
        }
        
        // Note: Do not set stream parameter for non-streaming requests

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
            throw OpenAIServiceError.requestFailed(statusCode, errorMessage)
        }
        
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
    ///   - model: The model name to use.
    ///   - previousResponseId: The ID of the previous response for continuity.
    /// - Returns: An asynchronous stream of `StreamingEvent` chunks.
    func streamChatRequest(userMessage: String, model: String, previousResponseId: String?) -> AsyncThrowingStream<StreamingEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Ensure API key is set
                    guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
                        throw OpenAIServiceError.missingAPIKey
                    }
                    
                    // Build the request JSON payload (same as non-streaming, but with stream: true)
                    var requestObject: [String: Any] = [
                        "model": model,
                        "store": true,
                        "stream": true // Enable streaming
                    ]
                    
                    var inputMessages: [[String: Any]] = []

                    // Add system instructions if they exist
                    if let instructions = UserDefaults.standard.string(forKey: "systemInstructions"), !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if modelPrefersSystemMessage(model) {
                            inputMessages.append(["role": "system", "content": instructions])
                        } else {
                            requestObject["instructions"] = instructions
                        }
                    }

                    // Add the user's message to the input
                    inputMessages.append(["role": "user", "content": userMessage])
                    requestObject["input"] = inputMessages
                    
                    var tools: [[String: Any]] = []
                    if UserDefaults.standard.bool(forKey: "enableWebSearch") {
                        tools.append(createToolConfiguration(for: "web_search_preview"))
                    }
                    if UserDefaults.standard.bool(forKey: "enableCodeInterpreter") && isToolSupported("code_interpreter", for: model, isStreaming: true) {
                        tools.append(createToolConfiguration(for: "code_interpreter"))
                    }
                    if UserDefaults.standard.bool(forKey: "enableImageGeneration") && isToolSupported("image_generation", for: model, isStreaming: true) {
                        tools.append(createToolConfiguration(for: "image_generation"))
                    }
                    if UserDefaults.standard.bool(forKey: "enableFileSearch") {
                        let multiIds = UserDefaults.standard.string(forKey: "selectedVectorStoreIds") ?? ""
                        let idsArray = multiIds.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
                        if !idsArray.isEmpty {
                            tools.append(["type": "file_search", "vector_store_ids": idsArray])
                        } else if let vectorStoreId = UserDefaults.standard.string(forKey: "selectedVectorStore"), !vectorStoreId.isEmpty {
                            tools.append(createToolConfiguration(for: "file_search", vectorStoreId: vectorStoreId))
                        }
                    }
                    
                    if !tools.isEmpty {
                        requestObject["tools"] = tools
                    }

                    // Set appropriate sampling or reasoning parameters based on model type
                    if model.starts(with: "o") {
                        let effort = UserDefaults.standard.string(forKey: "reasoningEffort") ?? "medium"
                        requestObject["reasoning"] = ["effort": effort]
                    } else {
                        let temp = UserDefaults.standard.double(forKey: "temperature")
                        requestObject["temperature"] = temp == 0.0 ? 1.0 : temp
                        requestObject["top_p"] = 1.0
                    }
                    
                    if let prevId = previousResponseId {
                        requestObject["previous_response_id"] = prevId
                    }
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: [])
                    
                    // For debugging: Print the JSON request for streaming
                    print("Streaming request - Tools enabled: \(tools.count) tools")
                    for (index, tool) in tools.enumerated() {
                        print("Tool \(index): \(tool["type"] ?? "unknown")")
                    }
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("OpenAI Streaming Request JSON: \(jsonString)")
                    }
                    
                    var request = URLRequest(url: apiURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    
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
                        
                        throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let dataString = String(line.dropFirst(6))
                            if dataString == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            guard let data = dataString.data(using: .utf8) else { continue }
                            
                            do {
                                let decodedChunk = try JSONDecoder().decode(StreamingEvent.self, from: data)
                                continuation.yield(decodedChunk)
                            } catch {
                                print("Stream decoding error: \(error) for data: \(dataString)")
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
    
    /// Fetches image data either from an OpenAI file ID or a direct URL.
    /// - Parameter imageContent: The content object containing either a file_id or url.
    /// - Returns: Raw image data.
    func fetchImageData(for imageContent: ContentItem) async throws -> Data {
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
    
    /// Determines if a model prefers receiving instructions via a system message in the input array.
    /// - Parameter model: The model name.
    /// - Returns: `true` if the model prefers a system message.
    private func modelPrefersSystemMessage(_ model: String) -> Bool {
        // O-series models prefer instructions via a system message.
        // GPT-series models prefer the top-level 'instructions' parameter.
        return model.starts(with: "o")
    }
    
    /// Creates a properly formatted tool configuration based on current API requirements
    /// - Parameters:
    ///   - toolType: The type of tool ("web_search_preview", "code_interpreter", "image_generation", "file_search")
    ///   - vectorStoreId: Optional vector store ID for file_search tool
    /// - Returns: A dictionary representing the tool configuration
    private func createToolConfiguration(for toolType: String, vectorStoreId: String? = nil) -> [String: Any] {
        switch toolType {
        case "web_search_preview":
            return [
                "type": "web_search_preview",
                "user_location": [ "type": "approximate", "country": "US" ],
                "search_context_size": "medium"
            ]
        case "code_interpreter":
            return [
                "type": "code_interpreter",
                "container": [ "type": "auto" ]
            ]
        case "image_generation":
            return [
                "type": "image_generation"
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
            return model.starts(with: "gpt-4") || model.starts(with: "o1") || model.starts(with: "o3")
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
    
    /// Adds a file to a vector store
    /// - Parameters:
    ///   - vectorStoreId: The ID of the vector store
    ///   - fileId: The ID of the file to add
    /// - Returns: The vector store file relationship
    func addFileToVectorStore(vectorStoreId: String, fileId: String) async throws -> VectorStoreFile {
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
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
}
