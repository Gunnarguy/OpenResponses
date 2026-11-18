import Foundation

/// A request to POST /v1/decisions: shared input plus 1–400 typed questions.
/// Limits come from the Decisions guide and API reference on developers.openai.com, read 2026-11-13:
/// `gpt-6-luna` only, 1–400 questions, 2–255 unique choices, 2–10 score levels, image URLs that start with
/// `data:` or `http(s)://` (no `file_id`), and $0.10 per 1M uncached input tokens with output not charged.
nonisolated struct DecisionsRequest: Codable, Equatable, Sendable {
    var input: String
    /// A `data:` URL for one image sent with the input, or nil.
    var imageDataURL: String?
    var questions: [DecisionQuestion]

    static let maxQuestions = 400
    static let choiceRange = 2...255
    static let levelRange = 2...10
    static let dollarsPerMillionInputTokens = 0.10

    /// The JSON body. Empty names become `question_1`, `question_2` and so on, so every answer can be matched.
    var body: [String: Any] {
        var content: [[String: Any]] = [["type": "input_text", "text": input]]
        if let imageDataURL { content.append(["type": "input_image", "image_url": imageDataURL]) }
        let inputValue: Any = imageDataURL == nil ? input : [["role": "user", "content": content]]
        return ["model": CurrentModelCatalog.decisionsModel, "input": inputValue,
                "questions": questions.enumerated().map { $0.element.body(index: $0.offset) }]
    }

    /// The first problem that would make OpenAI reject the request, in words a person can act on; nil when it can be sent.
    var problem: String? {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, imageDataURL == nil { return "Add some input to evaluate." }
        guard !questions.isEmpty else { return "Add at least one question." }
        if questions.count > Self.maxQuestions { return "Ask at most \(Self.maxQuestions) questions per request." }
        var names = Set<String>()
        for (index, question) in questions.enumerated() {
            let label = "Question \(index + 1)"
            if question.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "\(label) needs instructions." }
            let name = question.resolvedName(index: index)
            if !names.insert(name).inserted { return "Two questions are named \(name). Give each a different name." }
            let values = question.options.map { $0.value.trimmingCharacters(in: .whitespacesAndNewlines) }
            switch question.kind {
            case .predicate: break
            case .choice:
                if !Self.choiceRange.contains(values.count) { return "\(label) needs 2 to 255 choices." }
                if values.contains(where: \.isEmpty) { return "\(label) has a choice with no value." }
                if Set(values).count != values.count { return "\(label) has two choices with the same value." }
            case .score:
                if !Self.levelRange.contains(values.count) { return "\(label) needs 2 to 10 levels." }
                if values.contains(where: \.isEmpty) { return "\(label) has a level with no label." }
            }
        }
        return nil
    }

    static let examples: [(title: String, request: DecisionsRequest)] = [
        ("Support ticket", example),
        ("Bug severity", DecisionsRequest(input: "Export fails in Safari but works in Chrome.", questions: [
            DecisionQuestion(kind: .score, name: "severity", instructions: "How severe is this issue?", options: [
                DecisionOption(value: "Cosmetic", detail: "Appearance only; no lost functionality."),
                DecisionOption(value: "Workaround available", detail: "A task fails, but another way works."),
                DecisionOption(value: "Fully blocked", detail: "A task fails with no workaround.")])])),
        ("Product photo", DecisionsRequest(input: "Inspect the product in this photo.", questions: [
            DecisionQuestion(kind: .predicate, name: "visible_damage",
                             instructions: "Does the product have visible damage, such as a crack, tear, or dent? Ignore shadows and damage to the packaging.")]))
    ]

    /// Three questions of the three types about one support message.
    static let example = DecisionsRequest(input: "I was charged twice for my order and I need the second charge refunded before rent is due on Friday.", questions: [
        DecisionQuestion(kind: .choice, name: "department", instructions: "Which department should handle this message?", options: [
            DecisionOption(value: "billing", detail: "Payments, invoices, and refunds."),
            DecisionOption(value: "technical", detail: "Problems using the product."),
            DecisionOption(value: "shipping", detail: "Delivery and tracking."),
            DecisionOption(value: "other", detail: "Requests outside these categories.")]),
        DecisionQuestion(kind: .predicate, name: "asks_for_refund", instructions: "Does the customer ask for a refund?"),
        DecisionQuestion(kind: .score, name: "urgency", instructions: "How urgent is this message?", options: [
            DecisionOption(value: "Low", detail: "No deadline or harm mentioned."),
            DecisionOption(value: "Medium", detail: "A deadline or inconvenience is mentioned."),
            DecisionOption(value: "High", detail: "Money, safety, or access is at risk soon.")])
    ])
}

nonisolated enum DecisionQuestionKind: String, Codable, CaseIterable, Sendable {
    case predicate, choice, score

    var title: String {
        switch self {
        case .predicate: return "Yes or no"
        case .choice: return "Choice"
        case .score: return "Score"
        }
    }

    var summary: String {
        switch self {
        case .predicate: return "The probability, from 0 to 1, that a statement about the input is true."
        case .choice: return "One of your choices, with a probability for each."
        case .score: return "A rating against ordered levels, listed from lowest to highest."
        }
    }
}

nonisolated struct DecisionOption: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    /// A choice's value, or a score level's label.
    var value: String
    var detail: String = ""
}

nonisolated struct DecisionQuestion: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var kind: DecisionQuestionKind
    var name: String = ""
    var instructions: String = ""
    /// Choices for `.choice`, levels from lowest to highest for `.score`; ignored for `.predicate`.
    var options: [DecisionOption] = []

    func resolvedName(index: Int) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "question_\(index + 1)" : trimmed
    }

    func body(index: Int) -> [String: Any] {
        var body: [String: Any] = ["type": kind.rawValue, "name": resolvedName(index: index), "instructions": instructions]
        func entries(_ key: String) -> [[String: Any]] {
            options.map { option in
                var entry: [String: Any] = [key: option.value.trimmingCharacters(in: .whitespacesAndNewlines)]
                if !option.detail.isEmpty { entry["description"] = option.detail }
                return entry
            }
        }
        switch kind {
        case .predicate: break
        case .choice: body["choices"] = entries("value")
        case .score: body["levels"] = entries("label")
        }
        return body
    }
}

/// A decoded Decision object. Unknown answer types are kept so a new type from OpenAI shows instead of vanishing.
nonisolated struct DecisionsResult: Equatable, Sendable {
    nonisolated struct Bar: Equatable, Sendable {
        let label: String
        let probability: Double
    }

    nonisolated enum Answer: Equatable, Sendable {
        case predicate(name: String?, probability: Double)
        case choice(name: String?, choice: String, confidence: Double, bars: [Bar])
        case score(name: String?, score: Double, confidence: Double, bars: [Bar])
        case refusal(name: String?)
        case unknown(name: String?, type: String)

        var name: String? {
            switch self {
            case .predicate(let name, _), .choice(let name, _, _, _), .score(let name, _, _, _), .refusal(let name), .unknown(let name, _): return name
            }
        }
    }

    let model: String
    let answers: [Answer]
    let inputTokens: Int
    let cachedTokens: Int

    /// Uncached input at the published rate. Cache reads and writes have their own rates, so a request with cached
    /// tokens is reported without a dollar figure.
    var estimatedCost: Double? {
        cachedTokens == 0 ? Double(inputTokens) * DecisionsRequest.dollarsPerMillionInputTokens / 1_000_000 : nil
    }

    init(model: String, answers: [Answer], inputTokens: Int, cachedTokens: Int) {
        self.model = model
        self.answers = answers
        self.inputTokens = inputTokens
        self.cachedTokens = cachedTokens
    }

    init(json: [String: Any]) {
        model = json["model"] as? String ?? ""
        let usage = json["usage"] as? [String: Any]
        inputTokens = (usage?["input_tokens"] as? NSNumber)?.intValue ?? 0
        cachedTokens = ((usage?["input_tokens_details"] as? [String: Any])?["cached_tokens"] as? NSNumber)?.intValue ?? 0
        answers = (json["answers"] as? [[String: Any]] ?? []).map(Self.answer)
    }

    /// Choice values are typed: a boolean comes back as JSON true or false, shown as "true" or "false".
    static func text(_ value: Any?) -> String {
        if let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    private static func number(_ value: Any?) -> Double { (value as? NSNumber)?.doubleValue ?? 0 }

    private static func answer(_ json: [String: Any]) -> Answer {
        let name = json["name"] as? String
        let probabilities = json["probabilities"] as? [[String: Any]] ?? []
        switch json["type"] as? String ?? "" {
        case "predicate":
            return .predicate(name: name, probability: number(json["probability"]))
        case "choice":
            return .choice(name: name, choice: text(json["choice"]), confidence: number(json["confidence"]),
                           bars: probabilities.map { Bar(label: text($0["value"]), probability: number($0["probability"])) })
        case "score":
            return .score(name: name, score: number(json["score"]), confidence: number(json["confidence"]),
                          bars: probabilities.map { Bar(label: $0["label"] as? String ?? text($0["value"]), probability: number($0["probability"])) })
        case "refusal":
            return .refusal(name: name)
        case let other:
            return .unknown(name: name, type: other.isEmpty ? "unknown" : other)
        }
    }
}

/// Sends a DecisionsRequest through the app's JSON client, which reads the key from the Keychain.
struct DecisionsService {
    func run(_ request: DecisionsRequest) async throws -> DecisionsResult {
        if let problem = request.problem { throw OpenAIServiceError.invalidRequest(problem) }
        return DecisionsResult(json: try await ResponsesAPIClient().json(path: "/decisions", body: request.body))
    }
}
