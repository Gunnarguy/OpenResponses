import Foundation
import WebKit

/// An error related to the Computer Use feature.
enum ComputerUseError: Error, LocalizedError {
    case webViewNotAvailable
    case invalidActionType(String)
    case invalidParameters
    case javascriptError(String)
    case navigationFailed(Error)
    case screenshotFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .webViewNotAvailable:
            return "The web view is not available for computer use."
        case .invalidActionType(let type):
            return "The computer action type '\(type)' is not supported."
        case .invalidParameters:
            return "The parameters for the computer action were invalid."
        case .javascriptError(let error):
            return "A JavaScript error occurred: \(error)"
        case .navigationFailed(let error):
            return "The web view failed to navigate: \(error.localizedDescription)"
        case .screenshotFailed:
            return "Failed to capture a screenshot of the web view."
        case .invalidResponse:
            return "The response from the model was invalid for computer use."
        }
    }
}

/// Represents a single action to be performed by the computer use tool, decoded from a tool call.
struct ComputerAction: Decodable {
    /// The type of action to perform (e.g., "navigate", "click", "type").
    let type: String
    /// A dictionary of parameters for the action (e.g., "url" for "navigate", "x" and "y" for "click").
    let parameters: [String: Any]

    private enum CodingKeys: String, CodingKey {
        case type
        case parameters
    }
    
    /// Custom initializer for creating an action programmatically.
    init(type: String, parameters: [String: Any]) {
        self.type = type
        self.parameters = parameters
    }
    
    /// Decodes a `ComputerAction` from a decoder, handling flexible parameter types.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        // The parameters can be a mix of types, so we decode them into [String: AnyCodable]
        // and then extract the underlying `Any` value.
        if let params = try? container.decode([String: AnyCodable].self, forKey: .parameters) {
            parameters = params.reduce(into: [String: Any]()) { result, entry in
                if let value = entry.value.value {
                    result[entry.key] = value
                }
            }
        } else {
            parameters = [:]
        }
    }
}

/// The result of executing a computer action, to be sent back to the model.
struct ComputerActionResult {
    /// A base64-encoded screenshot of the web view after the action.
    let screenshot: String?
    /// The current URL of the web view after the action.
    let currentURL: String?
    /// Any textual output from the action (e.g., from a "getText" action).
    let output: String?
}

/// A compact description of an interactive or navigational element that is visible on the page.
struct BrowserElementDescriptor: Codable, Hashable {
    let text: String
    let hint: String?
    let type: String?
    let href: String?
    let role: String?
}

/// A DOM-aware snapshot of the currently visible page state for the live browser harness.
struct BrowserPageState: Codable, Hashable {
    let url: String?
    let title: String
    let readyState: String
    let visibleTextPreview: String
    let headings: [String]
    let buttons: [BrowserElementDescriptor]
    let links: [BrowserElementDescriptor]
    let inputs: [BrowserElementDescriptor]
}

/// The result of a DOM-aware browser automation command.
struct BrowserAutomationResult {
    let state: BrowserPageState
    let screenshot: String?
    let currentURL: String?
    let output: String?
}

/// Encodes a browser automation step so the model gets structured, compact page state back.
struct BrowserAutomationToolPayload: Codable {
    let action: String
    let output: String?
    let page: BrowserPageState
}
