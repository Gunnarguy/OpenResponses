import SwiftUI
import UIKit

/// The app's own text size, chosen in Settings → Text Size. "Same as iPhone" follows the system setting;
/// any other choice overrides it inside OpenResponses only.
enum AppTextSize {
    static let storageKey = "appTextSize"
    /// Stored value meaning "follow the system setting".
    static let system = "system"

    /// Every size a person can pick, smallest first.
    static let steps: [DynamicTypeSize] = DynamicTypeSize.allCases

    static func storedValue(_ size: DynamicTypeSize) -> String { String(describing: size) }

    static func size(from stored: String) -> DynamicTypeSize? {
        steps.first { storedValue($0) == stored }
    }

    static func name(_ size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Default"
        case .xLarge: return "Large"
        case .xxLarge: return "Extra Large"
        case .xxxLarge: return "Extra Extra Large"
        case .accessibility1: return "Accessibility 1"
        case .accessibility2: return "Accessibility 2"
        case .accessibility3: return "Accessibility 3"
        case .accessibility4: return "Accessibility 4"
        case .accessibility5: return "Accessibility 5"
        @unknown default: return "Custom"
        }
    }

    static func summary(_ stored: String) -> String {
        size(from: stored).map(name) ?? "Same as iPhone"
    }
}

/// Applies the chosen text size to the app's windows. A SwiftUI `.dynamicTypeSize` on the root view does not
/// reach sheets (checked 2026-11-19: Settings stayed at the system size), so the size is set as a trait
/// override on each window, which every sheet presented in it inherits.
struct AppTextSizeModifier: ViewModifier {
    @AppStorage(AppTextSize.storageKey) private var stored = AppTextSize.system
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { apply() }
            .onChange(of: stored) { _, _ in apply() }
            .onChange(of: scenePhase) { _, _ in apply() }
    }

    private func apply() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            if let size = AppTextSize.size(from: stored) {
                window.traitOverrides.preferredContentSizeCategory = UIContentSizeCategory(size)
            } else {
                window.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
            }
        }
    }
}

extension View {
    func appTextSize() -> some View { modifier(AppTextSizeModifier()) }
}

/// Settings → Text Size.
struct TextSizeSettingsView: View {
    @AppStorage(AppTextSize.storageKey) private var stored = AppTextSize.system
    @Environment(\.dynamicTypeSize) private var current

    private var followsSystem: Binding<Bool> {
        Binding(
            get: { AppTextSize.size(from: stored) == nil },
            set: { follow in
                stored = follow ? AppTextSize.system : AppTextSize.storedValue(current)
            }
        )
    }

    private var index: Binding<Double> {
        Binding(
            get: {
                let size = AppTextSize.size(from: stored) ?? current
                return Double(AppTextSize.steps.firstIndex(of: size) ?? 3)
            },
            set: { value in
                let i = min(max(Int(value.rounded()), 0), AppTextSize.steps.count - 1)
                stored = AppTextSize.storedValue(AppTextSize.steps[i])
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Same as iPhone", isOn: followsSystem)
            } footer: {
                Text("On, OpenResponses uses the text size from iPhone Settings → Display & Brightness. Off, the size below applies in this app only.")
            }

            if AppTextSize.size(from: stored) != nil {
                Section {
                    HStack(spacing: 12) {
                        Text("A").font(.footnote).accessibilityHidden(true)
                        Slider(value: index, in: 0...Double(AppTextSize.steps.count - 1), step: 1)
                            .accessibilityLabel("Text size")
                            .accessibilityValue(AppTextSize.summary(stored))
                        Text("A").font(.title2).accessibilityHidden(true)
                    }
                } header: {
                    Text(AppTextSize.summary(stored))
                }
            }

            Section {
                Text("The assistant's answers, your messages and every Settings page use this size.")
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Text Size")
        .navigationBarTitleDisplayMode(.inline)
    }
}
