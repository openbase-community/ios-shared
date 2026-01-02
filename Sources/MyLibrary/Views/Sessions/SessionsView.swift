import SwiftUI

/// View and manage active user sessions
public struct SessionsView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var sessions: [UserSession] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showEndAllConfirmation = false

    /// Whether to show the "last seen" column (if tracking is enabled)
    private var showLastSeen: Bool {
        authManager.config?.usersessions?.trackActivity == true
    }

    private var otherSessions: [UserSession] {
        sessions.filter { !$0.isCurrent }
    }

    public init() {}

    public var body: some View {
        List {
            // Current session
            if let currentSession = sessions.first(where: { $0.isCurrent }) {
                Section {
                    SessionRow(session: currentSession, showLastSeen: showLastSeen)
                } header: {
                    Text("Current Session")
                } footer: {
                    Text("This is your current active session.")
                }
            }

            // Other sessions
            if !otherSessions.isEmpty {
                Section {
                    ForEach(otherSessions) { session in
                        SessionRow(session: session, showLastSeen: showLastSeen) {
                            await endSession(session)
                        }
                    }
                } header: {
                    Text("Other Sessions")
                } footer: {
                    Text("You can sign out of individual sessions or all other sessions at once.")
                }
            }

            // End all other sessions
            if !otherSessions.isEmpty {
                Section {
                    Button(role: .destructive) {
                        showEndAllConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out Everywhere Else")
                        }
                    }
                }
            }

            if sessions.isEmpty && !isLoading {
                Section {
                    Text("No active sessions found.")
                        .foregroundColor(.secondary)
                }
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Active Sessions")
        .refreshable {
            await loadSessions()
        }
        .task {
            await loadSessions()
        }
        .overlay {
            if isLoading && sessions.isEmpty {
                ProgressView()
            }
        }
        .confirmationDialog(
            "Sign Out Everywhere Else",
            isPresented: $showEndAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out All Other Sessions", role: .destructive) {
                Task { await endAllOtherSessions() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will sign you out of all other devices and browsers. You'll remain signed in on this device.")
        }
    }

    private func loadSessions() async {
        isLoading = true
        error = nil

        do {
            let response = try await authManager.client.getSessions()
            if let data = response.data {
                sessions = data.sorted { s1, s2 in
                    // Current session first, then by last seen/created
                    if s1.isCurrent { return true }
                    if s2.isCurrent { return false }
                    return (s1.lastSeenAt ?? s1.createdAt) > (s2.lastSeenAt ?? s2.createdAt)
                }
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func endSession(_ session: UserSession) async {
        do {
            let response = try await authManager.client.endSessions(ids: [session.id])
            if let data = response.data {
                sessions = data
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func endAllOtherSessions() async {
        do {
            let response = try await authManager.client.endAllOtherSessions()
            if let data = response.data {
                sessions = data
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Row displaying a single session
struct SessionRow: View {
    let session: UserSession
    let showLastSeen: Bool
    var onEndSession: (() async -> Void)?

    @State private var isEnding = false

    init(
        session: UserSession,
        showLastSeen: Bool,
        onEndSession: (() async -> Void)? = nil
    ) {
        self.session = session
        self.showLastSeen = showLastSeen
        self.onEndSession = onEndSession
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: browserIcon)
                            .foregroundColor(.secondary)
                        Text(session.browserName)
                            .fontWeight(.medium)

                        if session.isCurrent {
                            Text("Current")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }

                    if let ip = session.ip {
                        Text("IP: \(ip)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !session.isCurrent, let onEndSession = onEndSession {
                    Button(role: .destructive) {
                        Task {
                            isEnding = true
                            await onEndSession()
                            isEnding = false
                        }
                    } label: {
                        if isEnding {
                            ProgressView()
                        } else {
                            Text("End")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isEnding)
                }
            }

            HStack(spacing: 16) {
                Label {
                    Text("Created \(session.createdDate, style: .relative) ago")
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if showLastSeen, let lastSeen = session.lastSeenDate {
                    Label {
                        Text("Last seen \(lastSeen, style: .relative) ago")
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var browserIcon: String {
        switch session.browserName.lowercased() {
        case "safari":
            return "safari"
        case "chrome":
            return "globe"
        case "firefox":
            return "flame"
        case "edge":
            return "square.stack.3d.up"
        default:
            return "globe"
        }
    }
}

#Preview {
    NavigationStack {
        SessionsView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
