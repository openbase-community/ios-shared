import Foundation

/// HTTP methods supported by the API
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// The main API client for django-allauth headless API
/// Uses URLSession for networking and manages session tokens automatically
@Observable
public final class AllAuthClient: @unchecked Sendable {
    /// Base URL for the API (e.g., "https://api.example.com/_allauth/app/v1")
    public let baseURL: URL

    /// User agent string sent with requests
    public var userAgent: String = "AllAuth-iOS/1.0"

    private let session: URLSession
    private let tokenManager: SessionTokenManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Stream of authentication changes
    private let authChangeContinuation: AsyncStream<AuthResponse<AuthData>>.Continuation
    public let authChanges: AsyncStream<AuthResponse<AuthData>>

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenManager: SessionTokenManager = SessionTokenManager()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenManager = tokenManager

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase

        // Create async stream for auth changes
        var continuation: AsyncStream<AuthResponse<AuthData>>.Continuation!
        self.authChanges = AsyncStream { continuation = $0 }
        self.authChangeContinuation = continuation
    }

    // MARK: - Core Request Method

    /// Perform an API request
    public func request<T: Decodable>(
        method: HTTPMethod,
        endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:]
    ) async throws -> AuthResponse<T> {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Add session token if available (except for config endpoint)
        if endpoint != .config, let token = tokenManager.sessionToken {
            request.setValue(token, forHTTPHeaderField: "X-Session-Token")
        }

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if present
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw AllAuthError.networkError(error)
        }

        guard response is HTTPURLResponse else {
            throw AllAuthError.invalidResponse
        }

        // Decode response
        let authResponse: AuthResponse<T>
        do {
            authResponse = try decoder.decode(AuthResponse<T>.self, from: data)
        } catch let error as DecodingError {
            throw AllAuthError.decodingError(error)
        }

        // Handle session token lifecycle
        if authResponse.status == 410 {
            tokenManager.clearToken()
        }
        if let newToken = authResponse.meta?.sessionToken {
            tokenManager.setSessionToken(newToken)
        }

        // Emit auth change events for relevant status codes
        if [401, 410].contains(authResponse.status) ||
           (authResponse.status == 200 && authResponse.meta?.isAuthenticated == true) {
            // Try to convert to AuthData response for the stream
            if let authData = authResponse as? AuthResponse<AuthData> {
                authChangeContinuation.yield(authData)
            }
        }

        return authResponse
    }

    // MARK: - Authentication

    /// Log in with email and password
    public func login(email: String, password: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .login,
            body: LoginRequest(email: email, password: password)
        )
    }

    /// Log out the current session
    public func logout() async throws -> AuthResponse<EmptyData> {
        try await request(method: .delete, endpoint: .session)
    }

    /// Sign up a new user
    public func signUp(email: String, password: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .signup,
            body: SignupRequest(email: email, password: password)
        )
    }

    /// Get current authentication status
    public func getAuth() async throws -> AuthResponse<AuthData> {
        try await request(method: .get, endpoint: .session)
    }

    /// Reauthenticate with password
    public func reauthenticate(password: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .reauthenticate,
            body: ["password": password]
        )
    }

    // MARK: - Passwordless Login

    /// Request a login code to be sent to email
    public func requestLoginCode(email: String) async throws -> AuthResponse<EmptyData> {
        try await request(
            method: .post,
            endpoint: .requestLoginCode,
            body: ["email": email]
        )
    }

    /// Confirm login with the code
    public func confirmLoginCode(code: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .confirmLoginCode,
            body: ["code": code]
        )
    }

    // MARK: - Configuration

    /// Get server configuration
    public func getConfig() async throws -> AuthResponse<AuthConfig> {
        try await request(method: .get, endpoint: .config)
    }

    // MARK: - Password Management

    /// Request a password reset email
    public func requestPasswordReset(email: String) async throws -> AuthResponse<EmptyData> {
        try await request(
            method: .post,
            endpoint: .requestPasswordReset,
            body: ["email": email]
        )
    }

    /// Get password reset info (validate key)
    public func getPasswordReset(key: String) async throws -> AuthResponse<PasswordResetData> {
        try await request(
            method: .get,
            endpoint: .resetPassword,
            headers: ["X-Password-Reset-Key": key]
        )
    }

    /// Reset password with key
    public func resetPassword(key: String, password: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .resetPassword,
            body: ResetPasswordRequest(key: key, password: password)
        )
    }

    /// Change password for authenticated user
    public func changePassword(currentPassword: String?, newPassword: String) async throws -> AuthResponse<EmptyData> {
        try await request(
            method: .post,
            endpoint: .changePassword,
            body: ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
        )
    }

    // MARK: - Email Management

    /// Get all email addresses for the user
    public func getEmailAddresses() async throws -> AuthResponse<[EmailAddress]> {
        try await request(method: .get, endpoint: .email)
    }

    /// Add a new email address
    public func addEmail(_ email: String) async throws -> AuthResponse<[EmailAddress]> {
        try await request(
            method: .post,
            endpoint: .email,
            body: ["email": email]
        )
    }

    /// Delete an email address
    public func deleteEmail(_ email: String) async throws -> AuthResponse<[EmailAddress]> {
        try await request(
            method: .delete,
            endpoint: .email,
            body: ["email": email]
        )
    }

    /// Mark an email address as primary
    public func markEmailAsPrimary(_ email: String) async throws -> AuthResponse<[EmailAddress]> {
        try await request(
            method: .patch,
            endpoint: .email,
            body: MarkEmailPrimaryRequest(email: email, primary: true)
        )
    }

    /// Request email verification to be resent
    public func requestEmailVerification(_ email: String) async throws -> AuthResponse<EmptyData> {
        try await request(
            method: .put,
            endpoint: .email,
            body: ["email": email]
        )
    }

    /// Get email verification info
    public func getEmailVerification(key: String) async throws -> AuthResponse<EmailVerificationData> {
        try await request(
            method: .get,
            endpoint: .verifyEmail,
            headers: ["X-Email-Verification-Key": key]
        )
    }

    /// Verify an email address
    public func verifyEmail(key: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .verifyEmail,
            body: ["key": key]
        )
    }

    // MARK: - MFA / 2FA

    /// Get all authenticators for the user
    public func getAuthenticators() async throws -> AuthResponse<[Authenticator]> {
        try await request(method: .get, endpoint: .authenticators)
    }

    /// Get TOTP authenticator setup info
    public func getTOTPAuthenticator() async throws -> AuthResponse<TOTPSetup> {
        try await request(method: .get, endpoint: .totpAuthenticator)
    }

    /// Activate TOTP authenticator with verification code
    public func activateTOTPAuthenticator(code: String) async throws -> AuthResponse<Authenticator> {
        try await request(
            method: .post,
            endpoint: .totpAuthenticator,
            body: ["code": code]
        )
    }

    /// Deactivate TOTP authenticator
    public func deactivateTOTPAuthenticator() async throws -> AuthResponse<EmptyData> {
        try await request(method: .delete, endpoint: .totpAuthenticator)
    }

    /// Authenticate with MFA code during login
    public func mfaAuthenticate(code: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .mfaAuthenticate,
            body: ["code": code]
        )
    }

    /// Reauthenticate with MFA code
    public func mfaReauthenticate(code: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .mfaReauthenticate,
            body: ["code": code]
        )
    }

    /// Trust the current device for MFA
    public func mfaTrust(_ trust: Bool) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .mfaTrust,
            body: ["trust": trust]
        )
    }

    // MARK: - Recovery Codes

    /// Get recovery codes
    public func getRecoveryCodes() async throws -> AuthResponse<RecoveryCodesData> {
        try await request(method: .get, endpoint: .recoveryCodes)
    }

    /// Generate new recovery codes
    public func generateRecoveryCodes() async throws -> AuthResponse<RecoveryCodesData> {
        try await request(method: .post, endpoint: .recoveryCodes)
    }

    // MARK: - Social Auth / OAuth

    /// Authenticate using a social provider token
    public func authenticateByToken(
        providerId: String,
        token: String,
        process: AuthProcess = .login
    ) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .providerToken,
            body: ProviderTokenRequest(provider: providerId, token: token, process: process)
        )
    }

    /// Complete social provider signup with additional data
    public func providerSignup(email: String) async throws -> AuthResponse<AuthData> {
        try await request(
            method: .post,
            endpoint: .providerSignup,
            body: ["email": email]
        )
    }

    /// Get connected social provider accounts
    public func getProviderAccounts() async throws -> AuthResponse<[ProviderAccount]> {
        try await request(method: .get, endpoint: .providers)
    }

    /// Disconnect a social provider account
    public func disconnectProviderAccount(providerId: String, accountUid: String) async throws -> AuthResponse<[ProviderAccount]> {
        try await request(
            method: .delete,
            endpoint: .providers,
            body: ["provider": providerId, "account": accountUid]
        )
    }

    // MARK: - Sessions

    /// Get all active sessions
    public func getSessions() async throws -> AuthResponse<[UserSession]> {
        try await request(method: .get, endpoint: .sessions)
    }

    /// End specific sessions
    public func endSessions(ids: [Int]) async throws -> AuthResponse<[UserSession]> {
        try await request(
            method: .delete,
            endpoint: .sessions,
            body: ["sessions": ids]
        )
    }

    /// End all other sessions except current
    public func endAllOtherSessions() async throws -> AuthResponse<[UserSession]> {
        try await request(method: .delete, endpoint: .sessions, body: EmptyObject())
    }
}

// MARK: - Request Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct SignupRequest: Encodable {
    let email: String
    let password: String
}

struct ResetPasswordRequest: Encodable {
    let key: String
    let password: String
}

struct ChangePasswordRequest: Encodable {
    let currentPassword: String?
    let newPassword: String
}

struct ProviderTokenRequest: Encodable {
    let provider: String
    let token: String
    let process: AuthProcess
}

struct MarkEmailPrimaryRequest: Encodable {
    let email: String
    let primary: Bool
}

struct EmptyObject: Encodable {}

// MARK: - Type Erasure Helper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self._encode = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
