# Apple System Integration Plan

## Scope & Goals

- Deliver on-device access to Apple Calendar, Reminders, and Notes so conversations can fetch and act on personal data once the user grants permission.
- Expose these capabilities through MCP-compliant tools so the OpenResponses assistant can reason about them safely and trigger downstream automations (e.g., pushing reminders into Notion).
- Preserve user privacy by adhering to Apple entitlement policies, explicit consent flows, and revocation controls.

## Prerequisites

- [ ] Confirm Apple Developer Program enrollment for required entitlements.
- [ ] Review latest App Intents and Model Context Protocol documentation (WWDC25 sessions, developer.apple.com/modelcontextprotocol).
- [ ] Audit current `AppContainer` services to ensure dependency injection can host Apple-specific services.

## Workstream 1 · API Capability Inventory

- [ ] Catalogue available App Intents for Notes, Reminders, and Calendar (EventKit wrappers, Notes intents beta set).
- [ ] Document gaps (e.g., missing full Notes read API) and define mitigation strategies (Shortcuts hand-off, local mirroring).
- [ ] Decide minimum OS requirement and feature gating (iOS 18+, macOS 15+ anticipated).

## Workstream 2 · EventKit Service Layer

- [x] Create `EventKitPermissionManager` to request and cache permissions for events/reminders.
- [x] Implement `CalendarRepository` (read upcoming events, create/update/delete) with unit coverage, keeping public entry points under 120 LOC.
- [x] Implement `ReminderRepository` using `EKReminder` with fetch filters (date range, lists) and mutation APIs.
- [x] Model shared DTOs (e.g., `CalendarItemSummary`) for downstream serialization, documented in `Core/Models`.

## Workstream 3 · App Intents & MCP Tool Contracts

- [x] Define `FetchCalendarItemsIntent`, `FetchRemindersIntent`, `CreateReminderIntent`, and mark destructive actions `@RequiresConfirmation`.
- [x] Publish MCP tool metadata in `ToolProviders/AppleToolsProvider.swift`, ensuring each tool declares capability strings, required permissions, and structured output schemas.
- [x] Extend `APICapabilities.swift` to describe new MCP tool options for model negotiation.
- [ ] Add regression tests covering rejected invocations when permissions are missing.

## Workstream 4 · Apple Notes Strategy

- [ ] Validate currently shipped Notes App Intents (create, append, list in folders) and prototype wrapper service.
- [ ] Offer graceful degradation path when system lacks the intents (display fallback guidance in-chat).
- [ ] Evaluate feasibility of local note indexing for richer queries without private APIs; document decision in `CASE_STUDY.md`.

## Workstream 5 · Notion Sync Automation

- [ ] Design Notion Ideas database payload schema (properties, relation fields, tags) and write TypeScript/Swift mapping tests.
- [ ] Extend existing Notion connector to accept Apple item payloads and handle idempotency (dedupe via reminder identifier + timestamp).
- [ ] Provide user-configurable routing rules (e.g., default Notion database, status mapping) persisted in Keychain or secure storage.

## Workstream 6 · UX, Permissions, and Safety

- [x] Add onboarding surface explaining why Apple data access is requested and how to revoke it.
- [x] Update `ChatViewModel+Streaming` status chips to reflect Apple tool calls ("Fetching Reminders", "Syncing to Notion").
- [x] Surface granular settings toggles (calendar read/write, reminders read/write, notes read/write) with live permission status.
- [ ] Implement audit log for tool usage stored locally so users can review accesses.

## Workstream 7 · Testing & Documentation

- [ ] Author UI tests covering permission prompts and denial flows (XCUITest harness targeting iOS simulator).
- [ ] Update `docs/ROADMAP.md` Phase 3 entries once capabilities ship; cross-reference `docs/api/Full_API_Reference.md`.
- [ ] Refresh `CASE_STUDY.md` and `PRODUCTION_CHECKLIST.md` with new architecture/testing steps.
- [ ] Produce user-facing guide (`docs/Files.md` or new doc) detailing how to connect Apple data and Notion automations.

## Reference Materials

- Model Context Protocol docs: <https://developer.apple.com/documentation/modelcontextprotocol>
- EventKit framework docs: <https://developer.apple.com/documentation/eventkit>
- App Intents session videos (WWDC24/25): check Apple Developer app for latest deep dives.
- Notes App Intents overview: search "Apple Notes App Intents" in 2025 documentation (beta availability varies by OS).
