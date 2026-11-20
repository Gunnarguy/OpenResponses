# Apple platform surfaces for OpenResponses (research, 2026-11-20)

Scope: how OpenResponses (iOS 17.0 target, one app target, bundle `Gunndamental.OpenResponses`, team Z3E334EXZD) should add Shortcuts and Siri actions, a share sheet entry and a Mac version, and which other system surfaces are worth adopting. Every Apple page cited below was read on 2026-11-20 through developer.apple.com (sosumi mirror, fetch timestamps 2026-11-20 UTC) unless the row says otherwise. Anything not read in a document is marked INFERRED. Nothing in the app was changed; this file is the only output.

Evidence labels: [doc_read 2026-11-20] for Apple pages, [code_verified] for facts read in this repo or in OpenIntelligence, [measured] for commands run against this project or App Store Connect.

## Recommendation table

| Surface | Recommended approach | Min OS | Doc URL | Size | Risk |
|---|---|---|---|---|---|
| Siri and Shortcuts "Ask OpenResponses" | One `AppIntent` in the app target, `supportedModes = [.background, .foreground(.dynamic)]`, returns `ReturnsValue<String or AnswerEntity> & ProvidesDialog & ShowsSnippetIntent`; conform to `ProgressReportingIntent` (17), `CancellableIntent` (26.4) and `LongRunningIntent` (27) through availability-gated extensions, the pattern OpenIntelligence ships | Intent iOS 17 (framework 16); modes and snippets iOS 26; cancel 26.4; long-running 27 | https://developer.apple.com/documentation/appintents/longrunningintent | M | Medium: answers over 30 s are cut on iOS 26 and earlier unless the app comes forward |
| Preset as a parameter | `AppEntity` over `PromptLibrary` presets with an `EntityQuery`; optional parameter | iOS 16 | https://developer.apple.com/documentation/appintents/app-shortcuts | S | Low |
| File or image input | `@Parameter var file: IntentFile?` converted through the existing attachment pipeline | iOS 16 | https://developer.apple.com/documentation/appintents/intentfile | S | Low; watch the 10 MB entity limit on returned values |
| App Shortcuts (Siri phrases, Spotlight, Action button) | `AppShortcutsProvider` with 2 to 4 shortcuts, each phrase containing `\(.applicationName)` | iOS 16 (initializer used: iOS 17) | https://developer.apple.com/design/human-interface-guidelines/app-shortcuts | S | Low; App Shortcuts are not supported in macOS |
| Share sheet | Classic Share Extension (`com.apple.share-services`) with an App Group inbox; the app reads the inbox on activation. No App Intents share-sheet entry exists in the docs read | iOS 8 (extension point) | https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionattributes/nsextensionactivationrule | M | Medium: the extension cannot open the app through a sanctioned API; the API key lives in a non-shared Keychain group |
| Mac, now | "iOS apps on Mac" (Designed for iPad) is already enabled by default in the build (`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`); confirm the App Store Connect toggle and test locally | macOS on Apple silicon | https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-in-macos | S | Low cost, iPad metrics, Apple silicon only |
| Mac, shipping version | Mac Catalyst on the same target and bundle ID, start with Scale Interface to Match iPad, move to Optimize Interface for Mac | macOS 27 SDK; Catalyst availability of the APIs used: 13.1 to 18 | https://developer.apple.com/documentation/uikit/creating-a-mac-version-of-your-ipad-app | M | Medium: sandbox entitlements, camera and realtime audio behavior on Mac need testing |
| Mac, native SwiftUI | Not now: 52 of 141 Swift files use UIKit types or iOS-only SwiftUI modifiers [measured] | macOS 14+ for most APIs used | https://developer.apple.com/documentation/xcode/configuring-a-multiplatform-app-target | L | High churn |
| Live Activity for a long answer | Free with `LongRunningIntent` on iOS 27 (system shows progress as a Live Activity with a stop button); no ActivityKit work for intents | iOS 27 | https://developer.apple.com/videos/play/wwdc2026/345 | S (part of the intent) | Low |
| Spotlight | `IndexedEntity` for conversations, backed by the existing `ConversationSearchIndex` text | iOS 18 | https://developer.apple.com/documentation/appintents/indexedentity | M | Low; conversation text enters the on-device index |
| Control Center control | `ControlWidget` button that runs "New chat" or "Ask" (widget extension needed) | iOS 18, macOS 26 | https://developer.apple.com/documentation/swiftui/controlwidget | M | Low |
| TipKit | Tip that shows the Siri phrase (`SiriTipView`) and points at Settings search | iOS 17 | https://developer.apple.com/documentation/tipkit | S | Low |
| Writing Tools | Keep the default in the composer; set `.writingToolsBehavior(.disabled)` on JSON and code editors | iOS 18 | https://developer.apple.com/documentation/swiftui/view/writingtoolsbehavior(_:) | S | Low |
| Foundation Models as a model option | Later, behind a provider switch: `SystemLanguageModel` (on-device) | iOS 26 | https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel | L | Medium: different request shape from the Responses API; PCC model needs a managed entitlement |
| Widgets | Low priority: a quick-ask button widget once intents exist | iOS 17 (interactive) INFERRED | https://developer.apple.com/documentation/widgetkit | M | Low value |
| Handoff | Low priority until a Mac version exists; conversations are local files | iOS 8 | https://developer.apple.com/documentation/foundation/nsuseractivity | M | Low value |
| Visual Intelligence | Skip: it matches camera or screen images to an app's own content catalog, and OpenResponses has none | iOS 26 | https://developer.apple.com/documentation/appintents/visual-intelligence | M | Poor fit |
| Siri tool (`@AppIntent(.tool)`) | Watch only: iOS 27.3 beta | iOS 27.3 beta | https://developer.apple.com/documentation/appintents/toolintent | S | Beta API |

## Facts about this codebase that drive the answers

- One app target, `SDKROOT = iphoneos`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, `TARGETED_DEVICE_FAMILY = "1,2"`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Swift 5 mode, generated Info.plist plus `OpenResponses/Info.plist` holding only the `openresponses` URL scheme [code_verified, OpenResponses.xcodeproj/project.pbxproj lines 576-627].
- Effective settings from `xcodebuild -showBuildSettings` [measured 2026-11-20]: `SUPPORTS_MACCATALYST = NO`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`, `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = YES`, `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER = NO`, `ENABLE_APP_SANDBOX = NO`, `MACOSX_DEPLOYMENT_TARGET = 27.0` (default, unused today).
- App Store Connect [measured 2026-11-20, read-only GET]: the app record has only `IOS` platform versions (3.0 waiting for review, 2.6 to 2.9 ready for sale). Whether "Make this app available on Mac" is on is not exposed in the attributes read; check App Store Connect, Pricing and Availability.
- No entitlements file exists; no App Group, no Keychain Sharing [code_verified].
- The API key is read with `KeychainService.shared.load(forKey: "openAIKey")` from a generic-password item with service `OpenResponses`, no `kSecAttrAccessGroup`, accessibility `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` [code_verified, Core/Services/KeychainService.swift lines 16-64; Core/Services/OpenAIService.swift lines 73, 212, 391]. Without an access group the item lives in the app's private group (team ID plus bundle ID), so an extension cannot read it today (see Question 2).
- Presets are `[Prompt]` JSON in `UserDefaults.standard` under `savedPrompts` [code_verified, Features/Chat/Data/PromptLibrary.swift]. Conversations are files under Application Support [code_verified, Core/Services/ConversationStorageService.swift].
- The request entry point is `OpenAIService.sendChatRequest(userMessage:prompt:attachments:fileData:fileNames:fileIds:imageAttachments:audioAttachments:previousResponseId:conversationId:)` and the streaming twin `streamChatRequest(...)` [code_verified, OpenAIService.swift lines 70 and 206]. An intent can call these without any view model.
- No App Intents, WidgetKit, ActivityKit, Core Spotlight, NSUserActivity, Foundation Models, TipKit or `writingToolsBehavior` code exists yet [measured, grep count 0 each].

---

## Question 1: Shortcuts and Siri (App Intents)

### Recommended shape of "Ask OpenResponses"

```swift
import AppIntents

@available(iOS 26.0, *)
struct AskOpenResponsesIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask OpenResponses"
    static let description = IntentDescription(
        "Sends a question to the OpenAI Responses API with your saved key and returns the answer.",
        categoryName: "Ask", searchKeywords: ["ask", "question", "OpenAI", "answer"])

    // Background first; come forward only when needed (no key saved, an MCP approval, a long answer on iOS 26).
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "Question", description: "The text to send as the user message")
    var question: String

    @Parameter(title: "Preset", description: "A saved preset; leave empty to use the active settings")
    var preset: PresetEntity?

    @Parameter(title: "File", description: "An optional image, PDF or text file to attach")
    var file: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Summary("Ask \(\.$question)") { \.$preset; \.$file }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetIntent {
        // Run through one runner, as OpenIntelligence's AskActionRunner does.
    }
}

@available(iOS 26.4, *) extension AskOpenResponsesIntent: CancellableIntent {}
@available(iOS 26.0, *) extension AskOpenResponsesIntent: ProgressReportingIntent {}
@available(iOS 27.0, *) extension AskOpenResponsesIntent: LongRunningIntent {}
```

Why each piece:

| Piece | What the docs say | Min OS | Source |
|---|---|---|---|
| `AppIntent` | Base protocol | iOS 16 | https://developer.apple.com/documentation/appintents/appintent [doc_read 2026-11-20 via search result] |
| `supportedModes` / `IntentModes` | `.background`, `.foreground(.immediate)`, `.foreground(.dynamic)`, `.foreground(.deferred)`; combine `.background` with `.dynamic` "to run the app in either the foreground or background, but to prefer the background". Inside `perform()` read `systemContext.currentMode` and `canContinueInForeground`, then call `continueInForeground(_:alwaysConfirm:)` | iOS 26.0 | https://developer.apple.com/documentation/appintents/appintent/supportedmodes |
| `openAppWhenRun` | Deprecated: "Please provide 'supportedModes' instead". Setting it `true` "generates an error if the app intent runs in an app extension" | iOS 16, deprecated | https://developer.apple.com/documentation/appintents/appintent/openappwhenrun |
| `OpenIntent` | Opens the app to show a `target` entity; "The system automatically brings your app to the foreground". Use for a separate "Open Conversation" intent, not for Ask | iOS 16 | https://developer.apple.com/documentation/appintents/openintent |
| `ProgressReportingIntent` | Provides `progress` | iOS 17.0 | https://developer.apple.com/documentation/appintents/progressreportingintent |
| `CancellableIntent` | `withIntentCancellationHandler(operation:onCancel:isolation:)`; reasons are a timeout ("didn't report progress and exceeded its 30-second runtime limit") or a person cancelling "in Siri, Live Activities, or Shortcuts" | iOS 26.4 | https://developer.apple.com/documentation/appintents/cancellableintent |
| `LongRunningIntent` | Inherits `ProgressReportingIntent`; wrap the work in `performBackgroundTask(options:operation:)` or `performBackgroundTask(options:operation:onCancel:)`; report progress regularly or the system "can cancel the background runtime extension". Note: "In macOS, the system allows background tasks to run without time limits" | iOS 27.0, macOS 27.0 | https://developer.apple.com/documentation/appintents/longrunningintent |
| `LongRunningTaskOptions` | Only option listed: `requiresGPU` (not needed; inference runs on OpenAI's servers) | iOS 27.0 | https://developer.apple.com/documentation/appintents/longrunningtaskoptions |
| Live Activity for progress | "as your intent runs, progress updates appear automatically as a Live Activity", with a stop button | iOS 27 | https://developer.apple.com/videos/play/wwdc2026/345 (transcript 13:25 to 14:25) |
| `IntentFile` | `filename`, `type`, `data`, `fileURL`, `data(contentType:)`, `withFile(contentType:allowOpenInPlace:fileHandler:)`, `removedOnCompletion` | iOS 16 | https://developer.apple.com/documentation/appintents/intentfile |
| `SnippetIntent` / `ShowsSnippetIntent` | Interactive snippet; the system may call `perform()` several times, so it must have no side effects; buttons must be initialized with an `AppIntent`; `reload()` refreshes a visible snippet | iOS 26.0 | https://developer.apple.com/documentation/appintents/snippetintent, https://developer.apple.com/documentation/appintents/displaying-static-and-interactive-snippets |
| Static snippet | `.result(view: SomeView())` returning `ShowsSnippetView` | iOS 16 INFERRED (protocol page not opened) | https://developer.apple.com/documentation/appintents/displaying-static-and-interactive-snippets |

Shape notes:

1. Return the answer as a value, not only as dialog. The snippet article says "When someone performs an action with Siri AI that invokes your app intent, the system might not display `IntentDialog` or `ShowsSnippetView`." A `ReturnsValue<String>` (or a small `AnswerEntity` with `text`, `model`, `responseId`) is what a shortcut chains into the next action.
2. Keep the returned entity small. The macOS 27 release notes, App Intents section, record that "AppEntity instances have a cumulative size limit of 10MB, including all child properties and their values" and that an app "might crash if an entity exceeds this limit". Do not put generated images or file bytes in the entity; return text plus a conversation ID. Source: https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes [doc_read 2026-11-20].
3. Answers that take longer than 30 seconds. On iOS 26.x the only ways past the limit are reporting progress (which does not extend the limit; OpenIntelligence's comment says the same) or coming forward with `continueInForeground`. On iOS 27 `LongRunningIntent.performBackgroundTask` extends it, as long as `progress` keeps changing. OpenIntelligence's `AskControl` ticks progress every 2 seconds and grows `totalUnitCount` near the end so the count never stalls; copy that design [code_verified, OpenIntelligence/Services/Agentic/RAGAppIntents.swift lines 57-160 and 380-437].
4. Streaming. Use `streamChatRequest` inside the operation and advance `progress` on each delta or every 2 seconds; return the final text. INFERRED: Siri does not show partial text; only the progress bar moves.
5. Background reach of the API key. The key is stored `AfterFirstUnlockThisDeviceOnly`, so a background intent can read it on a locked phone after the first unlock [code_verified]. If no key is saved, throw an error with `AppIntentError(description:)` (iOS 27, per the App Intents updates page) or, when `canContinueInForeground`, bring the app forward to onboarding.
6. Conformances behind availability. With the iOS 17 deployment target, declare the intent `@available(iOS 26.0, *)` (so `supportedModes` and `SnippetIntent` are usable) and add `CancellableIntent` (26.4) and `LongRunningIntent` (27.0) in `@available` extensions, exactly as OpenIntelligence does at RAGAppIntents.swift lines 1437-1458, then branch at runtime with `if #available(iOS 27.0, *), let long = intent as? any (LongRunningIntent & CancellableIntent)` (line 389). That file passed App Review in OpenIntelligence (per the task brief); its deployment target is iOS 26.0, not 17.0 [code_verified, OpenIntelligence.xcodeproj]. A shortcut on iOS 17 to 25 would see no OpenResponses action. Raising the deployment target is a separate decision for Gunnar.

### Preset as an AppEntity

```swift
struct PresetEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Preset"
    static let defaultQuery = PresetQuery()
    let id: UUID
    @Property(title: "Name") var name: String
    var displayRepresentation: DisplayRepresentation { "\(name)" }
}
struct PresetQuery: EntityQuery {
    func entities(for ids: [UUID]) async throws -> [PresetEntity] { /* PromptLibrary */ }
    func suggestedEntities() async throws -> [PresetEntity] { /* PromptLibrary */ }
}
```

- `PromptLibrary` reads `UserDefaults.standard`; that works when the intent runs in the app process. If the intent later moves to an App Intents extension, presets must move to `UserDefaults(suiteName:)` in an App Group [doc_read: https://developer.apple.com/documentation/xcode/configuring-app-groups].
- `Prompt.id` is a `UUID` assigned on add, so IDs are stable on one device. They are not stable across devices, so do not adopt `SyncableEntity` (iOS 27, "declares to the system that your entity's ID is stable and can be used across devices") [doc_read: https://developer.apple.com/videos/play/wwdc2026/345].
- `updateAppShortcutParameters()` on the provider refreshes stored parameter options after presets change [doc_read: https://developer.apple.com/documentation/appintents/appshortcutsprovider].

### AppShortcutsProvider rules and limits

| Rule | Source |
|---|---|
| "Each app can include up to 10 App Shortcuts." | HIG App Shortcuts, https://developer.apple.com/design/human-interface-guidelines/app-shortcuts |
| Phrases must include the app name: "You have to include your app name, but you can be creative with it." Use the `\(.applicationName)` token (`AppShortcutPhraseToken`) | HIG App Shortcuts; https://developer.apple.com/documentation/appintents/appshortcutphrase |
| "An App Shortcut can include a single optional value, or parameter, if it makes sense." Values should be "predictable and familiar" | HIG App Shortcuts |
| Order matters: the order sets the initial order in Spotlight and Shortcuts | HIG App Shortcuts, iOS section |
| "App Shortcuts aren't supported in macOS." Actions still appear in Shortcuts on Mac | HIG App Shortcuts, macOS section |
| HIG change log 2026-06-08: "Added guidance for adopting app schemas"; schemas cover common domains, App Shortcuts are for features "not covered by app schemas" | HIG App Shortcuts |
| Initializer `init(intent:phrases:shortTitle:systemImageName:)` (iOS 17.0) and the `parameterPresentation:` variant | https://developer.apple.com/documentation/appintents/appshortcut |
| `NegativeAppShortcutPhrases` exists to keep phrases from routing to the app | https://developer.apple.com/documentation/appintents/app-shortcuts |
| `SiriTipView` and `ShortcutsLink` surface the phrases inside the app | https://developer.apple.com/documentation/appintents/app-shortcuts |
| INFERRED (not read on 2026-11-20): only `AppEntity` or `AppEnum` parameters can appear inside a phrase; a free `String` such as the question cannot, so Siri asks for it after the phrase | WWDC22 10170 (not opened) |

Suggested set (4 of 10): "Ask `\(.applicationName)`" / "Ask `\(.applicationName)` a question" (Ask); "Ask `\(.applicationName)` with `\(\.$preset)`" (Ask with a preset entity); "New chat in `\(.applicationName)`" (an `OpenIntent`-style foreground intent); "Talk to `\(.applicationName)`" (opens Realtime voice in the foreground). No app schema domain fits a general chat assistant, so App Shortcuts are the right tool (INFERRED from the list of schema domains not being read in full).

### App target, App Intents extension or framework

| Option | What the docs say | Fit for OpenResponses |
|---|---|---|
| App target | Default; an intent that can run in the foreground "needs to live in your app bundle or in a shared framework your app includes" | Recommended now. The intent needs the Keychain item, `PromptLibrary`, conversation storage and `OpenAIService`, all in the app process |
| App Intents extension | "An app intent in your App Intents extension always runs in the background"; `continueInForeground` from an extension reports an error | Later, only if launch cost matters; it needs an App Group and a shared Keychain group first |
| Shared framework or Swift package | Declare `struct MyFrameworkPackage: AppIntentsPackage {}` in the framework and list it in the app's `includedPackages`; a Swift package must be "a shareable binary framework" | Needed only when a widget or control extension must run the same intents |
| `allowedExecutionTargets` | `IntentExecutionTargets` `.main`, `.appIntentsExtension`, `.widgetKitExtension`, `.default` | iOS 27.0; use `.main` for Ask if intents ever move into a shared framework |

Sources: https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents, https://developer.apple.com/documentation/appintents/appintentspackage (iOS 17.0), https://developer.apple.com/documentation/appintents/intentexecutiontargets (iOS 27.0).

### What is new in iOS 26 and 27 (App Intents)

From the App Intents updates page (https://developer.apple.com/documentation/updates/appintents) and WWDC26 session 345 (https://developer.apple.com/videos/play/wwdc2026/345). The WWDC25 "Explore new advances in App Intents" session (https://developer.apple.com/videos/play/wwdc2025/275) was found in search but its transcript was not read; its 2025 items below come from the updates page.

- June 2025 (iOS 26): `SnippetIntent` interactive snippets; `IndexedEntity` with `@Property(indexingKey:)`; Visual Intelligence through `IntentValueQuery`; `Transferable` entities tied to `NSUserActivity.appEntityIdentifier` for onscreen content.
- June 2026 (iOS 27): `LongRunningIntent` with `LongRunningTaskOptions`; `CancellableIntent` with `IntentCancellationReason` (page date June 2026, symbol availability 26.4); `UndoableIntent`; `supportedModes` listed again; `allowedExecutionTargets`; `EntityCollection` (identifiers only, avoids resolving every entity); `@UnionValue` with `AppUnionValue`; `IndexedEntityQuery`; `SyncableEntity`; `OwnershipProvidingEntity`; `RelevantEntities`; `IntentValueRepresentation`; `RunSystemShortcutIntent` for widgets; `AppIntentError(description:)`; native parameter types such as `Duration` and `PersonNameComponents` (session 345, 11:02).
- iOS 27.3 beta: `ToolIntent` and the `@AppIntent(.tool)` macro make an intent a tool Siri can call "while handling a person's request"; candidates are single-sentence actions; "Intents with side effects that a person needs to start explicitly" are listed as poor tools. Ask is a reasonable later candidate; beta today. https://developer.apple.com/documentation/appintents/toolintent
- Shortcuts in 2026 (WWDC26 session 310, https://developer.apple.com/videos/play/wwdc2026/310): notification, screenshot and keyboard automations; the Use Model action shows a transcript of the entities passed to the model; Storage persists values between runs and syncs across devices, which is why stable entity IDs matter.
- Testing: WWDC26 session 295 "Validate your App Intents adoption with AppIntentsTesting" (found in search, not read). INFERRED that it can run the Ask intent in unit tests without UI automation.

---

## Question 2: Share sheet entry

### Is a Share Extension still the way on iOS 27?

Yes. The App and system extensions overview lists "Share Extension" (iOS/iPadOS and macOS) and "Action Extension" ("Add custom actions to the share sheet") as the share-sheet extension points; the App Intents rows offer no share-sheet placement [doc_read: https://developer.apple.com/documentation/technologyoverviews/app-extensions]. The App Intents updates page (June 2024 to June 2026) lists `IntentFile` parameters for receiving content "other apps make available with app intents" and `Transferable` entities for sending content out, but no API that puts an app in the share sheet [doc_read: https://developer.apple.com/documentation/updates/appintents]. The WWDC26 "What's new in Shortcuts" transcript does not mention the share sheet [doc_read].

INFERRED (Shortcuts user feature, not a developer API, not read): a person can build a shortcut that accepts share-sheet input and passes it to "Ask OpenResponses" through its `IntentFile` parameter. That is a free bonus of Question 1, not a replacement for an extension.

### Extension setup

| Item | Value |
|---|---|
| Target | New "Share Extension" target, for example `OpenResponsesShare`, bundle ID `Gunndamental.OpenResponses.Share` (INFERRED naming; it must be prefixed by the app's bundle ID) |
| `NSExtensionPointIdentifier` | `com.apple.share-services` [doc_read: archive Share page, updated 2017-10-19, https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html] |
| Principal class | Untick "Use standard social compose interface" to get a `UIViewController` subclass instead of `SLComposeServiceViewController` [same archive page]. Host the SwiftUI view with `UIHostingController` as a child view controller (INFERRED; no 2026 page on SwiftUI in share extensions was read). Use `NSExtensionPrincipalClass` instead of `NSExtensionMainStoryboard` to drop the storyboard (key listed on the activation-rule page) |
| Input | `extensionContext?.inputItems` as `[NSExtensionItem]`, each with `attachments: [NSItemProvider]` [doc_read: https://developer.apple.com/documentation/foundation/nsextensioncontext/inputitems, search result] |
| Finish | `completeRequest(returningItems:completionHandler:)`; after that "the system can terminate your extension at any time" [doc_read: archive ExtensionScenarios page] |

### Activation rule (Info.plist, `NSExtension` > `NSExtensionAttributes` > `NSExtensionActivationRule`)

Keys available [doc_read: https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionattributes/nsextensionactivationrule]:

| Content | Key | Suggested value |
|---|---|---|
| Plain text | `NSExtensionActivationSupportsText` | `YES` |
| Web URL (from Safari and others) | `NSExtensionActivationSupportsWebURLWithMaxCount` | `1` |
| Web page | `NSExtensionActivationSupportsWebPageWithMaxCount` | `1` (only if a JavaScript preprocessing file is added) |
| Images | `NSExtensionActivationSupportsImageWithMaxCount` | `4` |
| Files of any type (PDF, documents) | `NSExtensionActivationSupportsFileWithMaxCount` | `4` |
| Movies | `NSExtensionActivationSupportsMovieWithMaxCount` | omit (`0`) |
| Totals | `NSExtensionActivationSupportsAttachmentsWithMinCount` / `...MaxCount` | optional |

For PDFs only, replace the dictionary with a predicate string. The archive guide gives this for exactly one PDF [doc_read: https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html, updated 2017-10-19]:

```
SUBQUERY (extensionItems, $extensionItem,
  SUBQUERY ($extensionItem.attachments, $attachment,
    ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "com.adobe.pdf"
  ).@count == $extensionItem.attachments.@count
).@count == 1
```

The same page: "If any app extensions in your containing app include the string `TRUEPREDICATE`, the app will be rejected."

### Handing content to the app

| Step | Detail | Source |
|---|---|---|
| App Group | Add the App Groups capability to both targets; ID must start with `group.`, for example `group.Gunndamental.OpenResponses`; iOS groups must be registered | https://developer.apple.com/documentation/xcode/configuring-app-groups |
| Entitlement | `com.apple.security.application-groups` (array of group IDs) in both targets' `.entitlements` | same page, links to the App Groups Entitlement |
| Shared storage | `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` for files; `UserDefaults(suiteName:)` for small flags | same page |
| Locking | "To avoid data corruption, you must synchronize data accesses. Use Core Data, SQLite, or Posix locks" | archive ExtensionScenarios page |
| Inbox design | The extension writes `Inbox/<uuid>/payload.json` plus attachment files, then completes. The app checks the inbox when `scenePhase` becomes `.active` (OpenResponsesApp.swift already observes `scenePhase`) and opens a new chat with the text and attachments prefilled. Design INFERRED |

### Can the extension open the containing app?

Not through a sanctioned API. `NSExtensionContext.open(_:completionHandler:)`: "Each extension point determines whether to support this method ... In iOS, the Today and iMessage app extension points support this method." Share is not listed [doc_read: https://developer.apple.com/documentation/foundation/nsextensioncontext/open(_:completionhandler:)]. Walking the responder chain to call `UIApplication.open` is not documented; treat it as a review risk (INFERRED). Options:

1. Inbox only (recommended first). The sheet says "Saved to OpenResponses" and the next launch shows the item. Smallest and lowest risk.
2. Answer inside the sheet. The extension calls the Responses API itself and shows the reply. This needs the API key in a shared Keychain access group: add Keychain Sharing (or use the App Group as an access group) to both targets, save the item with `kSecAttrAccessGroup`, and migrate the existing item, because items saved without a group go to the app's private default group, which the extension cannot read [doc_read: https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps]. Changing `KeychainService.save` and `load` is required for this option.

### Memory and time

Not stated in any page read on 2026-11-20 (the archive Share and ExtensionScenarios pages say nothing on memory). INFERRED: share extensions run under a much lower memory ceiling than apps, so decode images with downsampling (`ImageProcessingUtils` already resizes) and copy large files into the App Group container instead of loading them into memory. Measure in Instruments on device before choosing option 2. The macOS 27 and iOS 27 notes on Core AI say Neural Engine memory is now attributed to the app process; not relevant unless on-device models run in the extension.

---

## Question 3: Mac version

### What exists now

`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` is the effective value today [measured]. "After you sign the updated developer agreement, the App Store automatically makes compatible iOS apps available to users of a Mac with Apple silicon", unless "Make this app available on Mac" is turned off in Pricing and Availability [doc_read: https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-in-macos]. Whether OpenResponses is listed on the Mac App Store today was not determined (the App Store Connect attributes read do not include that toggle).

### Comparison

| | Designed for iPad (iOS app on Mac) | Mac Catalyst | Native macOS SwiftUI (multiplatform target) |
|---|---|---|---|
| Build settings that change | None; keep `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES`. Optional Info.plist `UILaunchToFullScreenByDefaultOnMac`, `UISupportsTrueScreenSizeOnMac` (for full-screen apps; not needed) | `SUPPORTS_MACCATALYST = YES` (Xcode General > Supported Destinations > Mac > Mac Catalyst); keep `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER = NO` so the bundle ID stays `Gunndamental.OpenResponses`; Xcode adds the App Sandbox entitlement to the Mac build only; Optimize for Mac switches the idiom to `UIUserInterfaceIdiom.mac` (INFERRED: Xcode writes this as `TARGETED_DEVICE_FAMILY` including `6`); Designed for iPad becomes irrelevant (INFERRED) | Add `macosx` to `SUPPORTED_PLATFORMS`, set `MACOSX_DEPLOYMENT_TARGET` (26.0 matches OpenIntelligence), `ENABLE_APP_SANDBOX = YES`, macOS entitlements; per-file platform filters or `#if os(macOS)` / `#if canImport(UIKit)` |
| Runs on | Apple silicon only | Apple silicon and Intel (Intel apps end with macOS 28 per the macOS 27 notes; irrelevant for new builds) | Apple silicon and Intel |
| UI | iPad metrics, scaled; fixed-size window unless iPad multitasking is adopted (iPad target family includes `2`, so resizable) | Scale Interface to Match iPad (`.pad` idiom, scaled) or Optimize Interface for Mac (`.mac` idiom, AppKit-sized controls; hard-coded sizes need review) | Native controls, menus, Settings scene, `MenuBarExtra` |
| What breaks in this codebase | Nothing at compile time. Runtime to test: `CameraPickerView` (`UIImagePickerController.isSourceTypeAvailable(.camera)` guard exists, CameraPickerView.swift:48); realtime voice (`AVAudioSession` routing, RealtimeService.swift 95-496); haptics no-op; `UIScreen.main.bounds` width math (EnhancedImageView.swift:10, MessageBubbleView.swift:143) assumes a phone-sized screen; `beginBackgroundTask` on scene background (OpenResponsesApp.swift:29) | Compiles almost unchanged because Catalyst is `os(iOS)`: the existing `#if os(iOS)` blocks (OpenAIService.swift 5/445/454, RequestInspectorView.swift 281, VoiceRecorderService.swift 35) stay active. `UIImagePickerController.SourceType.camera` is documented for Mac Catalyst; `AVAudioSession` is Mac Catalyst 13.1+. Same runtime checks as the left column, plus the sandbox: outgoing network, camera, microphone, contacts, calendars and user-selected files need Mac sandbox entitlements (INFERRED names: `com.apple.security.network.client`, `com.apple.security.device.camera`, `com.apple.security.device.audio-input`, `com.apple.security.personal-information.addressbook`, `com.apple.security.personal-information.calendars`, `com.apple.security.files.user-selected.read-write`). Under Optimize for Mac, `UIPageControl` throws (not used, measured by grep) and UIButton or UISlider customizations for non-normal states throw (review) | 52 of 141 Swift files need changes [measured by grep]: 36 use UIKit or AVAudioSession types (`UIImage` 16 files, `UIColor` 9, `UIPasteboard` 6, `UIApplication` 6, `UIGraphicsImageRenderer` 4, the 4 `UIViewControllerRepresentable` pickers and share sheet in ContentView.swift:153, CameraPickerView.swift, ImagePickerView.swift, DocumentPicker.swift, 2 `UIViewRepresentable` in JSONCodeEditor.swift and WebContentView.swift, `AVAudioSession` in RealtimeService.swift and VoiceRecorderService.swift, feedback generators in PlaygroundSettingsPanel.swift and MessageMetadataView.swift, `UIFont` in FileConverterService.swift and JSONCodeEditor.swift, `UIScreen` in 2 files) and 26 use iOS-only SwiftUI modifiers (`navigationBarTitleDisplayMode`, `.topBarLeading`/`.topBarTrailing`, `keyboardType`, `textInputAutocapitalization`). `AVAudioSession` has no macOS (non-Catalyst) availability on its doc page, so realtime audio needs a macOS audio path |
| Keychain | Same as iOS (INFERRED) | INFERRED: Catalyst uses the data protection keychain; the doc says iOS-style access groups apply to macOS items only "when you query with `kSecUseDataProtectionKeychain`" or synchronizable items. Test the existing `openAIKey` read | Add `kSecUseDataProtectionKeychain: true` to `KeychainService.baseQuery` on macOS (doc-backed requirement for group behavior; read on the keychain sharing page) |
| App Shortcuts and intents | Intents run; "App Shortcuts aren't supported in macOS" (HIG) | Same | Same |
| App Store | Same iOS listing; Mac users get the iPad build; toggle in App Store Connect | Same bundle ID allowed: "Apps built with Mac Catalyst using Xcode 11.4 or later can share a bundle ID with the iOS version of the app, supporting universal purchase" [doc_read: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/]. Adds a macOS platform version to the existing record, with its own version and build numbers | Same record, same bundle ID; the help page says macOS builds must be uploaded "from a separate Xcode target" with the bundle ID set to match (INFERRED: a multiplatform target's macOS destination satisfies this, as OpenIntelligence's single target with `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` suggests [code_verified]) |
| Once two platforms are approved | "a single platform version can no longer be removed from the record" (same help page) | same | same |
| Size | S | M | L |

### Recommendation

1. Now (S): run the app as "My Mac (Designed for iPad)" in Xcode, check camera, file import, realtime voice and the Keychain key, and confirm the App Store Connect "Make this app available on Mac" state. This costs no code and tells Gunnar whether Mac users can already install it.
2. Ship (M): Mac Catalyst on the existing target, same bundle ID, first with Scale Interface to Match iPad, then Optimize Interface for Mac once fixed sizes (`UIScreen.main.bounds` math, image widths) are replaced with container-relative sizing. Reasons: the app is SwiftUI with UIKit at the edges, every UIKit and AVFoundation API it uses has Mac Catalyst availability on the pages read, it keeps one target and one binary pipeline, and universal purchase is documented for Catalyst. Mac Catalyst is active in macOS 27 (release notes list a new window-activation behavior and fixes for Mac-idiom apps).
3. Native macOS (L): only if a Mac-specific feature needs AppKit (menu bar extra, multiple windows beyond Catalyst's scenes). Start by wrapping the 36 UIKit files behind small adapters (`PlatformImage`, `Pasteboard`, picker views) so the move is incremental.

---

## Question 4: Other system surfaces, ranked for this app

| Rank | Surface | Why for OpenResponses | Approach | Min OS | Doc |
|---|---|---|---|---|---|
| 1 | App Intents and App Shortcuts | Core of Questions 1 and 2; unlocks Siri, Spotlight actions, Action button, Shortcuts | Question 1 | iOS 16 to 27 | https://developer.apple.com/documentation/appintents/app-shortcuts |
| 2 | Live Activity for a long answer | Comes with `LongRunningIntent` on iOS 27 ("progress updates appear automatically as a Live Activity", with stop). An ActivityKit Live Activity for in-app streaming adds little, because the person is watching the chat | No separate ActivityKit work at first | iOS 27 | https://developer.apple.com/videos/play/wwdc2026/345 |
| 3 | Spotlight | Conversations are the app's main content; `IndexedEntity` "makes them discoverable by Apple Intelligence" and lets Spotlight open them. `ConversationSearchIndex` already extracts message text | `ConversationEntity: IndexedEntity` with `@Property(indexingKey:)` on title and summary, an `OpenIntent` targeting it, `hideInSpotlight` for private chats; `IndexedEntityQuery` (iOS 27) to fetch by ID | iOS 18 | https://developer.apple.com/documentation/appintents/indexedentity |
| 4 | Control Center and Lock Screen control | One-tap "New chat" or "Talk" (Realtime) from anywhere; also the Action button | Widget extension with a `ControlWidget` whose button runs an intent; if the intent lives in the app, `allowedExecutionTargets = .main` (iOS 27) or put it in a shared `AppIntentsPackage` | iOS 18, Mac Catalyst 18, macOS 26 | https://developer.apple.com/documentation/swiftui/controlwidget, https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system (search result) |
| 5 | TipKit | Settings now has about 50 searchable options (commit 6b656a4) and the new Siri phrases are invisible without a hint | `Tip` plus `TipView` or `.popoverTip`; `Tips.configure()` at launch; pair with `SiriTipView` for the phrase | iOS 17 | https://developer.apple.com/documentation/tipkit |
| 6 | Writing Tools | Apple Intelligence Writing Tools apply to `TextField` and `TextEditor` by default (the modifier exists to "customize or disable" it) | Leave the message composer at the default; `.writingToolsBehavior(.disabled)` on JSON schema, code and request inspector fields; the UIKit `JSONCodeEditor` (`UITextView`) needs the UIKit equivalent (INFERRED: `UITextView.writingToolsBehavior`) | iOS 18 | https://developer.apple.com/documentation/swiftui/view/writingtoolsbehavior(_:) |
| 7 | Foundation Models as a model option | Lets the app answer with no API key or offline; but the app's identity is a Responses API playground, and the on-device model has its own session, tool and guided-generation API, so it is a second provider, not another model ID | Later: a provider switch that routes plain chat to `LanguageModelSession(model: SystemLanguageModel.default)` after checking `availability`; three model versions exist (26.0 to 26.3, 26.4, 27.0) so prompts can shift between OS releases. `PrivateCloudComputeLanguageModel` (iOS 27) needs a managed entitlement ("you must meet certain eligibility requirements") | iOS 26 (on-device), iOS 27 (PCC) | https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel, https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel |
| 8 | Widgets | A Home Screen quick-ask button or a "last answer" widget; lower value than a control | `AppIntentConfiguration` widget with a `Button(intent:)` (INFERRED API names; WidgetKit pages not opened) | iOS 17 for interactive widgets (INFERRED) | https://developer.apple.com/documentation/widgetkit |
| 9 | Handoff | Useful only once a Mac version exists; conversations are local files and the `userInfo` payload has size limits (`NSUserActivityHandoffUserInfoTooLargeError`) | `NSUserActivity` with `isEligibleForHandoff`, `appEntityIdentifier` of a conversation entity, `NSUserActivityTypes` in Info.plist | iOS 8 | https://developer.apple.com/documentation/foundation/nsuseractivity |
| 10 | Visual Intelligence | The system "asks apps to match their content against the images it provides"; OpenResponses has no catalog to match, so results would be empty | Skip | iOS 26 (`IntentValueQuery`) | https://developer.apple.com/documentation/appintents/visual-intelligence, https://developer.apple.com/documentation/appintents/intentvaluequery |
| Watch | Siri tool (`ToolIntent`) | Siri could call Ask while handling a request | Revisit when it leaves beta | iOS 27.3 beta | https://developer.apple.com/documentation/appintents/toolintent |

Related notes from the macOS 27 release notes (read 2026-11-20, https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes): `SpotlightSearchTool` with the on-device model needs `.focused()` guides because the default schema exceeds the on-device context window; Shortcuts known issue: intents that use `Duration` or `LPLinkMetadata` can fail with "Describe a change".

## Suggested order of work

1. Ask intent, preset entity, App Shortcuts provider, snippet (M). Gate at iOS 26 or decide to raise the deployment target.
2. Designed for iPad check and App Store Connect toggle (S).
3. Share Extension with App Group inbox (M), then decide on shared Keychain for in-sheet answers.
4. TipKit tip for the Siri phrase and Writing Tools settings (S).
5. Spotlight `IndexedEntity` for conversations (M).
6. Mac Catalyst (M), then Control Center control (M).

## Pages read on 2026-11-20

App Intents: longrunningintent, cancellableintent, progressreportingintent, appintent/supportedmodes, appintent/openappwhenrun, intentfile, snippetintent, displaying-static-and-interactive-snippets, appshortcutsprovider, appshortcutsprovider/appshortcuts, appshortcut, appshortcut/init(intent:phrases:shorttitle:systemimagename:), appshortcutphrase, app-shortcuts, appintentspackage, openintent, configuring-the-runtime-behavior-of-your-app-intents, intentexecutiontargets, longrunningtaskoptions, appintent(_:), toolintent, indexedentity, visual-intelligence, intentvaluequery, updates/appintents. HIG: app-shortcuts. Videos: WWDC26 345 and 310 transcripts. Extensions: technologyoverviews/app-extensions, NSExtensionActivationRule, NSExtensionContext open(_:completionHandler:), archive Share.html and ExtensionScenarios.html (both updated 2017-10-19). Data sharing: xcode/configuring-app-groups, security/sharing-access-to-keychain-items-among-a-collection-of-apps. Mac: apple-silicon/running-your-ios-apps-in-macos, uikit/creating-a-mac-version-of-your-ipad-app, uikit/choosing-a-user-interface-idiom-for-your-mac-app, xcode/configuring-a-multiplatform-app-target, App Store Connect Help add-platforms, macOS 27 release notes, UIImagePickerController.SourceType.camera, AVAudioSession. Other: swiftui/view/writingtoolsbehavior(_:), foundationmodels/systemlanguagemodel, foundationmodels/privatecloudcomputelanguagemodel, swiftui/controlwidget, tipkit, foundation/nsuseractivity.
