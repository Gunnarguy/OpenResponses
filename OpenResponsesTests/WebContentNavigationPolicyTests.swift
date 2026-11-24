import XCTest
import WebKit
import SwiftUI
@testable import OpenResponses

final class WebContentNavigationPolicyTests: XCTestCase {
    
    @MainActor
    func testHTTPAndHTTPSSchemesAllowed() {
        var errorString: String? = nil
        let bindingError = Binding<String?>(
            get: { errorString },
            set: { errorString = $0 }
        )
        
        let webViewStruct = WebView(
            url: URL(string: "https://example.com")!,
            isLoading: .constant(false),
            error: bindingError
        )
        let coordinator = webViewStruct.makeCoordinator()
        
        let url = URL(string: "http://example.com/some/path")!
        let policy = coordinator.evaluatePolicy(for: url, navigationType: .other)
        
        XCTAssertEqual(policy.rawValue, WKNavigationActionPolicy.allow.rawValue)
        XCTAssertNil(errorString)
    }
    
    @MainActor
    func testNonHTTPSchemeBlocked() {
        var errorString: String? = nil
        let bindingError = Binding<String?>(
            get: { errorString },
            set: { errorString = $0 }
        )
        
        let webViewStruct = WebView(
            url: URL(string: "https://example.com")!,
            isLoading: .constant(false),
            error: bindingError
        )
        let coordinator = webViewStruct.makeCoordinator()
        
        let url = URL(string: "ftp://example.com/file.zip")!
        let policy = coordinator.evaluatePolicy(for: url, navigationType: .other)
        
        XCTAssertEqual(policy.rawValue, WKNavigationActionPolicy.cancel.rawValue)
        XCTAssertNotNil(errorString)
        XCTAssertTrue(errorString?.contains("blocked") == true)
    }
    
    @MainActor
    func testBlockedDomains() {
        var errorString: String? = nil
        let bindingError = Binding<String?>(
            get: { errorString },
            set: { errorString = $0 }
        )
        
        let webViewStruct = WebView(
            url: URL(string: "https://example.com")!,
            isLoading: .constant(false),
            error: bindingError
        )
        let coordinator = webViewStruct.makeCoordinator()
        
        let adURL = URL(string: "https://googleads.g.doubleclick.net/ad")!
        let policy = coordinator.evaluatePolicy(for: adURL, navigationType: .other)
        
        XCTAssertEqual(policy.rawValue, WKNavigationActionPolicy.cancel.rawValue)
    }

    /// A page's own iframe on about:srcdoc is blocked without replacing the preview with an error (2026-11-22).
    @MainActor
    func testBlockedIframeSchemeDoesNotFailThePage() {
        var errorString: String? = nil
        let bindingError = Binding<String?>(get: { errorString }, set: { errorString = $0 })
        let coordinator = WebView(url: URL(string: "https://openai.com")!, isLoading: .constant(false), error: bindingError).makeCoordinator()

        let frame = coordinator.evaluatePolicy(for: URL(string: "about:srcdoc")!, navigationType: .other, isMainFrame: false)
        XCTAssertEqual(frame.rawValue, WKNavigationActionPolicy.cancel.rawValue)
        XCTAssertNil(errorString, "an iframe the policy blocks must not show the page-wide error")

        let page = coordinator.evaluatePolicy(for: URL(string: "about:srcdoc")!, navigationType: .other, isMainFrame: true)
        XCTAssertEqual(page.rawValue, WKNavigationActionPolicy.cancel.rawValue)
        XCTAssertNotNil(errorString, "the main page on a blocked scheme still says why")
    }
}

/// Issue #78: Settings → Tools → Web page previews hides the loaded pages under answers; the Response Includes
/// switches never did, because they only choose what the API returns.
final class WebPagePreviewsTests: XCTestCase {
    private let links = [URL(string: "https://www.bernama.com/en/news.php?id=1")!,
                         URL(string: "https://example.com/article")!]

    func testPreviewsOnShowEveryDetectedLink() {
        let message = ChatMessage(role: .assistant, text: "See these.", webURLs: links)
        XCTAssertEqual(WebPagePreviews.urls(for: message, enabled: true), links)
    }

    func testPreviewsOffShowNothingButKeepTheLinks() {
        let message = ChatMessage(role: .assistant, text: "See these.", webURLs: links)
        XCTAssertEqual(WebPagePreviews.urls(for: message, enabled: false), [])
        XCTAssertEqual(message.webURLs, links, "turning previews off hides them; the saved message keeps its links")
    }

    func testMessageWithoutLinksShowsNothing() {
        let message = ChatMessage(role: .assistant, text: "No links.")
        XCTAssertEqual(WebPagePreviews.urls(for: message, enabled: true), [])
    }

    func testPreviewsDefaultOnUnderTheirOwnKey() {
        XCTAssertTrue(WebPagePreviews.defaultValue, "people who never touch the switch keep the previews they had")
        XCTAssertEqual(WebPagePreviews.storageKey, "showWebPagePreviews")
    }
}
