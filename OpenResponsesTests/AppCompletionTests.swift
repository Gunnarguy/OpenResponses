import XCTest
import UIKit
@testable import OpenResponses

@MainActor
final class AppCompletionTests: XCTestCase {
    func testMalformedSchemaCannotBecomeEmptyObjectInRequestPreview() {
        var prompt = Prompt.defaultPrompt()
        prompt.textFormatType = "json_schema"
        prompt.jsonSchemaName = "answer"
        for content in ["", "{", "[]", "null", "42", "{}", "{\"type\":\"array\"}"] {
            prompt.jsonSchemaContent = content
            XCTAssertThrowsError(try ResponseConfigurationValidation.validate(prompt), content)
            let preview = OpenAIService().testing_buildRequestObject(for: prompt, userMessage: "test")
            XCTAssertNotNil(preview["validation_error"], content)
            XCTAssertNil(preview["text"], content)
        }
    }

    func testStructuredSchemaNameAndNestedStrictRequirements() throws {
        var prompt = Prompt.defaultPrompt()
        prompt.textFormatType = "json_schema"
        prompt.jsonSchemaStrict = true
        prompt.jsonSchemaName = "answer"
        prompt.jsonSchemaContent = #"{"type":"object","properties":{"answer":{"type":["string","null"]}},"required":["answer"],"additionalProperties":false}"#
        XCTAssertNoThrow(try ResponseConfigurationValidation.validate(prompt))
        prompt.jsonSchemaName = ""
        XCTAssertThrowsError(try ResponseConfigurationValidation.validate(prompt))
        prompt.jsonSchemaName = "bad name"
        XCTAssertThrowsError(try ResponseConfigurationValidation.validate(prompt))
        prompt.jsonSchemaName = "answer"
        prompt.jsonSchemaContent = #"{"type":"object","properties":{"nested":{"type":"object","properties":{}}},"required":["nested"],"additionalProperties":false}"#
        XCTAssertThrowsError(try ResponseConfigurationValidation.validate(prompt)) { error in
            XCTAssertTrue(error.localizedDescription.contains("properties.nested"))
        }
    }

    func testSchemaValidationKeepsReferencesAndLiteralExampleData() throws {
        let schema = ##"{"type":"object","properties":{"answer":{"$ref":"#/$defs/value"}},"required":["answer"],"additionalProperties":false,"$defs":{"value":{"type":"string","examples":[{"type":"object"}]}}}"##
        let body: [String: Any] = ["text": ["format": ["type": "json_schema", "name": "answer", "strict": true,
            "schema": try ResponseConfigurationValidation.object(schema, label: "Test")]]]
        XCTAssertNoThrow(try ResponseConfigurationValidation.validate(body: body))
    }

    func testInvalidCustomToolConfigurationIsRejected() {
        var prompt = Prompt.defaultPrompt()
        prompt.enableCustomTool = true
        prompt.customToolName = "lookup"
        for content in ["{", "[]", "42"] {
            prompt.customToolParametersJSON = content
            XCTAssertThrowsError(try ResponseConfigurationValidation.validate(prompt))
        }
        prompt.customToolParametersJSON = #"{"type":"object","properties":{}}"#
        XCTAssertNoThrow(try ResponseConfigurationValidation.validate(prompt))
    }

    func testRawWorkbenchRejectsInvalidSchemaBeforeAnyTransportConnects() {
        let invalid: [String: Any] = ["text": ["format": ["type": "json_schema", "name": "answer", "schema": "not an object"]]]
        for transport in APIWorkbenchSession.Transport.allCases {
            let session = APIWorkbenchSession()
            session.run(body: invalid, transport: transport)
            XCTAssertFalse(session.isRunning)
            XCTAssertFalse(session.hasOpenSocket)
            XCTAssertTrue(session.status.contains("schema must be a JSON object"))
        }
        XCTAssertThrowsError(try ResponsesAPIClient().request(path: "/responses", body: invalid)) { error in
            XCTAssertTrue(error.localizedDescription.contains("schema must be a JSON object"))
        }
    }

    func testWorkbenchDraftRestoresInvalidWorkInProgressAndAllSelectors() throws {
        var persisted: Data?
        let draft = APIWorkbenchDraft(requestText: "{ unfinished", template: "Hosted shell", endpoint: "Retrieve response", transport: "WebSocket", resourceID: "resp_example")
        let store = APIWorkbenchDraftStore(read: { persisted }, write: { persisted = $0 })
        store.schedule(draft)
        store.flush()
        let reopened = APIWorkbenchDraftStore(read: { persisted }, write: { persisted = $0 })
        XCTAssertEqual(reopened.restored, draft)
    }

    func testWorkbenchDraftFlushKeepsLatestEditAndSkipsDuplicateWrites() throws {
        var persisted: Data?
        var writes = 0
        let store = APIWorkbenchDraftStore(read: { nil }, write: { persisted = $0; writes += 1 })
        var draft = APIWorkbenchDraft(requestText: "first", template: "Astra response", endpoint: "Create response", transport: "SSE", resourceID: "")
        store.schedule(draft)
        draft.requestText = "last edit before background"
        store.schedule(draft)
        store.flush()
        store.schedule(draft)
        store.flush()
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(try JSONDecoder().decode(APIWorkbenchDraft.self, from: XCTUnwrap(persisted)), draft)
    }

    func testWorkbenchDraftSaveFailurePreservesPreviousDraftAndCanRetry() throws {
        enum Failure: Error { case unavailable }
        var persisted: Data?
        var fail = false
        let store = APIWorkbenchDraftStore(read: { nil }, write: {
            if fail { throw Failure.unavailable }
            persisted = $0
        })
        var draft = APIWorkbenchDraft(requestText: "saved", template: "Astra response", endpoint: "Create response", transport: "SSE", resourceID: "")
        store.schedule(draft); store.flush()
        let previous = persisted
        fail = true
        draft.requestText = "new edit"
        store.schedule(draft); store.flush()
        XCTAssertEqual(persisted, previous)
        XCTAssertTrue(store.status.contains("could not be saved"))
        fail = false
        store.flush()
        XCTAssertEqual(try JSONDecoder().decode(APIWorkbenchDraft.self, from: XCTUnwrap(persisted)).requestText, "new edit")
    }

    func testUnreadableWorkbenchDraftIsNeverOverwrittenByDefaults() {
        var writes = 0
        let store = APIWorkbenchDraftStore(read: { Data("broken".utf8) }, write: { _ in writes += 1 })
        store.schedule(.init(requestText: "default", template: "Astra response", endpoint: "Create response", transport: "SSE", resourceID: ""))
        store.flush()
        XCTAssertNil(store.restored)
        XCTAssertEqual(writes, 0)
        XCTAssertTrue(store.status.contains("preserved"))
    }

    func testSwitchBeforeBufferedFlushKeepsTextInOriginalChat() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ChatViewModel(storageService: ConversationStorageService(storageURL: directory), startBackgroundWork: false)
        let message = ChatMessage(role: .assistant, text: "Start")
        model.messages = [ChatMessage(role: .user, text: "Prompt"), message]
        let originalId = try XCTUnwrap(model.activeConversation?.id)
        model.deltaBuffers[message.id] = " finished"
        model.scheduleDeltaFlush(for: message.id, messageIndex: 1, immediate: false)
        model.isStreaming = true
        model.streamingMessageId = message.id
        let next = Conversation.new(storePreference: false)
        model.selectConversation(next)
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertTrue(model.messages.isEmpty)
        XCTAssertFalse(model.isStreaming)
        XCTAssertEqual(model.conversations.first { $0.id == originalId }?.messages.last?.text, "Start finished")
        await model.flushConversationStorage()
    }

    func testBufferedFlushResolvesMessageIdentityAfterIndexChanges() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ChatViewModel(storageService: ConversationStorageService(storageURL: directory), startBackgroundWork: false)
        let message = ChatMessage(role: .assistant, text: "A")
        model.messages = [message]
        model.deltaBuffers[message.id] = "B"
        model.scheduleDeltaFlush(for: message.id, messageIndex: 0, immediate: false)
        model.messages.insert(ChatMessage(role: .user, text: "Other"), at: 0)
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(model.messages.first?.text, "Other")
        XCTAssertEqual(model.messages.last?.text, "AB")
        await model.flushConversationStorage()
    }

    func testStorageCoalescesBurstAndPersistsLatestImageConversation() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = ConversationStorageService(storageURL: directory, saveDelayNanoseconds: 30_000_000_000)
        _ = try storage.loadConversations()
        var conversation = Conversation.new(storePreference: false)
        conversation.messages = [ChatMessage(role: .assistant, text: "", images: [makeImage(.red)])]
        for index in 0..<100 {
            conversation.messages[0].text = "Chunk \(index)"
            storage.scheduleSave(conversation) { XCTFail($0.localizedDescription) }
        }
        XCTAssertEqual(storage.completedWriteCount, 0)
        await storage.flushPendingSaves()
        let saved = try ConversationStorageService(storageURL: directory).loadConversations()
        XCTAssertEqual(saved.first?.messages.first?.text, "Chunk 99")
        XCTAssertEqual(saved.first?.messages.first?.images?.count, 1)
        await Task.yield()
        XCTAssertEqual(storage.completedWriteCount, 1)
    }

    func testQueuedAndPendingSavesCannotResurrectDeletedConversation() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = ConversationStorageService(storageURL: directory)
        let conversation = Conversation.new(storePreference: false)
        storage.scheduleSave(conversation) { XCTFail($0.localizedDescription) }
        storage.flushScheduledSaves()
        storage.scheduleSave(conversation) { XCTFail($0.localizedDescription) }
        try storage.deleteConversation(withId: conversation.id)
        await storage.flushPendingSaves()
        XCTAssertTrue(try ConversationStorageService(storageURL: directory).loadConversations().isEmpty)
    }

    func testImageCacheInvalidatesWhenImageArrayChanges() throws {
        let original = ChatMessage(role: .user, text: "Image", images: [makeImage(.red)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let first = try encoder.encode(original)
        var edited = original
        edited.images = [makeImage(.blue)]
        let second = try encoder.encode(edited)
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first, try encoder.encode(original))
    }

    func testPaginationCollectsAllPagesAndDeduplicatesOverlappingItems() async throws {
        var cursors: [String?] = []
        let items: [Item] = try await ResourcePagination.collect { cursor in
            cursors.append(cursor)
            return cursor == nil
                ? ResourcePage(data: [Item(id: "a"), Item(id: "b")], hasMore: true, lastId: "b")
                : ResourcePage(data: [Item(id: "b"), Item(id: "c")], hasMore: false, lastId: "c")
        }
        XCTAssertEqual(items.map(\.id), ["a", "b", "c"])
        XCTAssertEqual(cursors, [nil, "b"])
    }

    func testPaginationRejectsRepeatingCursorInsteadOfReturningPartialResults() async {
        do {
            let _: [Item] = try await ResourcePagination.collect { _ in
                ResourcePage(data: [Item(id: "a")], hasMore: true, lastId: "a")
            }
            XCTFail("Expected cursor failure")
        } catch { XCTAssertTrue(error.localizedDescription.contains("cursor")) }
    }

    func testIndexingWaitsForCompletedStatus() async throws {
        var polls = 0
        let result = try await VectorStoreIndexing.waitUntilReady(initial: file("in_progress"), pollInterval: 0) { _ in
            polls += 1
            return self.file(polls == 1 ? "in_progress" : "completed")
        }
        XCTAssertEqual(result.status, "completed")
        XCTAssertEqual(polls, 2)
    }

    func testIndexingReportsServerFailure() async {
        do {
            _ = try await VectorStoreIndexing.waitUntilReady(initial: file("failed")) { _ in
                XCTFail("Must not poll terminal failure")
                return self.file("completed")
            }
            XCTFail("Expected indexing failure")
        } catch { XCTAssertTrue(error.localizedDescription.contains("failed")) }
    }

    func testIndexingTimeoutNeverBecomesSuccess() async {
        do {
            _ = try await VectorStoreIndexing.waitUntilReady(initial: file("in_progress"), timeout: 0) { _ in
                XCTFail("Must not poll past deadline")
                return self.file("completed")
            }
            XCTFail("Expected pending indexing")
        } catch { XCTAssertTrue(error.localizedDescription.contains("still running")) }
    }

    func testTrainingRequiresTenValidExamples() throws {
        let line = "{\"messages\":[{\"role\":\"user\",\"content\":\"Question\"},{\"role\":\"assistant\",\"content\":\"Answer\"}]}\n"
        XCTAssertThrowsError(try FineTuningDataset.validate(Data(line.utf8)))
        XCTAssertEqual(try FineTuningDataset.validate(Data(String(repeating: line, count: 10).utf8)).exampleCount, 10)
        XCTAssertThrowsError(try FineTuningDataset.validate(Data(String(repeating: "{}\n", count: 10).utf8)))
    }

    func testNotionCompactionKeepsWholeServerPageAndCursor() {
        let items = (0..<30).map { ["object": "page", "id": "page-\($0)"] }
        let result = NotionService.shared.compactSearchResult(["results": items, "has_more": true, "next_cursor": "next"], maxResults: 12)
        XCTAssertEqual((result["results"] as? [[String: Any]])?.count, 30)
        XCTAssertEqual(result["next_cursor"] as? String, "next")
        XCTAssertEqual(result["has_more"] as? Bool, true)
    }

    func testBatchDownloadPreservesCompleteErrorFile() async throws {
        _ = KeychainService.shared.save(value: "test-key", forKey: "openAIKey")
        defer { _ = KeychainService.shared.delete(forKey: "openAIKey") }
        let bytes = Data(String(repeating: "{\"custom_id\":\"request\",\"error\":{\"code\":\"test\"}}\n", count: 10_000).utf8)
        let service = BatchService { request in
            XCTAssertEqual(request.url?.path, "/v1/files/file_errors/content")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try bytes.write(to: url)
            return (url, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        let url = try await service.downloadBatchResult(fileId: "file_errors", isErrorFile: true)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        XCTAssertEqual(url.lastPathComponent, "batch-errors.jsonl")
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testDeletingActiveStreamingChatDoesNotRestoreItOnDisk() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = ChatViewModel(storageService: ConversationStorageService(storageURL: directory), startBackgroundWork: false)
        let message = ChatMessage(role: .assistant, text: "Partial")
        model.messages = [message]
        let conversation = try XCTUnwrap(model.activeConversation)
        model.deltaBuffers[message.id] = " tail"
        model.scheduleDeltaFlush(for: message.id, messageIndex: 0, immediate: false)
        model.isStreaming = true
        model.streamingMessageId = message.id
        model.deleteConversation(conversation)
        await model.flushConversationStorage()
        try await Task.sleep(for: .milliseconds(200))
        let saved = try ConversationStorageService(storageURL: directory).loadConversations()
        XCTAssertFalse(saved.contains { $0.id == conversation.id })
        XCTAssertFalse(model.conversations.contains { $0.id == conversation.id })
    }

    private struct Item: Decodable, Identifiable { let id: String }
    private func file(_ status: String) -> VectorStoreFile {
        VectorStoreFile(id: "file_1", object: "vector_store.file", usageBytes: 0, createdAt: 0,
                        vectorStoreId: "vs_1", status: status, lastError: nil, chunkingStrategy: nil, attributes: nil)
    }
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    private func makeImage(_ color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}

@MainActor
final class MCPAuthorizationTests: XCTestCase {
    private func reply(_ json: [String: Any], status: Int = 200, challenge: String? = nil) throws -> MCPAuthorizationTransport.Reply {
        .init(status: status, data: try JSONSerialization.data(withJSONObject: json), authenticate: challenge)
    }
    private var metadata: MCPOAuthMetadata {
        .init(issuer: "https://auth.example.com", authorizationEndpoint: "https://auth.example.com/authorize",
              tokenEndpoint: "https://auth.example.com/token", registrationEndpoint: "https://auth.example.com/register",
              revocationEndpoint: nil, resource: "https://mcp.example.com/mcp", scopes: ["read"], authMethod: "none")
    }
    private var client: MCPOAuthClient { .init(id: "test-client", secret: nil, authMethod: "none") }
    private func token(expires: Date = .distantPast) -> MCPOAuthCredential {
        .init(metadata: metadata, client: client, accessToken: "old-test-token", refreshToken: "refresh-test-token", expiresAt: expires, scope: "read")
    }
    private struct Record: Codable { let connection: MCPConnection; let oauth: MCPOAuthCredential? }
    private struct Archive: Codable { var version = 1; let records: [Record] }
    private func saved(_ connection: MCPConnection, oauth: MCPOAuthCredential) throws -> Data {
        try JSONEncoder().encode(Archive(records: [.init(connection: connection, oauth: oauth)]))
    }
    private func form(_ data: Data?) -> [String: String] {
        let components = URLComponents(string: "https://example.com/?" + String(decoding: data ?? Data(), as: UTF8.self))!
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }

    func testPKCEKnownVectorAndSecureRandomness() throws {
        XCTAssertEqual(MCPOAuthSecurity.challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        let first = try MCPOAuthSecurity.random(), second = try MCPOAuthSecurity.random()
        XCTAssertEqual(first.count, 43); XCTAssertNotEqual(first, second)
        XCTAssertNotNil(first.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression))
    }

    func testOAuthCallbackRejectsMismatchedOrAmbiguousResponses() throws {
        let base = MCPOAuthSecurity.redirectURI
        XCTAssertEqual(try MCPOAuthSecurity.callbackCode(URL(string: base + "?state=expected&code=okay")!, state: "expected", issuer: metadata.issuer), "okay")
        for suffix in ["?state=wrong&code=x", "?state=expected&state=expected&code=x", "?state=expected&code=x&code=y", "?state=expected&code=x&iss=https://evil.example", "?state=expected&code=x#fragment", "?state=expected"] {
            XCTAssertThrowsError(try MCPOAuthSecurity.callbackCode(URL(string: base + suffix)!, state: "expected", issuer: metadata.issuer))
        }
        for url in ["other://mcp/oauth/callback?state=expected&code=x", "openresponses://evil/oauth/callback?state=expected&code=x", "openresponses://mcp/other?state=expected&code=x"] {
            XCTAssertThrowsError(try MCPOAuthSecurity.callbackCode(URL(string: url)!, state: "expected", issuer: metadata.issuer))
        }
    }

    func testOAuthEndpointAndResourceBoundaries() throws {
        for address in ["http://mcp.example.com", "https://name:secret@mcp.example.com", "https://localhost", "https://printer.local", "https://127.0.0.1", "https://[::1]", "https://intranet", "https://example.com:8443", "https://example.com/#secret"] {
            XCTAssertThrowsError(try MCPOAuthSecurity.publicHTTPS(address), address)
        }
        XCTAssertTrue(MCPOAuthSecurity.resourceMatches(URL(string: "https://mcp.example.com/")!, server: URL(string: "https://mcp.example.com")!))
        XCTAssertTrue(MCPOAuthSecurity.resourceMatches(URL(string: "https://mcp.example.com/mcp")!, server: URL(string: "https://mcp.example.com/mcp/readonly")!))
        XCTAssertFalse(MCPOAuthSecurity.resourceMatches(URL(string: "https://mcp.example.com/mcp")!, server: URL(string: "https://mcp.example.com/mcp-evil")!))
        XCTAssertFalse(MCPOAuthSecurity.resourceMatches(URL(string: "https://evil.example/mcp")!, server: URL(string: "https://mcp.example.com/mcp")!))
    }

    func testDiscoveryUsesResourceMetadataAndPathIssuer() async throws {
        var requests: [URLRequest] = []
        let auth = MCPAuthorizationClient { request in
            requests.append(request)
            switch request.url!.absoluteString {
            case "https://mcp.example.com/.well-known/oauth-protected-resource/mcp":
                return try self.reply(["resource": "https://mcp.example.com/mcp", "authorization_servers": ["https://auth.example.com/tenant"], "scopes_supported": ["read"]])
            case "https://auth.example.com/.well-known/oauth-authorization-server/tenant":
                return try self.reply(["issuer": "https://auth.example.com/tenant", "authorization_endpoint": "https://auth.example.com/authorize", "token_endpoint": "https://auth.example.com/token", "registration_endpoint": "https://auth.example.com/register", "code_challenge_methods_supported": ["S256"], "token_endpoint_auth_methods_supported": ["none"], "scopes_supported": ["offline_access"]])
            default: XCTFail("Unexpected endpoint"); return try self.reply([:], status: 404)
            }
        }
        let result = try await auth.discover(serverURL: "https://mcp.example.com/mcp")
        XCTAssertEqual(result.scopes, ["offline_access", "read"])
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == nil && $0.httpBody == nil })
    }

    func testDiscoveryRejectsIssuerMismatchAndMissingPKCE() async throws {
        for badIssuer in [false, true] {
            let auth = MCPAuthorizationClient { request in
                if request.url!.host == "mcp.example.com" {
                    return try self.reply(["resource": "https://mcp.example.com/mcp", "authorization_servers": ["https://auth.example.com"]])
                }
                return try self.reply(["issuer": badIssuer ? "https://evil.example.com" : "https://auth.example.com", "authorization_endpoint": "https://auth.example.com/authorize", "token_endpoint": "https://auth.example.com/token", "code_challenge_methods_supported": badIssuer ? ["S256"] : ["plain"]])
            }
            do { _ = try await auth.discover(serverURL: "https://mcp.example.com/mcp"); XCTFail("Unsafe metadata accepted") }
            catch { XCTAssertEqual(error as? MCPAuthorizationError, .invalidMetadata) }
        }
    }

    func testLegacySameOriginAuthorizationMetadataWorks() async throws {
        let auth = MCPAuthorizationClient { request in
            if request.url!.path == "/.well-known/oauth-authorization-server" {
                return try self.reply(["issuer": "https://mcp.example.com", "authorization_endpoint": "https://mcp.example.com/authorize", "token_endpoint": "https://mcp.example.com/token", "code_challenge_methods_supported": ["S256"], "token_endpoint_auth_methods_supported": ["none"]])
            }
            return try self.reply([:], status: request.url!.path == "/mcp" ? 401 : 404)
        }
        let result = try await auth.discover(serverURL: "https://mcp.example.com/mcp")
        XCTAssertEqual(result.issuer, "https://mcp.example.com")
        XCTAssertNil(result.registrationEndpoint)
        do { _ = try await auth.register(metadata: result); XCTFail("Registration should be required") }
        catch { XCTAssertEqual(error as? MCPAuthorizationError, .providerRegistrationRequired) }
    }

    func testAuthorizationRequestAndTokenExchangeUsePKCEAndResource() async throws {
        var exchanged: URLRequest?
        let auth = MCPAuthorizationClient { request in exchanged = request; return try self.reply(["access_token": "test-only", "token_type": "Bearer", "expires_in": 3600, "refresh_token": "test-refresh"]) }
        let url = try auth.authorizationURL(metadata: metadata, client: client, state: "test-state", verifier: "test-verifier")
        let params = Dictionary(uniqueKeysWithValues: URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(params["redirect_uri"], MCPOAuthSecurity.redirectURI)
        XCTAssertEqual(params["code_challenge_method"], "S256")
        XCTAssertEqual(params["resource"], metadata.resource)
        XCTAssertNil(params["code_verifier"])
        let result = try await auth.exchange(code: "test-code", verifier: "test-verifier", metadata: metadata, client: client)
        XCTAssertEqual(result.refreshToken, "test-refresh")
        XCTAssertEqual(form(exchanged?.httpBody)["code_verifier"], "test-verifier")
        XCTAssertEqual(form(exchanged?.httpBody)["resource"], metadata.resource)
        XCTAssertEqual(exchanged?.httpMethod, "POST")
        XCTAssertEqual(exchanged?.url?.query, nil)
    }

    func testDynamicRegistrationValidatesCallbackAndAuthMethod() async throws {
        for valid in [true, false] {
            let auth = MCPAuthorizationClient { request in
                let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
                XCTAssertEqual(body["application_type"] as? String, "native")
                XCTAssertEqual(body["redirect_uris"] as? [String], [MCPOAuthSecurity.redirectURI])
                return try self.reply(["client_id": "test-client", "redirect_uris": [valid ? MCPOAuthSecurity.redirectURI : "https://evil.example.com"], "token_endpoint_auth_method": "none"], status: 201)
            }
            do { _ = try await auth.register(metadata: metadata); XCTAssertTrue(valid) }
            catch { XCTAssertFalse(valid); XCTAssertEqual(error as? MCPAuthorizationError, .invalidMetadata) }
        }
    }

    func testRefreshRotationAndOmittedRefreshToken() async throws {
        for rotated in [true, false] {
            let auth = MCPAuthorizationClient { request in
                XCTAssertEqual(self.form(request.httpBody)["grant_type"], "refresh_token")
                XCTAssertEqual(self.form(request.httpBody)["refresh_token"], "refresh-test-token")
                var response: [String: Any] = ["access_token": "fresh-test-token", "token_type": "Bearer", "expires_in": 3600]
                if rotated { response["refresh_token"] = "rotated-test-token" }
                return try self.reply(response)
            }
            let result = try await auth.refresh(token())
            XCTAssertEqual(result.refreshToken, rotated ? "rotated-test-token" : "refresh-test-token")
            XCTAssertFalse(result.needsRefresh())
        }
    }

    func testProviderErrorsNeverEchoSecretResponse() async throws {
        let auth = MCPAuthorizationClient { _ in try self.reply(["error": "invalid_grant", "error_description": "secret-test-token"], status: 400) }
        do { _ = try await auth.refresh(token()); XCTFail("Refresh should fail") }
        catch { XCTAssertEqual(error as? MCPAuthorizationError, .expired); XCTAssertFalse(error.localizedDescription.contains("secret-test-token")) }
    }

    func testAccountVaultPreservesLastSuccessfulWriteAndCorruptData() throws {
        var data: Data?
        var fail = false
        let store = MCPConnectionStore(read: { data }, write: { if fail { throw MCPAuthorizationError.secureStorage }; data = $0 })
        let first = try store.addPublic(providerID: "test", name: "First", serverURL: "https://mcp.example.com/mcp")
        let saved = data; fail = true
        XCTAssertThrowsError(try store.disconnect(id: first.id))
        XCTAssertEqual(data, saved); XCTAssertEqual(store.connections.count, 1)
        var wrote = false
        let corrupt = MCPConnectionStore(read: { Data("invalid".utf8) }, write: { _ in wrote = true })
        XCTAssertNotNil(corrupt.storageError)
        XCTAssertThrowsError(try corrupt.addPublic(providerID: "test", name: "Test", serverURL: "https://mcp.example.com"))
        XCTAssertFalse(wrote)
    }

    func testMultipleConnectionsProduceSeparateToolsAndIsolatedCredentials() throws {
        let store = MCPConnectionStore(read: { nil }, write: { _ in })
        let first = try store.addAPIKey(name: "First", serverURL: "https://one.example.com/mcp", header: "Authorization", token: "first-test-key")
        let second = try store.addAPIKey(name: "Second", serverURL: "https://two.example.com/mcp", header: "Authorization", token: "second-test-key")
        var prompt = Prompt.defaultPrompt(); prompt.enableMCPTool = true; prompt.currentOptions.mcpConnectionIDs = [first.id, second.id]
        let tools = try JSONSerialization.jsonObject(with: JSONEncoder().encode(store.tools(prompt: prompt))) as! [[String: Any]]
        XCTAssertEqual(tools.count, 2)
        XCTAssertNotEqual(tools[0]["server_label"] as? String, tools[1]["server_label"] as? String)
        XCTAssertEqual(tools[0]["authorization"] as? String, "first-test-key")
        XCTAssertEqual(tools[1]["authorization"] as? String, "second-test-key")
        XCTAssertTrue(tools.allSatisfy { $0["require_approval"] as? String == "always" })
        try store.disconnect(id: first.id)
        XCTAssertThrowsError(try store.tools(prompt: prompt))
        XCTAssertEqual(store.connections.map(\.id), [second.id])
    }

    func testRefreshIsCoalescedAndPersistsRotation() async throws {
        let connection = MCPConnection(id: UUID(), providerID: "test", name: "Test", serverURL: "https://mcp.example.com/mcp", authentication: .oauth)
        var data = try saved(connection, oauth: token())
        var count = 0
        let auth = MCPAuthorizationClient { _ in count += 1; try await Task.sleep(for: .milliseconds(20)); return try self.reply(["access_token": "fresh-test-token", "refresh_token": "rotated-test-token", "expires_in": 3600, "token_type": "Bearer"]) }
        let store = MCPConnectionStore(read: { data }, write: { data = $0 }, oauthClient: auth)
        async let first: Void = store.prepare(id: connection.id)
        async let second: Void = store.prepare(id: connection.id)
        _ = try await (first, second)
        XCTAssertEqual(count, 1)
        let reopened = MCPConnectionStore(read: { data }, write: { _ in }, oauthClient: auth)
        XCTAssertEqual(try reopened.configuration(id: connection.id).tool["authorization"] as? String, "fresh-test-token")
        try await reopened.prepare(id: connection.id); XCTAssertEqual(count, 1)
    }

    func testDisconnectDuringRefreshCannotResurrectAccount() async throws {
        let connection = MCPConnection(id: UUID(), providerID: "test", name: "Test", serverURL: "https://mcp.example.com/mcp", authentication: .oauth)
        let data = try saved(connection, oauth: token())
        var resume: CheckedContinuation<Void, Never>?
        let auth = MCPAuthorizationClient { _ in await withCheckedContinuation { resume = $0 }; return try self.reply(["access_token": "fresh-test-token", "expires_in": 3600, "token_type": "Bearer"]) }
        let store = MCPConnectionStore(read: { data }, write: { _ in }, oauthClient: auth)
        let task = Task { try await store.prepare(id: connection.id) }
        while resume == nil { await Task.yield() }
        try store.disconnect(id: connection.id)
        resume?.resume()
        do { try await task.value; XCTFail("Disconnected refresh should not commit") } catch {}
        XCTAssertTrue(store.connections.isEmpty)
    }

    func testManagedRefreshRejectsEndpointSubstitutionAndDeletedAccount() async throws {
        let store = MCPConnectionStore(read: { nil }, write: { _ in })
        let connection = try store.addAPIKey(name: "Test", serverURL: "https://mcp.example.com/mcp", header: "Authorization", token: "test-key")
        var tool = try store.configuration(id: connection.id).tool
        tool["server_url"] = "https://evil.example.com/mcp"
        do { _ = try await store.refreshCredentials(in: ["tools": [tool]]); XCTFail("Credentials must not be attached to another endpoint") }
        catch { XCTAssertEqual(error as? MCPAuthorizationError, .unsafeURL) }
        tool["server_url"] = connection.serverURL
        try store.disconnect(id: connection.id)
        do { _ = try await store.refreshCredentials(in: ["tools": [tool]]); XCTFail("Deleted account must not reuse stale token") }
        catch { XCTAssertEqual(error as? MCPAuthorizationError, .expired) }
    }

    func testRegistryFiltersUnsupportedInactiveAndCredentialURLs() throws {
        func entry(_ name: String, url: String, type: String = "streamable-http", status: String = "active") -> [String: Any] {
            ["server": ["name": name, "remotes": [["url": url, "type": type]]], "_meta": ["io.modelcontextprotocol.registry/official": ["status": status, "isLatest": true]]]
        }
        let data = try JSONSerialization.data(withJSONObject: ["servers": [
            entry("publisher/good", url: "https://good.example.com/mcp"),
            entry("publisher/duplicate", url: "https://good.example.com/mcp"),
            entry("publisher/local", url: "http://localhost:8080"),
            entry("publisher/secret", url: "https://example.com/mcp?token=secret"),
            entry("publisher/template", url: "https://example.com/{key}"),
            entry("publisher/inactive", url: "https://inactive.example.com", status: "deprecated"),
            entry("publisher/stdio", url: "https://example.com", type: "stdio")
        ], "metadata": ["nextCursor": "test-cursor"]])
        let page = try MCPRegistryService.parse(data)
        XCTAssertEqual(page.providers.map(\.registryName), ["publisher/good"])
        XCTAssertEqual(page.nextCursor, "test-cursor")
        XCTAssertEqual(page.providers.first?.signIn, .automatic)
    }
}

extension MCPAuthorizationTests {
    func testCompleteConnectionCommitsOnlyAfterMatchingBrowserCallback() async throws {
        var data: Data?
        var requests: [String] = []
        let auth = MCPAuthorizationClient { request in
            requests.append(request.url!.path)
            switch request.url!.path {
            case "/.well-known/oauth-protected-resource/mcp":
                return try self.reply(["resource": "https://mcp.example.com/mcp", "authorization_servers": ["https://auth.example.com"]])
            case "/.well-known/oauth-authorization-server":
                return try self.reply(["issuer": "https://auth.example.com", "authorization_endpoint": self.metadata.authorizationEndpoint, "token_endpoint": self.metadata.tokenEndpoint, "registration_endpoint": self.metadata.registrationEndpoint!, "code_challenge_methods_supported": ["S256"], "token_endpoint_auth_methods_supported": ["none"]])
            case "/register":
                return try self.reply(["client_id": "test-client", "redirect_uris": [MCPOAuthSecurity.redirectURI]], status: 201)
            case "/token":
                return try self.reply(["access_token": "test-token", "refresh_token": "test-refresh", "token_type": "Bearer", "expires_in": 3600])
            default: XCTFail("Unexpected endpoint"); return try self.reply([:], status: 404)
            }
        }
        let store = MCPConnectionStore(read: { data }, write: { data = $0 }, oauthClient: auth)
        let connected = try await store.connect(providerID: "test", name: "Test", serverURL: "https://mcp.example.com/mcp", authenticate: { url in
            XCTAssertNil(data); XCTAssertTrue(store.connections.isEmpty)
            let state = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!.first { $0.name == "state" }!.value!
            return URL(string: MCPOAuthSecurity.redirectURI + "?state=" + state + "&code=test-code")!
        }, progress: { _ in })
        XCTAssertEqual(connected.authentication, .oauth)
        XCTAssertEqual(try store.configuration(id: connected.id).tool["authorization"] as? String, "test-token")
        let before = data, tokenRequests = requests.filter { $0 == "/token" }.count
        do {
            _ = try await store.connect(providerID: "test", name: "Test", serverURL: connected.serverURL, reconnecting: connected.id,
                authenticate: { _ in URL(string: MCPOAuthSecurity.redirectURI + "?state=wrong&code=bad")! }, progress: { _ in })
            XCTFail("Wrong state accepted")
        } catch { XCTAssertEqual(error as? MCPAuthorizationError, .invalidCallback) }
        XCTAssertEqual(data, before)
        XCTAssertEqual(requests.filter { $0 == "/token" }.count, tokenRequests)
    }

    func testLegacyConfigurationMigrationIsIdempotentAndKeepsPermissions() throws {
        let store = MCPConnectionStore(read: { nil }, write: { _ in })
        var prompt = Prompt.defaultPrompt()
        prompt.mcpServerLabel = "test_" + UUID().uuidString
        prompt.mcpServerURL = "https://mcp.example.com/mcp"
        prompt.mcpIsConnector = false
        prompt.mcpHeaders = #"{"X-Custom-Key":"test-only-key"}"#
        prompt.mcpRequireApproval = "always"
        prompt.mcpAllowedTools = "search,read"
        let id = try XCTUnwrap(store.importLegacy(prompt: prompt))
        XCTAssertEqual(try store.importLegacy(prompt: prompt), id)
        XCTAssertEqual(store.connections.count, 1)
        XCTAssertEqual(store.connections[0].allowedTools, ["search", "read"])
        XCTAssertEqual(try store.configuration(id: id).tool["headers"] as? [String: String], ["x-custom-key": "test-only-key"])
        XCTAssertFalse(prompt.mcpHeaders.isEmpty)
        prompt.currentOptions.mcpConnectionIDs = [id]
        let roundTrip = try JSONDecoder().decode(Prompt.self, from: JSONEncoder().encode(prompt))
        XCTAssertEqual(roundTrip.currentOptions.mcpConnectionIDs, [id])
        XCTAssertNil(try store.importLegacy(prompt: roundTrip))
    }

    func testInvalidRefreshMarksAccountForSignInWithoutDroppingIt() async throws {
        let connection = MCPConnection(id: UUID(), providerID: "test", name: "Test", serverURL: "https://mcp.example.com/mcp", authentication: .oauth)
        let data = try saved(connection, oauth: token())
        let auth = MCPAuthorizationClient { _ in try self.reply(["error": "invalid_grant"], status: 400) }
        let store = MCPConnectionStore(read: { data }, write: { _ in }, oauthClient: auth)
        do { try await store.prepare(id: connection.id); XCTFail("Expired grant accepted") }
        catch { XCTAssertEqual(error as? MCPAuthorizationError, .expired) }
        XCTAssertEqual(store.connections.count, 1)
        XCTAssertTrue(store.connections[0].needsSignIn)
        XCTAssertThrowsError(try store.configuration(id: connection.id))
    }
}

extension MCPAuthorizationTests {
    func testCatalogInspectionAndRenamePreserveChatPolicy() throws {
        var data: Data?
        let store = MCPConnectionStore(read: { data }, write: { data = $0 })
        let connection = try store.addPublic(providerID: "test", name: "Test", serverURL: "https://mcp.example.com/mcp")
        try store.updatePolicy(id: connection.id, approval: "always", allowedTools: ["read"])
        try store.rename(id: connection.id, name: "Work workspace")
        XCTAssertNil(try store.configuration(id: connection.id, includeAllTools: true).tool["allowed_tools"])
        XCTAssertEqual(try store.configuration(id: connection.id).tool["allowed_tools"] as? [String], ["read"])
        XCTAssertEqual(store.displayName(for: connection.serverLabel), "Work workspace")
        let restored = MCPConnectionStore(read: { data }, write: { _ in })
        XCTAssertEqual(restored.connections.first?.allowedTools, ["read"])
        XCTAssertEqual(restored.connections.first?.name, "Work workspace")
    }
}
