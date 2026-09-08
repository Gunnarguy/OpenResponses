import Foundation

nonisolated struct MCPDiscoveryStream {
    let events: AsyncThrowingStream<[String: Any], Error>
    let cancel: () -> Void

    private final class NoRedirects: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }

    static func open(_ request: URLRequest) -> MCPDiscoveryStream {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForResource = request.timeoutInterval
        let session = URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
        var task: Task<Void, Never>!
        let events = AsyncThrowingStream<[String: Any], Error>(bufferingPolicy: .bufferingOldest(64)) { continuation in
            task = Task {
                defer { session.invalidateAndCancel() }
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else { throw MCPDiscoveryError.unavailable }
                    guard (200..<300).contains(http.statusCode) else {
                        if http.statusCode == 401 { throw MCPDiscoveryError.apiAuthentication }
                        if http.statusCode == 429 { throw MCPDiscoveryError.rateLimited }
                        if (500..<600).contains(http.statusCode) { throw MCPDiscoveryError.unavailable }
                        var data = Data()
                        for try await byte in bytes { data.append(byte); if data.count >= 32_768 { break } }
                        let classification = MCPDiscoveryError.server(String(decoding: data, as: UTF8.self))
                        throw classification == .noCatalog ? MCPDiscoveryError.apiRejected : classification
                    }
                    guard http.value(forHTTPHeaderField: "Content-Type")?.lowercased().contains("text/event-stream") == true else {
                        throw MCPDiscoveryError.malformedCatalog
                    }
                    var decoder = MCPDiscoverySSEDecoder()
                    for try await byte in bytes {
                        try Task.checkCancellation()
                        if let event = try decoder.append(byte) {
                            if case .dropped = continuation.yield(event) { throw MCPDiscoveryError.malformedCatalog }
                        }
                        if decoder.isDone { break }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            let worker = task!
            continuation.onTermination = { _ in worker.cancel(); session.invalidateAndCancel() }
        }
        let worker = task!
        return MCPDiscoveryStream(events: events, cancel: { worker.cancel(); session.invalidateAndCancel() })
    }
}

/// Incremental SSE framing with limits enforced before buffering an untrusted line.
nonisolated struct MCPDiscoverySSEDecoder {
    private var line = Data()
    private var payload = Data()
    private var totalBytes = 0
    private(set) var isDone = false
    static let maximumEventBytes = 4 * 1024 * 1024
    static let maximumStreamBytes = 12 * 1024 * 1024

    mutating func append(_ byte: UInt8) throws -> [String: Any]? {
        totalBytes += 1
        guard totalBytes <= Self.maximumStreamBytes, line.count + payload.count < Self.maximumEventBytes else {
            throw MCPDiscoveryError.malformedCatalog
        }
        guard byte == 10 else { line.append(byte); return nil }
        if line.last == 13 { line.removeLast() }
        defer { line.removeAll(keepingCapacity: true) }
        if line.isEmpty {
            guard !payload.isEmpty else { return nil }
            defer { payload.removeAll(keepingCapacity: true) }
            if String(decoding: payload, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                isDone = true
                return nil
            }
            guard let event = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any] else {
                throw MCPDiscoveryError.malformedCatalog
            }
            return event
        }
        if line.starts(with: Data("data:".utf8)) {
            var value = line.dropFirst(5)
            if value.first == 32 { value = value.dropFirst() }
            if !payload.isEmpty { payload.append(10) }
            payload.append(contentsOf: value)
        }
        return nil
    }
}
