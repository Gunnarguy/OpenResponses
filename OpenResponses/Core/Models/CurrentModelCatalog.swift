import Foundation

/// Verified against OpenAI's model catalog on September 6, 2026.
/// Account availability still comes from GET /models; discovery never grants capabilities.
enum CurrentModelCatalog {
    static let defaultModel = "gpt-6-astra"
    static let imageModel = "gpt-image-2"
    static let realtimeModel = "gpt-realtime-2.1"
    nonisolated static let transcriptionModel = "gpt-live-transcribe"
    static let recommended = ["gpt-6-astra", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"]
    static let legacy = ["gpt-5.5", "gpt-5.5-pro", "gpt-5.4", "gpt-5.4-pro", "gpt-5.4-mini", "gpt-5.4-nano", "gpt-5.2", "gpt-5.2-pro", "gpt-5.1", "gpt-5", "gpt-5-mini", "gpt-5-nano", "gpt-4.1", "gpt-4.1-mini", "gpt-4o", "gpt-4o-mini", "o3"]

    static func family(_ id: String) -> String {
        let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (recommended + ["gpt-5.6"]).first {
            normalized == $0 || normalized.range(of: "^" + NSRegularExpression.escapedPattern(for: $0) + "-\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil
        } ?? normalized
    }

    static func isModern(_ id: String) -> Bool {
        recommended.contains(family(id)) || family(id) == "gpt-5.6"
    }

    static func selectionModels(including selected: String) -> [String] {
        let models = recommended + legacy
        return models.contains(selected) || selected.isEmpty ? models : models + [selected]
    }

    static func supportsPro(_ id: String) -> Bool {
        ["gpt-6-astra", "gpt-5.6-sol", "gpt-5.6"].contains(family(id))
    }

    static func isRetired(_ id: String) -> Bool {
        ["computer-use-preview", "o3-deep-research", "o4-mini-deep-research", "chatgpt-4o-latest", "gpt-5-codex", "gpt-5.1-codex", "gpt-5.2-codex"].contains { id == $0 || id.hasPrefix($0 + "-") }
            || id.contains("chat-latest")
    }

    static func reasoningEfforts(for id: String) -> [String] {
        let key = family(id)
        if key == "gpt-6-astra" { return ["low", "medium", "high", "xhigh", "max"] }
        if isModern(key) { return ["none", "low", "medium", "high", "xhigh", "max"] }
        if id.contains("-pro") { return ["medium", "high", "xhigh"] }
        if ["gpt-5.5", "gpt-5.4", "gpt-5.2"].contains(where: { id.hasPrefix($0) }) { return ["none", "low", "medium", "high", "xhigh"] }
        if id.hasPrefix("gpt-5.1") { return ["none", "low", "medium", "high"] }
        if id.hasPrefix("gpt-5") { return ["minimal", "low", "medium", "high"] }
        return ["low", "medium", "high"]
    }

    static func normalizedEffort(_ effort: String, model: String) -> String {
        let options = reasoningEfforts(for: model)
        if options.contains(effort) { return effort }
        return ["none", "minimal"].contains(effort) ? "low" : "medium"
    }

    static func description(for id: String) -> String {
        switch family(id) {
        case "gpt-6-astra": return "Complex reasoning, coding, research, and computer use"
        case "gpt-5.6-sol", "gpt-5.6": return "General-purpose work with configurable reasoning"
        case "gpt-5.6-terra": return "Balanced capability, speed, and cost"
        case "gpt-5.6-luna": return "Fast, lower-cost requests"
        default:
            if isRetired(id) { return "Retired model · choose a current replacement" }
            return "Earlier model · " + (id.hasPrefix("gpt-5") || id.hasPrefix("o") ? "reasoning" : "text and chat")
        }
    }

    static func priority(_ id: String) -> Int {
        let models = recommended + legacy
        return models.firstIndex(of: family(id)).map { models.count - $0 } ?? 0
    }
}

/// Optional as a whole in Prompt so existing saved presets decode unchanged.
struct ModernResponseOptions: Codable, Equatable {
    var automaticCompaction: Bool = false
    var compactThreshold: Int = 100_000
    var toolSearch: Bool = false
    var hostedShell: Bool = false
    var reasoningMode: String = "standard"
    var reasoningContext: String = "auto"
    var imageAction: String = "auto"
    var partialImages: Int = 0
    var asyncTools: Bool = false
    var programmaticTools: Bool = false
    var multiAgent: Bool = false
    var maxSubagents: Int = 3
    var maxToolRounds: Int = 12
    var customToolFormat: String = "function"
    var mcpConnectionIDs: [UUID]? = nil
}

extension ModernResponseOptions {
    enum CodingKeys: String, CodingKey {
        case automaticCompaction, compactThreshold, toolSearch, hostedShell, reasoningMode, reasoningContext
        case imageAction, partialImages, asyncTools, programmaticTools, multiAgent, maxSubagents, maxToolRounds, customToolFormat, mcpConnectionIDs
    }

    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        automaticCompaction = try c.decodeIfPresent(Bool.self, forKey: .automaticCompaction) ?? false
        compactThreshold = try c.decodeIfPresent(Int.self, forKey: .compactThreshold) ?? 100_000
        toolSearch = try c.decodeIfPresent(Bool.self, forKey: .toolSearch) ?? false
        hostedShell = try c.decodeIfPresent(Bool.self, forKey: .hostedShell) ?? false
        reasoningMode = try c.decodeIfPresent(String.self, forKey: .reasoningMode) ?? "standard"
        reasoningContext = try c.decodeIfPresent(String.self, forKey: .reasoningContext) ?? "auto"
        imageAction = try c.decodeIfPresent(String.self, forKey: .imageAction) ?? "auto"
        partialImages = try c.decodeIfPresent(Int.self, forKey: .partialImages) ?? 0
        asyncTools = try c.decodeIfPresent(Bool.self, forKey: .asyncTools) ?? false
        programmaticTools = try c.decodeIfPresent(Bool.self, forKey: .programmaticTools) ?? false
        multiAgent = try c.decodeIfPresent(Bool.self, forKey: .multiAgent) ?? false
        maxSubagents = try c.decodeIfPresent(Int.self, forKey: .maxSubagents) ?? 3
        maxToolRounds = try c.decodeIfPresent(Int.self, forKey: .maxToolRounds) ?? 12
        mcpConnectionIDs = try c.decodeIfPresent([UUID].self, forKey: .mcpConnectionIDs)
        customToolFormat = try c.decodeIfPresent(String.self, forKey: .customToolFormat) ?? "function"
    }
}
