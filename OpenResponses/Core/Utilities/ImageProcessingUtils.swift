import UIKit
import Foundation

/// Utility class for optimizing image processing and memory management
class ImageProcessingUtils {
    
    /// Optimizes image for display by reducing size if necessary
    static func optimizeImageForDisplay(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        // If image is already small enough, return as-is
        guard maxSize > maxDimension else { return image }
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxDimension / maxSize
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /// Processes base64 image data efficiently with memory management
    static func processBase64Image(_ base64String: String, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                guard let imageData = Data(base64Encoded: base64String) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                guard let originalImage = UIImage(data: imageData) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                // Optimize the image for display
                let optimizedImage = optimizeImageForDisplay(originalImage)
                
                DispatchQueue.main.async {
                    completion(optimizedImage)
                }
            }
        }
    }
    
    /// Creates a placeholder image for loading states
    static func createPlaceholderImage(size: CGSize = CGSize(width: 300, height: 200)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // Fill with light gray background
        context?.setFillColor(UIColor.systemGray6.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        // Add loading icon
        let iconSize: CGFloat = 40
        let iconRect = CGRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        
        context?.setFillColor(UIColor.systemGray3.cgColor)
        context?.fillEllipse(in: iconRect)
        
        let placeholderImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return placeholderImage ?? UIImage()
    }
}

/// Extension to UIImage for additional utility methods
extension UIImage {
    /// Returns the memory footprint of the image in bytes
    var memoryFootprint: Int {
        guard let cgImage = self.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
    
    /// Checks if the image is considered large (>5MB)
    var isLargeImage: Bool {
        return memoryFootprint > 5 * 1024 * 1024 // 5MB
    }
}
