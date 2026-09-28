# Current State

Updated: 2026-09-28
Branch/worktree: main in the repo root. This handoff is written before two commits on top of bd8027e: (1) the codemap with its automatic upkeep, (2) the 2.8 bump; both are pushed to origin/main together, which starts an Xcode Cloud 2.8 archive.
Last verified commit: bd8027e

## Objective
Get 2.8 building: the push of the codemap and the `MARKETING_VERSION = 2.8` bump must produce a green Xcode Cloud archive that reaches App Store Connect. The codemap objective (feature index plus knowledge graph in docs/ai/codemap/, kept current by hooks) is complete with these commits; the Notion row "Feature index and relationship graph for fresh agent sessions" closes when they are on origin/main.

## Status
- Codemap: 24 slices (23 features plus `repository`), stamped at bd8027e, `check` clean; INDEX.md, DRIFT.md (14 rows), UNMAPPED.md (3 files, 79 unreachable types) generated. Fresh-session test in docs/ai/codemap/eval/RESULTS.md: 11 of 11 answers complete with the map against 10 of 11 without, but 29% more cumulative input; no token saving is claimed.
- Automatic upkeep (nobody runs the scripts by hand): `.claude/fast-check` after each Claude edit, a Stop hook in `.claude/settings.json` for Claude Code, a Stop hook in `.codex/hooks.json` for Codex, and `.githooks/pre-commit` (warns only; `core.hooksPath` is set to `.githooks` in this clone's .git/config). All call `python3 scripts/codemap.py hook <event>`; table in docs/ai/codemap/README.md "Automatic upkeep".
- 2.8: Gunnar created 2.8 in App Store Connect on 2026-09-28; both `MARKETING_VERSION` lines in project.pbxproj read 2.8.

## Completed (2026-09-28)
- Notion roadmap database: https://app.notion.com/p/3e949a74d54f81a89c34d9d9fc4e420e; IDs in `.claude/skills/notion-roadmap/SKILL.md` (gitignored).
- `scripts/codemap.py` 1.1.0, standard library, runs on Python 3.9 and 3.12: find, owner, refs, check, affected, derive, review, orphans, refresh, hook, stamp, index, unmapped, inventory. `affected` and `refresh` judge staleness by content (blob hash recorded by `stamp`, or a citation that no longer matches), so a commit alone never marks a slice stale.
- Pointer: root `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`), `.gitignore` allowlists both and ignores `__pycache__/`, one line atop `.github/copilot-instructions.md`.
- Skill `~/.claude/skills/codemap/` (outside the repo): SKILL.md, scripts/codemap.py (identical to the repo copy), scripts/measure_fresh.py, templates/ including the four hook files.

## Active Constraints
- Saved presets decode with synthesized Codable via try?; never add a non-optional Prompt property. New options go in ModernResponseOptions (tolerant decoder).
- Every push to main starts an Xcode Cloud archive; bump MARKETING_VERSION after each release. No attribution trailers. Wrap git in gtimeout 60. DerivedData outside iCloud.
- API facts come from OpenAI's Markdown reference (https://developers.openai.com/api/reference/llms.txt), with a fetch date. No OpenAI key on this Mac.
- Compare live ASC fields with the last committed copy before PATCHing (skip hand edits).
- Use the dedicated simulator "OpenResponses tests" (CC71613C-046E-4386-B24E-9512FD114884, iPhone 18 Pro, iOS 27.0); simulators are shared across sessions.
- Plans, decisions and traps live in the Notion roadmap (skill `notion-roadmap`); CHANGELOG.md stays the record of what shipped.
- Feature tasks start at `docs/ai/codemap/INDEX.md`. When the codemap Stop hook lists stale slices, update them and run `python3 scripts/codemap.py refresh <ids>`; its reminder is not a request to commit.
- 2026-09-28 (move to a decisions log when the repo has one): bulk delegated work runs on Antigravity `gemini-3.8-flash-high`; live `claude -p` tests run on a current model (`claude-sonnet-5-5`), not Haiku. Codex runs `.codex/hooks.json` only after Gunnar trusts it once with `/hooks` in Codex.

## Working Set
- `scripts/codemap.py`: the tool; the automation is the section after `# ---- automation`.
- `docs/ai/codemap/`: README.md (contract and the upkeep table), config.json, features/*.json, INDEX.md, DRIFT.md, UNMAPPED.md, eval/ (questions with ground truth, RESULTS.md).
- `.claude/settings.json`, `.claude/fast-check`, `.codex/hooks.json`, `.githooks/pre-commit`: the hooks.
- `AGENTS.md`, `CLAUDE.md`, `.gitignore`, `.github/copilot-instructions.md`: the pointer.
- `OpenResponses.xcodeproj/project.pbxproj`: MARKETING_VERSION 2.8 (its own commit).

## Verification
- `python3 scripts/codemap.py check` -> "codemap check at bd8027e: 24 slices, 0 errors, 0 warnings, 0 notes"; `affected` -> "no slice is affected" (both under /usr/bin/python3 3.9.6 as well).
- `xcodebuild -project OpenResponses.xcodeproj -scheme OpenResponses -showBuildSettings` -> "MARKETING_VERSION = 2.8".
- Hooks, in a scratch clone: a harmless edit -> fast-check silent, exit 0; an edit to a cited line -> exit 1 naming the voice slice, relayed by `~/.claude/hooks/post-edit-check.sh` as "Fast check FAILED"; Stop hook -> additionalContext naming voice, silent on the same state and when `stop_hook_active`; `--agent codex` -> `{"decision":"block","reason":...}`; a committed change is still found from the session baseline; a new unclaimed file is listed; pre-commit printed the warning and the commit went ahead; `refresh` with no ids re-stamped only voice; no map -> exit 0.
- Live Claude Code 2.1.284 runs in the clone (`--setting-sources project`): Haiku 4.5 and Sonnet 5.5 each answered DONE, were continued by the Stop hook, re-cited voice.json and ran `refresh voice`; `check` 0 errors afterwards; $0.18 and $0.20.
- `claude -p` and `codex exec` each quoted the AGENTS.md instruction from a clone (CLI 2.1.263, codex-cli 0.153.4).
- No app build or test run: no Swift source changed.

## Blockers / Unknowns
- The Codex Stop hook is verified with simulated input only, not in a live Codex session; Codex skips it until `/hooks` trusts it.
- Hooks keep citations true but do not rename graph nodes: both live runs kept the node id `defaults:realtime_barge_in` after renaming that key.
- The ground-truth answers in eval/questions.json must never be copied into a test clone.
- GPT-Live 1, voice-note transcription and the 2.7 Responses fields are verified against the reference and unit tests only (no key on this Mac).
- The Notion token in test.env was printed into a session log on 2026-09-24; Gunnar should rotate it.

## Exact Next Action
Open App Store Connect > Xcode Cloud for OpenResponses and read the run started by the push of the two commits after bd8027e. If it passes "Preparing build for App Store Connect", set the Notion roadmap row for the 2.8 bump (page 3e949a74-d54f-8179-bee1-d85eb85e5c62) to Completed with today's date. If it fails, read the failing step's log in that run before changing anything, and report it to Gunnar with the fix.
