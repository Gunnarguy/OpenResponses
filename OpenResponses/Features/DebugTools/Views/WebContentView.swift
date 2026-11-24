import SwiftUI
import WebKit

/// Settings → Tools → Web page previews: whether an answer that links to a web page shows that page, loaded,
/// under the answer. On by default (the behavior before the switch existed). The Response Includes switches in
/// Request Options don't control this: they choose what the API returns, not what the chat shows (issue #78).
enum WebPagePreviews {
    static let storageKey = "showWebPagePreviews"
    static let defaultValue = true

    /// The pages to show under a message: its detected links when previews are on, none when they are off.
    static func urls(for message: ChatMessage, enabled: Bool) -> [URL] {
        guard enabled else { return [] }
        return message.webURLs ?? []
    }
}

/// A SwiftUI view that embeds web content directly in chat messages
struct WebContentView: View {
    let url: URL
    @State private var isLoading = true
    @State private var error: String?
    @State private var loadingTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with URL and controls
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text(url.host ?? "Web Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)

            // Web content container
            if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Failed to load: \(error)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        isLoading = true
                        self.error = nil
                        startLoadingTimer()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                WebView(url: url, isLoading: $isLoading, error: $error)
                    .frame(height: 300)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            // Action buttons
            HStack {
                Button("Open in Safari") {
                    openExternalURL(url)
                }
                .font(.caption)
                .foregroundColor(.blue)

                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            startLoadingTimer()
        }
        .onDisappear {
            loadingTimer?.invalidate()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Web content from \(url.host ?? "unknown site")")
    }

    private func startLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { _ in
            DispatchQueue.main.async {
                if isLoading {
                    isLoading = false
                    self.error = "Loading timeout - try again or open in Safari"
                }
            }
        }
    }
}

#if os(macOS)
extension WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { makeWebView(coordinator: context.coordinator) }
    func updateNSView(_ webView: WKWebView, context: Context) { updateWebView(webView, coordinator: context.coordinator) }
}
#else
extension WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { makeWebView(coordinator: context.coordinator) }
    func updateUIView(_ webView: WKWebView, context: Context) { updateWebView(webView, coordinator: context.coordinator) }
}
#endif

/// WKWebView for SwiftUI: an NSView on the Mac, a UIView on iPhone and iPad (the conformances are above).
struct WebView {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: String?

    fileprivate func makeWebView(coordinator: Coordinator) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Configure for better experience and ad blocking
        #if !os(macOS)
        config.allowsInlineMediaPlayback = true
        #endif
        config.mediaTypesRequiringUserActionForPlayback = []
        config.suppressesIncrementalRendering = false

        // Create the web view with enhanced configuration
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        #if !os(macOS)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        #endif

        // Set a proper desktop user agent to avoid mobile redirects/ads
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

        // Configure web view settings for better compatibility
        webView.allowsBackForwardNavigationGestures = false
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Load the initial URL with cache policy to get fresh content
        let request = createRequest(for: url)
        webView.load(request)

        // Keep track of the requested URL in coordinator
        coordinator.lastRequestedURL = url

        return webView
    }

    fileprivate func updateWebView(_ webView: WKWebView, coordinator: Coordinator) {
        // Only load if the requested URL has actually changed.
        // Comparing with coordinator.lastRequestedURL prevents infinite reload loops
        // triggered by SwiftUI updates (such as scroll events or streaming state changes)
        // while the page is still loading or has redirected.
        if coordinator.lastRequestedURL != url {
            coordinator.lastRequestedURL = url
            let request = createRequest(for: url)
            webView.load(request)
        }
    }

    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15.0 // 15 second timeout
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        return request
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView
        var lastRequestedURL: URL?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.error = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            let nsError = error as NSError

            // Handle specific error cases
            if nsError.code == NSURLErrorCancelled {
                // Don't show error for cancelled loads (usually redirects or ad blocks)
                return
            } else if nsError.code == NSURLErrorTimedOut {
                parent.error = "Loading timeout - try again or open in Safari"
            } else if error.localizedDescription.contains("WEBP") {
                parent.error = "Image format not supported"
            } else if nsError.domain == NSURLErrorDomain {
                parent.error = "Network connection issue"
            } else if error.localizedDescription.contains("sandbox") {
                parent.error = "Security restriction"
            } else {
                parent.error = error.localizedDescription
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            let nsError = error as NSError

            // Handle specific error cases
            if nsError.code == NSURLErrorCancelled {
                // Don't show error for cancelled loads (usually redirects or ad blocks)
                return
            } else if nsError.code == NSURLErrorTimedOut {
                parent.error = "Loading timeout - try again or open in Safari"
            } else if error.localizedDescription.contains("WEBP") {
                parent.error = "Image format not supported"
            } else if nsError.domain == NSURLErrorDomain {
                parent.error = "Network connection issue"
            } else if error.localizedDescription.contains("sandbox") {
                parent.error = "Security restriction"
            } else {
                parent.error = error.localizedDescription
            }
        }

        // Handle link navigation within the web view
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let policy = evaluatePolicy(for: url, navigationType: navigationAction.navigationType,
                                        isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true)
            decisionHandler(policy)
        }

        // Testable core navigation policy decision logic
        /// `isMainFrame` is false for a page's own iframes. Those are still held to http and https, but a blocked one
        /// (an `about:srcdoc` or `data:` frame, which most news pages have) is dropped quietly: setting the error there
        /// replaced the whole source preview with "Navigation blocked" although the page itself loaded (seen 2026-11-22).
        func evaluatePolicy(for url: URL, navigationType: WKNavigationType, isMainFrame: Bool = true) -> WKNavigationActionPolicy {
            // Enforce strict HTTP/HTTPS URL scheme policy on all navigations and redirections
            let scheme = url.scheme?.lowercased() ?? ""
            guard scheme == "http" || scheme == "https" || (scheme == "about" && url.absoluteString == "about:blank") else {
                if isMainFrame { parent.error = "Navigation blocked: URL scheme '\(scheme)' is not allowed." }
                return .cancel
            }

            // Block common ad and tracking domains
            let blockedDomains = [
                "googleads.com", "doubleclick.net", "googlesyndication.com",
                "adsystem.com", "amazon-adsystem.com", "facebook.com/tr",
                "google-analytics.com", "taboola.com", "outbrain.com",
                "recaptcha", "captcha"
            ]

            if let host = url.host?.lowercased() {
                if blockedDomains.contains(where: { host.contains($0) }) {
                    return .cancel
                }
            }

            // Only block user-initiated clicks to completely external domains
            // Allow all redirects, iframes, and same-domain navigation
            if navigationType == .linkActivated,
               let originalHost = parent.url.host?.lowercased(),
               let currentHost = url.host?.lowercased(),
               currentHost != originalHost && !currentHost.hasSuffix(".\(originalHost)") && !originalHost.hasSuffix(".\(currentHost)") {
                // This is a user click to a completely external domain - open in Safari
                openExternalURL(url)
                return .cancel
            }

            // Allow all other navigation (same domain, redirects, iframes, forms, etc.)
            return .allow
        }

        // Handle target="_blank" new window navigations securely
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url else {
                return nil
            }

            let scheme = url.scheme?.lowercased() ?? ""
            guard scheme == "http" || scheme == "https" else {
                parent.error = "Navigation blocked: URL scheme '\(scheme)' is not allowed."
                return nil
            }

            webView.load(navigationAction.request)
            return nil
        }
    }
}

#Preview {
    WebContentView(url: URL(string: "https://gunzino.me")!)
        .padding()
}
