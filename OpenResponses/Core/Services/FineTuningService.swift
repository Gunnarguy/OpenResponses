import Foundation

class FineTuningService {
    static let shared = FineTuningService()
    
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
    
    /// Formats an array of FineTuningConversation objects to JSONL data format.
    func compileFineTuningJSONL(conversations: [FineTuningConversation]) throws -> Data {
        let encoder = JSONEncoder()
        var jsonlString = ""
        for conversation in conversations {
            let data = try encoder.encode(conversation)
            if let string = String(data: data, encoding: .utf8) {
                jsonlString += string + "\n"
            }
        }
        return Data(jsonlString.utf8)
    }
    
    func createFineTuningJob(
        trainingFileId: String,
        model: String,
        nEpochs: String = "auto",
        batchSize: String = "auto",
        learningRateMultiplier: String = "auto"
    ) async throws -> FineTuningJob {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/fine_tuning/jobs")!
        
        var requestBody: [String: Any] = [
            "training_file": trainingFileId,
            "model": model
        ]
        
        var hyperparameters: [String: Any] = [:]
        
        if nEpochs != "auto", let epochsInt = Int(nEpochs) {
            hyperparameters["n_epochs"] = epochsInt
        } else if nEpochs == "auto" {
            hyperparameters["n_epochs"] = "auto"
        }
        
        if batchSize != "auto", let batchInt = Int(batchSize) {
            hyperparameters["batch_size"] = batchInt
        } else if batchSize == "auto" {
            hyperparameters["batch_size"] = "auto"
        }
        
        if learningRateMultiplier != "auto", let lrDouble = Double(learningRateMultiplier) {
            hyperparameters["learning_rate_multiplier"] = lrDouble
        } else if learningRateMultiplier == "auto" {
            hyperparameters["learning_rate_multiplier"] = "auto"
        }
        
        if !hyperparameters.isEmpty {
            requestBody["hyperparameters"] = hyperparameters
        }
        
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
        
        return try JSONDecoder().decode(FineTuningJob.self, from: data)
    }
    
    func listFineTuningJobs() async throws -> [FineTuningJob] {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/fine_tuning/jobs")!
        
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
        
        let listResponse = try JSONDecoder().decode(AssistantListResponse<FineTuningJob>.self, from: data)
        return listResponse.data
    }
    
    func cancelFineTuningJob(jobId: String) async throws -> FineTuningJob {
        let headers = try createHeaders()
        let url = URL(string: "\(baseURL)/fine_tuning/jobs/\(jobId)/cancel")!
        
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
        
        return try JSONDecoder().decode(FineTuningJob.self, from: data)
    }
}
