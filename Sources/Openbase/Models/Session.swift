import Foundation

/// An active user session
public struct UserSession: Codable, Sendable, Identifiable, Equatable {
    /// Session ID
    public let id: Int

    /// When the session was created (Unix timestamp)
    public let createdAt: TimeInterval

    /// IP address of the session
    public let ip: String?

    /// User agent string
    public let userAgent: String?

    /// Whether this is the current session
    public let isCurrent: Bool

    /// When the session was last used (Unix timestamp, if tracking enabled)
    public let lastSeenAt: TimeInterval?

    public init(
        id: Int,
        createdAt: TimeInterval,
        ip: String? = nil,
        userAgent: String? = nil,
        isCurrent: Bool,
        lastSeenAt: TimeInterval? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.ip = ip
        self.userAgent = userAgent
        self.isCurrent = isCurrent
        self.lastSeenAt = lastSeenAt
    }

    /// Created date as Date object
    public var createdDate: Date {
        Date(timeIntervalSince1970: createdAt)
    }

    /// Last seen date as Date object (if available)
    public var lastSeenDate: Date? {
        lastSeenAt.map { Date(timeIntervalSince1970: $0) }
    }

    /// Parsed browser name from user agent
    public var browserName: String {
        guard let userAgent = userAgent else { return "Unknown" }

        if userAgent.contains("Chrome") && !userAgent.contains("Edg") {
            return "Chrome"
        } else if userAgent.contains("Safari") && !userAgent.contains("Chrome") {
            return "Safari"
        } else if userAgent.contains("Firefox") {
            return "Firefox"
        } else if userAgent.contains("Edg") {
            return "Edge"
        } else {
            return "Browser"
        }
    }
}
