import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let keychainService = KeychainService.shared

    let pages = [
        OnboardingPage(
            title: "Welcome to OpenResponses",
            description: "Experience the power of OpenAI's most advanced models with rich tool integration and seamless conversations.",
            imageName: "bubble.left.and.bubble.right.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Powerful AI Tools",
            description: "Access web search, code interpreter, file analysis, and more - all powered by OpenAI's latest capabilities.",
            imageName: "wrench.and.screwdriver.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Your Data, Your Choice",
            description: "Explore Demo stays offline. Live prompts, attachments, and request-related tool data are sent to OpenAI only after you choose Allow & Send.",
            imageName: "lock.shield.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "API Key Required",
            description: "Live requests need an OpenAI API key. Your key is stored in this device’s Keychain and sent to OpenAI for authentication. Review AI answers before acting.",
            imageName: "key.fill",
            color: .orange
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            #if os(macOS)
            // macOS has no paging TabView; show the current page and let Back and Next move between them.
            OnboardingPageView(page: pages[currentPage])
                .id(currentPage)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: currentPage)
            #else
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            #endif

            // Custom page indicator and buttons
            VStack(spacing: 20) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? .primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }

                // At the accessibility text sizes this text is taller than the space left, so it scrolls
                // instead of being cut to "AI-generated content can be inc…" (seen 2026-11-19).
                ScrollView {
                    VStack(spacing: 8) {
                        Text("AI-generated content can be incorrect or outdated. Double-check important information and avoid sharing sensitive data.")

                        Text("By using this app, you agree to the [Terms of Use (EULA)](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) and confirm you are 17+.")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 110)

                // Action buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                        if currentPage == pages.count - 1 {
                            // Mark onboarding as completed
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            isPresented = false

                            // Post notification to check API key after onboarding dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                            }
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(pages[currentPage].color.gradient)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 16 : 40)
        }
        .background(.ultraThinMaterial)
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Centered while it fits; scrolls once large text makes it taller than the page. Before, the title and
        // description were cut to "Welcome…" and "Experience t…" at the accessibility sizes (2026-11-19).
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 20 : 40) {
                    Image(systemName: page.imageName)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 56 : 80, weight: .light))
                        .foregroundStyle(page.color.gradient)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                        .accessibilityHidden(true)

                    VStack(spacing: 16) {
                        Text(page.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(page.description)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 16 : 40)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

// MARK: - Notification Extension

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
