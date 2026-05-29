# OpenResponses

SwiftUI-powered AI assistant and developer playground for the OpenAI Responses API. Featuring local-first architecture, sandboxed Python code execution, browser automation, and secure Keychain storage, OpenResponses delivers deep API observability with production-grade safety rails.

[![iOS CI](https://github.com/Gunnarguy/OpenResponses/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/Gunnarguy/OpenResponses/actions/workflows/ios-ci.yml)
[![Release Checks](https://github.com/Gunnarguy/OpenResponses/actions/workflows/release-check.yml/badge.svg)](https://github.com/Gunnarguy/OpenResponses/actions/workflows/release-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Last updated: 2026-05-29

---

## Table of Contents
- [Overview](#overview)
- [End-to-End User Journey](#end-to-end-user-journey)
- [System Architecture](#system-architecture)
- [Workflow Pipelines](#workflow-pipelines)
- [Configuration Catalog](#configuration-catalog)
- [Developer Onboarding](#developer-onboarding)
- [Documentation Index](#documentation-index)
- [License](#license)

---

## Overview

OpenResponses is a native iOS and macOS (Catalyst) client that interfaces directly with the OpenAI Responses API. It serves developers, prompt engineers, and technical creators as a mobile playground. Key characteristics include:
* **Direct Network Boundary:** OpenResponses establishes direct HTTPS connections to OpenAI. It does not run intermediary proxy servers.
* **Keychain Security:** API keys, Notion tokens, and MCP credentials reside strictly within the secure iOS Keychain.
* **Observe-in-Real-Time:** Displays token counts, activity indicators, expandable reasoning traces, and raw JSON payload structures for every query.

---

## End-to-End User Journey

```mermaid
flowchart TD
    subgraph Launch["1. Onboarding & Credentials"]
        Start([App Launched]) --> OnboardingCheck{Onboarding Complete?}
        OnboardingCheck -->|No| OB[Onboarding Pages] --> AddKey[Key Submission]
        OnboardingCheck -->|Yes| Main[Main View]
        AddKey --> Validate{Key Valid?}
        Validate -->|No| AddKey
        Validate -->|Yes| SaveKey[Store in iOS Keychain] --> Main
    end

    subgraph PromptSetup["2. Model & Settings Setup"]
        Main --> ModelPick[Select OpenAI Model]
        ModelPick --> ParamSet[Configure Temperature, Tools, and Metadata]
        ParamSet --> UserPrompt[Enter Chat Prompt]
    end

    subgraph Execution["3. Network & Tool Pipeline"]
        UserPrompt --> ConsentCheck{First-send Consent Granted?}
        ConsentCheck -->|No| Notice[AI Data Sharing Notice] --> Consent{User Agrees?}
        Consent -->|No| UserPrompt
        Consent -->|Yes| Send[Transmit Payload]
        ConsentCheck -->|Yes| Send
        Send --> SSE[Parse Server-Sent Events]
        SSE --> ToolCheck{Tool Call Triggered?}
        ToolCheck -->|Web Search| RunWeb[Query Web Search API] --> Send
        ToolCheck -->|Code Interpreter| RunCode[Execute sandboxed Python] --> Send
        ToolCheck -->|Computer Use| ConfirmComputer{Approve step in UI?}
        ConfirmComputer -->|No| Cancel[Cancel Chain] --> UserPrompt
        ConfirmComputer -->|Yes| RunComp[Transmit action to local network bridge] --> Send
        ToolCheck -->|No| FinalStream[Stream response.output_text.delta]
    end

    subgraph Completion["4. Output Display"]
        FinalStream --> Display[Render Answer with Citations & Thinking Traces]
    end

    style Start fill:#4CAF50,color:#fff
    style Display fill:#2196F3,color:#fff
    style Cancel fill:#f44336,color:#fff
```

---

## System Architecture

The application follows the **MVVM-S (Model-View-ViewModel-Service)** pattern to isolate UI components from connection logic:

```mermaid
flowchart LR
    subgraph Views["Views (SwiftUI)"]
        CV[ChatView]
        SH[SettingsHomeView]
        OV[OnboardingView]
    end

    subgraph ViewModels["ViewModels"]
        CVM[ChatViewModel]
    end

    subgraph Services["Services Layer"]
        OAS[OpenAIService]
        CS[ComputerService]
        KCS[KeychainService]
        CSS[ConversationStorageService]
        FCS[FileConverterService]
        NS[NotionService]
    end

    subgraph External["External Services"]
        Keychain[(Secure Keychain)]
        LocalFiles[(Local JSON files)]
        OpenAIAPI[(OpenAI API)]
        NotionAPI[(Notion API)]
        LocalBridge[(Local network bridge)]
    end

    CV <--->|binds / observes| CVM
    SH <--->|binds / observes| CVM
    OV --->|initializes keys| CVM

    CVM <--->|requests / streams| OAS
    CVM <--->|automations| CS
    CVM <--->|read / write| CSS
    CVM -.->|OAuth state| NS

    OAS -.->|load key| KCS
    NS -.->|load Notion token| KCS
    OAS <--->|HTTP / SSE| OpenAIAPI
    NS <--->|HTTP REST| NotionAPI
    KCS <--->|SecItem| Keychain
    CSS <--->|Serialization| LocalFiles
    CS <--->|HTTP REST| LocalBridge
```

---

## Workflow Pipelines

### Browser Automation / Computer Use Loop
```mermaid
flowchart TD
    Start[Agent requests computer action] --> Parse[Extract action parameters mouse/keyboard]
    Parse --> DisplaySheet[Surface Safety Approval Dialog]
    DisplaySheet --> Approval{User Approves?}
    Approval -->|No| Terminate[Cancel tool chain and return failure event]
    Approval -->|Yes| CaptureMouse[Move cursor position x, y]
    CaptureMouse --> Exec[Run action: click/type/scroll]
    Exec --> Screenshot[Capture WKWebView viewport screenshot]
    Screenshot --> Transmit[Send screenshot and result to Responses API]
    Transmit --> Next[Await model's next action decision]

    style Start fill:#4CAF50,color:#fff
    style Terminate fill:#f44336,color:#fff
```

### Model Context Protocol (MCP) Discovery & Execution
```mermaid
flowchart TD
    Launch[Select index / namespace with MCP enabled] --> Probe[Send health probe request to MCP Server]
    Probe --> Status{Server Online?}
    Status -->|No| Offline[Mark connector offline & log failure]
    Status -->|Yes| Discover[Get available tools list via JSON payload]
    Discover --> AllowList[Filter tools against Allowed Tools config]
    AllowList --> Register[Register tools in Responses API request configuration]
    Register --> Stream[Stream Chat completions]
    Stream --> Invoke{Model requests MCP run?}
    Invoke -->|No| Output[Finalize chat answer]
    Invoke -->|Yes| ApproveCheck{mcpRequireApproval == 'always'?/Tool sensitive?}
    ApproveCheck -->|Yes| UserConfirm{User approves Tool run?}
    UserConfirm -->|No| Refuse[Send tool error delta to stream] --> Stream
    UserConfirm -->|Yes| Call[POST request to mcpServerURL/tools/call] --> Stream
    ApproveCheck -->|No| Call

    style Launch fill:#4CAF50,color:#fff
    style Offline fill:#f44336,color:#fff
```

---

## Configuration Catalog

The configuration parameters are defined inside the `Prompt` model. They map to `UserDefaults` keys (persisted as JSON structures or preferences) or the secure iOS Keychain.

### 1. API Credentials & Auth
| Config Name | Storage Location | Default Value | Purpose |
| :--- | :--- | :--- | :--- |
| **OpenAI API Key** | Keychain (`openAIKey`) | None | Authenticates all OpenAI requests. |
| **Notion Token** | Keychain (`notionApiKey`) | None | Authenticates Notion integration queries. |
| **MCP Manual Headers** | Keychain (`mcp_manual_[label]`) | None | Custom headers payload (JSON) for custom MCP. |

### 2. Model & Execution Parameters
| Config Name | Storage Location | Default Value | Bounds / Ranges |
| :--- | :--- | :--- | :--- |
| **OpenAI Model** | `activePrompt` | `gpt-5.4` | List of allowed chat models. |
| **Reasoning Effort** | `activePrompt` | `medium` | `none`, `low`, `medium`, `high`, `max`. |
| **Temperature** | `activePrompt` | `1.0` | `0.0` to `2.0` (disabled for reasoning models). |
| **Top P** | `activePrompt` | `1.0` | `0.0` to `1.0` (nucleus sampling). |
| **Stream Responses** | `activePrompt` | `true` | Boolean. Enable Server-Sent Events (SSE). |
| **Store Responses** | `activePrompt` | `true` | Boolean. Keep history records on OpenAI servers. |
| **Prompt Cache Key** | `activePrompt` | `""` | String. Reuse cached context. |
| **Safety Identifier** | `activePrompt` | `""` | String. Abuse detection hashed tag. |
| **Tool Choice** | `activePrompt` | `auto` | `auto`, `required`, `none`. |
| **Parallel Tool Calls** | `activePrompt` | `true` | Boolean. Allow concurrent tool execution. |
| **Background Mode** | `activePrompt` | `false` | Boolean. Allows processing behind active UI. |
| **Max Tool Calls** | `activePrompt` | `0` (Disabled) | `1` to `32` (stepper constraint). |
| **Truncation Strategy** | `activePrompt` | `auto` | `auto` (automatic sliding window) or `disabled`. |

### 3. Enabled API Tools
| Config Name | Storage Location | Default Value | Description |
| :--- | :--- | :--- | :--- |
| **Web Search** | `activePrompt` | `true` | Toggle OpenAI search tool. |
| **Code Interpreter** | `activePrompt` | `true` | Toggle sandboxed Python container. |
| **Image Generation** | `activePrompt` | `true` | Toggle image production capabilities. |
| **File Search** | `activePrompt` | `false` | Toggle OpenAI vector stores search. |
| **Computer Use** | `activePrompt` | `false` | Toggle WKWebView automations. |
| **Notion Integration** | `activePrompt` | `true` | Toggle Notion tools payload registration. |
| **Apple Integrations** | `activePrompt` | `true` | Toggle Calendar, Reminders, and Contacts access. |

---

## Developer Onboarding

### Local Setup Walkthrough
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Gunnarguy/OpenResponses.git
   cd OpenResponses
   ```
2. **Open in Xcode:**
   Open `OpenResponses.xcodeproj` in Xcode 16.1 or newer.
3. **Environment Setup (Xcode Schemes):**
   * Edit Scheme (`Product > Scheme > Edit Scheme...`).
   * Under **Arguments**, configure environment variables for debug runs:
     * `OPENAI_API_KEY`: Developer testing token.
     * `NOTION_API_KEY`: Notion developer key.

### CLI Setup scripts (VS Code config)
Run the helper script to configure VS Code extensions, lint setups, and build targets:
```bash
bash scripts/setup-pi-mcp.sh
```

---

## Documentation Index

| File | Description |
| :--- | :--- |
| [README.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/README.md) | Central entry point and architecture walkthrough. |
| [ARCHITECTURE.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/ARCHITECTURE.md) | Deep dive into MVVM-S patterns and API endpoints mappings. |
| [ROADMAP.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/ROADMAP.md) | Phased project progression and OpenAssistant archive details. |
| [SECURITY.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/SECURITY.md) | Details Keychain partitions, scan utilities, and build guards. |
| [PRIVACY.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/PRIVACY.md) | Sandboxing bounds, data sharing notice, and opt-out tables. |
| [APP_STORE.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/APP_STORE.md) | Promotional copy listings and reviewer testing walkthrough. |
| [docs/CASE_STUDY.md](file:///Users/gunnarhostetler/Documents/GitHub/OpenResponses/docs/CASE_STUDY.md) | Case study of production milestones and issues solved. |

---

## License

OpenResponses is released under the [MIT License](LICENSE).
