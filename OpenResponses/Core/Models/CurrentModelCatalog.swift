import Foundation

/// Verified against OpenAI's model catalog, changelog and deprecations pages on September 24, 2026.
/// Account availability still comes from GET /models; discovery never grants capabilities.
///
/// Later general-purpose releases (for example `gpt-6.1-sol` or `gpt-7-luna`) are recognized by their
/// version number, so they are listed and configured like the current generation without an app update.
/// Specialized variants (audio, realtime, transcription, image, search, codex, cyber and similar) are not.
enum CurrentModelCatalog {
    static let defaultModel = "gpt-6-sol"
    nonisolated static let imageModel = "gpt-image-2.5-flare"
    /// Image models offered in settings, newest first. Earlier saved values stay selectable.
    nonisolated static let imageModels = ["gpt-image-2.5-flare", "gpt-image-2.5-sunburst", "gpt-image-2"]
    static let realtimeModel = "gpt-realtime-2.1"
    /// Realtime models offered for voice. `gpt-realtime` and `gpt-realtime-mini` retire January 20, 2027,
    /// so a value saved by an earlier version moves to the current default.
    static let realtimeModels = ["gpt-realtime-2.1", "gpt-realtime-2.1-mini"]
    nonisolated static let transcriptionModel = "gpt-live-transcribe"
    /// Small, inexpensive model for background probes such as MCP tool discovery.
    nonisolated static let utilityModel = "gpt-6-luna"
    static let recommended = ["gpt-6-sol", "gpt-6-astra", "gpt-6-luna", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"]
    /// Earlier models shown when the account's model list is unavailable. Models whose shutdown OpenAI has
    /// announced (gpt-5, gpt-5-mini, gpt-5-nano and o3 on December 11, 2026) are left out; the model list
    /// and the model ID field still reach anything the account can use.
    static let legacy = ["gpt-5.5", "gpt-5.5-pro", "gpt-5.4", "gpt-5.4-pro", "gpt-5.4-mini", "gpt-5.4-nano", "gpt-5.2", "gpt-5.2-pro", "gpt-5.1", "gpt-4.1", "gpt-4.1-mini", "gpt-4o", "gpt-4o-mini"]

    /// Variant words that mark a model as something other than a general text-and-tools model.
    nonisolated private static let specializedVariants: Set<String> = [
        "audio", "realtime", "transcribe", "tts", "image", "search", "codex", "cyber", "chat", "oss",
        "live", "translate", "embedding", "moderation", "instruct", "diarize", "rosalind", "daybreak", "latest", "deep", "research",
    ]

    /// Strips a trailing dated snapshot (`-2026-09-03`) and normalizes case.
    nonisolated static func baseID(_ id: String) -> String {
        let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let range = normalized.range(of: "-\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) else { return normalized }
        return String(normalized[..<range.lowerBound])
    }

    /// Parses `gpt-<major>[.<minor>][-variant...]` into its version and variant words.
    nonisolated static func generation(_ id: String) -> (major: Int, minor: Int, variants: [String])? {
        let base = baseID(id)
        guard base.hasPrefix("gpt-") else { return nil }
        let parts = base.dropFirst(4).split(separator: "-").map(String.init)
        guard let version = parts.first else { return nil }
        let numbers = version.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(numbers.count), let major = Int(numbers[0]) else { return nil }
        let minor = numbers.count == 2 ? Int(numbers[1]) : 0
        guard let minor else { return nil }
        let variants = Array(parts.dropFirst())
        guard variants.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isLetter) }) else { return nil }
        return (major, minor, variants)
    }

    static func family(_ id: String) -> String {
        baseID(id)
    }

    /// Current general-purpose models: the GPT-5.6 and GPT-6 families and any later general release.
    nonisolated static func isModern(_ id: String) -> Bool {
        guard let parsed = generation(id) else { return false }
        guard (parsed.major, parsed.minor) >= (5, 6) else { return false }
        if parsed.variants.contains(where: specializedVariants.contains) { return false }
        if (parsed.major, parsed.minor) == (5, 6) {
            return parsed.variants.isEmpty || ["sol", "terra", "luna"].contains(parsed.variants.joined(separator: "-"))
        }
        return parsed.variants.count <= 1
    }

    static func selectionModels(including selected: String) -> [String] {
        let models = recommended + legacy
        return models.contains(selected) || selected.isEmpty ? models : models + [selected]
    }

    static func supportsPro(_ id: String) -> Bool {
        ["gpt-6-astra", "gpt-5.6-sol", "gpt-5.6"].contains(family(id))
    }

    /// Async tool calling was introduced with GPT-6 Astra; other models run tools in order.
    static func supportsAsyncTools(_ id: String) -> Bool {
        family(id) == "gpt-6-astra"
    }

    static func isRetired(_ id: String) -> Bool {
        ["computer-use-preview", "o3-deep-research", "o4-mini-deep-research", "chatgpt-4o-latest", "gpt-5-codex", "gpt-5.1-codex", "gpt-5.2-codex"].contains { id == $0 || id.hasPrefix($0 + "-") }
            || id.contains("chat-latest")
    }

    static func reasoningEfforts(for id: String) -> [String] {
        let key = family(id)
        if isModern(key) {
            // GPT-6 Astra-class models start at low; every other current model also accepts none.
            if generation(key)?.variants == ["astra"] { return ["low", "medium", "high", "xhigh", "max"] }
            return ["none", "low", "medium", "high", "xhigh", "max"]
        }
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

    /// GPT Image 2.5 models accept `xhigh` and `max` quality in addition to auto, low, medium and high.
    nonisolated static func supportsExtendedImageQuality(_ model: String) -> Bool {
        baseID(model).hasPrefix("gpt-image-2.5")
    }

    nonisolated static func imageQualities(for model: String) -> [String] {
        supportsExtendedImageQuality(model) ? ["auto", "low", "medium", "high", "xhigh", "max"] : ["auto", "low", "medium", "high"]
    }

    /// Keeps a quality the chosen image model accepts, so switching models never produces a rejected request.
    nonisolated static func normalizedImageQuality(_ quality: String, model: String) -> String {
        imageQualities(for: model).contains(quality) ? quality : (["xhigh", "max"].contains(quality) ? "high" : "auto")
    }

    static func imageModelName(_ model: String) -> String {
        switch baseID(model) {
        case "gpt-image-2.5-flare": return "GPT Image 2.5 Flare · fast"
        case "gpt-image-2.5-sunburst": return "GPT Image 2.5 Sunburst"
        case "gpt-image-2": return "GPT Image 2"
        default: return model + " · older model"
        }
    }

    /// Keeps a saved Realtime model that is still offered; otherwise uses the current default.
    static func supportedRealtimeModel(_ stored: String) -> String {
        realtimeModels.contains(stored) ? stored : realtimeModel
    }

    static func description(for id: String) -> String {
        switch family(id) {
        case "gpt-6-sol": return "Complex coding and agentic work · recommended"
        case "gpt-6-astra": return "Most capable · hardest reasoning, research and computer use"
        case "gpt-6-luna": return "Most efficient · focused, high-volume tasks"
        case "gpt-5.6-sol", "gpt-5.6": return "Previous generation · general-purpose work"
        case "gpt-5.6-terra": return "Previous generation · balanced capability and cost"
        case "gpt-5.6-luna": return "Previous generation · fast, lower-cost requests"
        default:
            if isModern(id) { return "Current generation model" }
            if isRetired(id) { return "Retired model · choose a current replacement" }
            return "Earlier model · " + (id.hasPrefix("gpt-5") || id.hasPrefix("o") ? "reasoning" : "text and chat")
        }
    }

    static func priority(_ id: String) -> Int {
        let models = recommended + legacy
        if let index = models.firstIndex(of: family(id)) { return models.count - index }
        // A later general release sorts above everything listed, newest version first.
        if isModern(id), let parsed = generation(id) { return 1_000 + parsed.major * 100 + parsed.minor }
        return 0
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
