import Foundation

/// Provides concise user-facing summaries for tool call outputs.
enum FunctionOutputSummarizer {
    /// Builds a short failure summary from a raw tool output string.
    /// - Parameters:
    ///   - functionName: Name of the function that produced the output.
    ///   - rawOutput: Full string returned by the function.
    /// - Returns: A formatted summary when the output represents an error; otherwise `nil`.
    static func failureSummary(functionName: String, rawOutput: String) -> String? {
        let trimmed = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let jsonError = extractJSONError(from: trimmed) {
            let prefix = stripRedundantPrefix(jsonError.prefix, functionName: functionName)
            let message = join(prefix: prefix, message: jsonError.message)
            return formatFailure(functionName: functionName, message: message)
        }

        let lower = trimmed.lowercased()
        let isLikelyError = lower.hasPrefix("error") || lower.contains(" error") || lower.contains("request failed") || lower.contains("exception")
        guard isLikelyError else { return nil }

    let condensed = stripRedundantPrefix(trimmed, functionName: functionName) ?? trimmed
    return formatFailure(functionName: functionName, message: condensed)
    }

    /// Extracts the primary error message from a JSON error payload embedded in the output.
    private static func extractJSONError(from raw: String) -> (prefix: String?, message: String)? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else { return nil }
        let jsonString = String(raw[start...end])
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let object = json["object"] as? String, object == "error" else {
            return nil
        }

        var message = (json["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let codeComponent = (json["code"] ?? json["status"]).map { String(describing: $0) }
        if !message.isEmpty, let codeComponent {
            message = "\(message) (\(codeComponent))"
        } else if message.isEmpty, let codeComponent {
            message = codeComponent
        }

        if message.isEmpty {
            message = "Unknown error"
        }

        let prefix = raw[..<start].trimmingCharacters(in: .whitespacesAndNewlines)
        return (prefix.isEmpty ? nil : String(prefix), message)
    }

    /// Removes redundant boilerplate (e.g., "Error processing foo:") from the leading text.
    private static func stripRedundantPrefix(_ text: String?, functionName: String) -> String? {
        guard var text = text, !text.isEmpty else { return nil }
        let lower = text.lowercased()
        let needle = "error processing \(functionName.lowercased())"
        if lower.hasPrefix(needle) {
            if let colon = text.firstIndex(of: ":") {
                text = String(text[text.index(after: colon)...])
            } else {
                text = ""
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Joins optional prefix and message components with an em dash when both are present.
    private static func join(prefix: String?, message: String) -> String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let prefix = prefix?.trimmingCharacters(in: .whitespacesAndNewlines), !prefix.isEmpty else {
            return trimmedMessage
        }
        guard !trimmedMessage.isEmpty else { return prefix }
        return prefix + " — " + trimmedMessage
    }

    /// Formats the final failure string with consistent styling and length limits.
    private static func formatFailure(functionName: String, message: String) -> String {
        let condensed = message.count > 240 ? String(message.prefix(240)).trimmingCharacters(in: .whitespacesAndNewlines) + "…" : message
        return "⚠️ \(functionName) failed: \(condensed)"
    }
}
