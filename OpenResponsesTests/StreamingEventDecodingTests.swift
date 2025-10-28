import Foundation
import XCTest
@testable import OpenResponses

final class StreamingEventDecodingTests: XCTestCase {
    func testStreamingEventDecodesMCPListToolsWithNulls() throws {
        let json = """
        {
          "type": "response.completed",
          "sequence_number": 10,
          "response": {
            "id": "resp_123",
            "object": "response",
            "created_at": 1761670071,
            "status": "completed",
            "background": false,
            "error": null,
            "incomplete_details": null,
            "instructions": "You are a helpful assistant.",
            "max_output_tokens": null,
            "max_tool_calls": null,
            "model": "gpt-5-test",
            "output": [
              {
                "id": "mcpl_123",
                "type": "mcp_list_tools",
                "server_label": "Gmail",
                "tools": [
                  {
                    "name": "fetch_messages",
                    "description": "Read Gmail messages",
                    "metadata": null,
                    "annotations": {
                      "read_only": true
                    },
                    "input_schema": {
                      "type": "object",
                      "properties": {
                        "message_ids": {
                          "type": "array",
                          "description": null,
                          "items": {
                            "type": "string"
                          }
                        }
                      },
                      "required": ["message_ids"]
                    }
                  }
                ]
              }
            ]
          }
        }
        """

        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

        XCTAssertEqual(event.type, "response.completed")
        XCTAssertEqual(event.sequenceNumber, 10)

        guard let outputItem = event.response?.output?.first else {
            XCTFail("Expected output item")
            return
        }

        XCTAssertEqual(outputItem.serverLabel, "Gmail")
        XCTAssertEqual(outputItem.tools?.count, 1)

    guard let tool = outputItem.tools?.first else {
      XCTFail("Expected tool payload")
      return
    }

    XCTAssertEqual(tool["name"]?.value as? String, "fetch_messages")
    XCTAssertEqual(tool["metadata"]?.jsonString(), "null")

    guard let schemaJSON = tool["input_schema"]?.jsonString(),
        let schemaData = schemaJSON.data(using: .utf8),
        let schema = try JSONSerialization.jsonObject(with: schemaData) as? [String: Any] else {
      XCTFail("Expected input_schema JSON")
      return
    }

    XCTAssertEqual(schema["type"] as? String, "object")

    guard let required = schema["required"] as? [String] else {
      XCTFail("Expected required array")
      return
    }
    XCTAssertEqual(required, ["message_ids"])

    guard let properties = schema["properties"] as? [String: Any],
        let messageIds = properties["message_ids"] as? [String: Any] else {
      XCTFail("Expected properties.message_ids dictionary")
      return
    }

    XCTAssertEqual(messageIds["type"] as? String, "array")
    XCTAssertTrue(messageIds["description"] is NSNull)

    guard let items = messageIds["items"] as? [String: Any] else {
      XCTFail("Expected items dictionary")
      return
    }
    XCTAssertEqual(items["type"] as? String, "string")
  }

  func testStreamingEventDecodesApprovalRequestArgumentsObject() throws {
    let json = """
    {
      "type": "response.mcp_approval_request.added",
      "sequence_number": 4,
      "name": "list_messages",
      "server_label": "Gmail",
      "arguments": {
      "query": "from:boss@example.com",
      "max_results": 5
      },
      "approval_request_id": "mcpr_123",
      "item": {
      "id": "mcpr_123",
      "type": "mcp_approval_request",
      "server_label": "Gmail",
      "name": "list_messages",
      "arguments": {
        "query": "from:boss@example.com",
        "max_results": 5
      }
      }
    }
    """

    let data = Data(json.utf8)
    let event = try JSONDecoder().decode(StreamingEvent.self, from: data)

    XCTAssertEqual(event.type, "response.mcp_approval_request.added")
    XCTAssertEqual(event.sequenceNumber, 4)
    XCTAssertEqual(event.serverLabel, "Gmail")
    XCTAssertEqual(event.name, "list_messages")
    XCTAssertEqual(event.approvalRequestId, "mcpr_123")

    guard let topArguments = event.arguments,
        let topArgsData = topArguments.data(using: .utf8),
        let topArgs = try JSONSerialization.jsonObject(with: topArgsData) as? [String: Any] else {
      XCTFail("Expected top-level arguments JSON")
      return
    }

    XCTAssertEqual(topArgs["query"] as? String, "from:boss@example.com")
    XCTAssertEqual(topArgs["max_results"] as? Int, 5)

    guard let item = event.item else {
      XCTFail("Expected embedded item")
      return
    }
    XCTAssertEqual(item.serverLabel, "Gmail")
    XCTAssertEqual(item.name, "list_messages")

    guard let itemArguments = item.arguments,
        let itemArgsData = itemArguments.data(using: .utf8),
        let itemArgs = try JSONSerialization.jsonObject(with: itemArgsData) as? [String: Any] else {
      XCTFail("Expected item arguments JSON")
      return
    }

    XCTAssertEqual(itemArgs["query"] as? String, "from:boss@example.com")
    XCTAssertEqual(itemArgs["max_results"] as? Int, 5)
    }
}
