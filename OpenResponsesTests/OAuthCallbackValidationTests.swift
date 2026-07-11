import XCTest
@testable import OpenResponses

final class OAuthCallbackValidationTests: XCTestCase {
    
    func testOAuthRandomStringGenerator() {
        let rand1 = OAuthPKCE.random(length: 16)
        XCTAssertEqual(rand1.count, 16)
        
        let rand2 = OAuthPKCE.random(length: 32)
        XCTAssertEqual(rand2.count, 32)
        XCTAssertNotEqual(rand1, rand2)
    }
    
    func testCodeChallengeComputation() {
        // Standard RFC 7636 PKCE S256 test vector
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = OAuthPKCE.codeChallenge(from: verifier)
        XCTAssertEqual(challenge, "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }
    
    func testOAuthErrorDescriptions() {
        XCTAssertEqual(OAuthError.invalidCallbackScheme.localizedDescription, "The OAuth redirect callback scheme is invalid or unexpected.")
        XCTAssertEqual(OAuthError.stateMismatch.localizedDescription, "The OAuth state parameter mismatch. Possible CSRF attempt.")
    }
}
