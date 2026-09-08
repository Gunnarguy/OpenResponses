import Foundation
import WebKit
import Combine
import UIKit

struct JavaScriptResult: @unchecked Sendable {
    let value: Any?
}

/// A service that provides native, on-device browser automation capabilities.
///
/// This class manages an off-screen `WKWebView` instance to perform actions requested by the AI model,
/// such as navigating to URLs, clicking elements, typing text, and taking screenshots. It acts as a
/// local replacement for the previous server-based Playwright implementation.
///
/// The service is designed to be run on the main actor as it interacts with `WKWebView`, a UI component.
@MainActor
class ComputerService: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let autoAttachWebView: Bool
    private var webView: WKWebView?

    // Track attach lifecycle to avoid noisy logs and enable automatic retry when a key window appears.
    private var hasLoggedNoKeyWindow: Bool = false
    private var attachObservers: [NSObjectProtocol] = []
    private var didAttachToWindow: Bool {
        webView?.superview != nil
    }

    private let execution = BrowserExecution()
    private var navigationPolicy = BrowserNavigationPolicy()
    private var activeNavigationID: ObjectIdentifier?
    private var navigations: [ObjectIdentifier: (Result<Void, Error>) -> Void] = [:]
    private var pendingCallbacks: [UUID: (Error) -> Void] = [:]
    private var pageError: Error?
    private var lastHTTPStatus: Int?
    private var recoveryNotice: String?
    private let automationWorld = WKContentWorld.world(name: "OpenResponsesAutomation")

    func beginTurn() {
        cancelPendingOperations()
        execution.beginTurn()
        navigationPolicy = BrowserNavigationPolicy()
    }

    func cancelPendingOperations() {
        execution.cancel()
        webView?.stopLoading()
        failPendingCallbacks(CancellationError())
    }

    func setApprovalPending(_ pending: Bool) {
        execution.approvalPending = pending
        if pending { cancelPendingOperations() }
    }

    private func failPendingCallbacks(_ error: Error) {
        let pending = pendingCallbacks.values
        pendingCallbacks.removeAll()
        let loads = navigations.values
        navigations.removeAll()
        activeNavigationID = nil
        pending.forEach { $0(error) }
        loads.forEach { $0(.failure(error)) }
    }

    private func runBrowser<T>(actions: Int = 1, callID: String? = nil, operation: @escaping @MainActor () async throws -> T) async throws -> T {
        try await execution.run(actions: actions, callID: callID, onInterrupt: { [weak self] in
            self?.webView?.stopLoading()
        }) { [self] in
            pageError = nil
            return try await operation()
        }
    }

    init(autoAttachWebView: Bool = ComputerService.shouldAutoAttachWebView()) {
        self.autoAttachWebView = autoAttachWebView
        super.init()
        AppLogger.log("🔧 [ComputerService] Initializing new ComputerService instance", category: .general, level: .info)
        guard autoAttachWebView else {
            AppLogger.log("🤖 [ComputerService] Skipping WebView auto-attach for current configuration", category: .general, level: .info)
            return
        }

        setupWebView()

        // Proactively attempt to attach when app is ready
        Task { @MainActor in
            // Small delay to let the app fully initialize
            do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
            self.attachToWindowHierarchy()
        }
    }

    override convenience init() {
        self.init(autoAttachWebView: ComputerService.shouldAutoAttachWebView())
    }

    // Note: We avoid isolated deinit (requires iOS 18.4+) and rely on successful attach to unregister observers.

    /// Release the browser surface and outstanding work without clearing website data.
    func closeBrowser() {
        cancelPendingOperations()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
        unregisterAttachObservers()
    }

#if DEBUG
    func testing_loadHTML(_ html: String) async throws -> BrowserAutomationResult {
        try await runBrowser {
            try await self.prepareWebViewForExecution()
            try await self.loadNavigation { self.webView?.loadHTMLString(html, baseURL: nil) }
            return try await self.captureBrowserAutomationResult(actionOutput: "Fixture loaded")
        }
    }

    func testing_simulateProcessTermination() {
        if let webView { webViewWebContentProcessDidTerminate(webView) }
    }

    func testing_evaluatePage(_ script: String) async throws -> Any? {
        guard let webView else { throw ComputerUseError.webViewNotAvailable }
        let value: JavaScriptResult = try await boundedCallback(label: "fixture script") { finish in
            webView.evaluateJavaScript(script) { value, error in
                if let error { finish(.failure(error)) }
                else { finish(.success(JavaScriptResult(value: value))) }
            }
        }
        return value.value
    }
#endif

    /// Returns the current URL loaded in the WebView, if any.
    func currentURL() -> String? {
        return webView?.url?.absoluteString
    }

    /// True when no meaningful page is loaded yet (nil or about:blank)
    func isOnBlankPage() -> Bool {
        guard let url = webView?.url?.absoluteString else { return true }
        return url.isEmpty || url == "about:blank"
    }

    /// Configures and sets up the off-screen `WKWebView`.
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        configuration.suppressesIncrementalRendering = false
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        // Match the configured tool display to reduce scaling artifacts (default 440x956 from tool)
        let width: CGFloat = 440
        let height: CGFloat = 956
        let webViewFrame = CGRect(x: 0, y: 0, width: width, height: height)

        webView = WKWebView(frame: webViewFrame, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
        webView?.isOpaque = false
        webView?.backgroundColor = .white
        webView?.scrollView.backgroundColor = .white
        webView?.scrollView.isScrollEnabled = true
        // Keep the installed WebKit version in the user agent instead of spoofing an old OS.

        // Attempt immediate attach; if not possible, set up observers to retry when app/window becomes active.
        attachToWindowHierarchy()
        if !(didAttachToWindow) {
            registerAttachObservers()
        }
    }

    /// Attempts to attach the WebView to the window hierarchy for proper rendering
    private func attachToWindowHierarchy() {
        guard let webView = webView else { return }

        // Skip if already attached
        if webView.superview != nil {
            // Once attached, we can safely remove any observers.
            unregisterAttachObservers()
            return
        }

        // Try to find key window prioritizing active foreground scenes
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let foregroundActiveScenes = windowScenes.filter { $0.activationState == .foregroundActive }
        let keyWindow = foregroundActiveScenes.compactMap { $0.windows.first(where: { $0.isKeyWindow }) }.first
            ?? windowScenes.compactMap { $0.windows.first(where: { $0.isKeyWindow }) }.first

        if let window = keyWindow {
            // Keep the browser attached and opaque; snapshotting does not require onscreen interaction.
            webView.frame = CGRect(x: -1000, y: -1000, width: 440, height: 956) // Move completely off-screen
            webView.alpha = 1.0 // Keep full alpha since it's positioned off-screen
            webView.isHidden = false // Must not be hidden for reliable snapshots
            webView.isUserInteractionEnabled = false // Do not intercept touches
            webView.accessibilityElementsHidden = true // Keep it out of accessibility focus
            window.addSubview(webView)

            // Force layout after adding to window
            webView.setNeedsLayout()
            webView.layoutIfNeeded()

            AppLogger.log("✅ [WebView Setup] Successfully attached WebView to key window (off-screen)", category: .general, level: .info)
            unregisterAttachObservers()
        } else {
            // Log this warning only once to avoid console spam; future retries are silent until success.
            if !hasLoggedNoKeyWindow {
                hasLoggedNoKeyWindow = true
                AppLogger.log("⚠️ [WebView Setup] No key window available yet - will retry when the app/window becomes active", category: .general, level: .warning)
            }
        }
    }

    /// Register observers to retry attaching when the app becomes active or a window becomes key.
    private func registerAttachObservers() {
        // Avoid duplicate observers
        if !attachObservers.isEmpty { return }
        let center = NotificationCenter.default
        let didBecomeActive = center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in self.attachToWindowHierarchy() }
        }
        let didConnectScene = center.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in self.attachToWindowHierarchy() }
        }
        let windowBecameKey = center.addObserver(forName: UIWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in self.attachToWindowHierarchy() }
        }
        attachObservers.append(contentsOf: [didBecomeActive, didConnectScene, windowBecameKey])
    }

    /// Unregister attach observers once we have successfully attached or when deinitializing.
    private func unregisterAttachObservers() {
        let center = NotificationCenter.default
        for token in attachObservers { center.removeObserver(token) }
        attachObservers.removeAll()
    }

    /// Executes a given `ComputerAction` and returns the result.
    ///
    /// This is the main entry point for the service. It takes an action decoded from a tool call,
    /// executes it, and then captures a screenshot and the current URL to be sent back to the model.
    /// - Parameter action: The `ComputerAction` to perform.
    /// - Returns: A `ComputerActionResult` containing a screenshot and other metadata.
    func executeAction(_ action: ComputerAction) async throws -> ComputerActionResult {
        try await executeActions([action])
    }

    /// Executes a batch of computer actions sequentially and returns a single post-action screenshot.
    /// This matches the GA computer-use contract where GPT-5.4 emits `actions[]` for one computer call.
    func executeActions(_ actions: [ComputerAction], callID: String? = nil) async throws -> ComputerActionResult {
        try await runBrowser(actions: actions.count, callID: callID) { try await self.performComputerActions(actions) }
    }

    func liveBrowserNavigate(to urlString: String, callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) { try await self.browserNavigate(to: urlString) }
    }

    func liveBrowserRead(callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) { try await self.captureBrowserAutomationResult(actionOutput: "Read current page state") }
    }

    func liveBrowserSearch(query: String, site: String?, callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) { try await self.browserSearch(query: query, site: site) }
    }

    func liveBrowserClick(targetText: String, elementRef: String? = nil, callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) {
            try await self.prepareWebViewForExecution()
            let output = try await self.domAction("click", arguments: ["target": targetText, "ref": elementRef ?? ""])
            return try await self.captureBrowserAutomationResult(actionOutput: output)
        }
    }

    func liveBrowserType(text: String, fieldHint: String?, submit: Bool, elementRef: String? = nil, callID: String? = nil) async throws -> BrowserAutomationResult {
        guard text.utf8.count <= 100_000 else { throw ComputerUseError.invalidParameters }
        return try await runBrowser(callID: callID) {
            try await self.prepareWebViewForExecution()
            let output = try await self.domAction("type", arguments: ["text": text, "hint": fieldHint ?? "", "submit": submit, "ref": elementRef ?? ""])
            return try await self.captureBrowserAutomationResult(actionOutput: output)
        }
    }

    func liveBrowserScroll(direction: String, amount: Int?, callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) { try await self.browserScroll(direction: direction, amount: amount) }
    }

    func liveBrowserHistory(action: String, callID: String? = nil) async throws -> BrowserAutomationResult {
        try await runBrowser(callID: callID) {
            try await self.prepareWebViewForExecution()
            guard let webView = self.webView else { throw ComputerUseError.webViewNotAvailable }
            switch action {
            case "back":
                guard webView.canGoBack else { throw ComputerUseError.targetUnavailable("No previous page in browser history.") }
                try await self.loadNavigation { webView.goBack() }
            case "forward":
                guard webView.canGoForward else { throw ComputerUseError.targetUnavailable("No next page in browser history.") }
                try await self.loadNavigation { webView.goForward() }
            case "reload":
                try await self.loadNavigation { webView.reload() }
            default: throw ComputerUseError.invalidParameters
            }
            return try await self.captureBrowserAutomationResult(actionOutput: "Browser history: \(action)")
        }
    }

    private func performComputerActions(_ actions: [ComputerAction]) async throws -> ComputerActionResult {
        guard !actions.isEmpty else {
            throw ComputerUseError.invalidParameters
        }

        try await prepareWebViewForExecution()

        for action in actions {
            try await performAction(action)
            try await settleAfterAction(action)
        }

        let screenshot = try await takeScreenshot()
        let currentURL = webView?.url?.absoluteString
        let output = actions.count == 1
            ? "Dispatched action '\(actions[0].type)'. Inspect the screenshot to confirm the result."
            : "Dispatched \(actions.count) computer actions. Inspect the screenshot to confirm the result."

        return ComputerActionResult(screenshot: screenshot, currentURL: currentURL, output: output)
    }

    private func prepareWebViewForExecution() async throws {
        try Task.checkCancellation()
        if webView == nil { setupWebView() }
        guard let webView = webView else {
            throw ComputerUseError.webViewNotAvailable
        }

        // Ensure WebView is attached to window hierarchy before any actions
        // Wait up to 2 seconds for window to become available
        await MainActor.run {
            attachToWindowHierarchy()
        }

        // If still not attached after first attempt, wait and retry once
        if !didAttachToWindow {
            try await Task.sleep(for: .seconds(1))
            await MainActor.run {
                attachToWindowHierarchy()
            }

            // Final check - if still no window, we can proceed but log the issue
            if !didAttachToWindow {
                AppLogger.log("⚠️ [WebView Setup] Proceeding without window attachment - rendering may be suboptimal", category: .general, level: .warning)
            }
        }

        // Verify WebView is now properly set up
        if webView.superview == nil {
            throw ComputerUseError.webViewNotAvailable
        }
    }

    private func performAction(_ action: ComputerAction) async throws {
        try Task.checkCancellation()
        guard !execution.approvalPending else { throw ComputerUseError.approvalRequired }
        if let text = action.parameters["text"] as? String, text.utf8.count > 100_000 { throw ComputerUseError.invalidParameters }
        if let path = action.parameters["path"] as? [Any], path.count > 1_000 { throw ComputerUseError.invalidParameters }
        switch action.type {
        case "navigate":
            guard let urlString = action.parameters["url"] as? String,
                  let url = URL(string: urlString) else {
                throw ComputerUseError.invalidParameters
            }
            try await navigate(to: url)

        case "click":
            guard let x = Self.valueAsDouble(action.parameters["x"]),
                  let y = Self.valueAsDouble(action.parameters["y"]) else {
                throw ComputerUseError.invalidParameters
            }
            let buttonCode = Self.mouseButtonCode(from: action.parameters["button"])
            let modifierKeys = Self.valueAsStringArray(action.parameters["keys"])
            try await click(at: CGPoint(x: x, y: y), buttonCode: buttonCode, modifierKeys: modifierKeys)

        case "double_click":
            guard let x = Self.valueAsDouble(action.parameters["x"]),
                  let y = Self.valueAsDouble(action.parameters["y"]) else {
                throw ComputerUseError.invalidParameters
            }
            let buttonCode = Self.mouseButtonCode(from: action.parameters["button"])
            let modifierKeys = Self.valueAsStringArray(action.parameters["keys"])
            try await doubleClick(at: CGPoint(x: x, y: y), buttonCode: buttonCode, modifierKeys: modifierKeys)

        case "move":
            guard let x = Self.valueAsDouble(action.parameters["x"]),
                  let y = Self.valueAsDouble(action.parameters["y"]) else {
                throw ComputerUseError.invalidParameters
            }
            try await moveMouse(to: CGPoint(x: x, y: y))

        case "type":
            guard let text = action.parameters["text"] as? String else {
                throw ComputerUseError.invalidParameters
            }
            try await type(text: text)

        case "keypress":
            guard let keys = action.parameters["keys"] as? [String] else {
                throw ComputerUseError.invalidParameters
            }
            try await keypress(keys: keys)

        case "drag":
            guard let pathArray = action.parameters["path"] as? [[String: Any]] else {
                throw ComputerUseError.invalidParameters
            }
            let buttonCode = Self.mouseButtonCode(from: action.parameters["button"])
            let modifierKeys = Self.valueAsStringArray(action.parameters["keys"])
            try await drag(path: pathArray, buttonCode: buttonCode, modifierKeys: modifierKeys)

        case "scroll":
            if let x = Self.valueAsDouble(action.parameters["x"]),
               let y = Self.valueAsDouble(action.parameters["y"]) {
                try await moveMouse(to: CGPoint(x: x, y: y))
            }
            let scrollY = Self.valueAsDouble(action.parameters["scroll_y"]) ?? Self.valueAsDouble(action.parameters["scrollY"]) ?? 0
            let scrollX = Self.valueAsDouble(action.parameters["scroll_x"]) ?? Self.valueAsDouble(action.parameters["scrollX"]) ?? 0
            try await scroll(x: scrollX, y: scrollY)

        case "screenshot":
            if webView?.url == nil || webView?.url?.absoluteString == "about:blank" {
                if let urlString = action.parameters["url"] as? String,
                   let url = URL(string: urlString) {
                    try await navigate(to: url)
                }
            }

        case "wait":
            let msParam = Self.valueAsDouble(action.parameters["ms"]) ??
                          Self.valueAsDouble(action.parameters["milliseconds"]) ??
                          Self.valueAsDouble(action.parameters["duration"]) ??
                          Self.valueAsDouble(action.parameters["timeout"]) ??
                          Self.valueAsDouble(action.parameters["time"])
            let secParam = Self.valueAsDouble(action.parameters["seconds"]) ??
                           Self.valueAsDouble(action.parameters["secs"]) ??
                           Self.valueAsDouble(action.parameters["s"])
            let milliseconds: Double = msParam ?? (secParam != nil ? (secParam! * 1000.0) : 1000.0)
            guard milliseconds.isFinite, (0...10_000).contains(milliseconds) else { throw ComputerUseError.invalidParameters }
            let nanos = UInt64(milliseconds * 1_000_000)
            try await Task.sleep(nanoseconds: nanos)

        default:
            AppLogger.log("⚠️ [ComputerService] Unknown action type: '\(action.type)'. Attempting graceful handling.", category: .general, level: .warning)

            switch action.type.lowercased() {
            case "doubleclick", "double-click":
                guard let x = Self.valueAsDouble(action.parameters["x"]),
                      let y = Self.valueAsDouble(action.parameters["y"]) else {
                    throw ComputerUseError.invalidParameters
                }
                let buttonCode = Self.mouseButtonCode(from: action.parameters["button"])
                let modifierKeys = Self.valueAsStringArray(action.parameters["keys"])
                try await doubleClick(at: CGPoint(x: x, y: y), buttonCode: buttonCode, modifierKeys: modifierKeys)

            case "mouse_move", "mousemove", "hover":
                guard let x = Self.valueAsDouble(action.parameters["x"]),
                      let y = Self.valueAsDouble(action.parameters["y"]) else {
                    throw ComputerUseError.invalidParameters
                }
                try await moveMouse(to: CGPoint(x: x, y: y))

            default:
                throw ComputerUseError.invalidActionType(action.type)
            }
        }
    }

    private func settleAfterAction(_ action: ComputerAction) async throws {
        var extraWaitTime: UInt64 = 150_000_000
        if action.type == "click" {
            extraWaitTime = 500_000_000
        }

        try await ensureWebViewReady()
        try await waitForDomReadyAndPaint()
        try await Task.sleep(nanoseconds: extraWaitTime)
    }

    // MARK: - Private Action Implementations

    /// Navigates the web view to the specified URL.
    private func navigate(to url: URL) async throws {
        let finalURL = try BrowserNavigationPolicy.url(url.absoluteString)
        try await loadNavigation { self.webView?.load(URLRequest(url: finalURL, timeoutInterval: 20)) }
    }

    private func loadNavigation(_ load: () -> WKNavigation?) async throws {
        try Task.checkCancellation()
        let callback = BrowserCallback<Void>()
        var navigationID: ObjectIdentifier?
        try await callback.wait(timeout: .seconds(20), label: "page navigation", onInterrupt: { [weak self] in
            guard let self, let navigationID else { return }
            self.navigations.removeValue(forKey: navigationID)
            // A cancelled callback can arrive after the next operation starts loading.
            if self.activeNavigationID == navigationID {
                self.activeNavigationID = nil
                self.webView?.stopLoading()
            }
        }) { finish in
            guard let navigation = load() else {
                finish(.failure(ComputerUseError.webViewNotAvailable))
                return
            }
            navigationID = ObjectIdentifier(navigation)
            activeNavigationID = navigationID
            navigations[ObjectIdentifier(navigation)] = finish
        }
        if let pageError { throw pageError }
    }

    /// Coordinates are CSS pixels in the advertised 440 x 956 viewport. Never redirect a click
    /// to a nearby menu, consent button, or form, and never dispatch the same click twice.
    private func click(at point: CGPoint, buttonCode: Int = 0, modifierKeys: [String] = []) async throws {
        let flags = Self.mouseModifierFlags(from: modifierKeys)
        _ = try await domAction("pointClick", arguments: [
            "x": point.x, "y": point.y, "button": buttonCode,
            "ctrlKey": flags.ctrl, "metaKey": flags.meta, "altKey": flags.alt, "shiftKey": flags.shift
        ])
    }

    private func doubleClick(at point: CGPoint, buttonCode: Int = 0, modifierKeys: [String] = []) async throws {
        let flags = Self.mouseModifierFlags(from: modifierKeys)
        _ = try await domAction("pointDoubleClick", arguments: [
            "x": point.x, "y": point.y, "button": buttonCode,
            "ctrlKey": flags.ctrl, "metaKey": flags.meta, "altKey": flags.alt, "shiftKey": flags.shift
        ])
    }

    private func moveMouse(to point: CGPoint) async throws {
        _ = try await domAction("pointMove", arguments: ["x": point.x, "y": point.y])
    }

    /// Types the given text into the currently focused editable element.
    private func type(text: String) async throws {
        _ = try await domAction("type", arguments: ["text": text, "hint": "", "submit": false, "focusedOnly": true])
    }

    /// Simulates a keyboard action on the focused element.
    private func keypress(keys: [String]) async throws {
        // Handle common keyboard shortcuts via JavaScript
        let keyCombo = keys.joined(separator: "+").uppercased()
        let primaryKey = Self.normalizedKeyboardKey(keys.last ?? keys.first ?? "")
        let modifierFlags = Self.mouseModifierFlags(from: keys)

        var script = ""

        switch keyCombo {
        case "CTRL+A", "CMD+A":
            script = """
            (function() {
                var el = document.activeElement;
                if (el && (el.isContentEditable || el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                    el.select();
                    return "Selected all text in " + el.tagName;
                } else {
                    // Try to select all on the page
                    document.execCommand('selectAll');
                    return "Selected all content on page";
                }
            })();
            """
        case "CTRL+C", "CMD+C":
            script = """
            (function() {
                try {
                    document.execCommand('copy');
                    return "Copied selected content";
                } catch (e) {
                    return "Copy failed: " + e.message;
                }
            })();
            """
        case "CTRL+V", "CMD+V":
            script = """
            (function() {
                var el = document.activeElement;
                if (el && (el.isContentEditable || el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                    try {
                        if (!document.execCommand('paste')) return 'Paste failed: clipboard access unavailable';
                        return "Pasted into " + el.tagName;
                    } catch (e) {
                        return "Paste failed: " + e.message;
                    }
                } else {
                    return "No active editable element for paste";
                }
            })();
            """
        case "CTRL+Z", "CMD+Z":
            script = """
            (function() {
                try {
                    document.execCommand('undo');
                    return "Undo executed";
                } catch (e) {
                    return "Undo failed: " + e.message;
                }
            })();
            """
        case "ENTER", "RETURN":
            script = """
            (() => {
                const el = document.activeElement;
                if (!el || el === document.body) return "No active element for Enter key";
                if (el.form) {
                    if (!el.form.reportValidity()) return "Form validation prevented submission";
                    el.form.requestSubmit();
                    return "Requested form submission once";
                }
                el.dispatchEvent(new KeyboardEvent('keydown', {key:'Enter', code:'Enter', bubbles:true, cancelable:true}));
                el.dispatchEvent(new KeyboardEvent('keyup', {key:'Enter', code:'Enter', bubbles:true, cancelable:true}));
                return "Dispatched Enter key";
            })()
            """
        case "ESCAPE", "ESC":
            script = """
            (function() {
                var event = new KeyboardEvent('keydown', { key: 'Escape', keyCode: 27 });
                document.dispatchEvent(event);
                return "Escape key pressed";
            })();
            """
        case "TAB":
            script = """
            (function() {
                var event = new KeyboardEvent('keydown', { key: 'Tab', keyCode: 9 });
                document.activeElement?.dispatchEvent(event);
                return "Tab key pressed";
            })();
            """
        case "BACKSPACE":
            script = """
            (function() {
                var el = document.activeElement;
                if (el && (el.isContentEditable || el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                    var event = new KeyboardEvent('keydown', { key: 'Backspace', keyCode: 8 });
                    el.dispatchEvent(event);
                    return "Backspace pressed on " + el.tagName;
                } else {
                    return "No active editable element for Backspace";
                }
            })();
            """
        case "DELETE":
            script = """
            (function() {
                var el = document.activeElement;
                if (el && (el.isContentEditable || el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                    var event = new KeyboardEvent('keydown', { key: 'Delete', keyCode: 46 });
                    el.dispatchEvent(event);
                    return "Delete pressed on " + el.tagName;
                } else {
                    return "No active editable element for Delete";
                }
            })();
            """
        default:
            // For unhandled key combinations, try to create a basic keyboard event
            script = """
            (function() {
                var key = '\(primaryKey.sanitizedForJS())';
                var event = new KeyboardEvent('keydown', {
                    key: key,
                    ctrlKey: \(modifierFlags.ctrl),
                    metaKey: \(modifierFlags.meta),
                    altKey: \(modifierFlags.alt),
                    shiftKey: \(modifierFlags.shift)
                });
                var el = document.activeElement || document.body;
                el.dispatchEvent(event);
                return "Key combination '" + '\(keyCombo.sanitizedForJS())' + "' executed on " + el.tagName;
            })();
            """
        }

        try await evaluateActionScript(script)
    }

    /// Performs a drag gesture along the specified path
    private func drag(path: [[String: Any]], buttonCode: Int = 0, modifierKeys: [String] = []) async throws {
        let normalizedPath: [[String: Double]] = path.compactMap { point in
            guard let x = Self.valueAsDouble(point["x"]),
                  let y = Self.valueAsDouble(point["y"]) else {
                return nil
            }
            return ["x": x, "y": y]
        }

        guard normalizedPath.count >= 2 else {
            throw ComputerUseError.invalidParameters
        }

        let pathData = try JSONSerialization.data(withJSONObject: normalizedPath, options: [])
        guard let pathJSON = String(data: pathData, encoding: .utf8) else {
            throw ComputerUseError.invalidParameters
        }

        let modifierFlags = Self.mouseModifierFlags(from: modifierKeys)
        let buttonsMask = Self.mouseButtonsMask(for: buttonCode)

        let script = """
        (function() {
            var rawPath = \(pathJSON);
            var buttonCode = \(buttonCode);
            var buttonsMask = \(buttonsMask);
            var ctrlKey = \(modifierFlags.ctrl ? "true" : "false");
            var metaKey = \(modifierFlags.meta ? "true" : "false");
            var altKey = \(modifierFlags.alt ? "true" : "false");
            var shiftKey = \(modifierFlags.shift ? "true" : "false");
            var dpr = (window.devicePixelRatio || 1);
            var vw = window.innerWidth || document.documentElement.clientWidth || 0;
            var vh = window.innerHeight || document.documentElement.clientHeight || 0;
            if (rawPath.some(p => !Number.isFinite(p.x) || !Number.isFinite(p.y) || p.x < 0 || p.x >= vw || p.y < 0 || p.y >= vh)) return "No valid drag path: coordinates must be in the current viewport";
            function normX(v){ return v; }
            function normY(v){ return v; }
            var points = rawPath.map(function(point) {
                return { x: normX(point.x), y: normY(point.y) };
            });
            var start = points[0];
            var end = points[points.length - 1];

            var startElement = document.elementFromPoint(start.x, start.y);
            if (!startElement) {
                return "No element found at start point (" + start.x + ", " + start.y + ")";
            }

            // Create mouse events for drag operation
            var mouseDownEvent = new MouseEvent('mousedown', {
                bubbles: true,
                cancelable: true,
                clientX: start.x,
                clientY: start.y,
                button: buttonCode,
                buttons: buttonsMask,
                ctrlKey: ctrlKey,
                metaKey: metaKey,
                altKey: altKey,
                shiftKey: shiftKey
            });

            var mouseUpEvent = new MouseEvent('mouseup', {
                bubbles: true,
                cancelable: true,
                clientX: end.x,
                clientY: end.y,
                button: buttonCode,
                buttons: 0,
                ctrlKey: ctrlKey,
                metaKey: metaKey,
                altKey: altKey,
                shiftKey: shiftKey
            });

            // Execute drag sequence
            startElement.dispatchEvent(mouseDownEvent);

            // Replay the full model-provided path instead of reducing it to a straight line.
            for (var i = 1; i < points.length; i++) {
                var point = points[i];
                var moveEvent = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    clientX: point.x,
                    clientY: point.y,
                    button: buttonCode,
                    buttons: buttonsMask,
                    ctrlKey: ctrlKey,
                    metaKey: metaKey,
                    altKey: altKey,
                    shiftKey: shiftKey
                });
                document.dispatchEvent(moveEvent);
            }

            var endElement = document.elementFromPoint(end.x, end.y);
            if (endElement) {
                endElement.dispatchEvent(mouseUpEvent);
            } else {
                document.dispatchEvent(mouseUpEvent);
            }

            return "Drag from (" + start.x + ", " + start.y + ") to (" + end.x + ", " + end.y + ") completed via " + points.length + " points";
        })();
        """

        try await evaluateActionScript(script)
    }

    /// Scrolls the web page vertically by a given amount.
    private func scroll(x: Double, y: Double) async throws {
        let script = "window.scrollBy(\(x), \(y));"
        try await evaluateActionScript(script)
    }

    /// Scrolls to the very bottom of the page deterministically.
    /// Uses `document.scrollingElement` (fallbacks to body) to compute scroll height.
    func scrollToBottom() async throws {
        let js = """
        (function(){
            try {
                var el = document.scrollingElement || document.documentElement || document.body;
                var maxY = Math.max(el.scrollHeight || 0, document.body.scrollHeight || 0, document.documentElement.scrollHeight || 0);
                window.scrollTo({ top: maxY, left: 0, behavior: 'auto' });
                return 'Scrolled to bottom: ' + maxY;
            } catch (e) { return 'ScrollToBottom error: ' + e.message; }
        })();
        """
        _ = try await evaluateJavaScript(js)
        // Give layout/render a brief moment, then ensure we have a paint before screenshot
        try await Task.sleep(nanoseconds: 250_000_000)
        try await waitForDomReadyAndPaint()
    }

    /// Captures a screenshot of the web view's visible content.
    private func takeScreenshot() async throws -> String? {
        try Task.checkCancellation()
        guard let webView else { throw ComputerUseError.webViewNotAvailable }
        webView.layoutIfNeeded()
        let config = WKSnapshotConfiguration()
        config.afterScreenUpdates = true
        config.snapshotWidth = NSNumber(value: 440)
        // A read-only snapshot may be retried; failed writes are never replayed.
        for attempt in 0..<2 {
            do {
                return try await boundedCallback(label: "browser screenshot") { finish in
                    webView.takeSnapshot(with: config) { image, error in
                        if let error { finish(.failure(error)); return }
                        guard let image, image.size.width > 0, image.size.height > 0 else {
                            finish(.failure(ComputerUseError.screenshotFailed)); return
                        }
                        // WKSnapshotConfiguration uses points; PNG encodes device pixels (3x on
                        // modern iPhones). Match the tool's 440 x 956 coordinate space exactly.
                        let size = CGSize(width: 440, height: 956)
                        let format = UIGraphicsImageRendererFormat()
                        format.scale = 1
                        format.opaque = true
                        let normalized = UIGraphicsImageRenderer(size: size, format: format).image { context in
                            UIColor.white.setFill()
                            context.fill(CGRect(origin: .zero, size: size))
                            image.draw(in: CGRect(origin: .zero, size: size))
                        }
                        guard let data = normalized.pngData(), !data.isEmpty else {
                            finish(.failure(ComputerUseError.screenshotFailed)); return
                        }
                        finish(.success(data.base64EncodedString()))
                    }
                }
            } catch {
                try Task.checkCancellation()
                if let pageError { throw pageError }
                if attempt == 1 { throw ComputerUseError.screenshotFailed }
                try await Task.sleep(for: .milliseconds(200))
            }
        }
        throw ComputerUseError.screenshotFailed
    }

    nonisolated static func searchResultsURL(for currentURL: URL?, query: String) -> URL? {
        guard let host = currentURL?.host?.lowercased() else { return nil }
        return searchResultsURL(forHost: host, query: query)
    }

    nonisolated static func searchResultsURL(forSiteKeyword keyword: String, query: String) -> URL? {
        searchResultsURL(forHost: keyword.lowercased(), query: query)
    }

    private nonisolated static func searchResultsURL(forHost host: String, query: String) -> URL? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return nil }
        let destinations: [(String, String, String)] = [
            ("google", "https://www.google.com/search", "q"),
            ("bing", "https://www.bing.com/search", "q"),
            ("duckduckgo", "https://duckduckgo.com/", "q"),
            ("amazon", "https://www.amazon.com/s", "k"),
            ("youtube", "https://www.youtube.com/results", "search_query"),
            ("github", "https://github.com/search", "q")
        ]
        let normalized = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard let destination = destinations.first(where: { name, _, _ in
            normalized == name || normalized == name + ".com" || normalized.hasSuffix("." + name + ".com")
                || (name == "google" && ["google.co.uk", "www.google.co.uk"].contains(normalized))
        }) else { return nil }
        var components = URLComponents(string: destination.1)
        components?.queryItems = [URLQueryItem(name: destination.2, value: trimmedQuery)]
        let encodedQuery = components?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components?.percentEncodedQuery = encodedQuery
        return components?.url
    }

    private func browserNavigate(to value: String) async throws -> BrowserAutomationResult {
        let url = try BrowserNavigationPolicy.url(value)
        try await prepareWebViewForExecution()
        try await navigate(to: url)
        return try await captureBrowserAutomationResult(actionOutput: "Navigated to \(url.absoluteString)")
    }

    private func browserSearch(query: String, site: String?) async throws -> BrowserAutomationResult {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = directSearchURL(query: query, site: site) else { throw ComputerUseError.invalidParameters }
        try await prepareWebViewForExecution()
        try await navigate(to: url)
        return try await captureBrowserAutomationResult(actionOutput: "Opened search results")
    }

    private func browserScroll(direction: String, amount: Int?) async throws -> BrowserAutomationResult {
        try await prepareWebViewForExecution()
        let normalized = direction.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard ["up", "down"].contains(normalized), amount == nil || (1...2400).contains(amount!) else {
            throw ComputerUseError.invalidParameters
        }
        let distance = amount ?? 700
        try await scroll(x: 0, y: Double(normalized == "up" ? -distance : distance))
        return try await captureBrowserAutomationResult(actionOutput: "Scrolled \(normalized) by \(distance) points")
    }

    private func directSearchURL(query: String, site: String?) -> URL? {
        let site = site?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !site.isEmpty {
            if let direct = Self.searchResultsURL(forSiteKeyword: site, query: query) { return direct }
            guard let url = try? BrowserNavigationPolicy.url(site), let host = url.host else { return nil }
            if let direct = Self.searchResultsURL(for: url, query: query) { return direct }
            return Self.searchResultsURL(forSiteKeyword: "google", query: "site:" + host + " " + query)
        }
        return Self.searchResultsURL(for: webView?.url, query: query)
            ?? Self.searchResultsURL(forSiteKeyword: "google", query: query)
    }

    private func captureBrowserAutomationResult(actionOutput: String?) async throws -> BrowserAutomationResult {
        try await prepareWebViewForExecution()
        try await ensureWebViewReady()

        if let webView,
           webView.isLoading || webView.estimatedProgress < 0.85 {
            try await waitForNavigationToSettle()
        }

        try await waitForDomReadyAndPaint()

        var state = try await readBrowserPageState()
        state.httpStatus = lastHTTPStatus
        let screenshot = try await takeScreenshot()
        let currentURL = state.url ?? webView?.url?.absoluteString

        let output = [actionOutput, recoveryNotice].compactMap { $0 }.joined(separator: " ")
        recoveryNotice = nil
        return BrowserAutomationResult(
            state: state,
            screenshot: screenshot,
            currentURL: currentURL,
            output: output
        )
    }

    private func readBrowserPageState() async throws -> BrowserPageState {
        let value = try await evaluateJavaScript(BrowserDOM.script(action: "read", arguments: ["snapshotId": UUID().uuidString]))
        guard let object = value.value as? [String: Any] else { throw ComputerUseError.invalidResponse }
        return try JSONDecoder().decode(BrowserPageState.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func domAction(_ action: String, arguments: [String: Any]) async throws -> String {
        let result = try await evaluateJavaScript(BrowserDOM.script(action: action, arguments: arguments))
        guard let object = result.value as? [String: Any], let success = object["ok"] as? Bool else {
            throw ComputerUseError.invalidResponse
        }
        let message = object["message"] as? String ?? "Browser action failed. Read the page before retrying."
        guard success else { throw ComputerUseError.targetUnavailable(message) }
        return message
    }

    private func evaluateActionScript(_ script: String) async throws {
        let value = try await evaluateJavaScript(script)
        if let message = value.value as? String {
            let normalized = message.lowercased()
            if normalized.hasPrefix("no ") || normalized.contains("failed") || normalized.hasPrefix("unsupported") {
                throw ComputerUseError.targetUnavailable(message)
            }
        }
    }

    private func boundedCallback<T>(label: String, start: (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
        try Task.checkCancellation()
        let id = UUID()
        let callback = BrowserCallback<T>()
        defer { pendingCallbacks.removeValue(forKey: id) }
        return try await callback.wait(timeout: .seconds(6), label: label) { finish in
            pendingCallbacks[id] = { finish(.failure($0)) }
            start(finish)
        }
    }

    private func evaluateJavaScript(_ script: String) async throws -> JavaScriptResult {
        try Task.checkCancellation()
        guard let webView else { throw ComputerUseError.webViewNotAvailable }
        if let pageError { throw pageError }
        return try await boundedCallback(label: "page script") { finish in
            webView.evaluateJavaScript(script, in: nil, in: automationWorld) { result in
                finish(result.map { JavaScriptResult(value: $0) })
            }
        }
    }

    private func ensureWebViewReady() async throws {
        try Task.checkCancellation()
        guard let webView else { throw ComputerUseError.webViewNotAvailable }
        if webView.url == nil && !webView.isLoading {
            try await loadNavigation { webView.loadHTMLString("<html><head><meta name='viewport' content='width=device-width, initial-scale=1'></head><body></body></html>", baseURL: nil) }
        }
    }

    /// Wait for a stable, usable document, rather than treating estimated download progress as readiness.
    private func waitForNavigationToSettle(timeoutMs: Int = 5000, minimumProgress: Double = 0.85) async throws {
        try await waitForDomReadyAndPaint(timeoutMs: timeoutMs)
    }

    private func waitForDomReadyAndPaint(timeoutMs: Int = 5000) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .milliseconds(timeoutMs))
        var previous: String?
        var stableSince = clock.now
        while clock.now < deadline {
            try Task.checkCancellation()
            let result = try await evaluateJavaScript("""
            (() => {
              if (!document.body || document.readyState === 'loading' || innerWidth <= 0) return null;
              return JSON.stringify([location.href, document.readyState, document.body.scrollHeight,
                document.body.innerText.length, document.querySelectorAll('a,button,input').length]);
            })()
            """)
            let state = result.value as? String
            if state != nil && state == previous {
                if stableSince.duration(to: clock.now) >= .milliseconds(300) {
                    // callAsyncJavaScript awaits promises; evaluateJavaScript(requestAnimationFrame(...)) does not.
                    guard let webView else { throw ComputerUseError.webViewNotAvailable }
                    let _: JavaScriptResult = try await boundedCallback(label: "page paint") { finish in
                        webView.callAsyncJavaScript("await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))); return true;", arguments: [:], in: nil, in: automationWorld) { result in
                            finish(result.map { JavaScriptResult(value: $0) })
                        }
                    }
                    return
                }
            } else { previous = state; stableSince = clock.now }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw ComputerUseError.timedOut("stable page content")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard self.webView === webView, let navigation else { return }
        if activeNavigationID == ObjectIdentifier(navigation) { activeNavigationID = nil }
        navigations.removeValue(forKey: ObjectIdentifier(navigation))?(.success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard self.webView === webView, let navigation else { return }
        if activeNavigationID == ObjectIdentifier(navigation) { activeNavigationID = nil }
        navigations.removeValue(forKey: ObjectIdentifier(navigation))?(.failure(pageError ?? ComputerUseError.navigationFailed(error)))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView(webView, didFail: navigation, withError: error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard self.webView === webView else { decisionHandler(.cancel); return }
        guard !execution.approvalPending else { decisionHandler(.cancel); return }
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        // The empty document is generated internally, never accepted by browserNavigate.
        if url.absoluteString == "about:blank" { decisionHandler(.allow); return }
        do {
            try BrowserNavigationPolicy.validate(url)
            if navigationAction.targetFrame?.isMainFrame != false { try navigationPolicy.admit(url) }
            decisionHandler(.allow)
        } catch {
            if navigationAction.targetFrame?.isMainFrame != false { pageError = error }
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Follow ordinary target=_blank links in the same persistent session.
        guard self.webView === webView, !execution.approvalPending, navigationAction.targetFrame == nil,
              let url = navigationAction.request.url else { return nil }
        do { try navigationPolicy.admit(url); webView.load(navigationAction.request) }
        catch { pageError = error }
        return nil
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard self.webView === webView, let url = webView.url else { return }
        do { try navigationPolicy.admit(url) }
        catch {
            pageError = error
            webView.stopLoading()
            failPendingCallbacks(error)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard self.webView === webView else { decisionHandler(.cancel); return }
        if navigationResponse.isForMainFrame {
            lastHTTPStatus = (navigationResponse.response as? HTTPURLResponse)?.statusCode
            if !navigationResponse.canShowMIMEType {
                let error = ComputerUseError.targetUnavailable("This destination is a download the browser cannot display. Open or import the file explicitly.")
                pageError = error
                decisionHandler(.cancel)
                failPendingCallbacks(error)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard self.webView === webView else { return }
        pageError = ComputerUseError.processTerminated
        execution.abort(ComputerUseError.processTerminated)
        lastHTTPStatus = nil
        recoveryNotice = "The browser restarted after its content process stopped. The interrupted action was not replayed."
        failPendingCallbacks(ComputerUseError.processTerminated)
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
        self.webView = nil
        unregisterAttachObservers()
        // Recreate lazily on the next action. Never replay the interrupted action.
    }
}

// MARK: - Test detection helpers

private extension ComputerService {
    /// Determines whether the service should automatically attach a WebView.
    /// We disable auto-attach when running inside XCTest to avoid simulator crashes during CI.
    nonisolated static func shouldAutoAttachWebView() -> Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }
}

// MARK: - String Extension

// MARK: - Helpers

extension ComputerService {
    /// Coerces a heterogenous value (Int/Double/Float/String) into a Double.
    /// Returns nil if the value cannot be interpreted as a number.
    fileprivate nonisolated static func valueAsDouble(_ value: Any?) -> Double? {
        switch value {
        case let d as Double: return d
        case let i as Int: return Double(i)
        case let f as Float: return Double(f)
        case let s as String:
            // Allow numeric strings like "12" or "12.34"
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        default: return nil
        }
    }

    /// Coerces array-like key inputs from the Responses API into a `[String]`.
    fileprivate nonisolated static func valueAsStringArray(_ value: Any?) -> [String] {
        switch value {
        case let strings as [String]:
            return strings
        case let values as [Any]:
            return values.compactMap { value in
                if let string = value as? String { return string }
                return nil
            }
        case let string as String:
            return [string]
        default:
            return []
        }
    }

    fileprivate nonisolated static func mouseButtonCode(from value: Any?) -> Int {
        let normalized: String
        if let string = value as? String {
            normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else if let number = valueAsDouble(value) {
            switch Int(number) {
            case 1: return 1
            case 2: return 2
            default: return 0
            }
        } else {
            normalized = "left"
        }

        switch normalized {
        case "middle", "aux", "auxiliary", "wheel", "1":
            return 1
        case "right", "secondary", "context", "2":
            return 2
        default:
            return 0
        }
    }

    fileprivate nonisolated static func mouseButtonsMask(for buttonCode: Int) -> Int {
        switch buttonCode {
        case 1: return 4
        case 2: return 2
        default: return 1
        }
    }

    fileprivate nonisolated static func mouseModifierFlags(from keys: [String]) -> (ctrl: Bool, meta: Bool, alt: Bool, shift: Bool) {
        let normalized = Set(keys.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() })
        return (
            ctrl: normalized.contains("CTRL") || normalized.contains("CONTROL"),
            meta: normalized.contains("CMD") || normalized.contains("COMMAND") || normalized.contains("META") || normalized.contains("SUPER"),
            alt: normalized.contains("ALT") || normalized.contains("OPTION"),
            shift: normalized.contains("SHIFT")
        )
    }

    fileprivate nonisolated static func normalizedKeyboardKey(_ rawKey: String) -> String {
        let normalized = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized.uppercased() {
        case "ENTER", "RETURN": return "Enter"
        case "SPACE", "SPACEBAR": return " "
        case "ESC", "ESCAPE": return "Escape"
        case "TAB": return "Tab"
        case "BACKSPACE": return "Backspace"
        case "DELETE", "DEL": return "Delete"
        case "ARROWLEFT", "LEFT": return "ArrowLeft"
        case "ARROWRIGHT", "RIGHT": return "ArrowRight"
        case "ARROWUP", "UP": return "ArrowUp"
        case "ARROWDOWN", "DOWN": return "ArrowDown"
        case "HOME": return "Home"
        case "END": return "End"
        case "PAGEUP", "PGUP": return "PageUp"
        case "PAGEDOWN", "PGDN": return "PageDown"
        case "CTRL", "CONTROL": return "Control"
        case "CMD", "COMMAND", "META", "SUPER": return "Meta"
        case "ALT", "OPTION": return "Alt"
        case "SHIFT": return "Shift"
        default: return normalized
        }
    }
}

extension String {
    /// Sanitizes a string for safe insertion into a JavaScript literal.
    func sanitizedForJS() -> String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}

#if DEBUG
extension ComputerService {
    nonisolated static func testing_searchResultsURL(currentURL: String, query: String) -> String? {
        searchResultsURL(for: URL(string: currentURL), query: query)?.absoluteString
    }

    nonisolated static func testing_searchResultsURL(siteKeyword: String, query: String) -> String? {
        searchResultsURL(forSiteKeyword: siteKeyword, query: query)?.absoluteString
    }

    nonisolated static func testing_mouseButtonCode(_ value: Any?) -> Int {
        mouseButtonCode(from: value)
    }

    nonisolated static func testing_mouseButtonsMask(for buttonCode: Int) -> Int {
        mouseButtonsMask(for: buttonCode)
    }

    nonisolated static func testing_mouseModifierFlags(keys: [String]) -> [String: Bool] {
        let flags = mouseModifierFlags(from: keys)
        return [
            "ctrl": flags.ctrl,
            "meta": flags.meta,
            "alt": flags.alt,
            "shift": flags.shift,
        ]
    }

    nonisolated static func testing_normalizedKeyboardKey(_ rawKey: String) -> String {
        normalizedKeyboardKey(rawKey)
    }
}
#endif
