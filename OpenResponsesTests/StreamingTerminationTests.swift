import XCTest
@testable import OpenResponses

final class StreamingTerminationTests: XCTestCase {
    
    @MainActor
    func testGenerationIncrementsOnCancel() {
        let viewModel = ChatViewModel()
        let initialGen = viewModel.currentStreamGeneration
        
        viewModel.cancelStreaming()
        
        let newGen = viewModel.currentStreamGeneration
        XCTAssertNotEqual(initialGen, newGen, "Stream generation must change immediately on cancel")
    }
    
    @MainActor
    func testImmediateOperationalStateResets() {
        let viewModel = ChatViewModel()
        viewModel.isStreaming = true
        viewModel.isAwaitingComputerOutput = true
        viewModel.streamingStatus = .usingComputer
        
        viewModel.cancelStreaming()
        
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertFalse(viewModel.isAwaitingComputerOutput)
        XCTAssertEqual(viewModel.streamingStatus, .idle)
    }
}
