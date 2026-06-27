import Foundation

/// Represents an OpenAI Assistant object.
struct Assistant: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let createdAt: Int
    let name: String?
    let description: String?
    let model: String
    let instructions: String?
    let tools: [AssistantTool]
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, name, description, model, instructions, tools, metadata
        case createdAt = "created_at"
    }
}

/// Represents a tool in the Assistants API.
struct AssistantTool: Codable, Hashable {
    let type: String // "code_interpreter", "file_search", "function"
    let function: AssistantFunctionDefinition?
}

/// Represents the definition of a function tool.
struct AssistantFunctionDefinition: Codable, Hashable {
    let name: String
    let description: String?
    let parameters: [String: AnyCodable]?
}

/// Represents an Assistants API Thread.
struct AssistantThread: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let createdAt: Int
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, metadata
        case createdAt = "created_at"
    }
}

/// Represents a message in an Assistant Thread.
struct AssistantMessage: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let role: String // "user" or "assistant"
    let content: [AssistantMessageContent]
    let assistantId: String?
    let runId: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, role, content, metadata
        case createdAt = "created_at"
        case threadId = "thread_id"
        case assistantId = "assistant_id"
        case runId = "run_id"
    }
}

/// Represents message content structure.
struct AssistantMessageContent: Codable, Hashable {
    let type: String // "text" or "image_file"
    let text: AssistantMessageText?
}

/// Represents message content text object.
struct AssistantMessageText: Codable, Hashable {
    let value: String
    let annotations: [AssistantMessageAnnotation]?
}

/// Represents message content annotations.
struct AssistantMessageAnnotation: Codable, Hashable {
    let type: String
    let text: String
    let fileCitation: AssistantFileCitation?
    let startIndex: Int?
    let endIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case fileCitation = "file_citation"
        case startIndex = "start_index"
        case endIndex = "end_index"
    }
}

/// Represents message content file citation details.
struct AssistantFileCitation: Codable, Hashable {
    let fileId: String
    
    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
    }
}

/// Represents a Run of an Assistant Thread.
struct AssistantRun: Codable, Identifiable, Hashable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let assistantId: String
    let status: String // "queued", "in_progress", "requires_action", "completed", "failed", "cancelled", "expired"
    let requiredAction: AssistantRequiredAction?
    let lastError: AssistantRunError?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status
        case createdAt = "created_at"
        case threadId = "thread_id"
        case assistantId = "assistant_id"
        case requiredAction = "required_action"
        case lastError = "last_error"
    }
}

/// Represents an error detail on an Assistant Run.
struct AssistantRunError: Codable, Hashable {
    let code: String
    let message: String
}

/// Represents required action on a Run (e.g. function call outputs).
struct AssistantRequiredAction: Codable, Hashable {
    let type: String // "submit_tool_outputs"
    let submitToolOutputs: AssistantSubmitToolOutputsAction?
    
    enum CodingKeys: String, CodingKey {
        case type
        case submitToolOutputs = "submit_tool_outputs"
    }
}

/// Represents action payload for tool outputs.
struct AssistantSubmitToolOutputsAction: Codable, Hashable {
    let toolCalls: [AssistantToolCall]
    
    enum CodingKeys: String, CodingKey {
        case toolCalls = "tool_calls"
    }
}

/// Represents an assistant tool call.
struct AssistantToolCall: Codable, Hashable {
    let id: String
    let type: String // "function"
    let function: AssistantFunctionCall
}

/// Represents an assistant function call.
struct AssistantFunctionCall: Codable, Hashable {
    let name: String
    let arguments: String // JSON string
}

/// Represents delta updates in a streaming thread message.
struct AssistantMessageDelta: Codable, Hashable {
    let id: String
    let delta: AssistantMessageDeltaPayload
}

/// Represents delta payload in a streaming thread message.
struct AssistantMessageDeltaPayload: Codable, Hashable {
    let content: [AssistantMessageDeltaContent]?
}

/// Represents delta content array item.
struct AssistantMessageDeltaContent: Codable, Hashable {
    let index: Int
    let type: String // "text"
    let text: AssistantMessageDeltaText?
}

/// Represents delta text value.
struct AssistantMessageDeltaText: Codable, Hashable {
    let value: String?
}

/// Enumeration of all stream events returned by the Assistants API.
enum AssistantsStreamEvent {
    case threadCreated(AssistantThread)
    case threadRunCreated(AssistantRun)
    case threadRunQueued(AssistantRun)
    case threadRunInProgress(AssistantRun)
    case threadRunRequiresAction(AssistantRun)
    case threadRunCompleted(AssistantRun)
    case threadRunFailed(AssistantRun)
    case threadMessageCreated(AssistantMessage)
    case threadMessageDelta(AssistantMessageDelta)
    case threadMessageCompleted(AssistantMessage)
    case error(AssistantRunError)
    case unknown(event: String, data: String)
}

/// Wrapper for list response.
struct AssistantListResponse<T: Codable>: Codable {
    let object: String
    let data: [T]
}
