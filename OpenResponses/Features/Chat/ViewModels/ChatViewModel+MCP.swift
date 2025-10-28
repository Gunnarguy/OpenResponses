import Foundation

extension ChatViewModel {
    /// Non-streaming convenience: invoke a specific MCP tool with JSON arguments.
    /// - Parameters:
    ///   - tool: MCP tool name exposed by the configured server
    ///   - args: Arguments dictionary (will be JSON-encoded)
    ///   - serverLabel: Optional override; defaults to activePrompt.mcpServerLabel
    /// - Returns: OpenAIResponse with final output
    @discardableResult
    func mcpCall(tool: String, args: [String: Any], serverLabel: String? = nil) async throws -> OpenAIResponse {
        let label = (serverLabel?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (activePrompt.mcpServerLabel.isEmpty ? nil : activePrompt.mcpServerLabel)

        guard let finalLabel = label, !finalLabel.isEmpty else {
            throw OpenAIServiceError.invalidRequest("No MCP server label configured. Set it in Settings → MCP Servers.")
        }

        let argumentsJSON: String
        do {
            let data = try JSONSerialization.data(withJSONObject: args, options: [])
            argumentsJSON = String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            throw OpenAIServiceError.invalidRequest("Failed to encode MCP arguments: \(error.localizedDescription)")
        }

        return try await api.callMCP(
            serverLabel: finalLabel,
            tool: tool,
            argumentsJSON: argumentsJSON,
            prompt: activePrompt
        )
    }

    /// Streaming convenience: invoke a specific MCP tool with JSON arguments and get events.
    /// - Parameters:
    ///   - tool: MCP tool name
    ///   - args: Arguments dictionary (will be JSON-encoded)
    ///   - serverLabel: Optional override; defaults to activePrompt.mcpServerLabel
    /// - Returns: Async stream of StreamingEvent
    func mcpStream(tool: String, args: [String: Any], serverLabel: String? = nil) -> AsyncThrowingStream<StreamingEvent, Error> {
        let label = (serverLabel?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? (activePrompt.mcpServerLabel.isEmpty ? nil : activePrompt.mcpServerLabel)

        guard let finalLabel = label, !finalLabel.isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: OpenAIServiceError.invalidRequest("No MCP server label configured. Set it in Settings → MCP Servers."))
            }
        }

        let argumentsJSON: String
        do {
            let data = try JSONSerialization.data(withJSONObject: args, options: [])
            argumentsJSON = String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: OpenAIServiceError.invalidRequest("Failed to encode MCP arguments: \(error.localizedDescription)"))
            }
        }

        return api.callMCP(
            serverLabel: finalLabel,
            tool: tool,
            argumentsJSON: argumentsJSON,
            prompt: activePrompt,
            stream: true
        )
    }
}
