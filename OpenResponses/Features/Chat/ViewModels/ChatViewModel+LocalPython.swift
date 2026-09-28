import Foundation

/// A `run_python` call shown to the user before it runs.
struct PythonRunRequest: Identifiable, Equatable {
    let id = UUID()
    let code: String
}

extension ChatViewModel {
    /// Handles the `run_python` function tool: the user approves each run, then the code runs on this device.
    func runPythonTool(_ call: OutputItem) async -> String {
        struct Arguments: Decodable { let code: String }
        guard activePrompt.currentOptions.localPython else { return "Error: Local Python is turned off in Settings." }
        guard let data = call.arguments?.data(using: .utf8), let arguments = try? JSONDecoder().decode(Arguments.self, from: data),
              !arguments.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Error: Invalid arguments for run_python."
        }
        logActivity("🐍 Python: waiting for your approval")
        guard await requestPythonRun(arguments.code) else {
            logActivity("🐍 Python: not run")
            return "The user chose not to run this code."
        }
        logActivity("🐍 Python: running on this device")
        let result = await LocalPythonRunner.shared.run(arguments.code)
        logActivity(result.timedOut ? "🐍 Python: stopped at the time limit" : result.error == nil ? "🐍 Python: finished" : "🐍 Python: raised an error")
        return result.toolOutput
    }

    /// Shows the code and suspends until the user runs or declines it. A newer request declines an older one.
    func requestPythonRun(_ code: String) async -> Bool {
        resolvePythonRun(approved: false)
        return await withCheckedContinuation { continuation in
            pythonRunDecision = continuation
            pendingPythonRun = PythonRunRequest(code: code)
        }
    }

    /// Called by the approval sheet, by dismissing it, and when the turn is cancelled.
    func resolvePythonRun(approved: Bool) {
        let decision = pythonRunDecision
        pythonRunDecision = nil
        pendingPythonRun = nil
        decision?.resume(returning: approved)
    }
}
