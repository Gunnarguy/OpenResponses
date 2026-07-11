import XCTest
@testable import OpenResponses

final class ImageProcessingUtilsTests: XCTestCase {
    
    func testOptimizeImageForDisplayNoResize() {
        let original = ImageProcessingUtils.createPlaceholderImage(size: CGSize(width: 100, height: 100))
        let optimized = ImageProcessingUtils.optimizeImageForDisplay(original, maxDimension: 200)
        
        XCTAssertEqual(optimized.size.width, 100)
        XCTAssertEqual(optimized.size.height, 100)
    }
    
    func testOptimizeImageForDisplayResizes() {
        let original = ImageProcessingUtils.createPlaceholderImage(size: CGSize(width: 500, height: 250))
        let optimized = ImageProcessingUtils.optimizeImageForDisplay(original, maxDimension: 200)
        
        XCTAssertEqual(optimized.size.width, 200)
        XCTAssertEqual(optimized.size.height, 100)
    }
    
    func testCreatePlaceholderImage() {
        let placeholder = ImageProcessingUtils.createPlaceholderImage(size: CGSize(width: 50, height: 50))
        XCTAssertNotNil(placeholder)
        XCTAssertEqual(placeholder.size.width, 50)
        XCTAssertEqual(placeholder.size.height, 50)
    }
    
    func testProcessBase64Image() {
        let expectation = self.expectation(description: "Base64 processing completion")
        
        // Generate a 1x1 solid red PNG base64 string
        let base64String = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
        
        ImageProcessingUtils.processBase64Image(base64String) { image in
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
