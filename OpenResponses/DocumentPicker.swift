import SwiftUI
import UniformTypeIdentifiers

/// A SwiftUI view that wraps the `UIDocumentPickerViewController` to allow users to select documents.
/// This struct conforms to `UIViewControllerRepresentable` to bridge the UIKit view controller
/// into the SwiftUI view hierarchy.
struct DocumentPicker: UIViewControllerRepresentable {
    /// A binding to an array of `Data` objects, which will be populated with the contents of the selected files.
    @Binding var selectedFileData: [Data]
    /// A binding to an array of `String` objects for the filenames.
    @Binding var selectedFilenames: [String]

    /// Creates the `UIDocumentPickerViewController` instance.
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Allow selection of common document types.
        let supportedTypes: [UTType] = [
            .pdf,
            .text,
            .plainText,
            .sourceCode,
            .zip,
            .commaSeparatedText,
            .json,
            .rtf,
            .spreadsheet,
            .presentation
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    /// Updates the view controller. This is not needed for the document picker.
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    /// Creates the coordinator that will handle delegate callbacks from the `UIDocumentPickerViewController`.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// The coordinator class to handle delegate methods from the document picker.
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        /// Called when the user finishes picking documents.
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFileData.removeAll()
            parent.selectedFilenames.removeAll()
            
            for url in urls {
                // Start accessing the security-scoped resource.
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to start accessing security-scoped resource for \(url.lastPathComponent)")
                    continue
                }

                do {
                    let data = try Data(contentsOf: url)
                    parent.selectedFileData.append(data)
                    parent.selectedFilenames.append(url.lastPathComponent)
                } catch {
                    print("Failed to read data from \(url.lastPathComponent): \(error)")
                }

                // Stop accessing the security-scoped resource.
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
