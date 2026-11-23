import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// The Mac app is a native macOS target (3.1, 2026-11-22), built from the same sources as iPhone and iPad, the way
// OpenIntelligence does it. Catalyst counts as os(iOS), so Mac-only code here is `#if os(macOS)`. On the Mac the UIKit
// names the shared code uses map to their AppKit counterparts, and the iOS-only SwiftUI modifiers become no-ops, so
// the iPhone and iPad code reads as it did.

#if os(macOS)
typealias UIImage = NSImage
typealias UIColor = NSColor
typealias UIFont = NSFont

extension NSImage {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }

    /// AppKit images have no scale to set; the data's own pixel size is kept.
    convenience init?(data: Data, scale: CGFloat) { self.init(data: data) }

    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    /// The image as a CGImage at its full pixel size, as UIImage.cgImage gives it.
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    /// AppKit images carry their pixels in their representations; points equal pixels for the images this app makes.
    var scale: CGFloat { 1 }

    func pngData() -> Data? { bitmap?.representation(using: .png, properties: [:]) }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        bitmap?.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    private var bitmap: NSBitmapImageRep? {
        if let cg = cgImage { return NSBitmapImageRep(cgImage: cg) }
        guard let tiff = tiffRepresentation else { return nil }
        return NSBitmapImageRep(data: tiff)
    }
}

extension NSColor {
    static var systemBackground: NSColor { .windowBackgroundColor }
    static var secondarySystemBackground: NSColor { .controlBackgroundColor }
    static var secondarySystemGroupedBackground: NSColor { .controlBackgroundColor }
    static var tertiarySystemFill: NSColor { .quaternaryLabelColor }
    static var separator: NSColor { .separatorColor }
    // AppKit has its own systemGray; declaring one here shadowed it and made every gray below call itself until the
    // stack overflowed (Xcode Cloud run 58's "infinite recursion" warning, 2026-11-22).
    static var systemGray3: NSColor { NSColor.systemGray.withAlphaComponent(0.6) }
    static var systemGray6: NSColor { .controlBackgroundColor }
    static var systemGray5: NSColor { NSColor.systemGray.withAlphaComponent(0.25) }
    static var systemGray4: NSColor { NSColor.systemGray.withAlphaComponent(0.4) }
    static var systemGray2: NSColor { NSColor.systemGray.withAlphaComponent(0.8) }
    static var systemGroupedBackground: NSColor { .windowBackgroundColor }
    static var tertiarySystemBackground: NSColor { .textBackgroundColor }
    static var secondarySystemFill: NSColor { .tertiaryLabelColor }
}

extension Image {
    init(uiImage: NSImage) { self.init(nsImage: uiImage) }
}

extension Color {
    init(uiColor: NSColor) { self.init(nsColor: uiColor) }
}

/// The pasteboard calls the shared code makes, on the Mac's general pasteboard.
enum UIPasteboard {
    static let general = MacPasteboard()
}

struct MacPasteboard {
    var string: String? {
        get { NSPasteboard.general.string(forType: .string) }
        nonmutating set {
            NSPasteboard.general.clearContents()
            if let newValue { NSPasteboard.general.setString(newValue, forType: .string) }
        }
    }
}
#endif

/// Keyboard kinds the shared code asks for; the Mac has one keyboard, so they do nothing there.
enum PlatformKeyboard {
    case url, numberPad
}

/// Autocapitalization the shared code asks for; Mac text fields don't autocapitalize.
enum PlatformCapitalization {
    case never, sentences, words, characters
}

extension View {
    /// An inline navigation title on iPhone and iPad; the Mac puts the title in the window's title bar.
    @ViewBuilder func inlineNavigationTitle() -> some View {
        #if os(macOS)
        self
        #else
        navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder func platformKeyboard(_ kind: PlatformKeyboard) -> some View {
        #if os(macOS)
        self
        #else
        switch kind {
        case .url: keyboardType(.URL)
        case .numberPad: keyboardType(.numberPad)
        }
        #endif
    }

    @ViewBuilder func platformCapitalization(_ kind: PlatformCapitalization) -> some View {
        #if os(macOS)
        self
        #else
        switch kind {
        case .never: textInputAutocapitalization(.never)
        case .sentences: textInputAutocapitalization(.sentences)
        case .words: textInputAutocapitalization(.words)
        case .characters: textInputAutocapitalization(.characters)
        }
        #endif
    }

    /// Mac sheets need a size; without one SwiftUI shrinks them to their content. Forms inside are grouped, as Mac
    /// settings are (an unstyled Mac Form is two columns of labels and controls). Does nothing on iPhone and iPad.
    @ViewBuilder func macSheetFrame(width: CGFloat = 560, height: CGFloat = 620) -> some View {
        #if os(macOS)
        formStyle(.grouped)
            .frame(minWidth: width, idealWidth: width + 80, maxWidth: 1000, minHeight: height * 0.8, idealHeight: height)
        #else
        self
        #endif
    }

    /// A full-screen cover on iPhone and iPad; a large sheet on the Mac, which has no full-screen cover.
    @ViewBuilder func platformFullScreenCover<Content: View>(isPresented: Binding<Bool>,
                                                             @ViewBuilder content: @escaping () -> Content) -> some View {
        #if os(macOS)
        sheet(isPresented: isPresented) { content().frame(minWidth: 760, idealWidth: 900, minHeight: 560, idealHeight: 700) }
        #else
        fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }

    /// Lets text grow to its full height on iPhone and iPad. On the Mac it does nothing: AppKit sizes a window from its
    /// content's minimum, measured at a narrow width, where such text runs to one character a line and grows tall
    /// enough to push the rest of the window out of view (2026-11-22, the chat's notice under the input).
    @ViewBuilder func growsVerticallyOnIOS() -> some View {
        #if os(macOS)
        self
        #else
        fixedSize(horizontal: false, vertical: true)
        #endif
    }

    /// A grouped Form on the Mac (an unstyled Form there is two columns and doesn't scroll). Does nothing elsewhere.
    @ViewBuilder func macGroupedForm() -> some View {
        #if os(macOS)
        formStyle(.grouped)
        #else
        self
        #endif
    }
}

extension ToolbarItemPlacement {
    /// The leading side of the navigation bar on iPhone and iPad; the toolbar's navigation area on the Mac.
    static var leadingBar: ToolbarItemPlacement {
        #if os(macOS)
        .navigation
        #else
        .navigationBarLeading
        #endif
    }

    /// The trailing side of the navigation bar on iPhone and iPad; the toolbar's primary actions on the Mac.
    static var trailingBar: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .navigationBarTrailing
        #endif
    }
}

/// Draws an image of `size` points with a top-left origin, on UIKit's renderer or an AppKit drawing handler.
func renderPlatformImage(size: CGSize, _ draw: @escaping (CGContext) -> Void) -> UIImage {
    #if os(macOS)
    return NSImage(size: size, flipped: true) { _ in
        guard let context = NSGraphicsContext.current?.cgContext else { return false }
        draw(context)
        return true
    }
    #else
    return UIGraphicsImageRenderer(size: size).image { draw($0.cgContext) }
    #endif
}

/// Opens a URL in the default browser or app.
@MainActor func openExternalURL(_ url: URL) {
    #if os(macOS)
    NSWorkspace.shared.open(url)
    #else
    UIApplication.shared.open(url)
    #endif
}
