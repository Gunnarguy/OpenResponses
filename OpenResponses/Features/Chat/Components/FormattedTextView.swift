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
    /// Handles block elements (lists, paragraphs) by splitting into lines.
    @ViewBuilder
    private func parseAndDisplayText(_ string: String) -> some View {
        let lines = string.components(separatedBy: "\n")

        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Empty line = paragraph break
                    Spacer().frame(height: 8)
                } else if let bulletContent = extractBulletContent(from: line) {
                    // Bullet list item
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        renderInlineMarkdown(bulletContent)
                    }
                    .padding(.leading, 4)
                } else if let (number, numberedContent) = extractNumberedContent(from: line) {
                    // Numbered list item
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(number).")
                            .foregroundColor(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                        renderInlineMarkdown(numberedContent)
                    }
                    .padding(.leading, 4)
                } else {
                    // Regular paragraph line
                    renderInlineMarkdown(line)
                }
            }
        }
    }

    /// Extracts content after bullet markers (-, *, •)
    private func extractBulletContent(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") {
            return String(trimmed.dropFirst(2))
        } else if trimmed.hasPrefix("* ") {
            return String(trimmed.dropFirst(2))
        } else if trimmed.hasPrefix("• ") {
            return String(trimmed.dropFirst(2))
        }
        return nil
    }

    /// Extracts content after numbered markers (1., 2., etc.)
    private func extractNumberedContent(from line: String) -> (Int, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = #"^(\d+)\.\s+(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let contentRange = Range(match.range(at: 2), in: trimmed),
              let number = Int(trimmed[numberRange])
        else {
            return nil
        }
        return (number, String(trimmed[contentRange]))
    }

    /// Renders inline markdown (bold, italic, code) within a line
    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        if let attributedString = try? AttributedString(markdown: text) {
            Text(attributedString)
                .textSelection(.enabled)
        } else {
            Text(text)
                .textSelection(.enabled)
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
