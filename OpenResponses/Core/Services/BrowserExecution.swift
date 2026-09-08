import Foundation

/// Each callback owns its continuation. Late WebKit callbacks can never complete another request.
@MainActor
final class BrowserCallback<Value> {
    private var continuation: CheckedContinuation<Value, Error>?
    private var timer: Task<Void, Never>?
    private var interrupt: (() -> Void)?
    private var finished = false

    // Swift 6.3.3 crashes while optimizing the synthesized generic destructor.
    // Keep this destructor unoptimized until the stable toolchain includes the fix.
    @_optimize(none)
    deinit {}

    func wait(timeout: Duration, label: String, onInterrupt: @escaping () -> Void = {},
              start: (@escaping (Result<Value, Error>) -> Void) -> Void) async throws -> Value {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                self.interrupt = onInterrupt
                if Task.isCancelled {
                    finish(.failure(CancellationError()), interrupted: true)
                    return
                }
                timer = Task { [weak self] in
                    do { try await Task.sleep(for: timeout) } catch { return }
                    self?.finish(.failure(ComputerUseError.timedOut(label)), interrupted: true)
                }
                start { [self] result in finish(result) }
            }
        } onCancel: {
            Task { @MainActor [self] in finish(.failure(CancellationError()), interrupted: true) }
        }
    }

    func finish(_ result: Result<Value, Error>, interrupted: Bool = false) {
        guard !finished, let continuation else { return }
        finished = true
        self.continuation = nil
        timer?.cancel()
        timer = nil
        let onInterrupt = interrupt
        interrupt = nil
        if interrupted { onInterrupt?() }
        continuation.resume(with: result)
    }
}

/// One browser has one execution lane, shared by DOM functions and screenshot actions.
@MainActor
final class BrowserExecution {
    private struct Waiter {
        let id: UUID
        let callback: BrowserCallback<Void>
    }
    private var owner: UUID?
    private var waiters: [Waiter] = []
    private var cancelActive: ((Error) -> Void)?
    private(set) var generation = UUID()
    private(set) var actionsUsed = 0
    private var consumedCallIDs = Set<String>()
    private var callOrder: [String] = []
    var maxActions = 80
    var approvalPending = false

    func beginTurn() {
        cancel()
        actionsUsed = 0
        approvalPending = false
    }

    func cancel() { abort(CancellationError()) }

    func abort(_ error: Error) {
        generation = UUID()
        cancelActive?(error)
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.callback.finish(.failure(error)) }
    }

    func run<T>(actions: Int = 1, callID: String? = nil, timeout: Duration = .seconds(45),
                onInterrupt: @escaping () -> Void = {},
                operation: @escaping @MainActor () async throws -> T) async throws -> T {
        let expectedGeneration = generation
        let id = UUID()
        try Task.checkCancellation()
        if owner != nil {
            let callback = BrowserCallback<Void>()
            try await callback.wait(timeout: .seconds(120), label: "browser queue", onInterrupt: { [weak self] in
                self?.waiters.removeAll { $0.id == id }
                // Cancellation can race with granting the lane.
                self?.release(id)
            }) { _ in waiters.append(Waiter(id: id, callback: callback)) }
        } else {
            owner = id
        }
        defer { release(id) }
        try Task.checkCancellation()
        guard generation == expectedGeneration else { throw CancellationError() }
        guard !approvalPending else { throw ComputerUseError.approvalRequired }
        guard actions > 0, actions <= maxActions - actionsUsed else {
            throw ComputerUseError.limitExceeded("Browser action limit (\(maxActions)) reached for this turn.")
        }
        if let callID {
            guard consumedCallIDs.insert(callID).inserted else { throw ComputerUseError.duplicateCall }
            callOrder.append(callID)
            if callOrder.count > 2048 { consumedCallIDs.remove(callOrder.removeFirst()) }
        }
        // Keep consumed IDs even after failure/cancellation or a new user turn: effects may have occurred.
        actionsUsed += actions
        let callback = BrowserCallback<T>()
        var task: Task<Void, Never>?
        cancelActive = { callback.finish(.failure($0), interrupted: true) }
        return try await callback.wait(timeout: timeout, label: "browser operation", onInterrupt: {
            task?.cancel()
            onInterrupt()
        }) { finish in
            task = Task {
                do {
                    try Task.checkCancellation()
                    let value = try await operation()
                    try Task.checkCancellation()
                    finish(.success(value))
                } catch { finish(.failure(error)) }
            }
        }
    }

    private func release(_ id: UUID) {
        guard owner == id else { return }
        cancelActive = nil
        owner = nil
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            owner = next.id
            next.callback.finish(.success(()))
        }
    }
}

struct BrowserNavigationPolicy {
    var maxPages = 20
    private(set) var visited = Set<String>()

    static func url(_ value: String) throws -> URL {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.contains("://") || trimmed.lowercased().hasPrefix("about:")
            || trimmed.lowercased().hasPrefix("javascript:") || trimmed.lowercased().hasPrefix("data:")
            || trimmed.lowercased().hasPrefix("file:") ? trimmed : "https://" + trimmed
        guard let url = URL(string: text) else { throw ComputerUseError.invalidParameters }
        try validate(url)
        return url
    }

    static func validate(_ url: URL) throws {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else {
            throw ComputerUseError.navigationBlocked
        }
    }

    mutating func admit(_ url: URL) throws {
        try Self.validate(url)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        let key = components?.string ?? url.absoluteString
        guard visited.contains(key) || visited.count < maxPages else {
            throw ComputerUseError.limitExceeded("Browser page limit (\(maxPages)) reached for this turn.")
        }
        visited.insert(key)
    }
}
