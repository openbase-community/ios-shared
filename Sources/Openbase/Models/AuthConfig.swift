import Foundation

/// Server configuration for authentication
public struct AuthConfig: Decodable, Sendable {
    /// Account settings
    public let account: AccountConfig?

    /// Social account settings
    public let socialaccount: SocialAccountConfig?

    /// MFA settings
    public let mfa: MFAConfig?

    /// User sessions settings
    public let usersessions: UserSessionsConfig?

    public init(
        account: AccountConfig? = nil,
        socialaccount: SocialAccountConfig? = nil,
        mfa: MFAConfig? = nil,
        usersessions: UserSessionsConfig? = nil
    ) {
        self.account = account
        self.socialaccount = socialaccount
        self.mfa = mfa
        self.usersessions = usersessions
    }
}

/// Account configuration
public struct AccountConfig: Decodable, Sendable {
    /// Whether authentication by email is enabled
    public let authenticationMethod: String?

    /// Whether login by code is enabled
    public let loginByCodeEnabled: Bool?

    /// Whether email verification by code is enabled
    public let emailVerificationByCodeEnabled: Bool?

    public init(
        authenticationMethod: String? = nil,
        loginByCodeEnabled: Bool? = nil,
        emailVerificationByCodeEnabled: Bool? = nil
    ) {
        self.authenticationMethod = authenticationMethod
        self.loginByCodeEnabled = loginByCodeEnabled
        self.emailVerificationByCodeEnabled = emailVerificationByCodeEnabled
    }
}

/// Social account configuration
public struct SocialAccountConfig: Decodable, Sendable {
    /// Available OAuth providers
    public let providers: [ProviderInfo]

    public init(providers: [ProviderInfo]) {
        self.providers = providers
    }
}

/// MFA configuration
public struct MFAConfig: Decodable, Sendable {
    /// Supported authenticator types
    public let supportedTypes: [AuthenticatorType]?

    public init(supportedTypes: [AuthenticatorType]? = nil) {
        self.supportedTypes = supportedTypes
    }
}

/// User sessions configuration
public struct UserSessionsConfig: Decodable, Sendable {
    /// Whether to track last seen time
    public let trackActivity: Bool?

    public init(trackActivity: Bool? = nil) {
        self.trackActivity = trackActivity
    }
}

/// Information about an OAuth provider
public struct ProviderInfo: Codable, Sendable, Identifiable {
    /// Provider identifier (e.g., "google", "facebook")
    public let id: String

    /// Display name
    public let name: String

    /// Client ID (if applicable)
    public let clientId: String?

    /// Available flows for this provider
    public let flows: [String]?

    public init(id: String, name: String, clientId: String? = nil, flows: [String]? = nil) {
        self.id = id
        self.name = name
        self.clientId = clientId
        self.flows = flows
    }
}
