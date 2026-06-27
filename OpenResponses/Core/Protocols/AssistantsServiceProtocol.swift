import Foundation

/// Protocol defining functions to interact with OpenAI Assistants API.
protocol AssistantsServiceProtocol {
    /// Lists all assistants available in the user's account.
    func listAssistants() async throws -> [Assistant]
    
    /// Creates a new assistant.
    func createAssistant(
        name: String?,
        model: String,
        instructions: String?,
        tools: [AssistantTool]?
    ) async throws -> Assistant
    
    /// Creates a new assistant thread.
    func createThread() async throws -> AssistantThread
    
    /// Creates a message in a specific assistant thread.
    func createMessage(
        threadId: String,
        role: String,
        content: String
    ) async throws -> AssistantMessage
    
    /// Runs an assistant on a thread and returns a stream of events.
    func createRun(
        threadId: String,
        assistantId: String
    ) -> AsyncThrowingStream<AssistantsStreamEvent, Error>
    
    /// Submits function/tool outputs back to a run that requires action and returns a stream of events.
    func submitToolOutputs(
        threadId: String,
        runId: String,
        outputs: [[String: Any]]
    ) -> AsyncThrowingStream<AssistantsStreamEvent, Error>
}
