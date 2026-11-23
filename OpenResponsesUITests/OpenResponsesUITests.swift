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
        // The audits' frames and contrast samples assume portrait; on 2026-11-20 a simulator left in landscape (frames
        // past x = 700 on a 402 pt wide phone) failed the chat audit on text that passes in portrait.
        XCUIDevice.shared.orientation = .portrait
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
    ///
    /// The Settings root's section headers below the first screenful ("Assistant", "What the assistant can do")
    /// are reported as "Dynamic Type font sizes are partially unsupported" with the frame of the system's
    /// full-width header container, whatever the header holds: a String, a Label, an HStack of icon and text,
    /// and an explicit .subheadline font all gave the same report. A screenshot on 2026-11-19 (iOS 27.0
    /// simulator, Accessibility Large) showed both headers grown, the second wrapping to two lines.
    private let knownLabelFrameQuirks: Set<String> = ["Start Demo", "Exit Demo", "Assistant", "What the assistant can do"]

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

    /// Regression (reported on a device 2026-09-28): the Voice row in Settings opened its sheet, and within seconds
    /// the sheet closed again. Since 3.1 the row is on the Settings root, not the old Model tab.
    func testVoiceSettingsStayOpenFromSettings() throws {
        let app = launch()
        app.buttons["settingsButton"].tap()
        let settingsBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsBar.waitForExistence(timeout: 5))
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Voice")).firstMatch
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable, "the Voice row was not reached")
        row.tap()
        let voiceSettings = app.navigationBars["Voice Mode Settings"]
        XCTAssertTrue(voiceSettings.waitForExistence(timeout: 5), "the voice settings did not open")
        sleep(5)
        XCTAssertTrue(voiceSettings.exists, "the voice settings closed by themselves")
        XCTAssertTrue(settingsBar.exists, "Settings closed underneath the voice settings")
    }

    /// Search finds an option by a word that is not in its name, and opens the page that holds it (3.1).
    func testSettingsSearchOpensThePageThatHoldsAnOption() throws {
        let app = launch()
        app.buttons["settingsButton"].tap()
        let search = app.searchFields["Search settings"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("pyodide")
        let result = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Local Python")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "search did not list Local Python")
        result.tap()
        XCTAssertTrue(app.navigationBars["Tools"].waitForExistence(timeout: 5), "the Tools page did not open")
    }
}

/// App Store screenshots (2026-11-22). Off unless the runner sets `TEST_RUNNER_STORE_SHOTS_DIR` (xcodebuild passes it as
/// `STORE_SHOTS_DIR`), so `scripts/ui_tests.sh` never runs them. Needs a simulator whose Keychain holds an OpenAI key
/// (`scripts/sim_openai_key.py <udid>`): the chats are real answers. Each step writes `<n>-<name>.png` and the screen's
/// element tree as `<n>-<name>.txt` into that folder.
final class StoreScreenshotTests: XCTestCase {
    private var folder: URL!
    private var step = 0

    override func setUpWithError() throws {
        guard let dir = ProcessInfo.processInfo.environment["STORE_SHOTS_DIR"], !dir.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_STORE_SHOTS_DIR to capture App Store screenshots.")
        }
        folder = URL(fileURLWithPath: dir)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        continueAfterFailure = true
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        step += 1
        sleep(1)
        let base = folder.appendingPathComponent(String(format: "%02d-%@", step, name))
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: base.appendingPathExtension("png"))
        try? app.debugDescription.write(to: base.appendingPathExtension("txt"), atomically: true, encoding: .utf8)
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // The rating sheet asks once per version after a clean answer; marking 3.1 as asked keeps it out of the shots.
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-exploreModeEnabled", "NO", "-reviewPrompt.lastAskedVersion", "3.1"]
        app.launch()
        _ = app.textViews["chatInputTextField"].firstMatch.waitForExistence(timeout: 15)
        return app
    }

    private func done() {
        try? Data().write(to: folder.appendingPathComponent("DONE"))
    }

    /// Sends a message and waits until the answer has finished streaming.
    private func send(_ app: XCUIApplication, _ text: String, timeout: TimeInterval = 120) {
        let input = app.textViews["chatInputTextField"].exists ? app.textViews["chatInputTextField"] : app.textFields["chatInputTextField"]
        for _ in 0..<5 {
            input.tap()
            if (input.value(forKey: "hasKeyboardFocus") as? Bool) == true { break }
            sleep(1)
        }
        input.typeText(text)
        app.buttons["sendMessageButton"].tap()
        let allow = app.buttons["Allow & Send"]
        if allow.waitForExistence(timeout: 4) { allow.tap() }
        let stop = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'stop'")).firstMatch
        _ = stop.waitForExistence(timeout: 10)
        let end = Date().addingTimeInterval(timeout)
        while stop.exists && Date() < end { sleep(2) }
        sleep(2)
    }

    private func tapFirst(_ app: XCUIApplication, _ predicate: String, _ name: String) -> Bool {
        let element = app.descendants(matching: .any).matching(NSPredicate(format: predicate)).firstMatch
        guard element.waitForExistence(timeout: 5) else { shot(app, "missing-\(name)"); return false }
        element.tap()
        return true
    }

    /// Searches Settings and opens the first result whose label starts with `result`.
    private func openFromSearch(_ app: XCUIApplication, _ term: String, _ result: String) -> Bool {
        let search = app.searchFields["Search settings"]
        guard search.waitForExistence(timeout: 5) else { shot(app, "missing-search"); return false }
        search.tap()
        if let current = search.value as? String, !current.isEmpty, current != "Search settings" {
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        search.typeText(term)
        return tapFirst(app, "label BEGINSWITH '\(result)'", "result-\(term)")
    }

    private func back(_ app: XCUIApplication) {
        let bar = app.navigationBars.firstMatch
        if bar.buttons.firstMatch.exists { bar.buttons.firstMatch.tap() }
        sleep(1)
    }

    private func openPro(_ app: XCUIApplication) {
        let row = app.buttons["settings.pro"]
        guard row.waitForExistence(timeout: 5) else { shot(app, "missing-pro"); return }
        for _ in 0..<8 where !row.isHittable { app.swipeUp() }
        row.tap()
        sleep(3)
        shot(app, "pro")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        sleep(1)
    }

    /// The Pro sheet only (the iPhone set already has the rest).
    func testProSheet() throws {
        let app = launch()
        app.buttons["settingsButton"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        openPro(app)
        done()
    }

    /// Screens that need no answer: the model menu, Settings, Workbench, Connectors and Pro. No API requests.
    func testStaticSet() throws {
        let app = launch()
        if tapFirst(app, "label == 'Model' AND elementType == 9", "model") {
            sleep(2); shot(app, "models")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)).tap()
            sleep(1)
        }
        app.buttons["settingsButton"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        shot(app, "settings")
        if openFromSearch(app, "Workbench", "API Workbench") { sleep(2); shot(app, "workbench"); back(app) }
        if openFromSearch(app, "Connectors", "Connectors") { sleep(2); shot(app, "connectors"); back(app) }
        let search = app.searchFields["Search settings"]
        if search.exists, let current = search.value as? String, !current.isEmpty, current != "Search settings" {
            search.tap(); search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        openPro(app)
        done()
    }

    /// The whole set in one run: three live requests (web search, Python, a Decisions ask).
    func testStoreSet() throws {
        var app = launch()
        if (ProcessInfo.processInfo.environment["STORE_SHOTS_SKIP_WEB"] ?? "").isEmpty {
            send(app, "Search the web: what did OpenAI ship this month? Three short bullets with sources.")
            shot(app, "web-search")
            // A second message in the same chat sometimes cannot get keyboard focus; a relaunch opens a fresh field.
            app.terminate()
            app = launch()
        }
        send(app, "Use Python to make a bar chart of average monthly rainfall in Seattle, then say in one plain sentence which month is wettest.", timeout: 180)
        shot(app, "python")
        if tapFirst(app, "identifier == 'curlybraces' OR label == 'Request inspector'", "inspector") {
            sleep(2); shot(app, "inspector")
            if app.buttons["Close"].exists { app.buttons["Close"].tap() }
            sleep(1)
        }
        if tapFirst(app, "label == 'Model' AND elementType == 9", "model") {
            sleep(2); shot(app, "models")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)).tap()
            sleep(1)
        }
        app.buttons["settingsButton"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        shot(app, "settings")
        if (ProcessInfo.processInfo.environment["STORE_SHOTS_SKIP_DECISIONS"] ?? "").isEmpty, openFromSearch(app, "Decisions", "Decisions") {
            sleep(2)
            if app.buttons["decisions.ask"].waitForExistence(timeout: 3) {
                app.buttons["decisions.ask"].tap()
                sleep(25); shot(app, "decisions"); app.swipeUp(); shot(app, "decisions-scroll")
            }
            back(app)
        }
        if openFromSearch(app, "Workbench", "API Workbench") { sleep(2); shot(app, "workbench"); back(app) }
        if openFromSearch(app, "Connectors", "Connectors") { sleep(2); shot(app, "connectors"); back(app) }
        let search = app.searchFields["Search settings"]
        if search.exists, let current = search.value as? String, !current.isEmpty, current != "Search settings" {
            search.tap(); search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        openPro(app)
        done()
    }
}
