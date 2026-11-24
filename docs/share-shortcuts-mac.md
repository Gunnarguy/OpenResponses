# Share sheet, Shortcuts and the Mac (3.1)

Added 2026-11-20. Apple's guidance behind each choice is in `docs/research/apple-platform-2026-11.md`.

## Shortcuts and Siri

| Action | What it does | Runs |
|---|---|---|
| Ask OpenResponses | Sends one question with a saved preset (or the current settings) and an optional image, PDF or text file, and returns the answer as text | In the background, no app window |
| New Chat in OpenResponses | Opens the app on a new chat with the given text in the message field and the given files attached. Nothing is sent | Opens the app |

- Code: `OpenResponses/App/Intents/OpenResponsesIntents.swift`. Phrases: "Ask OpenResponses", "Ask OpenResponses a question", "Ask OpenResponses with <preset>", "New chat in OpenResponses", "Start a chat in OpenResponses".
- Both actions are part of OpenResponses Pro since 3.1 (`ProAccess`): without it, Ask answers with how to unlock Pro (Settings → OpenResponses Pro) and New Chat opens the app on the Pro sheet instead of the chat. A shortcut that sees the cached flag locked asks StoreKit before refusing.
- They run from Siri, Spotlight, the Action button and the Shortcuts app (`OpenResponsesShortcuts`).
- Ask uses the same consent as the chat: until the person has tapped Allow & Send once in the app, it fails with a message saying so. It also fails without an API key.
- Ask turns off every tool the app itself runs (browser, local Python, function and custom tools, Calendar, Reminders, Contacts, direct Notion tools, multi-agent, async and programmatic tools), because nobody is in the chat to approve or run them. OpenAI-hosted tools and connectors stay as the preset has them. A connector that asks for approval ends the shortcut with an error naming it.
- The intents work from iOS 17 (`openAppWhenRun` for New Chat; iOS 26 deprecates it in favor of `supportedModes`). Not done: `CancellableIntent` (26.4) and `LongRunningIntent` (27), which would let a long answer run past the background limit with a Live Activity.
- App Shortcuts (the phrases) are not supported on macOS (HIG). The actions still appear in the Mac Shortcuts app.

## Share sheet

- Target `OpenResponsesShare` (`com.apple.share-services`), code `OpenResponsesShare/ShareViewController.swift`, a SwiftUI form hosted in a `UIViewController` (no storyboard).
- Accepts text, one web link, up to 10 images and up to 10 files (`OpenResponsesShare/Info.plist`). Files over 25 MB are left out and listed.
- Part of OpenResponses Pro since 3.1: without it the sheet shows a Pro message with only Close, and `ShareModel.save` refuses.
- The person can add a question, taps Save, and the extension writes everything to `SharedInbox` in the App Group `group.Gunndamental.OpenResponses`. The app opens it as a new chat the next time it comes forward (`ChatViewModel.takeSharedInbox`, called from `ContentView` on `scenePhase == .active`).
- Why not answer inside the sheet: the API key is in the app's own Keychain access group, which the extension cannot read, and Apple documents no sanctioned way for a share extension to open its app (`NSExtensionContext.open(_:)` is for Today and iMessage extensions). Answering in the sheet would need a shared Keychain group and a migration of the stored key.
- Both targets carry the App Group (`Config/OpenResponses.entitlements`, `Config/OpenResponsesShare.entitlements`). A build signed without it falls back to an app-only inbox: shortcuts work, the share extension has nowhere to write.

## Mac

Native macOS since 2026-11-22 (Gunnar: "macosify it like how we did with OpenIntelligence"), replacing the Mac Catalyst build described in the 2026-11-20 verification below. macOS 3.1, build 60, is the first Mac version and is live on the App Store since 2026-11-23.

- The same app target builds for macOS (`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`, `SUPPORTS_MACCATALYST = NO`, `MACOSX_DEPLOYMENT_TARGET = 14.0`) on the same bundle ID, so the App Store record is a universal purchase and one OpenResponses Pro purchase covers it. It builds for Apple silicon and Intel.
- Entitlements through `CODE_SIGN_ENTITLEMENTS[sdk=macosx*]`: `Config/OpenResponses-mac.entitlements` (App Sandbox, network client, user-selected files, microphone, contacts, calendars; no camera, no App Group). The share extension is not on the Mac.
- On the Mac, Pro's state and the shortcut inbox live in the app's own container (`ProAccess.defaults` is `.standard` there), and the API key is in the data protection keychain.
- Interface: a sidebar of conversations beside the chat, toolbar New Chat, Share, Compact and Settings; Settings… (Command-comma) opens a window laid out like System Settings; Open and Save panels for files.
- Build locally: `~/.agents/bin/buildlock -- xcodebuild build -project OpenResponses.xcodeproj -scheme OpenResponses -destination 'platform=macOS' -derivedDataPath /private/tmp/openresponses-mac-dd`.
- Archive and upload by hand (what built 59 and 60): `xcodebuild archive ... -destination 'generic/platform=macOS' -allowProvisioningUpdates CURRENT_PROJECT_VERSION=<n>`, then `-exportArchive` with method app-store-connect, destination upload. Xcode Cloud's "Mac Release" workflow (Archive - macOS) does the same on every push to `main` without `[ci skip]`; a build number taken by a local upload blocks the next Cloud upload of that version.
- Shipping it adds a macOS platform to the App Store record. Apple: once two platforms are approved, one cannot be removed again.

## Verification (2026-11-20, Mac Catalyst era)

- Unit tests `SharedInboxAndShortcutTests` (8 tests): inbox order, duplicate names, unsafe names, a half-written delivery, taking the inbox into a new unsent chat, tool stripping, preset reading, answer text and its errors, the consent refusal. All pass on the "OpenResponses tests" simulator.
- The built app's `Metadata.appintents/extract.actionsdata` lists both intents and 2 App Shortcuts.
- The Mac Catalyst build compiled and launched unsigned on this Mac: onboarding and the chat screen drew; the Settings shortcut could not be sent from the shell (no Accessibility permission), so the menu commands have not been seen working.
- Not yet run on a device: the device build needs the App Group registered (see `docs/ai/STATE.md`).

## Verification since (2026-11-20 to 2026-11-23)

- Device: 3.1 Debug installed and launched on Gunnar's iPhone 16 Pro Max (`scripts/ship_device.sh`); `codesign -d --entitlements` showed `group.Gunndamental.OpenResponses` on the app and `OpenResponsesShare.appex`.
- Xcode Cloud run 57 signed the App Group and the share extension (build 57 `VALID`), and iOS 3.1 passed App Review (live 2026-11-23).
- Native Mac: `xcodebuild build -destination 'platform=macOS'` succeeded (2026-11-22); the Mac Release test run 58 archived, signed and exported in the Cloud. Not seen on the Mac: a live chat with a real key, computer use, voice.
- Not seen on the App Store build: the share sheet and the shortcuts end to end (Notion Verification row "Live-check 3.1 on a device").
