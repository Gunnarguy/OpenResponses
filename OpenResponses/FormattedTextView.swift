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
        var attributedString = AttributedString()
        
        // Use a simple regex-like approach to find markdown patterns
        var remainingText = Substring(string)
        
        // Regex to find markdown patterns: **bold**, *italic*, `code`
        let pattern = /(\*\*|`|\*)(.*?)\1/
        
        while let match = remainingText.firstMatch(of: pattern) {
            // Add the text before the match
            attributedString.append(AttributedString(remainingText[..<match.range.lowerBound]))
            
            // Get the content and the delimiter
            let delimiter = match.1
            let content = match.2
            var styledContent = AttributedString(content)
            
            // Apply styling based on the delimiter
            switch delimiter {
            case "**":
                styledContent.font = .body.bold()
            case "*":
                styledContent.font = .body.italic()
            case "`":
                styledContent.font = .system(size: inlineCodeFontSize, design: .monospaced)
                styledContent.backgroundColor = .gray.opacity(0.2)
            default:
                break
            }
            
            attributedString.append(styledContent)
            
            // Update the remaining text
            remainingText = remainingText[match.range.upperBound...]
        }
        
        // Add any remaining text after the last match
        attributedString.append(AttributedString(remainingText))
        
        return Text(attributedString)
            .textSelection(.enabled)
            .accessibilityElement()
            .accessibilityLabel(cleanTextForAccessibility(string))
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
