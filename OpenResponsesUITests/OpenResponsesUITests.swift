//
//  OpenResponsesUITests.swift
//  OpenResponsesUITests
//
//  Created by Gunnar Hostetler on 8/9/25.
//

import XCTest

/// Screen-level UI and accessibility checks that need no API key: each test starts past onboarding in
/// Explore Demo mode, which answers locally. `performAccessibilityAudit` covers contrast, Dynamic Type,
/// clipped text, hit regions, element descriptions and traits (iOS 17 and later).
final class OpenResponsesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // Launch arguments land in UserDefaults' argument domain, which @AppStorage and UserDefaults.standard read.
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-exploreModeEnabled", "YES"] + extraArguments
        app.launch()
        XCTAssertTrue(app.textViews["chatInputTextField"].firstMatch.waitForExistence(timeout: 10)
                      || app.textFields["chatInputTextField"].firstMatch.waitForExistence(timeout: 1),
                      "the chat screen did not appear")
        return app
    }

    /// Texts the audit misreads. In Settings → Explore Mode, SwiftUI reports each button Label's title frame
    /// starting at the icon's x (34 pt) while the title is drawn from about 75 pt, so the audit calls the text
    /// clipped and partly unscaled. A screenshot on 2026-09-28 (iOS 27.0 simulator) showed both rows whole.
    private let knownLabelFrameQuirks: Set<String> = ["Start Demo", "Exit Demo"]

    /// Runs the audit and fails once with every issue found, so one run lists all of them. Recorded but not
    /// failed: "nearly passed" contrast warnings, system navigation-bar chrome the app does not draw, and the
    /// label-frame quirk above.
    private func audit(_ app: XCUIApplication, _ types: XCUIAccessibilityAuditType = .all, screen: String) throws {
        var issues: [String] = []
        let bars = app.navigationBars.allElementsBoundByIndex.map(\.frame)
        try app.performAccessibilityAudit(for: types) { issue in
            let frame = issue.element?.frame ?? .zero
            let label = issue.element?.label ?? ""
            let element = issue.element.map { "\($0.elementType.rawValue) label='\($0.label)' id='\($0.identifier)' frame=\($0.frame)" } ?? "no element"
            let systemChrome = !frame.isEmpty && bars.contains { $0.contains(frame) }
            let warning = issue.compactDescription.localizedCaseInsensitiveContains("nearly passed")
            let quirk = self.knownLabelFrameQuirks.contains(label)
            print("AUDIT [\(screen)]\(systemChrome ? " (navigation bar)" : warning ? " (warning)" : quirk ? " (known quirk)" : "") \(issue.compactDescription): \(element)")
            if !systemChrome && !warning && !quirk { issues.append("[\(screen)] \(issue.compactDescription): \(element)") }
            return true
        }
        XCTAssertTrue(issues.isEmpty, "\(issues.count) accessibility issues:\n" + issues.joined(separator: "\n"))
    }

    func testChatScreenPassesTheAccessibilityAudit() throws {
        let app = launch()
        try audit(app, screen: "chat")
    }

    func testSettingsPassTheAccessibilityAudit() throws {
        let app = launch()
        app.buttons["settingsButton"].tap()
        // Audit only after the sheet has finished presenting; mid-animation frames read as clipped text.
        let settled = app.buttons["Start Demo"]
        XCTAssertTrue(settled.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: settled)
        waitForExpectations(timeout: 5)
        sleep(1) // the sheet's transition can still be scaling its content when it first becomes hittable
        try audit(app, screen: "settings")
    }

    func testConversationListPassesTheAccessibilityAudit() throws {
        let app = launch()
        app.buttons["conversationsButton"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        try audit(app, screen: "conversations")
    }

    func testLargestTextSizeKeepsTheChatScreenReadable() throws {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        try audit(app, [.dynamicType, .textClipped], screen: "chat, largest text")
    }

    func testExploreModeAnswersAMessage() throws {
        let app = launch()
        let input = app.textViews["chatInputTextField"].exists ? app.textViews["chatInputTextField"] : app.textFields["chatInputTextField"]
        input.tap()
        input.typeText("Hello from the UI test")
        app.buttons["sendMessageButton"].tap()
        XCTAssertTrue(app.staticTexts["Hello from the UI test"].waitForExistence(timeout: 10), "the sent message is not shown")
    }

    /// Regression (reported on a device 2026-09-28): the Voice row in Settings → Model opened its sheet, and
    /// within seconds the sheet closed again.
    func testVoiceSettingsStayOpenFromTheModelTab() throws {
        let app = launch()
        app.buttons["settingsButton"].tap()
        let modelTab = app.segmentedControls.buttons["Model"]
        XCTAssertTrue(modelTab.waitForExistence(timeout: 5))
        modelTab.tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Voice model, voice and instructions")).firstMatch
        for _ in 0..<8 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable, "the Voice row was not reached")
        row.tap()
        let voiceSettings = app.navigationBars["Voice Mode Settings"]
        XCTAssertTrue(voiceSettings.waitForExistence(timeout: 5), "the voice settings did not open")
        sleep(5)
        XCTAssertTrue(voiceSettings.exists, "the voice settings closed by themselves")
        XCTAssertTrue(modelTab.exists, "Settings closed underneath the voice settings")
    }
}
