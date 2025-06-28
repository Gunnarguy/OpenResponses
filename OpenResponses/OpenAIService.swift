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
            "input": [
                [
                    "role": "user",
                    "content": userMessage  // Sending the user message as the conversation input
                ]
            ],
            "store": true  // store conversation on API side to enable previous_response_id continuity
        ]
        
        // Build tools array based on user preferences
        var tools: [[String: Any]] = []
        
        // Add web search tool if enabled
        if UserDefaults.standard.bool(forKey: "enableWebSearch") {
            tools.append(createToolConfiguration(for: "web_search_preview"))
        }
        
        // Add code interpreter tool if enabled
        if UserDefaults.standard.bool(forKey: "enableCodeInterpreter") {
            tools.append(createToolConfiguration(for: "code_interpreter"))
        }
        
        // Add image generation tool if enabled
        if UserDefaults.standard.bool(forKey: "enableImageGeneration") {
            tools.append(createToolConfiguration(for: "image_generation"))
        }
        
        // Only add tools array if there are tools enabled
        if !tools.isEmpty {
            requestObject["tools"] = tools
        }
        
        // Debug: Print tools configuration
        print("Tools enabled: \(tools.count) tools")
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
    
    /// Creates a properly formatted tool configuration based on current API requirements
    /// - Parameter toolType: The type of tool ("web_search_preview", "code_interpreter", "image_generation")
    /// - Returns: A dictionary representing the tool configuration
    private func createToolConfiguration(for toolType: String) -> [String: Any] {
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
        default:
            return [:]
        }
    }
}
