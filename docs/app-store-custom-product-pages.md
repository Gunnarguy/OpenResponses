# App Store screenshots and custom product pages: plan

Drafted 2026-11-22 at Gunnar's word ("should probably update all of the OpenResponses App Store screen shots and maybe consider adding custom pages as well"). Nothing here is uploaded or created in App Store Connect; each step waits for his yes.

## What the listing has now (App Store Connect API, read 2026-11-22)

| Set | Count | Source |
| --- | --- | --- |
| iPhone 6.5" (`APP_IPHONE_65`) | 10 | Photos from a phone, `IMG_9978` to `IMG_9994` |
| iPad 12.9" (`APP_IPAD_PRO_3GEN_129`) | 10 | iPad Air 13-inch simulator, 2026-01-09 |
| Custom product pages | 0 | |

3.0 has been live since 2026-11-20 21:24 UTC (iTunes lookup `currentVersionReleaseDate`).

## Apple's rules (developer.apple.com, read 2026-11-22)

Custom product pages (`app-store/custom-product-pages` and the App Store Connect help page "Configure multiple product page versions"):

| Rule | Value |
| --- | --- |
| Pages per app | up to 70 |
| What a page can change | screenshots, app previews, promotional text, keywords, a deep link (iOS 18 and later) |
| Review | each page is submitted for App Review, independently of an app update |
| App version | no new version needed; keywords come from the latest approved version |
| Link | each page has its own URL: the default product page URL plus a product page ID parameter |
| Ads | Apple Ads can send an ad to a page, including Search results ads |
| Metrics | shown after a page has at least five first-time downloads |

Screenshots (`help/app-store-connect/reference/screenshot-specifications`): .jpeg, .jpg or .png with no alpha; up to 10 per device size. iPhone 6.9" is 1320 x 2868 portrait; iPad 13" is 2064 x 2752 or 2048 x 2732. App Store Connect scales the largest required size down to the others. The help page's exact wording on which iPhone size is required was read as a summary; check it on the page before uploading.

## New screenshots: staged 2026-11-22

In `docs/releases/v3.1/screenshots/`, with a contact sheet per device. Captured by `StoreScreenshotTests` (in `OpenResponsesUITests/OpenResponsesUITests.swift`, off unless `TEST_RUNNER_STORE_SHOTS_DIR` is set) on simulators made for this: "OpenResponses shots iPhone" (iPhone 17 Pro Max, iOS 27.0) and "OpenResponses shots iPad" (iPad Pro 13-inch M5, iOS 27.0). The demo and test simulators were not used. Answers are real: 10 requests on Gunnar's key (his word, 2026-11-22: "a handful").

| # | iPhone 6.9" (1320 x 2868) | iPad 13" (2064 x 2752) |
| --- | --- | --- |
| 1 | Web search answer with sources | Web search answer with sources |
| 2 | Request Inspector | Request Inspector |
| 3 | Code Interpreter chart | Code Interpreter chart (Seattle rainfall) |
| 4 | Model menu | Model menu |
| 5 | Settings | Settings |
| 6 | Connectors | Decisions answers |
| 7 | Decisions answers | |
| 8 | API Workbench | |

PNG, RGB, no alpha. Not captured: the OpenResponses Pro sheet (it shows no price until the product exists in App Store Connect) and the share sheet (system UI). On iPad, Settings and Decisions open as form sheets over the chat, so those two shots are smaller than the iPhone ones. The iPhone chart shot's text shows the model's LaTeX as typed (`\(y = x\sin(x)\)`): the chat does not render inline math.

Order follows the listing's own first line: "it shows you the request before it goes out, the events as they stream back, and every tool call along the way."

## Custom product pages: proposals

Each page is a separate audience, with its own first three screenshots and promotional text. The keywords come from the approved version, so a page gets search traffic only for keywords that version already has.

| Page | Who it is for | First screenshots | When |
| --- | --- | --- | --- |
| See every request | developers comparing the API's models | Request Inspector, API Workbench, model menu | now (3.0 features) |
| Connectors | people who use MCP servers or Notion | Connectors, a Notion tool step, Settings search | now (3.0 features) |
| Decisions | people trying the Decisions API | Decisions, Workbench "Create decision" | now (3.0 features) |
| Shortcuts and the share sheet | iPhone people who live in Shortcuts | Shortcuts, share sheet, Pro sheet | after 3.1 is live |
| Mac | Mac users | the Mac app | after 3.1 is live and the Mac build is signed |

The links would go where each audience already is: the README and docs (`GitHub_Repo` tag), gunnarguy.me (`Portfolio_Site`), and per-platform post tags. Each link keeps the campaign token form in the machine map and adds the page's ID parameter.

## Waiting for Gunnar

- Pick the screenshots to upload, and to which version (3.0's live listing, 3.1, or both).
- Say which custom product pages to create. Creating and submitting them is outward-facing.
