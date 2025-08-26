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
    static var allowDuplicateLogs = false
    
    /// Store recent log messages to detect duplicates
    private static var recentLogMessages = [String: Date]()
    
    /// Time window in seconds to consider logs as duplicates
    private static let duplicateWindowSeconds: TimeInterval = 1.0
    
    /// Log level for OpenAI API requests and responses
    /// This allows quick adjustment of verbosity for API logs
    static var openAILogLevel: Level = .debug
    
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
            
            // Clean up old entries
            recentLogMessages = recentLogMessages.filter { _, timestamp in
                now.timeIntervalSince(timestamp) < duplicateWindowSeconds
            }
            
            // Check if this is a duplicate message within the time window
            if recentLogMessages[logMessage] != nil {
                // Skip duplicate log
                return
            }
            
            // Store this message
            recentLogMessages[logMessage] = now
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
        
        if let body = body, let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []) {
            // Pretty print the JSON
            if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                logMessage += "\n📤 BODY: \(prettyString)"
            } else if let rawString = String(data: body, encoding: .utf8) {
                logMessage += "\n📤 BODY: \(rawString)"
            }
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
        
        if let body = body, let jsonObject = try? JSONSerialization.jsonObject(with: body, options: []) {
            // Pretty print the JSON
            if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                logMessage += "\n\(emoji) BODY: \(prettyString)"
            } else if let rawString = String(data: body, encoding: .utf8) {
                logMessage += "\n\(emoji) BODY: \(rawString)"
            }
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
        var logMessage = "🔄 STREAMING EVENT: \(eventType)\n"
        logMessage += "🔄 RAW DATA: \(data)"
        
        if let parsedEvent = parsedEvent {
            logMessage += "\n🔄 PARSED: \(parsedEvent)"
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
            
        default:
            // For unknown event types, include raw data for debugging
            logMessage += "\n🔄 RAW DATA: \(rawData)"
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
