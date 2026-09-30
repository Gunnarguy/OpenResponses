import Foundation
import XCTest
@testable import OpenResponses

/// The model catalog (ModelCatalog.json and https://gunzino.me/openresponses/models.json) and ModelCatalogStore.
@MainActor
final class ModelCatalogTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private let suite = "ModelCatalogTests"
    private let gpt62 = ModelCatalog.Model(id: "gpt-6.2-sol", summary: "Test model", reasoningEfforts: ["low", "medium", "high"],
                                           pro: false, asyncTools: true, released: "2026-10-01")

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        ModelCatalogStore.shared.use(ModelCatalogStore.builtIn)
        ModelCatalogStore.shared.recordShutdowns([:])
        UserDefaults.standard.removeObject(forKey: "accountModelShutdowns")
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testTheBuiltInCatalogIsValidAndIsWhatTheMenusList() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "ModelCatalog", withExtension: "json"), "ModelCatalog.json must be in the app bundle")
        let catalog = try XCTUnwrap(ModelCatalog.decode(Data(contentsOf: url)))
        XCTAssertEqual(ModelCatalogStore.builtIn, catalog)
        XCTAssertEqual(catalog.defaultModel, "gpt-6-sol")
        XCTAssertEqual(CurrentModelCatalog.recommended, catalog.current.map(\.id))
        XCTAssertEqual(CurrentModelCatalog.recommended.first, "gpt-6.1-sol")
        XCTAssertEqual(CurrentModelCatalog.legacy, catalog.earlier)
        XCTAssertEqual(ModelCatalogStore.shared.source, .builtIn, "unit tests never read a downloaded copy")
    }

    func testCatalogsTheAppCannotUseAreRejected() throws {
        let valid = try builtInJSON()
        XCTAssertNotNil(ModelCatalog.decode(try data(valid)))
        let models = try XCTUnwrap(valid["current"] as? [[String: Any]])
        func changingFirstModel(_ key: String, to value: Any?) -> (inout [String: Any]) -> Void {
            { json in
                var changed = models
                changed[0][key] = value
                json["current"] = changed
            }
        }
        let cases: [(String, (inout [String: Any]) -> Void)] = [
            ("a newer schema", { $0["schema"] = 2 }),
            ("an unknown effort", changingFirstModel("reasoningEfforts", to: ["low", "turbo"])),
            ("efforts out of order", changingFirstModel("reasoningEfforts", to: ["high", "low"])),
            ("a model ID with a space", changingFirstModel("id", to: "gpt 6")),
            ("an empty summary", changingFirstModel("summary", to: "")),
            ("a missing field", changingFirstModel("pro", to: nil)),
            ("a default model that is not current", { $0["defaultModel"] = "gpt-4o" }),
            ("a model listed twice", { $0["earlier"] = ["gpt-6-sol"] }),
        ]
        for (name, change) in cases {
            var json = valid
            change(&json)
            XCTAssertNil(ModelCatalog.decode(try data(json)), name)
        }
        XCTAssertNil(ModelCatalog.decode(Data("<html>Not found</html>".utf8)))
    }

    func testANewerDownloadIsUsedKeptForTheNextLaunchAndCheckedOnceADay() async throws {
        let store = ModelCatalogStore(cacheDirectory: directory, defaults: defaults, restore: true)
        XCTAssertEqual(store.source, .builtIn)
        let newer = try JSONEncoder().encode(catalog(revision: ModelCatalogStore.builtIn.revision + 1, adding: gpt62))
        var requests: [URLRequest] = []
        let now = Date()

        let changed = await store.refreshIfDue(now: now) { request in
            requests.append(request)
            return (newer, self.response(200))
        }
        XCTAssertTrue(changed)
        XCTAssertEqual(requests.first?.url, ModelCatalogStore.remoteURL)
        XCTAssertEqual(store.source, .downloaded)
        XCTAssertEqual(store.catalog.current.first?.id, "gpt-6.2-sol")
        XCTAssertTrue(store.summary.contains("downloaded from gunzino.me"))

        let again = await store.refreshIfDue(now: now.addingTimeInterval(3600)) { request in
            requests.append(request)
            return (newer, self.response(200))
        }
        XCTAssertFalse(again)
        XCTAssertEqual(requests.count, 1, "no second request within a day")

        let relaunched = ModelCatalogStore(cacheDirectory: directory, defaults: defaults, restore: true)
        XCTAssertEqual(relaunched.catalog.revision, ModelCatalogStore.builtIn.revision + 1)
        XCTAssertEqual(relaunched.source, .downloaded)
    }

    func testOlderBrokenOrFailedDownloadsLeaveTheCatalogAlone() async throws {
        let store = ModelCatalogStore(cacheDirectory: directory, defaults: defaults, restore: true)
        let revision = store.catalog.revision
        let downloads: [(String, Data, Int)] = [
            ("same revision", try JSONEncoder().encode(catalog(revision: revision, adding: gpt62)), 200),
            ("not JSON", Data("{".utf8), 200),
            ("server error", try JSONEncoder().encode(catalog(revision: revision + 5, adding: gpt62)), 500),
        ]
        for (index, (name, body, status)) in downloads.enumerated() {
            // Two days apart, so every attempt is due.
            let changed = await store.refreshIfDue(now: Date().addingTimeInterval(Double(index) * 2 * ModelCatalogStore.checkInterval)) { _ in
                (body, self.response(status))
            }
            XCTAssertFalse(changed, name)
        }
        XCTAssertEqual(store.catalog.revision, revision)
        XCTAssertEqual(store.source, .builtIn)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("ModelCatalog.json").path))
    }

    func testTheCatalogInUseSetsTheMenusTheDefaultAndEachModelsSettings() {
        ModelCatalogStore.shared.use(catalog(revision: 99, adding: gpt62, defaultModel: "gpt-6.2-sol",
                                             retiring: [.init(id: "gpt-4.5-preview", replacement: "gpt-6-luna")]))
        XCTAssertEqual(CurrentModelCatalog.defaultModel, "gpt-6.2-sol")
        XCTAssertEqual(Prompt.defaultPrompt().openAIModel, "gpt-6.2-sol")
        XCTAssertEqual(CurrentModelCatalog.selectionModels(including: "gpt-6-sol").first, "gpt-6.2-sol")
        XCTAssertEqual(CurrentModelCatalog.reasoningEfforts(for: "gpt-6.2-sol-2026-10-01"), ["low", "medium", "high"])
        XCTAssertFalse(CurrentModelCatalog.supportsPro("gpt-6.2-sol"))
        XCTAssertTrue(CurrentModelCatalog.supportsAsyncTools("gpt-6.2-sol"))
        XCTAssertEqual(CurrentModelCatalog.description(for: "gpt-6.2-sol"), "Test model")
        XCTAssertTrue(CurrentModelCatalog.isRetired("gpt-4.5-preview-2025-02-27"))
        XCTAssertEqual(CurrentModelCatalog.replacement(for: "gpt-4.5-preview-2025-02-27"), "gpt-6-luna")
        XCTAssertEqual(CurrentModelCatalog.replacement(for: "gpt-5-mini-2025-08-07"), "gpt-5.6-terra", "the longest matching entry wins")
        XCTAssertEqual(CurrentModelCatalog.replacement(for: "gpt-5.1-codex"), "gpt-6.2-sol", "no listed replacement: the default model")
    }

    func testShutdownDatesRetireAModelThirtyDaysAhead() {
        let store = ModelCatalogStore(cacheDirectory: directory, defaults: defaults, restore: true)
        let now = Date()
        store.recordShutdowns(["gpt-6-sol-2026-09-22": day(now, 10), "gpt-6-luna": day(now, 90), "gpt-5.5": day(now, -5), "gpt-4o": "soon"])
        XCTAssertTrue(store.isShuttingDown("gpt-6-sol-2026-09-22", now: now))
        XCTAssertFalse(store.isShuttingDown("gpt-6-luna", now: now), "90 days out is not yet retired")
        XCTAssertTrue(store.isShuttingDown("gpt-5.5", now: now))
        XCTAssertFalse(store.isShuttingDown("gpt-4o", now: now), "an unreadable date is ignored")
        XCTAssertFalse(store.isShuttingDown("gpt-6-sol", now: now), "a snapshot's date does not retire its alias")
        let relaunched = ModelCatalogStore(cacheDirectory: directory, defaults: defaults, restore: true)
        XCTAssertTrue(relaunched.isShuttingDown("gpt-6-sol-2026-09-22", now: now), "kept for the next launch")

        ModelCatalogStore.shared.recordShutdowns(["gpt-5.5": day(now, -5)])
        XCTAssertTrue(CurrentModelCatalog.isRetired("gpt-5.5"))
        XCTAssertNil(ModelCompatibilityService.shared.getCapabilities(for: "gpt-5.5"), "hidden from the account's model list")
    }

    func testTheModelListingDecodesShutdownDates() throws {
        let json = #"""
        {"object": "list", "data": [
          {"id": "gpt-6-sol", "object": "model", "created": 1, "owned_by": "openai", "shutdown_date": "2026-10-23"},
          {"id": "gpt-6-luna", "object": "model", "created": 1, "owned_by": "openai", "shutdown_date": null},
          {"id": "gpt-6-astra", "object": "model", "created": 1, "owned_by": "openai"}]}
        """#
        let listing = try JSONDecoder().decode(OpenAIModelsResponse.self, from: Data(json.utf8))
        XCTAssertEqual(listing.data.map(\.shutdownDate), ["2026-10-23", nil, nil])
    }

    // MARK: - Helpers

    private func builtInJSON() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "ModelCatalog", withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func data(_ json: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: json)
    }

    private func catalog(revision: Int, adding model: ModelCatalog.Model, defaultModel: String? = nil,
                         retiring: [ModelCatalog.Retired] = []) -> ModelCatalog {
        let builtIn = ModelCatalogStore.builtIn
        return ModelCatalog(schema: ModelCatalog.supportedSchema, revision: revision, updated: "2026-10-01", notes: nil,
                            defaultModel: defaultModel ?? builtIn.defaultModel, current: [model] + builtIn.current,
                            earlier: builtIn.earlier, retired: builtIn.retired + retiring)
    }

    private func response(_ status: Int) -> URLResponse {
        HTTPURLResponse(url: ModelCatalogStore.remoteURL, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    private func day(_ date: Date, _ offset: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date.addingTimeInterval(Double(offset) * 86_400))
    }
}
