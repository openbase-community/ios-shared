import Foundation

/// Generic API response wrapper matching the django-allauth response format
public struct AuthResponse<T: Decodable>: Decodable, Sendable where T: Sendable {
    /// HTTP status code
    public let status: Int

    /// Response data (type varies by endpoint)
    public let data: T?

    /// Response metadata
    public let meta: AuthMeta?

    /// Field-level errors
    public let errors: [APIFieldError]?

    public init(status: Int, data: T?, meta: AuthMeta?, errors: [APIFieldError]?) {
        self.status = status
        self.data = data
        self.meta = meta
        self.errors = errors
    }

    /// Check if the response indicates success
    public var isSuccess: Bool {
        status == 200
    }

    /// Check if authentication is required
    public var requiresAuth: Bool {
        status == 401
    }

    /// Check if the session has expired
    public var isSessionExpired: Bool {
        status == 410
    }
}

/// Response metadata
public struct AuthMeta: Decodable, Sendable {
    /// Whether the user is authenticated
    public let isAuthenticated: Bool?

    /// Session token (for APP client mode)
    public let sessionToken: String?

    /// Access token (for some OAuth flows)
    public let accessToken: String?

    public init(isAuthenticated: Bool? = nil, sessionToken: String? = nil, accessToken: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.sessionToken = sessionToken
        self.accessToken = accessToken
    }
}

/// Authentication data returned from auth endpoints
public struct AuthData: Decodable, Sendable {
    /// The authenticated user
    public let user: User?

    /// Available authentication flows
    public let flows: [PendingFlow]?

    /// Available authentication methods
    public let methods: [AuthMethod]?

    public init(user: User?, flows: [PendingFlow]?, methods: [AuthMethod]?) {
        self.user = user
        self.flows = flows
        self.methods = methods
    }

    /// Get the pending flow if any
    public var pendingFlow: PendingFlow? {
        flows?.first { $0.isPending }
    }
}

/// An authentication method
public struct AuthMethod: Decodable, Sendable, Identifiable {
    public var id: String { method }

    /// Method identifier
    public let method: String

    /// Provider ID for social auth methods
    public let provider: String?

    /// Email associated with the method
    public let email: String?

    /// When the method was used
    public let at: TimeInterval?

    public init(method: String, provider: String? = nil, email: String? = nil, at: TimeInterval? = nil) {
        self.method = method
        self.provider = provider
        self.email = email
        self.at = at
    }
}

/// Empty data type for endpoints that don't return data
public struct EmptyData: Decodable, Sendable {
    public init() {}
}

/// Password reset data
public struct PasswordResetData: Decodable, Sendable {
    public let user: User?

    public init(user: User?) {
        self.user = user
    }
}

/// Email verification data
public struct EmailVerificationData: Decodable, Sendable {
    public let email: String
    public let user: User?

    public init(email: String, user: User?) {
        self.email = email
        self.user = user
    }
}
