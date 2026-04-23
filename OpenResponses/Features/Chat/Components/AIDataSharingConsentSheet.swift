import SwiftUI

struct AIDataSharingConsentSheet: View {
    @EnvironmentObject private var viewModel: ChatViewModel

    private let privacyPolicyURL = URL(string: "https://github.com/Gunnarguy/OpenResponses/blob/main/PRIVACY.md")!

    private var request: ChatViewModel.AIDataSharingConsentRequest? {
        viewModel.pendingAIDataSharingConsent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    dataSummary
                    reassuranceBlock
                    Link(destination: privacyPolicyURL) {
                        Label("Read Privacy Policy", systemImage: "lock.shield")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 12) {
                        Button {
                            viewModel.approveAIDataSharingConsent()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Allow & Send")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button(role: .cancel) {
                            viewModel.denyAIDataSharingConsent()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Before You Send")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("OpenAI Data Sharing Notice", systemImage: "externaldrive.badge.icloud")
                .font(.headline)

            Text("OpenResponses sends your request to OpenAI only after you explicitly approve it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var dataSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("If you continue, OpenAI may receive:")
                .font(.subheadline.weight(.medium))

            bullet("The message text you typed")

            if request?.hasFileAttachments == true {
                bullet("Attached documents or files needed for this request")
            }

            if request?.hasImageAttachments == true {
                bullet("Attached images or screenshots")
            }

            if request?.usesEnabledTools == true {
                bullet("Request-related tool inputs or outputs needed to complete your task")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var reassuranceBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            bullet("Nothing is sent until you tap Allow & Send.")
            bullet("Explore Demo stays offline and does not make OpenAI API calls.")
            bullet("Your OpenAI API key is stored locally in the iOS Keychain.")
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.caption)
                .padding(.top, 2)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AIDataSharingConsentSheet()
        .environmentObject(AppContainer.shared.makeChatViewModel())
}
