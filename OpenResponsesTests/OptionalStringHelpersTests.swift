import XCTest
@testable import OpenResponses

final class OptionalStringHelpersTests: XCTestCase {
    
    func testBoundProperty() {
        var str: String? = nil
        XCTAssertEqual(str.bound, "")
        
        str.bound = "hello"
        XCTAssertEqual(str, "hello")
        XCTAssertEqual(str.bound, "hello")
        
        str.bound = ""
        XCTAssertNil(str)
        XCTAssertEqual(str.bound, "")
    }
    
    func testOrEmptyHelper() {
        let nilStr: String? = nil
        XCTAssertEqual(nilStr.orEmpty(), "")
        
        let valStr: String? = "world"
        XCTAssertEqual(valStr.orEmpty(), "world")
    }
}
