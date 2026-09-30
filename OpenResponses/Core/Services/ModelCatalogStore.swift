import Foundation
import os

/// The model catalog the app uses, readable from any thread. It starts from the copy built into the app, or from the
/// last downloaded copy when that one has a higher revision; `refreshIfDue()` downloads `remoteURL` at most once a
/// day and sends nothing but the request for the file. Shutdown dates from the account's GET /models listing
/// (`recordShutdowns`) retire a model `shutdownWindow` before it shuts down.
nonisolated final class ModelCatalogStore: @unchecked Sendable {
    static let shared = ModelCatalogStore()

    /// Published from the Gunzino site repository (public/openresponses/models.json), where a daily GitHub Action
    /// proposes models OpenAI adds. See docs/model-catalog.md.
    static let remoteURL = URL(string: "https://gunzino.me/openresponses/models.json")!
    /// The remote file is checked at most this often.
    static let checkInterval: TimeInterval = 24 * 60 * 60
    /// A model whose shutdown date is this close, or past, counts as retired: hidden from the model lists, and a preset
    /// naming it moves to its replacement.
    static let shutdownWindow: TimeInterval = 30 * 24 * 60 * 60

    enum Source: String, Sendable {
        case builtIn = "built into this version"
        case downloaded = "downloaded from gunzino.me"
    }

    private struct State: Sendable {
        var catalog: ModelCatalog
        var source: Source
        var shutdowns: [String: Date]
    }

    private let state: OSAllocatedUnfairLock<State>
    private let cacheURL: URL
    private let defaults: UserDefaults
    private let checkedKey = "modelCatalogCheckedAt"
    private let shutdownsKey = "accountModelShutdowns"

    /// `restore: false` ignores the downloaded copy and the saved shutdown dates. The shared store does that under
    /// unit tests, so they run against the built-in catalog.
    init(bundled: ModelCatalog = ModelCatalogStore.builtIn, cacheDirectory: URL? = nil, defaults: UserDefaults = .standard,
         restore: Bool = !ModelCatalogStore.isRunningTests) {
        let directory = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheURL = directory.appendingPathComponent("ModelCatalog.json")
        self.defaults = defaults
        var initial = State(catalog: bundled, source: .builtIn, shutdowns: [:])
        if restore {
            if let data = try? Data(contentsOf: cacheURL), let cached = ModelCatalog.decode(data), cached.revision > bundled.revision {
                initial.catalog = cached
                initial.source = .downloaded
            }
            let saved = defaults.dictionary(forKey: shutdownsKey) as? [String: String] ?? [:]
            initial.shutdowns = saved.compactMapValues(Self.date)
        }
        state = OSAllocatedUnfairLock(initialState: initial)
    }

    var catalog: ModelCatalog { state.withLock { $0.catalog } }
    var source: Source { state.withLock { $0.source } }

    /// For Settings → Model, e.g. "Model list revision 2 of 2026-09-30, downloaded from gunzino.me."
    var summary: String {
        let (catalog, source) = state.withLock { ($0.catalog, $0.source) }
        return "Model list revision \(catalog.revision) of \(catalog.updated), \(source.rawValue)."
    }

    /// Downloads the catalog when the last check is older than `checkInterval`, and uses it when it is valid and has a
    /// higher revision than the one in use. Returns true when the catalog in use changed.
    @discardableResult
    func refreshIfDue(now: Date = Date(),
                      load: (URLRequest) async throws -> (Data, URLResponse) = { try await URLSession.shared.data(for: $0) }) async -> Bool {
        if let last = defaults.object(forKey: checkedKey) as? Date, now.timeIntervalSince(last) < Self.checkInterval { return false }
        let request = URLRequest(url: Self.remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        guard let (data, response) = try? await load(request), (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
        defaults.set(now, forKey: checkedKey)
        return adopt(data)
    }

    /// Uses a downloaded catalog file when it is valid and newer than the one in use, and keeps it for the next launch.
    @discardableResult
    func adopt(_ data: Data) -> Bool {
        guard let downloaded = ModelCatalog.decode(data) else {
            AppLogger.log("Ignored an invalid model catalog download", category: .general, level: .warning)
            return false
        }
        let applied = state.withLock { state -> Bool in
            guard downloaded.revision > state.catalog.revision else { return false }
            state.catalog = downloaded
            state.source = .downloaded
            return true
        }
        if applied {
            try? data.write(to: cacheURL, options: .atomic)
            AppLogger.log("Using model catalog revision \(downloaded.revision)", category: .general, level: .info)
        }
        return applied
    }

    /// Replaces the catalog in use without the revision check (tests).
    func use(_ catalog: ModelCatalog, source: Source = .builtIn) {
        state.withLock { $0.catalog = catalog; $0.source = source }
    }

    /// Shutdown dates from GET /models (`shutdown_date`, YYYY-MM-DD) by model ID, kept for the next launch.
    func recordShutdowns(_ dates: [String: String]) {
        state.withLock { $0.shutdowns = dates.compactMapValues(Self.date) }
        defaults.set(dates, forKey: shutdownsKey)
    }

    /// True when the account's model list gives the model a shutdown date within `shutdownWindow`, or a past one.
    func isShuttingDown(_ id: String, now: Date = Date()) -> Bool {
        guard let date = state.withLock({ $0.shutdowns[id] }) else { return false }
        return date.timeIntervalSince(now) <= Self.shutdownWindow
    }

    // MARK: - Built-in copy

    /// The catalog built into this version (Resources/ModelCatalog/ModelCatalog.json). The unit tests check it; if it
    /// were ever unreadable, a one-model catalog keeps the app working.
    static let builtIn: ModelCatalog = {
        if let url = Bundle.main.url(forResource: "ModelCatalog", withExtension: "json"),
           let data = try? Data(contentsOf: url), let catalog = ModelCatalog.decode(data) {
            return catalog
        }
        AppLogger.log("ModelCatalog.json is missing or invalid; using a one-model catalog", category: .general, level: .error)
        return ModelCatalog(schema: ModelCatalog.supportedSchema, revision: 1, updated: "", notes: nil, defaultModel: "gpt-6-sol",
                            current: [.init(id: "gpt-6-sol", summary: "Complex coding and agentic work",
                                            reasoningEfforts: ["none", "low", "medium", "high", "xhigh", "max"], pro: true, asyncTools: false)],
                            earlier: [], retired: [])
    }()

    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    private static func date(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(text.prefix(10)))
    }
}
