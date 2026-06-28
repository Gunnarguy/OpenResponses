import XCTest
@testable import OpenResponses

final class ResponseSettingsRegistryTests: XCTestCase {

    func testEveryPromptCodingKeyHasSettingsDescriptor() {
        let codingKeys = Set(Prompt.CodingKeys.allCases.map(\.stringValue))
        let descriptorKeys = Set(ResponseSettingsRegistry.all.map(\.promptKeyPathName))
        let missing = codingKeys.subtracting(descriptorKeys)
        
        XCTAssertTrue(missing.isEmpty, "Missing settings descriptors: \(missing.sorted())")
    }
    
    func testEveryDescriptorHasRequiredFields() {
        for descriptor in ResponseSettingsRegistry.all {
            XCTAssertFalse(descriptor.title.isEmpty, "Descriptor \(descriptor.promptKeyPathName) is missing a title.")
            XCTAssertFalse(descriptor.description.isEmpty, "Descriptor \(descriptor.promptKeyPathName) is missing a description.")
        }
    }
}
