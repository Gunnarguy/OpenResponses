import Foundation

/// The model data behind the model menus and each model's settings: which models are current and in what order,
/// what each accepts, the default model, and where a retired model's presets move. The same file ships in the app
/// (Resources/ModelCatalog/ModelCatalog.json) and is published at `ModelCatalogStore.remoteURL`; the app uses the
/// valid copy with the higher revision, so a model OpenAI releases reaches the menus without an app update.
/// It fills in controls the app already has and never carries code. Format and upkeep: docs/model-catalog.md.
/// The validation rules match `problem()` in the Gunzino repository's scripts/openai_models.py.
nonisolated struct ModelCatalog: Codable, Equatable, Sendable {
    nonisolated struct Model: Codable, Equatable, Sendable {
        let id: String
        /// One line under the model's name in the model picker.
        let summary: String
        /// `reasoning.effort` values the model accepts, in `ModelCatalog.efforts` order.
        let reasoningEfforts: [String]
        /// `reasoning.mode: "pro"`.
        let pro: Bool
        /// `async: true` on function and custom tools.
        let asyncTools: Bool
        /// The day OpenAI released the model, or the day the catalog first listed it.
        var released: String?
    }

    nonisolated struct Retired: Codable, Equatable, Sendable {
        let id: String
        /// Where a preset naming this model, or one of its dated snapshots, moves; the default model when absent.
        var replacement: String?
    }

    /// The only schema this version reads; a file with another number is ignored.
    static let supportedSchema = 1
    /// Every `reasoning.effort` value, lowest first.
    static let efforts = ["none", "minimal", "low", "medium", "high", "xhigh", "max"]

    let schema: Int
    /// Raised with every change; the higher of the built-in and downloaded revisions wins.
    let revision: Int
    let updated: String
    var notes: String?
    let defaultModel: String
    /// Current general-purpose models, in menu order.
    let current: [Model]
    /// Earlier models, listed after the current ones.
    let earlier: [String]
    let retired: [Retired]

    /// Why the app cannot use this catalog, or nil when it can.
    func problem() -> String? {
        guard schema == Self.supportedSchema else { return "schema \(schema) is not \(Self.supportedSchema)" }
        guard revision >= 1 else { return "revision must be at least 1" }
        guard (1...50).contains(current.count), earlier.count <= 100, retired.count <= 200 else { return "too many or too few models" }
        var seen = Set<String>()
        for id in current.map(\.id) + earlier + retired.map(\.id) {
            guard Self.isValidID(id) else { return "invalid model ID \(id)" }
            guard seen.insert(id).inserted else { return "\(id) is listed twice" }
        }
        for model in current {
            guard !model.reasoningEfforts.isEmpty, model.reasoningEfforts == Self.efforts.filter(model.reasoningEfforts.contains) else {
                return "\(model.id): reasoning efforts must be distinct known values, lowest first"
            }
            guard (1...80).contains(model.summary.count) else { return "\(model.id): summary must be 1 to 80 characters" }
        }
        guard current.contains(where: { $0.id == defaultModel }) else { return "default model \(defaultModel) is not a current model" }
        if let bad = retired.compactMap(\.replacement).first(where: { !Self.isValidID($0) }) { return "invalid replacement \(bad)" }
        return nil
    }

    static func isValidID(_ id: String) -> Bool {
        id.range(of: "^[a-z0-9][a-z0-9.-]{0,63}$", options: .regularExpression) != nil
    }

    /// Decodes and validates a catalog file; nil when the app cannot use it.
    static func decode(_ data: Data) -> ModelCatalog? {
        guard let catalog = try? JSONDecoder().decode(ModelCatalog.self, from: data), catalog.problem() == nil else { return nil }
        return catalog
    }
}
