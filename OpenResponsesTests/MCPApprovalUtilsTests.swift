import XCTest
@testable import OpenResponses

final class MCPApprovalUtilsTests: XCTestCase {

    func testBuildMCPApprovalResponsePayload_ApproveTrue() {
        let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "req-123",
            approve: true,
            reason: nil
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "req-123")
        XCTAssertEqual(payload["approve"] as? Bool, true)
        XCTAssertNil(payload["reason"])
    }

    func testBuildMCPApprovalResponsePayload_ApproveFalse_WithoutReason() {
        let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "req-123",
            approve: false,
            reason: nil
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "req-123")
        XCTAssertEqual(payload["approve"] as? Bool, false)
        XCTAssertNil(payload["reason"])
    }

    func testBuildMCPApprovalResponsePayload_ApproveFalse_WithReason() {
        let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "req-123",
            approve: false,
            reason: "User cancelled"
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "req-123")
        XCTAssertEqual(payload["approve"] as? Bool, false)
        XCTAssertEqual(payload["reason"] as? String, "User cancelled")
    }

    func testBuildMCPApprovalResponsePayload_ApproveTrue_WithReasonIsIgnored() {
        let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "req-123",
            approve: true,
            reason: "Should be ignored"
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "req-123")
        XCTAssertEqual(payload["approve"] as? Bool, true)
        XCTAssertNil(payload["reason"])
    }

    func testBuildMCPApprovalResponsePayload_ApproveFalse_WithEmptyReason() {
        let payload = MCPApprovalUtils.buildMCPApprovalResponsePayload(
            approvalRequestId: "req-123",
            approve: false,
            reason: ""
        )

        XCTAssertEqual(payload["type"] as? String, "mcp_approval_response")
        XCTAssertEqual(payload["approval_request_id"] as? String, "req-123")
        XCTAssertEqual(payload["approve"] as? Bool, false)
        XCTAssertNil(payload["reason"])
    }
}
