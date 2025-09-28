import SwiftUI

/// A modal sheet prompting the user to approve or cancel pending safety checks before proceeding
/// with a computer-use action. Displays the checks and a concise summary of the action.
struct SafetyApprovalSheet: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Review required")
                    .font(.headline)
            }

            if let request = viewModel.pendingSafetyApproval {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The assistant wants to perform an action that needs your approval.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Action summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Requested action:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(request.action.type.capitalized)")
                            .font(.body)
                            .fontWeight(.medium)
                    }

                    // List safety checks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safety checks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(request.checks, id: \.id) { check in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(check.code.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(check.message)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            } else {
                Text("No pending approval.")
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Button(role: .cancel) {
                    viewModel.denySafetyChecks()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.approveSafetyChecks()
                } label: {
                    Text("Approve & Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
