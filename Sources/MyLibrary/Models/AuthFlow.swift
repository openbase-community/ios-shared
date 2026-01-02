import Foundation

/// Authentication flow types
public enum AuthFlowType: String, Codable, Sendable {
    case login
    case loginByCode = "login_by_code"
    case mfaAuthenticate = "mfa_authenticate"
    case mfaReauthenticate = "mfa_reauthenticate"
    case mfaTrust = "mfa_trust"
    case passwordResetByCode = "password_reset_by_code"
    case providerRedirect = "provider_redirect"
    case providerSignup = "provider_signup"
    case reauthenticate
    case signup
    case verifyEmail = "verify_email"
}

/// A pending authentication flow
public struct PendingFlow: Codable, Sendable, Identifiable {
    public var id: String { flowId.rawValue }

    /// The flow type
    public let flowId: AuthFlowType

    /// Whether this flow is currently pending
    public let isPending: Bool

    /// Types of authenticators that can be used
    public let types: [AuthenticatorType]?

    /// Whether the flow is for a passkey
    public let isPasskey: Bool?

    enum CodingKeys: String, CodingKey {
        case flowId = "id"
        case isPending = "is_pending"
        case types
        case isPasskey = "is_passkey"
    }

    public init(
        flowId: AuthFlowType,
        isPending: Bool,
        types: [AuthenticatorType]? = nil,
        isPasskey: Bool? = nil
    ) {
        self.flowId = flowId
        self.isPending = isPending
        self.types = types
        self.isPasskey = isPasskey
    }
}

/// Authentication process types
public enum AuthProcess: String, Codable, Sendable {
    case login
    case connect
}
