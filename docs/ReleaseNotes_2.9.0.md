# OpenResponses 2.9 release notes

Submitted October 1, 2026, and released October 2 as build 54. The App Store What's New text is [release_notes.txt](../fastlane/metadata/en-US/release_notes.txt), and the promotional text is [promotional_text.txt](../fastlane/metadata/en-US/promotional_text.txt). Every change was found while filming the app's demo videos on 2.8; the details and their tests are in [CHANGELOG.md](../CHANGELOG.md) under 2.9.

## Tool steps

| What 2.8 showed | Cause | 2.9 |
| --- | --- | --- |
| Every step stayed on Queued | Rows closed only on `response.output_item.completed`, which the Responses API never sends; it ends items with `response.output_item.done` (openai-python's stream event types, read October 1, 2026) | `output_item.done` closes hosted tool rows; `in_progress`, `searching`, `interpreting` and `generating` events show Running |
| A failed browser step showed Completed | Only outputs starting `Error:` counted, and browser failures read `Error processing …` | An output that starts with "Error" fails the step (`ChatViewModel.functionOutputFailed`) |
| MCP steps went from Queued to Completed, and a tool error was lost | `response.mcp_call.in_progress` names no tool; `mcp_tool_execution_error` has `content`, no `message`, so the item didn't decode | in_progress shows Running; `MCPToolError` reads content, or a bare string |
| `code_interpreter_call` | Hosted tool items have no name | Rows read Code Interpreter, Web Search, File Search, Image Generation, and a Code Interpreter step shows its `code` |

## Text

- On the streaming path taken with Computer Use and with models older than GPT-5.6 or specialized ones, a new text item now starts a new paragraph (`paragraphBreak`, `lastTextItemIds`).
- The failure note that stands in for an answer clears when the answer starts. A tool loop completes a response every round, and each completion forgot the notes, so a round of only tool calls left the note above the answer.
- Reasoning summaries render inline Markdown (`InlineMarkdown`).

## Charts and files

- `appendArtifact` keeps one entry per file id, preferring a copy that loaded and a real file name over the bare id.
- Code Interpreter keeps a displayed plot as a file named by its own id. When the code also saved the figure, the reply cited one chart twice; a plot that matches a saved file from the same container (same shape, and under 3% of pixels differing strongly at 32 by 32) shows once, as the saved file.
- `ChatMessage.listedArtifacts` leaves a picture out of Generated Files while `images` holds that very picture, so a browser screenshot that replaces `images` brings a chart back to the list.
- Saved text and error artifacts keep their content when a conversation is reopened.

## Verification

Full unit suite (the set CI runs) on simulator "OpenResponses tests" 73D9ECD6: 343 executed, 0 failures, 3 skipped (the live docs-page test without its variable, and two search-by-meaning tests that need Apple's on-device model, which a new simulator doesn't have yet). Two reviewer passes over the diff; their findings are fixed and covered by tests.
