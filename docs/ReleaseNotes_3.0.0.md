# OpenResponses 3.0 release notes

In development. Version 3.0 was created in App Store Connect on October 19, 2026, and nothing is submitted yet. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt). The details and their tests are in [CHANGELOG.md](../CHANGELOG.md) under 3.0.

## Tool steps

| What 2.9 showed | Cause | 3.0 |
| --- | --- | --- |
| A function call's step stayed empty until the call had come in | `response.function_call_arguments.delta` and `.done` fell to `default` in `handleStreamChunk`, so a row got its arguments only from `response.output_item.done` (Responses API streaming events reference, read October 19, 2026) | Each delta appends to the row's `rawArguments`, and `.done` fills a row that got no delta. Neither changes the row's status, and calls still run from `output_item.done` |
| Nothing, for a custom tool call's input events | `response.custom_tool_call_input.delta` and `.done` also fell to `default` | Recognized. A custom tool call has no row yet, so nothing shows for it |

Function calls in the chat are the app's own tools: the browser (`browserNavigate` and the other browser actions), Calendar, Reminders, Contacts, Notion, Local Python (`run_python`) and the Custom tool from Settings. Tapping a step shows its arguments under "Arguments:" (`ToolTimelineView`).

## Verification

`ToolRowsTextAndFilesTests` and `StreamingEventDecodingTests` on simulator "OpenResponses tests" 96574C1C (created October 19, 2026): 23 executed, 0 failures, including the new `testFunctionCallArgumentsStreamIntoTheirRow` and `testArgumentsDoneFillsAnEmptyRowAndCustomInputHasNoRow`. The full suite CI runs has not been run on this change yet. Code: commit `8836c39`.
