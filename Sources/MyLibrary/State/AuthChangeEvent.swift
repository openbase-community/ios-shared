import Foundation

/// Events that represent changes in authentication state
public enum AuthChangeEvent: Sendable, Equatable {
    /// User has logged out
    case loggedOut

    /// User has logged in
    case loggedIn

    /// User has successfully reauthenticated
    case reauthenticated

    /// Reauthentication is required for the current operation
    case reauthenticationRequired

    /// An authentication flow has been updated (e.g., MFA step)
    case flowUpdated(AuthFlowType)
}
