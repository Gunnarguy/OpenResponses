import XCTest
@testable import OpenResponses

final class URLDetectorStandaloneTests: XCTestCase {
    
    func testExtractRenderableURLs() {
        let text = "Check out https://google.com and http://example.org/path?query=1. Also contact mailto:test@example.com."
        let urls = URLDetector.extractRenderableURLs(from: text)
        
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "https://google.com")
        XCTAssertEqual(urls[1].absoluteString, "http://example.org/path?query=1")
    }
    
    func testWithURLDetection() {
        let message = ChatMessage.withURLDetection(
            role: .user,
            text: "Go to https://apple.com"
        )
        
        XCTAssertEqual(message.webURLs?.count, 1)
        XCTAssertEqual(message.webURLs?.first?.absoluteString, "https://apple.com")
    }
    
    func testForceWebURLs() {
        let expectedURL = URL(string: "https://custom.org")!
        let message = ChatMessage.withURLDetection(
            role: .user,
            text: "No url here",
            forceWebURLs: [expectedURL]
        )
        
        XCTAssertEqual(message.webURLs?.count, 1)
        XCTAssertEqual(message.webURLs?.first, expectedURL)
    }
}
