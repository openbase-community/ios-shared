import Foundation
import AuthenticationServices
import SwiftUI

/// Coordinates OAuth authentication flows using ASWebAuthenticationSession
@Observable
public final class OAuthFlowCoordinator: NSObject, @unchecked Sendable {
    /// The auth manager to use for API calls
    public weak var authManager: AuthManager?

    /// The callback URL scheme for your app (e.g., "myapp")
    public let callbackURLScheme: String

    /// Whether an OAuth flow is currently in progress
    public private(set) var isAuthenticating = false

    /// Current error if any
    public private(set) var error: Error?

    private var currentSession: ASWebAuthenticationSession?
    private var presentationAnchor: ASPresentationAnchor?

    public init(callbackURLScheme: String, authManager: AuthManager? = nil) {
        self.callbackURLScheme = callbackURLScheme
        self.authManager = authManager
        super.init()
    }

    /// Start OAuth flow with a provider
    /// - Parameters:
    ///   - provider: The provider to authenticate with
    ///   - process: Login or connect process
    ///   - baseURL: The base URL for OAuth (your backend)
    ///   - presentationAnchor: The window to present the auth UI from
    /// - Returns: Auth response if successful
    @MainActor
    public func startOAuthFlow(
        provider: ProviderInfo,
        process: AuthProcess = .login,
        baseURL: URL,
        presentationAnchor: ASPresentationAnchor
    ) async throws -> AuthResponse<AuthData> {
        self.presentationAnchor = presentationAnchor
        isAuthenticating = true
        error = nil

        defer {
            isAuthenticating = false
            self.presentationAnchor = nil
            currentSession = nil
        }

        // Build the OAuth URL
        let oauthURL = buildOAuthURL(
            baseURL: baseURL,
            provider: provider,
            process: process
        )

        // Start the web authentication session
        let callbackURL = try await startWebAuthSession(url: oauthURL)

        // Extract token from callback URL
        guard let token = extractToken(from: callbackURL) else {
            throw OAuthError.invalidCallback
        }

        // Authenticate with the token
        guard let authManager = authManager else {
            throw OAuthError.missingAuthManager
        }

        return try await authManager.authenticateByToken(
            providerId: provider.id,
            token: token,
            process: process
        )
    }

    /// Build the OAuth URL for the given provider
    private func buildOAuthURL(
        baseURL: URL,
        provider: ProviderInfo,
        process: AuthProcess
    ) -> URL {
        // The OAuth flow starts by redirecting to the provider's auth page
        // The backend handles the redirect and returns a callback with a token
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/_allauth/app/v1/auth/provider/redirect"

        // Build callback URL
        let callbackURL = "\(callbackURLScheme)://oauth/callback"

        components.queryItems = [
            URLQueryItem(name: "provider", value: provider.id),
            URLQueryItem(name: "process", value: process.rawValue),
            URLQueryItem(name: "callback_url", value: callbackURL)
        ]

        return components.url!
    }

    /// Start the web authentication session
    @MainActor
    private func startWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        continuation.resume(throwing: OAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: OAuthError.sessionError(error))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            self.currentSession = session

            if !session.start() {
                continuation.resume(throwing: OAuthError.failedToStart)
            }
        }
    }

    /// Extract the token from the OAuth callback URL
    private func extractToken(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Look for token in query parameters
        return components.queryItems?.first { $0.name == "token" }?.value
    }

    /// Cancel any ongoing OAuth flow
    public func cancel() {
        currentSession?.cancel()
        currentSession = nil
        isAuthenticating = false
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthFlowCoordinator: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}

// MARK: - OAuth Errors

/// Errors that can occur during OAuth flow
public enum OAuthError: Error, Sendable {
    case cancelled
    case invalidCallback
    case failedToStart
    case sessionError(Error)
    case missingAuthManager
}

extension OAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Authentication was cancelled"
        case .invalidCallback:
            return "Invalid OAuth callback"
        case .failedToStart:
            return "Failed to start authentication"
        case .sessionError(let error):
            return "Authentication error: \(error.localizedDescription)"
        case .missingAuthManager:
            return "Auth manager not configured"
        }
    }
}

// MARK: - Environment Key

private struct OAuthCoordinatorKey: EnvironmentKey {
    static let defaultValue: OAuthFlowCoordinator? = nil
}

public extension EnvironmentValues {
    var oauthCoordinator: OAuthFlowCoordinator? {
        get { self[OAuthCoordinatorKey.self] }
        set { self[OAuthCoordinatorKey.self] = newValue }
    }
}

public extension View {
    /// Inject the OAuth coordinator into the environment
    func oauthCoordinator(_ coordinator: OAuthFlowCoordinator) -> some View {
        environment(\.oauthCoordinator, coordinator)
            .environment(coordinator)
    }
}
