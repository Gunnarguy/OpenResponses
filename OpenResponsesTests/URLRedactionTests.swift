import XCTest
@testable import OpenResponses

final class URLRedactionTests: XCTestCase {
    
    func testRedactSensitiveURLParameters() {
        let url = URL(string: "https://api.openai.com/v1/chat/completions?code=mycode123&state=state_secret&keep_me=safe_value")!
        let redacted = AppLogger.redactSensitiveURLParameters(in: url)
        
        XCTAssertTrue(redacted.contains("code=%5BREDACTED_SECRET%5D"))
        XCTAssertTrue(redacted.contains("state=%5BREDACTED_SECRET%5D"))
        XCTAssertTrue(redacted.contains("keep_me=safe_value"))
        XCTAssertFalse(redacted.contains("mycode123"))
        XCTAssertFalse(redacted.contains("state_secret"))
    }
}
