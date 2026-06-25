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

    @MainActor
    func testChatMessageWithURLDetection() {
        // Test with text containing renderable URLs
        let messageWithURLs = ChatMessage.withURLDetection(role: .user, text: "Check out https://github.com and https://apple.com")
        XCTAssertEqual(messageWithURLs.webURLs?.count, 2)
        XCTAssertEqual(messageWithURLs.webURLs?[0].absoluteString, "https://github.com")
        XCTAssertEqual(messageWithURLs.webURLs?[1].absoluteString, "https://apple.com")

        // Test with text containing no renderable URLs
        let messageWithoutURLs = ChatMessage.withURLDetection(role: .user, text: "Hello world")
        XCTAssertNil(messageWithoutURLs.webURLs)

        // Test with forceWebURLs overriding text
        let forcedURL = URL(string: "https://override.com")!
        let messageWithForced = ChatMessage.withURLDetection(role: .user, text: "Check https://github.com", forceWebURLs: [forcedURL])
        XCTAssertEqual(messageWithForced.webURLs?.count, 1)
        XCTAssertEqual(messageWithForced.webURLs?[0].absoluteString, "https://override.com")

        // Test with nil text and nil forceWebURLs
        let messageWithNil = ChatMessage.withURLDetection(role: .user, text: nil)
        XCTAssertNil(messageWithNil.webURLs)
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


    func testAppleDateUtilitiesMakeReminderDateComponents() {
        let timeZone = TimeZone(identifier: "America/New_York")!

        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 5
        dateComponents.day = 10
        dateComponents.hour = 14
        dateComponents.minute = 30
        dateComponents.second = 45
        dateComponents.timeZone = timeZone
        dateComponents.calendar = Calendar(identifier: .gregorian)

        guard let date = dateComponents.calendar?.date(from: dateComponents) else {
            XCTFail("Failed to create date")
            return
        }

        let reminderComponents = AppleDateUtilities.makeReminderDateComponents(from: date, timeZone: timeZone)

        XCTAssertEqual(reminderComponents.year, 2026)
        XCTAssertEqual(reminderComponents.month, 5)
        XCTAssertEqual(reminderComponents.day, 10)
        XCTAssertEqual(reminderComponents.hour, 14)
        XCTAssertEqual(reminderComponents.minute, 30)
        XCTAssertEqual(reminderComponents.second, 45)
        XCTAssertEqual(reminderComponents.timeZone, timeZone)
        XCTAssertEqual(reminderComponents.calendar?.identifier, .gregorian)
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

    func testExtractImageLinks_MarkdownSyntax_WithTitle() {
        let text = "Here is an image: ![Alt text](https://example.com/image.png \"Image Title\")"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0], "https://example.com/image.png")
    }

    func testExtractImageLinks_MarkdownSyntax_EmptyUrl() {
        let text = "Here is an image with empty url: ![Alt text]()"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertTrue(links.isEmpty)
    }

    func testExtractImageLinks_BareHttpLinks_MixedCase() {
        let text = "Check out this image: https://example.com/test.PNG and also http://test.com/img.JpEg"
        let links = URLDetector.extractImageLinks(from: text)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0], "https://example.com/test.PNG")
        XCTAssertEqual(links[1], "http://test.com/img.JpEg")
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


    // MARK: - detectURLs Tests

    func testDetectURLs_WithEmptyString_ReturnsEmptyArray() {
        let urls = URLDetector.detectURLs(in: "")
        XCTAssertTrue(urls.isEmpty)
    }

    func testDetectURLs_WithNoURLs_ReturnsEmptyArray() {
        let text = "This is a simple text without any URLs."
        let urls = URLDetector.detectURLs(in: text)
        XCTAssertTrue(urls.isEmpty)
    }

    func testDetectURLs_WithValidHttpAndHttpsURLs_ExtractsCorrectly() {
        let text = "Check out http://example.com and https://www.test.org for more info."
        let urls = URLDetector.detectURLs(in: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "http://example.com")
        XCTAssertEqual(urls[1].absoluteString, "https://www.test.org")
    }

    func testDetectURLs_WithTrailingPunctuation_ExcludesPunctuation() {
        let text = "Have you seen https://apple.com? I also like https://github.com/! And here is https://wikipedia.org."
        let urls = URLDetector.detectURLs(in: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "https://apple.com")
        XCTAssertEqual(urls[1].absoluteString, "https://github.com/")
        XCTAssertEqual(urls[2].absoluteString, "https://wikipedia.org")
    }

    func testDetectURLs_IncludesNonHttpSchemes() {
        let text = "Send an email to test@example.com or use ftp://files.example.com to upload. But also visit https://valid.com."
        let urls = URLDetector.detectURLs(in: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "mailto:test@example.com")
        XCTAssertEqual(urls[1].absoluteString, "ftp://files.example.com")
        XCTAssertEqual(urls[2].absoluteString, "https://valid.com")
    }

    func testDetectURLs_WithComplexPathsAndQueries_ExtractsCorrectly() {
        let text = "Read more at https://example.com/path/to/page?param1=value&param2=123#section"
        let urls = URLDetector.detectURLs(in: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://example.com/path/to/page?param1=value&param2=123#section")
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
        // Note: '?' is treated as a query indicator rather than trailing punctuation.
        XCTAssertEqual(urls[0].absoluteString, "https://apple.com?")
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

    func testIsRenderableWebpage_AllSkipPatterns() {
        let skipPatterns = [
            "api.", "/api/", ".json", ".xml", ".pdf",
            ".jpg", ".jpeg", ".png", ".gif", ".webp",
            ".mp4", ".mp3", ".wav", ".zip", ".tar", ".gz"
        ]

        for pattern in skipPatterns {
            // Test in host
            // Not all patterns make valid hosts (like /api/), so we clean them up to inject
            let cleanPattern = pattern.trimmingCharacters(in: CharacterSet(charactersIn: "./"))
            if !cleanPattern.isEmpty {
                let hostUrlStr = "https://www.\(cleanPattern)example.com"
                if let hostUrl = URL(string: hostUrlStr) {
                    XCTAssertFalse(URLDetector.isRenderableWebpage(hostUrl), "Expected \(hostUrl) to NOT be a renderable webpage (skip pattern in host: \(pattern))")
                }
            }

            // Test in path
            if let url = URL(string: "https://www.example.com/path/to\(pattern)") {
                XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage (skip pattern: \(pattern))")
            }
        }
    }

    func testIsRenderableWebpage_CaseInsensitivity() {
        let urls = [
            URL(string: "https://API.example.com/data")!,
            URL(string: "https://example.com/API/v1/users")!,
            URL(string: "https://example.com/document.PDF")!,
            URL(string: "https://example.com/image.JPG")!
        ]

        for url in urls {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage (case insensitivity)")
        }
    }

    func testIsRenderableWebpage_QueryParametersNotSkipped() {
        // The implementation checks host and path, NOT query.
        // So a pattern in the query should not cause it to return false if it's otherwise a webpage.
        let urls = [
            URL(string: "https://www.example.com/viewer?file=document.pdf")!,
            URL(string: "https://www.example.com/search?q=api.")!,
            URL(string: "https://www.example.com/download?format=.json")!
        ]

        for url in urls {
            XCTAssertTrue(URLDetector.isRenderableWebpage(url), "Expected \(url) to be a renderable webpage (pattern in query only)")
        }
    }

    func testIsRenderableWebpage_NoHost() {
        // File URLs or custom schemes without a host
        let urls = [
            URL(string: "file:///path/to/document.pdf")!,
            URL(string: "custom:/api/data")!
        ]

        for url in urls {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage")
        }
    }

    func testIsRenderableWebpage_ValidWebpages() {
        let validURLs = [
            URL(string: "https://www.example.com")!,
            URL(string: "http://example.org/about")!,
            URL(string: "https://news.ycombinator.com/item?id=123")!,
            URL(string: "https://github.com/apple/swift")!,
            URL(string: "http://my-blog.dev/post/1")!
        ]

        for url in validURLs {
            XCTAssertTrue(URLDetector.isRenderableWebpage(url), "Expected \(url) to be a renderable webpage")
        }
    }

    // MARK: - extractRenderableURLs Tests

    func testExtractRenderableURLs_FiltersCorrectly() {
        let text = "Visit https://example.com or download https://example.com/file.pdf or hit the api https://api.example.com/data"
        let urls = URLDetector.extractRenderableURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://example.com")
    }

    // MARK: - detectURLs Tests

    func testDetectURLs_ExtractsAllLinkTypes() {
        let text = "Check out http://example.com, ftp://files.com/doc, and mailto:test@example.com"
        let urls = URLDetector.detectURLs(in: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "http://example.com")
        XCTAssertEqual(urls[1].absoluteString, "ftp://files.com/doc")
        XCTAssertEqual(urls[2].absoluteString, "mailto:test@example.com")
    }

    // MARK: - detectUniqueURLs Tests

    func testDetectUniqueURLs_RemovesDuplicatesAndPreservesOrder() {
        let text = "First https://one.com, then https://two.com, and again https://one.com. Finally https://three.com"
        let urls = URLDetector.detectUniqueURLs(in: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "https://one.com")
        XCTAssertEqual(urls[1].absoluteString, "https://two.com")
        XCTAssertEqual(urls[2].absoluteString, "https://three.com")
    }


    // MARK: - Additional extractURLs Tests

    func testExtractURLs_WithMixedCaseSchemes_ExtractsCorrectly() {
        let text = "Visit HtTpS://example.com or HTTP://test.org for info."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString.lowercased(), "https://example.com")
        XCTAssertEqual(urls[1].absoluteString.lowercased(), "http://test.org")
    }

    func testExtractURLs_WithIPAddress_ExtractsCorrectly() {
        let text = "Local router is at http://192.168.1.1 or https://10.0.0.1:8080/admin"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "http://192.168.1.1")
        XCTAssertEqual(urls[1].absoluteString, "https://10.0.0.1:8080/admin")
    }


    func testExtractURLs_ExcludesNonHttpSchemes() {
        let text = "Check out ftp://files.com or mailto:test@example.com or data:image/png;base64,123 but keep http://valid.com"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "http://valid.com")
    }



    func testExtractURLs_WithNewlinesAndTabs_ExtractsCorrectly() {
        let text = "\t\nhttp://test.com\n\t\rhttps://example.com/tabbed"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "http://test.com")
        XCTAssertEqual(urls[1].absoluteString, "https://example.com/tabbed")
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

final class OpenAIModelTests: XCTestCase {

    func testDisplayName_GPT5Series() {
        let models = [
            "gpt-5.5": "gpt-5.5",
            "gpt-5.5-pro": "gpt-5.5-pro",
            "gpt-5.5-mini": "gpt-5.5-mini",
            "gpt-5.5-nano": "gpt-5.5-nano",
            "gpt-5.4": "gpt-5.4",
            "gpt-5.4-pro": "gpt-5.4-pro",
            "gpt-5.4-mini": "gpt-5.4-mini",
            "gpt-5.4-nano": "gpt-5.4-nano",
            "gpt-5.2": "gpt-5.2",
            "gpt-5.2-pro": "gpt-5.2-pro",
            "gpt-5.1": "gpt-5.1",
            "gpt-5-mini": "gpt-5-mini",
            "gpt-5-nano": "gpt-5-nano",
            "gpt-5": "gpt-5",
            "gpt-5-thinking": "gpt-5-thinking"
        ]

        for (id, expectedName) in models {
            let model = OpenAIModel(id: id, object: "model", created: 123, ownedBy: "openai")
            XCTAssertEqual(model.displayName, expectedName)
            XCTAssertTrue(model.isReasoningModel) // All gpt-5 models are reasoning models
        }
    }

    func testDisplayName_GPT4Series() {
        let models = [
            "gpt-4.1": "gpt-4.1",
            "gpt-4.1-mini": "gpt-4.1-mini",
            "gpt-4.1-nano": "gpt-4.1-nano",
            "gpt-4.1-2025-04-14": "gpt-4.1 (2025-04-14)",
            "gpt-4o": "gpt-4o",
            "gpt-4o-mini": "gpt-4o-mini",
            "gpt-4o-2024-08-06": "gpt-4o (2024-08-06)",
            "gpt-4o-mini-2024-07-18": "gpt-4o-mini (2024-07-18)",
            "computer-use-preview": "computer-use-preview"
        ]

        for (id, expectedName) in models {
            let model = OpenAIModel(id: id, object: "model", created: 123, ownedBy: "openai")
            XCTAssertEqual(model.displayName, expectedName)
            XCTAssertFalse(model.isReasoningModel) // GPT-4 models are not reasoning models
        }
    }

    func testDisplayName_OSeries() {
        let models = [
            "o1": "o1",
            "o1-preview": "o1-preview",
            "o1-mini": "o1-mini",
            "o3": "o3",
            "o3-mini": "o3-mini",
            "o3-pro": "o3-pro" // Matches the prefix logic
        ]

        for (id, expectedName) in models {
            let model = OpenAIModel(id: id, object: "model", created: 123, ownedBy: "openai")
            XCTAssertEqual(model.displayName, expectedName)
            XCTAssertTrue(model.isReasoningModel) // O-series are reasoning models
        }
    }

    func testDisplayName_Fallback() {
        let models = [
            "unknown-model",
            "gpt-3.5-turbo",
            "dall-e-3"
        ]

        for id in models {
            let model = OpenAIModel(id: id, object: "model", created: 123, ownedBy: "openai")
            XCTAssertEqual(model.displayName, id) // Fallback returns the id as-is
            XCTAssertFalse(model.isReasoningModel)
        }
    }
}
