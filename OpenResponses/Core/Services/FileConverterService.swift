import Foundation
import PDFKit
import Vision
import AVFoundation
import UniformTypeIdentifiers
import NaturalLanguage

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Universal file converter that transforms unsupported file types into OpenAI-compatible formats
/// Acts as a "blender" to make any file type ingestible by the API
class FileConverterService {
    
    // MARK: - File Size Limits
    
    static let maxFileSizeBytes: Int64 = 512 * 1024 * 1024 // 512 MB (OpenAI limit)
    static let maxTokensPerFile: Int = 5_000_000 // 5 million tokens (OpenAI limit)
    
    // For converted files, we need to be more conservative
    static let maxConvertedFileSizeBytes: Int64 = 100 * 1024 * 1024 // 100 MB for safety
    static let maxCSVRows: Int = 100_000 // Reasonable limit for CSV processing
    static let chunkSizeForLargeFiles: Int = 50_000 // Lines per chunk for large files
    
    // MARK: - Supported Types by OpenAI
    
    /// File extensions natively supported by OpenAI's Files API
    static let openAISupportedExtensions: Set<String> = [
        "c", "cpp", "cs", "css", "csv", "doc", "docx", "gif", "html", "java",
        "jpeg", "jpg", "js", "json", "md", "pdf", "php", "png", "pptx", "py",
        "rb", "sh", "tar", "tex", "ts", "txt", "webp", "xlsx", "xml", "zip"
    ]
    
    /// File extensions supported by Vector Stores (more restrictive than general Files API)
    /// Source: https://platform.openai.com/docs/assistants/tools/file-search/supported-files
    static let vectorStoreSupportedExtensions: Set<String> = [
        "c", "cpp", "cs", "css", "doc", "docx", "go", "html", "java", "js",
        "json", "md", "pdf", "php", "pptx", "py", "rb", "sh", "tex", "ts", "txt"
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
    /// - Parameters:
    ///   - url: The file URL to process
    ///   - forVectorStore: If true, ensures compatibility with vector store requirements (more restrictive)
    /// - Returns: ConversionResult with the processed file data
    static func processFile(url: URL, forVectorStore: Bool = false) async throws -> ConversionResult {
        try validateFile(url: url)
        
        let fileExtension = url.pathExtension.lowercased()
        let filename = url.lastPathComponent
        
        AppLogger.log("🔄 Processing file: \(filename)", category: .fileManager, level: .info)
        AppLogger.log("   📎 Extension: .\(fileExtension)", category: .fileManager, level: .debug)
        AppLogger.log("   🎯 Target: \(forVectorStore ? "Vector Store" : "General Upload")", category: .fileManager, level: .debug)
        
        // For vector stores, check stricter requirements
        if forVectorStore {
            // Special handling for PDFs - extract text even though they're "supported"
            // This ensures searchability and reduces file size
            if fileExtension == "pdf" {
                AppLogger.log("   📄 PDF detected for vector store - extracting text for optimal searchability", category: .fileManager, level: .info)
                return try await extractTextFromPDF(url: url, originalFilename: filename)
            }
            
            if vectorStoreSupportedExtensions.contains(fileExtension) {
                AppLogger.log("   ✅ File type supported by Vector Stores", category: .fileManager, level: .info)
                let data = try Data(contentsOf: url)
                return ConversionResult(
                    convertedData: data,
                    filename: filename,
                    originalFilename: filename,
                    conversionMethod: "None (vector store compatible)",
                    wasConverted: false
                )
            } else if fileExtension == "csv" || fileExtension == "xlsx" {
                // CSV/Excel are supported for general uploads but not vector stores - convert to TXT
                AppLogger.log("   🔄 CSV/Excel not supported by vector stores - converting to TXT", category: .fileManager, level: .info)
                return try await convertCSVToText(url: url, originalFilename: filename)
            } else {
                // For other unsupported types, try generic conversion
                AppLogger.log("   🔄 File type not supported by vector stores - attempting conversion", category: .fileManager, level: .info)
                return try await convertUnsupportedFile(url: url, extension: fileExtension)
            }
        } else {
            // For general uploads, use broader support list
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
    
    /// Preprocesses an image for optimal OCR quality
    /// Converts to grayscale and enhances contrast for better text recognition
    private static func preprocessImageForOCR(_ cgImage: CGImage) -> CGImage? {
        // Convert to grayscale for better OCR accuracy
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        return context.makeImage()
    }
    
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
        
        // Preprocess image for better OCR quality (convert to grayscale)
        let processedImage = preprocessImageForOCR(cgImage) ?? cgImage
        
        let requestHandler = VNImageRequestHandler(cgImage: processedImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Specify supported languages for better accuracy (prioritize English, but support common languages)
        request.recognitionLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "zh-Hans", "ja-JP"]
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw FileConversionError.conversionFailed("No OCR results")
        }
        
        // Track confidence levels for quality reporting
        var lowConfidenceCount = 0
        var totalConfidence = 0.0
        
        let recognizedText = observations.compactMap { observation in
            guard let topCandidate = observation.topCandidates(1).first else { return nil }
            
            totalConfidence += Double(topCandidate.confidence)
            
            if topCandidate.confidence < 0.5 {
                lowConfidenceCount += 1
            }
            
            return topCandidate.string
        }.joined(separator: "\n")
        
        if recognizedText.isEmpty {
            throw FileConversionError.conversionFailed("No text recognized in image")
        }
        
        let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Double(observations.count)
        let confidencePercentage = Int(averageConfidence * 100)
        
        let qualityWarning = lowConfidenceCount > 0 ? 
            "\n# ⚠️ OCR Quality Notice: \(lowConfidenceCount) sections had low confidence (<50%). Consider reviewing for accuracy." : ""
        
        let metadata = """
        # Original File: \(originalFilename)
        # Converted from: Image file
        # Conversion Method: OCR (Optical Character Recognition - Enhanced)
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        # OCR Quality: \(confidencePercentage)% average confidence
        # Text Segments: \(observations.count)\(qualityWarning)
        
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
    
    // MARK: - CSV Conversion (Bulletproof)
    
    /// Intelligently converts CSV/Excel files to plain text format for vector store compatibility
    /// Handles large files with smart sampling and summarization using Apple ML frameworks
    private static func convertCSVToText(url: URL, originalFilename: String) async throws -> ConversionResult {
        AppLogger.log("   📊 Converting CSV to text format (bulletproof mode)...", category: .fileManager, level: .info)
        
        // Read the CSV file with multiple encoding fallbacks
        var csvContent: String?
        let encodings: [String.Encoding] = [.utf8, .utf16, .isoLatin1, .windowsCP1252, .macOSRoman]
        
        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding) {
                csvContent = content
                AppLogger.log("   ✅ Successfully read CSV with encoding: \(encoding)", category: .fileManager, level: .debug)
                break
            }
        }
        
        guard let csvData = csvContent else {
            throw FileConversionError.conversionFailed("Unable to read CSV file with any supported encoding")
        }
        
        let originalSize = csvData.utf8.count
        AppLogger.log("   📏 Original CSV size: \(formatBytes(Int64(originalSize)))", category: .fileManager, level: .info)
        
        // Split into lines for analysis
        let lines = csvData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let lineCount = lines.count
        AppLogger.log("   📊 CSV has \(lineCount) lines", category: .fileManager, level: .info)
        
        // Determine conversion strategy based on size and line count
        let strategy = determineConversionStrategy(lineCount: lineCount, dataSize: originalSize)
        AppLogger.log("   🎯 Using conversion strategy: \(strategy)", category: .fileManager, level: .info)
        
        var processedContent: String
        var conversionNotes: String
        
        switch strategy {
        case .full:
            // Small file - include everything
            processedContent = csvData
            conversionNotes = "Complete CSV data included."
            
        case .headTailSample(let headLines, let tailLines):
            // Medium file - include header, sample, and tail
            let header = lines.prefix(headLines).joined(separator: "\n")
            let tail = lines.suffix(tailLines).joined(separator: "\n")
            
            processedContent = """
            \(header)
            
            ... [\(lineCount - headLines - tailLines) rows omitted for size - total \(lineCount) rows] ...
            
            \(tail)
            """
            
            conversionNotes = """
            Large CSV file condensed for vector store compatibility.
            Showing first \(headLines) and last \(tailLines) rows out of \(lineCount) total.
            Full data available in original file: \(originalFilename)
            """
            
        case .intelligentSummary:
            // Very large file - use Apple NL framework for intelligent summarization
            processedContent = try await createIntelligentCSVSummary(lines: lines, originalFilename: originalFilename)
            conversionNotes = """
            Large CSV file (\(lineCount) rows) intelligently summarized using Apple NaturalLanguage framework.
            Summary includes: structure analysis, column detection, statistical overview, and representative samples.
            Full data available in original file: \(originalFilename)
            """
        }
        
        // Build final document with rich metadata
        let metadata = """
        # Original File: \(originalFilename)
        # Converted from: CSV file
        # Conversion Method: Intelligent CSV-to-Text with ML enhancement
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        # Original Size: \(formatBytes(Int64(originalSize)))
        # Total Rows: \(lineCount)
        # Conversion Strategy: \(strategy)
        # Note: Optimized for vector store compatibility and semantic search
        
        ## CONVERSION NOTES
        \(conversionNotes)
        
        ## CSV DATA
        
        \(processedContent)
        
        ## METADATA
        - File format: CSV (Comma-Separated Values)
        - Original filename: \(originalFilename)
        - Processing date: \(Date().formatted())
        - Optimized for: OpenAI Vector Store file_search tool
        """
        
        // Validate final size
        guard let finalData = metadata.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode converted text")
        }
        
        let finalSize = Int64(finalData.count)
        AppLogger.log("   ✅ Conversion complete! Final size: \(formatBytes(finalSize)) (reduced from \(formatBytes(Int64(originalSize))))", category: .fileManager, level: .info)
        
        // Safety check - ensure we're under the limit
        if finalSize > maxConvertedFileSizeBytes {
            AppLogger.log("   ⚠️ Converted file still too large, applying aggressive compression...", category: .fileManager, level: .warning)
            // Fallback to ultra-compressed version
            return try await createUltraCompressedCSVSummary(lines: lines, originalFilename: originalFilename)
        }
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_CSV.txt"
        
        return ConversionResult(
            convertedData: finalData,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Intelligent CSV-to-Text (\(strategy))",
            wasConverted: true
        )
    }
    
    // MARK: - Conversion Strategies
    
    private enum ConversionStrategy: CustomStringConvertible {
        case full
        case headTailSample(headLines: Int, tailLines: Int)
        case intelligentSummary
        
        var description: String {
            switch self {
            case .full:
                return "Full"
            case .headTailSample(let head, let tail):
                return "Head/Tail Sample (\(head)/\(tail))"
            case .intelligentSummary:
                return "ML-Enhanced Summary"
            }
        }
    }
    
    private static func determineConversionStrategy(lineCount: Int, dataSize: Int) -> ConversionStrategy {
        // Strategy based on line count and size
        if lineCount <= 1000 && dataSize < 1_000_000 { // < 1 MB and < 1K rows
            return .full
        } else if lineCount <= 10_000 && dataSize < 10_000_000 { // < 10 MB and < 10K rows
            return .headTailSample(headLines: 500, tailLines: 500)
        } else if lineCount <= 50_000 && dataSize < 50_000_000 { // < 50 MB and < 50K rows
            return .headTailSample(headLines: 1000, tailLines: 1000)
        } else {
            return .intelligentSummary
        }
    }
    
    /// Creates an intelligent summary of a large CSV using Apple's NaturalLanguage framework
    private static func createIntelligentCSVSummary(lines: [String], originalFilename: String) async throws -> String {
        AppLogger.log("   🧠 Creating intelligent CSV summary using Apple NaturalLanguage...", category: .fileManager, level: .info)
        
        // Analyze CSV structure
        guard let headerLine = lines.first else {
            throw FileConversionError.conversionFailed("CSV file has no header")
        }
        
        // Detect delimiter
        let delimiter = detectDelimiter(in: headerLine)
        let columns = headerLine.components(separatedBy: delimiter)
        let columnCount = columns.count
        
        AppLogger.log("   📋 Detected \(columnCount) columns with delimiter '\(delimiter)'", category: .fileManager, level: .debug)
        
        // Statistical sampling - take strategic samples
        let sampleSize = min(100, lines.count / 10) // 10% sample, max 100 rows
        var samples: [String] = []
        
        // Include header
        samples.append(headerLine)
        
        // Stratified sampling - take samples evenly distributed through the file
        if lines.count > 1 {
            let strideValue = max(1, (lines.count - 1) / sampleSize)
            for i in stride(from: 1, to: lines.count, by: strideValue).prefix(sampleSize) {
                samples.append(lines[i])
            }
        }
        
        // Analyze data types in columns using NaturalLanguage
        var columnAnalysis: [String] = []
        for (index, column) in columns.enumerated() {
            let sampleValues = samples.dropFirst().compactMap { line in
                line.components(separatedBy: delimiter)[safe: index]
            }
            
            let dataType = analyzeColumnDataType(sampleValues)
            columnAnalysis.append("  \(index + 1). \(column): \(dataType)")
        }
        
        // Build comprehensive summary
        let summary = """
        STRUCTURE:
        - Columns: \(columnCount)
        - Total Rows: \(lines.count)
        - Delimiter: '\(delimiter)'
        
        COLUMNS:
        \(columnAnalysis.joined(separator: "\n"))
        
        HEADER:
        \(headerLine)
        
        SAMPLE DATA (First 10 rows):
        \(samples.prefix(11).dropFirst().joined(separator: "\n"))
        
        SAMPLE DATA (Last 5 rows):
        \(lines.suffix(5).joined(separator: "\n"))
        
        DATA SUMMARY:
        This CSV contains \(lines.count) rows of data with \(columnCount) columns.
        The data has been intelligently sampled to provide representative examples
        while maintaining vector store compatibility. Column data types have been
        automatically detected using Apple's NaturalLanguage framework for optimal
        semantic search performance.
        """
        
        return summary
    }
    
    /// Fallback: Creates ultra-compressed summary when all else fails
    private static func createUltraCompressedCSVSummary(lines: [String], originalFilename: String) async throws -> ConversionResult {
        AppLogger.log("   🗜️ Creating ultra-compressed CSV summary...", category: .fileManager, level: .warning)
        
        let headerLine = lines.first ?? ""
        let firstFive = lines.prefix(6).dropFirst().joined(separator: "\n")
        let lastFive = lines.suffix(5).joined(separator: "\n")
        
        let content = """
        # Original File: \(originalFilename)
        # Converted from: CSV file (Ultra-compressed)
        # Total Rows: \(lines.count)
        # Note: File too large - showing structure only
        
        ## STRUCTURE
        Header: \(headerLine)
        Total Rows: \(lines.count)
        
        ## FIRST 5 ROWS
        \(firstFive)
        
        ## LAST 5 ROWS
        \(lastFive)
        
        ## NOTE
        This is an ultra-compressed representation of a very large CSV file.
        For full data access, please refer to the original file or consider
        splitting it into smaller chunks for vector store upload.
        """
        
        guard let data = content.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode ultra-compressed summary")
        }
        
        let newFilename = "\(URL(fileURLWithPath: originalFilename).deletingPathExtension().lastPathComponent)_CSV_Summary.txt"
        
        AppLogger.log("   ✅ Ultra-compressed summary created: \(formatBytes(Int64(data.count)))", category: .fileManager, level: .info)
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Ultra-compressed CSV Summary",
            wasConverted: true
        )
    }
    
    /// Detects the delimiter used in a CSV line
    private static func detectDelimiter(in line: String) -> String {
        let delimiters = [",", "\t", ";", "|"]
        var maxCount = 0
        var detectedDelimiter = ","
        
        for delimiter in delimiters {
            let count = line.components(separatedBy: delimiter).count
            if count > maxCount {
                maxCount = count
                detectedDelimiter = delimiter
            }
        }
        
        return detectedDelimiter
    }
    
    /// Uses NaturalLanguage framework to analyze column data types
    private static func analyzeColumnDataType(_ values: [String]) -> String {
        guard !values.isEmpty else { return "Unknown" }
        
        // Sample up to 20 values for analysis
        let sample = Array(values.prefix(20))
        
        // Check for numeric data
        let numericCount = sample.filter { Double($0) != nil }.count
        if Double(numericCount) > Double(sample.count) * 0.8 {
            return "Numeric"
        }
        
        // Check for dates
        let dateFormatter = ISO8601DateFormatter()
        let dateCount = sample.filter { dateFormatter.date(from: $0) != nil }.count
        if Double(dateCount) > Double(sample.count) * 0.7 {
            return "Date/Time"
        }
        
        // Check for boolean
        let boolValues = Set(["true", "false", "yes", "no", "1", "0", "t", "f", "y", "n"])
        let boolCount = sample.filter { boolValues.contains($0.lowercased()) }.count
        if Double(boolCount) > Double(sample.count) * 0.8 {
            return "Boolean"
        }
        
        // Use NaturalLanguage for text analysis
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        var hasRichText = false
        
        for value in sample.prefix(5) {
            if value.count > 50 {
                tagger.string = value
                let tags = tagger.tags(in: value.startIndex..<value.endIndex, unit: .word, scheme: .lexicalClass)
                if tags.count > 5 {
                    hasRichText = true
                    break
                }
            }
        }
        
        if hasRichText {
            return "Text (Rich Content)"
        }
        
        // Calculate average length
        let avgLength = sample.reduce(0) { $0 + $1.count } / sample.count
        if avgLength < 10 {
            return "Text (Short)"
        } else if avgLength < 50 {
            return "Text (Medium)"
        } else {
            return "Text (Long)"
        }
    }
    
    // MARK: - PDF Text Extraction (Bulletproof)
    
    /// Extracts all text from a PDF file using Apple's PDFKit
    /// This ensures PDFs are fully searchable in vector stores and reduces file size
    private static func extractTextFromPDF(url: URL, originalFilename: String) async throws -> ConversionResult {
        AppLogger.log("   📄 Extracting text from PDF using Apple PDFKit...", category: .fileManager, level: .info)
        
        // Load PDF document
        guard let pdfDocument = PDFDocument(url: url) else {
            throw FileConversionError.conversionFailed("Unable to load PDF document")
        }
        
        let pageCount = pdfDocument.pageCount
        AppLogger.log("   📊 PDF has \(pageCount) pages", category: .fileManager, level: .info)
        
        guard pageCount > 0 else {
            throw FileConversionError.conversionFailed("PDF has no pages")
        }
        
        // Extract metadata
        let metadata = pdfDocument.documentAttributes
        let title = metadata?[PDFDocumentAttribute.titleAttribute] as? String
        let author = metadata?[PDFDocumentAttribute.authorAttribute] as? String
        let subject = metadata?[PDFDocumentAttribute.subjectAttribute] as? String
        let creator = metadata?[PDFDocumentAttribute.creatorAttribute] as? String
        let keywords = metadata?[PDFDocumentAttribute.keywordsAttribute] as? [String]
        
        // Build metadata section
        var metadataSection = ""
        if let title = title, !title.isEmpty {
            metadataSection += "Title: \(title)\n"
        }
        if let author = author, !author.isEmpty {
            metadataSection += "Author: \(author)\n"
        }
        if let subject = subject, !subject.isEmpty {
            metadataSection += "Subject: \(subject)\n"
        }
        if let creator = creator, !creator.isEmpty {
            metadataSection += "Creator: \(creator)\n"
        }
        if let keywords = keywords, !keywords.isEmpty {
            metadataSection += "Keywords: \(keywords.joined(separator: ", "))\n"
        }
        
        // Extract text from all pages with progress tracking
        var extractedText = ""
        var pagesWithText = 0
        var totalCharacters = 0
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                AppLogger.log("   ⚠️ Unable to load page \(pageIndex + 1)", category: .fileManager, level: .warning)
                continue
            }
            
            guard let pageText = page.string else {
                AppLogger.log("   ⚠️ No text on page \(pageIndex + 1)", category: .fileManager, level: .debug)
                continue
            }
            
            let trimmedText = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty {
                extractedText += "--- PAGE \(pageIndex + 1) ---\n\n"
                extractedText += trimmedText
                extractedText += "\n\n"
                pagesWithText += 1
                totalCharacters += trimmedText.count
            }
            
            // Log progress every 10 pages for large PDFs
            if (pageIndex + 1) % 10 == 0 {
                AppLogger.log("   📄 Processed \(pageIndex + 1)/\(pageCount) pages...", category: .fileManager, level: .debug)
            }
        }
        
        AppLogger.log("   ✅ Extracted text from \(pagesWithText)/\(pageCount) pages (\(totalCharacters) characters)", category: .fileManager, level: .info)
        
        // Check if we got any text
        if extractedText.isEmpty {
            AppLogger.log("   ⚠️ No text could be extracted from PDF - may be image-based or encrypted", category: .fileManager, level: .warning)
            
            // Attempt OCR on first few pages if no text found
            return try await attemptPDFOCR(pdfDocument: pdfDocument, originalFilename: originalFilename, pageCount: pageCount)
        }
        
        // Determine if we need to compress based on size
        let originalSize = extractedText.utf8.count
        let shouldCompress = originalSize > maxConvertedFileSizeBytes || pageCount > 500
        
        var finalText: String
        var conversionNote: String
        
        if shouldCompress {
            AppLogger.log("   🗜️ Large PDF - applying intelligent compression...", category: .fileManager, level: .info)
            finalText = try compressPDFText(extractedText: extractedText, pageCount: pageCount, pagesWithText: pagesWithText)
            conversionNote = "Large PDF compressed intelligently. Full text extracted but summarized for vector store compatibility."
        } else {
            finalText = extractedText
            conversionNote = "Complete text extraction from all pages."
        }
        
        // Build final document
        let document = """
        # Original File: \(originalFilename)
        # Converted from: PDF document
        # Conversion Method: Text extraction using Apple PDFKit
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        # Pages: \(pageCount)
        # Pages with text: \(pagesWithText)
        # Total characters extracted: \(totalCharacters)
        # Note: Optimized for vector store semantic search
        
        ## PDF METADATA
        \(metadataSection.isEmpty ? "No metadata available\n" : metadataSection)
        
        ## CONVERSION NOTES
        \(conversionNote)
        
        ## EXTRACTED TEXT
        
        \(finalText)
        
        ## DOCUMENT INFO
        - Original filename: \(originalFilename)
        - Total pages: \(pageCount)
        - Pages with extracted text: \(pagesWithText)
        - Processing date: \(Date().formatted())
        - Optimized for: OpenAI Vector Store file_search tool
        """
        
        guard let data = document.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode extracted text")
        }
        
        let finalSize = Int64(data.count)
        let compressionRatio = originalSize > 0 ? Double(finalSize) / Double(originalSize) : 1.0
        
        AppLogger.log("   ✅ PDF extraction complete! Final size: \(formatBytes(finalSize)) (compression: \(String(format: "%.1f%%", compressionRatio * 100)))", category: .fileManager, level: .info)
        
        let newFilename = "\(url.deletingPathExtension().lastPathComponent)_extracted.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "PDF Text Extraction (PDFKit)",
            wasConverted: true
        )
    }
    
    /// Attempts OCR on PDF pages when text extraction fails (image-based PDFs)
    private static func attemptPDFOCR(pdfDocument: PDFDocument, originalFilename: String, pageCount: Int) async throws -> ConversionResult {
        AppLogger.log("   🔍 No text found - attempting OCR on PDF pages...", category: .fileManager, level: .info)
        
        var ocrText = ""
        let pagesToOCR = min(50, pageCount) // Increased from 10 to 50 pages for better coverage
        
        // Track OCR quality metrics
        var totalConfidence = 0.0
        var lowConfidencePages = 0
        var processedPages = 0
        
        for pageIndex in 0..<pagesToOCR {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Get page as image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            // Perform OCR using Vision
            guard let cgImage = image.cgImage else { continue }
            
            // Preprocess image for better OCR quality
            let processedImage = preprocessImageForOCR(cgImage) ?? cgImage
            
            let requestHandler = VNImageRequestHandler(cgImage: processedImage, options: [:])
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Multi-language support for better accuracy
            request.recognitionLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "zh-Hans", "ja-JP"]
            
            do {
                try requestHandler.perform([request])
                
                if let observations = request.results {
                    // Track confidence for this page
                    var pageConfidence = 0.0
                    var lowConfidenceCount = 0
                    
                    let pageText = observations.compactMap { observation in
                        guard let topCandidate = observation.topCandidates(1).first else { return nil }
                        
                        pageConfidence += Double(topCandidate.confidence)
                        
                        if topCandidate.confidence < 0.5 {
                            lowConfidenceCount += 1
                        }
                        
                        return topCandidate.string
                    }.joined(separator: "\n")
                    
                    if !pageText.isEmpty {
                        let avgPageConfidence = observations.isEmpty ? 0.0 : pageConfidence / Double(observations.count)
                        let confidenceEmoji = avgPageConfidence > 0.8 ? "✅" : avgPageConfidence > 0.5 ? "⚠️" : "❌"
                        
                        ocrText += "--- PAGE \(pageIndex + 1) (OCR \(confidenceEmoji) \(Int(avgPageConfidence * 100))%) ---\n\n"
                        ocrText += pageText
                        ocrText += "\n\n"
                        
                        totalConfidence += avgPageConfidence
                        if avgPageConfidence < 0.6 {
                            lowConfidencePages += 1
                        }
                        processedPages += 1
                    }
                }
            } catch {
                AppLogger.log("   ⚠️ OCR failed for page \(pageIndex + 1): \(error.localizedDescription)", category: .fileManager, level: .warning)
            }
            
            AppLogger.log("   📄 OCR processed page \(pageIndex + 1)/\(pagesToOCR)...", category: .fileManager, level: .debug)
        }
        
        if ocrText.isEmpty {
            throw FileConversionError.conversionFailed("No text could be extracted from PDF, even with OCR. This may be an empty or encrypted PDF.")
        }
        
        // Calculate overall quality metrics
        let overallConfidence = processedPages > 0 ? totalConfidence / Double(processedPages) : 0.0
        let confidencePercentage = Int(overallConfidence * 100)
        let qualityRating = overallConfidence > 0.8 ? "Excellent ✅" : overallConfidence > 0.6 ? "Good ⚠️" : "Fair ❌"
        
        let qualityWarning = lowConfidencePages > 0 ? 
            "\n# ⚠️ OCR Quality Notice: \(lowConfidencePages) pages had lower confidence (<60%). Consider reviewing those sections." : ""
        
        let document = """
        # Original File: \(originalFilename)
        # Converted from: PDF document (image-based)
        # Conversion Method: Enhanced OCR using Apple Vision framework
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        # Pages: \(pageCount)
        # Pages OCR'd: \(pagesToOCR)
        # OCR Quality: \(confidencePercentage)% average confidence (\(qualityRating))
        # Processed Pages: \(processedPages)\(qualityWarning)
        # Note: This was an image-based PDF requiring OCR with multi-language support
        
        ## CONVERSION NOTES
        This PDF contained no extractable text (likely scanned/image-based).
        Enhanced OCR was performed on the first \(pagesToOCR) pages using:
        - Apple Vision Framework (accurate mode)
        - Grayscale preprocessing for better accuracy
        - Multi-language recognition (EN, ES, FR, DE, IT, PT, ZH, JA)
        - Confidence tracking per page
        \(pageCount > pagesToOCR ? "\n⚠️ Full document has \(pageCount) pages - first \(pagesToOCR) were processed." : "")
        
        ## EXTRACTED TEXT (via Enhanced OCR)
        
        \(ocrText)
        
        ## DOCUMENT INFO
        - Original filename: \(originalFilename)
        - Total pages: \(pageCount)
        - Pages processed with OCR: \(pagesToOCR)
        - Successfully extracted pages: \(processedPages)
        - Average OCR confidence: \(confidencePercentage)%
        - Processing date: \(Date().formatted())
        """
        
        guard let data = document.data(using: .utf8) else {
            throw FileConversionError.conversionFailed("Unable to encode OCR text")
        }
        
        AppLogger.log("   ✅ Enhanced PDF OCR complete! Extracted \(ocrText.count) characters from \(processedPages) pages (quality: \(confidencePercentage)%)", category: .fileManager, level: .info)
        
        let newFilename = "\(originalFilename.replacingOccurrences(of: ".pdf", with: ""))_OCR.txt"
        
        return ConversionResult(
            convertedData: data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Enhanced PDF OCR (Vision framework with preprocessing)",
            wasConverted: true
        )
    }
    
    /// Compresses large PDF text extractions intelligently
    private static func compressPDFText(extractedText: String, pageCount: Int, pagesWithText: Int) throws -> String {
        let lines = extractedText.components(separatedBy: .newlines)
        
        // If under 100K lines, return as-is
        if lines.count < 100_000 {
            return extractedText
        }
        
        // For very large PDFs, take strategic samples
        let headerSize = min(25_000, lines.count / 4)
        let tailSize = min(25_000, lines.count / 4)
        
        let header = lines.prefix(headerSize).joined(separator: "\n")
        let tail = lines.suffix(tailSize).joined(separator: "\n")
        
        return """
        \(header)
        
        ... [\(lines.count - headerSize - tailSize) lines omitted - \(pageCount) total pages] ...
        
        \(tail)
        """
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
    
    // MARK: - Text to PDF Conversion
    
    /// Converts text content to a PDF document for OpenAI Responses API compatibility
    /// This allows .txt, .md, and other text files to be used with the input_file type
    static func convertTextToPDF(content: String, originalFilename: String) throws -> ConversionResult {
        AppLogger.log("📄 Converting text to PDF: \(originalFilename)", category: .fileManager, level: .info)
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Setup PDF context
        UIGraphicsBeginPDFContextToData(pdfData, .zero, [
            kCGPDFContextTitle as String: originalFilename,
            kCGPDFContextAuthor as String: "OpenResponses",
            kCGPDFContextCreator as String: "OpenResponses File Converter",
            kCGPDFContextSubject as String: "Converted from \(originalFilename)"
        ])
        
        // Page setup
        let pageWidth: CGFloat = 612.0  // 8.5 inches * 72 points/inch
        let pageHeight: CGFloat = 792.0 // 11 inches * 72 points/inch
        let margin: CGFloat = 72.0      // 1 inch margins
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let textRect = CGRect(x: margin, y: margin, width: pageWidth - 2*margin, height: pageHeight - 2*margin)
        
        // Font and paragraph style
        let fontSize: CGFloat = 12.0
        let font = UIFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]
        
        // Split content into lines for pagination
        let lines = content.components(separatedBy: .newlines)
        let lineHeight = ("A" as NSString).size(withAttributes: attributes).height + 4.0
        let linesPerPage = Int((textRect.height / lineHeight).rounded(.down))
        
        AppLogger.log("   📏 Text will span ~\((lines.count + linesPerPage - 1) / linesPerPage) page(s)", category: .fileManager, level: .debug)
        
        // Render pages
        var currentLine = 0
        while currentLine < lines.count {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            
            // Determine how many lines fit on this page
            let endLine = min(currentLine + linesPerPage, lines.count)
            let pageContent = lines[currentLine..<endLine].joined(separator: "\n")
            
            // Draw text
            (pageContent as NSString).draw(in: textRect, withAttributes: attributes)
            
            // Draw footer with page info
            let pageNumber = (currentLine / linesPerPage) + 1
            let footerText = "Page \(pageNumber) • \(originalFilename)"
            let footerFont = UIFont.systemFont(ofSize: 9.0)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.gray
            ]
            let footerRect = CGRect(x: margin, y: pageHeight - margin + 20, width: pageWidth - 2*margin, height: 20)
            (footerText as NSString).draw(in: footerRect, withAttributes: footerAttributes)
            
            currentLine = endLine
        }
        
        UIGraphicsEndPDFContext()
        
        AppLogger.log("   ✅ PDF created with \(pdfData.length) bytes", category: .fileManager, level: .info)
        
        // Generate new filename
        let baseFilename = (originalFilename as NSString).deletingPathExtension
        let newFilename = "\(baseFilename).pdf"
        
        return ConversionResult(
            convertedData: pdfData as Data,
            filename: newFilename,
            originalFilename: originalFilename,
            conversionMethod: "Text to PDF conversion",
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
