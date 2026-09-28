# Codemap evaluation, 2026-09-28

Question: does a fresh Claude Code session find a feature's implementation with less context, fewer tool
calls, or more accurately when it has the codemap?

## Method

- Two clones of this repository at `bd8027e`, outside `~/Documents`: **control** (the commit as it was) and
  **codemap** (the same commit plus `AGENTS.md`, `CLAUDE.md` containing `@AGENTS.md`, `scripts/codemap.py`
  and `docs/ai/codemap/` without `eval/`). Nothing else differed; neither held session records.
- One fresh `claude -p` session per question per clone: Claude Code 2.1.263, model `claude-opus-5-5` (the
  default), read-only tools (Read, Grep, Glob and read-only Bash), `--max-turns 40`, stream-json output.
  Harness: `~/.claude/skills/codemap/scripts/measure_fresh.py`.
- The same prompt in both clones: the question plus "Find where this is implemented in this repository.
  Answer with the file paths and line numbers that implement it and a two-sentence explanation. Do not
  modify any files." The prompt does not mention the codemap; the codemap clone gets it only through
  `CLAUDE.md`.
- Questions and ground truth are in [questions.json](questions.json), settled from the code before any run.
  An answer scores an item when it names that file and a line within 8 of the cited one.

## Results

| Question | Arm | Tool calls | Peak context (tokens) | Cumulative input (tokens) | Output | Cost | Time | Ground truth named |
|---|---|---|---|---|---|---|---|---|
| Voice: Live or Realtime, and which URL | control | 4 | 56,837 | 215,712 | 1,728 | $0.52 | 19 s | 2 of 3 |
| | codemap | 5 | 66,657 | 299,930 | 1,701 | $0.43 | 20 s | 3 of 3 |
| Where conversations are saved, and when | control | 10 | 60,684 | 340,835 | 2,788 | $0.40 | 29 s | 4 of 4 |
| | codemap | 7 | 67,372 | 367,275 | 2,327 | $0.45 | 28 s | 4 of 4 |
| MCP token storage and refresh | control | 7 | 61,280 | 385,934 | 2,438 | $0.41 | 29 s | 4 of 4 |
| | codemap | 10 | 76,852 | 547,217 | 3,225 | $0.58 | 39 s | 4 of 4 |
| **Total** | control | 21 | | 942,481 | | $1.34 | | 10 of 11 |
| | codemap | 22 | | 1,214,422 | | $1.47 | | 11 of 11 |

Peak context is the largest single turn's input (fresh, cache-read and cache-write tokens). Cumulative input
adds every turn, most of it cache reads of the same context.

## What the sessions did

- **Codemap arm, every question:** searched `INDEX.md`, read one slice (`voice.json`, `conversations.json`,
  `mcp-connections.json`), then opened the cited primary file at the cited region (`RealtimeService.swift`
  at line 85, `ConversationStorageService.swift`, `MCPConnectionStore.swift` at line 24) and confirmed with
  greps. Each answer said it found the code through the slice and checked it in the live code.
- **Control arm:** one grep on words from the question, then straight to the right file each time. These
  questions contain distinctive strings (`gpt-live`, `refresh_token`, `saveConversation`), so search alone
  found them.
- **The one miss:** the control answer for the voice question explains the URL choice but never says where
  the model comes from (the `realtime_model` setting passed by `InlineVoiceView`, line 130). The `voice`
  slice leads there directly.

## Findings

1. On these three questions the codemap did not reduce context or tool use. The codemap arm used 29%
   more cumulative input and about 10,000 more peak tokens per run, which is the index plus one slice
   carried through every later turn. Tool calls were equal within one (22 and 21).
2. The codemap arm was complete on all three questions; the control missed one required item.
3. A fresh session answering one question here peaked at 57,000 to 77,000 tokens of context and processed
   216,000 to 547,000 input tokens across its turns. The 100,000 to 200,000 tokens Gunnar observed in fresh
   sessions falls between those two measures, depending on which one he read. Each lookup took under
   40 seconds and 11 tool calls, cheap enough that loading the index and a slice added more tokens than it
   saved.

## Limits

- One run per cell and one model; differences of a few tool calls are within run-to-run variation.
- The questions were written by the session that built the map. Ground truth was fixed first, and the
  three slices were produced by delegated workers, not hand-written, but the workers' prompts named the
  same features.
- The codemap-arm sessions ran their greps against the original repository path, which they reconstructed
  from the clone's location (the scratchpad folder name encodes it). The source files are identical and no
  session opened `eval/`, but future clones should sit at a path that does not name the original.
- Untested: questions without distinctive search strings (what depends on a type, which features share a
  setting), change-impact work, and the value of the drift and orphan reports during editing. No saving is
  claimed for them.

## Rerun

Clone twice outside `~/Documents` at a neutral path, copy the codemap files into one clone (never `eval/`),
then for each question:

```bash
python3 ~/.claude/skills/codemap/scripts/measure_fresh.py run --repo <clone> --question "<question>" --out <name>.jsonl
```
