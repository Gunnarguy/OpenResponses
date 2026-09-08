import Foundation

enum VectorStoreIndexing {
    enum IndexingError: LocalizedError {
        case stillProcessing
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .stillProcessing: return "Uploaded; indexing is still running. Check again here or in Files."
            case .failed(let reason): return reason
            }
        }
    }

    static func waitUntilReady(
        initial: VectorStoreFile,
        timeout: TimeInterval = 90,
        pollInterval: TimeInterval = 2,
        retrieve: (TimeInterval) async throws -> VectorStoreFile
    ) async throws -> VectorStoreFile {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))
        var file = initial
        while true {
            try Task.checkCancellation()
            switch file.status {
            case "completed": return file
            case "failed", "cancelled":
                throw IndexingError.failed(file.lastError?.message ?? "Indexing was \(file.status).")
            case "in_progress": break
            default: throw IndexingError.failed("Unexpected indexing status: \(file.status). Refresh the file status.")
            }
            let remaining = clock.now.duration(to: deadline)
            guard remaining > .zero else { throw IndexingError.stillProcessing }
            try await Task.sleep(for: min(.seconds(pollInterval), remaining))
            let seconds = clock.now.duration(to: deadline).components
            let remainingSeconds = Double(seconds.seconds) + Double(seconds.attoseconds) / 1e18
            guard remainingSeconds > 0 else { throw IndexingError.stillProcessing }
            file = try await retrieve(min(15, remainingSeconds))
        }
    }
}
