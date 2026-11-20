# Share sheet, Shortcuts and the Mac (3.1)

Added 2026-11-20. Apple's guidance behind each choice is in `docs/research/apple-platform-2026-11.md`.

## Shortcuts and Siri

| Action | What it does | Runs |
|---|---|---|
| Ask OpenResponses | Sends one question with a saved preset (or the current settings) and an optional image, PDF or text file, and returns the answer as text | In the background, no app window |
| New Chat in OpenResponses | Opens the app on a new chat with the given text in the message field and the given files attached. Nothing is sent | Opens the app |

- Code: `OpenResponses/App/Intents/OpenResponsesIntents.swift`. Phrases: "Ask OpenResponses", "Ask OpenResponses a question", "Ask OpenResponses with <preset>", "New chat in OpenResponses", "Start a chat in OpenResponses".
- Ask uses the same consent as the chat: until the person has tapped Allow & Send once in the app, it fails with a message saying so. It also fails without an API key.
- Ask turns off every tool the app itself runs (browser, local Python, function and custom tools, Calendar, Reminders, Contacts, direct Notion tools, multi-agent, async and programmatic tools), because nobody is in the chat to approve or run them. OpenAI-hosted tools and connectors stay as the preset has them. A connector that asks for approval ends the shortcut with an error naming it.
- The intents work from iOS 17 (`openAppWhenRun` for New Chat; iOS 26 deprecates it in favor of `supportedModes`). Not done: `CancellableIntent` (26.4) and `LongRunningIntent` (27), which would let a long answer run past the background limit with a Live Activity.
- App Shortcuts (the phrases) are not supported on macOS (HIG). The actions still appear in the Mac Shortcuts app.

## Share sheet

- Target `OpenResponsesShare` (`com.apple.share-services`), code `OpenResponsesShare/ShareViewController.swift`, a SwiftUI form hosted in a `UIViewController` (no storyboard).
- Accepts text, one web link, up to 10 images and up to 10 files (`OpenResponsesShare/Info.plist`). Files over 25 MB are left out and listed.
- The person can add a question, taps Save, and the extension writes everything to `SharedInbox` in the App Group `group.Gunndamental.OpenResponses`. The app opens it as a new chat the next time it comes forward (`ChatViewModel.takeSharedInbox`, called from `ContentView` on `scenePhase == .active`).
- Why not answer inside the sheet: the API key is in the app's own Keychain access group, which the extension cannot read, and Apple documents no sanctioned way for a share extension to open its app (`NSExtensionContext.open(_:)` is for Today and iMessage extensions). Answering in the sheet would need a shared Keychain group and a migration of the stored key.
- Both targets carry the App Group (`Config/OpenResponses.entitlements`, `Config/OpenResponsesShare.entitlements`). A build signed without it falls back to an app-only inbox: shortcuts work, the share extension has nowhere to write.

## Mac

- Mac Catalyst on the same target and bundle ID (`SUPPORTS_MACCATALYST = YES`, `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER = NO`), which Apple documents as universal purchase with the iOS app. Interface: Scale to Match iPad (the default); Optimize for Mac is a later step once fixed-size layout (`UIScreen.main.bounds` math in `EnhancedImageView.swift` and `MessageBubbleView.swift`) is replaced.
- The Mac build uses `Config/OpenResponses-mac.entitlements` (App Sandbox, network client, user-selected files, camera, microphone, contacts, calendars, the App Group) through `CODE_SIGN_ENTITLEMENTS[sdk=macosx*]`.
- Menu commands: File > New Chat (Command-N) and OpenResponses > Settings (Command-comma); Command-Return sends from any hardware keyboard (`OpenResponsesCommands` in `OpenResponsesApp.swift`, `ChatInputView.sendButton`).
- Build for the Mac without signing: `xcodebuild -project OpenResponses.xcodeproj -scheme OpenResponses -destination 'platform=macOS,variant=Mac Catalyst' -derivedDataPath /private/tmp/openresponses-mac-dd CODE_SIGNING_ALLOWED=NO build`, then `open /private/tmp/openresponses-mac-dd/Build/Products/Debug-maccatalyst/OpenResponses.app`.
- Shipping it adds a macOS platform to the App Store record. Apple: once two platforms are approved, one cannot be removed again.

## Verification (2026-11-20)

- Unit tests `SharedInboxAndShortcutTests` (8 tests): inbox order, duplicate names, unsafe names, a half-written delivery, taking the inbox into a new unsent chat, tool stripping, preset reading, answer text and its errors, the consent refusal. All pass on the "OpenResponses tests" simulator.
- The built app's `Metadata.appintents/extract.actionsdata` lists both intents and 2 App Shortcuts.
- The Mac Catalyst build compiled and launched unsigned on this Mac: onboarding and the chat screen drew; the Settings shortcut could not be sent from the shell (no Accessibility permission), so the menu commands have not been seen working.
- Not yet run on a device: the device build needs the App Group registered (see `docs/ai/STATE.md`).
