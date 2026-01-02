import SwiftUI

/// Displays a list of OAuth provider buttons
public struct ProviderListView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(OAuthFlowCoordinator.self) private var oauthCoordinator: OAuthFlowCoordinator?

    /// The authentication process (login or connect)
    public let process: AuthProcess

    /// Called when authentication succeeds
    public var onSuccess: (() -> Void)?

    /// Called when authentication fails
    public var onError: ((Error) -> Void)?

    @State private var isAuthenticating = false
    @State private var activeProvider: String?

    public init(
        process: AuthProcess = .login,
        onSuccess: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.process = process
        self.onSuccess = onSuccess
        self.onError = onError
    }

    private var providers: [ProviderInfo] {
        authManager.config?.socialaccount?.providers ?? []
    }

    public var body: some View {
        if !providers.isEmpty {
            VStack(spacing: 12) {
                ForEach(providers) { provider in
                    ProviderButton(
                        provider: provider,
                        isLoading: activeProvider == provider.id && isAuthenticating
                    ) {
                        await authenticateWithProvider(provider)
                    }
                    .disabled(isAuthenticating)
                }
            }
        }
    }

    @MainActor
    private func authenticateWithProvider(_ provider: ProviderInfo) async {
        guard let coordinator = oauthCoordinator else {
            onError?(OAuthError.missingAuthManager)
            return
        }

        activeProvider = provider.id
        isAuthenticating = true

        do {
            // Get the window for presentation
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                throw OAuthError.failedToStart
            }

            let response = try await coordinator.startOAuthFlow(
                provider: provider,
                process: process,
                baseURL: authManager.client.baseURL,
                presentationAnchor: window
            )

            if response.isSuccess {
                onSuccess?()
            } else if let error = response.errors?.first {
                onError?(AllAuthError.serverError(status: response.status, errors: [error]))
            }
        } catch let oauthError as OAuthError {
            // User cancelled, don't report as error
            if case .cancelled = oauthError { return }
            onError?(oauthError)
        } catch {
            onError?(error)
        }

        isAuthenticating = false
        activeProvider = nil
    }
}

/// Button for a single OAuth provider
struct ProviderButton: View {
    let provider: ProviderInfo
    let isLoading: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                providerIcon
                    .frame(width: 20, height: 20)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Continue with \(provider.name)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(providerBackgroundColor)
            .foregroundColor(providerForegroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var providerIcon: some View {
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
        case "twitter", "x":
            Image(systemName: "at.circle.fill")
                .foregroundColor(.cyan)
        case "microsoft":
            Image(systemName: "square.grid.2x2.fill")
                .foregroundColor(.orange)
        default:
            Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
        }
    }

    private var providerBackgroundColor: Color {
        switch provider.id.lowercased() {
        case "apple":
            return Color.primary
        default:
            return Color(.systemBackground)
        }
    }

    private var providerForegroundColor: Color {
        switch provider.id.lowercased() {
        case "apple":
            return Color(.systemBackground)
        default:
            return Color.primary
        }
    }
}

#Preview {
    VStack {
        ProviderListView()
    }
    .padding()
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
