import XCTest
@testable import OpenResponses

/// These run the bundled Pyodide interpreter in a real WKWebView inside the test host.
@MainActor
final class LocalPythonRunnerTests: XCTestCase {
    private let runner = LocalPythonRunner.shared

    func testRunsPythonAndReturnsPrintedOutputAndTheLastValue() async {
        let result = await runner.run("import statistics\nprint(statistics.mean([2, 4, 9]))\n6 * 7", timeout: 60)
        XCTAssertNil(result.error, result.toolOutput)
        XCTAssertEqual(result.stdout, "5")
        XCTAssertEqual(result.value, "42")
    }

    func testEachRunStartsWithAnEmptyNamespace() async {
        _ = await runner.run("left_over = 1", timeout: 60)
        let result = await runner.run("print('left_over' in globals())", timeout: 60)
        XCTAssertEqual(result.stdout, "False", result.toolOutput)
    }

    func testErrorsComeBackAsTracebacks() async {
        let result = await runner.run("1 / 0", timeout: 60)
        XCTAssertTrue(result.error?.contains("ZeroDivisionError") == true, result.toolOutput)
    }

    func testTheNetworkAndPackageInstallsAreOutOfReach() async {
        let network = await runner.run("""
        from pyodide.http import pyfetch
        try:
            await pyfetch("https://example.com")
            print("reached")
        except Exception:
            print("blocked")
        """, timeout: 20)
        XCTAssertFalse(network.timedOut, "a refused request must fail at once, not wait out the time limit")
        XCTAssertEqual(network.stdout, "blocked", network.toolOutput)
        let package = await runner.run("import numpy", timeout: 60)
        XCTAssertTrue(package.error?.contains("ModuleNotFoundError") == true, package.toolOutput)
    }

    func testARunawayLoopIsStoppedAndTheNextRunStartsFresh() async {
        let stuck = await runner.run("while True:\n    pass", timeout: 3)
        XCTAssertTrue(stuck.timedOut)
        XCTAssertTrue(stuck.toolOutput.contains("time limit"))
        let next = await runner.run("print('ok')", timeout: 60)
        XCTAssertEqual(next.stdout, "ok", next.toolOutput)
    }

    func testToolOutputIsCappedAndLabelled() {
        let long = LocalPythonRunner.Result(stdout: String(repeating: "x", count: 20_000)).toolOutput
        XCTAssertTrue(long.hasPrefix("stdout:\n"))
        XCTAssertTrue(long.hasSuffix("[output truncated]"))
        XCTAssertLessThan(long.count, LocalPythonRunner.Result.outputLimit + 100)
        XCTAssertEqual(LocalPythonRunner.Result().toolOutput, "The code ran and printed nothing.")
    }
}
