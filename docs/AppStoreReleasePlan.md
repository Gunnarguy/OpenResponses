# App Store Release Plan

Last updated: 2025-11-08

This document tracks the remaining work needed to ship OpenResponses to the App Store. It mirrors the active todo list and should be updated whenever a task moves forward.

## Target

- **Release window:** Q4 2025 (ASAP once checklist is green)
- **Proposed versioning:** Marketing version `1.0.0`, build number `1`

## Readiness Checklist

| ID | Area | Status | Summary | Notes / Owners |
| -- | ---- | ------ | ------- | --------------- |
| 1 | Versioning | � In progress | Marketing version set to `1.0.0`; build number `1` confirmed | Next: Release scheme/TestFlight seed review |
| 2 | Privacy strings | ✅ Complete | Info.plist keys for Calendars, Contacts, Files, Local Network, Location (optional), Photos, Reminders verified in build settings | Confirmed in `project.pbxproj` (GENERATE_INFOPLIST_FILE build settings) |
| 3 | Sensitive logging | ✅ Complete | Disabled detailed network logging outside DEBUG; forced sanitized OpenAI logs in release | `AnalyticsService` & `AppLogger` updated 2025-11-08 |
| 4 | Secrets audit | ✅ Complete | Repository scanned; no hardcoded keys found; `.gitignore` updated; environment setup documented | See `docs/EnvironmentSetup.md` |
| 5 | Icons & launch | 🟡 In progress | AppIcon 1024×1024 PNG verified; launch screen generated via SwiftUI; needs device preview pass | Review on physical device before TestFlight |
| 6 | Store metadata | � In progress | Privacy policy, release notes, and comprehensive metadata prepared | See `docs/AppStoreMetadata.md` for complete submission content |
| 7 | Capabilities | 🟡 In progress | Code signing: Automatic; Team: Z3E334EXZD; Bundle ID: `Gunndamental.OpenResponses`; no custom entitlements | Verify provisioning before TestFlight upload |
| 8 | Accessibility & l10n | 🟡 Planned | VoiceOver, Dynamic Type, localization coverage sweep | Pair with UI polish session |
| 9 | Third-party notices | ✅ Complete | AboutView created with MIT License; added to Advanced tab | No external dependencies found |
| 10 | Tests & CI | 🔴 Not started | Add smoke tests, configure CI + TestFlight automation | Consider Fastlane workflow |
| 11 | Security/data handling | 🟡 Planned | Document data flows, analytics opt-in, update privacy policy | Align with Apple guidelines section 5 |
| 12 | Documentation | 🟡 In progress | Keep `PRODUCTION_CHECKLIST.md`, roadmap, API reference synchronized; prep release notes | Create release notes draft + doc sync |

_Status legend:_ `✅ Complete`, `🟡 Planned/In progress`, `🔴 Not started`

## Recent Updates

- **2025-11-08:** AboutView created with MIT License display; added to Advanced tab in Settings (Task 9).
- **2025-11-08:** App Store Connect metadata document created with descriptions, keywords, URLs, screenshots specs, and review notes (Task 6).
- **2025-11-08:** Secrets audit completed; no hardcoded keys in source; `.gitignore` expanded; `docs/EnvironmentSetup.md` created.
- **2025-11-08:** Marketing version bumped to `1.0.0` and Release build configuration reviewed for build `1`.
- **2025-11-08:** Network logging now DEBUG-only; OpenAI request/response bodies always sanitized in release builds.
- **2025-11-08:** Verified Info.plist privacy descriptions via `INFOPLIST_KEY_*` settings (calendars, contacts, documents, file system, local network, location, photos, reminders).

## Next Actions

1. Audit Release/TestFlight scheme and queue build `1` for TestFlight (Task 1 follow-up).
2. Validate AppIcon asset catalog coverage and launch screen UX (Task 5).
3. Prepare App Store creative assets and metadata (Task 6) while planning the accessibility sweep (Task 8).

Keep this file updated whenever a task status or note changes.
