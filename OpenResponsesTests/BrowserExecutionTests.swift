import XCTest
import WebKit
import UIKit
@testable import OpenResponses

@MainActor
final class BrowserExecutionTests: XCTestCase {
    func testLateCallbackCannotCompleteNextRequest() async throws {
        let first = BrowserCallback<Int>()
        var late: ((Result<Int, Error>) -> Void)?
        do {
            _ = try await first.wait(timeout: .milliseconds(20), label: "fixture") { late = $0 }
            XCTFail("Expected timeout")
        } catch { XCTAssertTrue(error is ComputerUseError) }
        let next = BrowserCallback<Int>()
        let result = try await next.wait(timeout: .seconds(1), label: "next") { finish in
            late?(.success(999))
            finish(.success(42))
            finish(.success(7))
        }
        XCTAssertEqual(result, 42)
    }

    func testCallbackCancellationInterruptsExactlyOnce() async throws {
        let callback = BrowserCallback<Void>()
        let started = expectation(description: "started")
        var interruptCount = 0
        var completion: ((Result<Void, Error>) -> Void)?
        let task = Task {
            try await callback.wait(timeout: .seconds(5), label: "fixture", onInterrupt: { interruptCount += 1 }) {
                completion = $0; started.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 1)
        task.cancel()
        do { try await task.value; XCTFail("Expected cancellation") } catch { XCTAssertTrue(error is CancellationError) }
        completion?(.success(()))
        XCTAssertEqual(interruptCount, 1)
    }

    func testExecutionSerializesCallsAndCancelsQueuedWork() async throws {
        let queue = BrowserExecution()
        let started = expectation(description: "first")
        var events: [String] = []
        let first = Task { try await queue.run {
            events.append("first"); started.fulfill()
            try await Task.sleep(for: .seconds(5))
            events.append("should not run")
        } }
        await fulfillment(of: [started], timeout: 1)
        let cancelled = Task { try await queue.run { events.append("cancelled") } }
        await Task.yield()
        cancelled.cancel()
        let next = Task { try await queue.run { events.append("next") } }
        await Task.yield()
        first.cancel()
        _ = await first.result
        _ = await cancelled.result
        try await next.value
        XCTAssertEqual(events, ["first", "next"])
    }

    func testOperationDeadlineDoesNotReplayActionAndLaneRecovers() async throws {
        let queue = BrowserExecution()
        var writes = 0
        do {
            try await queue.run(timeout: .milliseconds(30)) {
                writes += 1
                try await Task.sleep(for: .seconds(5))
                writes += 1
            }
            XCTFail("Expected deadline")
        } catch { XCTAssertTrue(error is ComputerUseError) }
        let result = try await queue.run { 7 }
        XCTAssertEqual(result, 7)
        XCTAssertEqual(writes, 1)
    }

    func testTurnCancellationInvalidatesActiveAndQueuedActions() async throws {
        let queue = BrowserExecution()
        let started = expectation(description: "active")
        var oldWrites = 0
        let first = Task { try await queue.run {
            started.fulfill()
            try await Task.sleep(for: .seconds(5))
            oldWrites += 1
        } }
        await fulfillment(of: [started], timeout: 1)
        let queued = Task { try await queue.run { oldWrites += 1 } }
        await Task.yield()
        queue.beginTurn()
        _ = await first.result
        _ = await queued.result
        try await queue.run { oldWrites += 10 }
        XCTAssertEqual(oldWrites, 10)
        XCTAssertEqual(queue.actionsUsed, 1)
    }

    func testActionBudgetAndApprovalGateApplyToSameLane() async throws {
        let queue = BrowserExecution()
        queue.maxActions = 2
        try await queue.run(actions: 2) { }
        do { try await queue.run { XCTFail("Budget bypass") }; XCTFail() } catch { }
        queue.beginTurn()
        queue.approvalPending = true
        do { try await queue.run { XCTFail("Approval bypass") }; XCTFail() } catch {
            guard case ComputerUseError.approvalRequired = error else { return XCTFail("Unexpected error") }
        }
        queue.approvalPending = false
        try await queue.run { }
    }

    func testRepeatedCallIDDoesNotReplayAnUncertainWriteAcrossTurns() async throws {
        let queue = BrowserExecution()
        var writes = 0
        do {
            try await queue.run(callID: "same-call", timeout: .milliseconds(20)) {
                writes += 1
                try await Task.sleep(for: .seconds(5))
            }
            XCTFail("Expected timeout")
        } catch { }
        queue.beginTurn()
        do { try await queue.run(callID: "same-call") { writes += 1 }; XCTFail("Duplicate replay") } catch {
            guard case ComputerUseError.duplicateCall = error else { return XCTFail("Wrong duplicate result") }
        }
        try await queue.run(callID: "new-call") { writes += 1 }
        XCTAssertEqual(writes, 2)
    }

    func testNavigationValidationAndPageBudgetIncludeRedirectDestinations() throws {
        for url in ["file:///etc/passwd", "javascript:alert(1)", "data:text/html,test", "ftp://example.com", "https://user:secret@example.com", "about:blank"] {
            XCTAssertThrowsError(try BrowserNavigationPolicy.url(url), url)
        }
        XCTAssertEqual(try BrowserNavigationPolicy.url("example.com/path").absoluteString, "https://example.com/path")
        var policy = BrowserNavigationPolicy()
        policy.maxPages = 2
        try policy.admit(URL(string: "https://example.com/one")!)
        try policy.admit(URL(string: "https://example.com/one#anchor")!)
        try policy.admit(URL(string: "https://other.example/redirect")!)
        XCTAssertThrowsError(try policy.admit(URL(string: "https://third.example/")!))
        XCTAssertEqual(policy.visited.count, 2)
    }
}

@MainActor
final class BrowserWebKitTests: XCTestCase {
    private var browser: ComputerService!

    override func setUp() async throws {
        browser = ComputerService(autoAttachWebView: true)
        browser.beginTurn()
    }

    override func tearDown() async throws {
        browser.closeBrowser()
        browser = nil
    }

    private let fixture = """
    <html><head><meta name='viewport' content='width=device-width, initial-scale=1'><title>Browser fixture</title></head>
    <body><h1>Browser fixture</h1>
    <button id='first' onclick='window.clicks=(window.clicks||0)+1;document.querySelector("#counter").textContent=window.clicks'>Choose</button>
    <button id='second'>Choose</button><p id='counter'>0</p>
    <form onsubmit='event.preventDefault(); window.submits=(window.submits||0)+1; document.querySelector("#result").textContent="Submits: "+window.submits'>
    <label for='email'>Email</label><input id='email' name='email'>
    <label for='search'>Search</label><input id='search'>
    <button>Submit</button></form><p id='result'>Ready</p>
    <a id='destination' href='https://example.com'>Destination</a>
    <script>
      const input=document.querySelector('#email');
      const native=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value');
      let frameworkValue='';
      Object.defineProperty(input,'value',{get(){return native.get.call(this)},set(v){frameworkValue=v;native.set.call(this,v)}});
      input.addEventListener('input',()=>{window.nativeSetterWorked=input.value!==frameworkValue});
    </script></body></html>
    """

    func testRealWebKitSnapshotPreciseClickAndNativeInputSubmission() async throws {
        let page = try await browser.testing_loadHTML(fixture)
        XCTAssertEqual(page.state.title, "Browser fixture")
        let png = try XCTUnwrap(page.screenshot.flatMap { Data(base64Encoded: $0) })
        XCTAssertTrue(png.starts(with: [137, 80, 78, 71]))
        let pixels = try XCTUnwrap(UIImage(data: png)?.cgImage)
        XCTAssertEqual(pixels.width, 440, "PNG pixels must match the advertised computer-tool viewport")
        XCTAssertEqual(pixels.height, 956)
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = "Browser fixture screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
        do { _ = try await browser.liveBrowserClick(targetText: "Choose"); XCTFail("Ambiguous click") } catch { }
        let reference = try XCTUnwrap(page.state.buttons.first(where: { $0.text == "Choose" })?.ref)
        let clicked = try await browser.liveBrowserClick(targetText: "", elementRef: reference)
        XCTAssertTrue(clicked.state.visibleTextPreview.contains("1"))
        let count = try await browser.testing_evaluatePage("window.clicks")
        XCTAssertEqual(count as? Int, 1)

    }

    func testNativeSetterSubmitsOnceAndPreservesWhitespace() async throws {
        let page = try await browser.testing_loadHTML(fixture)
        let ref = try XCTUnwrap(page.state.inputs.first(where: { $0.text == "Email" })?.ref)
        let filled = try await browser.liveBrowserType(text: "  plus + & ' quote  ", fieldHint: nil, submit: true, elementRef: ref)
        XCTAssertTrue(filled.state.visibleTextPreview.contains("Submits: 1"))
        let setter = try await browser.testing_evaluatePage("window.nativeSetterWorked")
        XCTAssertEqual(setter as? Bool, true)
        let value = try await browser.testing_evaluatePage("document.querySelector('#email').value")
        XCTAssertEqual(value as? String, "  plus + & ' quote  ")
    }

    func testReferencesExpireAfterReadAndChangedDestination() async throws {
        let page = try await browser.testing_loadHTML(fixture)
        let old = try XCTUnwrap(page.state.buttons.first?.ref)
        _ = try await browser.liveBrowserRead()
        do { _ = try await browser.liveBrowserClick(targetText: "", elementRef: old); XCTFail("Stale reference") } catch { }
        let next = try await browser.liveBrowserRead()
        let link = try XCTUnwrap(next.state.links.first?.ref)
        _ = try await browser.testing_evaluatePage("document.querySelector('#destination').href='https://example.org'")
        do { _ = try await browser.liveBrowserClick(targetText: "", elementRef: link); XCTFail("Changed destination") } catch { }
        // A hostile page's main-world map cannot forge an isolated-world reference.
        _ = try await browser.testing_evaluatePage("globalThis.__openResponsesSnapshot={refs:new Map([['forged',{el:document.querySelector('#first')}]]),url:location.href}; true")
        do { _ = try await browser.liveBrowserClick(targetText: "", elementRef: "forged"); XCTFail("Forged reference") } catch { }
    }

    func testMissingDisabledAndObscuredTargetsNeverReportSuccess() async throws {
        _ = try await browser.testing_loadHTML(fixture)
        do { _ = try await browser.liveBrowserType(text: "secret", fieldHint: "Missing field", submit: false); XCTFail() } catch { }
        _ = try await browser.testing_evaluatePage("document.querySelector('#first').disabled=true;document.querySelector('#second').disabled=true")
        do { _ = try await browser.liveBrowserClick(targetText: "Choose"); XCTFail() } catch { }
        _ = try await browser.testing_evaluatePage("const overlay=document.createElement('div');overlay.style='position:fixed;inset:0;background:white;z-index:999';document.body.append(overlay)")
        do { _ = try await browser.liveBrowserType(text: "secret", fieldHint: "Email", submit: false); XCTFail() } catch { }
    }

    func testInvalidWaitUnknownActionAndApprovalBlockBothToolPaths() async throws {
        _ = try await browser.testing_loadHTML(fixture)
        for action in [ComputerAction(type: "wait", parameters: ["ms": -1]), ComputerAction(type: "wait", parameters: ["ms": Double.nan]), ComputerAction(type: "invalid", parameters: [:])] {
            do { _ = try await browser.executeAction(action); XCTFail() } catch { }
        }
        browser.setApprovalPending(true)
        do { _ = try await browser.executeAction(ComputerAction(type: "click", parameters: ["x": 20, "y": 100])); XCTFail() } catch { }
        do { _ = try await browser.liveBrowserClick(targetText: "Submit"); XCTFail() } catch { }
        browser.setApprovalPending(false)
        _ = try await browser.liveBrowserRead()
    }

    func testProcessTerminationInterruptsActiveBatchAndRecoversWithoutReplay() async throws {
        let initial = try await browser.testing_loadHTML(fixture)
        let oldRef = try XCTUnwrap(initial.state.buttons.first?.ref)
        let pending = Task { try await browser.executeActions([
            ComputerAction(type: "wait", parameters: ["ms": 10_000]),
            ComputerAction(type: "click", parameters: ["x": 20, "y": 90])
        ]) }
        try await Task.sleep(for: .milliseconds(100))
        browser.testing_simulateProcessTermination()
        do { _ = try await pending.value; XCTFail("Expected process failure") } catch {
            guard case ComputerUseError.processTerminated = error else { return XCTFail("Wrong process failure: \(error)") }
        }
        let recovered = try await browser.liveBrowserRead()
        XCTAssertTrue(recovered.output?.contains("restarted") == true)
        XCTAssertEqual(recovered.state.title, "")
        do { _ = try await browser.liveBrowserClick(targetText: "", elementRef: oldRef); XCTFail() } catch { }
    }

    func testInputSanitizationAndInvalidNavigationAreReported() async throws {
        _ = try await browser.testing_loadHTML(fixture)
        do { _ = try await browser.liveBrowserType(text: "line one\nline two", fieldHint: "Email", submit: true); XCTFail() } catch { }
        let submits = try await browser.testing_evaluatePage("window.submits || 0")
        XCTAssertEqual(submits as? Int, 0)
        do { _ = try await browser.liveBrowserNavigate(to: "file:///etc/passwd"); XCTFail() } catch { }
        let page = try await browser.liveBrowserRead()
        XCTAssertEqual(page.state.title, "Browser fixture")
    }

    func testScreenshotClickFiresExactlyOnce() async throws {
        _ = try await browser.testing_loadHTML(fixture)
        let rawPoint = try await browser.testing_evaluatePage("(() => {const r=document.querySelector('#first').getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2}})()")
        let point = try XCTUnwrap(rawPoint as? [String: Double])
        _ = try await browser.executeAction(ComputerAction(type: "click", parameters: point))
        let count = try await browser.testing_evaluatePage("window.clicks")
        XCTAssertEqual(count as? Int, 1)
    }
}

/// Explicit public-site smoke tests, separate from the deterministic fixture suite.
@MainActor
final class BrowserLiveSiteTests: XCTestCase {
    func testExampleAndIANAWithHistory() async throws {
        let browser = ComputerService(autoAttachWebView: true)
        defer { browser.closeBrowser() }
        browser.beginTurn()
        let example = try await browser.liveBrowserNavigate(to: "https://example.com")
        XCTAssertEqual(example.state.title, "Example Domain")
        XCTAssertNotNil(example.screenshot)
        let iana = try await browser.liveBrowserNavigate(to: "https://www.iana.org/help/example-domains")
        XCTAssertTrue(iana.state.title.lowercased().contains("example"))
        XCTAssertNotNil(iana.screenshot)
        let back = try await browser.liveBrowserHistory(action: "back")
        XCTAssertEqual(back.state.title, "Example Domain")
        let forward = try await browser.liveBrowserHistory(action: "forward")
        XCTAssertTrue(forward.state.title.lowercased().contains("example"))
    }
}
