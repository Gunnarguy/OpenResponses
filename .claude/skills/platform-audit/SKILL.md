---
name: platform-audit
description: Re-check OpenResponses against OpenAI's current API and Apple's current frameworks, and write a dated gap report. Use when Gunnar asks "what's missing", "what's new in the API", "are we current", "audit the API", "what did OpenAI ship", "what did WWDC add", after an OpenAI changelog entry or a WWDC, and before planning a release. Answers from the docs, never from memory.
---

# Platform audit

OpenResponses is a playground for OpenAI's Responses API, so it is only as good as its coverage of
what OpenAI documents today, and it runs on Apple platforms whose system surfaces (Shortcuts, the share
sheet, the Mac) change every June. Model training predates both, so every claim comes from a page read
during the audit, with the date it was read.

The first audit ran on 2026-11-20 and its reports are the baseline:

- `docs/research/openai-api-gaps-2026-11.md`
- `docs/research/apple-platform-2026-11.md`

## Steps

1. **Read the last reports** above (or the newest `docs/research/*-YYYY-MM.md`), especially their
   "Already covered" lists, so nothing is researched twice.
2. **OpenAI.** Load the `openai-docs` MCP tools (`ToolSearch` "select:mcp__openai-docs__search_openai_docs,mcp__openai-docs__fetch_openai_doc").
   Read the changelog first (https://developers.openai.com/api/docs/changelog) from the date of the
   last report forward, then only the reference pages those entries touch. Search results can exceed
   100,000 characters: pass `limit` 5 or fewer and fetch pages by URL.
3. **Apple.** Load the `sosumi` MCP tools. Read the App Intents, SwiftUI, UIKit, AppKit and StoreKit
   "updates" pages (`/documentation/updates/<framework>`) and the newest WWDC "What's new" session
   transcripts for anything the app could use.
4. **Check the app before calling anything missing.** Grep for the API field, event type, model name
   or framework type; record the grep. `python3 scripts/codemap.py find <words>` locates the feature.
5. **Write** `docs/research/openai-api-gaps-YYYY-MM.md` and/or `docs/research/apple-platform-YYYY-MM.md`
   in the baseline's format: a gap table first (Area, what the docs say with URL, what the app does with
   file:line, value, size), then deprecations with shutdown dates, then "Already covered".
6. **File the gaps** that pass the roadmap's triage in Notion with the `notion-roadmap` skill: a
   deprecation that will break the app is "it blocks shipping"; everything else defaults to Future
   Backlog unless Gunnar places it.

## Rules

- No em dashes. Measurements and doc quotes, not adjectives.
- A model name, price, limit or date is quoted from a page read in this audit, with the date read.
- Two doc pages that disagree are both cited; the disagreement is the finding.
