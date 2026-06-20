import XCTest
@testable import OpenResponses

final class URLDetectorTests: XCTestCase {

    func testIsRenderableWebpage_ValidWebpages() {
        let validURLs = [
            URL(string: "https://www.example.com")!,
            URL(string: "http://example.org/about")!,
            URL(string: "https://news.ycombinator.com/item?id=123")!,
            URL(string: "https://github.com/apple/swift")!,
            URL(string: "http://my-blog.dev/post/1")!
        ]

        for url in validURLs {
            XCTAssertTrue(URLDetector.isRenderableWebpage(url), "Expected \(url) to be a renderable webpage")
        }
    }

    func testIsRenderableWebpage_APIEndpoints() {
        let apiURLs = [
            URL(string: "https://api.example.com/v1/users")!,
            URL(string: "https://example.com/api/v2/data")!,
            URL(string: "https://api.github.com/repos/apple/swift")!,
            URL(string: "http://backend.service/api/login")!
        ]

        for url in apiURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage (API endpoint)")
        }
    }

    func testIsRenderableWebpage_Files() {
        let fileURLs = [
            URL(string: "https://example.com/data.json")!,
            URL(string: "https://example.com/feed.xml")!,
            URL(string: "https://example.com/document.pdf")!,
            URL(string: "https://example.com/image.jpg")!,
            URL(string: "https://example.com/video.mp4")!,
            URL(string: "https://example.com/archive.zip")!
        ]

        for url in fileURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage (File extension)")
        }
    }

    func testIsRenderableWebpage_UnknownDomains() {
        let unknownURLs = [
            URL(string: "https://internal-server.local")!,
            URL(string: "http://192.168.1.1")!,
            URL(string: "https://my-app.custom")!
        ]

        for url in unknownURLs {
            XCTAssertFalse(URLDetector.isRenderableWebpage(url), "Expected \(url) to NOT be a renderable webpage (Unknown domain)")
        }
    }
}
