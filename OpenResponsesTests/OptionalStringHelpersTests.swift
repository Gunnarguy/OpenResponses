//
//  OptionalStringHelpersTests.swift
//  OpenResponsesTests
//

import XCTest
@testable import OpenResponses

final class OptionalStringHelpersTests: XCTestCase {

    // MARK: - `bound` tests

    func testBound_withNil() {
        var optionalString: String? = nil

        // Read
        XCTAssertEqual(optionalString.bound, "")

        // Write empty string
        optionalString.bound = ""
        XCTAssertNil(optionalString)

        // Write populated string
        optionalString.bound = "hello"
        XCTAssertEqual(optionalString, "hello")
    }

    func testBound_withEmptyString() {
        var optionalString: String? = ""

        // Read
        XCTAssertEqual(optionalString.bound, "")

        // Write empty string
        optionalString.bound = ""
        XCTAssertNil(optionalString)

        // Write populated string
        optionalString = "" // Reset
        optionalString.bound = "world"
        XCTAssertEqual(optionalString, "world")
    }

    func testBound_withPopulatedString() {
        var optionalString: String? = "existing"

        // Read
        XCTAssertEqual(optionalString.bound, "existing")

        // Write populated string
        optionalString.bound = "new"
        XCTAssertEqual(optionalString, "new")

        // Write empty string
        optionalString.bound = ""
        XCTAssertNil(optionalString)
    }

    // MARK: - `orEmpty()` tests

    func testOrEmpty_withNil() {
        let optionalString: String? = nil
        XCTAssertEqual(optionalString.orEmpty(), "")
    }

    func testOrEmpty_withEmptyString() {
        let optionalString: String? = ""
        XCTAssertEqual(optionalString.orEmpty(), "")
    }

    func testOrEmpty_withPopulatedString() {
        let optionalString: String? = "populated"
        XCTAssertEqual(optionalString.orEmpty(), "populated")
    }
}
