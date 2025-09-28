import SwiftUI

/// Compact chip that shows conversation-level token usage.
/// - Shows final totals (in/out/total) when available.
/// - During streaming, shows a live estimated output count if totals aren't final yet.
struct ConversationTokenCounterView: View {
    let usage: TokenUsage

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "number")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            Text(displayText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Token usage: \(displayText)")
    }

    private var displayText: String {
        let inTxt = usage.input.map { "in: \($0)" }
        let outTxt = usage.output.map { "out: \($0)" }
        let totTxt = usage.total.map { "total: \($0)" }
        let parts = [inTxt, outTxt, totTxt].compactMap { $0 }
        if !parts.isEmpty { return parts.joined(separator: " • ") }
        if let est = usage.estimatedOutput, est > 0 { return "out (est): \(est)" }
        return "tokens: —"
    }
}

struct ConversationTokenCounterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ConversationTokenCounterView(usage: TokenUsage(estimatedOutput: 128, input: nil, output: nil, total: nil))
            ConversationTokenCounterView(usage: TokenUsage(estimatedOutput: nil, input: 900, output: 600, total: 1500))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
