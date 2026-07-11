//
//  AppLoggerTests.swift
//  OpenResponsesTests
//

@testable import OpenResponses
import XCTest

final class AppLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear logs if necessary
        if Thread.isMainThread {
            ConsoleLogger.shared.logs.removeAll()
        } else {
            DispatchQueue.main.sync {
                ConsoleLogger.shared.logs.removeAll()
            }
        }
    }

    func testLogOpenAIRequestRedactsBearerToken() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers = ["Authorization": "Bearer sk-testtoken123", "Content-Type": "application/json"]

        AppLogger.logOpenAIRequest(url: url, method: "POST", headers: headers, body: nil)

        // ConsoleLogger uses DispatchQueue.main.async to append logs
        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertTrue(lastLog.message.contains("***REDACTED***"))
                XCTAssertFalse(lastLog.message.contains("sk-testtoken123"))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLogOpenAIRequestRedactsNonBearerToken() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers = ["Authorization": "Basic bXl1c2VyOm15cGFzcw==", "Content-Type": "application/json"]

        AppLogger.logOpenAIRequest(url: url, method: "POST", headers: headers, body: nil)

        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertTrue(lastLog.message.contains("***REDACTED***"))
                XCTAssertFalse(lastLog.message.contains("bXl1c2VyOm15cGFzcw=="))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLogOpenAIRequestNoAuthHeader() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers = ["Content-Type": "application/json"]

        AppLogger.logOpenAIRequest(url: url, method: "POST", headers: headers, body: nil)

        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertFalse(lastLog.message.contains("***REDACTED***"))
                XCTAssertTrue(lastLog.message.contains("Content-Type"))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLogRequestBodyRedactsSensitiveKeys() {
        let mockDict: [String: Any] = [
            "publicField": "Hello world",
            "password": "mySecretPassword123",
            "api_key": "sk-1234567890",
            "nested": [
                "token": "bearer abcdefg",
                "normal": "value"
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: mockDict, options: [])
        let result = AppLogger.logOpenAIRequestBodyPreview(data)

        XCTAssertNotNil(result)
        let resultStr = result!

        // Public info should remain
        XCTAssertTrue(resultStr.contains("Hello world"))
        XCTAssertTrue(resultStr.contains("value"))

        // Sensitive info should be redacted
        XCTAssertTrue(resultStr.contains("***REDACTED***"))
        XCTAssertFalse(resultStr.contains("mySecretPassword123"))
        XCTAssertFalse(resultStr.contains("sk-1234567890"))
        XCTAssertFalse(resultStr.contains("abcdefg"))
    }

    func testLogOpenAIResponseRedactsSensitiveHeaders() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers: [AnyHashable: Any] = [
            "Set-Cookie": "session_id=abcdef123456",
            "x-notion-request-id": "req-12345",
            "Content-Type": "application/json"
        ]

        AppLogger.logOpenAIResponse(url: url, statusCode: 200, headers: headers, body: nil)

        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertTrue(lastLog.message.contains("***REDACTED***"))
                XCTAssertFalse(lastLog.message.contains("abcdef123456"))
                XCTAssertFalse(lastLog.message.contains("req-12345"))
                XCTAssertTrue(lastLog.message.contains("Content-Type"))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLogOpenAIRequestRedactsURLQueryParameters() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions?token=supersecret123&other=test")!
        let headers = ["Content-Type": "application/json"]

        AppLogger.logOpenAIRequest(url: url, method: "POST", headers: headers, body: nil)

        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertTrue(lastLog.message.contains("***REDACTED***"))
                XCTAssertFalse(lastLog.message.contains("supersecret123"))
                XCTAssertTrue(lastLog.message.contains("other=test"))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testLogOpenAIResponseRedactsURLQueryParameters() {
        let expectation = XCTestExpectation(description: "Log added to ConsoleLogger")

        let url = URL(string: "https://api.openai.com/v1/chat/completions?api_key=sk-secretkey456&param=value")!
        let headers: [AnyHashable: Any] = ["Content-Type": "application/json"]

        AppLogger.logOpenAIResponse(url: url, statusCode: 200, headers: headers, body: nil)

        DispatchQueue.main.async {
            let logs = ConsoleLogger.shared.logs
            XCTAssertFalse(logs.isEmpty, "Expected log entry")
            if let lastLog = logs.last {
                XCTAssertTrue(lastLog.message.contains("***REDACTED***"))
                XCTAssertFalse(lastLog.message.contains("sk-secretkey456"))
                XCTAssertTrue(lastLog.message.contains("param=value"))
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

}
