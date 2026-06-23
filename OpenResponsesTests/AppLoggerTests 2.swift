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
        DispatchQueue.main.sync {
            ConsoleLogger.shared.clearLogs()
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
}
