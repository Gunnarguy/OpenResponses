import Combine
import Foundation
import StoreKit

/// The OpenResponses Pro purchase, with StoreKit 2 (StoreKit reference on developer.apple.com, read 2026-11-21):
/// `Transaction.currentEntitlements` holds one transaction per non-consumable the customer owns and leaves refunded
/// and revoked ones out; `Transaction.updates` delivers purchases made elsewhere (another device, Ask to Buy, a
/// refund), so it is watched from launch; `AppStore.sync()` is Restore Purchases and shows an App Store sign-in, so it
/// runs only when the person taps Restore. A purchase made on iPhone, iPad or Mac covers all three (one bundle ID).
@MainActor
final class ProStore: ObservableObject {
    static let shared = ProStore()

    @Published private(set) var isPro: Bool
    @Published private(set) var product: Product?
    @Published private(set) var isWorking = false
    @Published var message: String?
    /// Set to show the paywall sheet; ContentView presents it.
    @Published var paywall: ProAccess.Feature?

    private var updates: Task<Void, Never>?

    init() {
        isPro = ProAccess.isUnlocked
    }

    /// Called once at launch: listens for transactions and reads the current entitlements.
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task {
            await refresh()
            await loadProduct()
        }
    }

    func loadProduct() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [ProAccess.productID]).first
        } catch {
            AppLogger.log("Pro product lookup failed: \(error.localizedDescription)", category: .ui, level: .warning)
        }
    }

    /// Re-reads the entitlement from StoreKit and records it for the share extension.
    func refresh() async {
        var entitlements: [ProAccess.Entitlement] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                entitlements.append(.init(productID: transaction.productID, revoked: transaction.revocationDate != nil))
            }
        }
        apply(ProAccess.isEntitled(entitlements))
    }

    func apply(_ unlocked: Bool) {
        isPro = unlocked
        ProAccess.record(unlocked: unlocked)
    }

    /// Handles what `PurchaseAction` returned. Returns true when Pro is now unlocked.
    @discardableResult
    func handle(_ result: Product.PurchaseResult) async -> Bool {
        switch result {
        case .success(.verified(let transaction)):
            await transaction.finish()
            await refresh()
            message = isPro ? nil : "The purchase finished but the App Store didn't confirm it yet. Try Restore Purchases."
        case .success(.unverified(_, let error)):
            message = "The App Store couldn't verify the purchase: \(error.localizedDescription)"
        case .pending:
            message = "The purchase is waiting for approval (Ask to Buy, or a payment check). Pro unlocks as soon as it goes through."
        case .userCancelled:
            message = nil
        @unknown default:
            message = "The App Store returned a result this version doesn't know."
        }
        return isPro
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refresh()
            message = isPro ? nil : "No OpenResponses Pro purchase was found for this Apple Account."
        } catch {
            message = "Restore didn't finish: \(error.localizedDescription)"
        }
    }

    func showPaywall(_ feature: ProAccess.Feature) {
        message = nil
        paywall = feature
    }

    /// For a shortcut: Pro is unlocked when the cached state says so, or, when it doesn't, when StoreKit says so
    /// (a purchase on another device that this one hasn't recorded yet).
    static func checkUnlocked() async -> Bool {
        if ProAccess.isUnlocked { return true }
        await shared.refresh()
        return shared.isPro
    }
}
