import SwiftUI

// MARK: - MCP Approval Request Models

/// Represents an MCP tool approval request received during streaming
public struct MCPApprovalRequest: Identifiable, Codable {
    public let id: String
    public let type: String // "mcp_approval_request"
    public let serverLabel: String
    public let toolName: String
    public let arguments: String // JSON string of tool arguments
    public let requestContext: String? // Optional context about why the tool is needed
    
    public init(id: String, type: String, serverLabel: String, toolName: String, arguments: String, requestContext: String? = nil) {
        self.id = id
        self.type = type
        self.serverLabel = serverLabel
        self.toolName = toolName
        self.arguments = arguments
        self.requestContext = requestContext
    }
}

/// User's decision on an MCP approval request
public enum MCPApprovalDecision: String, CaseIterable {
    case approve = "approve"
    case deny = "deny"
    
    var displayName: String {
        switch self {
        case .approve: return "Approve"
        case .deny: return "Deny"
        }
    }
    
    var systemFeedback: String {
        switch self {
        case .approve: return "✅ MCP tool approved - proceeding with action"
        case .deny: return "❌ MCP tool denied - action canceled"
        }
    }
}

/// Response to send back for MCP approval
public struct MCPApprovalResponse: Codable {
    public let type: String = "mcp_approval_response"
    public let approvalRequestId: String
    public let approve: Bool
    
    public init(approvalRequestId: String, approve: Bool) {
        self.approvalRequestId = approvalRequestId
        self.approve = approve
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case approvalRequestId = "approval_request_id"
        case approve
    }
}

// MARK: - MCP Approval Sheet View

/// SwiftUI view for presenting MCP approval requests to the user
struct MCPApprovalSheet: View {
    let request: MCPApprovalRequest
    let onDecision: (MCPApprovalDecision) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var parsedArguments: [String: Any] {
        guard let data = request.arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MCP Tool Approval Required")
                            .font(.headline)
                        Text("Server: \(request.serverLabel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Divider()
                
                // Tool details
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        DetailRow(label: "Tool:", value: request.toolName)
                        DetailRow(label: "Server:", value: request.serverLabel)
                        
                        if let context = request.requestContext, !context.isEmpty {
                            DetailRow(label: "Context:", value: context)
                        }
                    }
                    
                    // Arguments section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tool Arguments:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if parsedArguments.isEmpty {
                            Text("No arguments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            ForEach(parsedArguments.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text("\(key):")
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Text(String(describing: value))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Warning section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Review Carefully")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    
                    Text("This MCP server is requesting to execute a tool with the above parameters. Only approve if you trust this action.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        onDecision(.deny)
                        dismiss()
                    } label: {
                        Text("Deny")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        onDecision(.approve)
                        dismiss()
                    } label: {
                        Text("Approve")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("MCP Approval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDecision(.deny)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.primary)
            Spacer()
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#Preview {
    MCPApprovalSheet(
        request: MCPApprovalRequest(
            id: "mcpr_example123",
            type: "mcp_approval_request",
            serverLabel: "github",
            toolName: "create_pull_request",
            arguments: #"{"title": "Fix bug", "body": "This PR fixes the critical bug", "branch": "main"}"#,
            requestContext: "The assistant wants to create a pull request to fix the reported bug."
        )
    ) { decision in
        print("Decision: \(decision)")
    }
}