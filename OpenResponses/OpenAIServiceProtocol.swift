import Foundation

/// Protocol defining the core functionality of the OpenAI service.
/// This makes the service more testable and allows for dependency injection.
protocol OpenAIServiceProtocol {
    /// Sends a chat request to the OpenAI API.
    func sendChatRequest(
        userMessage: String,
        prompt: Prompt,
        attachments: [[String: Any]]?,
        previousResponseId: String?
    ) async throws -> OpenAIResponse
    
    /// Streams a chat request and returns events as they arrive.
    func streamChatRequest(
        userMessage: String,
        prompt: Prompt,
        attachments: [[String: Any]]?,
        previousResponseId: String?
    ) -> AsyncThrowingStream<StreamingEvent, Error>
    
    /// Retrieves a response by ID.
    func getResponse(responseId: String) async throws -> OpenAIResponse
    
    /// Deletes a response by ID.
    func deleteResponse(responseId: String) async throws -> DeleteResponseResult
    
    /// Cancels a response that is in progress.
    func cancelResponse(responseId: String) async throws -> OpenAIResponse
    
    /// Returns a list of input items for a given response.
    func listInputItems(responseId: String) async throws -> InputItemsResponse
    
    /// Sends function output back to the API.
    func sendFunctionOutput(
        call: OutputItem,
        output: String,
        model: String,
        previousResponseId: String?
    ) async throws -> OpenAIResponse
    
    /// Fetches image data from the API.
    func fetchImageData(for imageContent: ContentItem) async throws -> Data
    
    /// Uploads a file to OpenAI.
    func uploadFile(
        fileData: Data,
        filename: String,
        purpose: String
    ) async throws -> OpenAIFile
    
    /// Lists files from OpenAI.
    func listFiles(purpose: String?) async throws -> [OpenAIFile]
    
    /// Deletes a file from OpenAI.
    func deleteFile(fileId: String) async throws
    
    /// Creates a vector store.
    func createVectorStore(
        name: String,
        fileIds: [String]?
    ) async throws -> VectorStore
    
    /// Lists available models from the OpenAI API.
    func listModels() async throws -> [OpenAIModel]
}

/// Network client protocol for handling HTTP requests to OpenAI.
/// This abstracts away the networking details from the service.
protocol OpenAINetworkClientProtocol {
    /// Performs a data request.
    func performRequest<T: Decodable>(
        endpoint: OpenAIEndpoint,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> T
    
    /// Performs a streaming request.
    func performStreamingRequest(
        endpoint: OpenAIEndpoint,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) -> AsyncThrowingStream<StreamingEvent, Error>
    
    /// Performs a file upload request.
    func uploadFile(
        endpoint: OpenAIEndpoint,
        fileData: Data,
        filename: String,
        purpose: String,
        apiKey: String
    ) async throws -> OpenAIFile
}

/// HTTP methods supported by the API.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

/// Represents OpenAI API endpoints.
enum OpenAIEndpoint {
    case responses
    case specificResponse(String)
    case files
    case specificFile(String)
    case fileContent(String)
    case vectorStores
    case specificVectorStore(String)
    
    /// Returns the full URL for the endpoint.
    var url: URL {
        let baseURL = "https://api.openai.com/v1"
        
        switch self {
        case .responses:
            return URL(string: "\(baseURL)/responses")!
        case .specificResponse(let id):
            return URL(string: "\(baseURL)/responses/\(id)")!
        case .files:
            return URL(string: "\(baseURL)/files")!
        case .specificFile(let id):
            return URL(string: "\(baseURL)/files/\(id)")!
        case .fileContent(let id):
            return URL(string: "\(baseURL)/files/\(id)/content")!
        case .vectorStores:
            return URL(string: "\(baseURL)/vector_stores")!
        case .specificVectorStore(let id):
            return URL(string: "\(baseURL)/vector_stores/\(id)")!
        }
    }
}

/// Enhanced error type for OpenAI service errors.
enum OpenAIServiceError: Error {
    case missingAPIKey
    case requestFailed(Int, String)  // HTTP status code and message
    case invalidResponseData
    case invalidRequest(String)
    case networkError(Error)
    case decodingError(Error)
    case rateLimited(Int, String)  // Retry after seconds and message
    case fileError(String)
    
    /// A user-friendly description of the error.
    var userFriendlyDescription: String {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please add your OpenAI API key in settings."
        case .requestFailed(let code, let message):
            return "Request failed with status code \(code): \(message)"
        case .invalidResponseData:
            return "Invalid response data received from the server."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError:
            return "Network error occurred. Please check your internet connection."
        case .decodingError:
            return "Error parsing the response from OpenAI."
        case .rateLimited(let seconds, _):
            return "Rate limited by OpenAI. Please try again in \(seconds) seconds."
        case .fileError(let message):
            return "File operation failed: \(message)"
        }
    }
    
    /// Whether this error can be retried.
    var isRetriable: Bool {
        switch self {
        case .networkError, .rateLimited:
            return true
        case .requestFailed(let code, _):
            // 5xx errors are server errors and can be retried
            return code >= 500 && code < 600
        default:
            return false
        }
    }
    
    /// Converts a general Error into a specific OpenAIServiceError case.
    static func from(error: Error) -> OpenAIServiceError {
        if let serviceError = error as? OpenAIServiceError {
            return serviceError
        }
        if let nsError = error as NSError? {
            if nsError.domain == NSURLErrorDomain {
                return .networkError(error)
            }
        }
        return .decodingError(error) // Fallback
    }
}
