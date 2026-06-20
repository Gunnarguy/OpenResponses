import XCTest
@testable import OpenResponses

final class URLDetectorTests: XCTestCase {

    // MARK: - extractURLs Tests

    func testExtractURLs_WithEmptyString_ReturnsEmptyArray() {
        let urls = URLDetector.extractURLs(from: "")
        XCTAssertTrue(urls.isEmpty)
    }

    func testExtractURLs_WithNoURLs_ReturnsEmptyArray() {
        let text = "This is a simple text without any URLs."
        let urls = URLDetector.extractURLs(from: text)
        XCTAssertTrue(urls.isEmpty)
    }

    func testExtractURLs_WithValidHttpAndHttpsURLs_ExtractsCorrectly() {
        let text = "Check out http://example.com and https://www.test.org for more info."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].absoluteString, "http://example.com")
        XCTAssertEqual(urls[1].absoluteString, "https://www.test.org")
    }

    func testExtractURLs_WithTrailingPunctuation_ExcludesPunctuation() {
        let text = "Have you seen https://apple.com? I also like https://github.com/! And here is https://wikipedia.org."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 3)
        // NSDataDetector automatically handles trailing punctuation intelligently.
        XCTAssertEqual(urls[0].absoluteString, "https://apple.com")
        XCTAssertEqual(urls[1].absoluteString, "https://github.com/")
        XCTAssertEqual(urls[2].absoluteString, "https://wikipedia.org")
    }

    func testExtractURLs_FiltersOutNonHttpSchemes() {
        // extractURLs is supposed to filter for "http" or "https" only
        let text = "Send an email to test@example.com or use ftp://files.example.com to upload. But also visit https://valid.com."
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://valid.com")
    }

    func testExtractURLs_WithComplexPathsAndQueries_ExtractsCorrectly() {
        let text = "Read more at https://example.com/path/to/page?param1=value&param2=123#section"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].absoluteString, "https://example.com/path/to/page?param1=value&param2=123#section")
    }

    func testExtractURLs_WithMultipleConsecutiveURLs_ExtractsCorrectly() {
        let text = "https://one.com https://two.com\nhttps://three.com"
        let urls = URLDetector.extractURLs(from: text)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "https://one.com")
        XCTAssertEqual(urls[1].absoluteString, "https://two.com")
        XCTAssertEqual(urls[2].absoluteString, "https://three.com")
    }
}
