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

    func testConversationEncoding() throws {
        let id = UUID()
        let lastModified = Date(timeIntervalSince1970: 1000)
        let lastSyncedAt = Date(timeIntervalSince1970: 2000)
        let conversation = Conversation(
            id: id,
            remoteId: "remote_123",
            title: "Test Chat",
            messages: [ChatMessage(role: .user, text: "Hello")],
            lastResponseId: "resp_123",
            lastModified: lastModified,
            metadata: ["key": "value"],
            lastSyncedAt: lastSyncedAt,
            shouldStoreRemotely: false,
            syncState: .synced
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(conversation)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, id.uuidString)
        XCTAssertEqual(json?["remoteId"] as? String, "remote_123")
        XCTAssertEqual(json?["title"] as? String, "Test Chat")
        XCTAssertEqual(json?["lastResponseId"] as? String, "resp_123")
        XCTAssertEqual(json?["shouldStoreRemotely"] as? Bool, false)
        XCTAssertEqual(json?["syncState"] as? String, Conversation.SyncState.synced.rawValue)

        let metadata = json?["metadata"] as? [String: String]
        XCTAssertEqual(metadata?["key"], "value")

        let messages = json?["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 1)
    }

    func testConversationDecodesLegacyJSONWithDefaults() throws {
        let jsonString = """
        {
            "id": "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
            "title": "Legacy Test Title"
        }
        """

        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        let conversation = try decoder.decode(Conversation.self, from: data)

        XCTAssertEqual(conversation.id, UUID(uuidString: "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D"))
        XCTAssertNil(conversation.remoteId)
        XCTAssertEqual(conversation.title, "Legacy Test Title")
        XCTAssertTrue(conversation.messages.isEmpty)
        XCTAssertNil(conversation.lastResponseId)

        let timeDifference = abs(conversation.lastModified.timeIntervalSince(Date()))
        XCTAssertLessThan(timeDifference, 5.0)

        XCTAssertNil(conversation.metadata)
        XCTAssertNil(conversation.lastSyncedAt)
        XCTAssertTrue(conversation.shouldStoreRemotely)
        XCTAssertEqual(conversation.syncState, .localOnly)
    }

    func testConversationDecodesLegacyJSONWithRemoteIdSetsSyncState() throws {
        let jsonString = """
        {
            "id": "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
            "title": "Legacy Test Title",
            "remoteId": "conv_remote_123"
        }
        """

        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        let conversation = try decoder.decode(Conversation.self, from: data)

        XCTAssertEqual(conversation.syncState, .synced)
    }

    func testConversationDecodesFullyPopulatedJSON() throws {
        let jsonString = """
        {
            "id": "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
            "remoteId": "conv_remote_123",
            "title": "Test Title",
            "messages": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "role": "user",
                    "text": "Hello"
                }
            ],
            "lastResponseId": "resp_456",
            "lastModified": 703555200,
            "metadata": {"key": "value"},
            "lastSyncedAt": 703555200,
            "shouldStoreRemotely": false,
            "syncState": "synced"
        }
        """

        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        let conversation = try decoder.decode(Conversation.self, from: data)

        XCTAssertEqual(conversation.id, UUID(uuidString: "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D"))
        XCTAssertEqual(conversation.remoteId, "conv_remote_123")
        XCTAssertEqual(conversation.title, "Test Title")
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first?.text, "Hello")
        XCTAssertEqual(conversation.lastResponseId, "resp_456")
        XCTAssertEqual(conversation.lastModified.timeIntervalSinceReferenceDate, 703555200)
        XCTAssertEqual(conversation.metadata, ["key": "value"])
        XCTAssertEqual(conversation.lastSyncedAt?.timeIntervalSinceReferenceDate, 703555200)
        XCTAssertEqual(conversation.shouldStoreRemotely, false)
        XCTAssertEqual(conversation.syncState, .synced)
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

    func testComputerServiceNormalizesComputerUseMouseMetadata() {
        XCTAssertEqual(ComputerService.testing_mouseButtonCode("left"), 0)
        XCTAssertEqual(ComputerService.testing_mouseButtonCode("middle"), 1)
        XCTAssertEqual(ComputerService.testing_mouseButtonCode("right"), 2)
        XCTAssertEqual(ComputerService.testing_mouseButtonsMask(for: 0), 1)
        XCTAssertEqual(ComputerService.testing_mouseButtonsMask(for: 1), 4)
        XCTAssertEqual(ComputerService.testing_mouseButtonsMask(for: 2), 2)

        let flags = ComputerService.testing_mouseModifierFlags(keys: ["CTRL", "Shift", "Option", "Meta"])
        XCTAssertEqual(flags["ctrl"], true)
        XCTAssertEqual(flags["shift"], true)
        XCTAssertEqual(flags["alt"], true)
        XCTAssertEqual(flags["meta"], true)
    }

    func testComputerServiceNormalizesComputerUseKeyboardKeys() {
        XCTAssertEqual(ComputerService.testing_normalizedKeyboardKey("ARROWLEFT"), "ArrowLeft")
        XCTAssertEqual(ComputerService.testing_normalizedKeyboardKey("pagedown"), "PageDown")
        XCTAssertEqual(ComputerService.testing_normalizedKeyboardKey("ESC"), "Escape")
        XCTAssertEqual(ComputerService.testing_normalizedKeyboardKey("SPACE"), " ")
        XCTAssertEqual(ComputerService.testing_normalizedKeyboardKey("a"), "a")
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

final class URLDetectorTests: XCTestCase {

    func testExtractImageLinks_MarkdownSyntax() {
        let text = "Here is an image: ![Alt text](https://example.com/image.png) and another ![Second](https://example.com/second.jpg)."
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0], "https://example.com/image.png")
        XCTAssertEqual(links[1], "https://example.com/second.jpg")
    }

    func testExtractImageLinks_BareHttpLinks() {
        let text = "Check out this image: https://example.com/test.png?size=large and also http://test.com/img.jpg"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0], "https://example.com/test.png?size=large")
        XCTAssertEqual(links[1], "http://test.com/img.jpg")
    }

    func testExtractImageLinks_DataURLs() {
        let text = "Inline image data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII= "
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0], "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")
    }

    func testExtractImageLinks_SandboxPaths() {
        let text = "Local file at sandbox:/Documents/image.png"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0], "sandbox:/Documents/image.png")
    }

    func testExtractImageLinks_DuplicateRemoval() {
        let text = "Image ![test](https://example.com/img.png) and the same bare link https://example.com/img.png"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0], "https://example.com/img.png")
    }

    func testExtractImageLinks_OrderPreservation() {
        let text = """
        1. https://example.com/one.png
        2. ![Two](https://example.com/two.jpg)
        3. sandbox:/three.webp
        4. data:image/png;base64,four
        """
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 4)
        XCTAssertEqual(links[0], "https://example.com/one.png")
        XCTAssertEqual(links[1], "https://example.com/two.jpg")
        XCTAssertEqual(links[2], "sandbox:/three.webp")
        XCTAssertEqual(links[3], "data:image/png;base64,four")
    }

    // MARK: - extractURLs Tests

    func testExtractURLs_WithEmptyString_ReturnsEmptyArray() {
        let urls = URLDetector.extractURLs(from: "")
        XCTAssertTrue(urls.isEmpty)
    }

    func testExtractURLs_WithNoURLs_ReturnsEmptyArray() {
        let text = "This is a simple text without any URLs."
        let urls = URLDetector.extractURLs(from: text)
        XCTAssertTrue(urls.isEmpty)
    }

    func testExtractURLs_WithValidHttpAndHttpsURLs_ExtractsCorrectly() {
        let text = "Check out http://example.com and https://www.test.org for more info."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "http://example.com")
        XCTAssertEqual(urls[1].absoluteString, "https://www.test.org")
    }

    func testExtractURLs_WithTrailingPunctuation_ExcludesPunctuation() {
        let text = "Have you seen https://apple.com? I also like https://github.com/! And here is https://wikipedia.org."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 3)
        // NSDataDetector automatically handles trailing punctuation intelligently.
        XCTAssertEqual(urls[0].absoluteString, "https://apple.com")
        XCTAssertEqual(urls[1].absoluteString, "https://github.com/")
        XCTAssertEqual(urls[2].absoluteString, "https://wikipedia.org")
    }

    func testExtractURLs_FiltersOutNonHttpSchemes() {
        // extractURLs is supposed to filter for "http" or "https" only
        let text = "Send an email to test@example.com or use ftp://files.example.com to upload. But also visit https://valid.com."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://valid.com")
    }

    func testExtractURLs_WithComplexPathsAndQueries_ExtractsCorrectly() {
        let text = "Read more at https://example.com/path/to/page?param1=value&param2=123#section"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://example.com/path/to/page?param1=value&param2=123#section")
    }

    func testExtractURLs_WithMultipleConsecutiveURLs_ExtractsCorrectly() {
        let text = "https://one.com https://two.com\nhttps://three.com"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "https://one.com")
        XCTAssertEqual(urls[1].absoluteString, "https://two.com")
        XCTAssertEqual(urls[2].absoluteString, "https://three.com")
    }

    // MARK: - isRenderableWebpage Tests

    func testIsRenderableWebpage_ValidWebpages() {
        let validURLs = [
            URL(string: "https://www.example.com")!,
            URL(string: "http://example.org/about")!,
            URL(string: "https://news.ycombinator.com/item?id=123")!,
            URL(string: "https://github.com/apple/swift")!,
            URL(string: "http://my-blog.dev/post/1")!
        ]

        for url in validURLs {
            XCTAssertTrue(URLDetector.isRenderableWebpage(url), "Expected \\(url) to be a renderable webpage")
        }
    }

    func testIsRenderableWebpage_APIEndpoints() {
        let apiURLs = [
            URL(string: "https://api.example.com/v1/users")!,
            URL(string: "https://example.com/api/v2/data")!,
            URL(string: "https://api.github.com/repos/apple/swift")!,
            URL(string: "http://backend.service/api/login")!
        ]

        for url in apiURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \\(url) to NOT be a renderable webpage (API endpoint)")
        }
    }

    func testIsRenderableWebpage_Files() {
        let fileURLs = [
            URL(string: "https://example.com/data.json")!,
            URL(string: "https://example.com/feed.xml")!,
            URL(string: "https://example.com/document.pdf")!,
            URL(string: "https://example.com/image.jpg")!,
            URL(string: "https://example.com/video.mp4")!,
            URL(string: "https://example.com/archive.zip")!
        ]

        for url in fileURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \\(url) to NOT be a renderable webpage (File extension)")
        }
    }

    func testIsRenderableWebpage_UnknownDomains() {
        let unknownURLs = [
            URL(string: "https://internal-server.local")!,
            URL(string: "http://192.168.1.1")!,
            URL(string: "https://my-app.custom")!
        ]

        for url in unknownURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \\(url) to NOT be a renderable webpage (Unknown domain)")
        }
    }
}

final class AppleDateUtilitiesTests: XCTestCase {

    func testParseISO8601_WithNilOrEmptyString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601(nil))
        XCTAssertNil(AppleDateUtilities.parseISO8601(""))
        XCTAssertNil(AppleDateUtilities.parseISO8601("   "))
        XCTAssertNil(AppleDateUtilities.parseISO8601("\n\t "))
    }

    func testParseISO8601_WithValidString_NoFractionalSeconds() {
        let validString = "2023-10-25T14:30:00Z"
        let parsedDate = AppleDateUtilities.parseISO8601(validString)
        XCTAssertNotNil(parsedDate)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate!)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 25)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)
    }

    func testParseISO8601_WithValidString_WithFractionalSeconds() {
        let validString = "2023-10-25T14:30:00.123Z"
        let parsedDate = AppleDateUtilities.parseISO8601(validString)
        XCTAssertNotNil(parsedDate)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: parsedDate!)

        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 25)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 0)

        // 123 milliseconds is 123_000_000 nanoseconds
        // Date computations might have slight precision issues, so we check an approximate range or rounded value if necessary.
        // But for ISO8601DateFormatter it should be quite exact.
        if let nanosecond = components.nanosecond {
            // Allow a small delta for floating point precision issues in Date
            let diff = abs(nanosecond - 123_000_000)
            XCTAssertLessThan(diff, 1_000_000, "Nanoseconds should be approximately 123,000,000")
        } else {
            XCTFail("Nanoseconds should not be nil")
        }
    }

    func testParseISO8601_WithInvalidString_ReturnsNil() {
        XCTAssertNil(AppleDateUtilities.parseISO8601("invalid-date"))
        XCTAssertNil(AppleDateUtilities.parseISO8601("2023/10/25 14:30:00"))
        XCTAssertNil(AppleDateUtilities.parseISO8601("2023-10-25")) // Missing time part
    }
}
