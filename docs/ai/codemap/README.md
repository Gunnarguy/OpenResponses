# Codemap: feature index and knowledge graph

A fresh agent session should find a named feature, its purpose and the files to open without
re-reading the repository. The map has two levels:

1. [INDEX.md](INDEX.md): one row per feature, with the words a user might say, one sentence of
   purpose, the slice to open and the file to start at. It is small enough to read every time.
2. `features/<id>.json`: one slice per feature, read only when that feature is the task. A slice
   lists the feature's files, its nodes (views, view models, services, state, storage,
   integrations, configuration, tests) and typed edges between them, each with evidence.

[DRIFT.md](DRIFT.md) lists places where a document and the code disagree.
[UNMAPPED.md](UNMAPPED.md) lists source files no feature claims, with what was checked about each.
All three Markdown files are generated from the slices by `python3 scripts/codemap.py index`.

## Using it on a feature task

1. Read `INDEX.md`, or run `python3 scripts/codemap.py find <words>`.
2. Open only the matching slice.
3. Confirm the cited lines in the live code before trusting them. `python3 scripts/codemap.py check <id>`
   reports any citation that no longer matches, and `affected` lists slices whose files changed
   since they were stamped.
4. Edit. Then update the slice (below) in the same change.

`python3 scripts/codemap.py owner <path>` names the feature that owns a file, and
`python3 scripts/codemap.py refs <Symbol>` lists live declarations and mentions of a symbol,
which is the fallback when a slice is silent.

## Evidence and status

Every node and edge carries a status:

| Status | Meaning |
|---|---|
| VERIFIED | Someone opened the cited file, read the code at the cited line, and it shows this relationship. |
| INFERRED | Based on naming, a comment, a document, or a reference that was not read in context. |
| UNKNOWN | Expected but not found. The edge points to `?` and the note says what was looked for. |

Evidence is `{"path", "line", "match"}`. `match` is text copied from one line of that file,
compared without regard to whitespace; `line` is a hint that `stamp` keeps current. The checker
re-finds every `match`, so a renamed function or deleted call shows up as a broken citation rather
than a silently wrong map. Static reading misses relationships made at run time (protocol dispatch,
notifications, SwiftUI environment injection); those are recorded as INFERRED or UNKNOWN rather than
asserted.

## Slice schema (`codemap/1`)

```json
{
  "schema": "codemap/1",
  "id": "voice",
  "name": "Voice mode",
  "aliases": ["realtime", "live", "gpt-live-1"],
  "purpose": "One sentence: what the feature does for the user and where it runs.",
  "revision": "bd8027e",
  "verified_on": "2026-09-28",
  "entry_points": ["InlineVoiceView"],
  "files": [{"path": "OpenResponses/Core/Services/RealtimeService.swift", "role": "primary", "blob": "<set by stamp>"}],
  "nodes": [{"id": "RealtimeService", "kind": "service", "path": "...", "line": 12, "match": "final class RealtimeService", "status": "VERIFIED", "note": "..."}],
  "edges": [{"from": "InlineVoiceView", "type": "calls", "to": "RealtimeService", "status": "VERIFIED",
             "evidence": [{"path": "...", "line": 88, "match": "realtimeService.connect("}], "note": "..."}],
  "docs": [{"path": "ARCHITECTURE.md", "section": "Browser, voice and files", "quote": "text copied from one line",
            "claim": "what the document says", "status": "CONFIRMED", "evidence": {"path": "...", "line": 1, "match": "..."}, "note": "..."}],
  "unknowns": ["what could not be established"],
  "related": ["chat-turn"]
}
```

- `role`: `primary` (the feature owns the file), `shared` (a file several features use, such as
  `ChatViewModel.swift`), `test`.
- Node `kind`: `view`, `view_model`, `service`, `model`, `function`, `state`, `persistence`,
  `integration`, `config`, `test`, `util`, `intent`, `resource`, `entry`. Large shared files get
  `function` nodes for the functions that implement this feature, so an agent can jump to them.
- Node ids are short and unique within the slice, usually the Swift symbol (`ChatViewModel.sendMessage`).
  State and storage use a prefix: `defaults:<key>`, `keychain:<service>`, `file:<name>`,
  `openai:<endpoint>`. An edge can point at another feature as `feature:<id>`, or at a node in
  another slice as `<feature-id>#<node-id>`.
- Edge `type`: `renders`, `calls`, `reads`, `writes`, `configures`, `depends_on`, `tested_by`.
- Doc `status`: `CONFIRMED`, `CONTRADICTED` (the code does something else), `STALE` (describes an
  earlier state: old paths, versions, removed features), `UNVERIFIED` (not checkable from code, such
  as live API behavior). Contradicted and stale claims are listed in DRIFT.md; the documents are not
  rewritten to hide them.
- A slice with `"index": false` holds repository-wide claims and stays out of the index.

## Keeping it current

After changing code:

```bash
python3 scripts/codemap.py affected        # stale slices, and new files no slice claims
python3 scripts/codemap.py refresh [ID...] # derive, stamp and index; no ids means every stale slice
```

A slice is stale when a file it lists differs from the blob hash `stamp` recorded, or when one of
its citations no longer matches. Commits alone do not make a slice stale. For each stale slice:
re-read the changed code, fix, rename or remove what it invalidated, add what is new, then
`refresh <id>`; its `stamp` step refuses while any citation is broken. A slice whose content is still
right only needs the refresh. A new source file either joins a slice's `files` or gets a note under
`unmapped_notes` in `config.json`.

### Automatic upkeep

Nobody has to remember the commands above; these hooks name the stale slices when it matters.

| When | What runs | Effect |
|---|---|---|
| After each Edit or Write in Claude Code | `.claude/fast-check`, called by the Context OS post-edit hook in `~/.claude/hooks/` | Silent unless the edit removed a cited line or left a slice invalid; then Claude is told which slice and what to run. |
| End of each Claude Code turn | Stop hook in `.claude/settings.json` | Once per state, lists the slices the session made stale (commits since the session's baseline plus uncommitted changes) and new unclaimed files, as feedback Claude acts on before finishing. |
| End of each Codex turn | Stop hook in `.codex/hooks.json` | The same list, as a continuation prompt. Codex runs a project hook only after `/hooks` trusts it. |
| `git commit` | `.githooks/pre-commit` | Prints the stale slices and never blocks. Enabled per clone with `git config core.hooksPath .githooks`. |

All four call `python3 scripts/codemap.py hook <event>`. None of them edits or stamps a slice: a stamp
claims someone re-read the code, so it stays with the agent that did.

`check` exits 1 on errors (broken citation, missing path, schema fault), so it can gate CI.
Warnings (changed files, unmapped files) and notes (moved lines, commits since stamping) do not fail it.

The tool is `scripts/codemap.py`, standard-library Python with no dependencies. The method is packaged
for other repositories as the `codemap` skill in `~/.claude/skills/codemap/`.
