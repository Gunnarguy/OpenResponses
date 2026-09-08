import Foundation
import CoreFoundation

/// Local checks catch malformed configuration without rewriting the user's schema.
/// OpenAI remains authoritative for model-specific JSON Schema support.
enum ResponseConfigurationValidation {
    static func object(_ text: String, label: String) throws -> [String: Any] {
        let value: Any
        do { value = try JSONSerialization.jsonObject(with: Data(text.utf8), options: .fragmentsAllowed) }
        catch { throw OpenAIServiceError.invalidRequest("\(label) contains invalid JSON. Check commas, quotes, and braces.") }
        guard let object = value as? [String: Any] else {
            throw OpenAIServiceError.invalidRequest("\(label) must be a JSON object, not an array or scalar.")
        }
        return object
    }

    static func validate(_ prompt: Prompt) throws {
        if prompt.textFormatType == "json_schema" {
            try name(prompt.jsonSchemaName, label: "Schema name")
            try schema(object(prompt.jsonSchemaContent, label: "Output schema"), strict: prompt.jsonSchemaStrict, path: "Output schema")
        }
        if prompt.enableCustomTool {
            try name(prompt.customToolName, label: "Custom tool name")
            try schema(object(prompt.customToolParametersJSON, label: "Custom tool parameters"), strict: false, path: "Custom tool parameters")
        }
    }

    static func validate(body: [String: Any]) throws {
        if let error = body["validation_error"] as? String { throw OpenAIServiceError.invalidRequest(error) }
        if let text = body["text"] as? [String: Any], let format = text["format"] as? [String: Any], format["type"] as? String == "json_schema" {
            try name(format["name"] as? String ?? "", label: "text.format.name")
            guard let value = format["schema"] as? [String: Any] else {
                throw OpenAIServiceError.invalidRequest("text.format.schema must be a JSON object.")
            }
            try schema(value, strict: format["strict"] as? Bool == true, path: "text.format.schema")
        }
        for tool in body["tools"] as? [[String: Any]] ?? [] where tool["type"] as? String == "function" {
            try name(tool["name"] as? String ?? "", label: "Function name")
            if let parameters = tool["parameters"], !(parameters is NSNull) {
                guard let value = parameters as? [String: Any] else {
                    throw OpenAIServiceError.invalidRequest("Function parameters must be a JSON object.")
                }
                try schema(value, strict: tool["strict"] as? Bool == true, path: "Function parameters")
            }
        }
    }

    private static func name(_ value: String, label: String) throws {
        guard value.range(of: "^[A-Za-z0-9_-]{1,64}$", options: .regularExpression) != nil else {
            throw OpenAIServiceError.invalidRequest("\(label) needs 1–64 letters, numbers, underscores, or hyphens.")
        }
    }

    private static func schema(_ value: [String: Any], strict: Bool, path: String) throws {
        guard value["type"] as? String == "object", value["anyOf"] == nil else {
            throw OpenAIServiceError.invalidRequest("\(path) needs a root type of object without a root anyOf.")
        }
        try validateNode(value, strict: strict, path: path)
    }

    private static func validateNode(_ node: [String: Any], strict: Bool, path: String) throws {
        let isObject = node["type"] as? String == "object" || (node["type"] as? [String])?.contains("object") == true
        if isObject {
            if node["properties"] != nil, !(node["properties"] is [String: Any]) {
                throw OpenAIServiceError.invalidRequest("\(path).properties must be an object.")
            }
            let properties = node["properties"] as? [String: Any] ?? [:]
            if strict {
                guard let extra = node["additionalProperties"] as? NSNumber,
                      CFGetTypeID(extra) == CFBooleanGetTypeID(), !extra.boolValue else {
                    throw OpenAIServiceError.invalidRequest("\(path): strict schemas need additionalProperties set to false on every object.")
                }
                guard let required = node["required"] as? [String], Set(required) == Set(properties.keys), required.count == Set(required).count else {
                    throw OpenAIServiceError.invalidRequest("\(path): strict schemas must list every property in required. Use a nullable type for optional values.")
                }
            }
        }
        // Visit schema nodes only; values inside enum/default/examples are user data.
        for key in ["properties", "$defs", "definitions", "patternProperties"] {
            for (name, child) in node[key] as? [String: Any] ?? [:] {
                guard let child = child as? [String: Any] else {
                    throw OpenAIServiceError.invalidRequest("\(path).\(key).\(name) must be a schema object.")
                }
                try validateNode(child, strict: strict, path: "\(path).\(key).\(name)")
            }
        }
        for key in ["items", "additionalProperties"] {
            if let child = node[key] as? [String: Any] { try validateNode(child, strict: strict, path: "\(path).\(key)") }
        }
        for key in ["anyOf", "allOf", "oneOf", "prefixItems"] {
            for (index, child) in (node[key] as? [[String: Any]] ?? []).enumerated() {
                try validateNode(child, strict: strict, path: "\(path).\(key)[\(index)]")
            }
        }
    }
}
