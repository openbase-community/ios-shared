import Foundation

/// Represents the current authentication state
public enum AuthState: Sendable, Equatable {
    /// Initial loading state
    case loading

    /// User is authenticated
    case authenticated(User)

    /// User is authenticated but needs to reauthenticate (e.g., for sensitive operations)
    case requiresReauthentication(User)

    /// User is not authenticated
    case unauthenticated

    /// An error occurred during authentication
    case error(String)

    /// Whether the user is authenticated (including reauthentication required)
    public var isAuthenticated: Bool {
        switch self {
        case .authenticated, .requiresReauthentication:
            return true
        case .loading, .unauthenticated, .error:
            return false
        }
    }

    /// The current user if authenticated
    public var user: User? {
        switch self {
        case .authenticated(let user), .requiresReauthentication(let user):
            return user
        case .loading, .unauthenticated, .error:
            return nil
        }
    }

    /// Whether reauthentication is required
    public var requiresReauth: Bool {
        if case .requiresReauthentication = self {
            return true
        }
        return false
    }

    /// Whether the state is still loading
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.authenticated(let l), .authenticated(let r)):
            return l == r
        case (.requiresReauthentication(let l), .requiresReauthentication(let r)):
            return l == r
        case (.unauthenticated, .unauthenticated):
            return true
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}
