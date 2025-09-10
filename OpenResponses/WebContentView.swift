import SwiftUI
import WebKit

/// A SwiftUI view that embeds web content directly in chat messages
struct WebContentView: View {
    let url: URL
    @State private var isLoading = true
    @State private var error: String?
    
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
                    UIApplication.shared.open(url)
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Web content from \(url.host ?? "unknown site")")
    }
}

/// UIViewRepresentable wrapper for WKWebView
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: String?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Configure for better experience and ad blocking
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.suppressesIncrementalRendering = false
        
        // Create the web view with enhanced configuration
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        
        // Set a proper desktop user agent to avoid mobile redirects/ads
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        // Configure web view settings
        webView.allowsBackForwardNavigationGestures = false
        // JavaScript is enabled by default in WKWebView
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Load the initial URL with cache policy to get fresh content
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the URL has actually changed
        if webView.url != url {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
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
            parent.error = error.localizedDescription
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.error = error.localizedDescription
        }
        
        // Handle link navigation within the web view
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            // Block common ad domains and suspicious redirects
            let adDomains = ["googleads.com", "doubleclick.net", "googlesyndication.com", "adsystem.com", "amazon-adsystem.com", "facebook.com/tr", "google-analytics.com"]
            if let host = url.host, adDomains.contains(where: { host.contains($0) }) {
                decisionHandler(.cancel)
                return
            }
            
            // Allow navigation to the original domain and its subdomains
            if let originalHost = parent.url.host, let currentHost = url.host {
                if currentHost == originalHost || currentHost.hasSuffix(".\(originalHost)") {
                    decisionHandler(.allow)
                } else {
                    // External domain - open in Safari instead
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                }
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

#Preview {
    WebContentView(url: URL(string: "https://gunzino.me")!)
        .padding()
}
