import SwiftUI

/// Shows Python the assistant wants to run on this device and asks the user to run or decline it.
struct PythonRunApprovalSheet: View {
    let request: PythonRunRequest
    let onDecision: (Bool) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("The assistant wants to run this code on your device. It has the Python standard library only: no network, no files, no installs, and it stops after 30 seconds.")
                    .font(.subheadline)
                    .foregroundStyle(Color.accessibleSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView([.vertical, .horizontal]) {
                    Text(request.code)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Python code")
                .accessibilityValue(request.code)
                HStack(spacing: 12) {
                    Button(role: .cancel) { onDecision(false) } label: {
                        Text("Don't Run").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    Button { onDecision(true) } label: {
                        Text("Run").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("runPythonButton")
                }
            }
            .padding()
            .navigationTitle("Run Python?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
