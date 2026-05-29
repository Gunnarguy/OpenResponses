# OpenResponses AI Agent Coding Instructions

## 1. Project Identity

OpenResponses is a native iOS and macOS (Catalyst) AI assistant client and developer playground designed to interface directly with the OpenAI Responses API (`/v1/responses`). Written in Swift and SwiftUI, the application implements a local-first, low-latency execution pipeline with zero intermediate server proxies. It features direct integration with OpenAI system tools (Web Search, Code Interpreter, Computer Use), custom Model Context Protocol (MCP) server discovery, Notion workspace integration, and native Apple device permissions (Calendar, Reminders, Contacts). It secures all user-provided API credentials inside the secure iOS Keychain.

---

## 2. Prime Directives

- **Direct Connections Only:** All external operations must go directly from the client to destination endpoints (e.g. `api.openai.com` or Notion workspace) over secure HTTPS. Do not introduce proxy servers.
- **Keychain Enclave Safety:** All user secrets, API keys, and access tokens must reside strictly in the iOS Keychain. Never write secrets to standard `UserDefaults` or plaintext log outputs.
- **Strict Verification:** **Do not invent files, APIs, or completed features.** If a model capability, setting parameter, or script is not present in the current codebase, mark it as "Needs verification" or state the gap explicitly.
- **Observability Focus:** Maintain granular, real-time telemetry rendering (such as active token counters, activity feeds, request inspector JSONs, and expandable reasoning logs).

---

## 3. Architecture Rules

The application uses the **MVVM-S (Model-View-ViewModel-Service)** pattern backed by the `AppContainer` dependency injection singleton:
- **Views (SwiftUI):** Must remain pure, declarative layouts that observe properties published by ViewModels and propagate tap or text-entry actions. Views must contain zero storage, network, or business logic.
- **ViewModels:** Maintain active conversation states, parameters, and coordination logic. To prevent large file sizes, split ViewModels using extensions (e.g., `ChatViewModel+Streaming.swift`). Schedule all UI modifications to the `@MainActor`.
- **Services:** Stateless logic blocks performing network requests, SSE stream decoding, local file conversions, or Keychain interactions. Views must never query services directly; access services through ViewModels.
- **Storage:** Persist conversation details and prompts to sandboxed local JSON files via the `ConversationStorageService` (local-first).

---

## 4. Key Files by Concern

- **App Bootstrapping:**
  - [OpenResponsesApp.swift](OpenResponses/App/OpenResponsesApp.swift) — App entry point & startup migrations.
  - [AppContainer.swift](OpenResponses/App/AppContainer.swift) — Service locator and dependency injection container.
- **Main Interface:**
  - [ContentView.swift](OpenResponses/App/ContentView.swift) — Main tab navigation layout.
  - [ChatView.swift](OpenResponses/Features/Chat/ChatView.swift) — Chat stream message bubbles, activity monitors, and prompt entry.
- **ViewModels:**
  - [ChatViewModel.swift](OpenResponses/Features/Chat/ChatViewModel.swift) — Coordinates state, tool approvals, and configurations.
- **Services:**
  - [OpenAIService.swift](OpenResponses/Core/Services/OpenAIService.swift) — Payload builder, streaming events emitter.
  - [ComputerService.swift](OpenResponses/Core/Services/ComputerService.swift) — Local browser WKWebView automation loop.
  - [KeychainService.swift](OpenResponses/Core/Services/KeychainService.swift) — Keychain helper.
  - [ConversationStorageService.swift](OpenResponses/Core/Services/ConversationStorageService.swift) — Local JSON persistence.
  - [FileConverterService.swift](OpenResponses/Core/Services/FileConverterService.swift) — Conversions for 43 document/image types.
  - [NotionService.swift](OpenResponses/Core/Services/NotionService.swift) — Notion integrations API client.
- **Tool Mappings:**
  - [NotionProvider.swift](OpenResponses/Core/ToolProviders/NotionProvider.swift) — Notation tool registry.
  - [AppleProvider.swift](OpenResponses/Core/ToolProviders/AppleProvider.swift) — Native Calendar / Contacts / Reminders tool schemas.

---

## 5. Build and Test Commands

- **Build Target:** Xcode 16.1+ / Scheme `OpenResponses`.
- **Secret Scan Command:**
  ```bash
  python3 scripts/secret_scan.py
  ```
- **Preflight Check Command:**
  ```bash
  bash scripts/preflight_check.sh
  ```
- **Unit Test Command:**
  ```bash
  xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```

---

## 6. Logging Conventions

- **No Raw Print Statements:** Do not use `print()` or `NSLog()` in production files.
- **Structured Tracing:** Use `AppLogger` categories (`AppLogger.trace()`, `AppLogger.debug()`) to write logs. This logs events into the developer panel view.
- **Log Sanitation:** Ensure that raw tokens, passwords, and private API keys are never captured in debug logs.

---

## 7. Security Rules

- **UserDefaults Exclusion:** Never use `@AppStorage` or standard `UserDefaults` to save secrets. Use them only for user configurations, UI states, and feature flags.
- **WKWebView Sandboxing:** When running local browser automation via `ComputerService`, verify that cookies, frames, and scripting boundaries are isolated to the specific target domain. Enforce step-by-step UI confirmation before any automation action is dispatched.
- **Secret Scans:** Run `python3 scripts/secret_scan.py` prior to committing files to prevent the leak of credentials.

---

## 8. Documentation Update Rules

- **Synchronize Docs on Architecture Changes:** When modifying API requests, tool integrations, or storage layers, you must update:
  - [README.md](README.md) (Configuration and flow tables)
  - [ARCHITECTURE.md](ARCHITECTURE.md) (System layer maps)
  - [ROADMAP.md](ROADMAP.md) (Status of feature implementations)
  - [PRIVACY.md](PRIVACY.md) & [SECURITY.md](SECURITY.md) (If data boundaries change)
- **Repository-Relative Links only:** All markdown documents must use repository-relative links. Never use absolute local file system paths (such as `file:///Users/username/...`).
