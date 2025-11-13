import Foundation

/// Represents a single, ongoing conversation, including its messages, sync state, and metadata.
struct Conversation: Identifiable, Codable {
    /// Captures the current sync relationship between the local cache and the backend Conversations API.
    enum SyncState: String, Codable {
        case localOnly
        case syncing
        case synced
        case pendingUpdate
        case pendingDelete
        case failed
    }

    /// A unique identifier for the conversation (local UUID used for persistence and UI diffing).
    var id: UUID

    /// OpenAI Conversations API identifier (conv_…). Populated once the conversation is created on the backend.
    var remoteId: String?

    /// The title of the conversation, often derived from the first user message.
    var title: String

    /// The array of messages that make up the conversation.
    var messages: [ChatMessage]

    /// The ID of the last response from the OpenAI API. Maintains context for legacy `previous_response_id` flows.
    var lastResponseId: String?

    /// The timestamp when the conversation was last modified. Used for sorting conversations.
    var lastModified: Date

    /// Arbitrary metadata mirrored to the Conversations API.
    var metadata: [String: String]?

    /// Last time the conversation successfully synced with the backend.
    var lastSyncedAt: Date?

    /// Whether the conversation should be stored remotely (`store` flag in API requests).
    var shouldStoreRemotely: Bool

    /// Tracks the current sync status relative to the backend.
    var syncState: SyncState

    /// A static factory method to create a new, empty conversation.
    /// - Parameter storePreference: Whether the conversation should be synced to the backend when possible.
    /// - Returns: A `Conversation` instance with defaults reflecting the current timestamp.
    static func new(storePreference: Bool) -> Conversation {
        Conversation(
            id: UUID(),
            remoteId: nil,
            title: "New Chat",
            messages: [],
            lastResponseId: nil,
            lastModified: Date(),
            metadata: nil,
            lastSyncedAt: nil,
            shouldStoreRemotely: storePreference,
            syncState: storePreference ? .localOnly : .localOnly
        )
    }

    /// Custom coding keys to maintain backwards compatibility with previously persisted conversations.
    private enum CodingKeys: String, CodingKey {
        case id
        case remoteId
        case title
        case messages
        case lastResponseId
        case lastModified
        case metadata
        case lastSyncedAt
        case shouldStoreRemotely
        case syncState
    }

    init(
        id: UUID,
        remoteId: String?,
        title: String,
        messages: [ChatMessage],
        lastResponseId: String?,
        lastModified: Date,
        metadata: [String: String]?,
        lastSyncedAt: Date?,
        shouldStoreRemotely: Bool,
        syncState: SyncState
    ) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.messages = messages
        self.lastResponseId = lastResponseId
        self.lastModified = lastModified
        self.metadata = metadata
        self.lastSyncedAt = lastSyncedAt
        self.shouldStoreRemotely = shouldStoreRemotely
        self.syncState = syncState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        remoteId = try container.decodeIfPresent(String.self, forKey: .remoteId)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decodeIfPresent([ChatMessage].self, forKey: .messages) ?? []
        lastResponseId = try container.decodeIfPresent(String.self, forKey: .lastResponseId)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
        shouldStoreRemotely = try container.decodeIfPresent(Bool.self, forKey: .shouldStoreRemotely) ?? true
        syncState = try container.decodeIfPresent(SyncState.self, forKey: .syncState) ?? (remoteId == nil ? .localOnly : .synced)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(remoteId, forKey: .remoteId)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(lastResponseId, forKey: .lastResponseId)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(lastSyncedAt, forKey: .lastSyncedAt)
        try container.encode(shouldStoreRemotely, forKey: .shouldStoreRemotely)
        try container.encode(syncState, forKey: .syncState)
    }
}
