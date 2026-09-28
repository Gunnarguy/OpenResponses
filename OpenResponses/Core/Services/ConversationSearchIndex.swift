import CryptoKit
import Foundation
import NaturalLanguage

/// One message's searchable text, copied off the main actor.
nonisolated struct SearchableMessage: Sendable {
    let conversationID: UUID
    let messageID: UUID
    let text: String
}

/// A conversation that matches a search, with the passage that matched best.
nonisolated struct ConversationSearchHit: Identifiable, Equatable, Sendable {
    var id: UUID { conversationID }
    let conversationID: UUID
    let messageID: UUID
    let snippet: String
    let score: Double
}

/// Finds conversations by meaning with Apple's on-device sentence embeddings (NaturalLanguage, iOS 14 and later).
/// Vectors are cached per message in Caches and keyed by a SHA-256 of the message text, so an edited message is
/// embedded again, a deleted one is dropped, and nothing leaves the device. Without an embedding model for the
/// language, search falls back to matching words.
actor ConversationSearchIndex {
    static let shared = ConversationSearchIndex()

    /// Passages longer than this many characters are split at sentence boundaries.
    nonisolated static let passageLength = 320
    /// Long messages contribute at most this many passages.
    nonisolated static let maxPassagesPerMessage = 12
    /// Semantic matches below this cosine similarity are not shown unless words also match. Measured on
    /// 2026-09-28 with the English sentence embedding on macOS 27 (revision 1, 512 dimensions): related
    /// passages scored 0.21 to 0.28, unrelated ones 0.02 to 0.18. The iOS 27 simulator has no model.
    nonisolated static let minimumSimilarity = 0.15

    private struct Entry: Codable {
        let digest: String
        /// Float16 vectors, one per passage, stored as raw bytes.
        let vectors: [Data]
    }

    private struct Store: Codable {
        var format = 1
        var language: String
        var revision: Int
        var entries: [String: Entry] = [:]
    }

    private let fileURL: URL
    private var store: Store?
    private var embedding: NLEmbedding?
    private var language: NLLanguage = .english
    private var isDirty = false

    /// `useEmbeddings: false` gives word-only search, as on a device without an embedding model.
    init(directory: URL? = nil, language: NLLanguage? = nil, useEmbeddings: Bool = true) {
        let base = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        fileURL = base.appendingPathComponent("ConversationSearchIndex.plist")
        let preferred = language ?? Locale.preferredLanguages.first.map { NLLanguage(rawValue: String($0.prefix(2))) } ?? .english
        if !useEmbeddings {
            embedding = nil
        } else if let model = NLEmbedding.sentenceEmbedding(for: preferred) {
            self.language = preferred
            embedding = model
        } else {
            self.language = .english
            embedding = NLEmbedding.sentenceEmbedding(for: .english)
        }
    }

    /// True when searches rank by meaning rather than by words alone. The embedding object can exist while its
    /// model asset is missing ("Unable to locate Asset for sentence embedding model", iOS 27 simulator), so this
    /// asks for a real vector.
    var isSemantic: Bool { embedding?.vector(for: "search") != nil }

    /// Embeds messages that are new or changed and drops cached messages that no longer exist.
    func update(with messages: [SearchableMessage]) {
        guard let embedding else { return }
        loadIfNeeded(for: embedding)
        var live = Set<String>()
        for message in messages {
            let key = message.messageID.uuidString
            live.insert(key)
            let digest = Self.digest(message.text)
            if store?.entries[key]?.digest == digest { continue }
            let passages = Self.passages(of: message.text)
            let vectors = passages.compactMap { embedding.vector(for: $0) }
            // A missing vector means the model is not ready; leave the message uncached so a later update retries.
            guard vectors.count == passages.count else { continue }
            store?.entries[key] = Entry(digest: digest, vectors: vectors.map(Self.pack))
            isDirty = true
        }
        // Filter a copy: `store?.entries = store?.entries.filter` reads `store` inside its own modify access,
        // which Swift's exclusivity check stops at run time.
        if let entries = store?.entries, entries.keys.contains(where: { !live.contains($0) }) {
            let kept = entries.filter { live.contains($0.key) }
            store?.entries = kept
            isDirty = true
        }
        saveIfNeeded()
    }

    /// Conversations ranked by the best-matching passage of any of their messages.
    func search(_ query: String, in messages: [SearchableMessage], limit: Int = 25) -> [ConversationSearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        update(with: messages)
        let words = Self.words(trimmed)
        let queryVector = embedding?.vector(for: trimmed).map { $0.map(Float.init) }
        var best: [UUID: ConversationSearchHit] = [:]
        for message in messages {
            let passages = Self.passages(of: message.text)
            guard !passages.isEmpty else { continue }
            let vectors = store?.entries[message.messageID.uuidString].map { $0.vectors.map(Self.unpack) } ?? []
            for (index, passage) in passages.enumerated() {
                let wordMatch = !words.isEmpty && Set(Self.words(passage)).isSuperset(of: words)
                var similarity = 0.0
                if let queryVector, index < vectors.count { similarity = Self.cosine(queryVector, vectors[index]) }
                guard wordMatch || (queryVector != nil && similarity >= Self.minimumSimilarity) else { continue }
                let score = similarity + (wordMatch ? 0.25 : 0)
                if score > (best[message.conversationID]?.score ?? -1) {
                    best[message.conversationID] = ConversationSearchHit(conversationID: message.conversationID, messageID: message.messageID,
                                                                         snippet: passage, score: score)
                }
            }
        }
        return best.values.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    /// Writes pending changes; call when the app moves to the background.
    func flush() { saveIfNeeded() }

    /// Number of messages with cached vectors (tests and diagnostics).
    func cachedMessageCount() -> Int { store?.entries.count ?? 0 }

    /// The text digest cached for a message (tests and diagnostics).
    func cachedDigest(for messageID: UUID) -> String? { store?.entries[messageID.uuidString]?.digest }

    // MARK: - Storage

    private func loadIfNeeded(for embedding: NLEmbedding) {
        guard store == nil else { return }
        if let data = try? Data(contentsOf: fileURL), let saved = try? PropertyListDecoder().decode(Store.self, from: data),
           saved.format == 1, saved.language == language.rawValue, saved.revision == embedding.revision {
            store = saved
        } else {
            store = Store(language: language.rawValue, revision: embedding.revision)
        }
    }

    private func saveIfNeeded() {
        guard isDirty, let store else { return }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        guard let data = try? encoder.encode(store) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if (try? data.write(to: fileURL, options: .atomic)) != nil { isDirty = false }
    }

    // MARK: - Text and vectors

    nonisolated static func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Sentences grouped into passages of about `passageLength` characters, at most `maxPassagesPerMessage`.
    nonisolated static func passages(of text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var passages: [String] = []
        var current = ""
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }
            if !current.isEmpty, current.count + sentence.count + 1 > passageLength {
                passages.append(current)
                current = ""
            }
            current += current.isEmpty ? sentence : " " + sentence
            return passages.count < maxPassagesPerMessage
        }
        if !current.isEmpty, passages.count < maxPassagesPerMessage { passages.append(current) }
        return passages
    }

    nonisolated static func words(_ text: String) -> Set<String> {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return Set(folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 })
    }

    nonisolated static func cosine(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, normA: Float = 0, normB: Float = 0
        for index in a.indices {
            dot += a[index] * b[index]
            normA += a[index] * a[index]
            normB += b[index] * b[index]
        }
        guard normA > 0, normB > 0 else { return 0 }
        return Double(dot / (normA.squareRoot() * normB.squareRoot()))
    }

    nonisolated static func pack(_ vector: [Double]) -> Data {
        let halves = vector.map { Float16(Float($0)) }
        return halves.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    nonisolated static func unpack(_ data: Data) -> [Float] {
        // Copy rather than bind: Data's bytes carry no alignment guarantee for Float16.
        var halves = [Float16](repeating: 0, count: data.count / MemoryLayout<Float16>.size)
        _ = halves.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return halves.map(Float.init)
    }
}
