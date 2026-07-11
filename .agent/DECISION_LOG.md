# Decision Log

This document records the final dispositions and architectural decisions made for each PR.

| PR # | Title | Disposition | Rationale / Integration Notes |
|---|---|---|---|
| 53 | Remove dead commented code for calculator tool | Consolidated | Deleted dead commented-out code to maintain a clean codebase. |
| 54 | Remove deprecated detectToolsUsed function | Consolidated | Removed unused legacy `detectToolsUsed` to reduce technical debt. |
| 55 | Optimize AppleDataModels by caching ISO8601DateFormatter | Consolidated | Replaced mutable data races with thread-safe `AppleDateUtilities` ISO8601 value-styled formatting and parsing. |
| 56 | Add unit tests for URLDetector.extractImageLinks | Consolidated | Integrated via `URLDetectorTests.swift` verifying extracting, filtering, and parsing web URLs. |
| 57 | Restrict WebContentView URL schemes to HTTP/HTTPS | Consolidated | Enforced HTTP/HTTPS scheme restrictions and handled `target="_blank"` new window delegations securely in `WebContentView.swift`. |
| 58 | Replace print with AppLogger in OpenAIService | Consolidated | Unified standard logging and gated verbose API bodies behind `#if DEBUG`. |
| 59 | Optimize key window lookup to avoid intermediate allocations | Consolidated | Refactored `ComputerService.swift` to prioritize foreground active scenes when fetching the key window. |
| 60 | Optimize DateFormatter initialization in FileConverterService | Consolidated | Replaced mutable `sharedISO8601Formatter` with pure, thread-safe value formatting and static utilities. |
| 61 | Add test coverage for ImageProcessingUtils.createPlaceholderImage | Consolidated | Integrated via `ImageProcessingUtilsTests.swift` validating placeholder size and color constraints. |
| 62 | Cache DateFormatter in FineTuningView to improve performance | Consolidated | Refactored to use Swift's modern thread-safe `Date.FormatStyle` value formatting. |
| 63 | Testing Improvement: Add tests for ImageProcessingUtils.optimizeImageForDisplay | Consolidated | Integrated via `ImageProcessingUtilsTests.swift` confirming downscaling constraints are respected. |
| 64 | Add test for UIImage memoryFootprint | Consolidated | Integrated via `UIImageExtensionsTests.swift` confirming core layout and byte allocation checks. |
| 65 | Fix insecure storage of mcpHeaders in UserDefaults | Consolidated | Re-keyed Keychain secrets by stable `Prompt.id.uuidString` and added self-healing legacy label/plaintext migrations. |
| 66 | Fix OAuth CSRF vulnerability in Google Providers | Consolidated | Implemented PKCE challenge, state-matching, duplicate query checking, and once-only continuation resumption. |
| 67 | Add comprehensive tests for Optional+StringHelpers | Consolidated | Integrated via `OptionalStringHelpersTests.swift` checking bounds binding and fallback properties. |
| 68 | Cache ISO8601DateFormatter initialization for AppleDataModels | Consolidated | Addressed under thread-safety consolidation (`AppleDateUtilities`). |
| 69 | Redact sensitive query parameters from logged URLs | Consolidated | Centralized query parameter scrubbing (`[REDACTED_SECRET]`) in `AppLogger.swift`. |
| 70 | Optimize DateFormatter initialization in BatchJobsView | Consolidated | Refactored to use Swift's modern thread-safe `Date.FormatStyle` value formatting. |
| 71 | Reset streaming state on computer_call_output network failure | Consolidated | Integrated via `currentStreamGeneration` tracking and immediate state cleanup. |
| 72 | properly reset streaming task on network failure | Consolidated | Integrated via unified `resetStreamingState` cancelling ongoing tasks immediately. |
| 73 | Reset streaming state completely on computer tool error | Consolidated | Integrated via `cleanupComputerUseState` immediately cleaning up wait counts and active streams. |
| 74 | Fix streaming state reset on computer tool error | Consolidated | Integrated via unified helper eliminating the 2-second sleep task. |
| 75 | Fix: Complete streaming state reset on error | Consolidated | Integrated via unified helper wrapping all MainActor callbacks. |
| 76 | Fix streaming state reset logic on computer_call_output errors | Consolidated | Integrated via centralized cleanups on all computer call network/logical failures. |
