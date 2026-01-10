//
//  AboutView.swift
//  OpenResponses
//
//  Created for App Store release - displays app information and licenses
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    // Read version from bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Info Section
                    appInfoSection

                    Divider()

                    // Links Section
                    linksSection

                    Divider()

                    // License Section
                    licenseSection

                    Divider()

                    // Acknowledgments
                    acknowledgementsSection

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var appInfoSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
                .padding(.bottom, 8)

            Text("OpenResponses")
                .font(.title2)
                .fontWeight(.bold)

            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("An intelligent AI assistant powered by OpenAI's latest models")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }

    private var linksSection: some View {
        VStack(spacing: 12) {
            Link(destination: URL(string: "https://github.com/Gunnarguy/OpenResponses/blob/main/PRIVACY.md")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "lock.shield")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "https://github.com/Gunnarguy/OpenResponses/issues")!) {
                HStack {
                    Label("Support (GitHub)", systemImage: "questionmark.circle")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    private var licenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("License", systemImage: "doc.text.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("MIT License")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Copyright © 2025 Gunnar Hostetler")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(mitLicenseText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var acknowledgementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Third-Party Software", systemImage: "square.stack.3d.up.fill")
                .font(.headline)

            Text("This application uses only native iOS frameworks and APIs. No third-party dependencies are included.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                acknowledgementRow(
                    title: "OpenAI API",
                    description: "Powered by OpenAI's GPT models for intelligent conversations"
                )

                acknowledgementRow(
                    title: "Apple Frameworks",
                    description: "SwiftUI, Foundation, Security (Keychain), and Contacts"
                )
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func acknowledgementRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - License Text

    private var mitLicenseText: String {
        """
        MIT License

        Copyright (c) 2025 Gunnar Hostetler

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """
    }
}

#Preview {
    AboutView()
}
