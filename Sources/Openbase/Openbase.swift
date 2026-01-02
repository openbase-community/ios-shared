// Openbase - Swift Package for Openbase Authentication
// A comprehensive authentication library for iOS apps with SwiftUI support

import SwiftUI

// MARK: - API

/// Re-export API types
public typealias Client = AllAuthClient
public typealias Endpoint = APIEndpoint
public typealias FieldError = APIFieldError
public typealias TokenManager = SessionTokenManager

// MARK: - Library Configuration

/// Configuration for the Openbase authentication package
public struct AllAuthConfiguration {
    /// The base URL for the allauth API (e.g., "https://api.example.com/_allauth/app/v1")
    public let baseURL: URL

    /// The OAuth callback URL scheme (e.g., "myapp")
    public let oauthCallbackScheme: String?

    /// User agent string for API requests
    public let userAgent: String

    public init(
        baseURL: URL,
        oauthCallbackScheme: String? = nil,
        userAgent: String = "AllAuth-iOS/1.0"
    ) {
        self.baseURL = baseURL
        self.oauthCallbackScheme = oauthCallbackScheme
        self.userAgent = userAgent
    }
}

// MARK: - Factory Methods

/// Create a configured AuthManager
public func createAuthManager(configuration: AllAuthConfiguration) -> AuthManager {
    let client = AllAuthClient(baseURL: configuration.baseURL)
    client.userAgent = configuration.userAgent
    return AuthManager(client: client)
}

/// Create an OAuth flow coordinator
public func createOAuthCoordinator(
    configuration: AllAuthConfiguration,
    authManager: AuthManager
) -> OAuthFlowCoordinator? {
    guard let scheme = configuration.oauthCallbackScheme else {
        return nil
    }
    let coordinator = OAuthFlowCoordinator(callbackURLScheme: scheme, authManager: authManager)
    return coordinator
}

// MARK: - SwiftUI Environment Setup

public extension View {
    /// Configure the authentication environment for this view hierarchy
    func allAuthEnvironment(
        configuration: AllAuthConfiguration
    ) -> some View {
        let authManager = createAuthManager(configuration: configuration)
        let oauthCoordinator = createOAuthCoordinator(configuration: configuration, authManager: authManager)

        return self
            .authManager(authManager)
            .environment(authManager)
            .modifier(OptionalOAuthModifier(coordinator: oauthCoordinator))
    }

    /// Configure authentication with an existing auth manager
    func allAuthEnvironment(
        authManager: AuthManager,
        oauthCoordinator: OAuthFlowCoordinator? = nil
    ) -> some View {
        self
            .authManager(authManager)
            .environment(authManager)
            .modifier(OptionalOAuthModifier(coordinator: oauthCoordinator))
    }
}

/// Helper modifier to optionally apply OAuth coordinator
struct OptionalOAuthModifier: ViewModifier {
    let coordinator: OAuthFlowCoordinator?

    func body(content: Content) -> some View {
        if let coordinator = coordinator {
            content
                .oauthCoordinator(coordinator)
                .environment(coordinator)
        } else {
            content
        }
    }
}

// MARK: - Public Type Aliases for Convenience

/// Authentication change event type alias
public typealias ChangeEvent = AuthChangeEvent

/// Authentication flow type alias
public typealias Flow = AuthFlowType

/// Pending flow type alias
public typealias Pending = PendingFlow

// MARK: - Version Info

/// Library version information
public enum LibraryInfo {
    public static let version = "1.0.0"
    public static let name = "Openbase"
    public static let minimumIOSVersion = "17.0"
}
