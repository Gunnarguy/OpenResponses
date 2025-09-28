import Foundation
import os.log

// Import StreamingEvent model
import SwiftUI // This should already be there for access to UI types

/// A logging utility for the OpenResponses app.
enum AppLogger {
    /// Log categories for different parts of the app.
    enum Category: String {
        case network = "Network"
        case ui = "UI"
        case fileManager = "FileManager"
        case chat = "Chat"
        case general = "General"
        case openAI = "OpenAI"  // Dedicated category for OpenAI API
        case streaming = "Streaming" // Dedicated category for streaming events
    }
    
    /// Log levels for different severity of messages.
    enum Level {
        case debug
        case info
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
    
    /// Shared logger instance
    private static let logger = OSLog(subsystem: "com.gunndamental.OpenResponses", category: "App")
    
    /// Whether to print to console in DEBUG mode
    #if DEBUG
    static var consoleLoggingEnabled = true
    #else
    static var consoleLoggingEnabled = false
    #endif
    
    /// Whether to print duplicate logs for the same message
    static var allowDuplicateLogs = true  // Temporarily disabled to avoid crashes
    
    /// Store recent log messages to detect duplicates
    private static var recentLogMessages = [String: Date]()
    private static let recentLogMessagesQueue = DispatchQueue(label: "com.gunndamental.OpenResponses.recentLogs", attributes: .concurrent)
    
    /// Time window in seconds to consider logs as duplicates
    private static let duplicateWindowSeconds: TimeInterval = 1.0
    
    /// Log level for OpenAI API requests and responses
    /// This allows quick adjustment of verbosity for API logs
    static var openAILogLevel: Level = .debug
    /// When true, requests/responses bodies are omitted to keep logs concise
    static var minimizeOpenAILogBodies: Bool = UserDefaults.standard.bool(forKey: "minimizeOpenAILogBodies") {
        didSet {
            log("Minimize API Log Bodies set to: \(minimizeOpenAILogBodies)", category: .openAI, level: .info)
        }
    }

    // MARK: - Log Sanitization Helpers

    /// Max number of characters to include from any long string in logs
    private static let maxStringPreview = 400
    /// Keys that are likely to contain large base64 or data-URIs
    private static let heavyPayloadKeys: Set<String> = [
        "image_url", "partial_image_b64", "screenshot_b64", "image_b64", "partial_image", "imageData", "image"
    ]

    /// Returns a truncated version of the input string, preserving head/tail around an omission marker.
    private static func truncateMiddle(_ s: String, max: Int = maxStringPreview) -> String {
        guard s.count > max, max > 20 else { return s }
        let headCount = max / 2 - 5
        let tailCount = max / 2 - 5
        let head = s.prefix(headCount)
        let tail = s.suffix(tailCount)
        return String(head) + " …[truncated]… " + String(tail)
    }

    /// Heuristically redacts data-URI images and base64 blobs inside strings.
    private static func sanitizeString(_ s: String, shouldTruncate: Bool = true) -> String {
        // Redact data:image/*;base64,....
        if s.lowercased().hasPrefix("data:image/") {
            // Keep the header but remove the payload
            if let comma = s.firstIndex(of: ",") {
                let header = s[..<comma]
                let payloadLen = s[comma...].count - 1
                return "\(header),[\(payloadLen) chars base64 REDACTED]"
            } else {
                return "[data:image payload REDACTED]"
            }
        }
        // If string looks like long base64, truncate only if requested
        let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=\n\r")
        if s.count > 120, s.unicodeScalars.allSatisfy({ base64Chars.contains($0) }) {
            return shouldTruncate ? truncateMiddle(s) : s
        }
        // Generic truncation for very long strings - only if requested
        return shouldTruncate ? truncateMiddle(s) : s
    }

    /// Recursively sanitize a JSON object by redacting heavy fields.
    private static func sanitizeJSONObject(_ obj: Any) -> Any {
        switch obj {
        case var dict as [String: Any]:
            for (k, v) in dict {
                if let str = v as? String {
                    if heavyPayloadKeys.contains(k) || str.lowercased().hasPrefix("data:image/") || str.count > maxStringPreview {
                        dict[k] = sanitizeString(str)
                    }
                } else if v is [Any] || v is [String: Any] {
                    dict[k] = sanitizeJSONObject(v)
                }
            }
            return dict
        case let arr as [Any]:
            return arr.map { sanitizeJSONObject($0) }
        case let s as String:
            return sanitizeString(s)
        default:
            return obj
        }
    }
    
    /// Pretty print JSON Data with sanitization and truncation safeguards.
    private static func prettySanitizedJSON(_ data: Data) -> String? {
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []) {
            let sanitized = sanitizeJSONObject(obj)
            if let pretty = try? JSONSerialization.data(withJSONObject: sanitized, options: .prettyPrinted) {
                var s = String(data: pretty, encoding: .utf8)
                if let str = s, str.count > 2000 {
                    s = truncateMiddle(str, max: 2000)
                }
                return s
            }
        }
        // Fallback: raw string with generic truncation
        if let str = String(data: data, encoding: .utf8) {
            return truncateMiddle(str, max: 2000)
        }
        return nil
    }

    /// Public helper to get a sanitized preview of a JSON body for logging.
    /// Keeps internal sanitization centralized while letting other components request a preview.
    static func logOpenAIRequestBodyPreview(_ data: Data) -> String? {
        return prettySanitizedJSON(data)
    }
    
    /// Log a message with the specified category and level.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log.
    ///   - level: The severity level of the log.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func log(
        _ message: String,
        category: Category,
        level: Level = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        // Check for duplicate logs if feature is enabled
        if !allowDuplicateLogs {
            let now = Date()
            var shouldSkip = false
            
            recentLogMessagesQueue.sync {
                // Clean up old entries
                recentLogMessages = recentLogMessages.filter { _, timestamp in
                    now.timeIntervalSince(timestamp) < duplicateWindowSeconds
                }
                
                // Check if this is a duplicate message within the time window
                if recentLogMessages[logMessage] != nil {
                    shouldSkip = true
                } else {
                    // Store this message
                    recentLogMessages[logMessage] = now
                }
            }
            
            if shouldSkip {
                return
            }
        }
        
        // Send to system logger
        os_log("%{public}s", log: logger, type: level.osLogType, "\(level.emoji) \(logMessage)")
        
        // Also send to the debug console
        let consoleEntry = LogEntry(
            level: level.osLogType,
            category: category,
            message: message
        )
        ConsoleLogger.shared.addLog(consoleEntry)
    }
    
    /// Log an error with additional context.
    /// - Parameters:
    ///   - error: The error to log.
    ///   - message: An optional message providing context about the error.
    ///   - category: The category of the log.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func logError(
        _ error: Error,
        message: String? = nil,
        category: Category,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorMessage: String
        if let message = message {
            errorMessage = "\(message): \(error.localizedDescription)"
        } else {
            errorMessage = error.localizedDescription
        }
        
        log(
            errorMessage,
            category: category,
            level: .error,
            file: file,
            function: function,
            line: line
        )
    }
    
    // MARK: - OpenAI API Logging
    
    /// Log an OpenAI API request with detailed information.
    /// - Parameters:
    ///   - url: The URL of the request.
    ///   - method: The HTTP method.
    ///   - headers: The HTTP headers (sensitive info will be redacted).
    ///   - body: The request body.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func logOpenAIRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Redact sensitive headers
        var safeHeaders = headers
        if safeHeaders["Authorization"] != nil {
            if let auth = safeHeaders["Authorization"], auth.starts(with: "Bearer ") {
                safeHeaders["Authorization"] = "Bearer sk-***REDACTED***"
            }
        }
        
        var logMessage = "📤 API REQUEST: \(method) \(url.absoluteString)\n"
        logMessage += "📤 HEADERS: \(safeHeaders)"
        
        if !minimizeOpenAILogBodies {
            if let body = body, let pretty = prettySanitizedJSON(body) {
                logMessage += "\n📤 BODY: \(pretty)"
            }
        } else {
            logMessage += "\n📤 BODY: (omitted)"
        }
        
        log(
            logMessage,
            category: .openAI,
            level: openAILogLevel,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Log an OpenAI API response with detailed information.
    /// - Parameters:
    ///   - url: The URL of the request.
    ///   - statusCode: The HTTP status code.
    ///   - headers: The response headers.
    ///   - body: The response body.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func logOpenAIResponse(
        url: URL,
        statusCode: Int,
        headers: [AnyHashable: Any],
        body: Data?,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let success = statusCode >= 200 && statusCode < 300
        let emoji = success ? "📥" : "⚠️"
        let level: Level = success ? openAILogLevel : .warning
        
        var logMessage = "\(emoji) API RESPONSE: \(statusCode) \(url.absoluteString)\n"
        logMessage += "\(emoji) HEADERS: \(headers)"
        
        if !minimizeOpenAILogBodies {
            if let body = body, let pretty = prettySanitizedJSON(body) {
                logMessage += "\n\(emoji) BODY: \(pretty)"
            }
        } else {
            logMessage += "\n\(emoji) BODY: (omitted)"
        }
        
        log(
            logMessage,
            category: .openAI,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Log a streaming event from the OpenAI API.
    /// - Parameters:
    ///   - eventType: The type of streaming event.
    ///   - data: The raw JSON data.
    ///   - parsedEvent: The parsed event object.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func logStreamingEvent(
        eventType: String,
        data: String,
        parsedEvent: Any?,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var logMessage = "🔄 STREAMING EVENT: \(eventType)"
        // Only include payload details when not minimized
        if !minimizeOpenAILogBodies {
            // For failed responses, don't truncate at all to capture complete error details
            if eventType.contains("failed") || eventType.contains("error") {
                let safeData = sanitizeString(data, shouldTruncate: false)  // No truncation for errors
                logMessage += "\n🔄 RAW DATA: \(safeData)"
            } else {
                let safeData = truncateMiddle(sanitizeString(data), max: 600)
                logMessage += "\n🔄 RAW DATA: \(safeData)"
            }
            if let parsedEvent = parsedEvent {
                logMessage += "\n🔄 PARSED: \(parsedEvent)"
            }
        }
        
        log(
            logMessage,
            category: .streaming,
            level: openAILogLevel,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Log a structured streaming event with better format and filtering.
    /// - Parameters:
    ///   - event: The StreamingEvent to log.
    ///   - rawData: The raw JSON data string.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line where the log was called.
    static func logStructuredStreamingEvent(
        event: StreamingEvent,
        rawData: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var logMessage = "🔄 STREAMING EVENT: \(event.type) (seq: \(event.sequenceNumber))"
        
        // Add contextual information based on the event type
        if !minimizeOpenAILogBodies {
            switch event.type {
        case "response.created", "response.queued", "response.in_progress", "response.completed":
            if let response = event.response {
                logMessage += "\n🔄 RESPONSE ID: \(response.id)"
                logMessage += "\n🔄 STATUS: \(response.status ?? "unknown")"
                
                if let usage = response.usage, event.type == "response.completed" {
                    logMessage += "\n🔄 TOKENS: in=\(usage.inputTokens), out=\(usage.outputTokens), total=\(usage.totalTokens)"
                }
            }
            
        case "response.output_item.added", "response.output_item.done":
            logMessage += "\n🔄 OUTPUT INDEX: \(event.outputIndex ?? -1)"
            if let item = event.item {
                logMessage += "\n🔄 ITEM: \(item.id) (type: \(item.type))"
            }
            
        case "response.content_part.added", "response.content_part.done":
            if let itemId = event.itemId {
                logMessage += "\n🔄 ITEM ID: \(itemId)"
                logMessage += "\n🔄 CONTENT INDEX: \(event.contentIndex ?? -1)"
            }
            if let part = event.part {
                logMessage += "\n🔄 PART TYPE: \(part.type)"
                if let text = part.text, !text.isEmpty {
                    // Truncate long text content
                    let truncated = text.count > 100 ? text.prefix(100) + "..." : text
                    logMessage += "\n🔄 TEXT: \(truncated)"
                }
            }
            
        case "response.output_text.delta":
            if let itemId = event.itemId, let delta = event.delta {
                logMessage += "\n🔄 ITEM ID: \(itemId)"
                logMessage += "\n🔄 DELTA: \"\(delta)\""
            }
            
        case "response.output_text.done":
            if let itemId = event.itemId {
                logMessage += "\n🔄 ITEM ID: \(itemId)"
            }
            
        case "response.failed", "error":
            // For failed responses, include complete raw data without truncation for debugging
            let safeData = sanitizeString(rawData, shouldTruncate: false)
            logMessage += "\n🔄 RAW DATA: \(safeData)"
            if let response = event.response {
                logMessage += "\n🔄 RESPONSE ID: \(response.id)"
                logMessage += "\n🔄 STATUS: \(response.status ?? "failed")"
                if let error = response.error {
                    logMessage += "\n🔄 ERROR CODE: \(error.code ?? "unknown")"
                    logMessage += "\n🔄 ERROR MESSAGE: \(error.message)"
                }
            }
            
        default:
            // For unknown event types, include a sanitized snippet only
            let safe = truncateMiddle(sanitizeString(rawData), max: 600)
            logMessage += "\n🔄 RAW DATA: \(safe)"
            }
        }
        
        log(
            logMessage,
            category: .streaming,
            level: openAILogLevel,
            file: file,
            function: function,
            line: line
        )
    }
}
