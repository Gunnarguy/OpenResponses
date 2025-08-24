import SwiftUI

/// Extensions and utilities to improve accessibility throughout the app.
enum AccessibilityUtils {
    /// Common accessibility identifiers used for UI testing.
    enum Identifier {
        static let chatInput = "chatInputTextField"
        static let sendButton = "sendMessageButton"
        static let settingsButton = "settingsButton"
        static let clearConversationButton = "clearConversationButton"
        static let apiKeyField = "apiKeySecureField"
        static let messagesScrollView = "messagesScrollView"
    }
    
    /// Common accessibility hints for UI elements.
    enum Hint {
        static let chatInput = "Type your message here to chat with the AI assistant"
        static let sendButton = "Send your message to the AI assistant"
        static let settingsButton = "Open settings to configure the app"
        static let clearConversation = "Clear the current conversation history"
        static let apiKeyField = "Enter your OpenAI API key here"
        static let fileAttachButton = "Attach a file to your message"
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Sets commonly used accessibility attributes for a view.
    /// - Parameters:
    ///   - label: The accessibility label.
    ///   - hint: The accessibility hint.
    ///   - identifier: The accessibility identifier (for UI testing).
    ///   - traits: The accessibility traits.
    /// - Returns: A view with the accessibility attributes set.
    func accessibilityConfiguration(
        label: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: AccessibilityTraits? = nil
    ) -> some View {
        return self
            .modifier(AccessibilityConfigurationModifier(
                label: label,
                hint: hint,
                identifier: identifier,
                traits: traits
            ))
    }
    
    /// Makes a view more accessible for screen readers by ensuring adequate tap target size.
    /// - Parameter extraPadding: Additional padding to add around the view.
    /// - Returns: A view with enhanced touch area.
    func accessibleTapTarget(extraPadding: CGFloat = 8) -> some View {
        self
            .padding(extraPadding)
            .contentShape(Rectangle())
    }
}

// MARK: - Accessibility Color Extensions

extension Color {
    /// Returns a high-contrast version of the color suitable for text.
    /// - Returns: A color with higher contrast suitable for text.
    func accessibleTextColor() -> Color {
        // This is a simple implementation; you may want to use a more sophisticated approach
        // based on the color's luminance.
        return self.opacity(1.0)
    }
    
    /// Returns a color that is appropriate for text on top of the given background color.
    /// - Parameter backgroundColor: The background color.
    /// - Returns: A text color with good contrast against the background.
    static func accessibleTextColor(for backgroundColor: Color) -> Color {
        // Simple implementation - use white for dark backgrounds and black for light backgrounds
        // A more sophisticated implementation would calculate the contrast ratio
        return .primary
    }
}

// MARK: - Accessibility Modifiers

/// A view modifier that applies accessibility configuration.
struct AccessibilityConfigurationModifier: ViewModifier {
    let label: String?
    let hint: String?
    let identifier: String?
    let traits: AccessibilityTraits?
    
    func body(content: Content) -> some View {
        content
            .transformIf(label != nil) { content in
                content.accessibilityLabel(Text(label!))
            }
            .transformIf(hint != nil) { content in
                content.accessibilityHint(Text(hint!))
            }
            .transformIf(identifier != nil) { content in
                content.accessibilityIdentifier(identifier!)
            }
            .transformIf(traits != nil) { content in
                content.accessibilityAddTraits(traits!)
            }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Conditionally applies a transformation to a view.
    /// - Parameters:
    ///   - condition: The condition that determines if the transformation is applied.
    ///   - transform: The transformation to apply to the view.
    /// - Returns: The transformed view if the condition is true, otherwise the original view.
    @ViewBuilder func transformIf<T: View>(
        _ condition: Bool,
        transform: (Self) -> T
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
