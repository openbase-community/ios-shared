import Foundation

/// API endpoint paths matching the django-allauth headless API
public enum APIEndpoint: Sendable {
    // MARK: - Meta
    case config

    // MARK: - Account Management
    case changePassword
    case email
    case providers

    // MARK: - Account Management: 2FA
    case authenticators
    case recoveryCodes
    case totpAuthenticator

    // MARK: - Auth: Basics
    case login
    case requestLoginCode
    case confirmLoginCode
    case session
    case reauthenticate
    case requestPasswordReset
    case resetPassword
    case signup
    case verifyEmail

    // MARK: - Auth: 2FA
    case mfaAuthenticate
    case mfaReauthenticate
    case mfaTrust

    // MARK: - Auth: Social
    case providerSignup
    case providerToken

    // MARK: - Auth: Sessions
    case sessions

    /// The URL path for this endpoint
    public var path: String {
        switch self {
        // Meta
        case .config:
            return "/config"

        // Account management
        case .changePassword:
            return "/account/password/change"
        case .email:
            return "/account/email"
        case .providers:
            return "/account/providers"

        // Account management: 2FA
        case .authenticators:
            return "/account/authenticators"
        case .recoveryCodes:
            return "/account/authenticators/recovery-codes"
        case .totpAuthenticator:
            return "/account/authenticators/totp"

        // Auth: Basics
        case .login:
            return "/auth/login"
        case .requestLoginCode:
            return "/auth/code/request"
        case .confirmLoginCode:
            return "/auth/code/confirm"
        case .session:
            return "/auth/session"
        case .reauthenticate:
            return "/auth/reauthenticate"
        case .requestPasswordReset:
            return "/auth/password/request"
        case .resetPassword:
            return "/auth/password/reset"
        case .signup:
            return "/auth/signup"
        case .verifyEmail:
            return "/auth/email/verify"

        // Auth: 2FA
        case .mfaAuthenticate:
            return "/auth/2fa/authenticate"
        case .mfaReauthenticate:
            return "/auth/2fa/reauthenticate"
        case .mfaTrust:
            return "/auth/2fa/trust"

        // Auth: Social
        case .providerSignup:
            return "/auth/provider/signup"
        case .providerToken:
            return "/auth/provider/token"

        // Auth: Sessions
        case .sessions:
            return "/auth/sessions"
        }
    }
}
