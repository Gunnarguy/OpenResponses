# OpenResponses 3.0 release notes

In development. Version 3.0 was created in App Store Connect on October 19, 2026, and nothing is submitted yet. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt). The details and their tests are in [CHANGELOG.md](../CHANGELOG.md) under 3.0.

## Tool steps

| What 2.9 showed | Cause | 3.0 |
| --- | --- | --- |
| A function call's step stayed empty until the call had come in | `response.function_call_arguments.delta` and `.done` fell to `default` in `handleStreamChunk`, so a row got its arguments only from `response.output_item.done` (Responses API streaming events reference, read October 19, 2026) | Each delta appends to the row's `rawArguments`, and `.done` fills a row that got no delta. Neither changes the row's status, and calls still run from `output_item.done` |
| Nothing, for a custom tool call's input events | `response.custom_tool_call_input.delta` and `.done` also fell to `default` | Recognized. A custom tool call has no row yet, so nothing shows for it |

Function calls in the chat are the app's own tools: the browser (`browserNavigate` and the other browser actions), Calendar, Reminders, Contacts, Notion, Local Python (`run_python`) and the Custom tool from Settings. Tapping a step shows its arguments under "Arguments:" (`ToolTimelineView`).

## Calendar and Reminders dates

| What 2.9 did | Cause | 3.0 |
| --- | --- | --- |
| A time with no offset ("2026-11-04T18:30:00") failed: "The provided date is not a valid ISO 8601 timestamp". On October 21, 2026, all twelve Calendar and Reminders calls for a photographed schedule failed this way | `AppleDateUtilities.parseISO8601` (`Date.ISO8601FormatStyle`) needs an offset or `Z`; ISO 8601 does not | `parseToolDate` reads it in the device's time zone; a value with an offset or `Z` means that moment, with or without seconds |
| A bare date ("2026-11-04") failed the same way | The same | As a reminder's due date, a due day with no time; as a query's end, the whole day; as an event's start or end, refused with "Calendar events need a time of day", since the app makes timed events only |

The tool schemas already ask for the device's offset "preferably", so the model's requests don't change. `parseISO8601` stays strict for the file converter's date-column check.

## Decisions

OpenAI's Decisions API (`POST /v1/decisions`) is generally available: it returns typed answers instead of text, and runs only on `gpt-6-luna` at $0.10 per million input tokens with output not charged (Decisions guide and API reference, read November 13, 2026).

| Where | What it does |
| --- | --- |
| Settings → Advanced → Developer Operations → Decisions (`DecisionsView`) | Text input and an optional photo (sent as a JPEG data URL, at most 1,536 pixels on its longest side). Up to 400 questions: yes or no (`predicate`, a probability), choice (2 to 255 unique values, a probability each) and score (2 to 10 ordered levels; the score is a probability-weighted average of the level numbers). Answers show as bars with their confidence; a refusal and an unknown answer type are shown, not dropped. The footer shows input tokens, cached tokens and the cost. Three examples and Copy Request JSON are in the ⋯ menu. Questions are saved on the device (UserDefaults `decisionsQuestions.v1`); the input and photo are not. The same data-sharing consent as the Workbench, and offline in Demo Mode. |
| API Workbench → Create decision | `POST /decisions` with the support-ticket example. |
| `scripts/decisions_probe.sh [Keychain service]` | One live call with the same example; the key goes from the Keychain to curl on stdin. |

Request building, validation and answer decoding are in `DecisionsModels.swift` (`DecisionsRequest.problem` names what OpenAI would reject before the request is sent). The Agents API (`/v1/agents/sessions`, beta) was considered and not added: the app already does multi-agent turns, programmatic tool calling, the hosted shell and MCP through the Responses API, and the Agents API has no Zero Data Retention.

## Verification

`ToolRowsTextAndFilesTests` and `StreamingEventDecodingTests` on simulator "OpenResponses tests" 96574C1C (created October 19, 2026): 23 executed, 0 failures, including the new `testFunctionCallArgumentsStreamIntoTheirRow` and `testArgumentsDoneFillsAnEmptyRowAndCustomInputHasNoRow`. The full suite CI runs has not been run on this change yet. Code: commit `8836c39`.

Calendar and Reminders dates (October 21, 2026, uncommitted when run): `AppleDateUtilitiesTests` and `DateFormattingTests` on simulator "OpenResponses tests" D4947B13 (iPhone 18 Pro, iOS 27.0, created that day; Reminders access granted with `simctl privacy` for the EventKit test): 26 executed, 0 failures. The full suite CI runs (`-only-testing:OpenResponsesTests -skip-testing:OpenResponsesTests/BrowserLiveSiteTests`) on the same simulator: 360 executed, 2 skipped (the live docs-page test without its variable, and a search-by-meaning test that needs Apple's on-device model), 0 failures. Two read-only review passes; the first found a skipped midnight, bare event dates, untested call sites, non-ASCII digits and a release-notes claim, all fixed; the second found only low-severity items, also fixed.

Decisions (November 13, 2026, uncommitted when run): `DecisionsTests` (9, at the end of `OpenAIServiceTests.swift`, one of them draws the answer cards with `ImageRenderer`) and the full unit suite (`-only-testing:OpenResponsesTests`) on simulator "OpenResponses tests" 2460D513 (iPhone 18 Pro, iOS 27.0): 370 executed, 3 skipped, 0 failures. In that simulator's Explore Demo the screen opens from Settings → Advanced → Developer Operations, Ask shows the Demo Mode message, and the question editor lists the example's choices. Not yet sent to the live API.
