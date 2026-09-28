# OpenResponses: instructions for coding agents

Feature tasks: read `docs/ai/codemap/INDEX.md` first, open only the matching
`docs/ai/codemap/features/<id>.json`, confirm its cited lines in the live code, then edit.
After changing code, update the slices it made stale (`python3 scripts/codemap.py affected` lists them),
then run `python3 scripts/codemap.py refresh`. Hooks in `.claude/`, `.codex/` and `.githooks/` name
stale slices automatically. The method is in `docs/ai/codemap/README.md`.

Current state, blockers and the exact next action: `docs/ai/STATE.md`.
