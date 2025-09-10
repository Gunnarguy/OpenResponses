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
        
        // Skip screenshot services and redirecting services
        let skipServices = [
            "s.wordpress.com",  // WordPress mShots screenshot service
            "mshots",           // Any mShots-related service
        ]
        
        for service in skipServices {
            if host.contains(service) || path.contains(service) {
                return false
            }
        }
        
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
