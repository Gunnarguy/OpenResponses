# Model list

Added in 2.8 (2026-09-29), after GPT-6.1 Sol came out and the model menus could not list it without an app update.
Nothing has to be done by hand when OpenAI releases a model: the account's model list shows it, and the app reads its
settings from OpenAI's docs site.

| Source | What it gives | When |
|---|---|---|
| `OpenResponses/Resources/ModelCatalog/ModelCatalog.json`, built in | The models the app knows, in menu order, with their reasoning efforts, pro mode, async tool calls and summaries; the default model; retired models and where their presets move | Always |
| GET /models with the user's key | Which models the account can use, and each one's `shutdown_date` | Once per launch (`ChatViewModel.refreshAccountModels`) |
| The model's page on OpenAI's docs site, `https://developers.openai.com/api/docs/models/<id>.md` | Reasoning efforts, a summary, and whether the Responses API supports it, for a model the built-in list does not name | The first time the account lists the model, again after 7 days, at most 3 pages per launch |

A new general-purpose model (for example `gpt-6.2-sol`) appears at the top of the chat status bar menu and the request
settings menu at the next launch after the account lists it. Until its page has been read, its reasoning options start
at low (GPT-6 Astra and GPT-6.1 Sol reject `none` with HTTP 400), pro mode is on, and async tool calls are on for
versions after 6.0. A page that says the Responses API does not support the model takes it out of the menus. A page
that cannot be read leaves those fallbacks in place until the next try.

A model whose GET /models entry has a `shutdown_date` within 30 days, or past, counts as retired: it leaves the model
lists, and a preset naming it moves to its replacement.

The docs request carries no personal data, chat content or API key, and Explore Demo and unit tests make none. The
privacy policy at https://gunzino.me/openresponses/privacy/ describes both automatic requests (section 3, updated
2026-09-29). Page text is parsed as data for settings the app already has, never run (App Review Guideline 2.5.2).

## The built-in file

```json
{
  "schema": 1,
  "revision": 1,
  "updated": "2026-09-29",
  "notes": "free text",
  "defaultModel": "gpt-6-sol",
  "current": [
    {"id": "gpt-6.1-sol", "summary": "Near-Astra performance at a lower cost", "reasoningEfforts": ["low", "medium", "high", "xhigh", "max"], "pro": true, "asyncTools": true, "released": "2026-09-29"}
  ],
  "earlier": ["gpt-5.5", "gpt-4o"],
  "retired": [{"id": "gpt-5-mini", "replacement": "gpt-5.6-terra"}, {"id": "o1-pro"}]
}
```

| Field | Meaning |
|---|---|
| `schema` | Must be 1. |
| `revision`, `updated` | Raise and date them with every change. |
| `defaultModel` | Default for new presets, the API Workbench and onboarding. Existing presets keep their model (Notion Decision row). |
| `current` | Menu order, top first. `summary` is the line under the name (1 to 80 characters). `reasoningEfforts` lists the values the model page gives, lowest first, from none, minimal, low, medium, high, xhigh, max. `pro` is `reasoning.mode: "pro"`; `asyncTools` is `async: true` on function and custom tools. |
| `earlier` | Older models listed after the current ones. Their reasoning options come from rules in `CurrentModelCatalog`. |
| `retired` | Hidden from every model list. A preset naming one, or a dated snapshot of one, moves to `replacement` (the longest matching entry wins), or to `defaultModel` when there is none. |

Model IDs are lowercase letters, digits, dots and hyphens, and each appears once across `current`, `earlier` and
`retired`. `ModelCatalog.problem()` enforces these rules, and the unit tests fail if the built-in file breaks them.

## Upkeep

Nothing is needed for a new model. Edit the built-in file in an app release to change the default model, the order,
a summary, or a setting the docs page cannot give (pro mode and async tool calls are not on model pages), or to retire
a model before its shutdown date is within 30 days.

If OpenAI changes the layout of its model pages, `ModelCatalog.settings(fromDocsPage:id:checkedOn:)` stops finding
settings and new models keep the fallbacks. `testTheLiveGPT61SolPageStillGivesItsSettings` checks the live page:

```bash
TEST_RUNNER_LIVE_OPENAI_DOCS=1 xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses -destination "platform=iOS Simulator,name=OpenResponses tests" -only-testing:OpenResponsesTests/ModelCatalogTests -derivedDataPath "$TMPDIR/openresponses-derived" CODE_SIGNING_ALLOWED=NO
```
