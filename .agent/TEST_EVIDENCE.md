# Test Evidence

This document registers all native test executions, build statuses, and diagnostic logs.

## Build and Test Suite Executions

### Execution 1: Baseline Check
* **Command**: `xcodebuild test -scheme OpenResponses -destination "id=3935B03E-320F-42E5-8A32-6528B819B94A"`
* **Result**: SUCCESS
* **Duration**: 188.277 seconds
* **Warnings**: None that block compilation or testing.
* **Errors/Failures**: None. Executed 139 unit tests and 10 UI tests, 0 failures.

### Execution 2: Consolidated Integration Verification
* **Command**: `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "id=3935B03E-320F-42E5-8A32-6528B819B94A"`
* **Result**: SUCCESS
* **Duration**: 96.789 seconds
* **Warnings**: Isolated Swift 6 conformed Sendable/Actor warnings, non-blocking.
* **Errors/Failures**: None. Executed 162 unit tests and 10 UI tests (172 total), 0 failures. All new tests (for URL detection, WebView HTTP restrictions, memory footprint, optional string helpers, secure MCP keychain persistence, and OAuth callback validations) compiled and passed successfully.
