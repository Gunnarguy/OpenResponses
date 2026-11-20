import Foundation

/// Where a request's system instructions go, and what the conversation history holds afterwards.
///
/// GPT-6.2 and later "append top-level `instructions` after `input`", so those tokens are billed "at the uncached
/// input-token rate on every request", and OpenAI's guidance is to "put them in a `developer` message as the first item
/// in `input`" (latest-model and prompt caching guides, read 2026-11-20). That developer message "remains in the
/// conversation history when you use `previous_response_id`", while top-level instructions "do not carry over". So a
/// chained turn must neither resend the developer message (it would pile up in the history) nor drop the instructions.
nonisolated enum InstructionsPlacement: Equatable, Sendable {
    /// Sent as top-level `instructions`, as for every model before GPT-6.2.
    case topLevel(String)
    /// Sent as a `developer` message, the first item of `input`, on a new chain.
    case developerMessage(String)
    /// Already in the chained history as a developer message; nothing is sent.
    case carried
    case none

    /// Prefix for instructions that changed after a chain began with a developer message: the old message stays in
    /// the history, so the model is told which one applies.
    static let updatedPrefix = "Updated instructions (these replace the earlier instructions in this conversation):\n\n"

    /// GPT-6.2 and later general-purpose models put top-level instructions after `input`.
    static func placesTopLevelAfterInput(_ model: String) -> Bool {
        let base = CurrentModelCatalog.baseID(model)
        guard CurrentModelCatalog.isModern(base), let version = CurrentModelCatalog.generation(base) else { return false }
        return (version.major, version.minor) >= (6, 2)
    }

    /// Chooses the placement. `carried` is what the history after `previousResponseId` already holds as a developer
    /// message (from `InstructionsLedger`), nil when that is unknown or nothing. `replacesInput` is true when the input
    /// is a replayed or compacted window, or a custom input, which a leading developer message would not fit.
    /// Returns the placement and what the history holds once this request is answered.
    static func choose(instructions: String, model: String, previousResponseId: String?, conversationId: String?,
                       replacesInput: Bool, carried: String?) -> (placement: InstructionsPlacement, historyHolds: String?) {
        let previous = previousResponseId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let conversation = conversationId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let carriedText = (carried?.isEmpty ?? true) ? nil : carried
        guard !instructions.isEmpty else { return (.none, previous.isEmpty ? nil : carriedText) }
        if !previous.isEmpty {
            if carriedText == instructions { return (.carried, carriedText) }
            if carriedText != nil { return (.topLevel(updatedPrefix + instructions), carriedText) }
            return (.topLevel(instructions), nil)
        }
        if !conversation.isEmpty || replacesInput || !placesTopLevelAfterInput(model) {
            return (.topLevel(instructions), nil)
        }
        return (.developerMessage(instructions), instructions)
    }
}

/// Remembers which system instructions each response's history holds as a developer message, so the next chained
/// request can tell whether to send them (`InstructionsPlacement.choose`). In memory only: after a relaunch a chain's
/// instructions go top-level again, which repeats them but never drops them.
nonisolated final class InstructionsLedger: @unchecked Sendable {
    static let shared = InstructionsLedger()

    private let lock = NSLock()
    /// What the history holds after the last request built on a parent response ("" for a new chain). An empty value
    /// means "no developer instructions".
    private var sentFrom: [String: String] = [:]
    /// What the history of a response holds, as linked by `link(parent:child:)`.
    private var carried: [String: String] = [:]
    private let limit = 500

    /// The instructions the history after `responseID` holds as a developer message, or nil.
    func carriedInstructions(after responseID: String?) -> String? {
        guard let responseID, !responseID.isEmpty else { return nil }
        lock.lock(); defer { lock.unlock() }
        let value = carried[responseID]
        return value?.isEmpty == false ? value : nil
    }

    /// Records what the history will hold after a request built on `parent` (nil for a new chain).
    func recordRequest(parent: String?, holds instructions: String?) {
        lock.lock(); defer { lock.unlock() }
        if sentFrom.count > limit { sentFrom.removeAll() }
        sentFrom[parent ?? ""] = instructions ?? ""
    }

    /// Links a response to the request it answered, called when a chat's last response ID moves from `parent` to
    /// `child`. A request the app did not build itself (a later tool round) inherits the parent's history.
    func link(parent: String?, child: String) {
        guard !child.isEmpty, child != parent else { return }
        lock.lock(); defer { lock.unlock() }
        if carried.count > limit { carried.removeAll() }
        let key = parent ?? ""
        if let sent = sentFrom[key] {
            carried[child] = sent
        } else if let parent, let inherited = carried[parent] {
            carried[child] = inherited
        }
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        sentFrom.removeAll()
        carried.removeAll()
    }
}
