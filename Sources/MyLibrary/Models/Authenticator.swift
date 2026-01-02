import Foundation

/// Types of MFA authenticators
public enum AuthenticatorType: String, Codable, Sendable {
    case totp
    case recoveryCodes = "recovery_codes"
}

/// An MFA authenticator
public struct Authenticator: Codable, Sendable, Identifiable {
    public var id: String { type.rawValue }

    /// The authenticator type
    public let type: AuthenticatorType

    /// When the authenticator was created (Unix timestamp)
    public let createdAt: TimeInterval?

    /// When the authenticator was last used (Unix timestamp)
    public let lastUsedAt: TimeInterval?

    /// Total number of recovery codes (for recovery_codes type)
    public let totalCodeCount: Int?

    /// Number of unused recovery codes (for recovery_codes type)
    public let unusedCodeCount: Int?

    public init(
        type: AuthenticatorType,
        createdAt: TimeInterval? = nil,
        lastUsedAt: TimeInterval? = nil,
        totalCodeCount: Int? = nil,
        unusedCodeCount: Int? = nil
    ) {
        self.type = type
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.totalCodeCount = totalCodeCount
        self.unusedCodeCount = unusedCodeCount
    }

    /// Created date as Date object
    public var createdDate: Date? {
        createdAt.map { Date(timeIntervalSince1970: $0) }
    }

    /// Last used date as Date object
    public var lastUsedDate: Date? {
        lastUsedAt.map { Date(timeIntervalSince1970: $0) }
    }
}

/// TOTP setup data
public struct TOTPSetup: Codable, Sendable {
    /// The TOTP secret key
    public let secret: String

    /// The TOTP URL for QR code generation
    public let totpUrl: String?

    /// SVG data for QR code (if provided by server)
    public let totpSvg: String?

    public init(secret: String, totpUrl: String? = nil, totpSvg: String? = nil) {
        self.secret = secret
        self.totpUrl = totpUrl
        self.totpSvg = totpSvg
    }
}

/// Recovery codes data
public struct RecoveryCodesData: Codable, Sendable {
    /// Total number of recovery codes
    public let totalCodeCount: Int

    /// Number of unused recovery codes
    public let unusedCodeCount: Int

    /// The actual recovery codes (only returned when generating)
    public let unusedCodes: [String]?

    public init(totalCodeCount: Int, unusedCodeCount: Int, unusedCodes: [String]? = nil) {
        self.totalCodeCount = totalCodeCount
        self.unusedCodeCount = unusedCodeCount
        self.unusedCodes = unusedCodes
    }
}
