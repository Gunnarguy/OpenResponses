import SwiftUI
import Combine

/// Global visibility toggle holder for the activity feed; persists only in-memory.
final class ActivityVisibility: ObservableObject {
    static let shared = ActivityVisibility()
    @Published var isVisible: Bool = true
}

/// A compact view that lists short lines describing what the app is doing under the hood.
struct ActivityFeedView: View {
    let lines: [String]
    @State private var isExpanded = false
    private let maxVisibleLines = 5
    private let maxExpandedHeight: CGFloat = 180
    var body: some View {
        let visibleLines = Array(lines.suffix(maxVisibleLines))
        let hasOverflow = lines.count > maxVisibleLines
        VStack(alignment: .leading, spacing: 4) {
            if isExpanded, hasOverflow {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(lines.indices, id: \.self) { i in
                            Text("• \(lines[i])")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textSelection(.disabled)
                                .fontDesign(.monospaced)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                    }
                }
                .frame(maxHeight: maxExpandedHeight)
            } else {
                ForEach(visibleLines.indices, id: \.self) { i in
                    Text("• \(visibleLines[i])")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.disabled)
                        .fontDesign(.monospaced)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            if hasOverflow {
                Button(action: { isExpanded.toggle() }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show less" : "Show more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if !isExpanded, hasOverflow {
                Text("… \(lines.count - maxVisibleLines) more")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textSelection(.disabled)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    // Avoid complex transitions during frequent updates to prevent flicker
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Activity details")
        .animation(.default, value: lines.count)
    }
}

/// A small button that toggles the activity details visibility.
struct ActivityToggleButton: View {
    @ObservedObject private var visibility = ActivityVisibility.shared
    var body: some View {
        Button(action: { visibility.isVisible.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: visibility.isVisible ? "chevron.down.circle" : "chevron.right.circle")
                Text("Details")
            }
            .font(.caption)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(visibility.isVisible ? "Hide details" : "Show details")
    }
}
