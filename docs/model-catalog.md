# Model catalog

Added in 2.8 (2026-09-29), after GPT-6.1 Sol came out and the model menus could not list it without an app update.

The model menus, each model's reasoning options, pro mode and async tool calls, the default model for new presets,
and which retired models move where all come from one JSON file, the model catalog:

| Copy | Where | Used when |
|---|---|---|
| Built in | `OpenResponses/Resources/ModelCatalog/ModelCatalog.json` | Always available; the unit tests check it |
| Published | https://gunzino.me/openresponses/models.json, from `public/openresponses/models.json` in the Gunzino repository | Its revision is higher than the built-in one's |

`ModelCatalogStore` (`OpenResponses/Core/Services/ModelCatalogStore.swift`) downloads the published copy at launch at
most once every 24 hours, keeps it in Caches, and uses whichever valid copy has the higher `revision`. A copy that
fails validation is ignored, so a broken file can never break the app. Explore Demo and unit tests do not download.
Settings → Model shows the revision in use and where it came from.

The request sends nothing but a plain GET for a public file. The file is data for controls the app already has,
never code (App Review Guideline 2.5.2). The privacy policy at https://gunzino.me/openresponses/privacy/ describes
the request (section 3, updated 2026-09-29).

## Format

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
| `schema` | Must be 1. A file with another number is ignored, so a future format cannot break 2.8. |
| `revision` | Raise it with every change, including a revert. The higher revision wins. |
| `defaultModel` | Default for new presets, the API Workbench and onboarding. Existing presets keep their model (Notion Decision row). |
| `current` | Menu order, top first. `summary` is the line under the name (1 to 80 characters). `reasoningEfforts` lists the values the model page gives, lowest first, from none, minimal, low, medium, high, xhigh, max. `pro` is `reasoning.mode: "pro"`; `asyncTools` is `async: true` on function and custom tools. |
| `earlier` | Older models listed after the current ones. Their reasoning options come from rules in `CurrentModelCatalog`. |
| `retired` | Hidden from every model list. A preset naming one, or a dated snapshot of one, moves to `replacement` (the longest matching entry wins), or to `defaultModel` when there is none. |

Model IDs are lowercase letters, digits, dots and hyphens, and each appears once across `current`, `earlier` and
`retired`. The same rules are in `ModelCatalog.problem()` and in `problem()` in the Gunzino repository's
`scripts/openai_models.py`; change them together.

Two things work without the file:

- A general-purpose model the account has but the file does not list yet (for example `gpt-6.2-sol`) still appears
  in the menus, from GET /models once per launch. Until the file lists it, its reasoning options start at low, pro
  mode is on, and async tool calls are on for versions after 6.0.
- A model whose GET /models entry has a `shutdown_date` within 30 days, or past, counts as retired.

## Upkeep

- **New models:** the Gunzino workflow `.github/workflows/openai-models.yml` runs daily at 15:10 UTC. It compares
  the file with https://developers.openai.com/api/docs/models and, for each new general-purpose model, reads the
  model's docs page, adds an entry at the top of `current`, raises `revision`, and asks Gunnar to merge: a pull
  request when the repository lets Actions open one, otherwise an issue with a link that opens it. Merging deploys
  the site, and every install picks the file up within a day. The same check runs by hand with
  `python3 scripts/openai_models.py watch` in the Gunzino repository.
- **Any other change** (a default model, a retirement, a corrected setting): edit `public/openresponses/models.json`
  in the Gunzino repository, raise `revision`, run `python3 scripts/openai_models.py check`, and push. The site's
  deploy runs the same check and refuses a file the app would ignore.
- **Before an app release:** copy the published file into the built-in one, so a fresh install starts current:

  ```bash
  curl -fsS https://gunzino.me/openresponses/models.json -o OpenResponses/Resources/ModelCatalog/ModelCatalog.json
  ```
