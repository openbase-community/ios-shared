import SwiftUI

/// Authenticate with a recovery code during login or reauthentication
public struct AuthenticateRecoveryCodesView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var code = ""
    @State private var isLoading = false
    @State private var errors: [APIFieldError]?

    /// Whether this is a reauthentication (vs login)
    public let isReauthentication: Bool

    /// Called when authentication succeeds
    public var onSuccess: (() -> Void)?

    /// Called when user wants to use authenticator app instead
    public var onUseAuthenticatorApp: (() -> Void)?

    public init(
        isReauthentication: Bool = false,
        onSuccess: (() -> Void)? = nil,
        onUseAuthenticatorApp: (() -> Void)? = nil
    ) {
        self.isReauthentication = isReauthentication
        self.onSuccess = onSuccess
        self.onUseAuthenticatorApp = onUseAuthenticatorApp
    }

    private var isFormValid: Bool {
        !code.isEmpty
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Use Recovery Code")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter one of your recovery codes to verify your identity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Info box
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("One-time use")
                            .fontWeight(.semibold)
                    }

                    Text("Each recovery code can only be used once. After using this code, it will be invalidated.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Form
                VStack(spacing: 16) {
                    AuthTextField(
                        "Recovery Code",
                        placeholder: "Enter recovery code",
                        text: $code,
                        fieldType: .text,
                        errors: errors,
                        errorParam: "code"
                    )

                    // Global errors
                    FormErrorsView(errors: errors)
                }

                // Verify button
                LoadingButton("Verify", isLoading: isLoading) {
                    await authenticate()
                }
                .disabled(!isFormValid)

                // Authenticator app link
                if let onUseAuthenticatorApp = onUseAuthenticatorApp {
                    Button("Use authenticator app instead") {
                        onUseAuthenticatorApp()
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recovery Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func authenticate() async {
        isLoading = true
        errors = nil

        do {
            let response: AuthResponse<AuthData>
            if isReauthentication {
                response = try await authManager.mfaReauthenticate(code: code)
            } else {
                response = try await authManager.mfaAuthenticate(code: code)
            }

            if response.isSuccess {
                onSuccess?()
            } else {
                errors = response.errors
            }
        } catch {
            errors = [APIFieldError(param: nil, code: "error", message: error.localizedDescription)]
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AuthenticateRecoveryCodesView()
    }
    .environment(AuthManager(baseURL: URL(string: "https://example.com")!))
}
