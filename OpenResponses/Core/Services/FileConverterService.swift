import Foundation
import PDFKit
import Vision
import AVFoundation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Universal file converter that transforms unsupported file types into OpenAI-compatible formats
/// Acts as a "blender" to make any file type ingestible by the API
class FileConverterService {
    
    // MARK: - File Size Limits
    
    static let maxFileSizeBytes: Int64 = 512 * 1024 * 1024 // 512 MB
    static let maxTokensPerFile: Int = 5_000_000 // 5 million tokens
    
    // MARK: - Supported Types by OpenAI
    
    /// File extensions natively supported by OpenAI's Files API
    static let openAISupportedExtensions: Set<String> = [
        "c", "cpp", "cs", "css", "csv", "doc", "docx", "gif", "html", "java",
        "jpeg", "jpg", "js", "json", "md", "pdf", "php", "png", "pptx", "py",
        "rb", "sh", "tar", "tex", "ts", "txt", "webp", "xlsx", "xml", "zip"
    ]
    
    // MARK: - Conversion Result
    
    struct ConversionResult {
        let convertedData: Data
        let filename: String
        let originalFilename: String
        let conversionMethod: String
        let wasConverted: Bool
    }
    
    // MARK: - File Validation
    
    /// Validates if a file can be processed
    static func validateFile(url: URL) throws {
        AppLogger.log("🔍 Validating file: \(url.lastPathComponent)", category: .fileManager, level: .info)
        
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileConversionError.fileNotFound
        }
        
        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw FileConversionError.unableToReadFile
        }
        
        AppLogger.log("   📏 File size: \(formatBytes(fileSize))", category: .fileManager, level: .debug)
        
        if fileSize > maxFileSizeBytes {
            AppLogger.log("   ❌ File exceeds 512 MB limit", category: .fileManager, level: .error)
            throw FileConversionError.fileTooLarge(fileSize: fileSize, maxSize: maxFileSizeBytes)
        }
        
        if fileSize == 0 {
            AppLogger.log("   ❌ File is empty", category: .fileManager, level: .error)
            throw FileConversionError.emptyFile
        }
        
        AppLogger.log("   ✅ File validation passed", category: .fileManager, level: .info)
    }
    
    // MARK: - Main Conversion Method
    
    /// Processes a file and converts it if necessary to an OpenAI-compatible format
    static func processFile(url: URL) async throws -> ConversionResult {
        try validateFile(url: url)
        
        let fileExtension = url.pathExtension.lowercased()
        let filename = url.lastPathComponent
        
        AppLogger.log("🔄 Processing file: \(filename)", category: .fileManager, level: .info)
        AppLogger.log("   📎 Extension: .\(fileExtension)", category: .fileManager, level: .debug)
        
        // Check if already supported
        if openAISupportedExtensions.contains(fileExtension) {
            AppLogger.log("   ✅ File type natively supported by OpenAI", category: .fileManager, level: .info)
            let data = try Data(contentsOf: url)
            return ConversionResult(
                convertedData: data,
                filename: filename,
                originalFilename: filename,
                conversionMethod: "None (natively supported)",
                wasConverted: false
            )
        }
        
        AppLogger.log("   🔄 File type not natively supported - attempting conversion", category: .fileManager, level: .info)
        
        // Attempt conversion based on file type
        return try await convertUnsupportedFile(url: url, extension: fileExtension)
    }
    
    // MARK: - Conversion Logic
    
    private static func convertUnsupportedFile(url: URL, extension: String) async throws -> ConversionResult {
        let filename = url.lastPathComponent
        
        // Try to determine file type from UTType
        let utType = UTType(filenameExtension: `extension`)
        
        // Image files (non-supported formats) → OCR to text
        if utType?.conforms(to: .image) == true {
            AppLogger.log("   🖼️ Image file detected - attempting OCR", category: .fileManager, level: .info)
            return try await convertImageToText(url: url, originalFilename: filename)
        }
        
        // Audio files → Placeholder for transcription
        if utType?.conforms(to: .audio) == true {
            AppLogger.log("   🎵 Audio file detected - generating metadata", category: .fileManager, level: .info)
            return try await convertAudioToText(url: url, originalFilename: filename)
        }
        
        // Video files → Placeholder for transcription
        if utType?.conforms(to: .movie) == true {
            AppLogger.log("   🎬 Video file detected - generating metadata", category: .fileManager, level: .info)
            return try await convertVideoToText(url: url, originalFilename: filename)
        }
        
        // Try reading as plain text (works for many formats)
        if let textContent = try? String(contentsOf: url, encoding: .utf8), !textContent.isEmpty {
            AppLogger.log("   📝 Readable as plain text", category: .fileManager, level: .info)
            return try convertToPlainText(content: textContent, originalFilename: filename, method: "Text extraction")
        }
        
        // Try UTF-16
        if let textContent = try? String(contentsOf: url, encoding: .utf16), !textContent.isEmpty {
            AppLogger.log("   📝 Readable as UTF-16 text", category: .fileManager, level: .info)
            return try convertToPlainText(content: textContent, originalFilename: filename, method: "UTF-16 extraction")
        }
        
        // Binary file → Create metadata document
        AppLogger.log("   📦 Binary file - creating metadata document", category: .fileManager, level: .info)
        return try convertBinaryToMetadata(url: url, originalFilename: filename)
    }
    
    // MARK: - Specific Converters
    
    /// Convert image to text using OCR (Vision framework)
    private static func convertImageToText(url: URL, originalFilename: String) async throws -> ConversionResult {
        #if os(macOS)
        guard let image = NSImage(contentsOf: url) else {
            throw FileConversionError.conversionFailed("Unable to load image")
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw FileConversionError.conversionFailed("Unable to get CGImage")
        }
        #else
        // iOS/iPadOS
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw FileConversionError.conversionFailed("Unable to load image")
        }
        
        guard let cgImage = image.cgImage else {
            throw FileConversionError.conversionFailed("Unable to get CGImage")
        }
        #endif
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw FileConversionError.conversionFailed("No OCR results")
        }
        
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        if recognizedText.isEmpty {
            throw FileConversionError.conversionFailed("No text recognized in image")
        }
        
        let metadata = """
        # Original File: \(originalFilename)
        # Converted from: Image file
        # Conversion Method: OCR (Optical Character Recognition)
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        --- EXTRACTED TEXT ---
        
        \(recognizedText)
        """
        
        AppLogger.log("   ✅ OCR successful - extracted \(recognizedText.count) characters", category: .fileManager, level: .info)
        
        guard let data = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode text")
        }
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_OCR.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "OCR (Vision framework)",
            wasConverted: true
        )
    }
    
    /// Convert audio file to text (metadata for now, transcription would require Whisper API)
    private static func convertAudioToText(url: URL, originalFilename: String) async throws -> ConversionResult {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        
        let metadata = """
        # Original File: \(originalFilename)
        # File Type: Audio
        # Duration: \(String(format: "%.2f", duration)) seconds
        # Conversion Note: Audio transcription requires separate processing
        # Recommendation: Use OpenAI's Whisper API for transcription
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        --- AUDIO FILE INFORMATION ---
        
        This is an audio file that requires transcription. To process this file:
        1. Use OpenAI's Whisper API for speech-to-text conversion
        2. Upload the resulting transcript to this vector store
        
        File Details:
        - Original filename: \(originalFilename)
        - Duration: \(String(format: "%.2f", duration)) seconds
        - Format: \(url.pathExtension.uppercased())
        """
        
        AppLogger.log("   ℹ️ Audio metadata generated", category: .fileManager, level: .info)
        
        guard let data = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode metadata")
        }
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_AudioInfo.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Audio metadata extraction",
            wasConverted: true
        )
    }
    
    /// Convert video file to text metadata
    private static func convertVideoToText(url: URL, originalFilename: String) async throws -> ConversionResult {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let tracks = try await asset.load(.tracks)
        
        let videoTracks = tracks.filter { $0.mediaType == .video }
        let audioTracks = tracks.filter { $0.mediaType == .audio }
        
        let metadata = """
        # Original File: \(originalFilename)
        # File Type: Video
        # Duration: \(String(format: "%.2f", duration)) seconds
        # Video Tracks: \(videoTracks.count)
        # Audio Tracks: \(audioTracks.count)
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        --- VIDEO FILE INFORMATION ---
        
        This is a video file. To extract meaningful content:
        1. Extract audio track and use Whisper API for transcription
        2. Extract keyframes and use Vision API for image analysis
        3. Upload the resulting analysis to this vector store
        
        File Details:
        - Original filename: \(originalFilename)
        - Duration: \(String(format: "%.2f", duration)) seconds
        - Format: \(url.pathExtension.uppercased())
        - Video tracks: \(videoTracks.count)
        - Audio tracks: \(audioTracks.count)
        """
        
        AppLogger.log("   ℹ️ Video metadata generated", category: .fileManager, level: .info)
        
        guard let data = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode metadata")
        }
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_VideoInfo.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Video metadata extraction",
            wasConverted: true
        )
    }
    
    /// Convert plain text with metadata
    private static func convertToPlainText(content: String, originalFilename: String, method: String) throws -> ConversionResult {
        let metadata = """
        # Original File: \(originalFilename)
        # Conversion Method: \(method)
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        --- CONTENT ---
        
        \(content)
        """
        
        guard let data = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode text")
        }
        
        let newFilename = "\(URL(fileURLWithPath: originalFilename).deletingPathExtension().lastPathComponent).txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: method,
            wasConverted: true
        )
    }
    
    /// Convert binary file to metadata document
    private static func convertBinaryToMetadata(url: URL, originalFilename: String) throws -> ConversionResult {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let creationDate = attributes[.creationDate] as? Date ?? Date()
        let modificationDate = attributes[.modificationDate] as? Date ?? Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        let metadata = """
        # Original File: \(originalFilename)
        # File Type: Binary file
        # Size: \(formatBytes(fileSize))
        # Created: \(dateFormatter.string(from: creationDate))
        # Modified: \(dateFormatter.string(from: modificationDate))
        # Conversion Method: Metadata extraction
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        --- BINARY FILE INFORMATION ---
        
        This is a binary file that cannot be directly converted to text.
        
        File Details:
        - Original filename: \(originalFilename)
        - File extension: \(url.pathExtension)
        - Size: \(formatBytes(fileSize))
        - Created: \(dateFormatter.string(from: creationDate))
        - Last modified: \(dateFormatter.string(from: modificationDate))
        
        To process this file, you may need to:
        1. Use specialized software to export to a supported format
        2. Extract data programmatically and save as text/JSON/CSV
        3. Convert to PDF format if it's a document
        """
        
        AppLogger.log("   ℹ️ Binary file metadata generated", category: .fileManager, level: .info)
        
        guard let data = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode metadata")
        }
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_FileInfo.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Binary metadata extraction",
            wasConverted: true
        )
    }
    
    // MARK: - Helpers
    
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Errors

enum FileConversionError: LocalizedError {
    case fileNotFound
    case fileTooLarge(fileSize: Int64, maxSize: Int64)
    case emptyFile
    case unableToReadFile
    case conversionFailed(String)
    case unsupportedFileType(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .fileTooLarge(let size, let maxSize):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let sizeStr = formatter.string(fromByteCount: size)
            let maxStr = formatter.string(fromByteCount: maxSize)
            return "File size (\(sizeStr)) exceeds OpenAI's limit of \(maxStr)"
        case .emptyFile:
            return "File is empty"
        case .unableToReadFile:
            return "Unable to read file"
        case .conversionFailed(let reason):
            return "Conversion failed: \(reason)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        }
    }
}
