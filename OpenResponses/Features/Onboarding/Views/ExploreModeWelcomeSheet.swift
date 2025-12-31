import SwiftUI

/// First-run helper shown when the user has completed onboarding but has not configured an OpenAI API key.
/// Lets users explore the UI safely without making any network calls.
struct ExploreModeWelcomeSheet: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    let openSettings: () -> Void

    private var isMissingOpenAIKey: Bool {
        let key = KeychainService.shared.load(forKey: "openAIKey")
        return key?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    /// When the user has no key and Explore is off, we require an explicit choice:
    /// start the offline demo or open Settings to add a key.
    private var isRequiredFirstRunGate: Bool {
        isMissingOpenAIKey && !viewModel.exploreModeEnabled
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Explore Demo", systemImage: "sparkles")
                            .font(.headline)
                        Text("Try a guided, offline demo conversation. No API calls are made, and you don’t need an API key.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            viewModel.startExploreDemoConversation()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Start Explore Demo")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Connect OpenAI", systemImage: "key.fill")
                            .font(.headline)
                        Text("To generate real responses, add your OpenAI API key. The key is stored only in your iOS Keychain and can be removed anytime.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                openSettings()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Add API Key")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Text("Tip: If you’re new, start with Explore Demo first—then add a key when you’re ready.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isRequiredFirstRunGate)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isRequiredFirstRunGate {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OpenResponses")
                .font(.largeTitle.bold())

            Text("Explore what the app can do, then connect your own OpenAI API key when you’re ready.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ExploreModeWelcomeSheet(openSettings: {})
        .environmentObject(AppContainer.shared.makeChatViewModel())
}
