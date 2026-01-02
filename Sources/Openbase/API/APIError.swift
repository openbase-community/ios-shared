import Foundation

/// A field-level error returned by the API
public struct APIFieldError: Codable, Identifiable, Sendable, Equatable {
    public var id: String { "\(param ?? "global")-\(code)" }

    /// The field parameter this error relates to, or nil for global errors
    public let param: String?

    /// Error code identifier
    public let code: String

    /// Human-readable error message
    public let message: String

    public init(param: String?, code: String, message: String) {
        self.param = param
        self.code = code
        self.message = message
    }
}

/// Errors that can occur when interacting with the AllAuth API
public enum AllAuthError: Error, Sendable {
    /// Network-level error
    case networkError(URLError)

    /// Failed to decode response
    case decodingError(DecodingError)

    /// Server returned an error response
    case serverError(status: Int, errors: [APIFieldError])

    /// Session has expired (410 status)
    case sessionExpired

    /// Authentication required (401 status)
    case unauthorized

    /// Invalid response from server
    case invalidResponse

    /// Invalid URL configuration
    case invalidURL
}

extension AllAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let status, let errors):
            if let firstError = errors.first {
                return firstError.message
            }
            return "Server error (status \(status))"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .unauthorized:
            return "Authentication required."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidURL:
            return "Invalid URL configuration."
        }
    }
}
