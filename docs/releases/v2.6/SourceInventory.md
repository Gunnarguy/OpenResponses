# OpenResponses 2.6: source inventory

Captured September 8, 2026. Primary baseline: `855ab3b4aac8f19b487757c269e2e0a20d2cbb02`. Committed target: `bf5a783f7912b9e12f37e88e63c5c6891412eb94` plus the current implementation working tree.

This inventory includes **129 app, test and Xcode-project files: 64 added and 65 modified**. It excludes documentation, generated output, dependencies and build artifacts. A changed file may contain both earlier development and September fixes. File counts are not feature counts. [SourceSnapshot.json](SourceSnapshot.json) records the SHA-256 of each current file so the documented implementation can be identified even before it is committed.

## Phase definitions

- **Earlier v2.6:** changed between the baseline and committed HEAD.
- **September:** changed only in the implementation working tree, including new untracked source.
- **Earlier v2.6 + September:** changed in both intervals.

## File inventory

| File | Change from baseline | Development phase |
| --- | --- | --- |
| [OpenResponses.xcodeproj/project.pbxproj](../../../OpenResponses.xcodeproj/project.pbxproj) | Modified | Earlier v2.6 + September |
| [OpenResponses/App/AppLogger.swift](../../../OpenResponses/App/AppLogger.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/App/ContentView.swift](../../../OpenResponses/App/ContentView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/App/OpenResponsesApp.swift](../../../OpenResponses/App/OpenResponsesApp.swift) | Modified | September |
| [OpenResponses/Core/Models/APICapabilities.swift](../../../OpenResponses/Core/Models/APICapabilities.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Models/AppleDataModels.swift](../../../OpenResponses/Core/Models/AppleDataModels.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Models/AssistantsModels.swift](../../../OpenResponses/Core/Models/AssistantsModels.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Models/BatchModels.swift](../../../OpenResponses/Core/Models/BatchModels.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Models/ChatMessage.swift](../../../OpenResponses/Core/Models/ChatMessage.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Models/ComputerModels.swift](../../../OpenResponses/Core/Models/ComputerModels.swift) | Modified | September |
| [OpenResponses/Core/Models/Conversation.swift](../../../OpenResponses/Core/Models/Conversation.swift) | Modified | September |
| [OpenResponses/Core/Models/ConversationAPIModels.swift](../../../OpenResponses/Core/Models/ConversationAPIModels.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Models/CurrentModelCatalog.swift](../../../OpenResponses/Core/Models/CurrentModelCatalog.swift) | Added | September |
| [OpenResponses/Core/Models/FineTuningModels.swift](../../../OpenResponses/Core/Models/FineTuningModels.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Models/JSONLDocument.swift](../../../OpenResponses/Core/Models/JSONLDocument.swift) | Added | September |
| [OpenResponses/Core/Models/MCPProvider.swift](../../../OpenResponses/Core/Models/MCPProvider.swift) | Added | September |
| [OpenResponses/Core/Models/OpenAIModel.swift](../../../OpenResponses/Core/Models/OpenAIModel.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Models/Prompt.swift](../../../OpenResponses/Core/Models/Prompt.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Models/ResponseModels.swift](../../../OpenResponses/Core/Models/ResponseModels.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Models/ResponseSettingDescriptor.swift](../../../OpenResponses/Core/Models/ResponseSettingDescriptor.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Models/ResponseSettingsRegistry.swift](../../../OpenResponses/Core/Models/ResponseSettingsRegistry.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Core/Protocols/AssistantsServiceProtocol.swift](../../../OpenResponses/Core/Protocols/AssistantsServiceProtocol.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Protocols/OpenAIServiceProtocol.swift](../../../OpenResponses/Core/Protocols/OpenAIServiceProtocol.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Services/APIWorkbenchDraftStore.swift](../../../OpenResponses/Core/Services/APIWorkbenchDraftStore.swift) | Added | September |
| [OpenResponses/Core/Services/APIWorkbenchSession.swift](../../../OpenResponses/Core/Services/APIWorkbenchSession.swift) | Added | September |
| [OpenResponses/Core/Services/AppleCalendarRepository.swift](../../../OpenResponses/Core/Services/AppleCalendarRepository.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/AppleReminderRepository.swift](../../../OpenResponses/Core/Services/AppleReminderRepository.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/AssistantsService.swift](../../../OpenResponses/Core/Services/AssistantsService.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Services/BatchService.swift](../../../OpenResponses/Core/Services/BatchService.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Core/Services/BrowserDOM.swift](../../../OpenResponses/Core/Services/BrowserDOM.swift) | Added | September |
| [OpenResponses/Core/Services/BrowserExecution.swift](../../../OpenResponses/Core/Services/BrowserExecution.swift) | Added | September |
| [OpenResponses/Core/Services/ComputerService.swift](../../../OpenResponses/Core/Services/ComputerService.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Services/ContactsPermissionManager.swift](../../../OpenResponses/Core/Services/ContactsPermissionManager.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/ContactsRepository.swift](../../../OpenResponses/Core/Services/ContactsRepository.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/ConversationStorageService.swift](../../../OpenResponses/Core/Services/ConversationStorageService.swift) | Modified | September |
| [OpenResponses/Core/Services/FileConverterService.swift](../../../OpenResponses/Core/Services/FileConverterService.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/FineTuningService.swift](../../../OpenResponses/Core/Services/FineTuningService.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Core/Services/KeychainService.swift](../../../OpenResponses/Core/Services/KeychainService.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/MCPAuthorization.swift](../../../OpenResponses/Core/Services/MCPAuthorization.swift) | Added | September |
| [OpenResponses/Core/Services/MCPConfigurationService.swift](../../../OpenResponses/Core/Services/MCPConfigurationService.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Services/MCPConnectionStore.swift](../../../OpenResponses/Core/Services/MCPConnectionStore.swift) | Added | September |
| [OpenResponses/Core/Services/MCPDiscoveryService.swift](../../../OpenResponses/Core/Services/MCPDiscoveryService.swift) | Added | September |
| [OpenResponses/Core/Services/MCPDiscoveryStream.swift](../../../OpenResponses/Core/Services/MCPDiscoveryStream.swift) | Added | September |
| [OpenResponses/Core/Services/MCPRegistryService.swift](../../../OpenResponses/Core/Services/MCPRegistryService.swift) | Added | September |
| [OpenResponses/Core/Services/MCPWebAuthentication.swift](../../../OpenResponses/Core/Services/MCPWebAuthentication.swift) | Added | September |
| [OpenResponses/Core/Services/ModelCompatibilityService.swift](../../../OpenResponses/Core/Services/ModelCompatibilityService.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Services/NotionService.swift](../../../OpenResponses/Core/Services/NotionService.swift) | Modified | September |
| [OpenResponses/Core/Services/OpenAIService.swift](../../../OpenResponses/Core/Services/OpenAIService.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Core/Services/RealtimeAudioPipeline.swift](../../../OpenResponses/Core/Services/RealtimeAudioPipeline.swift) | Added | September |
| [OpenResponses/Core/Services/RealtimeService.swift](../../../OpenResponses/Core/Services/RealtimeService.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Core/Services/ResourcePagination.swift](../../../OpenResponses/Core/Services/ResourcePagination.swift) | Added | September |
| [OpenResponses/Core/Services/ResponseConfigurationValidation.swift](../../../OpenResponses/Core/Services/ResponseConfigurationValidation.swift) | Added | September |
| [OpenResponses/Core/Services/ResponseSocketRunner.swift](../../../OpenResponses/Core/Services/ResponseSocketRunner.swift) | Added | September |
| [OpenResponses/Core/Services/ResponseTurnRunner.swift](../../../OpenResponses/Core/Services/ResponseTurnRunner.swift) | Added | September |
| [OpenResponses/Core/Services/ResponsesAPIClient.swift](../../../OpenResponses/Core/Services/ResponsesAPIClient.swift) | Added | September |
| [OpenResponses/Core/Services/VectorStoreIndexing.swift](../../../OpenResponses/Core/Services/VectorStoreIndexing.swift) | Added | September |
| [OpenResponses/Core/Services/VoiceRecorderService.swift](../../../OpenResponses/Core/Services/VoiceRecorderService.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/GoogleProviders.swift](../../../OpenResponses/Core/ToolProviders/GoogleProviders.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/NotionModels.swift](../../../OpenResponses/Core/ToolProviders/NotionModels.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/NotionProvider+Connect.swift](../../../OpenResponses/Core/ToolProviders/NotionProvider+Connect.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/NotionProvider.swift](../../../OpenResponses/Core/ToolProviders/NotionProvider.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/ToolProvider.swift](../../../OpenResponses/Core/ToolProviders/ToolProvider.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/ToolProviders/ToolProviderTypes.swift](../../../OpenResponses/Core/ToolProviders/ToolProviderTypes.swift) | Added | Earlier v2.6 |
| [OpenResponses/Core/Utilities/AppFeatureFlags.swift](../../../OpenResponses/Core/Utilities/AppFeatureFlags.swift) | Modified | September |
| [OpenResponses/Core/Utilities/ImageProcessingUtils.swift](../../../OpenResponses/Core/Utilities/ImageProcessingUtils.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Core/Utilities/MCPApprovalUtils.swift](../../../OpenResponses/Core/Utilities/MCPApprovalUtils.swift) | Modified | September |
| [OpenResponses/Core/Utilities/URLDetector.swift](../../../OpenResponses/Core/Utilities/URLDetector.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/AttachmentPills.swift](../../../OpenResponses/Features/Chat/Components/AttachmentPills.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/ChatInputView.swift](../../../OpenResponses/Features/Chat/Components/ChatInputView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/ChatStatusBar.swift](../../../OpenResponses/Features/Chat/Components/ChatStatusBar.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/DynamicModelSelector.swift](../../../OpenResponses/Features/Chat/Components/DynamicModelSelector.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/FileManagerView.swift](../../../OpenResponses/Features/Chat/Components/FileManagerView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/FormattedTextView.swift](../../../OpenResponses/Features/Chat/Components/FormattedTextView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/ImagePickerView.swift](../../../OpenResponses/Features/Chat/Components/ImagePickerView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/InlineVoiceView.swift](../../../OpenResponses/Features/Chat/Components/InlineVoiceView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/JSONCodeEditor.swift](../../../OpenResponses/Features/Chat/Components/JSONCodeEditor.swift) | Added | September |
| [OpenResponses/Features/Chat/Components/MessageBubbleView.swift](../../../OpenResponses/Features/Chat/Components/MessageBubbleView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Chat/Components/MessageMetadataView.swift](../../../OpenResponses/Features/Chat/Components/MessageMetadataView.swift) | Modified | September |
| [OpenResponses/Features/Chat/Components/PlaygroundSettingsPanel.swift](../../../OpenResponses/Features/Chat/Components/PlaygroundSettingsPanel.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/RequestInspectorView.swift](../../../OpenResponses/Features/Chat/Components/RequestInspectorView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/ToolTimelineView.swift](../../../OpenResponses/Features/Chat/Components/ToolTimelineView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Components/VectorStoreSmartUploadView.swift](../../../OpenResponses/Features/Chat/Components/VectorStoreSmartUploadView.swift) | Modified | September |
| [OpenResponses/Features/Chat/ViewModels/ChatViewModel+Streaming.swift](../../../OpenResponses/Features/Chat/ViewModels/ChatViewModel+Streaming.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/ViewModels/ChatViewModel.swift](../../../OpenResponses/Features/Chat/ViewModels/ChatViewModel.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/ViewModels/ManagedResponsePresentation.swift](../../../OpenResponses/Features/Chat/ViewModels/ManagedResponsePresentation.swift) | Added | September |
| [OpenResponses/Features/Chat/Views/ChatView.swift](../../../OpenResponses/Features/Chat/Views/ChatView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Views/CreateAssistantSheet.swift](../../../OpenResponses/Features/Chat/Views/CreateAssistantSheet.swift) | Added | Earlier v2.6 |
| [OpenResponses/Features/Chat/Views/MCPApprovalView.swift](../../../OpenResponses/Features/Chat/Views/MCPApprovalView.swift) | Modified | September |
| [OpenResponses/Features/Chat/Views/VoiceModeSettingsSheet.swift](../../../OpenResponses/Features/Chat/Views/VoiceModeSettingsSheet.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Chat/Views/VoiceModeView.swift](../../../OpenResponses/Features/Chat/Views/VoiceModeView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Compatibility/ModelCompatibilityView.swift](../../../OpenResponses/Features/Compatibility/ModelCompatibilityView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Conversations/Views/ConversationListView.swift](../../../OpenResponses/Features/Conversations/Views/ConversationListView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/DebugTools/Views/DebugConsoleView.swift](../../../OpenResponses/Features/DebugTools/Views/DebugConsoleView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/DebugTools/Views/WebContentView.swift](../../../OpenResponses/Features/DebugTools/Views/WebContentView.swift) | Modified | Earlier v2.6 |
| [OpenResponses/Features/Onboarding/Views/ModelConfigurationView.swift](../../../OpenResponses/Features/Onboarding/Views/ModelConfigurationView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Onboarding/Views/OnboardingView.swift](../../../OpenResponses/Features/Onboarding/Views/OnboardingView.swift) | Modified | September |
| [OpenResponses/Features/Settings/Views/APIWorkbenchView.swift](../../../OpenResponses/Features/Settings/Views/APIWorkbenchView.swift) | Added | September |
| [OpenResponses/Features/Settings/Views/BatchJobsView.swift](../../../OpenResponses/Features/Settings/Views/BatchJobsView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Settings/Views/FineTuningView.swift](../../../OpenResponses/Features/Settings/Views/FineTuningView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Settings/Views/LegacyMigrationLabView.swift](../../../OpenResponses/Features/Settings/Views/LegacyMigrationLabView.swift) | Added | Earlier v2.6 + September |
| [OpenResponses/Features/Settings/Views/MCPConnectionsView.swift](../../../OpenResponses/Features/Settings/Views/MCPConnectionsView.swift) | Added | September |
| [OpenResponses/Features/Settings/Views/MCPConnectorGalleryView.swift](../../../OpenResponses/Features/Settings/Views/MCPConnectorGalleryView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Settings/Views/MCPDiscoverySection.swift](../../../OpenResponses/Features/Settings/Views/MCPDiscoverySection.swift) | Added | September |
| [OpenResponses/Features/Settings/Views/ModernResponseSettings.swift](../../../OpenResponses/Features/Settings/Views/ModernResponseSettings.swift) | Added | September |
| [OpenResponses/Features/Settings/Views/RemoteMCPSetupSheet.swift](../../../OpenResponses/Features/Settings/Views/RemoteMCPSetupSheet.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Settings/Views/SettingsHomeView.swift](../../../OpenResponses/Features/Settings/Views/SettingsHomeView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Features/Tools/Views/ToolConnectionsView.swift](../../../OpenResponses/Features/Tools/Views/ToolConnectionsView.swift) | Modified | Earlier v2.6 + September |
| [OpenResponses/Info.plist](../../../OpenResponses/Info.plist) | Added | September |
| [OpenResponses/Resources/Localization/Localizable.xcstrings](../../../OpenResponses/Resources/Localization/Localizable.xcstrings) | Modified | Earlier v2.6 + September |
| [OpenResponsesTests/AppCompletionTests.swift](../../../OpenResponsesTests/AppCompletionTests.swift) | Added | September |
| [OpenResponsesTests/AppleDateUtilitiesTests.swift](../../../OpenResponsesTests/AppleDateUtilitiesTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/BrowserExecutionTests.swift](../../../OpenResponsesTests/BrowserExecutionTests.swift) | Added | September |
| [OpenResponsesTests/ChatViewModelLifecycleTests.swift](../../../OpenResponsesTests/ChatViewModelLifecycleTests.swift) | Modified | Earlier v2.6 + September |
| [OpenResponsesTests/DateFormattingTests.swift](../../../OpenResponsesTests/DateFormattingTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/FunctionOutputSummarizerTests.swift](../../../OpenResponsesTests/FunctionOutputSummarizerTests.swift) | Modified | Earlier v2.6 |
| [OpenResponsesTests/ImageProcessingUtilsTests.swift](../../../OpenResponsesTests/ImageProcessingUtilsTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/MCPApprovalUtilsTests.swift](../../../OpenResponsesTests/MCPApprovalUtilsTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/MCPSecretPersistenceTests.swift](../../../OpenResponsesTests/MCPSecretPersistenceTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/OAuthCallbackValidationTests.swift](../../../OpenResponsesTests/OAuthCallbackValidationTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/OpenAIServiceTests.swift](../../../OpenResponsesTests/OpenAIServiceTests.swift) | Modified | September |
| [OpenResponsesTests/OpenResponsesTests.swift](../../../OpenResponsesTests/OpenResponsesTests.swift) | Modified | Earlier v2.6 + September |
| [OpenResponsesTests/OptionalStringHelpersTests.swift](../../../OpenResponsesTests/OptionalStringHelpersTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/ResponseSettingsRegistryTests.swift](../../../OpenResponsesTests/ResponseSettingsRegistryTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/StreamingEventDecodingTests.swift](../../../OpenResponsesTests/StreamingEventDecodingTests.swift) | Modified | September |
| [OpenResponsesTests/StreamingTerminationTests.swift](../../../OpenResponsesTests/StreamingTerminationTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/UIImageExtensionsTests.swift](../../../OpenResponsesTests/UIImageExtensionsTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/URLDetectorTests.swift](../../../OpenResponsesTests/URLDetectorTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/URLRedactionTests.swift](../../../OpenResponsesTests/URLRedactionTests.swift) | Added | Earlier v2.6 |
| [OpenResponsesTests/WebContentNavigationPolicyTests.swift](../../../OpenResponsesTests/WebContentNavigationPolicyTests.swift) | Added | Earlier v2.6 |

## Committed development chronology

These are the 57 reachable commits after the primary baseline, including merges. Commit subjects describe historical intent; the current technical notes describe the final implementation and supersede retired intermediate behavior.

| Commit | Date | Subject |
| --- | --- | --- |
| `e77e889` | 2026-06-25 | Version 2.6 Staging |
| `e3c0136` | 2026-06-25 | 🔒 fix: prevent test.env from being bundled into release builds (#50) |
| `6d1d000` | 2026-06-25 | ⚡ Optimize concurrent file uploading in FileManagerView (#49) |
| `88e8e7d` | 2026-06-25 | Fix: complete streaming state reset on computer tool error (#48) |
| `bc0b748` | 2026-06-25 | Optimize string concatenation in FileConverterService (#47) |
| `6e94c71` | 2026-06-25 | Optimize array allocations in OpenAI streaming parser (#46) |
| `74ac1ff` | 2026-06-25 | 🧪 Add tests for AppleDateUtilities.parseQueryDate (#44) |
| `89e3023` | 2026-06-25 | perf: optimize database metadata fetch in NotionProvider (#43) |
| `f0813d8` | 2026-06-25 | 🧪 Improve URLDetector.isRenderableWebpage test coverage (#42) |
| `1b8d9c5` | 2026-06-25 | ⚡ Optimize linked database fetching in NotionProvider (#41) |
| `5db27cc` | 2026-06-25 | 🧪 Add tests for URLDetector URL detection methods (#40) |
| `36f8a57` | 2026-06-25 | 🧪 [Added tests for ChatMessage.withURLDetection] (#37) |
| `1b304f5` | 2026-06-25 | fix(chat): reset streaming status and notify user on computer_call_output network failure (#35) |
| `9faa6d7` | 2026-06-25 | ⚡ Optimize fallback image fetching in ChatViewModel (#34) |
| `205324d` | 2026-06-25 | Optimize artifactType lookups using static Sets for O(1) performance (#33) |
| `d164d9c` | 2026-06-25 | ⚡ Optimize sequential image downloads in ChatViewModel (#32) |
| `8ea1a7a` | 2026-06-25 | Add tests for AppleDateUtilities.parseISO8601 (#31) |
| `f0307bc` | 2026-06-25 | 🧪 [testing improvement] Add tests for AppleDateUtilities.makeReminderDateComponents (#30) |
| `18445e2` | 2026-06-25 | 🧪 [testing improvement] Add tests for URLDetector.detectURLs (#28) |
| `ecc09f2` | 2026-06-25 | 🧪 Add tests for URLDetector.extractImageLinks edge cases (#27) |
| `aec4af6` | 2026-06-25 | 🧹 Fix unsafe force unwraps in APICapabilities decoder (#26) |
| `3443723` | 2026-06-25 | Add malformed JSON test to FunctionOutputSummarizer (#25) |
| `4179011` | 2026-06-25 | 🧹 Fix unsafe force unwrap in APICapabilities Decoder (#24) |
| `c46bd97` | 2026-06-25 | 🧪 Add tests for MCPApprovalUtils.buildTextFromApprovalRequests (#23) |
| `a0cd6b4` | 2026-06-25 | 🧪 Add unit tests for OpenAIModel.displayName (#22) |
| `4962773` | 2026-06-25 | 🧹 [Code Health] Remove unnecessary delete and map operations (#20) |
| `423f43f` | 2026-06-25 | Fix CI failure: merge redundant AppleDateUtilitiesTests and update URLDetector tests for new strict URL handling |
| `2c1523a` | 2026-06-25 | 🧹 [Code Health] Remove leftover automated PR garbage files (.orig, .patch, .txt) |
| `eadbe53` | 2026-06-25 | chore: add missing test file references to Xcode project |
| `25ec532` | 2026-06-25 | Resolve strict concurrency compiler errors and warnings under Swift 6 mode |
| `6890ece` | 2026-06-25 | Fix Swift 6 strict concurrency errors in AppLogger and NotionProvider |
| `377fc22` | 2026-06-25 | Fix strict concurrency warnings across Notion, Keychain, Contacts, ImagePicker, and WebView |
| `181fafb` | 2026-06-26 | Refactor ChatStatusBar, ModelCompatibilityView, and SettingsHomeView toggles to prevent label wrapping/truncation |
| `89c5050` | 2026-06-26 | Fix CI actions build failure by using setup-xcode action and generic iOS Simulator destination |
| `3d464b9` | 2026-06-27 | feat: integrate Assistants, Batch, and Fine-Tuning into UI & optimize Realtime Voice Mode |
| `07f80a1` | 2026-06-27 | feat: finalize dynamic settings registry, inline tool execution cards, legacy Assistants lab, and stabilize Realtime voice mode |
| `38117e0` | 2026-07-10 | chore(repo): initialize PR audit control files and manifest |
| `1c2bcb0` | 2026-07-10 | Consolidate and fix 24 open Jules PRs (#53-#76) |
| `1b6438c` | 2026-07-10 | Merge pull request #77 from Gunnarguy/audit/openresponses-jules-prs-2026-07-10 |
| `bc9cf86` | 2026-07-10 | docs: Update README to move MCP feature to Completed (Phase 1) |
| `cf90261` | 2026-07-10 | Complete Phase 2: Remote Conversations & Rich Annotations |
| `7b06777` | 2026-07-10 | Update README docs to mark Phase 2 and Phase 3 as completed |
| `1e2edda` | 2026-07-10 | Integrate GPT-5.6 family models (Sol, Terra, Luna) |
| `df26439` | 2026-07-11 | Fix GPT-5.6 integration parameters (verbosity, prompt caching, max reasoning effort) |
| `711ea6f` | 2026-07-11 | Fix syntax and redeclaration errors for verbosity |
| `d0836df` | 2026-07-11 | fix: resolve optional binding compiler error for verbosity in OpenAIService.swift |
| `ac4175a` | 2026-07-11 | docs: Update App Store release plan and CI/CD docs for Xcode Cloud and v2.6 |
| `46aeab6` | 2026-07-11 | fix(OpenAI): Remove duplicate root verbosity parameter from Responses API request |
| `3a613cf` | 2026-07-11 | feat(UI): Add interactive model picker to ChatStatusBar and handle 405 listing error gracefully |
| `cb76ebb` | 2026-07-11 | docs: Add Release Notes for version 2.6.0 and update README references |
| `b52df91` | 2026-07-11 | feat(UI): Add gpt-5.6, reasoning summary, and verbosity parameters to PlaygroundSettingsPanel |
| `3c06def` | 2026-07-12 | fix: resolve compaction model parameters, disable temperature on reasoning models, dynamic reasoning picker, and update realtime voice models |
| `a1d6947` | 2026-07-12 | fix(Realtime): optimize chunking frequency and implement customizable Voice Barge-In VAD protection |
| `d423b1d` | 2026-07-12 | fix: enforce lowercase normalization for model IDs, add gpt-5.6 family prefixes to capabilities fallback list, and handle compaction response not found errors gracefully |
| `1c8bd9d` | 2026-07-12 | fix(Realtime): transition state back to Listening on response.done to resume mic input transmission |
| `69ccc97` | 2026-07-12 | fix(Realtime): add 800ms speaker playback cooldown after response.done to eliminate tail audio feedback |
| `bf5a783` | 2026-09-02 | docs: solo voice, not a team |

## Late changes while the source still declared v2.5

ASC confirms released v2.5 used uploaded **build 4** on June 19. The local source version-bump commit used build 7; source and Xcode Cloud upload build numbers are different. The retained CI records do not identify the exact source SHA for the released build. Therefore the main inventory uses the last explicitly labeled v2.5 source state, and this additional interval is preserved so likely post-upload work is not lost. Do not describe these changes as proven to be in the shipped v2.5 binary.

Between `de7df81` (the June 19 source version bump) and `855ab3b` (June 25), development added request/body/header/token/cookie redaction and fixed test deadlocks, URL ordering, concurrency and duplicate iCloud conflict files. A temporary telemetry addition was reverted. These ten commits are outside the primary 129-file delta:

| Commit | Date | Subject |
| --- | --- | --- |
| `57dd4db` | 2026-06-23 | chore(telemetry): inject Firebase SDK initialization |
| `1ff01d6` | 2026-06-23 | fix(ci): revert telemetry injection until SPM package is linked |
| `67b0131` | 2026-06-23 | fix(ci): remove duplicate sync conflict swift files causing redeclaration errors |
| `5216078` | 2026-06-23 | fix(ci): restore ChatViewModel concurrency semantics |
| `d96854a` | 2026-06-24 | 🔒 [Security Fix] Redact sensitive keys in AppLogger |
| `314baae` | 2026-06-24 | 🔒 Fix explicit token and cookie leakage in OpenAI response logging |
| `a9c4792` | 2026-06-25 | fix(security): redact sensitive headers, resolve test suite deadlock, and fix URLDetector order bugs |
| `16b5f37` | 2026-06-25 | Merge PR 52: generic HTTP header redaction and test fixes |
| `b2f39c5` | 2026-06-25 | Merge branch 'main' into jules-17347710159993976695-52f2056e |
| `855ab3b` | 2026-06-25 | Merge PR 51: request body sensitive key redaction and test fixes |

### Files changed in the late v2.5 source interval

These five paths changed between `de7df81` and `855ab3b`. They supplement the primary comparison; overlapping paths must not be counted twice. The Cloud manifest associates the project with its Cloud product, while the Swift/test changes cover diagnostics redaction and URL/test reliability.

| File | Change in this interval |
| --- | --- |
| [Xcode Cloud manifest](../../../OpenResponses.xcodeproj/xcshareddata/xcodecloud/manifest.json) | Added |
| [AppLogger.swift](../../../OpenResponses/App/AppLogger.swift) | Modified |
| [URLDetector.swift](../../../OpenResponses/Core/Utilities/URLDetector.swift) | Modified |
| [AppLoggerTests.swift](../../../OpenResponsesTests/AppLoggerTests.swift) | Modified |
| [OpenResponsesTests.swift](../../../OpenResponsesTests/OpenResponsesTests.swift) | Modified |

## Release identity and delivery

The July `v2.6.0` tag points to `1e2edda`, before later work. ASC/Xcode Cloud identifies uploaded v2.6 build 38 with committed HEAD `bf5a783`; it does not include the working-tree implementation documented here. See [ASC status](ASCStatus.md) and [validation](Validation.md).

The snapshot records source only: it contains no API credentials, private signing keys, device conversation contents or request payloads.
