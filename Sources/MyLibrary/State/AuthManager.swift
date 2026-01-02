import Foundation
import SwiftUI

/// Manages authentication state for the application
/// Use this as the central source of truth for auth state
@Observable
public final class AuthManager: @unchecked Sendable {
    /// The API client
    public let client: AllAuthClient

    /// Current authentication state
    public private(set) var state: AuthState = .loading

    /// Server configuration
    public private(set) var config: AuthConfig?

    /// Current pending authentication flow (if any)
    public private(set) var pendingFlow: PendingFlow?

    /// Available authentication methods
    public private(set) var authMethods: [AuthMethod] = []

    /// Last authentication change event
    public private(set) var lastEvent: AuthChangeEvent?

    /// Previous auth response for detecting changes
    private var previousAuthResponse: AuthResponse<AuthData>?

    public init(client: AllAuthClient) {
        self.client = client
    }

    /// Convenience initializer with base URL
    public convenience init(baseURL: URL) {
        self.init(client: AllAuthClient(baseURL: baseURL))
    }

    // MARK: - Computed Properties

    /// Whether the user is authenticated
    public var isAuthenticated: Bool {
        state.isAuthenticated
    }

    /// The current user (if authenticated)
    public var user: User? {
        state.user
    }

    /// Whether reauthentication is required
    public var requiresReauthentication: Bool {
        state.requiresReauth
    }

    // MARK: - State Loading

    /// Load initial authentication state
    @MainActor
    public func loadAuthState() async {
        state = .loading

        do {
            // Load config and auth in parallel
            async let configTask = client.getConfig()
            async let authTask = client.getAuth()

            let (configResponse, authResponse) = try await (configTask, authTask)

            if configResponse.isSuccess {
                config = configResponse.data
            }

            updateState(from: authResponse)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Refresh the current authentication state
    @MainActor
    public func refreshAuth() async throws {
        let response = try await client.getAuth()
        updateState(from: response)
    }

    // MARK: - State Updates

    /// Update state from an auth response
    @MainActor
    public func updateState(from response: AuthResponse<AuthData>) {
        // Determine auth change event
        let event = determineAuthChangeEvent(from: response)
        if let event = event {
            lastEvent = event
        }

        // Update pending flow
        pendingFlow = response.data?.pendingFlow

        // Update auth methods
        authMethods = response.data?.methods ?? []

        // Update state based on response
        if response.status == 200, let user = response.data?.user {
            state = .authenticated(user)
        } else if response.status == 401 {
            if response.meta?.isAuthenticated == true, let user = response.data?.user {
                state = .requiresReauthentication(user)
            } else {
                state = .unauthenticated
            }
        } else if response.status == 410 {
            state = .unauthenticated
        } else if let errors = response.errors, !errors.isEmpty {
            state = .error(errors.first?.message ?? "Authentication error")
        }

        previousAuthResponse = response
    }

    /// Determine what auth change event occurred
    private func determineAuthChangeEvent(from response: AuthResponse<AuthData>) -> AuthChangeEvent? {
        let wasAuthenticated = previousAuthResponse?.meta?.isAuthenticated ?? false
        let isNowAuthenticated = response.meta?.isAuthenticated ?? false

        // Session expired
        if response.status == 410 {
            return .loggedOut
        }

        // Logged in
        if !wasAuthenticated && isNowAuthenticated && response.status == 200 {
            return .loggedIn
        }

        // Logged out
        if wasAuthenticated && !isNowAuthenticated {
            return .loggedOut
        }

        // Reauthentication required
        if response.status == 401 && isNowAuthenticated {
            return .reauthenticationRequired
        }

        // Check for flow updates
        if let pendingFlow = response.data?.pendingFlow, pendingFlow.isPending {
            return .flowUpdated(pendingFlow.flowId)
        }

        // Reauthenticated
        let wasRequiringReauth = previousAuthResponse?.status == 401 &&
            (previousAuthResponse?.meta?.isAuthenticated ?? false)
        if wasRequiringReauth && response.status == 200 {
            return .reauthenticated
        }

        return nil
    }

    // MARK: - Authentication Actions

    /// Log in with email and password
    @MainActor
    public func login(email: String, password: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.login(email: email, password: password)
        updateState(from: response)
        return response
    }

    /// Log out
    @MainActor
    public func logout() async throws {
        _ = try await client.logout()
        state = .unauthenticated
        lastEvent = .loggedOut
        pendingFlow = nil
        authMethods = []
    }

    /// Sign up a new user
    @MainActor
    public func signUp(email: String, password: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.signUp(email: email, password: password)
        updateState(from: response)
        return response
    }

    /// Reauthenticate with password
    @MainActor
    public func reauthenticate(password: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.reauthenticate(password: password)
        updateState(from: response)
        return response
    }

    /// Request a login code
    @MainActor
    public func requestLoginCode(email: String) async throws -> AuthResponse<EmptyData> {
        try await client.requestLoginCode(email: email)
    }

    /// Confirm login with code
    @MainActor
    public func confirmLoginCode(code: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.confirmLoginCode(code: code)
        updateState(from: response)
        return response
    }

    /// Authenticate with MFA code
    @MainActor
    public func mfaAuthenticate(code: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.mfaAuthenticate(code: code)
        updateState(from: response)
        return response
    }

    /// Reauthenticate with MFA code
    @MainActor
    public func mfaReauthenticate(code: String) async throws -> AuthResponse<AuthData> {
        let response = try await client.mfaReauthenticate(code: code)
        updateState(from: response)
        return response
    }

    /// Trust the current device for MFA
    @MainActor
    public func mfaTrust(_ trust: Bool) async throws -> AuthResponse<AuthData> {
        let response = try await client.mfaTrust(trust)
        updateState(from: response)
        return response
    }

    /// Authenticate with OAuth token
    @MainActor
    public func authenticateByToken(
        providerId: String,
        token: String,
        process: AuthProcess = .login
    ) async throws -> AuthResponse<AuthData> {
        let response = try await client.authenticateByToken(
            providerId: providerId,
            token: token,
            process: process
        )
        updateState(from: response)
        return response
    }
}

// MARK: - Environment Key

private struct AuthManagerKey: EnvironmentKey {
    static let defaultValue: AuthManager? = nil
}

public extension EnvironmentValues {
    var authManager: AuthManager? {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }
}

public extension View {
    /// Inject the auth manager into the environment
    func authManager(_ manager: AuthManager) -> some View {
        environment(\.authManager, manager)
            .environment(manager)
    }
}
