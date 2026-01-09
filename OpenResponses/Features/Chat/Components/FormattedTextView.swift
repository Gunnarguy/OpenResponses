import SwiftUI

/// A view that formats text to display basic Markdown elements like bold, italics, and code blocks.
struct FormattedTextView: View {
    let text: String

    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Split the text by code blocks to handle them separately
            let parts = text.components(separatedBy: "```")

            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index % 2 == 0 {
                    // This is regular text, parse for inline markdown
                    parseAndDisplayText(part.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    // This is a code block
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(part.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.system(size: codeBlockFontSize, design: .monospaced))
                            .padding(10)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(Color.white)
                            .cornerRadius(8)
                            .textSelection(.enabled)
                            .accessibilityLabel("Code block")
                            .accessibilityHint("Swipe horizontally to view more code")
                    }
                }
            }
        }
    }

    /// Parses a string for inline markdown and returns a composed Text view.
    private func parseAndDisplayText(_ string: String) -> some View {
        do {
            let attributedString = try AttributedString(markdown: string)
            // Optional: Customize inline code style if needed, but system default is usually fine.
            return Text(attributedString)
        } catch {
            return Text(string)
        }
    }

    /// Removes markdown formatting for accessibility readers
    private func cleanTextForAccessibility(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
    }

    /// Responsive font size for code blocks based on accessibility settings
    private var codeBlockFontSize: CGFloat {
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge:
            return 20
        case .accessibilityExtraExtraLarge:
            return 18
        case .accessibilityExtraLarge:
            return 16
        case .accessibilityLarge:
            return 15
        default:
            return 14
        }
    }

    /// Responsive font size for inline code based on accessibility settings
    private var inlineCodeFontSize: CGFloat {
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge:
            return 18
        case .accessibilityExtraExtraLarge:
            return 16
        case .accessibilityExtraLarge:
            return 15
        case .accessibilityLarge:
            return 14
        default:
            return 13
        }
    }

}
