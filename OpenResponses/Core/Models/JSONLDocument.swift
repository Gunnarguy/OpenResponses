import SwiftUI
import UniformTypeIdentifiers

struct JSONLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText, .data] }
    static var writableContentTypes: [UTType] { [.plainText] }
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct FineTuningDataset {
    let data: Data
    let exampleCount: Int

    static func validate(_ data: Data) throws -> Self {
        guard data.count <= 50 * 1024 * 1024 else {
            throw OpenAIServiceError.invalidRequest("Choose a training file smaller than 50 MB for validation on this device.")
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw OpenAIServiceError.invalidRequest("The training file must be UTF-8 JSONL.")
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        for (index, line) in lines.enumerated() {
            let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
            guard let messages = object?["messages"] as? [[String: Any]],
                  messages.contains(where: { $0["role"] as? String == "user" }),
                  messages.last?["role"] as? String == "assistant",
                  messages.allSatisfy({ message in
                      guard let role = message["role"] as? String,
                            ["system", "user", "assistant"].contains(role),
                            let content = message["content"] as? String,
                            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            message["tool_calls"] == nil, message["function_call"] == nil else { return false }
                      return true
                  }) else {
                throw OpenAIServiceError.invalidRequest("Line \(index + 1) must contain text messages, a user prompt, and a final assistant answer. This importer supports text-only supervised examples.")
            }
        }
        guard lines.count >= 10 else {
            throw OpenAIServiceError.invalidRequest("Training requires at least 10 examples on separate JSONL lines. This file contains \(lines.count).")
        }
        return Self(data: data, exampleCount: lines.count)
    }
}
