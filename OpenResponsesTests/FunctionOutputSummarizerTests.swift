import XCTest
@testable import OpenResponses

final class FunctionOutputSummarizerTests: XCTestCase {
    func testFailureSummaryWithEmbeddedJSON() {
        let raw = "Error processing getNotionDatabase: Notion API request failed (HTTP 404): {\"object\":\"error\",\"status\":404,\"code\":\"object_not_found\",\"message\":\"Could not find database with ID: 1e8d94c5-0ea0-4ea8-8fa5-444c640c7ffb. Make sure the relevant pages and databases are shared with your integration.\"}"
        let summary = FunctionOutputSummarizer.failureSummary(functionName: "getNotionDatabase", rawOutput: raw)
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary?.contains("⚠️ getNotionDatabase failed") == true)
        XCTAssertTrue(summary?.contains("object_not_found") == true)
        XCTAssertTrue(summary?.contains("Could not find database") == true)
    }

    func testFailureSummaryReturnsNilForSuccessPayload() {
        let raw = "{\"object\":\"page\",\"id\":\"123\"}"
        let summary = FunctionOutputSummarizer.failureSummary(functionName: "createNotionPage", rawOutput: raw)
        XCTAssertNil(summary)
    }

    func testFailureSummaryForPlainErrorString() {
        let raw = "Error: Network unreachable"
        let summary = FunctionOutputSummarizer.failureSummary(functionName: "searchNotion", rawOutput: raw)
        XCTAssertEqual(summary, "⚠️ searchNotion failed: Error: Network unreachable")
    }
}
