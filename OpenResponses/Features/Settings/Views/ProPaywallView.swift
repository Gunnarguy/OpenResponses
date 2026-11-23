import StoreKit
import SwiftUI

/// The OpenResponses Pro sheet: what Pro unlocks, the price from the App Store, Buy and Restore Purchases.
/// Shown from Settings > OpenResponses Pro and wherever a locked feature is tapped.
struct ProPaywallView: View {
    @ObservedObject var store: ProStore
    /// The feature that was tapped, listed first; nil from Settings.
    var feature: ProAccess.Feature?
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss

    private var features: [ProAccess.Feature] {
        guard let feature else { return ProAccess.Feature.allCases }
        return [feature] + ProAccess.Feature.allCases.filter { $0 != feature }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: store.isPro ? "checkmark.seal.fill" : "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(store.isPro ? .green : .accentColor)
                            .accessibilityHidden(true)
                        Text(store.isPro ? "OpenResponses Pro is unlocked" : "OpenResponses Pro")
                            .font(.title2.bold())
                        Text(store.isPro
                             ? "Thank you. Pro covers this Apple Account on iPhone, iPad and Mac."
                             : "One purchase, no subscription. It covers iPhone, iPad and Mac. Everything else in the app stays free, and you keep using your own OpenAI key.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Pro unlocks") {
                    ForEach(features) { item in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.headline)
                                Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: item.systemImage)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if !store.isPro {
                    Section {
                        Button {
                            Task { await buy() }
                        } label: {
                            HStack {
                                Text(store.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                                    .font(.headline)
                                Spacer()
                                if store.isWorking { ProgressView() }
                            }
                        }
                        .disabled(store.product == nil || store.isWorking)
                        .accessibilityIdentifier("pro.buy")

                        Button("Restore Purchases") { Task { await store.restore() } }
                            .disabled(store.isWorking)
                            .accessibilityIdentifier("pro.restore")
                    } footer: {
                        if store.product == nil {
                            Text("Getting the price from the App Store…")
                        }
                    }
                }

                if let message = store.message {
                    Section { Text(message).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Pro")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await store.loadProduct() }
        }
    }

    private func buy() async {
        guard let product = store.product else { return }
        do {
            let result = try await purchase(product)
            if await store.handle(result) { dismiss() }
        } catch {
            store.message = "The purchase didn't start: \(error.localizedDescription)"
        }
    }
}
