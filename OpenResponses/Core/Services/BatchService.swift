import Foundation

class BatchService {
    static let shared = BatchService()
    
    private let baseURL = "https://api.openai.com/v1"
    
    private let download: (URLRequest) async throws -> (URL, URLResponse)

    init(download: @escaping (URLRequest) async throws -> (URL, URLResponse) = { request in
        try await URLSession.shared.download(for: request)
    }) {
        self.download = download
    }
    
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
        try await ResourcePagination.list(path: "/batches", as: BatchJob.self)
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
    
    /// Download directly to disk so large result/error files never become a truncated UI string.
    func downloadBatchResult(fileId: String, isErrorFile: Bool = false) async throws -> URL {
        var request = try ResponsesAPIClient().request(path: "/files/\(fileId)/content", method: "GET")
        request.timeoutInterval = 120
        let (temporaryURL, response) = try await download(request)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        // Error responses are small JSON; successful files stay on disk.
        if (response as? HTTPURLResponse)?.statusCode != 200 {
            let errorData = (try? Data(contentsOf: temporaryURL)) ?? Data()
            try ResponsesAPIClient.validate(response, data: errorData)
        }
        try Task.checkCancellation()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("BatchExports", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let output = directory.appendingPathComponent(isErrorFile ? "batch-errors.jsonl" : "batch-results.jsonl")
        try FileManager.default.moveItem(at: temporaryURL, to: output)
        return output
    }
}
