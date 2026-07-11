import XCTest
@testable import OpenResponses

final class UIImageExtensionsTests: XCTestCase {
    
    func testMemoryFootprintAndLargeImageCheck() {
        let size = CGSize(width: 100, height: 100)
        let image = ImageProcessingUtils.createPlaceholderImage(size: size)
        
        XCTAssertGreaterThan(image.memoryFootprint, 0)
        XCTAssertFalse(image.isLargeImage)
    }
}
