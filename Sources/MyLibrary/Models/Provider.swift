import Foundation

/// A connected social provider account
public struct ProviderAccount: Codable, Sendable, Identifiable, Equatable {
    public var id: String { uid }

    /// Unique identifier for this connection
    public let uid: String

    /// Display name for the account
    public let display: String?

    /// Provider information
    public let provider: ProviderInfo

    public init(uid: String, display: String?, provider: ProviderInfo) {
        self.uid = uid
        self.display = display
        self.provider = provider
    }

    public static func == (lhs: ProviderAccount, rhs: ProviderAccount) -> Bool {
        lhs.uid == rhs.uid && lhs.provider.id == rhs.provider.id
    }
}
