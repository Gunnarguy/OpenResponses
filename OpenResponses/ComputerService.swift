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
    
    // Track attach lifecycle to avoid noisy logs and enable automatic retry when a key window appears.
    private var hasLoggedNoKeyWindow: Bool = false
    private var attachObservers: [NSObjectProtocol] = []
    private var didAttachToWindow: Bool {
        webView?.superview != nil
    }
    
    // Continuations to bridge delegate-based asynchronous operations with async/await.
    private var navigationContinuation: CheckedContinuation<Void, Error>?
    private var javascriptContinuation: CheckedContinuation<Any?, Error>?
    // Suppresses model-originated clicks for a brief window after we programmatically submit a search.
    // This helps avoid the model immediately clicking promo/suggestion tiles before results finish loading.
    private var suppressClicksUntil: Date?
    
    override init() {
        super.init()
        setupWebView()
    }

    // Note: We avoid isolated deinit (requires iOS 18.4+) and rely on successful attach to unregister observers.

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
            // Strict mode: do not inject help pages. If about:blank, just capture the current state.
            // If the model wants to navigate, it should issue a navigate action.
            if webView.url == nil || webView.url?.absoluteString == "about:blank" {
                if let urlString = action.parameters["url"] as? String, let url = URL(string: urlString) {
                    try await navigate(to: url)
                }
                // Else, proceed without injecting any content; the screenshot will reflect the blank state.
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
        // For click actions, give extra time for JavaScript frameworks to respond
        var extraWaitTime: UInt64 = 150_000_000 // default 150ms
        if action.type == "click" {
            extraWaitTime = 500_000_000 // 500ms for clicks
        }
        
        // Ensure the web view has rendered at least once before snapshot
        try await ensureWebViewReady()
        try await waitForDomReadyAndPaint()
        try? await Task.sleep(nanoseconds: extraWaitTime)
        
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
        AppLogger.log("🌐 [Navigation] Starting navigation to: \(finalURL.absoluteString)", category: .general, level: .debug)
        try await withCheckedThrowingContinuation { continuation in
            self.navigationContinuation = continuation
            self.webView?.load(URLRequest(url: finalURL))
        }
        AppLogger.log("🌐 [Navigation] Completed: \(webView?.url?.absoluteString ?? "unknown")", category: .general, level: .debug)
    }
    
    /// Simulates a click at a specific point on the web page.
    /// Uses multiple strategies to ensure clicks work on modern JavaScript-heavy sites.
    private func click(at point: CGPoint) async throws {
        // If a post-search suppression window is active, skip executing the click to avoid misclicks
        if let until = suppressClicksUntil, Date() < until {
            AppLogger.log("🛡️ [Click Guard] Suppressing click during post-search stabilization window", category: .general, level: .info)
            return
        }
        // Adjust for high-DPI screenshots: model might send coordinates in physical pixels.
        // Convert to CSS pixels by dividing by devicePixelRatio when coordinates exceed viewport.
        let script = """
        (function() {
            // Generic top-left hamburger/menu guardrail: if the point is near the top-left corner,
            // avoid clicking generic containers; try to resolve a visible icon-like control first.
            function findHamburgerNearTopLeft(x, y) {
                var vw = window.innerWidth || document.documentElement.clientWidth || 0;
                var vh = window.innerHeight || document.documentElement.clientHeight || 0;
                // Envelope ~80x80 CSS px in top-left; conservative and site-agnostic
                if (x > 80 || y > 80) return null;
                // Probe several selectors that commonly represent menus/buttons
                var candidates = Array.from(document.querySelectorAll('button, a, [role="button"], [aria-label]'));
                // Filter to visible, small-ish controls that are near (x,y)
                candidates = candidates.filter(function(el){
                    var r = el.getBoundingClientRect();
                    if (r.width <= 0 || r.height <= 0) return false;
                    // visibility check
                    var style = window.getComputedStyle(el);
                    if (style.visibility === 'hidden' || style.display === 'none' || style.pointerEvents === 'none') return false;
                    // proximity to top-left and reasonable icon bounds
                    var cx = r.left + r.width/2, cy = r.top + r.height/2;
                    var near = (cx < 120 && cy < 120);
                    var iconSized = (r.width <= 64 && r.height <= 64);
                    // textual cues
                    var txt = (el.innerText || '').toLowerCase();
                    var lab = (el.getAttribute('aria-label') || '').toLowerCase();
                    var title = (el.getAttribute('title') || '').toLowerCase();
                    var looksLikeMenu = lab.includes('menu') || lab.includes('hamburger') || title.includes('menu') || title.includes('hamburger') || txt === '';
                    return near && iconSized && looksLikeMenu;
                });
                // Prefer the closest candidate to (x,y)
                if (candidates.length) {
                    candidates.sort(function(a,b){
                        var ra=a.getBoundingClientRect(), rb=b.getBoundingClientRect();
                        var acx=ra.left+ra.width/2, acy=ra.top+ra.height/2;
                        var bcx=rb.left+rb.width/2, bcy=rb.top+rb.height/2;
                        function d(cx,cy){ var dx=cx-x, dy=cy-y; return dx*dx+dy*dy; }
                        return d(acx,acy)-d(bcx,bcy);
                    });
                    return candidates[0];
                }
                return null;
            }
            function pickClickableFromPoint(x,y){
                var list = (document.elementsFromPoint ? document.elementsFromPoint(x,y) : [document.elementFromPoint(x,y)].filter(Boolean));
                for (var i=0;i<list.length;i++){
                    var el = list[i];
                    var clickable = el.closest && el.closest('a,button,input,textarea,select,[role="button"],[onclick],[tabindex],label');
                    if (clickable) return clickable;
                }
                return document.elementFromPoint(x,y);
            }
            function isVisible(el){
                if (!el) return false;
                var r = el.getBoundingClientRect();
                if (r.width <= 0 || r.height <= 0) return false;
                var s = window.getComputedStyle(el);
                if (s.visibility === 'hidden' || s.display === 'none' || s.pointerEvents === 'none' || parseFloat(s.opacity||'1') === 0) return false;
                return true;
            }
            function looksLikeConsentOverlay(node){
                if (!node || node === document.body) return false;
                var txt = ((node.innerText||'') + ' ' + (node.className||'') + ' ' + (node.id||'')).toLowerCase();
                if (txt.includes('cookie') || txt.includes('consent') || txt.includes('privacy') || txt.includes('onetrust') || txt.includes('gdpr')){
                    var r = node.getBoundingClientRect();
                    return (r.height > 120 && isVisible(node));
                }
                return false;
            }
            function findAncestorOverlay(el){
                var cur = el;
                while (cur && cur !== document.body){
                    if (looksLikeConsentOverlay(cur)) return cur;
                    cur = cur.parentElement;
                }
                return null;
            }
            function textOf(el){
                var t = (el.innerText||'').trim();
                if (!t && (el.value||'').trim()) t = el.value.trim();
                if (!t){
                    var lab = (el.getAttribute('aria-label')||'').trim();
                    var title = (el.getAttribute('title')||'').trim();
                    t = lab || title;
                }
                return (t||'');
            }
            function findConsentButtonWithin(root, x, y){
                var candidates = Array.from(root.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]')).filter(isVisible);
                if (!candidates.length) return null;
                var PRIORITY = [
                    /accept all/i,
                    /accept/i,
                    /agree/i,
                    /allow/i,
                    /ok/i,
                    /got it/i,
                    /continue/i
                ];
                function score(el){
                    var t = textOf(el);
                    for (var i=0;i<PRIORITY.length;i++){
                        if (PRIORITY[i].test(t)) return 1000 - i*10; // prioritize earlier matches
                    }
                    // distance bonus to keep clicks near intended area
                    var r = el.getBoundingClientRect();
                    var cx = r.left + r.width/2, cy = r.top + r.height/2;
                    var dx = cx - x, dy = cy - y;
                    var dist2 = dx*dx + dy*dy;
                    return Math.max(0, 500 - Math.min(dist2, 500));
                }
                candidates.sort(function(a,b){ return score(b) - score(a); });
                return candidates[0] || null;
            }
            var px = \(point.x);
            var py = \(point.y);
            var dpr = (window.devicePixelRatio || 1);
            var vw = window.innerWidth || document.documentElement.clientWidth || 0;
            var vh = window.innerHeight || document.documentElement.clientHeight || 0;
            if (px > vw || py > vh) { px = px / dpr; py = py / dpr; }
            px = Math.max(0, Math.min(vw - 1, px));
            py = Math.max(0, Math.min(vh - 1, py));

            // Guardrail: attempt to resolve a precise top-left icon if applicable.
            // If the point is near the top-left but no menu-like control is found, refuse the click.
            var nearTopLeft = (px <= 80 && py <= 80);
            var el = null;
            if (nearTopLeft) {
                el = findHamburgerNearTopLeft(px, py);
                if (!el) {
                    return "Refused click: no menu-like control visible near top-left.";
                }
            } else {
                el = pickClickableFromPoint(px, py);
                // If the selected element appears to be a consent/cookie overlay container,
                // prefer a visible consent button within it (e.g., "Accept All").
                var overlay = el && looksLikeConsentOverlay(el) ? el : (el ? findAncestorOverlay(el) : null);
                if (overlay) {
                    var consentBtn = findConsentButtonWithin(overlay, px, py);
                    if (consentBtn) el = consentBtn;
                }
            }
            if (!el) { return "No element found at point (" + px + ", " + py + ")."; }
            try { el.scrollIntoView({block:'center', inline:'center', behavior:'auto'}); } catch(e) {}
            var el2 = pickClickableFromPoint(px, py) || el; el = el2;
            var rect = el.getBoundingClientRect();
            var clickX = Math.round(rect.left + Math.min(rect.width/2, Math.max(1, rect.width - 1)));
            var clickY = Math.round(rect.top + Math.min(rect.height/2, Math.max(1, rect.height - 1)));
            clickX = Math.max(0, Math.min(vw - 1, clickX));
            clickY = Math.max(0, Math.min(vh - 1, clickY));

            var result = "Clicked element: " + el.tagName + (el.className ? "." + el.className : "") + (el.id ? "#" + el.id : "") + " at (" + clickX + ", " + clickY + ")";
            try {
                if (el.focus) el.focus();
                ['mousedown','mouseup','click'].forEach(function(type){
                    var ev = new MouseEvent(type, {bubbles:true, cancelable:true, view:window, clientX:clickX, clientY:clickY, button:0, buttons:(type==='mousedown'?1:0)});
                    el.dispatchEvent(ev);
                });
                if (el.click) el.click();
                if (el.href && el.tagName === 'A') { result += " (Link: " + el.href + ")"; }
            } catch(e) { result += " (Error: " + e.message + ")"; }
            return result;
        })();
        """
        let clickResult = try await evaluateJavaScript(script)
        AppLogger.log("🖱️ Click result: \(clickResult ?? "No result")", category: .general, level: .info)
        
        // Give JavaScript frameworks time to process the click
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
    }

    // MARK: - Universal element targeting by visible text

    /// Attempts to locate a clickable point for an element whose visible text matches the provided text.
    /// Site-agnostic: scans a broad set of elements, filters by visibility, and prefers exact match, then contains.
    /// Returns CSS pixel coordinates within the viewport or nil if no reasonable candidate is found.
    func findClickablePointByVisibleText(_ text: String, preferExact: Bool = true) async throws -> CGPoint? {
        guard webView != nil else { return nil }
        let escaped = text.sanitizedForJS()
        let script = """
        (function(){
            function norm(s){ return (s||'').trim().replace(/\\s+/g,' ').toLowerCase(); }
            function isVisible(el){
                if(!el) return false;
                var style = window.getComputedStyle(el);
                if(!style || style.visibility==='hidden' || style.display==='none' || style.pointerEvents==='none') return false;
                var r = el.getBoundingClientRect();
                if(r.width<=1 || r.height<=1) return false;
                if(r.bottom < -10 || r.right < -10 || r.top > (window.innerHeight+10) || r.left > (window.innerWidth+10)) return false;
                return true;
            }
            var target = norm('\(escaped)');
            var selectors = 'a,button,[role="button"],input[type="submit"],input[type="button"],[onclick],[tabindex],div,span,h1,h2,h3,h4,h5,h6,li,article,section';
            var els = Array.from(document.querySelectorAll(selectors)).filter(isVisible);
            if(!els.length) return null;
            function score(el){
                var t = norm(el.innerText);
                if(!t) return -1;
                if(t === target) return 100; // exact match
                if(t.includes(target)) return 60 + Math.min(20, Math.floor((target.length/Math.max(1,t.length))*20));
                var tt = new Set(t.split(' '));
                var tg = new Set(target.split(' '));
                var inter = 0; tg.forEach(w=>{ if(tt.has(w)) inter++; });
                if(inter>0) return 30 + inter;
                return -1;
            }
            var best = null; var bestScore = -1;
            for (var el of els){
                var s = score(el);
                if (s > bestScore){ bestScore = s; best = el; }
            }
            if(!best || bestScore < 0) return null;
            var r = best.getBoundingClientRect();
            var cx = Math.max(1, Math.min(window.innerWidth-1, r.left + r.width/2));
            var cy = Math.max(1, Math.min(window.innerHeight-1, r.top + r.height/2));
            return {x: cx, y: cy, text: best.innerText};
        })();
        """
        let result = try await evaluateJavaScript(script)
        if let dict = result as? [String: Any], let x = dict["x"] as? CGFloat, let y = dict["y"] as? CGFloat {
            self.suppressClicksUntil = Date().addingTimeInterval(0.5)
            return CGPoint(x: x, y: y)
        }
        return nil
    }
    
    /// Simulates a double-click at a specific point on the web page.
    private func doubleClick(at point: CGPoint) async throws {
        let script = """
        (function() {
            var px = \(point.x);
            var py = \(point.y);
            var dpr = (window.devicePixelRatio || 1);
            var vw = window.innerWidth || document.documentElement.clientWidth || 0;
            var vh = window.innerHeight || document.documentElement.clientHeight || 0;
            if (px > vw || py > vh) { px = px / dpr; py = py / dpr; }
            px = Math.max(0, Math.min(vw - 1, px));
            py = Math.max(0, Math.min(vh - 1, py));

            var el = document.elementFromPoint(px, py);
            if (el) {
                el.focus();
                var event = new MouseEvent('dblclick', {
                    bubbles: true,
                    cancelable: true,
                    clientX: px,
                    clientY: py,
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
            var px = \(point.x);
            var py = \(point.y);
            var dpr = (window.devicePixelRatio || 1);
            var vw = window.innerWidth || document.documentElement.clientWidth || 0;
            var vh = window.innerHeight || document.documentElement.clientHeight || 0;
            if (px > vw || py > vh) { px = px / dpr; py = py / dpr; }
            px = Math.max(0, Math.min(vw - 1, px));
            py = Math.max(0, Math.min(vh - 1, py));

            var el = document.elementFromPoint(px, py);
            if (el) {
                var event = new MouseEvent('mouseover', {
                    bubbles: true,
                    cancelable: true,
                    clientX: px,
                    clientY: py
                });
                el.dispatchEvent(event);
                
                var moveEvent = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    clientX: px,
                    clientY: py
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
            var startX = \(startX); var startY = \(startY); var endX = \(endX); var endY = \(endY);
            var dpr = (window.devicePixelRatio || 1);
            var vw = window.innerWidth || document.documentElement.clientWidth || 0;
            var vh = window.innerHeight || document.documentElement.clientHeight || 0;
            function normX(v){ if (v>vw||v<0) v = v/dpr; return Math.max(0, Math.min(vw-1, v)); }
            function normY(v){ if (v>vh||v<0) v = v/dpr; return Math.max(0, Math.min(vh-1, v)); }
            startX = normX(startX); startY = normY(startY);
            endX = normX(endX); endY = normY(endY);
            
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
        try? await Task.sleep(nanoseconds: 250_000_000)
        try await waitForDomReadyAndPaint()
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

    /// Focuses a site search box (if present), types the query, and submits it.
    ///
    /// Behavior:
    /// - Amazon: uses specific selectors and prefers clicking the submit button (avoids intercepts).
    /// - Other sites (incl. Google/Bing): tries a broad set of search selectors and submits via form or Enter.
    /// - Adds a short post-submit click suppression window to avoid immediate promo/suggestion clicks.
    func performSearchIfOnKnownEngine(query: String) async throws {
        guard let webView = webView else { return }
        let host = webView.url?.host?.lowercased()
        let isAmazon = (host?.contains("amazon.") ?? false)

        let escaped = query.sanitizedForJS()
        let js: String
        if isAmazon {
            js = """
            (function(){
                // Try common Amazon search selectors
                var sel = document.querySelector('#twotabsearchtextbox, input[name="field-keywords"], input[aria-label="Search Amazon"], input[type="search"][name="k"]');
                if(!sel){ return 'No Amazon search box found'; }
                if (sel.focus) sel.focus();
                sel.value = '\(escaped)';
                try { sel.setSelectionRange(sel.value.length, sel.value.length); } catch(e) {}
                try { sel.dispatchEvent(new Event('input', {bubbles:true})); } catch(e) {}
                // Prefer clicking the submit button to avoid Amazon intercepts
                var submitBtn = document.querySelector('#nav-search-submit-button, input[type="submit"][value], input[type="submit"]');
                if (submitBtn) {
                    try { submitBtn.click(); return 'Amazon search submitted via button'; } catch(e) {}
                }
                // Fallback: press Enter in the field
                try {
                    var kd = new KeyboardEvent('keydown', {key:'Enter', keyCode:13, which:13, bubbles:true}); sel.dispatchEvent(kd);
                    var ku = new KeyboardEvent('keyup', {key:'Enter', keyCode:13, which:13, bubbles:true}); sel.dispatchEvent(ku);
                    return 'Amazon search submitted via Enter';
                } catch(e) {}
                return 'Amazon search typed but not submitted';
            })();
            """
        } else {
            js = """
            (function(){
                function isVisible(el){
                    if(!el) return false;
                    var style = window.getComputedStyle(el);
                    var rect = el.getBoundingClientRect();
                    return style && style.visibility !== 'hidden' && style.display !== 'none' && rect.width > 0 && rect.height > 0;
                }
                // Broad set of search selectors for generic sites, Google, Bing, etc.
                var selectors = [
                    'input[name="q"]', 'textarea[name="q"]',
                    'input[type="search"]', 'textarea[type="search"]',
                    'input[aria-label="Search"]', 'textarea[aria-label="Search"]',
                    'input[placeholder*="Search" i]', 'textarea[placeholder*="Search" i]',
                    'input[placeholder*="search" i]', 'textarea[placeholder*="search" i]'
                ];
                var sel = null;
                for (var s of selectors){
                    var cands = Array.from(document.querySelectorAll(s));
                    sel = cands.find(isVisible);
                    if (sel) break;
                }
                if(!sel){ return 'No search box found'; }
                if (sel.focus) sel.focus();
                sel.value = '\(escaped)';
                try { sel.setSelectionRange(sel.value.length, sel.value.length); } catch(e) {}
                try { sel.dispatchEvent(new Event('input', {bubbles:true})); } catch(e) {}
                // Try to submit via nearby submit button first, then form.submit, then Enter
                var submitted = false;
                try {
                    var root = sel.form || document;
                    var btn = root.querySelector('button[type="submit"], input[type="submit"], [aria-label="Search" i][role="button"], [type="image"][name="btnG"]');
                    if (btn && isVisible(btn)) { btn.click(); submitted = true; }
                } catch(e) {}
                if (!submitted && sel.form) { try { sel.form.submit(); submitted = true; } catch(e) {} }
                if (!submitted) {
                    try {
                        var kd = new KeyboardEvent('keydown', {key:'Enter', keyCode:13, which:13, bubbles:true}); sel.dispatchEvent(kd);
                        var ku = new KeyboardEvent('keyup', {key:'Enter', keyCode:13, which:13, bubbles:true}); sel.dispatchEvent(ku);
                        submitted = true;
                    } catch(e) {}
                }
                return submitted ? 'Search submitted' : 'Search typed but not submitted';
            })();
            """
        }
        _ = try await evaluateJavaScript(js)
        // Start a short suppression window to ignore model-originated clicks right after programmatic submit
        self.suppressClicksUntil = Date().addingTimeInterval(1.0)
        // Give the page time to navigate and paint results
        try? await Task.sleep(nanoseconds: 700_000_000) // 700ms
        try await waitForDomReadyAndPaint()
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
