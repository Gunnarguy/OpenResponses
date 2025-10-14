import SwiftUI

/// View for displaying MCP approval requests and handling user decisions
struct MCPApprovalView: View {
    let approval: MCPApprovalRequest
    let onApprove: (String?) -> Void  // Optional reason
    let onReject: (String?) -> Void   // Optional reason
    
    @State private var showingDetails = false
    @State private var reason = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Approval Required")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("MCP tool wants to execute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badge
                if approval.status != .pending {
                    statusBadge
                }
            }
            
            // Tool details
            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Server", value: approval.serverLabel, icon: "server.rack")
                detailRow(label: "Tool", value: approval.toolName, icon: "wrench.and.screwdriver.fill")
                
                // Arguments (expandable)
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingDetails.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Arguments")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if showingDetails {
                    ScrollView {
                        Text(formattedArguments)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)
                    }
                    .frame(maxHeight: 120)
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
            
            // Security warning
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("This tool will have access to the data shown above. Review carefully before approving.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(6)
            
            // Optional reason field
            if approval.status == .pending {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reason (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Why are you approving/rejecting this?", text: $reason)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
            } else if let savedReason = approval.reason, !savedReason.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(savedReason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(6)
            }
            
            // Action buttons
            if approval.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        isProcessing = true
                        onReject(reason.isEmpty ? nil : reason)
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    
                    Button {
                        isProcessing = true
                        onApprove(reason.isEmpty ? nil : reason)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: approval.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption2)
            
            Text(approval.status.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(approval.status == .approved ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (approval.status == .approved ? Color.green : Color.red).opacity(0.1)
        )
        .cornerRadius(6)
    }
    
    private var formattedArguments: String {
        // Try to pretty-print JSON
        if let data = approval.arguments.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return approval.arguments
    }
}

#Preview {
    VStack(spacing: 20) {
        MCPApprovalView(
            approval: MCPApprovalRequest(
                id: "mcpr_123",
                toolName: "search_files",
                serverLabel: "Dropbox",
                arguments: "{\"query\":\"*.pdf\",\"limit\":10}",
                status: .pending,
                reason: nil
            ),
            onApprove: { reason in
                print("Approved: \(reason ?? "no reason")")
            },
            onReject: { reason in
                print("Rejected: \(reason ?? "no reason")")
            }
        )
        
        MCPApprovalView(
            approval: MCPApprovalRequest(
                id: "mcpr_456",
                toolName: "send_email",
                serverLabel: "Gmail",
                arguments: "{\"to\":\"user@example.com\",\"subject\":\"Test\"}",
                status: .approved,
                reason: "Verified recipient"
            ),
            onApprove: { _ in },
            onReject: { _ in }
        )
    }
    .padding()
}
