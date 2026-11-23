import Foundation

/// OpenResponses Pro (3.1): one non-consumable In-App Purchase that unlocks the features new in 3.1 that run outside
/// the chat screen. Everything that shipped in 2.9 and 3.0 stays free.
///
/// This file is compiled into the app and the share extension (a membership exception in project.pbxproj), so both
/// read the same unlocked state. The app is the only writer: `ProStore` reads StoreKit's current entitlements at
/// launch and on every transaction update and records the result here, in the App Group's defaults, where the share
/// extension (another process) can read it.
nonisolated enum ProAccess {
    /// The product in App Store Connect and in `Config/OpenResponsesPro.storekit`.
    static let productID = "Gunndamental.OpenResponses.pro"
    static let unlockedKey = "proUnlocked"
    /// A locked feature that was tried somewhere without a screen of its own (a shortcut), so the app shows the
    /// paywall for it when it next comes forward.
    static let pendingPaywallKey = "proPendingPaywall"

    enum Feature: String, CaseIterable, Identifiable, Sendable {
        case shortcuts, shareSheet, longCache
        var id: String { rawValue }

        var title: String {
            switch self {
            case .shortcuts: return "Shortcuts and Siri"
            case .shareSheet: return "Share to OpenResponses"
            case .longCache: return "12-hour prompt cache"
            }
        }

        var detail: String {
            switch self {
            case .shortcuts: return "Ask OpenResponses and New Chat from Siri, Spotlight, the Action button and the Shortcuts app."
            case .shareSheet: return "Send text, links, images and files from any app's share sheet into a new chat."
            case .longCache: return "Keep a reused prompt prefix cached for 12 hours instead of 30 minutes."
            }
        }

        var systemImage: String {
            switch self {
            case .shortcuts: return "square.stack.3d.up.fill"
            case .shareSheet: return "square.and.arrow.up"
            case .longCache: return "clock.arrow.circlepath"
            }
        }

        /// What a shortcut or the share sheet says when this feature is locked. It names the way to unlock it.
        var lockedMessage: String {
            "\(title) is part of OpenResponses Pro, a one-time purchase. Open OpenResponses and go to Settings > OpenResponses Pro to unlock it."
        }
    }

    /// The App Group's defaults, shared with the share extension; the app's own defaults if the group is missing
    /// (an unsigned build), so the app still works on its own.
    static var defaults: UserDefaults { UserDefaults(suiteName: SharedInbox.appGroupID) ?? .standard }

    static var isUnlocked: Bool { defaults.bool(forKey: unlockedKey) }

    static func record(unlocked: Bool, in store: UserDefaults = defaults) {
        store.set(unlocked, forKey: unlockedKey)
    }

    /// One verified transaction, reduced to what decides the entitlement.
    struct Entitlement: Equatable, Sendable {
        var productID: String
        var revoked: Bool
    }

    /// Pro is unlocked when a current entitlement for the Pro product was not refunded or revoked. StoreKit's
    /// `currentEntitlements` already leaves refunded and revoked products out (StoreKit reference, read 2026-11-21);
    /// the revocation check is kept so a transaction from `updates` is judged the same way.
    static func isEntitled(_ entitlements: [Entitlement]) -> Bool {
        entitlements.contains { $0.productID == productID && !$0.revoked }
    }

    static func requestPaywall(_ feature: Feature, in store: UserDefaults = defaults) {
        store.set(feature.rawValue, forKey: pendingPaywallKey)
    }

    /// The feature a shortcut asked about, once; nil when none is waiting.
    static func takePendingPaywall(from store: UserDefaults = defaults) -> Feature? {
        guard let raw = store.string(forKey: pendingPaywallKey) else { return nil }
        store.removeObject(forKey: pendingPaywallKey)
        return Feature(rawValue: raw)
    }

    /// A 12-hour cache lifetime saved in a preset is sent only with Pro; without it the request uses OpenAI's
    /// default (30 minutes) rather than failing.
    static func allowedCacheTTL(_ ttl: String?, unlocked: Bool = isUnlocked) -> String? {
        ttl == "12h" && !unlocked ? nil : ttl
    }
}
