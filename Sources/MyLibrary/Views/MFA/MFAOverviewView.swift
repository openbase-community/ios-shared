import SwiftUI

/// Overview of MFA settings and available authenticators
public struct MFAOverviewView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var authenticators: [Authenticator] = []
    @State private var isLoading = true
    @State private var error: String?

    /// Called when user wants to activate TOTP
    public var onActivateTOTP: (() -> Void)?

    /// Called when user wants to deactivate TOTP
    public var onDeactivateTOTP: (() -> Void)?

    /// Called when user wants to view recovery codes
    public var onViewRecoveryCodes: (() -> Void)?

    /// Called when user wants to generate recovery codes
    public var onGenerateRecoveryCodes: (() -> Void)?

    public init(
        onActivateTOTP: (() -> Void)? = nil,
        onDeactivateTOTP: (() -> Void)? = nil,
        onViewRecoveryCodes: (() -> Void)? = nil,
        onGenerateRecoveryCodes: (() -> Void)? = nil
    ) {
        self.onActivateTOTP = onActivateTOTP
        self.onDeactivateTOTP = onDeactivateTOTP
        self.onViewRecoveryCodes = onViewRecoveryCodes
        self.onGenerateRecoveryCodes = onGenerateRecoveryCodes
    }

    private var totpAuthenticator: Authenticator? {
        authenticators.first { $0.type == .totp }
    }

    private var recoveryCodesAuthenticator: Authenticator? {
        authenticators.first { $0.type == .recoveryCodes }
    }

    public var body: some View {
        List {
            // TOTP Section
            Section {
                if let totp = totpAuthenticator {
                    // TOTP is active
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Authenticator App")
                                    .fontWeight(.medium)
                            }

                            if let createdAt = totp.createdDate {
                                Text("Added \(createdAt, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let onDeactivateTOTP = onDeactivateTOTP {
                            Button("Remove", role: .destructive) {
                                onDeactivateTOTP()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    // TOTP not active
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                Text("Authenticator App")
                                    .fontWeight(.medium)
                            }

                            Text("Not configured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let onActivateTOTP = onActivateTOTP {
                            Button("Set Up") {
                                onActivateTOTP()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } header: {
                Text("Two-Factor Authentication")
            } footer: {
                Text("Use an authenticator app like Google Authenticator or 1Password to generate verification codes.")
            }

            // Recovery Codes Section
            Section {
                if let recovery = recoveryCodesAuthenticator {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text("Recovery Codes")
                                    .fontWeight(.medium)
                            }

                            if let unused = recovery.unusedCodeCount, let total = recovery.totalCodeCount {
                                Text("\(unused) of \(total) codes remaining")
                                    .font(.caption)
                                    .foregroundColor(unused <= 2 ? .orange : .secondary)
                            }
                        }

                        Spacer()

                        VStack(spacing: 8) {
                            if let onViewRecoveryCodes = onViewRecoveryCodes {
                                Button("View") {
                                    onViewRecoveryCodes()
                                }
                                .buttonStyle(.bordered)
                            }

                            if let onGenerateRecoveryCodes = onGenerateRecoveryCodes {
                                Button("Regenerate") {
                                    onGenerateRecoveryCodes()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                } else if totpAuthenticator != nil {
                    // Show option to generate recovery codes only if TOTP is active
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.secondary)
                                Text("Recovery Codes")
                                    .fontWeight(.medium)
                            }

                            Text("Not generated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let onGenerateRecoveryCodes = onGenerateRecoveryCodes {
                            Button("Generate") {
                                onGenerateRecoveryCodes()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } header: {
                if totpAuthenticator != nil {
                    Text("Backup")
                }
            } footer: {
                if totpAuthenticator != nil {
                    Text("Recovery codes can be used to access your account if you lose your authenticator device.")
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
        .navigationTitle("Two-Factor Auth")
        .refreshable {
            await loadAuthenticators()
        }
        .task {
            await loadAuthenticators()
        }
        .overlay {
            if isLoading && authenticators.isEmpty {
                ProgressView()
            }
        }
    }

    private func loadAuthenticators() async {
        isLoading = true
        error = nil

        do {
            let response = try await authManager.client.getAuthenticators()
            if let data = response.data {
                authenticators = data
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        MFAOverviewView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
