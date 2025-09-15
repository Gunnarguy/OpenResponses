import Foundation
import UIKit

/// Utility for detecting and extracting URLs from text messages
struct URLDetector {
    
    /// Extracts all valid URLs from a text string
    /// - Parameter text: The input text to search for URLs
    /// - Returns: Array of URLs found in the text
    static func extractURLs(from text: String) -> [URL] {
        // Use NSDataDetector to find URLs
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let urlString = String(text[range])
            return URL(string: urlString)
        }.filter { url in
            // Only include HTTP/HTTPS URLs that are likely to be web pages
            url.scheme == "http" || url.scheme == "https"
        }
    }
    
    /// Checks if a URL appears to be a webpage (not an API endpoint or file)
    /// - Parameter url: The URL to check
    /// - Returns: True if the URL appears to be a renderable webpage
    static func isRenderableWebpage(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        // Skip common API endpoints and file types
        let skipPatterns = [
            "api.",
            "/api/",
            ".json",
            ".xml",
            ".pdf",
            ".jpg", ".jpeg", ".png", ".gif", ".webp",
            ".mp4", ".mp3", ".wav",
            ".zip", ".tar", ".gz"
        ]
        
        for pattern in skipPatterns {
            if host.contains(pattern) || path.contains(pattern) {
                return false
            }
        }
        
        // Include common website domains
        let webDomains = [
            ".com", ".org", ".net", ".edu", ".gov",
            ".io", ".co", ".me", ".dev", ".app"
        ]
        
        return webDomains.contains { host.contains($0) }
    }
    
    /// Extracts URLs from text and filters for renderable webpages
    /// - Parameter text: The input text to search
    /// - Returns: Array of URLs that should be rendered as web content
    static func extractRenderableURLs(from text: String) -> [URL] {
        let allURLs = extractURLs(from: text)
        return allURLs.filter { isRenderableWebpage($0) }
    }

    /// Extracts image-like links from markdown or plain text.
    /// Supports:
    /// - Markdown image syntax: ![alt](url)
    /// - Bare http(s) image links ending with common extensions
    /// - Data URLs (data:image/...)
    /// - Sandbox paths (sandbox:/...) — returned as raw strings for caller to decide handling
    /// Returns unique links in order of appearance.
    static func extractImageLinks(from text: String) -> [String] {
        var results: [String] = []
        var seen = Set<String>()

        // 1) Markdown image syntax ![...](url)
        // Simple, robust scan without heavy regex engine dependencies
        let pattern = #"!\[[^\]]*\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let ns = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            for m in matches {
                if m.numberOfRanges >= 2 {
                    let r = m.range(at: 1)
                    if r.location != NSNotFound, let urlStr = ns.substring(with: r).split(separator: " ").first.map(String.init) {
                        if !seen.contains(urlStr) { results.append(urlStr); seen.insert(urlStr) }
                    }
                }
            }
        }

        // 2) Bare http(s) links that look like images
        let httpImagePattern = #"https?://[^\s)]+\.(png|jpg|jpeg|gif|webp)(\?[^\s)]*)?"#
        if let regex = try? NSRegularExpression(pattern: httpImagePattern, options: .caseInsensitive) {
            let ns = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            for m in matches {
                let r = m.range(at: 0)
                if r.location != NSNotFound {
                    let urlStr = ns.substring(with: r)
                    if !seen.contains(urlStr) { results.append(urlStr); seen.insert(urlStr) }
                }
            }
        }

        // 3) Data URLs
        // Keep simple prefix detection to avoid massive regex overhead on large blobs
        if text.lowercased().contains("data:image/") {
            // Find all occurrences of data:image and attempt to capture until first whitespace or closing paren
            let tokens = text.components(separatedBy: "data:image")
            for i in 1..<tokens.count { // skip leading chunk before first token
                let tail = "data:image" + tokens[i]
                if let endIdx = tail.firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "\r" }) {
                    let candidate = String(tail[..<endIdx])
                    if !seen.contains(candidate) { results.append(candidate); seen.insert(candidate) }
                } else {
                    let candidate = tail
                    if !seen.contains(candidate) { results.append(candidate); seen.insert(candidate) }
                }
            }
        }

        // 4) Sandbox paths (not fetchable by app, but useful to surface)
        let sandboxPattern = #"sandbox:/[^\s)]+"#
        if let regex = try? NSRegularExpression(pattern: sandboxPattern, options: []) {
            let ns = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
            for m in matches {
                let r = m.range(at: 0)
                if r.location != NSNotFound {
                    let path = ns.substring(with: r)
                    if !seen.contains(path) { results.append(path); seen.insert(path) }
                }
            }
        }

        return results
    }
    
    /// Detects all URLs in the given text.
    ///
    /// - Parameter text: The text to search for URLs.
    /// - Returns: An array of `URL` objects found in the text.
    static func detectURLs(in text: String) -> [URL] {
        // Use NSDataDetector to find URLs
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let urls = matches.compactMap { match -> URL? in
            guard let range = Range(match.range, in: text) else { return nil }
            let urlString = String(text[range])
            return URL(string: urlString)
        }
        return urls
    }

    /// Detects all unique URLs in the given text, preserving the order of their first appearance.
    ///
    /// - Parameter text: The text to search for URLs.
    /// - Returns: An array of unique `URL` objects found in the text.
    static func detectUniqueURLs(in text: String) -> [URL] {
        let allURLs = detectURLs(in: text)
        var uniqueURLs = [URL]()
        var seen = Set<URL>()
        for url in allURLs {
            if !seen.contains(url) {
                uniqueURLs.append(url)
                seen.insert(url)
            }
        }
        return uniqueURLs
    }
}

/// Extension to automatically detect and add web URLs to ChatMessage
extension ChatMessage {
    
    /// Creates a ChatMessage with automatic URL detection
    /// - Parameters:
    ///   - id: Message ID
    ///   - role: Message role
    ///   - text: Message text (URLs will be auto-detected)
    ///   - images: Optional images
    ///   - forceWebURLs: Optional array to override auto-detection
    /// - Returns: ChatMessage with webURLs populated from detected URLs
    static func withURLDetection(
        id: UUID = UUID(),
        role: Role,
        text: String?,
        images: [UIImage]? = nil,
        forceWebURLs: [URL]? = nil
    ) -> ChatMessage {
        
        let detectedURLs: [URL]?
        
        if let forceWebURLs = forceWebURLs {
            detectedURLs = forceWebURLs
        } else if let text = text {
            let urls = URLDetector.extractRenderableURLs(from: text)
            detectedURLs = urls.isEmpty ? nil : urls
        } else {
            detectedURLs = nil
        }
        
        return ChatMessage(
            id: id,
            role: role,
            text: text,
            images: images,
            webURLs: detectedURLs
        )
    }
}
