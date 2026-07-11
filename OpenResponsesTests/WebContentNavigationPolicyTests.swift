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
}
