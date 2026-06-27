import Foundation

class BatchService {
    static let shared = BatchService()
    
    private let baseURL = "https://api.openai.com/v1"
    
    private init() {}
    
    private var apiKey: String? {
        KeychainService.shared.load(forKey: "openAIKey")
    }
    
    private func createHeaders() throws -> [String: String] {
        guard let key = apiKey, !key.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        return [
            "Authorization": "Bearer \(key)",
            "Content-Type": "application/json"
        ]
    }
    
    /// Compiles an array of BatchInputLine requests into a single .jsonl Data payload.
    func compileJSONL(lines: [BatchInputLine]) throws -> Data {
        let encoder = JSONEncoder()
        var jsonlString = ""
        for line in lines {
            let data = try encoder.encode(line)
            if let string = String(data: data, encoding: .utf8) {
                jsonlString += string + "\n"
            }
        }
        return Data(jsonlString.utf8)
    }
    
    func submitBatch(inputFileId: String, endpoint: String = "/v1/chat/completions") async throws -> BatchJob {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/batches")!
        
        let requestBody: [String: Any] = [
            "input_file_id": inputFileId,
            "endpoint": endpoint,
            "completion_window": "24h"
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(BatchJob.self, from: data)
    }
    
    func retrieveBatch(batchId: String) async throws -> BatchJob {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/batches/\(batchId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(BatchJob.self, from: data)
    }
    
    func listBatches() async throws -> [BatchJob] {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/batches")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        let listResponse = try JSONDecoder().decode(AssistantListResponse<BatchJob>.self, from: data)
        return listResponse.data
    }
    
    func cancelBatch(batchId: String) async throws -> BatchJob {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/batches/\(batchId)/cancel")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        return try JSONDecoder().decode(BatchJob.self, from: data)
    }
    
    /// Downloads the result file content as String.
    func downloadBatchResult(fileId: String) async throws -> String {
        guard let key = apiKey, !key.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/files/\(fileId)/content")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenAIServiceError.requestFailed(httpResponse.statusCode, errorMsg)
        }
        
        guard let contentString = String(data: data, encoding: .utf8) else {
            throw OpenAIServiceError.invalidResponseData
        }
        
        return contentString
    }
}
