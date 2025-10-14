import SwiftUI
import UniformTypeIdentifiers

/// A SwiftUI view that wraps the `UIDocumentPickerViewController` to allow users to select documents.
/// This struct conforms to `UIViewControllerRepresentable` to bridge the UIKit view controller
/// into the SwiftUI view hierarchy.
/// 
/// **Now enhanced with FileConverterService integration for universal file type support!**
struct DocumentPicker: UIViewControllerRepresentable {
    /// A binding to an array of `Data` objects, which will be populated with the contents of the selected files.
    @Binding var selectedFileData: [Data]
    /// A binding to an array of `String` objects for the filenames.
    @Binding var selectedFilenames: [String]
    /// Optional callback for conversion status feedback
    var onConversionStatus: ((String) -> Void)? = nil

    /// Creates the `UIDocumentPickerViewController` instance.
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Allow ALL content types - FileConverterService will handle validation and conversion
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
            .presentation,
            .image,
            .movie,
            .audio,
            .data, // Catch-all for binary files
            .content // Catch-all for any content
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
            
            AppLogger.log("📁 User selected \(urls.count) file(s) for chat attachment", category: .fileManager, level: .info)
            
            // Process files asynchronously with FileConverterService
            Task {
                for (index, url) in urls.enumerated() {
                    // Since we use asCopy: true, try direct access first
                    // If that fails, try with security-scoped access
                    var needsSecurityScope = false
                    var fileData: Data?
                    
                    // Attempt 1: Direct access (works for copied files)
                    do {
                        fileData = try Data(contentsOf: url)
                        AppLogger.log("✅ Direct file access successful for \(url.lastPathComponent)", category: .fileManager, level: .info)
                    } catch {
                        // Attempt 2: Security-scoped access
                        needsSecurityScope = true
                        AppLogger.log("ℹ️ Direct access failed, trying security-scoped access for \(url.lastPathComponent)", category: .fileManager, level: .info)
                    }
                    
                    // If direct access failed, try security-scoped
                    if needsSecurityScope {
                        guard url.startAccessingSecurityScopedResource() else {
                            let errorMessage = "❌ Failed to access \(url.lastPathComponent) - File permissions denied"
                            AppLogger.log("❌ Security-scoped resource access denied for \(url.lastPathComponent)", category: .fileManager, level: .error)
                            AppLogger.log("   URL: \(url.path)", category: .fileManager, level: .error)
                            AppLogger.log("   URL isFileURL: \(url.isFileURL)", category: .fileManager, level: .error)
                            await MainActor.run {
                                parent.onConversionStatus?(errorMessage)
                            }
                            continue
                        }
                        
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        // Try reading after security scope granted
                        do {
                            fileData = try Data(contentsOf: url)
                            AppLogger.log("✅ Security-scoped access successful for \(url.lastPathComponent)", category: .fileManager, level: .info)
                        } catch {
                            let errorMessage = "❌ Failed to read \(url.lastPathComponent): \(error.localizedDescription)"
                            AppLogger.log("❌ Failed to read file even with security scope: \(error)", category: .fileManager, level: .error)
                            await MainActor.run {
                                parent.onConversionStatus?(errorMessage)
                            }
                            continue
                        }
                    }
                    
                    // If we got here, we have the file data
                    guard let data = fileData else {
                        let errorMessage = "❌ Failed to load \(url.lastPathComponent)"
                        AppLogger.log("❌ File data is nil for \(url.lastPathComponent)", category: .fileManager, level: .error)
                        await MainActor.run {
                            parent.onConversionStatus?(errorMessage)
                        }
                        continue
                    }
                    
                    do {
                        AppLogger.log("📤 [\(index + 1)/\(urls.count)] Processing: \(url.lastPathComponent) (\(data.count) bytes)", category: .fileManager, level: .info)
                        
                        // Use FileConverterService to validate and convert if needed
                        let conversionResult = try await FileConverterService.processFile(url: url)
                        
                        // Update UI with status
                        if conversionResult.wasConverted {
                            let statusMessage = "🔄 Converted \(conversionResult.originalFilename) via \(conversionResult.conversionMethod)"
                            AppLogger.log("   \(statusMessage)", category: .fileManager, level: .info)
                            await MainActor.run {
                                parent.onConversionStatus?(statusMessage)
                            }
                        } else {
                            AppLogger.log("   ✅ File natively supported, no conversion needed", category: .fileManager, level: .info)
                        }
                        
                        // Add processed file data
                        await MainActor.run {
                            parent.selectedFileData.append(conversionResult.convertedData)
                            parent.selectedFilenames.append(conversionResult.filename)
                        }
                        
                        AppLogger.log("   ✅ Successfully processed \(conversionResult.filename)", category: .fileManager, level: .info)
                        
                    } catch FileConversionError.fileTooLarge(let size, let limit) {
                        let errorMessage = "❌ \(url.lastPathComponent): File size (\(formatBytes(size))) exceeds limit (\(formatBytes(limit)))"
                        AppLogger.log(errorMessage, category: .fileManager, level: .error)
                        await MainActor.run {
                            parent.onConversionStatus?(errorMessage)
                        }
                    } catch {
                        let errorMessage = "❌ Failed to process \(url.lastPathComponent): \(error.localizedDescription)"
                        AppLogger.log(errorMessage, category: .fileManager, level: .error)
                        await MainActor.run {
                            parent.onConversionStatus?(errorMessage)
                        }
                    }
                }
                
                AppLogger.log("🎉 Completed processing \(urls.count) file(s): \(parent.selectedFileData.count) succeeded", category: .fileManager, level: .info)
                
                // Show completion message
                if parent.selectedFileData.count > 0 {
                    let successMessage = "✅ Successfully attached \(parent.selectedFileData.count) file\(parent.selectedFileData.count == 1 ? "" : "s")"
                    await MainActor.run {
                        parent.onConversionStatus?(successMessage)
                    }
                } else if urls.count > 0 {
                    // All files failed
                    let failureMessage = "❌ Failed to attach \(urls.count) file\(urls.count == 1 ? "" : "s") - Check file permissions and try again"
                    await MainActor.run {
                        parent.onConversionStatus?(failureMessage)
                    }
                }
            }
        }
        
        /// Helper to format bytes for user-friendly display
        private func formatBytes(_ bytes: Int64) -> String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
    }
}
