import Foundation
import WebKit

/// Runs Python on the device with Pyodide 314.0.7 (CPython compiled to WebAssembly, bundled, MPL-2.0) in a hidden
/// WKWebView. Only the standard library is available: a content rule list blocks every load except the bundled
/// runtime, so code cannot reach the network or install packages (App Store guideline 2.5.2 forbids downloading
/// code), and each run starts from an empty namespace. A run that outlasts its time limit tears the web view down,
/// which ends its web content process; the next run loads a fresh interpreter.
@MainActor
final class LocalPythonRunner: NSObject {
    static let shared = LocalPythonRunner()

    nonisolated struct Result: Equatable, Sendable {
        var stdout = ""
        var stderr = ""
        var value: String?
        var error: String?
        var timedOut = false

        /// Characters of each stream returned to the model, so a runaway print cannot flood the context.
        nonisolated static let outputLimit = 16_000

        /// The tool output the model receives.
        var toolOutput: String {
            if timedOut { return "Error: the Python run exceeded its time limit and was stopped." }
            func clip(_ text: String) -> String {
                text.count > Self.outputLimit ? String(text.prefix(Self.outputLimit)) + "\n[output truncated]" : text
            }
            var sections: [String] = []
            if !stdout.isEmpty { sections.append("stdout:\n" + clip(stdout)) }
            if let value, !value.isEmpty, value != "None" { sections.append("result:\n" + clip(value)) }
            if !stderr.isEmpty { sections.append("stderr:\n" + clip(stderr)) }
            if let error { sections.append("error:\n" + clip(error)) }
            return sections.isEmpty ? "The code ran and printed nothing." : sections.joined(separator: "\n\n")
        }
    }

    enum RunnerError: LocalizedError {
        case missingRuntime, loadFailed(String)
        var errorDescription: String? {
            switch self {
            case .missingRuntime: return "The bundled Python runtime is missing from the app."
            case .loadFailed(let reason): return "Python could not start: \(reason)"
            }
        }
    }

    nonisolated static let scheme = "openresponses-python"
    /// The only files the runtime scheme serves, with their MIME types.
    nonisolated static let runtimeFiles: [String: String] = [
        "python-runner.html": "text/html", "pyodide.mjs": "text/javascript", "pyodide.asm.mjs": "text/javascript",
        "pyodide.asm.wasm": "application/wasm", "python_stdlib.zip": "application/zip", "pyodide-lock.json": "application/json",
    ]
    /// Everything but the runtime scheme is blocked, including fetch, XHR and WebSockets from Python. Content
    /// blocker regular expressions have no `|`, so each allowed prefix is its own rule.
    nonisolated static let contentRules = """
    [{"trigger":{"url-filter":".*"},"action":{"type":"block"}},
     {"trigger":{"url-filter":"^openresponses-python:"},"action":{"type":"ignore-previous-rules"}},
     {"trigger":{"url-filter":"^blob:"},"action":{"type":"ignore-previous-rules"}},
     {"trigger":{"url-filter":"^data:"},"action":{"type":"ignore-previous-rules"}}]
    """

    private var webView: WKWebView?
    private var loading: Task<WKWebView, Error>?
    private var navigationWaiter: CheckedContinuation<Void, Error>?

    /// Runs `code` and returns what it printed, its last expression's value, or its error.
    func run(_ code: String, timeout: TimeInterval = 30) async -> Result {
        let webView: WKWebView
        do { webView = try await readyWebView() } catch {
            tearDown()
            return Result(error: error.localizedDescription)
        }
        final class Once { var done = false }
        let once = Once()
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let result: Result
                do {
                    let reply = try await webView.callAsyncJavaScript("return await window.openResponsesRun(code)",
                                                                      arguments: ["code": code], contentWorld: .page)
                    result = Self.result(from: reply)
                } catch {
                    result = Result(error: "Python stopped: \(error.localizedDescription)")
                }
                guard !once.done else { return }
                once.done = true
                continuation.resume(returning: result)
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(timeout))
                guard !once.done else { return }
                once.done = true
                self.tearDown() // A blocked interpreter cannot be interrupted; its process is ended instead.
                continuation.resume(returning: Result(timedOut: true))
            }
        }
    }

    /// Drops the interpreter; the next run starts a new one.
    func tearDown() {
        loading?.cancel()
        loading = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
        navigationWaiter?.resume(throwing: RunnerError.loadFailed("stopped"))
        navigationWaiter = nil
    }

    nonisolated static func result(from reply: Any?) -> Result {
        guard let object = reply as? [String: Any] else { return Result(error: "Python returned no result.") }
        return Result(stdout: object["stdout"] as? String ?? "", stderr: object["stderr"] as? String ?? "",
                      value: object["value"] as? String, error: object["error"] as? String)
    }

    private func readyWebView() async throws -> WKWebView {
        if let webView { return webView }
        if let loading { return try await loading.value }
        let task = Task { @MainActor () -> WKWebView in
            guard Bundle.main.url(forResource: "pyodide.asm.wasm", withExtension: nil) != nil else { throw RunnerError.missingRuntime }
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            configuration.setURLSchemeHandler(PythonRuntimeSchemeHandler(), forURLScheme: Self.scheme)
            let rules = try await WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "OpenResponsesPythonSandbox", encodedContentRuleList: Self.contentRules)
            if let rules { configuration.userContentController.add(rules) }
            let view = WKWebView(frame: .zero, configuration: configuration)
            view.navigationDelegate = self
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                navigationWaiter = continuation
                view.load(URLRequest(url: URL(string: "\(Self.scheme)://runtime/python-runner.html")!))
            }
            let ready = try await view.callAsyncJavaScript("return await window.openResponsesReady", contentWorld: .page)
            if let failure = ready as? String { throw RunnerError.loadFailed(failure) }
            return view
        }
        loading = task
        do {
            let view = try await task.value
            webView = view
            loading = nil
            return view
        } catch {
            loading = nil
            throw error
        }
    }
}

extension LocalPythonRunner: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationWaiter?.resume()
        navigationWaiter = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationWaiter?.resume(throwing: RunnerError.loadFailed(error.localizedDescription))
        navigationWaiter = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationWaiter?.resume(throwing: RunnerError.loadFailed(error.localizedDescription))
        navigationWaiter = nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if webView === self.webView { tearDown() }
    }
}

/// Serves the bundled Pyodide files, and nothing else, to the runner page.
final class PythonRuntimeSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let name = url.pathComponents.last,
              let mime = LocalPythonRunner.runtimeFiles[name],
              let file = Bundle.main.url(forResource: name, withExtension: nil),
              let data = try? Data(contentsOf: file, options: .mappedIfSafe),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": mime, "Content-Length": String(data.count)]) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}
