import XCTest
@testable import OpenResponses

final class MCPApprovalUtilsTests: XCTestCase {

    func testBuildTextFromApprovalRequests_EmptyArray_ReturnsNil() {
        let text = MCPApprovalUtils.buildTextFromApprovalRequests([])
        XCTAssertNil(text)
    }

    func testBuildTextFromApprovalRequests_SingleRequest_FormatsCorrectly() {
        let request = MCPApprovalRequest(
            id: "req1",
            toolName: "test_tool",
            serverLabel: "test_server",
            arguments: "{\"key\": \"value\"}",
            status: .pending
        )

        let text = MCPApprovalUtils.buildTextFromApprovalRequests([request])

        let expectedText = """
        Approval required to run **test_tool** on **test_server**.

        Arguments:
        ```json
        {
          "key" : "value"
        }
        ```
        """

        XCTAssertEqual(text, expectedText)
    }

    func testBuildTextFromApprovalRequests_MultipleRequests_FormatsCorrectly() {
        let request1 = MCPApprovalRequest(
            id: "req1",
            toolName: "tool1",
            serverLabel: "server1",
            arguments: "{\"k1\": \"v1\"}",
            status: .pending
        )
        let request2 = MCPApprovalRequest(
            id: "req2",
            toolName: "tool2",
            serverLabel: "server2",
            arguments: "{\"k2\": \"v2\"}",
            status: .pending
        )

        let text = MCPApprovalUtils.buildTextFromApprovalRequests([request1, request2])

        let expectedText = """
        Approval required to run **tool1** on **server1**.

        Arguments:
        ```json
        {
          "k1" : "v1"
        }
        ```

        ---

        Approval required to run **tool2** on **server2**.

        Arguments:
        ```json
        {
          "k2" : "v2"
        }
        ```
        """

        XCTAssertEqual(text, expectedText)
    }

    func testBuildTextFromApprovalRequests_InvalidJsonArguments_OmitsArguments() {
        let request = MCPApprovalRequest(
            id: "req1",
            toolName: "tool1",
            serverLabel: "server1",
            arguments: "invalid json string",
            status: .pending
        )

        let text = MCPApprovalUtils.buildTextFromApprovalRequests([request])

        let expectedText = "Approval required to run **tool1** on **server1**."
        XCTAssertEqual(text, expectedText)
    }

    func testBuildTextFromApprovalRequests_EmptyJsonArguments_OmitsArguments() {
        let request = MCPApprovalRequest(
            id: "req1",
            toolName: "tool1",
            serverLabel: "server1",
            arguments: "{}",
            status: .pending
        )

        let text = MCPApprovalUtils.buildTextFromApprovalRequests([request])

        let expectedText = "Approval required to run **tool1** on **server1**."
        XCTAssertEqual(text, expectedText)
    }

    func testBuildTextFromApprovalRequests_WhitespaceArguments_OmitsArguments() {
        let request = MCPApprovalRequest(
            id: "req1",
            toolName: "tool1",
            serverLabel: "server1",
            arguments: "   \n  ",
            status: .pending
        )

        let text = MCPApprovalUtils.buildTextFromApprovalRequests([request])

        let expectedText = "Approval required to run **tool1** on **server1**."
        XCTAssertEqual(text, expectedText)
    }
}
