import Foundation

/// Manages the session token for API authentication
/// Stores the token securely in the iOS Keychain
@Observable
public final class SessionTokenManager: Sendable {
    private static let tokenKey = "sessionToken"

    private let keychain: KeychainHelper

    public init(keychain: KeychainHelper = KeychainHelper()) {
        self.keychain = keychain
    }

    /// The current session token, if any
    public var sessionToken: String? {
        get {
            try? keychain.getString(forKey: Self.tokenKey)
        }
    }

    /// Save a new session token
    public func setSessionToken(_ token: String) {
        try? keychain.save(token, forKey: Self.tokenKey)
    }

    /// Clear the session token
    public func clearToken() {
        try? keychain.delete(Self.tokenKey)
    }

    /// Check if a session token exists
    public var hasToken: Bool {
        sessionToken != nil
    }
}
