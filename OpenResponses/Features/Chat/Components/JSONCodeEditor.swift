import SwiftUI

#if os(macOS)
import AppKit

/// JSON is literal text: smart quotes, dashes, and insertion rules corrupt requests. The Mac version is an NSTextView
/// with every substitution off.
struct JSONCodeEditor: NSViewRepresentable {
    @Binding var text: String
    var label = "JSON editor"
    @Environment(\.isEnabled) private var isEnabled

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        guard let view = scroll.documentView as? NSTextView else { return scroll }
        view.delegate = context.coordinator
        view.drawsBackground = false
        view.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        view.isRichText = false
        view.allowsUndo = true
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticTextReplacementEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isContinuousSpellCheckingEnabled = false
        view.isGrammarCheckingEnabled = false
        view.smartInsertDeleteEnabled = false
        view.textContainerInset = NSSize(width: 4, height: 6)
        view.setAccessibilityLabel(label)
        view.setAccessibilityIdentifier(label)
        view.string = text
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let view = scroll.documentView as? NSTextView else { return }
        view.isEditable = isEnabled
        view.setAccessibilityLabel(label)
        if view.string != text {
            let selection = view.selectedRange()
            view.string = text
            let length = (text as NSString).length
            let start = min(selection.location, length)
            view.setSelectedRange(NSRange(location: start, length: min(selection.length, length - start)))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: JSONCodeEditor
        init(_ parent: JSONCodeEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            parent.text = view.string
        }
    }
}
#else
/// JSON is literal text: smart quotes, dashes, and insertion rules corrupt requests.
struct JSONCodeEditor: UIViewRepresentable {
    @Binding var text: String
    var label = "JSON editor"
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .monospacedSystemFont(ofSize: 12, weight: .regular))
        view.adjustsFontForContentSizeCategory = true
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.spellCheckingType = .no
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.keyboardType = .asciiCapable
        view.accessibilityLabel = label
        view.accessibilityIdentifier = label
        let toolbar = UIToolbar()
        toolbar.items = [.flexibleSpace(), UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak view] _ in view?.resignFirstResponder() })]
        toolbar.sizeToFit()
        view.inputAccessoryView = toolbar
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        view.isEditable = isEnabled
        view.accessibilityLabel = label
        if view.text != text {
            let selection = view.selectedRange
            view.text = text
            let length = (text as NSString).length
            let start = min(selection.location, length)
            view.selectedRange = NSRange(location: start, length: min(selection.length, length - start))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: JSONCodeEditor
        init(_ parent: JSONCodeEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
    }
}
#endif
