# Minimal Viable App-Store Submission Tracker

**Last updated:** 2025-11-11

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
- [ ] **App Store metadata** – confirm description, keywords, support URL, privacy policy URL, review notes template.
- [ ] **Visual assets** – capture four iPhone screenshots, verify 1024×1024 icon in `Assets.xcassets`.
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
| `AppReviewNotes.md` | project root or `docs/` | Release eng | Complete |
| Screenshot set (4 PNGs) | `AppStoreAssets/` | Design/dev | Not started |

## Decision Log

- 2025-11-11: Adopt Minimal Viable App-Store Submission (MVAS) scope; full CI/CD automation deferred.
- 2025-11-11: Added `scripts/secret_scan.py` and verified repo passes automated secret scan.
- 2025-11-11: Shortened Info.plist privacy copy, removed unused location permission, and added `scripts/preflight_check.sh`.
- 2025-11-11: Refreshed `PRIVACY.md` and published `docs/AppReviewNotes.md` for App Review handoff.

## Next Update

Add outcomes after each workstream completes (checkbox status + Decision Log entry).
