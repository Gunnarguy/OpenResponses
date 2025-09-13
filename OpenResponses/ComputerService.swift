import Foundation
import WebKit
import Combine
import UIKit

/// A service that provides native, on-device browser automation capabilities.
///
/// This class manages an off-screen `WKWebView` instance to perform actions requested by the AI model,
/// such as navigating to URLs, clicking elements, typing text, and taking screenshots. It acts as a
/// local replacement for the previous server-based Playwright implementation.
///
/// The service is designed to be run on the main actor as it interacts with `WKWebView`, a UI component.
@MainActor
class ComputerService: NSObject, WKNavigationDelegate {
    
    private var webView: WKWebView?
    
    // Continuations to bridge delegate-based asynchronous operations with async/await.
    private var navigationContinuation: CheckedContinuation<Void, Error>?
    private var javascriptContinuation: CheckedContinuation<Any?, Error>?
    
    override init() {
        super.init()
        setupWebView()
    }

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
        webView?.isOpaque = false
        webView?.backgroundColor = .white
        webView?.scrollView.backgroundColor = .white
        webView?.scrollView.isScrollEnabled = true
        // Present as iPhone Safari to encourage mobile layouts that match our tool display
        webView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        // Defer window attachment until later if no key window is available during initialization
        attachToWindowHierarchy()
    }
    
    /// Attempts to attach the WebView to the window hierarchy for proper rendering
    private func attachToWindowHierarchy() {
        guard let webView = webView else { return }
        
        // Skip if already attached
        if webView.superview != nil {
            return
        }
        
        // Try to find key window in all connected scenes
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = windowScenes.compactMap { $0.windows.first(where: { $0.isKeyWindow }) }.first
        
        if let window = keyWindow {
            // IMPORTANT: Keep the webView within window bounds so WebKit renders paint frames.
            // We make it non-interactive and nearly transparent so it won't affect UX.
            webView.alpha = 0.01 // Low alpha still renders; alpha=0 may skip rendering on some devices
            webView.isHidden = false // Must not be hidden for reliable snapshots
            webView.isUserInteractionEnabled = false // Do not intercept touches
            webView.accessibilityElementsHidden = true // Keep it out of accessibility focus
            window.addSubview(webView)
            
            // Force layout after adding to window
            webView.setNeedsLayout()
            webView.layoutIfNeeded()
            
            AppLogger.log("✅ [WebView Setup] Successfully attached WebView to key window", category: .general, level: .info)
        } else {
            AppLogger.log("⚠️ [WebView Setup] No key window available yet - will retry during first action", category: .general, level: .warning)
        }
    }
    
    /// Executes a given `ComputerAction` and returns the result.
    ///
    /// This is the main entry point for the service. It takes an action decoded from a tool call,
    /// executes it, and then captures a screenshot and the current URL to be sent back to the model.
    /// - Parameter action: The `ComputerAction` to perform.
    /// - Returns: A `ComputerActionResult` containing a screenshot and other metadata.
    func executeAction(_ action: ComputerAction) async throws -> ComputerActionResult {
        guard let webView = webView else {
            throw ComputerUseError.webViewNotAvailable
        }
        
        // Ensure WebView is attached to window hierarchy before any actions
        await MainActor.run {
            attachToWindowHierarchy()
        }
        
        // Verify WebView is now properly set up
        if webView.superview == nil {
            throw ComputerUseError.webViewNotAvailable
        }
        
        // Perform the requested action.
        switch action.type {
        case "navigate":
            guard let urlString = action.parameters["url"] as? String, let url = URL(string: urlString) else {
                throw ComputerUseError.invalidParameters
            }
            try await navigate(to: url)
            
        case "click":
            // Accept Int/Double (or numeric strings) for coordinates.
            guard let x = Self.valueAsDouble(action.parameters["x"]),
                  let y = Self.valueAsDouble(action.parameters["y"]) else {
                throw ComputerUseError.invalidParameters
            }
            try await click(at: CGPoint(x: x, y: y))
            
        case "double_click":
            // Double click at coordinates
            guard let x = Self.valueAsDouble(action.parameters["x"]),
                  let y = Self.valueAsDouble(action.parameters["y"]) else {
                throw ComputerUseError.invalidParameters
            }
            try await doubleClick(at: CGPoint(x: x, y: y))
            
        case "move":
            // Move mouse to coordinates (simulate hover)
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
            // Handle drag actions with path coordinates
            guard let pathArray = action.parameters["path"] as? [[String: Any]] else {
                throw ComputerUseError.invalidParameters
            }
            try await drag(path: pathArray)
            
        case "scroll":
            // Support both "scrollY" and shorthand "y"; default X to 0.
            let scrollY = Self.valueAsDouble(action.parameters["scrollY"]) ?? Self.valueAsDouble(action.parameters["y"]) ?? 0
            let scrollX = Self.valueAsDouble(action.parameters["scrollX"]) ?? Self.valueAsDouble(action.parameters["x"]) ?? 0
            try await scroll(x: scrollX, y: scrollY)
            
        case "screenshot":
            // If no page is loaded yet, attempt to navigate to a sensible URL if provided in parameters.
            // This helps when the model issues a bare "screenshot" as the first action.
            if webView.url == nil || webView.url?.absoluteString == "about:blank" {
                if let urlString = action.parameters["url"] as? String, let url = URL(string: urlString) {
                    try await navigate(to: url)
                } else {
                    // Create a simple HTML page asking which website to visit
                    print("🌐 [Navigation Fallback] AI requested screenshot without navigation. Showing help page.")
                    let helpHTML = """
                    <!DOCTYPE html>
                    <html><head><title>Where would you like to go?</title>
                    <style>body{font-family:system-ui;padding:40px;text-align:center;background:#f5f5f5;}
                    h1{color:#333;}.suggestion{margin:10px;padding:15px;background:white;border-radius:8px;display:inline-block;}
                    .warning{color:#d73502;font-weight:bold;margin:20px;}
                    </style></head>
                    <body>
                    <h1>🚫 USE NAVIGATE ACTION</h1>
                    <div class="warning">DO NOT CLICK - Use navigate action instead:</div>
                    <p>{"type": "navigate", "parameters": {"url": "https://google.com"}}</p>
                    <div class="suggestion">Navigate to Google</div>
                    <div class="suggestion">Navigate to YouTube</div>
                    <div class="suggestion">Navigate to Amazon</div>
                    </body></html>
                    """
                    webView.loadHTMLString(helpHTML, baseURL: nil)
                    // Wait a moment for the HTML to load
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }
            }
            // Otherwise, a screenshot simply captures the current state.
            break
        case "wait":
            // Pause execution for a short duration to allow the page/UI to settle, then continue.
            // Accept either milliseconds (ms) or seconds parameters; default to 1s if unspecified.
            // Also accept keys like "duration", "timeout", or "time" (milliseconds).
            let msParam = Self.valueAsDouble(action.parameters["ms"]) ??
                          Self.valueAsDouble(action.parameters["milliseconds"]) ??
                          Self.valueAsDouble(action.parameters["duration"]) ??
                          Self.valueAsDouble(action.parameters["timeout"]) ??
                          Self.valueAsDouble(action.parameters["time"]) // assume ms
            let secParam = Self.valueAsDouble(action.parameters["seconds"]) ??
                           Self.valueAsDouble(action.parameters["secs"]) ??
                           Self.valueAsDouble(action.parameters["s"]) // seconds
            let milliseconds: Double = msParam ?? (secParam != nil ? (secParam! * 1000.0) : 1000.0)
            let nanos = UInt64(milliseconds * 1_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            
        default:
            // Instead of throwing an error for unknown actions, log and gracefully handle
            AppLogger.log("⚠️ [ComputerService] Unknown action type: '\(action.type)'. Attempting graceful handling.", category: .general, level: .warning)
            
            // Try to handle some common action variations that might not be in our switch
            switch action.type.lowercased() {
            case "doubleclick", "double-click":
                // Handle variations of double_click
                guard let x = Self.valueAsDouble(action.parameters["x"]),
                      let y = Self.valueAsDouble(action.parameters["y"]) else {
                    throw ComputerUseError.invalidParameters
                }
                try await doubleClick(at: CGPoint(x: x, y: y))
            case "mouse_move", "mousemove", "hover":
                // Handle variations of move
                guard let x = Self.valueAsDouble(action.parameters["x"]),
                      let y = Self.valueAsDouble(action.parameters["y"]) else {
                    throw ComputerUseError.invalidParameters
                }
                try await moveMouse(to: CGPoint(x: x, y: y))
            default:
                // For truly unknown actions, return a meaningful result instead of crashing
                AppLogger.log("❌ [ComputerService] Unsupported action type: '\(action.type)'. Returning screenshot of current state.", category: .general, level: .error)
                // Don't throw - just continue to screenshot to show current state
            }
        }
        
        // After any action, wait for content to be ready and then take a screenshot.
        // Ensure the web view has rendered at least once before snapshot
        try await ensureWebViewReady()
        try await waitForDomReadyAndPaint()
        try? await Task.sleep(nanoseconds: 150_000_000) // small settle before snapshot
        let screenshot = try await takeScreenshot()
        let currentURL = webView.url?.absoluteString
        
        return ComputerActionResult(screenshot: screenshot, currentURL: currentURL, output: "Action '\(action.type)' completed successfully.")
    }
    
    // MARK: - Private Action Implementations
    
    /// Navigates the web view to the specified URL.
    private func navigate(to url: URL) async throws {
        // Ensure a valid scheme; default to https if missing
        let finalURL: URL = {
            if url.scheme == nil || url.scheme?.isEmpty == true {
                return URL(string: "https://\(url.absoluteString)") ?? url
            }
            return url
        }()
        print("🌐 [Navigation Debug] Starting navigation to: \(finalURL.absoluteString)")
        try await withCheckedThrowingContinuation { continuation in
            self.navigationContinuation = continuation
            self.webView?.load(URLRequest(url: finalURL))
        }
        print("🌐 [Navigation Debug] Navigation completed to: \(webView?.url?.absoluteString ?? "unknown")")
    }
    
    /// Simulates a click at a specific point on the web page.
    private func click(at point: CGPoint) async throws {
        let script = """
        (function() {
            var el = document.elementFromPoint(\(point.x), \(point.y));
            if (el) {
                el.focus();
                el.click();
                return "Clicked element: " + el.tagName;
            }
            return "No element found at point.";
        })();
        """
        _ = try await evaluateJavaScript(script)
    }
    
    /// Simulates a double-click at a specific point on the web page.
    private func doubleClick(at point: CGPoint) async throws {
        let script = """
        (function() {
            var el = document.elementFromPoint(\(point.x), \(point.y));
            if (el) {
                el.focus();
                var event = new MouseEvent('dblclick', {
                    bubbles: true,
                    cancelable: true,
                    clientX: \(point.x),
                    clientY: \(point.y),
                    button: 0
                });
                el.dispatchEvent(event);
                return "Double-clicked element: " + el.tagName;
            }
            return "No element found at point for double-click.";
        })();
        """
        _ = try await evaluateJavaScript(script)
    }
    
    /// Simulates moving the mouse to a specific point (hover effect).
    private func moveMouse(to point: CGPoint) async throws {
        let script = """
        (function() {
            var el = document.elementFromPoint(\(point.x), \(point.y));
            if (el) {
                var event = new MouseEvent('mouseover', {
                    bubbles: true,
                    cancelable: true,
                    clientX: \(point.x),
                    clientY: \(point.y)
                });
                el.dispatchEvent(event);
                
                var moveEvent = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    clientX: \(point.x),
                    clientY: \(point.y)
                });
                el.dispatchEvent(moveEvent);
                
                return "Moved mouse to element: " + el.tagName;
            }
            return "No element found at point for mouse move.";
        })();
        """
        _ = try await evaluateJavaScript(script)
    }
    
    /// Types the given text into the currently focused editable element.
    private func type(text: String) async throws {
        let script = """
        (function() {
            var el = document.activeElement;
            if (el && (el.isContentEditable || el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                el.value += '\(text.sanitizedForJS())';
                return "Typed text into " + el.tagName;
            }
            return "No active editable element found.";
        })();
        """
        _ = try await evaluateJavaScript(script)
    }
    
    /// Simulates key press combinations like Ctrl+A, Ctrl+C, etc.
    private func keypress(keys: [String]) async throws {
        // Handle common keyboard shortcuts via JavaScript
        let keyCombo = keys.joined(separator: "+").uppercased()
        
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
                        document.execCommand('paste');
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
            (function() {
                var el = document.activeElement;
                if (el) {
                    var event = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13 });
                    el.dispatchEvent(event);
                    var event2 = new KeyboardEvent('keyup', { key: 'Enter', keyCode: 13 });
                    el.dispatchEvent(event2);
                    return "Enter key pressed on " + el.tagName;
                } else {
                    return "No active element for Enter key";
                }
            })();
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
            let primaryKey = keys.last ?? keys.first ?? ""
            script = """
            (function() {
                var key = '\(primaryKey.sanitizedForJS())';
                var event = new KeyboardEvent('keydown', { 
                    key: key,
                    ctrlKey: \(keys.contains { $0.uppercased() == "CTRL" }),
                    metaKey: \(keys.contains { $0.uppercased() == "CMD" || $0.uppercased() == "META" }),
                    altKey: \(keys.contains { $0.uppercased() == "ALT" }),
                    shiftKey: \(keys.contains { $0.uppercased() == "SHIFT" })
                });
                var el = document.activeElement || document.body;
                el.dispatchEvent(event);
                return "Key combination '" + '\(keyCombo.sanitizedForJS())' + "' executed on " + el.tagName;
            })();
            """
        }
        
        _ = try await evaluateJavaScript(script)
    }
    
    /// Performs a drag gesture along the specified path
    private func drag(path: [[String: Any]]) async throws {
        guard path.count >= 2 else {
            throw ComputerUseError.invalidParameters
        }
        
        // Extract start and end points from path
        guard let startDict = path.first,
              let endDict = path.last,
              let startX = Self.valueAsDouble(startDict["x"]),
              let startY = Self.valueAsDouble(startDict["y"]),
              let endX = Self.valueAsDouble(endDict["x"]),
              let endY = Self.valueAsDouble(endDict["y"]) else {
            throw ComputerUseError.invalidParameters
        }
        
        let script = """
        (function() {
            var startX = \(startX);
            var startY = \(startY);
            var endX = \(endX);
            var endY = \(endY);
            
            var startElement = document.elementFromPoint(startX, startY);
            if (!startElement) {
                return "No element found at start point (" + startX + ", " + startY + ")";
            }
            
            // Create mouse events for drag operation
            var mouseDownEvent = new MouseEvent('mousedown', {
                bubbles: true,
                cancelable: true,
                clientX: startX,
                clientY: startY,
                button: 0
            });
            
            var mouseMoveEvent = new MouseEvent('mousemove', {
                bubbles: true,
                cancelable: true,
                clientX: endX,
                clientY: endY,
                button: 0
            });
            
            var mouseUpEvent = new MouseEvent('mouseup', {
                bubbles: true,
                cancelable: true,
                clientX: endX,
                clientY: endY,
                button: 0
            });
            
            // Execute drag sequence
            startElement.dispatchEvent(mouseDownEvent);
            
            // Simulate movement with multiple intermediate points for smoother drag
            var steps = 5;
            for (var i = 1; i <= steps; i++) {
                var x = startX + (endX - startX) * (i / steps);
                var y = startY + (endY - startY) * (i / steps);
                var moveEvent = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    clientX: x,
                    clientY: y,
                    button: 0
                });
                document.dispatchEvent(moveEvent);
            }
            
            var endElement = document.elementFromPoint(endX, endY);
            if (endElement) {
                endElement.dispatchEvent(mouseUpEvent);
            } else {
                document.dispatchEvent(mouseUpEvent);
            }
            
            return "Drag from (" + startX + ", " + startY + ") to (" + endX + ", " + endY + ") completed";
        })();
        """
        
        _ = try await evaluateJavaScript(script)
    }
    
    /// Scrolls the web page vertically by a given amount.
    private func scroll(x: Double, y: Double) async throws {
        let script = "window.scrollBy(\(x), \(y));"
        _ = try await evaluateJavaScript(script)
    }
    
    /// Captures a screenshot of the web view's visible content.
    private func takeScreenshot() async throws -> String? {
        guard let webView = webView else { throw ComputerUseError.webViewNotAvailable }
        
        // Debug: Log webview state before screenshot
        print("📸 [Screenshot Debug] WebView state: frame=\(webView.frame), url=\(webView.url?.absoluteString ?? "nil"), isLoading=\(webView.isLoading)")
        print("📸 [Screenshot Debug] WebView estimated progress: \(webView.estimatedProgress)")
        
        // Critical: Temporarily restore alpha to 1.0 for screenshot capture
        let originalAlpha = webView.alpha
        webView.alpha = 1.0
        
        // Critical: Verify WebView has proper dimensions before screenshot
        if webView.frame.width <= 0 || webView.frame.height <= 0 {
            print("📸 [Screenshot Debug] WebView has invalid frame dimensions: \(webView.frame)")
            
            // Try to fix the frame
            let width: CGFloat = 440
            let height: CGFloat = 956
            webView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            webView.setNeedsLayout()
            webView.layoutIfNeeded()
            
            print("📸 [Screenshot Debug] Fixed WebView frame to: \(webView.frame)")
            
            // Wait a moment for layout to complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        let config = WKSnapshotConfiguration()
        config.afterScreenUpdates = true
        // Match the view's width to reduce rescaling artifacts
        config.snapshotWidth = NSNumber(value: Float(webView.bounds.width))
        
        // Retry snapshot a few times if the WebKit content process is still getting ready
        for attempt in 1...5 {
            do {
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    webView.takeSnapshot(with: config) { image, error in
                        if let error = error {
                            print("📸 [Screenshot Debug] Attempt \(attempt) failed: \(error)")
                            continuation.resume(throwing: error)
                            return
                        }
                        if let image = image, let data = image.pngData() {
                            print("📸 [Screenshot Debug] Attempt \(attempt) succeeded: \(image.size.width)x\(image.size.height) pixels, \(data.count) bytes")
                            // Validate that we got meaningful content (not just a tiny white/empty image)
                            if data.count > 1000 {
                                continuation.resume(returning: data.base64EncodedString())
                            } else {
                                print("📸 [Screenshot Debug] Attempt \(attempt) produced tiny/empty image: \(data.count) bytes")
                                continuation.resume(throwing: ComputerUseError.screenshotFailed)
                            }
                        } else {
                            print("📸 [Screenshot Debug] Attempt \(attempt) failed: no image or PNG data")
                            continuation.resume(throwing: ComputerUseError.screenshotFailed)
                        }
                    }
                }
                
                // Restore alpha and return successful result
                webView.alpha = originalAlpha
                return result
            } catch {
                print("📸 [Screenshot Debug] Attempt \(attempt) exception: \(error)")
                // Small backoff before next attempt
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                if attempt == 5 {
                    print("📸 [Screenshot Debug] All attempts failed, generating fallback")
                    // Restore original alpha before returning fallback
                    webView.alpha = originalAlpha
                    
                    // Provide a larger, more visible fallback image with diagnostic info
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 440, height: 100))
                    let img = renderer.image { ctx in
                        UIColor.systemRed.setFill()
                        ctx.fill(CGRect(x: 0, y: 0, width: 440, height: 100))
                        
                        let text = "WebView Screenshot Failed\nFrame: \(webView.frame)\nURL: \(webView.url?.absoluteString ?? "None")"
                        let attrs: [NSAttributedString.Key: Any] = [
                            .foregroundColor: UIColor.white,
                            .font: UIFont.systemFont(ofSize: 14)
                        ]
                        text.draw(in: CGRect(x: 10, y: 20, width: 420, height: 60), withAttributes: attrs)
                    }
                    return img.pngData()?.base64EncodedString()
                }
            }
        }
        
        // Restore original alpha before returning
        webView.alpha = originalAlpha
        return nil
    }
    
    /// Evaluates a JavaScript string in the web view.
    private func evaluateJavaScript(_ script: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            self.javascriptContinuation = continuation
            self.webView?.evaluateJavaScript(script) { result, error in
                if let error = error {
                    self.javascriptContinuation?.resume(throwing: ComputerUseError.javascriptError(error.localizedDescription))
                } else {
                    self.javascriptContinuation?.resume(returning: result)
                }
                self.javascriptContinuation = nil
            }
        }
    }
    
    /// Ensures the WKWebView has loaded at least a minimal document so snapshots succeed reliably.
    private func ensureWebViewReady() async throws {
        guard let webView = webView else { throw ComputerUseError.webViewNotAvailable }
        if webView.url == nil && !(webView.isLoading) {
            let html = """
            <html><head><meta name=viewport content="initial-scale=1.0"></head>
            <body style='background:#ffffff;height:100vh;'></body></html>
            """
            try await withCheckedThrowingContinuation { continuation in
                self.navigationContinuation = continuation
                webView.loadHTMLString(html, baseURL: nil)
            }
        }
        // Give WebKit a moment to render
        try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
    }

    /// Waits until the DOM is ready and at least one paint has occurred, to avoid blank captures.
    private func waitForDomReadyAndPaint(timeoutMs: Int = 3000) async throws {
        print("⏳ [DOM Debug] Starting DOM ready check...")
        let start = Date()
        while Date().timeIntervalSince(start) * 1000 < Double(timeoutMs) {
            do {
                let ready: Bool = try await withCheckedThrowingContinuation { cont in
                    let js = """
                    (function() {
                        try { if (document.visibilityState === 'prerender') return false; } catch(e) {}
                        var rs = document.readyState;
                        var painted = false;
                        try {
                            painted = (window.innerWidth>0 && window.innerHeight>0 && document.body && document.body.getBoundingClientRect().height>0);
                        } catch(e) { painted = false; }
                        var result = (rs === 'interactive' || rs === 'complete') && painted;
                        console.log('DOM Check - readyState:', rs, 'painted:', painted, 'result:', result);
                        return result;
                    })();
                    """
                    self.webView?.evaluateJavaScript(js) { result, error in
                        if let error = error { 
                            print("⏳ [DOM Debug] JS error: \(error)")
                            cont.resume(returning: false) 
                        }
                        else { 
                            let isReady = (result as? Bool) ?? false
                            print("⏳ [DOM Debug] DOM ready result: \(isReady)")
                            cont.resume(returning: isReady) 
                        }
                    }
                }
                if ready {
                    print("⏳ [DOM Debug] DOM is ready! Requesting animation frames...")
                    // Two RAFs to ensure a paint frame has been presented
                    _ = try? await evaluateJavaScript("requestAnimationFrame(()=>requestAnimationFrame(()=>{}))")
                    print("⏳ [DOM Debug] Animation frames completed")
                    return
                }
            } catch {
                print("⏳ [DOM Debug] Exception during check: \(error)")
                // ignore and retry
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        print("⏳ [DOM Debug] Timeout reached after \(timeoutMs)ms")
    }
    
    // MARK: - WKNavigationDelegate
    
    /// Called when a web view navigation finishes. Resumes the continuation for the `navigate` action.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationContinuation?.resume(returning: ())
        navigationContinuation = nil
    }
    
    /// Called when a web view navigation fails. Resumes the continuation by throwing an error.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationContinuation?.resume(throwing: ComputerUseError.navigationFailed(error))
        navigationContinuation = nil
    }
    
    /// Called when a provisional navigation fails. Resumes the continuation by throwing an error.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationContinuation?.resume(throwing: ComputerUseError.navigationFailed(error))
        navigationContinuation = nil
    }
}

// MARK: - String Extension

// MARK: - Helpers

extension ComputerService {
    /// Coerces a heterogenous value (Int/Double/Float/String) into a Double.
    /// Returns nil if the value cannot be interpreted as a number.
    fileprivate static func valueAsDouble(_ value: Any?) -> Double? {
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
