import Foundation

/// An email address associated with a user account
public struct EmailAddress: Codable, Sendable, Identifiable, Equatable {
    public var id: String { email }

    /// The email address
    public let email: String

    /// Whether the email is verified
    public let verified: Bool

    /// Whether this is the primary email
    public let primary: Bool

    public init(email: String, verified: Bool, primary: Bool) {
        self.email = email
        self.verified = verified
        self.primary = primary
    }
}
