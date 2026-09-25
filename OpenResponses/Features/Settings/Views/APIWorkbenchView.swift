import SwiftUI

struct APIWorkbenchView: View {
    @AppStorage("exploreModeEnabled") private var exploreModeEnabled = false
    @AppStorage(AppFeatureFlags.aiDataSharingConsentVersionKey) private var consentVersion = 0
    @StateObject private var session = APIWorkbenchSession()
    @StateObject private var draftStore = APIWorkbenchDraftStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var restoredDraft = false
    @State private var replacement: APIWorkbenchDraft?
    @State private var showingReplacement = false
    @State private var showingDeleteConfirmation = false
    @State private var transport = APIWorkbenchSession.Transport.sse
    @State private var template = Template.response
    @State private var endpoint = Endpoint.responses
    @State private var resourceID = ""
    @State private var requestText = ResponsesAPIClient.pretty(Template.response.body)
    @State private var steeringText = ""
    @State private var utilityStatus = ""
    @State private var counting = false
    @State private var toolOutput = ""
    @State private var toolResultDrafts: [String: String] = [:]
    @State private var selectedCallID = ""
    @State private var followUp = ""
    @State private var showingConsent = false
    @State private var pendingAction = NetworkAction.run

    private enum NetworkAction { case run, count }

    /// Every current JSON endpoint in the app's scope, checked against OpenAI's API reference on September 24, 2026.
    /// Raw values are persisted in drafts; keep existing names stable. Deprecated APIs (Assistants, reusable prompts,
    /// Evals, fine-tuning, image variations, Videos) are intentionally absent.
    enum Endpoint: String, CaseIterable {
        case responses = "Create response", count = "Count input tokens", compact = "Compact input window"
        case retrieve = "Retrieve response", cancel = "Cancel background response", inputItems = "Response input items"
        case deleteResponse = "Delete stored response"
        case createConversation = "Create conversation", getConversation = "Retrieve conversation", conversationItems = "Conversation items"
        case updateConversation = "Update conversation metadata", addConversationItems = "Add conversation items"
        case deleteConversation = "Delete conversation"
        case listModels = "List models", retrieveModel = "Retrieve model"
        case moderation = "Create moderation", embeddings = "Create embeddings"
        case listFiles = "List files", retrieveFile = "Retrieve file", deleteFile = "Delete file"
        case listVectorStores = "List vector stores", createVectorStore = "Create vector store", retrieveVectorStore = "Retrieve vector store"
        case searchVectorStore = "Search vector store", vectorStoreFiles = "Vector store files", deleteVectorStore = "Delete vector store"
        case listContainers = "List containers", createContainer = "Create container", retrieveContainer = "Retrieve container"
        case containerFiles = "Container files", deleteContainer = "Delete container"
        case listBatches = "List batches", retrieveBatch = "Retrieve batch", cancelBatch = "Cancel batch"
        case realtimeClientSecret = "Create Realtime client secret", voiceConsents = "List voice consents"

        var method: String {
            switch self {
            case .retrieve, .inputItems, .getConversation, .conversationItems, .listModels, .retrieveModel, .listFiles, .retrieveFile,
                 .listVectorStores, .retrieveVectorStore, .vectorStoreFiles, .listContainers, .retrieveContainer, .containerFiles,
                 .listBatches, .retrieveBatch, .voiceConsents:
                return "GET"
            case .deleteResponse, .deleteConversation, .deleteFile, .deleteVectorStore, .deleteContainer:
                return "DELETE"
            default:
                return "POST"
            }
        }

        var needsID: Bool {
            switch self {
            case .retrieve, .cancel, .inputItems, .deleteResponse, .getConversation, .conversationItems, .updateConversation,
                 .addConversationItems, .deleteConversation, .retrieveModel, .retrieveFile, .deleteFile, .retrieveVectorStore,
                 .searchVectorStore, .vectorStoreFiles, .deleteVectorStore, .retrieveContainer, .containerFiles, .deleteContainer,
                 .retrieveBatch, .cancelBatch:
                return true
            default:
                return false
            }
        }

        var idPlaceholder: String {
            switch self {
            case .retrieveModel: return "Model ID"
            case .retrieveFile, .deleteFile: return "File ID"
            case .retrieveVectorStore, .searchVectorStore, .vectorStoreFiles, .deleteVectorStore: return "Vector store ID"
            case .retrieveContainer, .containerFiles, .deleteContainer: return "Container ID"
            case .retrieveBatch, .cancelBatch: return "Batch ID"
            case .getConversation, .conversationItems, .updateConversation, .addConversationItems, .deleteConversation: return "Conversation ID"
            default: return "Response ID"
            }
        }

        func path(id: String) throws -> String {
            if needsID, id.range(of: "^[A-Za-z0-9_.:-]+$", options: .regularExpression) == nil {
                throw OpenAIServiceError.invalidRequest("Enter the resource ID returned by OpenAI.")
            }
            switch self {
            case .responses: return "/responses"
            case .count: return "/responses/input_tokens"
            case .compact: return "/responses/compact"
            case .retrieve, .deleteResponse: return "/responses/\(id)"
            case .cancel: return "/responses/\(id)/cancel"
            case .inputItems: return "/responses/\(id)/input_items?limit=100&order=asc"
            case .createConversation: return "/conversations"
            case .getConversation, .updateConversation, .deleteConversation: return "/conversations/\(id)"
            case .conversationItems: return "/conversations/\(id)/items?limit=100&order=asc"
            case .addConversationItems: return "/conversations/\(id)/items"
            case .listModels: return "/models"
            case .retrieveModel: return "/models/\(id)"
            case .moderation: return "/moderations"
            case .embeddings: return "/embeddings"
            case .listFiles: return "/files?limit=100"
            case .retrieveFile, .deleteFile: return "/files/\(id)"
            case .listVectorStores: return "/vector_stores?limit=100"
            case .createVectorStore: return "/vector_stores"
            case .retrieveVectorStore, .deleteVectorStore: return "/vector_stores/\(id)"
            case .searchVectorStore: return "/vector_stores/\(id)/search"
            case .vectorStoreFiles: return "/vector_stores/\(id)/files?limit=100"
            case .listContainers: return "/containers?limit=100"
            case .createContainer: return "/containers"
            case .retrieveContainer, .deleteContainer: return "/containers/\(id)"
            case .containerFiles: return "/containers/\(id)/files?limit=100"
            case .listBatches: return "/batches?limit=100"
            case .retrieveBatch: return "/batches/\(id)"
            case .cancelBatch: return "/batches/\(id)/cancel"
            case .realtimeClientSecret: return "/realtime/client_secrets"
            case .voiceConsents: return "/audio/voice_consents"
            }
        }

        /// Example request body for endpoints that do not derive their body from the current Responses request.
        var exampleBody: [String: Any]? {
            switch self {
            case .createConversation: return ["items": [] as [String], "metadata": ["source": "workbench"]]
            case .updateConversation: return ["metadata": ["topic": "workbench"]]
            case .addConversationItems: return ["items": [["type": "message", "role": "user", "content": "Hello from the Workbench."]]]
            case .moderation: return ["model": "omni-moderation-latest", "input": "Text to classify."]
            case .embeddings: return ["model": "text-embedding-3-small", "input": "Text to embed."]
            case .createVectorStore: return ["name": "Workbench store", "expires_after": ["anchor": "last_active_at", "days": 7]]
            case .searchVectorStore: return ["query": "What does this document say about pricing?", "max_num_results": 5, "rewrite_query": true]
            case .createContainer: return ["name": "Workbench container", "memory_limit": "1g", "expires_after": ["anchor": "last_active_at", "minutes": 20]]
            case .cancel, .cancelBatch: return [:]
            case .realtimeClientSecret: return ["expires_after": ["anchor": "created_at", "seconds": 600],
                                                "session": ["type": "realtime", "model": CurrentModelCatalog.realtimeModel]]
            default: return nil
            }
        }
    }

    enum Template: String, CaseIterable {
        case response = "Basic response", shell = "Hosted shell", toolSearch = "Tool search"
        case asyncTools = "Async function tool", programmatic = "Programmatic tool calling"
        case multiAgent = "Multi-agent beta", images = "Image generation", compaction = "Automatic compaction"
        case reasoningUpdate = "Reasoning update", custom = "Custom text tool", patch = "Apply patch"

        var body: [String: Any] {
            var body: [String: Any] = ["model": CurrentModelCatalog.defaultModel, "input": "Explain what this API capability does in two sentences.", "store": false, "max_output_tokens": 2048, "reasoning": ["effort": "low"]]
            var function: [String: Any] = ["type": "function", "name": "lookup_inventory", "description": "Look up inventory for a product. The client supplies the actual result.", "parameters": ["type": "object", "properties": ["sku": ["type": "string"]], "required": ["sku"], "additionalProperties": false], "strict": true]
            switch self {
            case .response: break
            case .shell:
                body["tools"] = [["type": "shell", "environment": ["type": "container_auto"]]]
                body["input"] = "Use the hosted shell to calculate the first ten Fibonacci numbers."
            case .toolSearch:
                function["defer_loading"] = true
                body["tools"] = [["type": "tool_search"], function]
                body["input"] = "Look up inventory for SKU demo-123."
            case .asyncTools:
                body["model"] = "gpt-6-astra"
                function["async"] = true
                body["tools"] = [function]
                body["input"] = "Start looking up inventory for demo-123. While the lookup runs, explain why inventory accuracy matters."
            case .programmatic:
                function["allowed_callers"] = ["direct", "programmatic"]
                body["tools"] = [["type": "programmatic_tool_calling"], function]
                body["input"] = "Use a program to look up demo-123 and demo-456, then compare their inventory."
            case .multiAgent:
                body["model"] = "gpt-5.6-sol"
                body["multi_agent"] = ["enabled": true, "max_concurrent_subagents": 2]
                body["input"] = "Use two subagents to compare the advantages of unit tests and integration tests, then synthesize their findings."
            case .images:
                body["tools"] = [["type": "image_generation", "model": CurrentModelCatalog.imageModel, "action": "generate", "size": "auto", "quality": "low", "partial_images": 1]]
                body["input"] = "Generate a small illustration of a paper boat on blue water."
            case .compaction:
                body["context_management"] = [["type": "compaction", "compact_threshold": 100_000]]
            case .reasoningUpdate:
                body["model"] = "gpt-6-astra"
                body["input"] = [["type": "configuration_update", "reasoning": ["effort": "high"]], ["role": "user", "content": "Explain one subtle tradeoff in database transaction isolation."]]
            case .custom:
                body["tools"] = [["type": "custom", "name": "run_query", "description": "Submit a SQL query for the client to execute and return results.", "format": ["type": "text"]]]
                body["input"] = "Use run_query to request SELECT 1."
            case .patch:
                body["tools"] = [["type": "apply_patch"]]
                body["input"] = "Propose an apply_patch call to create hello.txt containing Hello world. The client will review and apply it."
            }
            return body
        }
    }

    var body: some View {
        Form {
            Section("Request") {
                Picker("Example", selection: Binding(get: { template }, set: selectTemplate)) {
                    ForEach(Template.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.disabled(session.isRunning)
                Picker("Endpoint", selection: Binding(get: { endpoint }, set: selectEndpoint)) {
                    ForEach(Endpoint.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.disabled(session.isRunning)
                if endpoint.needsID { TextField(endpoint.idPlaceholder, text: $resourceID).textInputAutocapitalization(.never).autocorrectionDisabled() }
                if endpoint == .responses {
                    Picker("Transport", selection: $transport) {
                        ForEach(APIWorkbenchSession.Transport.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).disabled(session.isRunning)
                }
                if endpoint.method == "POST" {
                    JSONCodeEditor(text: $requestText, label: "Request JSON").font(.system(.caption, design: .monospaced)).frame(minHeight: 240).autocorrectionDisabled().textInputAutocapitalization(.never)
                        .disabled(session.isRunning)
                }
                HStack {
                    Button("Run request", systemImage: "play.fill", action: requestRun).disabled(session.isRunning)
                    Spacer()
                    Button("Stop connection", systemImage: "stop.fill") { session.stop() }.disabled(!session.isRunning)
                }
                .buttonStyle(.borderless)
                ShareLink("Export request draft", item: requestText)
                Text(draftStore.status).font(.caption).foregroundStyle(.secondary)
                Text("Uses your Keychain API key. Examples make real API requests and incur normal usage charges. Function, custom, and patch tools require an actual client result; hosted tools run on OpenAI.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if endpoint == .responses {
                Section("Inspect and continue") {
                    Button(counting ? "Counting…" : "Count input tokens") { countTokens() }.disabled(counting || session.isRunning)
                    if let responseID = session.responseID {
                        LabeledContent("Response", value: responseID).font(.caption).textSelection(.enabled)
                        TextField("Follow-up message", text: $followUp)
                        Button("Prepare next turn") { prepareContinuation() }.disabled(session.isRunning || followUp.isEmpty)
                    }
                    if transport == .webSocket, template != .multiAgent {
                        TextField("New instruction while the model works", text: $steeringText)
                        Button("Send steering instruction") { session.steer(steeringText); steeringText = "" }
                            .disabled(!session.isRunning || session.responseID == nil || steeringText.isEmpty)
                    }
                }
            }
            if !session.pendingCalls.isEmpty {
                Section("Client tool results") {
                    Text("Execute the requested tool in your own environment, then supply its real output. Preparing a result does not execute or approve the action.").font(.caption)
                    Picker("Tool call", selection: $selectedCallID) {
                        Text("Select a call").tag("")
                        ForEach(Array(session.pendingCalls.enumerated()), id: \.offset) { _, call in
                            Text(call["name"] as? String ?? call["type"] as? String ?? "Tool")
                                .tag(call["call_id"] as? String ?? call["id"] as? String ?? "")
                        }
                    }
                    TextEditor(text: $toolOutput).font(.system(.caption, design: .monospaced)).frame(minHeight: 100)
                    Button("Save this tool result") { saveToolResult() }.disabled(selectedCallID.isEmpty || toolOutput.isEmpty)
                    Text("\(toolResultDrafts.count) result(s) saved").font(.caption).foregroundStyle(.secondary)
                    Button("Prepare result batch") { prepareToolResults() }.disabled(session.isRunning || toolResultDrafts.isEmpty)
                    if session.canInjectToolResults, session.isRunning {
                        Button("Send saved results to waiting agents") { injectToolResults() }
                            .disabled(toolResultDrafts.isEmpty || session.injectionPending)
                    }
                    Text(ResponsesAPIClient.pretty(session.pendingCalls)).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }
            Section("Status") {
                Text(session.status).textSelection(.enabled)
                if !utilityStatus.isEmpty { Text(utilityStatus).font(.caption).textSelection(.enabled) }
            }
            if !session.result.isEmpty {
                Section("Complete response") {
                    ShareLink("Export response JSON", item: ResponsesAPIClient.pretty(session.result))
                }
            }
            Section("Response and events") {
                Text(session.transcript.isEmpty ? "Run a request to inspect its response and events." : session.transcript)
                    .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
        }
        .navigationTitle("API Workbench")
        .onAppear { restoreDraft() }
        .onChange(of: currentDraft) { _, draft in draftStore.schedule(draft) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { draftStore.schedule(currentDraft); draftStore.flush() }
        }
        .confirmationDialog("Replace the current request?", isPresented: $showingReplacement, titleVisibility: .visible) {
            Button("Replace request", role: .destructive) {
                if let replacement { applyDraft(replacement) }
                replacement = nil
            }
            Button("Keep current request", role: .cancel) { replacement = nil }
        } message: {
            Text("Changing the example or endpoint replaces the request JSON. Export your draft first if you want to keep a separate copy.")
        }
        .confirmationDialog("Delete this resource?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(endpoint.rawValue, role: .destructive) { run() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("OpenAI permanently deletes \(resourceID.isEmpty ? "the resource" : resourceID) from your API project. This cannot be undone.")
        }
        .onChange(of: selectedCallID) { _, id in toolOutput = toolResultDrafts[id] ?? "" }
        .onDisappear { draftStore.schedule(currentDraft); draftStore.flush(); session.stop() }
        .alert("Before You Send", isPresented: $showingConsent) {
            Button("Allow & Send") {
                consentVersion = AppFeatureFlags.aiDataSharingConsentVersion
                if pendingAction == .run { run() } else { countTokens() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("OpenAI will receive your request JSON, including its input and tool data. Hosted tools can run on OpenAI, and normal API usage charges apply. Your API key is stored in this device’s Keychain and sent to OpenAI to authenticate the request.")
        }
    }

    private var currentDraft: APIWorkbenchDraft {
        APIWorkbenchDraft(requestText: requestText, template: template.rawValue, endpoint: endpoint.rawValue,
                          transport: transport.rawValue, resourceID: resourceID)
    }

    private func restoreDraft() {
        guard !restoredDraft else { return }
        restoredDraft = true
        if let draft = draftStore.restored { applyDraft(draft) }
    }

    private func applyDraft(_ draft: APIWorkbenchDraft) {
        template = Template(rawValue: draft.template) ?? ["Astra response": .response, "GPT Image 2": .images][draft.template] ?? .response
        endpoint = Endpoint(rawValue: draft.endpoint) ?? .responses
        transport = APIWorkbenchSession.Transport(rawValue: draft.transport) ?? .sse
        resourceID = draft.resourceID
        requestText = draft.requestText
        utilityStatus = ""
    }

    private func proposeReplacement(_ draft: APIWorkbenchDraft) {
        if draft.requestText == requestText { applyDraft(draft) }
        else { replacement = draft; showingReplacement = true }
    }

    private func selectTemplate(_ value: Template) {
        guard value != template else { return }
        var draft = currentDraft
        draft.template = value.rawValue
        draft.endpoint = Endpoint.responses.rawValue
        draft.requestText = ResponsesAPIClient.pretty(value.body)
        proposeReplacement(draft)
    }

    private func selectEndpoint(_ value: Endpoint) {
        guard value != endpoint else { return }
        var draft = currentDraft
        draft.endpoint = value.rawValue
        do {
            switch value {
            case .count:
                draft.requestText = ResponsesAPIClient.pretty(ResponsesAPIClient.tokenCountBody(from: try parsedRequest()))
            case .compact:
                draft.requestText = ResponsesAPIClient.pretty(try parsedRequest().filter { ["model", "input", "instructions"].contains($0.key) })
            case .responses: draft.requestText = ResponsesAPIClient.pretty(template.body)
            default:
                if let example = value.exampleBody { draft.requestText = ResponsesAPIClient.pretty(example) }
            }
            proposeReplacement(draft)
        } catch { utilityStatus = error.localizedDescription }
    }

    private func parsedRequest() throws -> [String: Any] {
        let body = try ResponseConfigurationValidation.object(requestText, label: "Request")
        try ResponseConfigurationValidation.validate(body: body)
        return body
    }

    /// Deletions ask first; every other request runs immediately.
    private func requestRun() {
        if endpoint.method == "DELETE" { showingDeleteConfirmation = true } else { run() }
    }

    private func run() {
        do {
            utilityStatus = ""
            let body = ["GET", "DELETE"].contains(endpoint.method) ? [:] : try parsedRequest()
            let path = try endpoint.path(id: resourceID)
            guard authorizeNetwork(.run) else { return }
            toolResultDrafts = [:]
            selectedCallID = ""
            toolOutput = ""
            session.run(body: endpoint == .count ? ResponsesAPIClient.tokenCountBody(from: body) : body,
                        path: path, method: endpoint.method,
                        transport: endpoint == .responses ? transport : .http)
        } catch { utilityStatus = error.localizedDescription }
    }

    private func countTokens() {
        do {
            let body = try parsedRequest()
            guard authorizeNetwork(.count) else { return }
            counting = true
            Task {
                defer { counting = false }
                do { utilityStatus = "\(try await ResponsesAPIClient().countTokens(request: body).formatted()) input tokens" }
                catch { utilityStatus = error.localizedDescription }
            }
        } catch { utilityStatus = error.localizedDescription }
    }

    private func authorizeNetwork(_ action: NetworkAction) -> Bool {
        guard !exploreModeEnabled else {
            utilityStatus = "Demo Mode is offline. Turn it off in Settings → General to make live requests."
            return false
        }
        guard let key = KeychainService.shared.load(forKey: "openAIKey"), !key.isEmpty else {
            utilityStatus = OpenAIServiceError.missingAPIKey.localizedDescription
            return false
        }
        guard consentVersion >= AppFeatureFlags.aiDataSharingConsentVersion else {
            pendingAction = action
            showingConsent = true
            return false
        }
        return true
    }

    private func continuationBody(input: [[String: Any]]) throws -> [String: Any] {
        var body = try parsedRequest()
        body.removeValue(forKey: "conversation")
        if (transport == .webSocket && session.hasOpenSocket) || body["store"] as? Bool != false {
            body["previous_response_id"] = session.responseID
            body["input"] = input
        } else {
            let originalInput = session.lastRequestBody["input"] ?? body["input"]
            var history = ResponseTurnRunner.inputItems(originalInput)
            history += session.result["output"] as? [[String: Any]] ?? []
            body.removeValue(forKey: "previous_response_id")
            body["input"] = history + input
        }
        return body
    }

    private func prepareContinuation() {
        do {
            requestText = ResponsesAPIClient.pretty(try continuationBody(input: [["role": "user", "content": followUp]]))
            followUp = ""
        } catch { utilityStatus = error.localizedDescription }
    }

    private func saveToolResult() {
        guard let call = session.pendingCalls.first(where: { $0["call_id"] as? String == selectedCallID }),
              ["function_call", "custom_tool_call"].contains(call["type"] as? String ?? "") else {
            utilityStatus = "For patch results or MCP approvals, enter the documented output item in the request JSON after reviewing the action."
            return
        }
        toolResultDrafts[selectedCallID] = toolOutput
    }

    private func resultItems(requireAll: Bool) throws -> [[String: Any]] {
        let calls = session.pendingCalls.filter { ["function_call", "custom_tool_call"].contains($0["type"] as? String ?? "") }
        if requireAll, calls.contains(where: { ($0["async"] as? Bool != true) && toolResultDrafts[$0["call_id"] as? String ?? ""] == nil }) {
            throw OpenAIServiceError.invalidRequest("Save results for every synchronous function/custom call before preparing the continuation.")
        }
        return calls.compactMap { call in
            guard let id = call["call_id"] as? String, let output = toolResultDrafts[id] else { return nil }
            return ["type": call["type"] as? String == "function_call" ? "function_call_output" : "custom_tool_call_output", "call_id": id, "output": output]
        }
    }

    private func prepareToolResults() {
        do { requestText = ResponsesAPIClient.pretty(try continuationBody(input: resultItems(requireAll: true))) }
        catch { utilityStatus = error.localizedDescription }
    }

    private func injectToolResults() {
        do { session.injectToolResults(try resultItems(requireAll: false)) }
        catch { utilityStatus = error.localizedDescription }
    }
}
