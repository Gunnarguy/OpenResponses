import Foundation

/// Hands text, links and files to the chat from outside it: the share sheet (a separate process)
/// and the New Chat shortcut (in the app's process).
///
/// Each delivery is a folder under `Inbox/` in the App Group container, holding `item.json` and the
/// files it names. The app reads every waiting delivery when it becomes active, opens one new chat
/// with their text in the message field and their files attached, then deletes the folders. Nothing
/// is sent anywhere until the person taps Send in the app (3.1).
///
/// Without the App Group (a build signed without that capability) the inbox lives in the app's own
/// Application Support folder, which only the app's own process can reach: shortcuts still work and
/// the share extension has nowhere to write.
nonisolated struct SharedInbox: Sendable {
    static let appGroupID = "group.Gunndamental.OpenResponses"

    struct File: Codable, Equatable, Sendable {
        enum Kind: String, Codable, Sendable { case image, file }
        var name: String
        var kind: Kind
    }

    struct Item: Codable, Equatable, Sendable {
        var id: UUID = UUID()
        var createdAt: Date = Date()
        var text: String
        var files: [File] = []
        /// Where it came from, shown nowhere; kept for diagnostics ("share", "shortcut").
        var source: String
    }

    /// One waiting delivery with its files read into memory.
    struct Delivery: Sendable {
        var item: Item
        var fileData: [String: Data]
    }

    let root: URL

    init(root: URL) {
        self.root = root
    }

    /// The inbox the app and the share extension share, or the app-only fallback.
    static var shared: SharedInbox {
        let fm = FileManager.default
        if let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return SharedInbox(root: group.appendingPathComponent("Inbox", isDirectory: true))
        }
        let support = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        return SharedInbox(root: support.appendingPathComponent("Inbox", isDirectory: true))
    }

    /// True when the share extension can reach this inbox.
    static var isSharedWithExtensions: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    /// Writes one delivery. `files` pairs each file's description with its bytes.
    @discardableResult
    func deliver(text: String, files: [(File, Data)] = [], source: String) throws -> Item {
        let fm = FileManager.default
        var item = Item(text: text, source: source)
        let folder = root.appendingPathComponent(item.id.uuidString, isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        var used = Set<String>()
        for (file, data) in files {
            var described = file
            described.name = Self.uniqueName(Self.safeName(file.name), taken: &used)
            try data.write(to: folder.appendingPathComponent(described.name), options: .atomic)
            item.files.append(described)
        }
        // item.json last: a folder without it is a delivery still being written, and is skipped.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(item).write(to: folder.appendingPathComponent("item.json"), options: .atomic)
        return item
    }

    /// Every complete delivery, oldest first, without removing anything.
    func pending() -> [Delivery] {
        let fm = FileManager.default
        guard let folders = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var deliveries: [Delivery] = []
        for folder in folders where folder.hasDirectoryPath {
            guard let data = try? Data(contentsOf: folder.appendingPathComponent("item.json")),
                  let item = try? decoder.decode(Item.self, from: data)
            else { continue }
            var fileData: [String: Data] = [:]
            for file in item.files {
                if let bytes = try? Data(contentsOf: folder.appendingPathComponent(file.name)) {
                    fileData[file.name] = bytes
                }
            }
            deliveries.append(Delivery(item: item, fileData: fileData))
        }
        return deliveries.sorted { $0.item.createdAt < $1.item.createdAt }
    }

    /// Removes the named deliveries once the app has taken them.
    func remove(_ ids: [UUID]) {
        for id in ids {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(id.uuidString, isDirectory: true))
        }
    }

    /// Every delivery's text joined with blank lines, in arrival order.
    static func combinedText(_ deliveries: [Delivery]) -> String {
        deliveries
            .map { $0.item.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    static func safeName(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty || cleaned == "item.json" || cleaned.hasPrefix(".") ? "file-\(cleaned)" : cleaned
    }

    private static func uniqueName(_ name: String, taken: inout Set<String>) -> String {
        var candidate = name
        var counter = 2
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        while taken.contains(candidate) {
            candidate = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            counter += 1
        }
        taken.insert(candidate)
        return candidate
    }
}
