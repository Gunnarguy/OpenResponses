# OpenResponses

SwiftUI-powered AI assistant for the OpenAI Responses API featuring computer use, code interpreter, file search, image generation, and MCP integrations—all wrapped in a production-ready iOS experience with deep observability and safety rails.

[![iOS CI](https://github.com/Gunnarguy/OpenResponses/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/Gunnarguy/OpenResponses/actions/workflows/ios-ci.yml)
[![Release Checks](https://github.com/Gunnarguy/OpenResponses/actions/workflows/release-check.yml/badge.svg)](https://github.com/Gunnarguy/OpenResponses/actions/workflows/release-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Status — November 2025:** Phase 1 is complete. OpenResponses ships with local conversation storage, full Responses tool support, and the Minimal Viable App-Store Submission (MVAS) checklist. Phase 2 focuses on Conversations API migration and cross-device sync.

---

## Table of Contents

- [Overview](#overview)
- [Core Features](#core-features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Initial Configuration](#initial-configuration)
- [Toolbox at a Glance](#toolbox-at-a-glance)
- [Privacy, Safety, and Compliance](#privacy-safety-and-compliance)
- [Testing & Quality Gates](#testing--quality-gates)
- [Release Workflow](#release-workflow)
- [Documentation Hub](#documentation-hub)
- [Roadmap Snapshot](#roadmap-snapshot)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Overview

OpenResponses is an end-to-end iOS, iPadOS, and macOS (Catalyst) client for the OpenAI Responses API. It targets developers and advanced users who need:

- Full coverage of the current tool surface (computer use, code interpreter, file/vector search, image generation, MCP connectors).
- Rich observability—streaming analytics, reasoning trace playback, and API inspectors that make debugging and demos effortless.
- Enterprise-ready safeguards—Keychain credential storage, explicit approval flows for automation, and a minimal privacy footprint.

The app follows a productized workflow: everything you need to test, ship, and submit to the App Store—including privacy docs, tracking scripts, and the MVAS tracker—is built into the repository.

---

## Core Features

- **Model Playground:** Live model catalogue with compatibility gating, preset management, and advanced request controls (streaming flags, prompt cache IDs, reasoning toggles).
- **Observability Surface:** Streaming activity feed, live token usage, “Assistant Thinking” trace viewer, analytics events, and structured logging for every tool event.
- **Tooling Portfolio:** Computer use with safety approvals, code interpreter with artifact viewer, multi-vector file search, direct file and image attachments, Notion/MCP connectors, custom function calls.
- **Knowledge Workflows:** Vector store management flows, file conversion pipeline, and document picker enhancements built on `FileConverterService`.
- **Native Shell:** SwiftUI UI with accessibility support, keyboard shortcuts, share sheets, prompt library, onboarding, and settings tuned for fast iteration.

---

## Architecture

OpenResponses follows MVVM with dependency injection through `AppContainer`.

- **Views:** SwiftUI views such as `ChatView`, `MessageBubbleView`, and modular settings/onboarding screens.
- **View Models:** `ChatViewModel` orchestrates conversations, state, and tool execution; extensions such as `ChatViewModel+Streaming` handle 40+ streaming event types.
- **Services:** `OpenAIService` wraps the Responses API, `ComputerService` automates the computer-use browser, `ConversationStorageService` persists local history, `KeychainService` stores secrets, and compatibility helpers gate tooling per model.
- **Data Models:** Rich types for streaming events, function calls, computer-use actions, artifacts, and reasoning traces keep decoding resilient and expressive.

> Dive deeper in `docs/CASE_STUDY.md` for component diagrams, request flows, and design decisions.

---

## Getting Started

### Prerequisites

- Xcode 16.1 (or newer)
- macOS Sonoma
- An OpenAI API key (sk-… project key)

### Clone & Open

```sh
git clone https://github.com/Gunnarguy/OpenResponses.git
cd OpenResponses
open OpenResponses.xcodeproj
```

### Build Targets

- **OpenResponses (iOS/iPadOS):** Run on simulator or device.
- **OpenResponses (macOS Catalyst):** Build/run via “My Mac (Designed for iPad)” scheme.

---

## Initial Configuration

1. Launch the app.
2. Complete onboarding (3 screens summarizing capabilities and key requirements).
3. When prompted, paste your OpenAI API key. It is stored in the iOS Keychain (`KeychainService`) and never checked into source control.
4. Use Settings → General to toggle streaming, published prompts, and prompt cache IDs.
5. Enable tools (code interpreter, computer use, file search, MCP) in Settings → Tools. Each capability enforces additional confirmation flows as required.

Secrets are intentionally absent from the repo. Run `python3 scripts/secret_scan.py` anytime to validate.

---

## Toolbox at a Glance

| Capability | Details |
| --- | --- |
| **Computer Use** | Navigate/click/scroll automation with safety approval sheets, blank-page recovery, screenshot attachments, and status updates. |
| **Code Interpreter** | Sandboxed Python execution with artifact viewer, status heartbeats, and result summarization. |
| **File Search & Vector Stores** | Upload files, manage vector stores, toggle file search per prompt, and configure rankers or thresholds. |
| **Image Generation** | Trigger image creation with optional detail level control and inline previews. |
| **MCP Connectors** | Register local/remote MCP servers, inspect tools, and gate usage through approval UI with Keychain-backed auth. |
| **Prompt Library** | Save and reuse prompt presets including reasoning/model settings and safety identifiers. |
| **Observability** | Activity feed, streaming status chips, token usage counters, API inspector, debug console, and analytics hooks. |

---

## Privacy, Safety, and Compliance

- **Credentials:** API keys and integration tokens live only in the Keychain. No secrets ship with the app or reside on disk.
- **Data Residency:** Conversations and attachments stay on device until you explicitly send them to OpenAI or an MCP tool.
- **Permissions:** The app currently requests Photos, Files, Calendars, Contacts, Reminders, and Local Network usage descriptions. Camera, microphone, speech recognition, and location are intentionally excluded in v1.0.0.
- **Computer Use Safeguards:** Every automation step requires review; declines cancel the chain immediately. Status updates ensure reviewers see what is happening at all times.
- **Docs:** See `PRIVACY.md` for the privacy summary and `docs/AppReviewNotes.md` for reviewer instructions.

---

## Testing & Quality Gates

- **Unit & Snapshot Tests:** Run inside Xcode (`⌘U`) or via `xcodebuild` on `OpenResponsesTests`, `StreamingEventDecodingTests`, and related targets.
- **Secret Scan:** `python3 scripts/secret_scan.py`
- **Preflight Check:** `bash scripts/preflight_check.sh` verifies Info.plist usage descriptions and reruns the secret scan.
- **Manual QA:** Follow `docs/PRODUCTION_CHECKLIST.md` for streaming, tooling, accessibility, and documentation checks.
- **API Coverage:** Update `docs/api/Full_API_Reference.md` when adding request fields, tool types, or event handling.

---

## Release Workflow

The Minimal Viable App-Store Submission (MVAS) plan captures everything needed to submit OpenResponses to TestFlight/App Store with ~6–12 hours of effort.

1. Track progress in `docs/MVAS_SUBMISSION_TRACKER.md` (checklist + decision log).
2. Ensure privacy copy is current (`PRIVACY.md`, App Store metadata, `docs/AppReviewNotes.md`).
3. Run `bash scripts/preflight_check.sh` to confirm secrets and Info.plist values are clean.
4. Archive in Xcode → Organizer → Validate/Upload.
5. Invite internal TestFlight testers for the sanity pass (onboarding, chat, computer use).
6. Submit to App Review with the dossier from `docs/AppReviewNotes.md`.

---

## Documentation Hub

- `docs/ROADMAP.md` — phased rollout plan with current status.
- `docs/CASE_STUDY.md` — architecture narrative including diagrams and streaming lifecycle.
- `docs/api/Full_API_Reference.md` — field-by-field implementation status for Responses.
- `docs/PRODUCTION_CHECKLIST.md` — manual QA and release verification steps.
- `docs/Advanced.md`, `docs/Tools.md`, `docs/Files.md`, `docs/Images.md` — feature-specific how-tos.
- `docs/AppReviewNotes.md` — one-pager for App Store reviewers.
- `Notion/` — MCP connector setup guides.

---

## Roadmap Snapshot

- **Phase 1 (Complete):** Multi-modal inputs, full Responses tool coverage, computer-use hardening, vector workflow, observability overhaul.
- **Phase 2 (In Progress):** Conversations API adoption, annotation rendering, cross-device sync, enhanced conversation metadata.
- **Beyond:** Apple Intelligence integration, richer UI polish, offline caching, and advanced prompt caching (see `docs/ROADMAP.md`).

---

## Contributing

We welcome pull requests aligned with the roadmap.

1. Fork the repo and branch from `main` or the active release branch.
2. Implement the change with tests where applicable.
3. Run unit tests and `bash scripts/preflight_check.sh`.
4. Update relevant docs (`docs/`, `PRIVACY.md`, `README.md`, etc.).
5. Submit a PR describing the change, test evidence, and any roadmap linkage.

Please open an issue before large architectural work so we can coordinate on Phase 2 priorities.

---

## Support

- Email: [support@gunnarguy.com](mailto:support@gunnarguy.com)
- Issues: <https://github.com/Gunnarguy/OpenResponses/issues>
- Discussions and roadmap queries: see `docs/ROADMAP.md` and `docs/MVAS_SUBMISSION_TRACKER.md`

---

## License

MIT — see [`LICENSE`](LICENSE).
