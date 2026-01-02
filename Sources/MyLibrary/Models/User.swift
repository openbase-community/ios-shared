import Foundation

/// A user account
public struct User: Codable, Sendable, Identifiable, Equatable {
    /// Unique user ID
    public let id: Int

    /// Primary email address
    public let email: String

    /// Username (optional)
    public let username: String?

    /// Display name (optional)
    public let display: String?

    /// Whether the user has a usable password set
    public let hasUsablePassword: Bool?

    public init(
        id: Int,
        email: String,
        username: String? = nil,
        display: String? = nil,
        hasUsablePassword: Bool? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.display = display
        self.hasUsablePassword = hasUsablePassword
    }

    /// Display name with fallback to email
    public var displayName: String {
        display ?? username ?? email
    }
}
