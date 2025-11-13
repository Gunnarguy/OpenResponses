# Production Checklist

This checklist keeps release candidates honest. Run it before tagging a build or shipping a TestFlight so we catch regression-prone areas early. All steps assume the current OpenAI key is valid and rate limits are healthy.

## 1. Environment & Configuration

- [ ] Launch the app on both iOS (simulator or device) and macOS Catalyst to ensure platform parity.
- [ ] Verify the OpenAI API key is stored in Keychain (`Settings → General`). Toggle the key off/on to confirm persistence.
- [ ] Load at least one saved prompt preset from the Prompt Library and confirm reasoning defaults, tool toggles, and truncation strategy survive reload.

## 2. Core Chat Flow

- [ ] Send a plain text prompt with streaming enabled; confirm typing cursor, token counters, and activity feed behave normally.
- [ ] Disable streaming and send another prompt; confirm the response arrives as a single message with the correct final status.
- [ ] Trigger a reasoning-capable model (e.g., `gpt-5`) and verify the **Assistant Thinking** panel appears with trace summaries.
- [ ] Switch to a non-reasoning model and confirm the panel hides while previous reasoning traces remain accessible in older messages.

## 3. Tooling

### 3.1 Computer Use

- [ ] Enable the `computer` tool with the `computer-use-preview` model.
- [ ] Issue a navigation request ("Open [openai.com](https://openai.com)") and confirm:
  - [ ] Navigate-first helper avoids blank screenshots.
  - [ ] Screenshots attach to the assistant message and render in chat.
  - [ ] Status chips show "Controlling computer session" and clear after completion.
- [ ] Approve a safety request and observe the approval sheet flow; ensure denial also clears pending state and logs a system message.

### 3.2 Code Interpreter

- [ ] Enable the code interpreter and upload a small CSV; request a summary to confirm artifacts render with download options.
- [ ] Trigger a long-running script to ensure progress indicators and artifact handling remain responsive.

### 3.3 Web Search & File Search

- [ ] Run a web search-enabled prompt; confirm activity feed updates ("Researching web sources") and results cite source URLs.
- [ ] Enable file search with two vector store IDs (dummy values are fine) and confirm validation messages appear. Disable the toggle afterwards to revert.

### 3.4 MCP Connectors

- [ ] Open the MCP connector gallery, install a sample connector (e.g., Calculator), and run a tool call.
- [ ] For remote MCP, ensure the health probe runs before streaming (status message "Running MCP tool diagnostics").

## 4. Attachments & Media

- [ ] Attach two local files (pdf + txt) and verify they appear in the Selected Files tray with appropriate icons.
- [ ] Send an image attachment and ensure image detail level selector persists.
- [ ] Run an image generation request (`gpt-image-1`) and confirm progress heartbeats, preview updates, and final render.

## 5. Conversation Management

- [ ] Create three conversations, switch between them, and confirm local persistence (quit and relaunch the app, verifying state).
- [ ] Export a conversation via the advanced settings panel and re-import it to confirm structure integrity.
- [ ] Delete a conversation and ensure the next conversation becomes active without crashing.

## 6. Error Handling & Offline Behaviour

- [ ] Toggle airplane mode or disable network; attempt to send a prompt and confirm the app surfaces a friendly offline message without crashing.
- [ ] Simulate a rate limit error (set `max_output_tokens` excessively high or reuse a known rate-limited key) and confirm retry guidance appears.
- [ ] Observe that analytics/logging continue recording errors without leaking secrets (check Debug Console or configured logging sink).

## 7. Accessibility & UI Polish

- [ ] Run through the main chat and settings views with VoiceOver enabled to ensure controls have meaningful labels.
- [ ] Adjust Dynamic Type settings and confirm the chat list, settings tables, and activity feed respect font scaling.
- [ ] Test keyboard navigation on macOS (tab through controls, send message with ⌘+Return, focus in/out of input field).

## 8. Documentation & Versioning

- [ ] Update `docs/CASE_STUDY.md`, `docs/ROADMAP.md`, and `docs/api/Full_API_Reference.md` with any new coverage changes.
- [ ] Review `README.md` for feature parity and clean copy.
- [ ] Ensure release notes capture notable fixes (computer-use regressions, reasoning panel improvements, etc.).

Sign off only when every box is checked for the target platform(s). Remember to capture manual test notes in the release PR for future reference.
