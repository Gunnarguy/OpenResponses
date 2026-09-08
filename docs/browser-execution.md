# Browser execution

> Part of the [complete v2.6 release dossier](releases/v2.6/README.md). Test counts below describe this milestone; the final implementation total is **265**, recorded in the [validation ledger](releases/v2.6/Validation.md). [Live ASC status](releases/v2.6/ASCStatus.md) is tracked separately.


The app has two distinct browsing paths. OpenAI hosts `web_search`, including citations, source URLs, domain filters, search context size, and approximate location. `ComputerService` runs a persistent WKWebView on the iPhone for actual page navigation and interaction. It attaches outside the visible window and uses the app's WebKit website store; it is not a remote browser or a Safari session.

## Execution contract

DOM functions and screenshot computer actions share one FIFO execution lane. Every WebKit callback owns its continuation; navigation callbacks also match the specific `WKNavigation`. Late completions cannot resume a later operation, and an old cancellation cannot stop a newer tracked navigation. The last 2,048 attempted tool-call IDs are remembered in memory across turns, including uncertain failures, to prevent duplicate delivery from replaying an action. Legacy screenshot/three-action halts have been removed in favor of the shared budget.

- A navigation has a 20-second deadline, a script/snapshot callback 6 seconds, an entire operation 45 seconds, and queue admission 120 seconds.
- A user turn permits at most 80 actions and 20 distinct main-frame URLs. Redirect destinations count; fragment changes do not. These counters reset for a new user message.
- Stop, conversation changes, disabling computer use, and pending safety checks cancel active/queued work. Results and approvals are bound to the initiating chat turn.
- A WebKit process termination interrupts active work and recreates the browser on the next operation. It does not replay an interrupted click or submission.
- Main-frame navigation and redirects require HTTP/HTTPS without embedded credentials. Ordinary new-window links open in the same browser. Non-displayable downloads return an explicit error. HTTP status is included in page state.
- A failed screenshot is an error, never a diagnostic image masquerading as a page. PNG dimensions are exactly 440×956 pixels, matching the computer tool's coordinate system regardless of device display scale.

Cancellation cannot undo an action the website already received. After an uncertain result, the tool instructions require reading the page before considering a retry.

## DOM tools

`browserNavigate`, `browserRead`, `browserSearch`, `browserClick`, `browserType`, `browserScroll`, and `browserHistory` return structured page state. History accepts `back`, `forward`, or `reload`.

Each snapshot contains a snapshot ID and element refs. The ref map lives in an isolated WebKit content world. A ref expires after another snapshot, a URL change, element removal, or a relevant target change (including destination/form action). Page scripts cannot forge that map from their own JavaScript world.

Use a current ref for clicking or typing. Text targeting must resolve to a unique visible control. Missing, ambiguous, disabled, and obscured controls fail explicitly. Coordinate actions use actual viewport points; they do not guess nearby menu or cookie-consent controls. Single clicks dispatch one activation. Typing uses native input setters plus input/change events, preserves supplied whitespace, permits clearing a field, and verifies the immediate entered value. Submission is requested once and honors HTML form validation.

Page readiness waits for a usable, briefly stable DOM and awaits two actual animation frames. Pages that do not settle return a timeout. No synthetic desktop event mechanism can guarantee a website accepted a business operation; returned page state is the evidence to inspect.

## Approval and search settings

API-provided computer safety checks pause both screenshot and DOM execution. Approval is scoped to the originating turn; denying or dismissing the sheet cancels the chain. This is not a separate local classifier for every potentially consequential website operation. The assistant must still follow the user's authorization and treat webpage instructions as untrusted.

The legacy hosted-search `profile` parameter is rejected by the live API (`tools[0].profile`, HTTP 400). Search Style now contributes instruction text instead. Preferred Page Limit and Preferred Crawl Depth are labeled as guidance because the hosted search tool exposes no hard page/depth controls. The independent on-device browser limits above are enforced in code.

## Verification on September 7, 2026

The final app-hosted test run passed all 238 tests, including the public-site smoke test. The signed physical-device build also succeeded and was installed and launched on Gunnar’s Hand Extension (iPhone 16 Pro Max). The app process was confirmed running. Three existing conversation files were present after installation, with unchanged metadata across launch.

- Deterministic callback/lane tests cover cancellation, late/double callbacks, queue ordering, deadlines, approval gating, generation invalidation, and budgets.
- Native WebKit fixtures cover actual screenshots, pixel dimensions, single-fire DOM/coordinate clicks, controlled-input native setters, whitespace and sanitization, one form submission, stale/forged refs, changed link destinations, obscured/disabled targets, invalid waits/actions, and process recovery without replay.
- Public-site smoke test loads example.com and IANA, captures real pages, and verifies back/forward history.
- Live hosted `web_search` with allowed/blocked domains completed with a citation and 19 source URLs. No API key is embedded in the simulator or test fixtures.

Run the deterministic suite with `xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination '<simulator destination>' -only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests -parallel-testing-enabled NO -collect-test-diagnostics never`. Run `BrowserLiveSiteTests` explicitly for the public network smoke test, with a 60-second per-test allowance.

Coverage is top-document DOM plus the existing visual action path. Cross-origin frames, closed shadow roots, trusted-event-only controls, native file pickers/dialogs, and CAPTCHA/login flows are not claimed as universally automated. This pass does not constitute new end-to-end validation of unrelated file search, Apple/Notion writes, Batch, or fine-tuning features.
