import Combine
import Foundation

/// Decides when the app asks for an App Store rating with Apple's own sheet (`requestReview`), the only way it asks.
///
/// When: on the first answer that finished cleanly with the person's own API key, or on the third finished answer of
/// any kind, whichever comes first. Once per app version, and never within 14 days of the last ask (Human Interface
/// Guidelines, Ratings and reviews: "a week or two between requests"). Never at launch, never during onboarding, never
/// in Explore Demo, never from a button, never under tests.
///
/// Apple shows the sheet at most three times in 365 days on a device and decides itself whether to show it at all, so
/// this decides only when to ask (`RequestReviewAction`, read 2026-11-14, and confirmed in the iOS 27.0 SDK's
/// `_StoreKit_SwiftUI.swiftinterface`: iOS 16.0 and later, `@MainActor callAsFunction()`).
///
/// Until 3.0 the app never asked: on 2026-11-14 it had 359 first-time downloads and 1 US rating.
@MainActor
final class ReviewPromptService: ObservableObject {
    static let shared = ReviewPromptService()

    /// How a chat turn ended, read from the conversation's last message.
    enum Outcome: Equatable {
        /// Nothing to count: Explore Demo, an error or notice, a stopped answer, an empty one, or one still waiting
        /// for an approval.
        case none
        /// An answer with text, where a tool step failed or was cancelled on the way.
        case finished
        /// An answer with text and no failed or cancelled tool step.
        case clean
    }

    /// Flipped true when the next good moment arrives; ContentView consumes it.
    @Published private(set) var wantsPrompt = false

    private let defaults: UserDefaults
    private let cleanKey = "reviewPrompt.cleanAnswers"
    private let finishedKey = "reviewPrompt.finishedAnswers"
    private let lastAskedKey = "reviewPrompt.lastAskedAt"
    private let lastAskedVersionKey = "reviewPrompt.lastAskedVersion"
    nonisolated static let minimumCleanAnswers = 1
    nonisolated static let minimumFinishedAnswers = 3
    nonisolated static let minimumDaysBetweenAsks = 14.0
    /// The text `ChatViewModel.cancelStreaming` appends to an answer the person stopped.
    nonisolated static let cancelledMarker = "[Streaming cancelled by user]"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// ContentView calls this each time a chat turn stops streaming.
    func noteTurnEnded(lastMessage: ChatMessage?, exploreDemo: Bool) {
        let outcome = Self.outcome(of: lastMessage, exploreDemo: exploreDemo)
        guard outcome != .none else { return }
        let finished = defaults.integer(forKey: finishedKey) + 1
        defaults.set(finished, forKey: finishedKey)
        var clean = defaults.integer(forKey: cleanKey)
        if outcome == .clean {
            clean += 1
            defaults.set(clean, forKey: cleanKey)
        }
        let lastAsked = defaults.double(forKey: lastAskedKey)
        guard
            Self.shouldAsk(
                thisAnswerIsClean: outcome == .clean, cleanAnswers: clean, finishedAnswers: finished,
                lastAskedVersion: defaults.string(forKey: lastAskedVersionKey), currentVersion: Self.currentVersion,
                daysSinceLastAsk: lastAsked > 0 ? (Date().timeIntervalSince1970 - lastAsked) / 86_400 : nil,
                isTesting: Self.isTesting)
        else { return }
        wantsPrompt = true
    }

    /// ContentView calls this once it has handed the request to StoreKit, and only then.
    func didAsk() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastAskedKey)
        defaults.set(Self.currentVersion, forKey: lastAskedVersionKey)
        wantsPrompt = false
    }

    /// Pure, so every rule above is pinned by a test. Counts include the answer that just finished.
    nonisolated static func shouldAsk(
        thisAnswerIsClean: Bool, cleanAnswers: Int, finishedAnswers: Int, lastAskedVersion: String?,
        currentVersion: String, daysSinceLastAsk: Double?, isTesting: Bool
    ) -> Bool {
        guard !isTesting, !currentVersion.isEmpty, lastAskedVersion != currentVersion else { return false }
        if let days = daysSinceLastAsk, days < minimumDaysBetweenAsks { return false }
        return (thisAnswerIsClean && cleanAnswers >= minimumCleanAnswers) || finishedAnswers >= minimumFinishedAnswers
    }

    /// Pure. A failed turn ends on a system message (`ChatViewModel.handleError`), so only an assistant message with
    /// text counts.
    nonisolated static func outcome(of message: ChatMessage?, exploreDemo: Bool) -> Outcome {
        guard !exploreDemo, let message, message.role == .assistant else { return .none }
        let text = (message.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.hasSuffix(cancelledMarker) else { return .none }
        if message.mcpApprovalRequests?.contains(where: { $0.status == .pending }) == true { return .none }
        let steps = message.toolTimeline ?? []
        if steps.contains(where: { $0.status == .awaitingApproval || $0.status == .running || $0.status == .queued }) {
            return .none
        }
        return steps.contains(where: { $0.status == .failed || $0.status == .cancelled }) ? .finished : .clean
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private static var isTesting: Bool {
        // The UI tests launch in Explore Demo, which never counts an answer.
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
