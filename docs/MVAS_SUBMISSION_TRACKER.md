# Minimal Viable App-Store Submission Tracker

**Last updated:** 2025-11-11 (evening)

## Mission

Deliver a TestFlight-ready build and App Store Connect submission for OpenResponses with the smallest viable scope while maintaining privacy, compliance, and reviewer clarity.

## Status Snapshot

- ✅ App codebase builds and runs on simulator (baseline assumption to verify).
- ⬜ Build archive validated in Xcode Organizer.
- ⬜ TestFlight build uploaded and visible to internal testers.
- ⬜ App Review package (metadata + dossier) submitted.

## Workstream Checklist

- [x] **Secrets hygiene** – run automated scan, confirm release build requires user-supplied keys only.
- [x] **Info.plist privacy strings** – add minimal NS*UsageDescription values needed for shipped capabilities.
- [x] **Privacy documentation** – update `PRIVACY.md`, create `AppReviewNotes.md`, ensure links wired in metadata.
- [x] **App Store metadata** – confirm description, keywords, support URL, privacy policy URL, review notes template.
- [x] **Visual assets** – verify 1024×1024 icon in `Assets.xcassets`; screenshot storyboard ready in `docs/ScreenshotGuide.md`.
- [ ] **Build & upload** – archive Release build, validate, and upload to App Store Connect.
- [ ] **Internal TestFlight smoke** – invite testers, verify onboarding, chat, and computer-use gating.
- [ ] **Submit for review** – fill App Privacy questionnaire, attach review notes, submit version 1.0.0.

## Key Risks & Mitigations

- **Privacy strings missing:** Blocked by checklist above; run `scripts/preflight_check.sh` before archiving.
- **Secret leakage:** Run `scripts/secret_scan.py`; fail build if any token-like string is detected.
- **Reviewer confusion about Computer Use/MCP:** Provide clear scripted flow in `AppReviewNotes.md` and optional screen recording link.
- **Unexpected crash in Release build:** Smoke test on latest simulator after archiving; rerun if fixes applied.

## Artifacts To Produce

| Artifact | Location | Owner | Status |
| --- | --- | --- | --- |
| `scripts/secret_scan.py` | `scripts/` | Release eng | Complete |
| `scripts/preflight_check.sh` | `scripts/` | Release eng | Complete |
| `PRIVACY.md` refresh | repository root | Release eng | Complete |
| `AppReviewNotes.md` | `docs/` | Release eng | Complete |
| `docs/AppStoreMetadata.md` | `docs/` | Release eng + Product copy | Complete |
| `docs/ScreenshotGuide.md` | `docs/` | Design/dev | Complete |
| App icon 1024×1024 | `OpenResponses/Resources/Assets/Assets.xcassets/AppIcon.appiconset/` | Design/dev | Complete |
| Screenshot captures | `AppStoreAssets/` | Design/dev | Not started |

## Decision Log

- 2025-11-11: Adopt Minimal Viable App-Store Submission (MVAS) scope; full CI/CD automation deferred.
- 2025-11-11: Added `scripts/secret_scan.py` and verified repo passes automated secret scan.
- 2025-11-11: Shortened Info.plist privacy copy, removed unused location permission, and added `scripts/preflight_check.sh`.
- 2025-11-11: Refreshed `PRIVACY.md` and published `docs/AppReviewNotes.md` for App Review handoff.
- 2025-11-11: Captured detailed MVAS execution plan covering metadata, assets, archive/upload, and submission steps.
- 2025-11-11 (evening): Verified completed workstreams: secrets hygiene ✅, Info.plist strings ✅, privacy docs ✅, metadata prep ✅, app icon ✅, screenshot guide ✅.
- 2025-11-12: Added in-app AI accuracy warnings plus pre-permission disclosures for Calendar, Reminders, Contacts, and computer-use local network prompts.

## Next Update

Add outcomes after each workstream completes (checkbox status + Decision Log entry).

## Outstanding Workstreams Detail

### App Store metadata

- [x] Cross-check `docs/AppStoreMetadata.md` against the current app feature set; trim or update copy where scope narrowed for MVAS.
- [ ] Populate App Store Connect fields (description, keywords, support URL, privacy policy URL) using the vetted text in `docs/AppStoreMetadata.md` and `PRIVACY.md`.
- [ ] Stage review notes template from `docs/AppReviewNotes.md` in App Store Connect → App Review Information.

### Visual assets

- [x] Align screenshot storyboard with `docs/ScreenshotGuide.md`; confirm the eight required frames cover chat streaming, settings, tools, and dark mode.
- [ ] Capture 6.9" iPhone simulator shots via `xcrun simctl io booted screenshot` and drop assets into `AppStoreAssets/` with final filenames.
- [x] Re-verify the 1024×1024 app icon in `OpenResponses/Resources/Assets/Assets.xcassets/AppIcon.appiconset/Contents.json` matches current branding specs.

### Build & upload

- [ ] Run `scripts/secret_scan.py` and `scripts/preflight_check.sh` prior to any archive to catch regressions introduced since the last pass.
- [ ] Clean, build, and archive the Release configuration in Xcode 16.1+; validate the archive via Organizer before uploading.
- [ ] Upload the validated archive to App Store Connect (Transporter or Organizer) and confirm processing kicks off.

### Internal TestFlight smoke

- [ ] Once the build appears in App Store Connect, add internal testers and install on-device to confirm onboarding, chat flow, and computer-use gating.
- [ ] Record any regressions in `TONIGHT_CHECKLIST.md` and remediate prior to external submission.

### Submit for review

- [ ] Complete the App Privacy questionnaire with the zero-data collection answers already documented in `docs/PRODUCTION_CHECKLIST.md`.
- [ ] Attach review notes, privacy links, and required contact info; double-check that uploaded screenshots and metadata are marked Ready for Review.
- [ ] Submit version 1.0.0 for App Review once TestFlight smoke tests pass.

## Workstream Owners & Dependencies

| Workstream | Primary Owner | Dependencies | Target Window |
| --- | --- | --- | --- |
| App Store metadata | Release eng + Product copy | Final feature scope locked, docs/AppStoreMetadata.md current | Before archive |
| Visual assets | Design/dev | Simulator build stable, storyboard approved | Before metadata submission |
| Build & upload | Release eng | Secrets/preflight scripts green, signing assets current | Immediately after metadata ready |
| Internal TestFlight smoke | Release eng + QA | Build processed in App Store Connect | Same day as upload |
| Submit for review | Release eng | Metadata + screenshots + privacy answers + passing smoke test | Within 24h of successful TestFlight |

## Monitoring & Reporting

- Track progress nightly in this document; update the Decision Log with each completed workstream.
- Mirror status in `docs/PRODUCTION_CHECKLIST.md` once archive validation, metadata, and screenshots reach done.
- Flag blockers (build failures, asset issues, App Store Connect validations) immediately in the team channel; capture mitigations here for continuity.

## Execution Timeline (Draft)

| Day & Time (local) | Milestone | Owner | Notes |
| --- | --- | --- | --- |
| Nov 11 – 20:00 | Finalize metadata copy and review notes | Release eng + Product copy | Leverage `docs/AppStoreMetadata.md`; confirm privacy links resolve. |
| Nov 11 – 21:00 | Prepare simulator scenes for screenshots | Design/dev | Follow `docs/ScreenshotGuide.md`; lock UI state before capture. |
| Nov 11 – 22:00 | Capture & export 6.9" screenshots | Design/dev | Save into `AppStoreAssets/` with final filenames, verify crop margins. |
| Nov 11 – 22:30 | Run preflight scripts (`secret_scan`, `preflight_check`) | Release eng | Capture console output for release notes. |
| Nov 11 – 23:00 | Archive Release build + validate | Release eng | Organizer validation must be green before upload. |
| Nov 11 – 23:30 | Upload to App Store Connect | Release eng | Monitor processing status; expect ~30 minutes. |
| Nov 12 – 00:15 | Internal TestFlight smoke | Release eng + QA | Use `TONIGHT_CHECKLIST.md` and log results inline. |
| Nov 12 – 01:00 | Submit metadata + build for review | Release eng | Ensure privacy questionnaire + review notes attached. |

## Cross-References & Daily Ritual

- Each evening, reconcile this tracker with `TONIGHT_CHECKLIST.md`; mark any completed checks in both places to maintain a single source of truth.
- When a workstream reaches ✅, add a Decision Log entry with outcome, owner, and any lingering follow-ups.
- Before lights out, confirm App Store Connect status (Processing, Ready to Test, Waiting for Review) and log it here alongside the date.
