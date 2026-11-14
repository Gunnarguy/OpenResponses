import XCTest
@testable import OpenResponses

final class DateFormattingTests: XCTestCase {
    
    func testParseISO8601Valid() {
        let isoStr = "2026-07-10T15:30:45.123Z"
        let date = AppleDateUtilities.parseISO8601(isoStr)
        XCTAssertNotNil(date)
        
        let formatted = AppleDateUtilities.formatISO8601(date!)
        XCTAssertEqual(formatted, isoStr)
    }
    
    func testParseISO8601Invalid() {
        let invalidStr = "not-a-date"
        let date = AppleDateUtilities.parseISO8601(invalidStr)
        XCTAssertNil(date)
    }
}

/// Pins when the app asks Apple for a rating. Each rule here, if it drifted, would either waste one of Apple's three
/// prompts a year or skip the people most worth asking. (The test target lists its files in the project, so this
/// class lives in an existing file.)
@MainActor
final class ReviewPromptServiceTests: XCTestCase {

    func testAsksOnTheFirstCleanAnswer() {
        XCTAssertEqual(ReviewPromptService.minimumCleanAnswers, 1)
        XCTAssertTrue(ask(clean: true, cleanAnswers: 1, finishedAnswers: 1))
    }

    func testAsksOnTheThirdFinishedAnswer_evenWithoutACleanOne() {
        XCTAssertEqual(ReviewPromptService.minimumFinishedAnswers, 3)
        XCTAssertFalse(ask(clean: false, cleanAnswers: 0, finishedAnswers: 1))
        XCTAssertFalse(ask(clean: false, cleanAnswers: 0, finishedAnswers: 2))
        XCTAssertTrue(ask(clean: false, cleanAnswers: 0, finishedAnswers: 3))
    }

    func testAnAnswerWithAFailedStep_beforeTheThird_doesNotAsk_evenAfterAnEarlierCleanOne() {
        // The moment is the good answer itself, not a later one that went wrong.
        XCTAssertFalse(ask(clean: false, cleanAnswers: 1, finishedAnswers: 2))
    }

    func testOncePerVersion() {
        XCTAssertFalse(ask(clean: true, cleanAnswers: 2, finishedAnswers: 5, lastAskedVersion: "3.0"))
        XCTAssertTrue(ask(clean: true, cleanAnswers: 2, finishedAnswers: 5, lastAskedVersion: "2.9", daysSince: 30))
    }

    /// Human Interface Guidelines: at least a week or two between requests, whatever the version.
    func testNeverWithinFourteenDaysOfTheLastAsk() {
        XCTAssertEqual(ReviewPromptService.minimumDaysBetweenAsks, 14)
        XCTAssertFalse(ask(clean: true, cleanAnswers: 2, finishedAnswers: 5, lastAskedVersion: "2.9", daysSince: 13.9))
        XCTAssertTrue(ask(clean: true, cleanAnswers: 2, finishedAnswers: 5, lastAskedVersion: "2.9", daysSince: 14))
    }

    func testNeverUnderTests_orWithoutAVersion() {
        XCTAssertFalse(ask(clean: true, cleanAnswers: 1, finishedAnswers: 1, isTesting: true))
        XCTAssertFalse(ask(clean: true, cleanAnswers: 1, finishedAnswers: 1, version: ""))
    }

    private func ask(
        clean: Bool, cleanAnswers: Int, finishedAnswers: Int, lastAskedVersion: String? = nil,
        version: String = "3.0", daysSince: Double? = nil, isTesting: Bool = false
    ) -> Bool {
        ReviewPromptService.shouldAsk(
            thisAnswerIsClean: clean, cleanAnswers: cleanAnswers, finishedAnswers: finishedAnswers,
            lastAskedVersion: lastAskedVersion, currentVersion: version, daysSinceLastAsk: daysSince,
            isTesting: isTesting)
    }

    // MARK: What counts as an answer

    func testAnAssistantAnswerWithText_isClean() {
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "Paris.")), .clean)
        let step = ToolExecutionTimeline(toolType: "web_search_call", toolName: "web_search_call", status: .completed)
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "Paris.", toolTimeline: [step])), .clean)
    }

    func testAnAnswerWhoseToolStepFailedOrWasCancelled_isFinishedButNotClean() {
        for status in [ToolExecutionTimeline.Status.failed, .cancelled] {
            let step = ToolExecutionTimeline(toolType: "function_call", toolName: "browserRead", status: status)
            XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "I could not open it.", toolTimeline: [step])), .finished)
        }
    }

    func testExploreDemo_neverCounts() {
        XCTAssertEqual(
            ReviewPromptService.outcome(of: ChatMessage(role: .assistant, text: "A demo reply."), exploreDemo: true), .none)
    }

    func testAnError_aNotice_anEmptyAnswer_orNoMessage_doesNotCount() {
        // A failed turn ends on a system message (ChatViewModel.handleError).
        XCTAssertEqual(outcome(ChatMessage(role: .system, text: "Error: The request timed out.")), .none)
        XCTAssertEqual(outcome(ChatMessage(role: .user, text: "Hello")), .none)
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "  \n")), .none)
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: nil)), .none)
        XCTAssertEqual(outcome(nil), .none)
    }

    func testAStoppedAnswer_doesNotCount() {
        let stopped = "The capital of" + "\n\n" + ReviewPromptService.cancelledMarker
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: stopped)), .none)
    }

    func testAnAnswerStillWaitingForAnApprovalOrAStep_doesNotCount() {
        let request = MCPApprovalRequest(id: "a1", toolName: "search", serverLabel: "notion", arguments: "{}", status: .pending)
        XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "Approve?", mcpApprovalRequests: [request])), .none)
        for status in [ToolExecutionTimeline.Status.awaitingApproval, .running, .queued] {
            let step = ToolExecutionTimeline(toolType: "function_call", toolName: "run_python", status: status)
            XCTAssertEqual(outcome(ChatMessage(role: .assistant, text: "Running.", toolTimeline: [step])), .none)
        }
    }

    /// The ask is recorded only by `didAsk`, which ContentView calls after it made the request.
    func testCountsAndTheAskRecord_liveInTheGivenDefaults() throws {
        let suite = "ReviewPromptServiceTests"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = ReviewPromptService(defaults: defaults)
        service.noteTurnEnded(lastMessage: ChatMessage(role: .assistant, text: "Paris."), exploreDemo: false)
        service.noteTurnEnded(lastMessage: ChatMessage(role: .system, text: "Error"), exploreDemo: false)
        XCTAssertEqual(defaults.integer(forKey: "reviewPrompt.finishedAnswers"), 1)
        XCTAssertEqual(defaults.integer(forKey: "reviewPrompt.cleanAnswers"), 1)
        XCTAssertFalse(service.wantsPrompt, "never under tests")
        XCTAssertNil(defaults.string(forKey: "reviewPrompt.lastAskedVersion"), "nothing is recorded until the request is made")
        service.didAsk()
        XCTAssertNotNil(defaults.string(forKey: "reviewPrompt.lastAskedVersion"))
        XCTAssertGreaterThan(defaults.double(forKey: "reviewPrompt.lastAskedAt"), 0)
    }

    func testTheSettingsLinkOpensTheWriteReviewPage() {
        XCTAssertEqual(AboutView.writeReviewURL.absoluteString, "https://apps.apple.com/app/id6757338355?action=write-review")
    }

    private func outcome(_ message: ChatMessage?) -> ReviewPromptService.Outcome {
        ReviewPromptService.outcome(of: message, exploreDemo: false)
    }
}
