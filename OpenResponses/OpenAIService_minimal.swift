import Foundation
import SwiftUI

/// A minimal test version of OpenAIService with only essential parameters
class OpenAIServiceMinimal: OpenAIServiceProtocol {
    private let apiURL = URL(string: "https://api.openai.com/v1/responses")!
    
    private struct ErrorResponse: Decodable {
        let error: ErrorDetail
    }

    private struct ErrorDetail: Decodable {
        let message: String
    }
    
    func sendChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, imageAttachments: [InputImage]?, previousResponseId: String?) async throws -> OpenAIResponse {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        // Create minimal request with only essential parameters
        let requestObject: [String: Any] = [
            "model": prompt.openAIModel,
            "input": [["role": "user", "content": userMessage]],
            "instructions": prompt.systemInstructions.isEmpty ? "You are a helpful assistant." : prompt.systemInstructions
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestObject, options: .prettyPrinted)
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Minimal OpenAI Request JSON: \(jsonString)")
        }
        
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 120
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            var errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseString)")
            }
            
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(OpenAIResponse.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            throw OpenAIServiceError.invalidResponseData
        }
    }
    
    func streamChatRequest(userMessage: String, prompt: Prompt, attachments: [[String: Any]]?, fileData: [Data]?, fileNames: [String]?, imageAttachments: [InputImage]?, previousResponseId: String?) -> AsyncThrowingStream<StreamingEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                // For minimal testing, just throw an error since streaming is complex
                continuation.finish(throwing: OpenAIServiceError.requestFailed(501, "Streaming not implemented in minimal version"))
            }
        }
    }
    
    func sendFunctionOutput(call: OutputItem, output: String, model: String, previousResponseId: String?) async throws -> OpenAIResponse {
        throw OpenAIServiceError.requestFailed(501, "Function output not implemented in minimal version")
    }
    
    func sendComputerCallOutput(call: StreamingItem, output: Any, model: String, previousResponseId: String?, acknowledgedSafetyChecks: [SafetyCheck]? = nil, currentUrl: String? = nil) async throws -> OpenAIResponse {
        throw OpenAIServiceError.requestFailed(501, "Computer call output not implemented in minimal version")
    }
    
    func sendComputerCallOutput(callId: String, output: Any, model: String, previousResponseId: String?, acknowledgedSafetyChecks: [SafetyCheck]? = nil, currentUrl: String? = nil) async throws -> OpenAIResponse {
        throw OpenAIServiceError.requestFailed(501, "Computer call output not implemented in minimal version")
    }
    
    // MARK: - Backward compatibility methods for computer use
    
    func sendComputerCallOutput(call: StreamingItem, output: Any, model: String, previousResponseId: String?) async throws -> OpenAIResponse {
        return try await sendComputerCallOutput(
            call: call,
            output: output,
            model: model,
            previousResponseId: previousResponseId,
            acknowledgedSafetyChecks: nil,
            currentUrl: nil
        )
    }
    
    func sendComputerCallOutput(callId: String, output: Any, model: String, previousResponseId: String?) async throws -> OpenAIResponse {
        return try await sendComputerCallOutput(
            callId: callId,
            output: output,
            model: model,
            previousResponseId: previousResponseId,
            acknowledgedSafetyChecks: nil,
            currentUrl: nil
        )
    }
    
    // Protocol stub implementations
    func getResponse(responseId: String) async throws -> OpenAIResponse {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func deleteResponse(responseId: String) async throws -> DeleteResponseResult {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func cancelResponse(responseId: String) async throws -> OpenAIResponse {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func listInputItems(responseId: String) async throws -> InputItemsResponse {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func fetchImageData(for imageContent: ContentItem) async throws -> Data {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func uploadFile(fileData: Data, filename: String, purpose: String) async throws -> OpenAIFile {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func listFiles(purpose: String?) async throws -> [OpenAIFile] {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func deleteFile(fileId: String) async throws {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func createVectorStore(name: String, fileIds: [String]?) async throws -> VectorStore {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }
    
    func listModels() async throws -> [OpenAIModel] {
        throw OpenAIServiceError.requestFailed(501, "Not implemented in minimal version")
    }

    // No audio transcription in minimal version

}
