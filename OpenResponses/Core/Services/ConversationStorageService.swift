import Foundation

/// A service responsible for persisting and retrieving `Conversation` objects from the device's local storage.
/// This class handles the serialization of conversations to JSON and saves them to the file system.
class ConversationStorageService {
    /// The singleton instance of the storage service, ensuring a single point of access to the conversation data.
    static let shared = ConversationStorageService()

    /// The URL of the directory where conversations are stored. This is typically the app's Application Support directory.
    private let storageURL: URL

    /// An in-memory cache of the conversations, sorted by their last modified date.
    /// Using a cache avoids repeatedly reading from the disk.
    private var conversationsCache: [Conversation]?

    /// Initializes the storage service. It sets up the storage directory and ensures it exists.
    /// If the directory cannot be created, it will trigger a fatal error, as the app cannot function without it.
    private init() {
        do {
            let fileManager = FileManager.default
            let appSupportDir = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            storageURL = appSupportDir.appendingPathComponent("Conversations")

            // Create the storage directory if it doesn't already exist.
            if !fileManager.fileExists(atPath: storageURL.path) {
                try fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            fatalError("Failed to initialize ConversationStorageService: \(error)")
        }
    }

    /// Retrieves all conversations, sorted by the last modified date in descending order.
    /// - Returns: An array of `Conversation` objects.
    /// - Throws: An error if the conversations cannot be loaded from the disk.
    func loadConversations() throws -> [Conversation] {
        // Return from cache if available
        if let cached = conversationsCache {
            return cached
        }

        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil)

        var loadedConversations: [Conversation] = []
        for url in fileURLs where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                let conversation = try JSONDecoder().decode(Conversation.self, from: data)
                loadedConversations.append(conversation)
            } catch {
                // Log the error but continue loading other conversations
                print("Failed to load or decode conversation from \(url.lastPathComponent): \(error)")
            }
        }

        // Sort by last modified date, newest first
        loadedConversations.sort { $0.lastModified > $1.lastModified }
        
        // Update the cache
        self.conversationsCache = loadedConversations
        
        return loadedConversations
    }

    /// Saves a single conversation to the disk.
    /// - Parameter conversation: The `Conversation` object to save.
    /// - Throws: An error if the conversation cannot be encoded or saved.
    func saveConversation(_ conversation: Conversation) throws {
        let fileURL = storageURL.appendingPathComponent("\(conversation.id.uuidString).json")
        let data = try JSONEncoder().encode(conversation)
        try data.write(to: fileURL, options: .atomic)
        
        // Update the cache
        updateCache(with: conversation)
    }

    /// Deletes a conversation from the disk.
    /// - Parameter conversationId: The UUID of the conversation to delete.
    /// - Throws: An error if the file cannot be removed.
    func deleteConversation(withId conversationId: UUID) throws {
        let fileURL = storageURL.appendingPathComponent("\(conversationId.uuidString).json")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        // Remove from cache
        conversationsCache?.removeAll { $0.id == conversationId }
    }
    
    /// Updates the in-memory cache with the given conversation.
    /// This ensures the cache is consistent with the latest changes.
    private func updateCache(with conversation: Conversation) {
        if let index = conversationsCache?.firstIndex(where: { $0.id == conversation.id }) {
            conversationsCache?[index] = conversation
        } else {
            conversationsCache?.append(conversation)
        }
        // Re-sort the cache to maintain order
        conversationsCache?.sort { $0.lastModified > $1.lastModified }
    }
}
