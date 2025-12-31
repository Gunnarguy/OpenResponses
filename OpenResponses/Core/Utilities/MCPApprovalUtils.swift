import Foundation

/// Pure helpers for decoding/formatting MCP approval flows.
///
/// This exists primarily to keep parsing/formatting logic testable without
/// instantiating heavyweight objects like `ChatViewModel` (which wires up
/// networking, persistence, timers, etc.).
enum MCPApprovalUtils {
    static func buildMCPApprovalResponsePayload(
        approvalRequestId: String,
        approve: Bool,
        reason: String?
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "type": "mcp_approval_response",
            "approval_request_id": approvalRequestId,
            "approve": approve,
        ]

        if let reason, !reason.isEmpty, !approve {
            payload["reason"] = reason
        }

        return payload
    }

    static func buildTextFromApprovalRequests(_ requests: [MCPApprovalRequest]) -> String? {
        guard !requests.isEmpty else { return nil }

        let sections = requests.map { request in
            makeApprovalSummary(
                toolName: request.toolName,
                serverLabel: request.serverLabel,
                rawArguments: request.arguments
            )
        }

        let joined = sections
            .joined(separator: "\n\n---\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return joined.isEmpty ? nil : joined
    }

    /// Extracts `MCPApprovalRequest` objects from the final list of streaming output items.
    ///
    /// - Returns: A tuple of requests and the resolved last server label (useful for callers that want to cache it).
    static func extractApprovalRequests(
        from items: [StreamingOutputItem]?,
        prompt: Prompt,
        lastServerLabel: String? = nil
    ) -> (requests: [MCPApprovalRequest], resolvedLastServerLabel: String?) {
        guard let items else { return ([], lastServerLabel) }

        var collected: [MCPApprovalRequest] = []
        var seenIds = Set<String>()
        var resolvedLast = lastServerLabel

        for item in items where item.type == "mcp_approval_request" {
            guard let tool = item.name else { continue }

            let resolved = resolveServerLabel(
                serverLabel: item.serverLabel,
                itemServerLabel: item.serverLabel,
                fallbackId: item.id,
                lastMCPServerLabel: resolvedLast,
                prompt: prompt
            )

            let server = resolved.label
            resolvedLast = server

            let identifier = item.approvalRequestId ?? item.id
            if seenIds.contains(identifier) { continue }
            seenIds.insert(identifier)

            let args = item.arguments ?? "{}"
            let request = MCPApprovalRequest(
                id: identifier,
                toolName: tool,
                serverLabel: server,
                arguments: args,
                status: .pending,
                reason: nil
            )
            collected.append(request)
        }

        return (collected, resolvedLast)
    }

    // MARK: - Formatting

    private static func makeApprovalSummary(toolName: String, serverLabel: String, rawArguments: String) -> String {
        var parts = ["Approval required to run **\(toolName)** on **\(serverLabel)**."]
        if let prettyArgs = prettyPrintArguments(rawArguments) {
            parts.append("Arguments:\n```json\n\(prettyArgs)\n```")
        }
        return parts.joined(separator: "\n\n")
    }

    private static func prettyPrintArguments(_ json: String) -> String? {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "{}", let data = trimmed.data(using: .utf8) else { return nil }

        do {
            let object = try JSONSerialization.jsonObject(with: data)

            if let dict = object as? [String: Any], !dict.isEmpty {
                let pretty = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
                return String(data: pretty, encoding: .utf8)
            }

            if let array = object as? [Any], !array.isEmpty {
                let pretty = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
                return String(data: pretty, encoding: .utf8)
            }

            if let value = object as? CustomStringConvertible {
                return value.description
            }
        } catch {
            // Formatting is best-effort; callers can fall back to raw JSON.
        }

        return nil
    }

    // MARK: - Label resolution

    private static func resolveServerLabel(
        serverLabel: String?,
        itemServerLabel: String?,
        fallbackId: String?,
        lastMCPServerLabel: String?,
        prompt: Prompt
    ) -> (label: String, usedFallback: Bool) {
        if let direct = trimmedIfNotEmpty(serverLabel) {
            return (direct, false)
        }
        if let alternate = trimmedIfNotEmpty(itemServerLabel) {
            return (alternate, false)
        }
        if let cached = trimmedIfNotEmpty(lastMCPServerLabel) {
            return (cached, true)
        }
        if let promptLabel = trimmedIfNotEmpty(prompt.mcpServerLabel) {
            return (promptLabel, true)
        }
        if prompt.mcpIsConnector, let connectorId = prompt.mcpConnectorId,
           let connector = MCPConnector.connector(for: connectorId)
        {
            return (connector.name, true)
        }
        if let fallbackId, !fallbackId.isEmpty {
            return ("MCP \(String(fallbackId.prefix(6)))", true)
        }
        return ("MCP Server", true)
    }

    private static func trimmedIfNotEmpty(_ value: String?) -> String? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        return raw
    }
}
