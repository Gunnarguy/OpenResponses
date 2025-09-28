import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
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
            title: "API Key Required",
            description: "To get started, you'll need an OpenAI API key. Don't worry - your key is stored securely on your device and never shared.",
            imageName: "key.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
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
            .padding(.bottom, 40)
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
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(page.color.gradient)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 40)
            
            Spacer()
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
