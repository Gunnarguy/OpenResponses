# OpenResponses AI Coding Conventions

This document guides AI agents in understanding and contributing to the OpenResponses codebase. It reflects the project's long-term vision as defined in **`ROADMAP.md`**.

## The Big Picture: A Phased Evolution

The app is undergoing a phased upgrade to achieve 100% compliance with the latest OpenAI and Apple capabilities. All contributions must align with the official **`ROADMAP.md`**.

### Current State vs. Future State

- **Current:** The app uses a partial implementation of the Responses API (`/v1/responses`) and manages conversation state locally using `previous_response_id`. Conversation history is stored on the device.
- **Future (The Goal):** The app will fully integrate the **Conversations API** (`/v1/conversations`) for backend-managed, cross-device conversation history. It will also support advanced input modalities (direct file uploads), tools (`computer`, `gpt-image-1`), and on-device Apple Intelligence. Audio input is out of scope.

Refer to the `ROADMAP.md` for the specific phase and priority of each feature.

## Architecture & Core Patterns

The application is built with **SwiftUI** and follows a **Model-View-ViewModel (MVVM)** architecture.

- **Dependency Injection:** A central singleton, `AppContainer` (`/OpenResponses/AppContainer.swift`), manages service dependencies. The primary service is the `OpenAIService`.
- **MVVM Structure:**
  - **Views (SwiftUI):** Located in `/OpenResponses/`. The primary UI is `ChatView.swift`. Views are lightweight and driven by the `ChatViewModel`.
  - **ViewModel (`ChatViewModel.swift`):** This is the brain of the application. It holds all UI state (`@Published` properties), manages the conversation flow, and orchestrates API calls. **Crucially, it is responsible for the transition from local state management to backend conversation sync.**
  - **Models:** Data structures like `ChatMessage.swift`, `Prompt.swift`, and `StreamingEvent.swift` represent the app's data. These models must be expanded to support all API features as outlined in the roadmap.

## Key Components & Conventions

- **API Communication (`OpenAIService.swift`):** This is the only class that communicates with the OpenAI API.

  - `buildRequestObject(...)` is a critical method that dynamically constructs the complex JSON payload for the `/v1/responses` endpoint. It must be updated to support all parameters and input types (files) from the roadmap.
  - It will be expanded to include methods for the `/v1/conversations` API (`createConversation`, `listConversations`, etc.).

- **Streaming Logic (`ChatViewModel.swift`):**

  - The method `handleStreamChunk(_:for:)` is the entry point for processing incoming `StreamingEvent` objects. This handler must be enhanced to support **all** event types defined in the API, not just text deltas.
  - The `updateStreamingStatus(for:item:)` method translates events into user-facing status messages. This is a key UX feature that must cover all tool calls and reasoning steps.

- **Secure Storage (`KeychainService.swift`):** The OpenAI API key is sensitive and **must** be stored in the Keychain. Use the singleton `KeychainService.swift` for all interactions with the Keychain.

## Documentation Ecosystem & Maintenance

This project maintains a comprehensive documentation ecosystem that **MUST** be kept consistent whenever code changes are made. Each document serves a specific purpose:

### Core Documents (Located in `/docs/`)

- **`ROADMAP.md`** - The strategic master plan. Defines all phases, features, and implementation priorities. This is the source of truth for what to build and when.
- **`CASE_STUDY.md`** - Technical deep-dive and architectural overview. Update when new features demonstrate architectural patterns or when the technical approach changes.
- **`PRODUCTION_CHECKLIST.md`** - Comprehensive pre-release validation checklist. Update when new features require testing or when new requirements emerge.
- **`FILE_MANAGEMENT.md`** - User guide for file and vector store features. Update when file handling capabilities change.
- **`APP_STORE_GUIDE.md`** - App Store submission guidance. Update when new features affect the app description or submission requirements.
- **`PRIVACY_POLICY.md`** - Legal document. Update when data handling practices change.
- **`docs/api/Full_API_Reference.md`** - Field-level API implementation status. Update when API coverage changes.

### Documentation Maintenance Rules

**When implementing any feature:**

1. **Check `ROADMAP.md` first** - Understand the feature's phase, priority, and requirements
2. **Update implementation status** - Mark features as complete in `ROADMAP.md` and `docs/api/Full_API_Reference.md`
3. **Update `CASE_STUDY.md`** - Add technical details for significant architectural changes
4. **Update `PRODUCTION_CHECKLIST.md`** - Add testing requirements for new features
5. **Update user guides** - Modify `FILE_MANAGEMENT.md` or other user-facing docs as needed

**When fixing bugs:**

- Update relevant checklists to prevent regression
- Update technical documentation if the fix reveals architectural insights

**When refactoring:**

- Update `CASE_STUDY.md` if architectural patterns change
- Ensure all documentation reflects the new code structure

## Developer Workflow

### Starting Work (New Conversation Protocol)

1. **Read `ROADMAP.md`** - Understand the current phase and priorities
2. **Check `docs/api/Full_API_Reference.md`** - Understand current API implementation status
3. **Review `CASE_STUDY.md`** - Understand the architectural patterns and design decisions
4. **Scan `PRODUCTION_CHECKLIST.md`** - Understand quality and testing standards

### Before Implementing Any Feature

1. **Consult `ROADMAP.md`** - Verify the feature's priority and phase
2. **Check existing implementation** - Review current code in the relevant files
3. **Plan documentation updates** - Identify which docs will need updates
4. **Consider API impact** - Will this change API coverage or capabilities?

### API Key Configuration

On first launch, the app checks for an API key in the Keychain. If none is found, it presents the `SettingsView.swift`.

### Example: Implementing a Feature from the Roadmap (e.g., Direct File Uploads)

**Code Changes:**

1. **Update the Model:** Add a new property to `Prompt.swift` to handle the new data (e.g., `fileData: Data?`)
2. **Modify `buildRequestObject`:** In `OpenAIService.swift`, add logic to construct the `input_file` object in the request body if the new property is present
3. **Update the UI:** Add UI elements to `FileManagerView.swift` to attach files
4. **Update the ViewModel:** Add logic to `ChatViewModel.swift` to manage file attachments and pass the file data to the API service
5. **Handle New Streaming Events:** If the feature introduces new events, update `updateStreamingStatus` in `ChatViewModel.swift` to provide user feedback

**Documentation Updates:**

1. **Mark complete in `ROADMAP.md`:** Update Phase 1 status for Direct File Uploads
2. **Update `docs/api/Full_API_Reference.md`:** Mark input_file parameters as implemented
3. **Update `CASE_STUDY.md`:** Add section on file handling architecture if significant
4. **Update `PRODUCTION_CHECKLIST.md`:** Add file upload testing requirements
5. **Update user documentation:** Add file input instructions to relevant user guides

## Critical Success Factors

1. **Always maintain documentation consistency** - Code changes without doc updates create technical debt
2. **Follow the roadmap phases** - Don't jump ahead to Phase 3 features when Phase 1 is incomplete
3. **Preserve architectural patterns** - The MVVM structure and dependency injection patterns are foundational
4. **Test comprehensively** - Use `PRODUCTION_CHECKLIST.md` to ensure quality standards
5. **Consider AI handoff** - Write code and documentation so the next AI conversation can pick up seamlessly
