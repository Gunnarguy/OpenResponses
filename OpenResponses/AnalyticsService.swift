import Foundation
import SwiftUI
import OSLog
import Combine
// Import necessary for StreamingEvent model
// Note: If SwiftUI is importing the model automatically, this may not be needed

/// Represents an API request for inspection and debugging
class APIRequestRecord: Identifiable, ObservableObject {
    let id = UUID()
    let timestamp = Date()
    let url: URL
    let method: String
    let headers: [String: Any]
    let body: Data
    @Published var response: APIResponseRecord?
    
    init(url: URL, method: String, headers: [String: Any], body: Data) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

/// Represents an API response for inspection and debugging
struct APIResponseRecord {
    let timestamp = Date()
    let statusCode: Int
    let headers: [String: Any]
    let body: Data
}

/// A lightweight analytics service for tracking app usage and events.
/// This implementation doesn't send data to any external service by default.
/// Replace the implementation with your preferred analytics provider when ready.
class AnalyticsService: ObservableObject {
    // MARK: - Singleton
    
    static let shared = AnalyticsService()
    private init() {}
    
    // MARK: - API Request History
    
    @Published var apiRequestHistory: [APIRequestRecord] = []
    private let maxHistorySize = 20 // Keep last 20 requests
    
    // MARK: - Configuration
    
    /// Whether analytics are enabled. Users should be able to toggle this.
    @AppStorage("analyticsEnabled") private var analyticsEnabled: Bool = true
    
    /// Whether detailed network logging is enabled
    @AppStorage("detailedNetworkLogging") private var detailedNetworkLogging: Bool = true
    
    // MARK: - Event Tracking
    
    /// Track a screen view.
    /// - Parameter screenName: The name of the screen that was viewed.
    func trackScreenView(_ screenName: String) {
        guard analyticsEnabled else { return }
        
        // Log locally for now
        AppLogger.log("Screen viewed: \(screenName)", category: .ui)
        
        // When ready, implement your analytics provider here:
        // AnalyticsProvider.logScreenView(screenName)
    }
    
    /// Track a specific event.
    /// - Parameters:
    ///   - name: The name of the event.
    ///   - parameters: Additional parameters to associate with the event.
    func trackEvent(name: String, parameters: [String: Any]? = nil) {
        guard analyticsEnabled else { return }
        
        // Log locally for now
        if let parameters = parameters {
            AppLogger.log("Event: \(name), params: \(parameters)", category: .ui)
        } else {
            AppLogger.log("Event: \(name)", category: .ui)
        }
        
        // When ready, implement your analytics provider here:
        // AnalyticsProvider.logEvent(name, parameters: parameters)
    }
    
    /// Track an error event.
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - context: Additional context about where the error occurred.
    func trackError(_ error: Error, context: String) {
        guard analyticsEnabled else { return }
        
        // Log locally for now
        AppLogger.logError(error, message: "Error in \(context)", category: .general)
        
        // When ready, implement your analytics provider here:
        // AnalyticsProvider.logError(error, context: context)
    }
    
    // MARK: - Network Logging
    
    /// Log detailed information about an API request.
    /// - Parameters:
    ///   - url: The URL of the request.
    ///   - method: The HTTP method used.
    ///   - headers: The request headers.
    ///   - body: The request body, if any.
    func logAPIRequest(url: URL, method: String, headers: [String: String], body: Data?) {
        guard detailedNetworkLogging else { return }
        
        // Store request for inspection
        let requestRecord = APIRequestRecord(
            url: url,
            method: method,
            headers: headers,
            body: body ?? Data()
        )
        
        DispatchQueue.main.async {
            self.apiRequestHistory.append(requestRecord)
            // Keep only the most recent requests
            if self.apiRequestHistory.count > self.maxHistorySize {
                self.apiRequestHistory.removeFirst()
            }
        }
        
        // Use the enhanced AppLogger method for OpenAI API requests
        if url.absoluteString.contains("openai.com") {
            AppLogger.logOpenAIRequest(url: url, method: method, headers: headers, body: body)
        } else {
            var logMessage = "📤 API REQUEST: \(method) \(url.absoluteString)\n"
            logMessage += "📤 HEADERS: \(redactSensitiveHeaders(headers))\n"
            
            if let body = body, let bodyString = prettyPrintJSON(body) {
                logMessage += "📤 BODY: \(bodyString)"
            }
            
            AppLogger.log(logMessage, category: .network, level: .debug)
        }
    }
    
    /// Log detailed information about an API response.
    /// - Parameters:
    ///   - url: The URL of the request.
    ///   - statusCode: The HTTP status code.
    ///   - headers: The response headers.
    ///   - body: The response body, if any.
    func logAPIResponse(url: URL, statusCode: Int, headers: [AnyHashable: Any], body: Data?) {
        guard detailedNetworkLogging else { return }
        
        // Find the corresponding request and attach the response
        if let lastRequest = apiRequestHistory.last(where: { $0.url == url }) {
            let responseRecord = APIResponseRecord(
                statusCode: statusCode,
                headers: Dictionary(uniqueKeysWithValues: headers.map { (String(describing: $0.key), $0.value) }),
                body: body ?? Data()
            )
            DispatchQueue.main.async {
                lastRequest.response = responseRecord
            }
        }
        
        // Use the enhanced AppLogger method for OpenAI API responses
        if url.absoluteString.contains("openai.com") {
            AppLogger.logOpenAIResponse(url: url, statusCode: statusCode, headers: headers, body: body)
        } else {
            let success = statusCode >= 200 && statusCode < 300
            let emoji = success ? "📥" : "⚠️"
            
            var logMessage = "\(emoji) API RESPONSE: \(statusCode) \(url.absoluteString)\n"
            logMessage += "\(emoji) HEADERS: \(headers)\n"
            
            if let body = body, let bodyString = prettyPrintJSON(body) {
                logMessage += "\(emoji) BODY: \(bodyString)"
            }
            
            let level: AppLogger.Level = success ? .debug : .warning
            AppLogger.log(logMessage, category: .network, level: level)
        }
    }
    
    /// Log streaming events from the API.
    /// - Parameters:
    ///   - eventType: The type of streaming event.
    ///   - data: The raw event data.
    ///   - parsedEvent: The parsed event object, if available.
    func logStreamingEvent(eventType: String, data: String, parsedEvent: Any?) {
        guard detailedNetworkLogging else { return }
        
        // Use the enhanced AppLogger method for structured streaming events
        if let event = parsedEvent as? StreamingEvent {
            AppLogger.logStructuredStreamingEvent(event: event, rawData: data)
        } else {
            // Fallback to the basic streaming event logging
            AppLogger.logStreamingEvent(eventType: eventType, data: data, parsedEvent: parsedEvent)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Clears the API request history.
    func clearRequestHistory() {
        DispatchQueue.main.async {
            self.apiRequestHistory.removeAll()
        }
    }
    
    /// Formats JSON data for better readability.
    /// - Parameter data: The JSON data to format.
    /// - Returns: A formatted JSON string, or nil if the data couldn't be formatted.
    private func prettyPrintJSON(_ data: Data) -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return String(data: data, encoding: .utf8) ?? "Invalid JSON data"
        }
    }
    
    /// Removes sensitive information from request headers.
    /// - Parameter headers: The original headers.
    /// - Returns: Redacted headers.
    private func redactSensitiveHeaders(_ headers: [String: String]) -> [String: String] {
        var redactedHeaders = headers
        
        // Redact API keys or tokens
        if redactedHeaders["Authorization"] != nil {
            if let auth = redactedHeaders["Authorization"], auth.starts(with: "Bearer ") {
                redactedHeaders["Authorization"] = "Bearer sk-***REDACTED***"
            }
        }
        
        return redactedHeaders
    }
}

// MARK: - Analytics Event Names

/// Constants for analytics event names to ensure consistency.
enum AnalyticsEvent {
    // App lifecycle events
    static let appLaunch = "app_launch"
    static let appBackground = "app_background"
    static let appForeground = "app_foreground"
    
    // Chat events
    static let messageSent = "message_sent"
    static let messageReceived = "message_received"
    static let conversationCleared = "conversation_cleared"
    
    // Network events
    static let apiRequestSent = "api_request_sent"
    static let apiResponseReceived = "api_response_received"
    static let streamingEventReceived = "streaming_event_received"
    static let networkError = "network_error"
    
    // Feature usage events
    static let fileAttached = "file_attached"
    static let settingsChanged = "settings_changed"
    static let toolEnabled = "tool_enabled"
    static let toolDisabled = "tool_disabled"
    static let presetSaved = "preset_saved"
    static let presetLoaded = "preset_loaded"
}

/// Constants for analytics parameter names to ensure consistency.
enum AnalyticsParameter {
    static let model = "model"
    static let messageLength = "message_length"
    static let responseTime = "response_time"
    static let streamingEnabled = "streaming_enabled"
    static let toolsUsed = "tools_used"
    static let settingName = "setting_name"
    static let settingValue = "setting_value"
    static let errorCode = "error_code"
    static let errorDomain = "error_domain"
    
    // Network parameters
    static let endpoint = "endpoint"
    static let statusCode = "status_code"
    static let requestMethod = "request_method"
    static let requestSize = "request_size"
    static let responseSize = "response_size"
    static let eventType = "event_type"
    static let sequenceNumber = "sequence_number"
}
