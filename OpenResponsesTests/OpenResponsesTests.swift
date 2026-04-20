//
//  OpenResponsesTests.swift
//  OpenResponsesTests
//
//  Created by GitHub Copilot on 8/24/25.
//

import XCTest
@testable import OpenResponses

final class OpenResponsesTests: XCTestCase {

    private let promptDefaultsSuite = "OpenResponsesPromptLibraryTests"
    private var promptDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "savedPrompts")
        promptDefaults = UserDefaults(suiteName: promptDefaultsSuite)!
        promptDefaults.removePersistentDomain(forName: promptDefaultsSuite)
    }

    override func tearDown() {
        promptDefaults?.removePersistentDomain(forName: promptDefaultsSuite)
        promptDefaults = nil
        UserDefaults.standard.removeObject(forKey: "savedPrompts")
        super.tearDown()
    }

    // Test KeychainService
    func testKeychainService() {
        let testKey = "testKey"
        let testValue = "testValue"

        // Clean up from previous test runs
        _ = KeychainService.shared.delete(forKey: testKey)

        // Test saving
        XCTAssertTrue(KeychainService.shared.save(value: testValue, forKey: testKey), "Should save value to keychain")

        // Test loading
        XCTAssertEqual(KeychainService.shared.load(forKey: testKey), testValue, "Should load correct value from keychain")

        // Test deleting
        XCTAssertTrue(KeychainService.shared.delete(forKey: testKey), "Should delete value from keychain")
        XCTAssertNil(KeychainService.shared.load(forKey: testKey), "Should return nil after deletion")
    }

    // Test ChatMessage model
    @MainActor
    func testChatMessage() {
        // Create a chat message
        let message = ChatMessage(role: .user, text: "Hello")

        // Test core properties
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.text, "Hello")
        XCTAssertNil(message.images)
        XCTAssertNil(message.webURLs)
    }

    func testConversationTransferCodecRoundTripPreservesMessages() throws {
        let conversation = Conversation(
            id: UUID(),
            remoteId: "conv_remote_123",
            title: "Release Checklist",
            messages: [
                ChatMessage(role: .user, text: "What should ship in this update?"),
                ChatMessage(
                    role: .assistant,
                    text: "Fix import/export and reminder priority first.",
                    toolsUsed: ["file_search", "apple_reminders"],
                    tokenUsage: TokenUsage(estimatedOutput: nil, input: 42, output: 18, total: 60)
                ),
            ],
            lastResponseId: "resp_123",
            lastModified: Date(timeIntervalSince1970: 1_735_705_600),
            metadata: ["source": "unit-test"],
            lastSyncedAt: Date(timeIntervalSince1970: 1_735_705_900),
            shouldStoreRemotely: true,
            syncState: .synced
        )

        let exported = try ConversationTransferCodec.exportConversation(
            conversation,
            cumulativeTokenUsage: TokenUsage(estimatedOutput: nil, input: 42, output: 18, total: 60)
        )
        let imported = try ConversationTransferCodec.importConversation(from: exported)

        XCTAssertEqual(imported.title, "Release Checklist")
        XCTAssertEqual(imported.messages.count, 2)
        XCTAssertEqual(imported.messages.first?.text, "What should ship in this update?")
        XCTAssertEqual(imported.messages.last?.toolsUsed ?? [], ["file_search", "apple_reminders"])
        XCTAssertEqual(imported.messages.last?.tokenUsage?.total, 60)
        XCTAssertNil(imported.remoteId)
        XCTAssertNil(imported.lastResponseId)
        XCTAssertFalse(imported.shouldStoreRemotely)
        XCTAssertEqual(imported.syncState, .localOnly)
    }

    func testConversationTransferCodecImportsLegacyExportFormat() throws {
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "title": "New Chat",
            "lastModified": "2025-11-08T12:00:00Z",
            "messages": [
                [
                    "id": UUID().uuidString,
                    "role": "user",
                    "text": "Tidy up the conversation flow before release.",
                ],
                [
                    "id": UUID().uuidString,
                    "role": "assistant",
                    "text": "Import/export is the first thing to fix.",
                    "tokenUsage": [
                        "input": 25,
                        "output": 12,
                        "total": 37,
                    ],
                ],
            ],
            "tokenUsage": [
                "input": 25,
                "output": 12,
                "total": 37,
            ],
            "exportVersion": "1.0",
            "exportedAt": "2025-11-08T12:30:00Z",
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        let imported = try ConversationTransferCodec.importConversation(from: data)

        XCTAssertEqual(imported.messages.count, 2)
        XCTAssertEqual(imported.messages.first?.role, .user)
        XCTAssertEqual(imported.messages.last?.tokenUsage?.total, 37)
        XCTAssertEqual(imported.title, "New Chat")
        XCTAssertFalse(imported.shouldStoreRemotely)
        XCTAssertEqual(imported.syncState, .localOnly)
    }

    func testRequestBuilderOmitsBackgroundWhenStoreResponsesIsDisabled() {
        let service = OpenAIService()
        var prompt = Prompt.defaultPrompt()
        prompt.backgroundMode = true
        prompt.storeResponses = false

        let request = service.testing_buildRequestObject(
            for: prompt,
            userMessage: "Run in the background if possible."
        )

        XCTAssertEqual(request["store"] as? Bool, false)
        XCTAssertNil(request["background"])
    }

    func testRequestBuilderUsesSafetyIdentifierInsteadOfDeprecatedUserField() {
        let service = OpenAIService()
        var prompt = Prompt.defaultPrompt()
        prompt.userIdentifier = "hashed-user-123"

        let request = service.testing_buildRequestObject(
            for: prompt,
            userMessage: "Hello"
        )

        XCTAssertEqual(request["safety_identifier"] as? String, "hashed-user-123")
        XCTAssertNil(request["user"])
    }

    func testAppleDateUtilitiesParsesISO8601WithAndWithoutFractionalSeconds() {
        let withoutFractional = AppleDateUtilities.parseISO8601("2026-04-19T00:00:00Z")
        let withFractional = AppleDateUtilities.parseISO8601("2026-04-19T00:00:00.000Z")

        XCTAssertNotNil(withoutFractional)
        XCTAssertNotNil(withFractional)
        XCTAssertEqual(withoutFractional, withFractional)
    }

    func testAppleDateUtilitiesNormalizesUtcDayBoundaryQueriesToLocalDay() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let normalizedStart = AppleDateUtilities.parseQueryDate("2026-04-19T00:00:00Z", timeZone: losAngeles)
        let normalizedEnd = AppleDateUtilities.parseQueryDate("2026-04-19T23:59:59Z", timeZone: losAngeles)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = losAngeles

        let startComponents = normalizedStart.map { calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: $0) }
        let endComponents = normalizedEnd.map { calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: $0) }

        XCTAssertEqual(startComponents?.year, 2026)
        XCTAssertEqual(startComponents?.month, 4)
        XCTAssertEqual(startComponents?.day, 19)
        XCTAssertEqual(startComponents?.hour, 0)
        XCTAssertEqual(startComponents?.minute, 0)
        XCTAssertEqual(startComponents?.second, 0)

        XCTAssertEqual(endComponents?.year, 2026)
        XCTAssertEqual(endComponents?.month, 4)
        XCTAssertEqual(endComponents?.day, 19)
        XCTAssertEqual(endComponents?.hour, 23)
        XCTAssertEqual(endComponents?.minute, 59)
        XCTAssertEqual(endComponents?.second, 59)
    }

    func testAppleDateUtilitiesLeavesNonBoundaryUtcInstantsUnchanged() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let standard = AppleDateUtilities.parseISO8601("2026-04-19T16:30:00Z")
        let query = AppleDateUtilities.parseQueryDate("2026-04-19T16:30:00Z", timeZone: losAngeles)

        XCTAssertEqual(query, standard)
    }

    func testComputerToolEncodesUsingCurrentToolType() throws {
        let payload = [APICapabilities.Tool.computer]

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        XCTAssertEqual(json?.first?["type"] as? String, "computer")
        XCTAssertNil(json?.first?["display_width"])
        XCTAssertNil(json?.first?["display_height"])
        XCTAssertNil(json?.first?["environment"])
    }

    func testLegacyComputerPreviewToolEncodesUsingLegacyFields() throws {
        let payload = [APICapabilities.Tool.computerPreview(
            environment: "browser",
            displayWidth: 1024,
            displayHeight: 768
        )]

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        XCTAssertEqual(json?.first?["type"] as? String, "computer_use_preview")
        XCTAssertEqual(json?.first?["display_width"] as? Int, 1024)
        XCTAssertEqual(json?.first?["display_height"] as? Int, 768)
        XCTAssertEqual(json?.first?["environment"] as? String, "browser")
    }

    @MainActor
    func testComputerShortcutActivatesLocallyAndListsCapabilities() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let viewModel = ChatViewModel(
            storageService: ConversationStorageService(storageURL: directory),
            startBackgroundWork: false
        )
        viewModel.activePrompt.openAIModel = "gpt-5.4"
        viewModel.activePrompt.enableComputerUse = false

        viewModel.sendUserMessage("Computer")

        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        XCTAssertEqual(viewModel.messages.first?.text, "Computer")
        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("What would you like me to do?") == true)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("persistent live browser") == true)
        XCTAssertTrue(viewModel.messages.last?.text?.contains("live webpage DOM") == true)
        XCTAssertTrue(viewModel.activePrompt.enableComputerUse)
    }

    @MainActor
    func testSearchQueryExtractionStripsSearchBarSuffixes() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let viewModel = ChatViewModel(
            storageService: ConversationStorageService(storageURL: directory),
            startBackgroundWork: false
        )

        XCTAssertEqual(
            viewModel.testing_extractExplicitSearchQuery(from: "Open Google and search for penguin facts in the search bar"),
            "penguin facts"
        )
        XCTAssertEqual(
            viewModel.testing_refineSearchPhrase("backpacks in the search box and press enter"),
            "backpacks"
        )
    }

    @MainActor
    func testDerivedScreenshotURLUsesKnownEngineSearchResultsForExplicitSearches() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let viewModel = ChatViewModel(
            storageService: ConversationStorageService(storageURL: directory),
            startBackgroundWork: false
        )

        XCTAssertEqual(
            viewModel.testing_derivedScreenshotURL(from: "Open Google and search for penguin facts in the search bar"),
            "https://www.google.com/search?q=penguin%20facts"
        )
        XCTAssertEqual(
            viewModel.testing_derivedScreenshotURL(from: "Open Amazon and search for backpacks"),
            "https://www.amazon.com/s?k=backpacks"
        )
    }

    func testComputerServiceBuildsDirectSearchResultURLs() {
        XCTAssertEqual(
            ComputerService.testing_searchResultsURL(currentURL: "https://www.google.com", query: "penguin facts"),
            "https://www.google.com/search?q=penguin%20facts"
        )
        XCTAssertEqual(
            ComputerService.testing_searchResultsURL(siteKeyword: "amazon", query: "best value backpack"),
            "https://www.amazon.com/s?k=best%20value%20backpack"
        )
    }

    func testComputerServicePrefersProgrammaticSearchForSearchStyleSubmissions() {
        XCTAssertTrue(
            ComputerService.testing_shouldPreferProgrammaticSearch(
                fieldHint: "Google Search",
                submit: true,
                currentURL: "https://www.google.com"
            )
        )

        XCTAssertTrue(
            ComputerService.testing_shouldPreferProgrammaticSearch(
                fieldHint: nil,
                submit: true,
                currentURL: "https://www.amazon.com"
            )
        )

        XCTAssertFalse(
            ComputerService.testing_shouldPreferProgrammaticSearch(
                fieldHint: "Email",
                submit: true,
                currentURL: "https://accounts.google.com"
            )
        )

        XCTAssertFalse(
            ComputerService.testing_shouldPreferProgrammaticSearch(
                fieldHint: "Google Search",
                submit: false,
                currentURL: "https://www.google.com"
            )
        )
    }

    // Test PromptLibrary
    @MainActor
    func testPromptLibraryPersistsAddUpdateAndDelete() throws {
        let library = PromptLibrary(userDefaults: promptDefaults, userDefaultsKey: "savedPrompts")
        var prompt = Prompt.defaultPrompt()
        prompt.name = "Release Prompt"

        library.addPrompt(prompt)
        XCTAssertEqual(library.prompts.count, 1)

        var savedPrompt = try XCTUnwrap(library.prompts.first)
        XCTAssertNotEqual(savedPrompt.id, prompt.id)
        savedPrompt.temperature = 0.42
        library.updatePrompt(savedPrompt)

        let reloadedLibrary = PromptLibrary(userDefaults: promptDefaults, userDefaultsKey: "savedPrompts")
        XCTAssertEqual(reloadedLibrary.prompts.count, 1)
        XCTAssertEqual(reloadedLibrary.prompts.first?.temperature, 0.42)

        reloadedLibrary.deletePrompt(at: IndexSet(integer: 0))
        XCTAssertTrue(reloadedLibrary.prompts.isEmpty)
    }
}
