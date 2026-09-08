import AuthenticationServices
import UIKit

/// Uses the provider's system sign-in sheet and browser cookies; never asks for a provider password.
@MainActor
final class MCPWebAuthentication: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private var attempt: UUID?

    func signIn(url: URL) async throws -> URL {
        guard session == nil else { throw MCPAuthorizationError.cancelled }
        let id = UUID()
        attempt = id
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "openresponses") { [weak self] callback, error in
                    Task { @MainActor in
                        guard let self, self.attempt == id else { return }
                        if let callback { self.finish(.success(callback)) }
                        else { self.finish(.failure(MCPAuthorizationError.cancelled)) }
                    }
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                self.session = session
                if !session.start() { finish(.failure(MCPAuthorizationError.cancelled)) }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                guard self?.attempt == id else { return }
                self?.cancel()
            }
        }
    }

    func cancel() {
        session?.cancel()
        finish(.failure(MCPAuthorizationError.cancelled))
    }

    private func finish(_ result: Result<URL, Error>) {
        let callback = continuation
        continuation = nil
        session = nil
        attempt = nil
        callback?.resume(with: result)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
