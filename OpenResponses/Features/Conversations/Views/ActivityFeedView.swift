import SwiftUI
import Combine

/// Global visibility toggle holder for the activity feed; persists only in-memory.
final class ActivityVisibility: ObservableObject {
    static let shared = ActivityVisibility()
    @Published var isVisible: Bool = false // Collapsed by default for cleaner UI
}

/// A compact view that lists short lines describing what the app is doing under the hood.
struct ActivityFeedView: View {
    let lines: [String]
    var onClear: (() -> Void)?
    @State private var isExpanded = false
    private let maxVisibleLines = 3
    private let maxExpandedHeight: CGFloat = 120

    var body: some View {
        let visibleLines = Array(lines.suffix(maxVisibleLines))
        let hasOverflow = lines.count > maxVisibleLines
        let overflowCount = lines.count - maxVisibleLines

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

            // Compact action row: expand/collapse + clear
            HStack(spacing: 12) { 
                if hasOverflow {
                    Button(action: { isExpanded.toggle() }) { 
                        HStack(spacing: 2) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            Text(isExpanded ? "Less" : "+\(overflowCount)")
                        }
                        .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if let onClear {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(6)
            .background(Color(.systemGray6).opacity(0.6))
            .cornerRadius(6)
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
