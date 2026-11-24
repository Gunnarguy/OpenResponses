# OpenResponses Pro

A one-time, non-consumable In-App Purchase added in 3.1 (Gunnar, 2026-11-21: "an unlock and what to unlock, do all of it"). The app stays bring-your-own-key and needs no server. **Status, 2026-11-23:** live on the App Store with iOS 3.1 (In-App Purchase `6838132013` `APPROVED`, iOS 3.1 `READY_FOR_SALE`); the Mac app, which shares the purchase, went live the same day (macOS 3.1 build 60).

## What Pro unlocks, and what stays free

Rule: nobody loses anything. Everything in 2.9 and 3.0 stays free. Only features new in 3.1 are behind Pro (decided before 3.1 was released, so no shipped feature was ever locked).

| Feature | New in | Pro? | Where it's gated |
| --- | --- | --- | --- |
| Shortcuts and Siri: Ask OpenResponses, New Chat | 3.1 | Yes | `AskOpenResponsesIntent.perform` throws a message naming Settings > OpenResponses Pro; `NewChatIntent.perform` opens the app on the Pro sheet instead of the chat |
| Share to OpenResponses (share sheet) | 3.1 | Yes | `ShareView` shows a Pro message and only Close; `ShareModel.save` refuses |
| 12-hour prompt cache lifetime | 3.1 | Yes | Request Options shows "12 hours (Pro)" with a lock and opens the Pro sheet; `OpenAIService` sends a saved 12-hour lifetime only with Pro (`ProAccess.allowedCacheTTL`) |
| Service tier picker | 3.0 | No | |
| GPT-6.2 Sol and Astra, GPT-6.1 Terra | 3.1 | No | Models stay free: the person pays OpenAI for them |
| GPT-6.2 instruction placement, service tiers filtered per model, blocked domains as an API filter, misalignment stops, retired-model moves, Connectors and source-preview fixes | 3.1 | No | Fixes and API updates |
| The Mac app (native macOS) | 3.1 | No | One purchase covers iPhone, iPad and Mac (one bundle ID, universal purchase) |

Price: USD 4.99 (Gunnar, 2026-11-21), chosen after the session data below. Changeable in App Store Connect at any time.

| Measure (App Store Connect analytics, opted-in users only, MONTHLY grain) | OpenResponses | OpenIntelligence |
| --- | --- | --- |
| Sessions, August to October 2026 | 275 | 589 |
| Minutes, August to October 2026 | 229 | 3,551 |
| Average session | about 50 seconds | about 6 minutes |
| First downloads, October 2026 | 67 | |

## How it works

- `ProAccess` (`OpenResponses/Core/Services/ProAccess.swift`), compiled into the app and the share extension: product ID `Gunndamental.OpenResponses.pro`, the features, the entitlement rule, and the unlocked flag in the App Group's defaults (`group.Gunndamental.OpenResponses`, key `proUnlocked`), which the share extension reads.
- `ProStore` (`OpenResponses/Core/Services/ProStore.swift`), app only: StoreKit 2. Watches `Transaction.updates` from launch, reads `Transaction.currentEntitlements` (refunded and revoked purchases are left out), records the result. Restore Purchases calls `AppStore.sync()`, which only runs from a tap because it shows an App Store sign-in. StoreKit reference read on developer.apple.com 2026-11-21.
- `ProPaywallView`: what Pro unlocks, the price from the App Store (`Product.displayPrice`), Buy (`@Environment(\.purchase)`, the SwiftUI purchase action), Restore Purchases. Opened from Settings > OpenResponses Pro and from any locked feature.
- A shortcut checks the cached flag and, when it says locked, asks StoreKit directly before refusing, so a purchase made on another device works before the app has run.
- App Review Guideline 3.1.1 (read 2026-11-21): unlocking features must use In-App Purchase, and restorable purchases need a restore mechanism. Both are met.

## Local testing

`Config/OpenResponsesPro.storekit` holds the product at USD 4.99. `ProAccessTests` (end of `OpenResponsesTests/OpenAIServiceTests.swift`) loads it with `SKTestSession(contentsOf:)`, buys, checks the unlock and the shared flag, refunds and checks the lock. To try the sheet by hand in Xcode: Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration > `OpenResponsesPro.storekit`. The shared scheme does not set it, so a build from the command line asks the real App Store.

## App Store Connect: created 2026-11-22

Created through the App Store Connect API at Gunnar's word (2026-11-22: "Yes, create it"): In-App Purchase id `6838132013`, en-US localization, a USD 4.99 manual price in the USA base territory (proceeds USD 4.24; Apple equalizes the other territories), and availability in all 175 territories with new territories on. Review screenshot (Gunnar, 2026-11-22: "Yes, capture it"): the Pro sheet showing "Unlock for $4.99", run from Xcode with the scheme's StoreKit file on the iPhone 17 Pro Max simulator, saved as `docs/releases/v3.1/screenshots/pro-review-iphone.png` and uploaded (asset state COMPLETE). Read back after it: state `READY_TO_SUBMIT`. API reference read on developer.apple.com 2026-11-22; the `${local-id}` form for the inline price comes from OpenIntelligence's `scripts/schedule_sale.py`.

It was attached to iOS 3.1 as the second item of review submission 639883b0 on 2026-11-22 (a first In-App Purchase is reviewed with a new app version) and approved with it on 2026-11-23. The fields as entered:

| Field | Value |
| --- | --- |
| Type | Non-Consumable |
| Reference name | OpenResponses Pro |
| Product ID | `Gunndamental.OpenResponses.pro` (must match `ProAccess.productID`) |
| Price | USD 4.99 |
| Family Sharing | Off |
| Display name (en-US) | OpenResponses Pro |
| Description (en-US, 55 characters max) | Shortcuts, Siri, the share sheet and a 12-hour cache. |
| Review screenshot | The Pro sheet in the simulator (Settings > OpenResponses Pro) |
| Review notes | One-time unlock for the 3.1 features that run outside the chat: the Ask OpenResponses and New Chat shortcuts, the share sheet entry, and the 12-hour prompt cache lifetime. Everything else is free. Settings > OpenResponses Pro has Buy and Restore Purchases. |

Approved with iOS 3.1 on 2026-11-23. A later change to the product's text or price is made in App Store Connect; text changes go to review with the next app version.
