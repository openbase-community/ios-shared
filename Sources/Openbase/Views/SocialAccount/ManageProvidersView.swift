import SwiftUI

/// Manage connected social provider accounts
public struct ManageProvidersView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(OAuthFlowCoordinator.self) private var oauthCoordinator: OAuthFlowCoordinator?

    @State private var connectedAccounts: [ProviderAccount] = []
    @State private var isLoading = true
    @State private var isConnecting = false
    @State private var error: String?

    public init() {}

    private var availableProviders: [ProviderInfo] {
        let connectedIds = Set(connectedAccounts.map { $0.provider.id })
        return (authManager.config?.socialaccount?.providers ?? [])
            .filter { !connectedIds.contains($0.id) }
    }

    public var body: some View {
        List {
            // Connected accounts section
            if !connectedAccounts.isEmpty {
                Section {
                    ForEach(connectedAccounts) { account in
                        ConnectedAccountRow(account: account) {
                            await disconnectAccount(account)
                        }
                    }
                } header: {
                    Text("Connected Accounts")
                } footer: {
                    Text("You can sign in with any of these connected accounts.")
                }
            }

            // Available providers section
            if !availableProviders.isEmpty {
                Section {
                    ForEach(availableProviders) { provider in
                        Button {
                            Task { await connectProvider(provider) }
                        } label: {
                            HStack {
                                providerIcon(for: provider)
                                    .frame(width: 24, height: 24)

                                Text("Connect \(provider.name)")

                                Spacer()

                                if isConnecting {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .disabled(isConnecting)
                    }
                } header: {
                    Text("Available Accounts")
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
        .navigationTitle("Connected Accounts")
        .refreshable {
            await loadAccounts()
        }
        .task {
            await loadAccounts()
        }
        .overlay {
            if isLoading && connectedAccounts.isEmpty {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func providerIcon(for provider: ProviderInfo) -> some View {
        switch provider.id.lowercased() {
        case "google":
            Image(systemName: "g.circle.fill")
                .foregroundColor(.red)
        case "apple":
            Image(systemName: "apple.logo")
                .foregroundColor(.primary)
        case "facebook":
            Image(systemName: "f.circle.fill")
                .foregroundColor(.blue)
        case "github":
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .foregroundColor(.primary)
        default:
            Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
        }
    }

    private func loadAccounts() async {
        isLoading = true
        error = nil

        do {
            let response = try await authManager.client.getProviderAccounts()
            if let data = response.data {
                connectedAccounts = data
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func connectProvider(_ provider: ProviderInfo) async {
        guard let coordinator = oauthCoordinator else {
            error = "OAuth not configured"
            return
        }

        isConnecting = true
        error = nil

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                throw OAuthError.failedToStart
            }

            let response = try await coordinator.startOAuthFlow(
                provider: provider,
                process: .connect,
                baseURL: authManager.client.baseURL,
                presentationAnchor: window
            )

            if response.isSuccess {
                await loadAccounts()
            } else {
                error = response.errors?.first?.message
            }
        } catch let oauthError as OAuthError {
            // User cancelled, ignore
            if case .cancelled = oauthError { return }
            self.error = oauthError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }

        isConnecting = false
    }

    private func disconnectAccount(_ account: ProviderAccount) async {
        do {
            let response = try await authManager.client.disconnectProviderAccount(
                providerId: account.provider.id,
                accountUid: account.uid
            )

            if let data = response.data {
                connectedAccounts = data
            } else {
                error = response.errors?.first?.message
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Row displaying a connected social account
struct ConnectedAccountRow: View {
    let account: ProviderAccount
    let onDisconnect: () async -> Void

    @State private var isDisconnecting = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.provider.name)
                    .fontWeight(.medium)

                if let display = account.display {
                    Text(display)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive) {
                Task {
                    isDisconnecting = true
                    await onDisconnect()
                    isDisconnecting = false
                }
            } label: {
                if isDisconnecting {
                    ProgressView()
                } else {
                    Text("Disconnect")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isDisconnecting)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ManageProvidersView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
